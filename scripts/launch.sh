#!/bin/bash
# launch.sh — launch the overlay idempotently on SessionStart.
#   macOS : compile glance.swift (if needed) and run the native binary.
#   Windows (Git Bash / MSYS / Cygwin): launch the PowerShell overlay.
#   Other : no-op.

DIR="$HOME/.claude/claude-glance"
mkdir -p "$DIR"
# Seed a default state so the overlay shows green on first launch.
[ -f "$DIR/status" ] || printf 'green' > "$DIR/status"

case "$(uname -s)" in
  Darwin) OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=win ;;
  *) exit 0 ;;
esac

if [ "$OS" = "mac" ]; then
  PIDFILE="$DIR/pid"
  BIN="$DIR/glance"
  SRC="${CLAUDE_PLUGIN_ROOT}/scripts/glance.swift"

  # Already running? nothing to do.
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    exit 0
  fi

  # Compile if the binary is missing or older than the source.
  if [ ! -x "$BIN" ] || [ "$SRC" -nt "$BIN" ]; then
    command -v swiftc >/dev/null 2>&1 || exit 0
    swiftc -O "$SRC" -o "$BIN" 2>/dev/null || exit 0
  fi

  nohup "$BIN" >/dev/null 2>&1 &

elif [ "$OS" = "win" ]; then
  # Find PowerShell.
  PS=powershell.exe
  command -v "$PS" >/dev/null 2>&1 || PS=powershell
  command -v "$PS" >/dev/null 2>&1 || exit 0

  PS1_U="${CLAUDE_PLUGIN_ROOT}/scripts/glance.ps1"
  # Convert paths to Windows form for PowerShell (cygpath ships with Git Bash).
  PS1_W="$(cygpath -w "$PS1_U" 2>/dev/null || echo "$PS1_U")"
  STATUS_W="$(cygpath -w "$DIR/status" 2>/dev/null || echo "$DIR/status")"

  # glance.ps1 self-enforces a single instance via a named mutex, so it's safe
  # to fire on every SessionStart.
  "$PS" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden \
    -File "$PS1_W" -StatusFile "$STATUS_W" >/dev/null 2>&1 &
fi
exit 0
