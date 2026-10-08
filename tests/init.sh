#!/usr/bin/env bash
# Idempotence of `outpost init` (whole state: mission tree, git history, skill, shell profile).
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPOST="$ROOT/outpost"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export NO_COLOR=1 HOME="$TMP/home" SHELL=/bin/zsh; mkdir -p "$HOME"
PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }
t()    { if eval "$2"; then ok "$1"; else fail "$1"; fi; }
ID="GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@b.c GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@b.c"
NOID="GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME= GIT_COMMITTER_NAME= EMAIL="

snapshot() { # mission tree, notes git history, skill and profile
  ( cd "$1" && find . -type f -not -path './notes/.git/*' | LC_ALL=C sort | xargs shasum
    git -C notes log --format='%s' | sort
    git -C notes status --short
    cd "$HOME" && find . -type f | LC_ALL=C sort | xargs shasum )
}

echo "full rerun"
M="$TMP/m1"
env $ID "$OUTPOST" init "$M" --agent claude >/dev/null 2>&1; snapshot "$M" > "$TMP/s1"
env $ID "$OUTPOST" init "$M" --agent claude >/dev/null 2>&1; snapshot "$M" > "$TMP/s2"
t "state identical after a second run" 'diff -q "$TMP/s1" "$TMP/s2" >/dev/null'
OUT=$(env $ID "$OUTPOST" init "$M" 2>&1)
t "reports nothing to do" 'printf "%s" "$OUT" | grep -q "Nothing to do"'
t "notes is clean and committed" '[ -z "$(git -C "$M/notes" status --short)" ] && [ "$(git -C "$M/notes" rev-list --count HEAD)" = 2 ]'

echo "never overwrites"
echo "my own mission text" > "$M/notes/context/mission.md"; echo "mine" > "$M/workspace/README.md"
env $ID "$OUTPOST" init "$M" >/dev/null 2>&1
t "edited files are kept" '[ "$(cat "$M/notes/context/mission.md")" = "my own mission text" ] && [ "$(cat "$M/workspace/README.md")" = mine ]'
rm "$M/notes/people/people.md"
env $ID "$OUTPOST" init "$M" >/dev/null 2>&1
t "a deleted skeleton file is recreated" '[ -f "$M/notes/people/people.md" ]'

echo "failed commit on the first run heals on the next"
M2="$TMP/m2"
env $NOID "$OUTPOST" init "$M2" --no-skill --no-profile >/dev/null 2>&1
t "first run: nothing committed" '! git -C "$M2/notes" rev-parse -q --verify HEAD >/dev/null'
echo mine > "$M2/notes/my-own.md"; git -C "$M2/notes" add my-own.md
env $ID "$OUTPOST" init "$M2" --no-skill --no-profile >/dev/null 2>&1
t "rerun commits the skeleton" '[ "$(git -C "$M2/notes" rev-list --count HEAD)" = 2 ]'
t "your own staged file is not swept in" '! git -C "$M2/notes" ls-tree -r --name-only HEAD | grep -q my-own.md && git -C "$M2/notes" status --short | grep -q "^A  my-own.md"'
env $ID "$OUTPOST" init "$M2" --no-skill --no-profile >/dev/null 2>&1
t "no extra commit on a third run" '[ "$(git -C "$M2/notes" rev-list --count HEAD)" = 2 ]'

echo "agent switch only adds"
env $ID "$OUTPOST" init "$M" --agent copilot >/dev/null 2>&1
t "claude files stay, copilot skill added" '[ -f "$M/notes/CLAUDE.md" ] && [ -f "$HOME/.claude/skills/outpost-note/SKILL.md" ] && [ -f "$HOME/.copilot/skills/outpost-note/SKILL.md" ]'

echo; echo "$PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
