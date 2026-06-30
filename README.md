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

In Claude Code:

```
/plugin marketplace add Harish111/claude-glance
/plugin install claude-glance@harish-tools
```

Then **restart Claude Code** (hooks only load at session start).

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

- **No light after install** → make sure you **restarted** Claude Code, and that `swiftc` exists (`xcode-select --install`).
- **No sound** → check your volume isn't muted; sounds use macOS system files in `/System/Library/Sounds/`.
- **Light doesn't change** → confirm the plugin is enabled (`/plugin`), then restart.

## License

MIT
