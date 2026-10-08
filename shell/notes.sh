# Outpost quick capture. Add to ~/.bashrc or ~/.zshrc:
#   source /path/to/outpost/shell/notes.sh
#
#   n  "text"   -> note in today's public daily note
#   np "text"   -> same, in today's private daily note
#
# Both call `outpost note`, which finds the mission from the current folder
# (or from $NOTES when you are outside any mission).

if [ -n "${BASH_VERSION:-}" ]; then
  _outpost_src="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  eval '_outpost_src="${(%):-%x}"'
fi
_OUTPOST_BIN="$(cd "$(dirname "$_outpost_src")/.." && pwd)/outpost"
unset _outpost_src

n()  { printf '%s\n' "$*" | "$_OUTPOST_BIN" note; }
np() { printf '%s\n' "$*" | "$_OUTPOST_BIN" note --private; }
