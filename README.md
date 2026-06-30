# claude-glance 🚦

Know what Claude Code is doing **at a glance** — a floating **traffic-light overlay** plus **sound alerts**, so you can switch to other windows and still see, from the corner of your eye, exactly what Claude is up to.

| Lamp | Meaning | Sound |
|------|---------|-------|
| 🔴 Red | Waiting for your confirmation (an "allow once / always" prompt) | Glass chime |
| 🟡 Yellow | Running / working on your task | — |
| 🟢 Green | Done, idle, ready for your next message | Tink |

The overlay is a native macOS panel that **floats above every app, on every Space, and over fullscreen apps**, without ever stealing focus.

> **Platform:** macOS only for now (uses Swift/AppKit for the overlay and `afplay` for sounds). On Windows/Linux the plugin installs but stays inactive — cross-platform support is planned.

## Requirements

- macOS
- **Xcode Command Line Tools** (provides `swiftc`). If you don't have them: `xcode-select --install`
- Claude Code

## Install

> ⚠️ **Plugins only work in the terminal CLI version of Claude Code** — not the desktop or web app. If `/plugin` doesn't exist where you type it, see [Troubleshooting](#troubleshooting).

1. Open your terminal and start Claude Code:
   ```bash
   claude
   ```
2. **Inside** the Claude Code prompt (not the shell), run:
   ```
   /plugin marketplace add Harish111/claude-glance
   /plugin install claude-glance@harish-tools
   ```
3. Then **restart Claude Code** (hooks only load at session start). After install you may see `Run /reload-plugins to apply` — `/reload-plugins` works too, but a full restart is the most reliable.

On the first session after install, the overlay's Swift source is compiled once into `~/.claude/claude-glance/` (locally compiled, so no Gatekeeper warning) and launched. It then auto-starts on every session and survives app restarts and reboots.

## Usage

- The light appears in the **top-right corner**.
- **Drag** it anywhere you like.
- **Double-click** it to close it (it'll come back next session).

## How it works

- Claude Code lifecycle **hooks** (`hooks/hooks.json`) write one word — `red`, `yellow`, or `green` — to `~/.claude/claude-glance/status`.
- The overlay (`scripts/glance.swift`) polls that file ~5×/sec and lights the matching lamp.
- `scripts/launch.sh` compiles-if-needed and launches the overlay idempotently on `SessionStart`.

## Uninstall

```
/plugin uninstall claude-glance@harish-tools
```

To also stop the overlay and remove its runtime files:

```bash
pkill -f claude-glance
rm -rf ~/.claude/claude-glance
```

## Troubleshooting

### `/plugin isn't available in this environment`
The plugin system exists **only in the terminal CLI** version of Claude Code. The desktop app and web app (claude.ai/code) don't have it — if you type `/plug` there you'll only see *skills*, no `/plugin` command. Run the install from a terminal instead: open Terminal, run `claude`, then type the `/plugin` commands inside it.

### `command not found: /plugin` (in your shell)
`/plugin` is **not** a shell command. Don't type it at the `zsh`/`bash` prompt. First start Claude Code with `claude`, then type `/plugin …` **inside** the Claude Code prompt.

### Install fails: `Failed to parse marketplace ... claude-plugins-official ... Invalid schema`
This error is about Anthropic's **built-in** marketplace, not claude-glance — but it aborts the whole install. It means your **Claude Code is outdated**: its plugin-schema parser is older than the current official marketplace manifest (you'll see `plugins.N.source: Invalid input`, `Unrecognized key: "displayName"`, etc.).

**Fix — update Claude Code, then retry:**
```bash
claude update
```
If `claude update` isn't supported by your install method, use npm:
```bash
npm install -g @anthropic-ai/claude-code@latest
```
Then start `claude` again and re-run `/plugin install claude-glance@harish-tools` (the marketplace stays added). Tip: `Successfully added marketplace: harish-tools` earlier means *your* part worked — only the outdated parser was blocking.

### Every sound plays twice
You have **two copies** running — e.g. the plugin **and** a manual hooks setup in `~/.claude/settings.json` that calls the same scripts. Keep one. To drop the manual copy, remove the relevant entries from the `hooks` block in `~/.claude/settings.json`; to drop the plugin, `/plugin uninstall claude-glance@harish-tools`.

### No light after install
- Make sure you **restarted** Claude Code (or ran `/reload-plugins`).
- Confirm `swiftc` exists: `xcode-select --install`.
- Check it compiled/launched: `ls ~/.claude/claude-glance/` should contain `glance` (the binary) and `status`. If the binary is missing, compilation failed — run `swiftc -O ~/.claude/plugins/**/scripts/glance.swift -o /tmp/glance` manually to see the error.

### No sound
Check your volume isn't muted. Sounds use macOS system files in `/System/Library/Sounds/` (Glass, Tink) via `afplay`.

### Light shows but doesn't change color
The state file is updated but the overlay may be stale. Confirm one process is running (`pgrep -f glance`), then restart Claude Code so the lifecycle hooks reload.

### It works in the terminal but not in the desktop app
Expected — the desktop app has no plugin system, so the overlay won't run there. (A manual-hooks setup can cover the desktop app, but that's outside this plugin.)

## License

MIT
