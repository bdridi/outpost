# Outpost shell commands, sourced by the outpost block of your shell profile:
#   source <mission>/_outpost/shell/commands.sh
#
#   outpost ... -> the outpost command of the clone that set up this mission
#   n  "text"   -> note in today's public daily note
#   np "text"   -> same, in today's private daily note
#
# Notes go to the mission around the current folder, or to $OUTPOST_NOTES outside any mission.
# Managed by outpost: `outpost update` regenerates this file.

_OUTPOST_BIN={{OUTPOST_BIN_QUOTED}}

outpost() { "$_OUTPOST_BIN" "$@"; }
n()  { printf '%s\n' "$*" | "$_OUTPOST_BIN" note; }
np() { printf '%s\n' "$*" | "$_OUTPOST_BIN" note --private; }
