#!/usr/bin/env bash
# Tests for the shell-profile block written by `outpost init`. Uses a temporary HOME.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPOST="$ROOT/outpost"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export NO_COLOR=1 HOME="$TMP/home"; mkdir -p "$HOME"
PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }
t()    { if eval "$2"; then ok "$1"; else fail "$1"; fi; }
init() { "$OUTPOST" init "$@" >/dev/null 2>&1; }

echo "zsh: new profile"
export SHELL=/bin/zsh
M="$TMP/m1"; init "$M" --no-skill
RC="$HOME/.zshrc"; REAL=$(cd "$M" && pwd -P)
t "created" '[ -f "$RC" ]'
t "exports OUTPOST_NOTES" 'grep -qF "export OUTPOST_NOTES='"'"'$REAL/notes'"'"'" "$RC"'
t "sources the mission's commands.sh" 'grep -qF "source '"'"'$REAL/_outpost/shell/commands.sh'"'"'" "$RC"'
t "commands.sh calls this clone's binary" 'grep -qF "_OUTPOST_BIN='"'"'$ROOT/outpost'"'"'" "$REAL/_outpost/shell/commands.sh"'

echo "the block works in a real shell"
if command -v zsh >/dev/null 2>&1; then
  OUT=$(zsh -c "source '$RC'; echo \$OUTPOST_NOTES; type n >/dev/null && type np >/dev/null && echo fns")
  t "zsh gets OUTPOST_NOTES, n and np" '[ "$OUT" = "$REAL/notes
fns" ]'
else
  echo "  skip  zsh not installed"
fi
OUT=$(bash -c "source '$RC'; cd /; outpost --version")
t "outpost works from anywhere" '[ "$OUT" = "$("$OUTPOST" --version)" ]'
OUT=$(bash -c "source '$RC'; echo \$OUTPOST_NOTES; type n >/dev/null && type np >/dev/null && echo fns")
t "bash gets OUTPOST_NOTES, n and np" '[ "$OUT" = "$REAL/notes
fns" ]'

echo "idempotence and respect for the rest of the file"
printf 'alias ll="ls -l"\n' > "$RC.new"; cat "$RC" >> "$RC.new"; printf 'export AFTER=1\n' >> "$RC.new"; mv "$RC.new" "$RC"
BEFORE=$(cat "$RC"); init "$M" --no-skill
t "rerun changes nothing" '[ "$(cat "$RC")" = "$BEFORE" ]'
t "one block only" '[ "$(grep -c "^# >>> outpost" "$RC")" = 1 ]'
M2="$TMP/m2"; init "$M2" --no-skill; REAL2=$(cd "$M2" && pwd -P)
t "new mission rewrites the block in place" 'grep -qF "$REAL2/notes" "$RC" && ! grep -qF "$REAL/notes" "$RC"'
t "lines before and after are kept" 'grep -q "^alias ll=" "$RC" && grep -q "^export AFTER=1$" "$RC" && [ "$(tail -n1 "$RC")" = "export AFTER=1" ]'

echo "paths with a quote"
Q="$TMP/it's here"; QOUT=$("$OUTPOST" init "$Q" --no-skill 2>&1); QRC=$?; RQ=$(cd "$Q" && pwd -P)
OUT=$(bash -c "source '$RC'; echo \$OUTPOST_NOTES" 2>&1)
t "quoted safely" '[ "$OUT" = "$RQ/notes" ]'
[ "$OUT" = "$RQ/notes" ] || printf '        want %s\n        got  %s\n' "$RQ/notes" "$OUT"; printf '        init exit %s:\n%s\n' "$QRC" "$QOUT"

echo "bash and unsupported shells"
rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"
SHELL=/bin/bash init "$TMP/m4" --no-skill
t "bash profile written" '[ -f "$HOME/.bashrc" ] || [ -f "$HOME/.bash_profile" ]'
rm -f "$HOME/.bashrc" "$HOME/.bash_profile"
OUT=$(SHELL=/usr/bin/fish "$OUTPOST" init "$TMP/m5" --no-skill 2>&1)
t "fish: nothing written" '[ -z "$(ls -A "$HOME")" ]'
t "fish: manual lines shown" 'printf "%s" "$OUT" | grep -q "export OUTPOST_NOTES="'

echo "windows (Git Bash)"
rm -rf "$HOME"; mkdir -p "$HOME"
OUTPOST_OS=windows SHELL=/usr/bin/bash init "$TMP/w1" --no-skill; RW=$(cd "$TMP/w1" && pwd -P)
t "block in .bashrc" 'grep -qF "$RW/notes" "$HOME/.bashrc"'
t ".bash_profile created, loads .bashrc" 'grep -qF ". ~/.bashrc" "$HOME/.bash_profile"'
OUT=$(bash --login -c 'echo "$OUTPOST_NOTES"; type n >/dev/null && echo fns' 2>/dev/null | tail -n 2)
t "a login shell gets OUTPOST_NOTES and n" '[ "$OUT" = "$RW/notes
fns" ]'
B=$(cat "$HOME/.bash_profile" "$HOME/.bashrc")
OUTPOST_OS=windows SHELL=/usr/bin/bash init "$TMP/w1" --no-skill
t "rerun changes nothing" '[ "$(cat "$HOME/.bash_profile" "$HOME/.bashrc")" = "$B" ]'
rm -rf "$HOME"; mkdir -p "$HOME"; printf 'export MINE=1\n' > "$HOME/.bash_profile"
OUT=$(OUTPOST_OS=windows SHELL=/usr/bin/bash "$OUTPOST" init "$TMP/w3" --no-skill 2>&1)
t "own .bash_profile untouched" '[ "$(cat "$HOME/.bash_profile")" = "export MINE=1" ]'
t "warns that it does not load .bashrc" 'printf "%s" "$OUT" | grep -q "does not load ~/.bashrc"'
OUT=$(OUTPOST_OS=windows "$OUTPOST" init 'C:/missions/x' --dry-run 2>&1)
t "dry-run refuses a drive path" 'printf "%s" "$OUT" | grep -q "relative folder name"'
rm -rf "$HOME"; mkdir -p "$HOME"

echo "dry-run and --no-profile"
DRY="test-profile-$$"  # own name: never touch your own .dry-run/ missions
init "$DRY" --dry-run
t "dry-run uses the fake home" '[ -f "$ROOT/.dry-run/$DRY/.fake-home/.zshrc" ]'
t "real home untouched" '[ -z "$(ls -A "$HOME")" ]'
rm -rf "$ROOT/.dry-run/$DRY"; rmdir "$ROOT/.dry-run" 2>/dev/null
init "$TMP/m6" --no-skill --no-profile
t "--no-profile writes nothing" '[ -z "$(ls -A "$HOME")" ]'

echo "unterminated block is left alone"
printf '# >>> outpost >>> broken\nexport X=1\n' > "$HOME/.zshrc"; B=$(cat "$HOME/.zshrc")
init "$TMP/m7" --no-skill
t "file untouched" '[ "$(cat "$HOME/.zshrc")" = "$B" ]'

echo; echo "$PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
