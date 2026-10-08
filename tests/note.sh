#!/usr/bin/env bash
# Tests for `outpost note` and the n/np shell functions. Bash + git only.
# Usage: tests/note.sh
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPOST="$ROOT/outpost"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Temporary HOME: init writes the skill and the shell profile there, never in your real home.
export OUTPOST_DATE=2026-10-07 OUTPOST_TIME=14:32 NO_COLOR=1 HOME="$TMP/home" SHELL=/bin/zsh
mkdir -p "$HOME"
PASS=0; FAIL=0

ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/        /'; }
check() { # <name> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1" "expected:
$2
actual:
$3"; fi
}

new_mission() { # -> prints path of a fresh mission
  local m="$TMP/m$RANDOM$RANDOM"
  "$OUTPOST" init "$m" >/dev/null 2>&1
  printf '%s' "$m"
}
fake_crypt() { mkdir -p "$1/notes/.git/git-crypt/keys"; }  # pretend git-crypt is ready

M=$(new_mission); DAILY="$M/notes/daily/2026-10-07.md"
mkdir -p "$M/workspace/some-repo/src"

echo "single note"
(cd "$M/workspace/some-repo/src" && printf 'Decision: keep pagination in the API.\nGain above 10k rows.\n' \
  | "$OUTPOST" note --tags "type/decision, topic/La recherche #x.y") >/dev/null
check "format" '# 2026-10-07

---

<!-- note 14:32 -->
**14:32** · Decision: keep pagination in the API.
Gain above 10k rows.

#type/decision #topic/La #recherche #x-y
<!-- /note -->

---' "$(cat "$DAILY")"

echo "second note shares one separator"
printf 'Second.\n' | (cd "$M" && "$OUTPOST" note) >/dev/null
check "three separators for two notes" "3" "$(grep -c '^---$' "$DAILY" | tr -d ' ')"
check "two notes" "2" "$(grep -c '^<!-- note ' "$DAILY" | tr -d ' ')"
# never two separators with only blank lines between them
DOUBLE=$(awk '/^---$/ { if (prev) bad=1; prev=1; next } /[^[:space:]]/ { prev=0 } END { print bad+0 }' "$DAILY")
check "no double separator" "0" "$DOUBLE"

echo "markdown content is preserved"
M2=$(new_mission); D2="$M2/notes/daily/2026-10-07.md"
(cd "$M2" && "$OUTPOST" note <<'TXT'
Shell: use "quotes", $HOME and `backticks`.

```sh
echo "$HOME"
```
- item
TXT
) >/dev/null
grep -q 'echo "\$HOME"' "$D2" && grep -q 'use "quotes", \$HOME and `backticks`' "$D2" && ok "quotes, \$ and code kept" || fail "quotes, \$ and code kept" "$(cat "$D2")"

echo "refusals leave the file untouched"
BEFORE=$(cat "$D2")
printf 'text\n```sh\nopen block\n' | (cd "$M2" && "$OUTPOST" note) >/dev/null 2>&1 && fail "unclosed fence refused" || ok "unclosed fence refused"
printf 'x <!-- /note --> y\n' | (cd "$M2" && "$OUTPOST" note) >/dev/null 2>&1 && fail "marker in text refused" || ok "marker in text refused"
printf '   \n\n' | (cd "$M2" && "$OUTPOST" note) >/dev/null 2>&1 && fail "empty note refused" || ok "empty note refused"
check "file unchanged" "$BEFORE" "$(cat "$D2")"
printf 'inline ```code``` is fine\n' | (cd "$M2" && "$OUTPOST" note) >/dev/null 2>&1 && ok "inline triple backticks allowed" || fail "inline triple backticks allowed"

echo "first line that is block syntax"
M3=$(new_mission)
printf -- '- a list item\n- another\n' | (cd "$M3" && "$OUTPOST" note) >/dev/null
check "time on its own line" '<!-- note 14:32 -->
**14:32**

- a list item
- another
<!-- /note -->' "$(sed -n '/^<!-- note/,/^<!-- \/note/p' "$M3/notes/daily/2026-10-07.md")"

echo "windows line endings"
M4=$(new_mission)
printf 'line one  \r\nline two\r\n' | (cd "$M4" && "$OUTPOST" note) >/dev/null
check "CR and trailing spaces removed" '**14:32** · line one
line two' "$(sed -n '/^\*\*14:32/,/^line two/p' "$M4/notes/daily/2026-10-07.md")"

echo "hand-written text before a note (no setext heading)"
M7=$(new_mission); D7="$M7/notes/daily/2026-10-07.md"
printf 'freestyle line without trailing newline' >> "$D7"
printf 'after\n' | (cd "$M7" && "$OUTPOST" note) >/dev/null
check "blank line before ---" 'freestyle line without trailing newline

---' "$(grep -B2 -m1 '^---$' "$D7" | grep -v '^# ' | sed '/^$/{N;}' | sed -n '1,3p')"

echo "private notes"
M5=$(new_mission)
printf 'secret\n' | (cd "$M5" && "$OUTPOST" note --private) >/dev/null 2>&1 && fail "refused without git-crypt" || ok "refused without git-crypt"
[ ! -e "$M5/notes/daily/2026-10-07.private.md" ] && ok "no private file created" || fail "no private file created"
fake_crypt "$M5"
printf 'secret\n' | (cd "$M5" && "$OUTPOST" note --private) >/dev/null 2>&1 && ok "allowed when git-crypt is ready" || fail "allowed when git-crypt is ready"
grep -q '^# 2026-10-07 (private)$' "$M5/notes/daily/2026-10-07.private.md" && ok "private header" || fail "private header"
[ ! -e "$M5/notes/daily/2026-10-07.md" ] && ok "public daily untouched" || fail "public daily untouched"

echo "finding the mission"
OUT="$TMP/outside"; mkdir -p "$OUT"
printf 'x\n' | (cd "$OUT" && env -u OUTPOST_NOTES "$OUTPOST" note) >/dev/null 2>&1 && fail "no mission, no OUTPOST_NOTES: error" || ok "no mission, no OUTPOST_NOTES: error"
printf 'via env\n' | (cd "$OUT" && OUTPOST_NOTES="$M3/notes" "$OUTPOST" note) >/dev/null 2>&1 && grep -q 'via env' "$M3/notes/daily/2026-10-07.md" && ok "falls back to \$OUTPOST_NOTES" || fail "falls back to \$OUTPOST_NOTES"
printf 'inside wins\n' | (cd "$M4/workspace" && OUTPOST_NOTES="$M3/notes" "$OUTPOST" note) >/dev/null 2>&1
grep -q 'inside wins' "$M4/notes/daily/2026-10-07.md" && ok "current mission wins over \$OUTPOST_NOTES" || fail "current mission wins over \$OUTPOST_NOTES"

printf 'via default\n' | (cd "$OUT" && env -u OUTPOST_NOTES "$OUTPOST" note --default-notes "$M3/notes") >/dev/null 2>&1 && grep -q 'via default' "$M3/notes/daily/2026-10-07.md" && ok "falls back to --default-notes" || fail "falls back to --default-notes"
printf 'mission wins\n' | (cd "$M4/workspace" && env -u OUTPOST_NOTES "$OUTPOST" note --default-notes "$M3/notes") >/dev/null 2>&1
grep -q 'mission wins' "$M4/notes/daily/2026-10-07.md" && ok "current mission wins over --default-notes" || fail "current mission wins over --default-notes"

echo "n / np shell functions"
M6=$(new_mission); fake_crypt "$M6"
for sh in bash zsh; do
  command -v "$sh" >/dev/null 2>&1 || { echo "  skip  $sh not installed"; continue; }
  rm -f "$M6"/notes/daily/*.md
  ( cd "$M6" && "$sh" -c "source '$M6/_outpost/shell/commands.sh'; n 'hello from $sh'; np 'private from $sh'" ) >/dev/null 2>&1
  grep -q "hello from $sh" "$M6/notes/daily/2026-10-07.md" 2>/dev/null && ok "$sh: n" || fail "$sh: n"
  grep -q "private from $sh" "$M6/notes/daily/2026-10-07.private.md" 2>/dev/null && ok "$sh: np" || fail "$sh: np"
done

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
