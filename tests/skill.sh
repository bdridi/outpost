#!/usr/bin/env bash
# Tests for the note skill installed by `outpost init`. Never touches the real $HOME.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPOST="$ROOT/outpost"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export NO_COLOR=1 HOME="$TMP/home"; mkdir -p "$HOME"
PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }
t()    { if eval "$2"; then ok "$1"; else fail "$1"; fi; }

echo "claude agent"
M="$TMP/m1"; "$OUTPOST" init --no-profile "$M" --agent claude >/dev/null 2>&1
S="$HOME/.claude/skills/outpost-note/SKILL.md"
t "installed under ~/.claude/skills" '[ -f "$S" ]'
t "placeholder replaced by the real path" 'grep -qF "\"$ROOT/outpost\" note" "$S" && ! grep -q "{{OUTPOST_BIN}}" "$S"'
REAL=$(cd "$M" && pwd -P)
t "notes folder baked in" 'grep -qF -- "--default-notes \"$REAL/notes\"" "$S" && ! grep -q "{{NOTES_DIR}}" "$S"'
t "frontmatter name" 'head -n 2 "$S" | grep -q "^name: outpost-note$"'
t "nothing for copilot" '[ ! -e "$HOME/.copilot" ]'

echo "copilot agent"
M="$TMP/m2"; "$OUTPOST" init --no-profile "$M" --agent copilot >/dev/null 2>&1
t "installed under ~/.copilot/skills" '[ -f "$HOME/.copilot/skills/outpost-note/SKILL.md" ]'

echo "idempotence and ownership"
OUT=$("$OUTPOST" init --no-profile "$M" 2>&1)
t "rerun: up to date" 'printf "%s" "$OUT" | grep -q "note skill: "'
F="$HOME/.copilot/skills/outpost-note/SKILL.md"
printf 'stale\n<!-- managed by outpost -->\n' > "$F"
OUT=$("$OUTPOST" init --no-profile "$M" 2>&1)
t "managed file is updated" 'printf "%s" "$OUT" | grep -q "note skill updated" && grep -q "^name: outpost-note$" "$F"'
printf 'my own version\n' > "$F"
OUT=$("$OUTPOST" init --no-profile "$M" 2>&1)
t "unmanaged file left untouched" '[ "$(cat "$F")" = "my own version" ]'
t "warning shown" 'printf "%s" "$OUT" | grep -q "not managed by outpost"'

echo "dry-run and --no-skill"
rm -rf "$HOME/.claude" "$HOME/.copilot"
"$OUTPOST" init --no-profile skilltest --dry-run --agent claude >/dev/null 2>&1
t "dry-run writes in the fake home" '[ -f "$ROOT/.dry-run/skilltest/.fake-home/.claude/skills/outpost-note/SKILL.md" ]'
t "dry-run leaves the real home alone" '[ -z "$(ls -A "$HOME")" ]'
rm -rf "$ROOT/.dry-run"
"$OUTPOST" init --no-profile "$TMP/m3" --agent claude --no-skill >/dev/null 2>&1
t "--no-skill installs nothing" '[ -z "$(ls -A "$HOME")" ]'

echo; echo "$PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
