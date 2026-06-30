# glance.ps1 — Claude Code status traffic light (Windows overlay).
# Reads a status file (one word: red | yellow | green) and lights the matching
# lamp in a borderless, always-on-top window. Drag to move. Double-click to quit.
#
# NOTE (v1 limitation): always-on-top on the CURRENT desktop only. Pinning across
# all virtual desktops needs undocumented COM APIs and is a future enhancement.

param([string]$StatusFile)

$ErrorActionPreference = 'SilentlyContinue'

# Single-instance guard: if an overlay is already running, exit quietly.
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'claude-glance-overlay', [ref]$createdNew)
if (-not $createdNew) { return }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrEmpty($StatusFile)) {
  $StatusFile = Join-Path $env:USERPROFILE '.claude\claude-glance\status'
}

$bright = @{
  red    = [System.Drawing.Color]::FromArgb(255, 59, 48)
  yellow = [System.Drawing.Color]::FromArgb(255, 204, 0)
  green  = [System.Drawing.Color]::FromArgb(52, 199, 89)
}
$dim = @{
  red    = [System.Drawing.Color]::FromArgb(74, 23, 20)
  yellow = [System.Drawing.Color]::FromArgb(74, 61, 0)
  green  = [System.Drawing.Color]::FromArgb(18, 61, 28)
}

$W = 58; $H = 158
$script:state = 'green'

function Read-State {
  try {
    $s = (Get-Content -Raw -ErrorAction Stop -LiteralPath $StatusFile).Trim().ToLower()
    if (@('red', 'yellow', 'green') -contains $s) { return $s }
  } catch {}
  return 'green'
}

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.Width = $W
$form.Height = $H
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 30)
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Left = $wa.Right - $W - 24
$form.Top = $wa.Top + 44

$form.Add_Paint({
  param($sender, $e)
  $g = $e.Graphics
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $r = 16
  $cx = $W / 2
  $ys = @(34, [int]($H / 2), ($H - 34))
  $names = @('red', 'yellow', 'green')
  for ($i = 0; $i -lt 3; $i++) {
    $name = $names[$i]
    if ($name -eq $script:state) { $col = $bright[$name] } else { $col = $dim[$name] }
    $brush = New-Object System.Drawing.SolidBrush($col)
    $g.FillEllipse($brush, ($cx - $r), ($ys[$i] - $r), (2 * $r), (2 * $r))
    $brush.Dispose()
  }
})

# Drag to move; double-click to quit.
$script:dragging = $false; $script:dx = 0; $script:dy = 0
$form.Add_MouseDown({
  param($s, $e)
  if ($e.Clicks -ge 2) { $form.Close(); return }
  $script:dragging = $true; $script:dx = $e.X; $script:dy = $e.Y
})
$form.Add_MouseUp({ $script:dragging = $false })
$form.Add_MouseMove({
  param($s, $e)
  if ($script:dragging) {
    $form.Left += ($e.X - $script:dx)
    $form.Top += ($e.Y - $script:dy)
  }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 200
$timer.Add_Tick({
  $ns = Read-State
  if ($ns -ne $script:state) { $script:state = $ns; $form.Invalidate() }
})
$timer.Start()

[System.Windows.Forms.Application]::Run($form)
$mutex.ReleaseMutex()
