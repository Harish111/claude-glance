#!/bin/bash
# notify.sh <state> [mac-soundfile]
# Writes the status word the overlay reads, and optionally plays a sound.
#   macOS : afplay the given sound file.
#   Windows (Git Bash / MSYS / Cygwin): play the matching system sound.
#   Other : just write the state (no sound).

STATE="$1"
MACSOUND="$2"

case "$(uname -s)" in
  Darwin) OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=win ;;
  *) OS=other ;;
esac

DIR="$HOME/.claude/claude-glance"
mkdir -p "$DIR"
[ -n "$STATE" ] && printf '%s' "$STATE" > "$DIR/status"

if [ "$OS" = "mac" ]; then
  if [ -n "$MACSOUND" ] && command -v afplay >/dev/null 2>&1; then
    afplay "$MACSOUND" >/dev/null 2>&1 &
  fi
elif [ "$OS" = "win" ]; then
  # Only alerting states carry a sound (red on the Mac side passes Glass,
  # green passes Tink; yellow passes nothing). Map those to Windows system sounds.
  if [ -n "$MACSOUND" ]; then
    case "$STATE" in
      red)   WSOUND="Exclamation" ;;
      green) WSOUND="Asterisk" ;;
      *)     WSOUND="" ;;
    esac
    if [ -n "$WSOUND" ]; then
      PS=powershell.exe
      command -v "$PS" >/dev/null 2>&1 || PS=powershell
      if command -v "$PS" >/dev/null 2>&1; then
        "$PS" -NoProfile -Command "[System.Media.SystemSounds]::$WSOUND.Play()" >/dev/null 2>&1 &
      fi
    fi
  fi
fi
exit 0
