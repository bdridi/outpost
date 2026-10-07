# Outpost quick capture. Add to ~/.bashrc or ~/.zshrc:
#   export NOTES=/path/to/mission/notes
#   source /path/to/outpost/shell/notes.sh
#
#   n  "text"   -> "- HH:MM text" in today's public daily note
#   np "text"   -> same, in today's private daily note

_notes_append() { # $1 = "" or ".private", $2 = text
  if [ -z "${NOTES:-}" ] || [ ! -d "$NOTES" ]; then
    echo "NOTES must point to the notes folder" >&2; return 1
  fi
  if [ -z "$2" ]; then echo "usage: n[p] \"text\"" >&2; return 1; fi
  _d=$(date +%F); _f="$NOTES/daily/$_d$1.md"
  mkdir -p "$NOTES/daily"
  if [ ! -f "$_f" ]; then
    if [ -f "$NOTES/templates/daily$1.md" ]; then
      sed "s/{{date}}/$_d/g" "$NOTES/templates/daily$1.md" > "$_f"
    else
      printf '# %s\n\n' "$_d" > "$_f"
    fi
  fi
  printf -- '- %s %s\n' "$(date +%H:%M)" "$2" >> "$_f"
}
n()  { _notes_append ""         "$*"; }
np() { _notes_append ".private" "$*"; }
