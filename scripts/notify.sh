#!/bin/bash
# notify.sh <state> [soundfile]
# Writes the status word the overlay reads, and optionally plays a sound.
# No-op on non-macOS so the plugin is harmless elsewhere.
[ "$(uname)" = "Darwin" ] || exit 0

DIR="$HOME/.claude/claude-glance"
mkdir -p "$DIR"

[ -n "$1" ] && printf '%s' "$1" > "$DIR/status"

if [ -n "$2" ] && command -v afplay >/dev/null 2>&1; then
  afplay "$2" >/dev/null 2>&1 &
fi
exit 0
