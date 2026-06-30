#!/bin/bash
# launch.sh — compile (if needed) and launch the overlay, idempotently.
# Called on SessionStart. No-op on non-macOS or if swiftc is unavailable.
[ "$(uname)" = "Darwin" ] || exit 0

DIR="$HOME/.claude/claude-glance"
mkdir -p "$DIR"
PIDFILE="$DIR/pid"
BIN="$DIR/glance"
SRC="${CLAUDE_PLUGIN_ROOT}/scripts/glance.swift"

# Seed a default state so the overlay shows green on first launch.
[ -f "$DIR/status" ] || printf 'green' > "$DIR/status"

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
exit 0
