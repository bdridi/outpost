#!/usr/bin/env bash
# Tests for `outpost update`: release tags, _outpost/ regeneration, user files kept, idempotence.
# Uses a local upstream repo (no network) and a temporary HOME.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
TMP=$(cd "$TMP" && pwd -P)
export NO_COLOR=1 HOME="$TMP/home" SHELL=/bin/zsh OUTPOST_DATE=2026-10-07 OUTPOST_TIME=14:32; mkdir -p "$HOME"
export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@b.c GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@b.c
PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }
t()    { if eval "$2"; then ok "$1"; else fail "$1"; fi; }

snapshot() { # mission tree, notes git history and status, home
  ( cd "$1" && find . -type f -not -path './notes/.git/*' | LC_ALL=C sort | xargs shasum
    git -C notes log --format='%s' | sort
    git -C notes status --short
    cd "$HOME" && find . -type f | LC_ALL=C sort | xargs shasum )
}
release() { # <version>: commit the upstream working tree and tag it
  sed -i.bak "s/^VERSION=.*/VERSION=\"$1\"/" "$SRC/outpost" && rm -f "$SRC/outpost.bak"
  git -C "$SRC" add -A && git -C "$SRC" commit -q -m "release $1" && git -C "$SRC" tag "v$1"
}

# Upstream: a copy of this working tree, released as v1.0.0.
SRC="$TMP/upstream"; mkdir -p "$SRC"
(cd "$ROOT" && git ls-files -co --exclude-standard | while IFS= read -r f; do
  [ -e "$f" ] || continue; mkdir -p "$SRC/$(dirname "$f")"; cp -p "$f" "$SRC/$f"; done)
git -C "$SRC" init -q -b main && release 1.0.0

# Install clone, pinned on the tag (detached HEAD), as the README says.
INST="$TMP/install"; git clone -q --branch v1.0.0 "$SRC" "$INST" 2>/dev/null
O="$INST/outpost"

echo "init at v1.0.0"
M="$TMP/mission"; "$O" init "$M" --agent claude --no-profile >/dev/null 2>&1
t "_outpost/ created with its version" '[ "$(cat "$M/_outpost/VERSION")" = 1.0.0 ]'
t "skill rendered in _outpost and copied to the home" 'cmp -s "$M/_outpost/skills/outpost-note/SKILL.md" "$HOME/.claude/skills/outpost-note/SKILL.md" && ! grep -q "{{" "$HOME/.claude/skills/outpost-note/SKILL.md"'
t "foam template generated from daily.md" '[ "$(head -n1 "$M/notes/.foam/templates/daily-note.md")" = "# \${FOAM_DATE_YEAR}-\${FOAM_DATE_MONTH}-\${FOAM_DATE_DATE}" ]'
t "relays point to _outpost" 'grep -q "_outpost/notes/AGENTS.md" "$M/notes/AGENTS.md" && grep -q "^@../_outpost/notes/AGENTS.md$" "$M/notes/CLAUDE.md"'
t "hook is the relay" 'grep -q "_outpost/notes/hooks/pre-commit" "$M/notes/.git/hooks/pre-commit"'
t "--no-profile saved" 'grep -q "^profile=0$" "$M/.outpost.conf"'

# User state.
echo "my mission" > "$M/notes/context/mission.md"
printf 'my note\n' | (cd "$M" && "$O" note) >/dev/null
echo "secret" > "$M/notes/topics/x.private.md"
echo "mine" > "$M/workspace/README.md"
git -C "$M/notes" add daily && git -C "$M/notes" commit -q -m "my daily" -- daily
BEFORE_USER=$(cd "$M" && shasum notes/context/mission.md notes/daily/2026-10-07.md notes/topics/x.private.md workspace/README.md)

echo "release v1.1.0, then update"
printf '\nRule added in 1.1.\n' >> "$SRC/templates/_outpost/notes/AGENTS.md"
printf '# {{date}}\n\nDaily layout 1.1\n' > "$SRC/templates/_outpost/notes/templates/daily.md"
mkdir -p "$SRC/templates/notes/retro" && touch "$SRC/templates/notes/retro/.gitkeep"
release 1.1.0
OUT=$(cd "$M/workspace" && "$O" update 2>&1)
t "clone moved to the new tag" '[ "$(git -C "$INST" describe --tags)" = v1.1.0 ]'
t "new version announced" 'printf "%s" "$OUT" | grep -q "v1.0.0 -> v1.1.0"'
t "_outpost/ regenerated" '[ "$(cat "$M/_outpost/VERSION")" = 1.1.0 ] && grep -q "Rule added in 1.1" "$M/_outpost/notes/AGENTS.md"'
t "no leftover build folder" '[ ! -e "$M/_outpost.new" ]'
t "foam template follows daily.md" 'grep -q "Daily layout 1.1" "$M/notes/.foam/templates/daily-note.md"'
t "new user folder added" '[ -f "$M/notes/retro/.gitkeep" ]'
t "user files untouched" '[ "$(cd "$M" && shasum notes/context/mission.md notes/daily/2026-10-07.md notes/topics/x.private.md workspace/README.md)" = "$BEFORE_USER" ]'
t "one commit, outpost files only" '[ "$(git -C "$M/notes" log -1 --format=%s)" = "outpost: notes v1.1.0" ] && [ "$(git -C "$M/notes" show --name-only --format= HEAD | LC_ALL=C sort | tr "\n" " ")" = ".foam/templates/daily-note.md retro/.gitkeep " ]'
t "your pending edits stay uncommitted" 'git -C "$M/notes" status --short | grep -q "context/mission.md"'
t "saved --no-profile respected" '[ ! -e "$HOME/.zshrc" ]'
t "next notes use the new daily layout" '[ "$(cd "$M" && OUTPOST_DATE=2026-10-08 "$O" note <<< x >/dev/null; sed -n 3p "$M/notes/daily/2026-10-08.md")" = "Daily layout 1.1" ]'

echo "idempotence"
snapshot "$M" > "$TMP/s1"
OUT=$(cd "$M" && "$O" update 2>&1)
snapshot "$M" > "$TMP/s2"
t "second update changes nothing" 'diff -q "$TMP/s1" "$TMP/s2" >/dev/null'
t "reports nothing to do" 'printf "%s" "$OUT" | grep -q "Nothing to do"'
t "clone stays on the tag" '[ "$(git -C "$INST" describe --tags)" = v1.1.0 ]'

echo "the tool only moves when it is safe"
printf '# {{date}}\n\nDaily layout 1.2\n' > "$SRC/templates/_outpost/notes/templates/daily.md"; release 1.2.0
echo x > "$INST/local-change"
OUT=$(cd "$M" && "$O" update 2>&1)
t "local changes: clone not moved" '[ "$(git -C "$INST" describe --tags)" = v1.1.0 ] && printf "%s" "$OUT" | grep -q "local changes"'
rm "$INST/local-change"
OUT=$(cd "$M" && "$O" update --no-fetch 2>&1)
t "--no-fetch: clone not moved" '[ "$(git -C "$INST" describe --tags)" = v1.1.0 ]'
git -C "$INST" remote set-url origin "$TMP/nowhere"
OUT=$(cd "$M" && "$O" update 2>&1)
t "offline: warning, mission still refreshed" 'printf "%s" "$OUT" | grep -q "could not fetch" && printf "%s" "$OUT" | grep -q "Nothing to do"'
git -C "$INST" remote set-url origin "$SRC"
DEV="$TMP/dev"; git clone -q "$SRC" "$DEV"
OUT=$(cd "$M" && "$DEV/outpost" update 2>&1)
t "dev clone on a branch: not moved, mission refreshed from it" 'printf "%s" "$OUT" | grep -q "dev clone" && grep -q "Daily layout 1.2" "$M/_outpost/notes/templates/daily.md"'

echo "dry-run"
"$O" init demo --dry-run >/dev/null 2>&1
OUT=$("$O" update demo --dry-run 2>&1)
t "update works on a dry-run mission" 'printf "%s" "$OUT" | grep -q "update \[dry-run\]" && [ -f "$INST/.dry-run/demo/_outpost/VERSION" ]'
t "dry-run never moves the clone" '[ "$(git -C "$INST" describe --tags)" = v1.1.0 ]'
OUT=$(cd "$INST/.dry-run/demo/notes" && "$O" update 2>&1)
t "found from inside a dry-run mission" 'printf "%s" "$OUT" | grep -q "update \[dry-run\]"'
t "real home untouched by dry-run" '[ ! -e "$HOME/.copilot" ]'

echo "mission from before _outpost/"
L="$TMP/legacy"; "$O" init "$L" --no-skill --no-profile >/dev/null 2>&1
rm -rf "$L/_outpost"
mkdir -p "$L/notes/templates"; echo "# {{date}} (my old template)" > "$L/notes/templates/daily.md"
echo "# old conventions" > "$L/notes/AGENTS.md"
git -C "$SRC" show v1.0.0:templates/_outpost/notes/hooks/pre-commit > "$L/notes/.git/hooks/pre-commit"
OUT=$(cd "$L" && "$O" update --no-fetch 2>&1)
t "_outpost/ created" '[ -f "$L/_outpost/VERSION" ]'
t "old files kept" '[ -f "$L/notes/templates/daily.md" ] && [ "$(cat "$L/notes/AGENTS.md")" = "# old conventions" ]'
t "old files reported" 'printf "%s" "$OUT" | grep -q "notes/templates/ is no longer used" && printf "%s" "$OUT" | grep -q "notes/AGENTS.md predates _outpost"'
t "old hook switched to the relay" 'grep -q "_outpost/notes/hooks/pre-commit" "$L/notes/.git/hooks/pre-commit"'

echo "hook relay fails closed"
rm -rf "$L/_outpost"; echo y > "$L/notes/y.md"; git -C "$L/notes" add y.md
t "commit blocked without _outpost/" '! git -C "$L/notes" commit -q -m y 2>/dev/null'
(cd "$L" && "$O" update --no-fetch >/dev/null 2>&1)
t "commit allowed again after update" 'git -C "$L/notes" commit -q -m y'

echo "a foreign _outpost/ is never replaced"
F="$TMP/foreign"; mkdir -p "$F/_outpost"; echo mine > "$F/_outpost/file"
"$O" init "$F" --no-skill --no-profile >/dev/null 2>&1 && fail "init refused" || ok "init refused"
t "nothing created, folder untouched" '[ "$(cat "$F/_outpost/file")" = mine ] && [ ! -e "$F/notes" ] && [ ! -e "$F/workspace" ]'

echo; echo "$PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
