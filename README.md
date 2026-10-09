<div align="center">

# 🛰️ Outpost

**A one-command workspace for client missions.**
A fixed folder layout and a private-by-design notes system, set up in seconds on any client machine.

![bash](https://img.shields.io/badge/bash-only-4EAA25?logo=gnubash&logoColor=white)
![git](https://img.shields.io/badge/git-required-F05032?logo=git&logoColor=white)
![git-crypt](https://img.shields.io/badge/git--crypt-optional-blue)
![dependencies](https://img.shields.io/badge/dependencies-none-success)

</div>

---

## ✨ What it does

Outpost is a **generic template and script**. On a fresh client machine, one command gives you:

- 📁 a **mission folder layout**, organized by the *origin* of each file
- 📝 a **notes system** (VS Code + [Foam](https://foambubble.github.io/foam/)) with daily capture, templates and agent conventions
- 🔐 **private notes** encrypted with git-crypt, guarded by a pre-commit hook
- 🤖 a setup ready for a local agent (**Copilot** or **Claude Code**)

> It contains no client name, no mission content, nothing client-specific. Ever.

## 🗂️ Layout

```
<mission-root>/
├── 🛰️ _outpost/    managed by Outpost: conventions, templates, skill, hook (see Update)
├── 📝 notes/       notes system (own git repo, see below)
├── 💻 workspace/   clones of the client's repos, nothing else
├── 📥 resources/   documents provided by the client, read-only
├── 📤 outbox/      non-code work I write for the client
└── 🧪 sandbox/     POCs, throwaway scripts, experiments
```

Folders follow the **origin** of a file (client, me, code, experiment), not its topic.
That tells you at a glance what may leave the machine. Code you deliver is commits and PRs
in `workspace/`; `outbox/` is for everything that is not code.

| | Rule |
|---|------|
| 1️⃣ | When in doubt → `sandbox/`. |
| 2️⃣ | Never two copies of a document: link to it from `notes/`. |
| 3️⃣ | End of mission: everything stays on the client machine. Only `notes/retro.md` leaves. |

## 🚀 Install

Clone a **release tag**, not `main`, outside the mission root:

```sh
git clone --branch v0.2.0 https://github.com/bdridi/outpost.git ~/outpost
```

The clone stays on that tag (detached HEAD): nothing changes until you run `outpost update`.
Requirements: `bash` and `git`. Add [`git-crypt`](https://github.com/AGWA/git-crypt) for the private notes.
On Windows, everything runs in **Git Bash** (see [Windows](#-windows)).
No submodule, no remote linking a mission to this repo.

The first `init` is called with the clone's path, since nothing is installed yet:

```sh
~/outpost/outpost init ~/missions/<client>
```

After that, `outpost` works from any new terminal: the shell profile block (see
[Quick capture](#-quick-capture)) defines it, with no symlink and no `PATH` change.

## 🧭 Usage

```sh
outpost init [path] [--agent copilot|claude] [--dry-run] [--verbose] [--no-skill] [--no-profile]
```

| Option | Effect |
|--------|--------|
| `path` | Mission root (default: current directory) |
| `--agent` | Local agent for the notes, default `copilot`: where the note skill is installed (see [Capture from your agent](#-capture-from-your-agent)). Saved in `<mission-root>/.outpost.conf`, outside the client git, and reused on re-runs and updates |
| `--dry-run` | `path` becomes a folder **name** created under `.dry-run/` (gitignored). No absolute path, no `..` |
| `--verbose` | List every created file |
| `--no-profile` | Do not touch your shell profile (see [Quick capture](#-quick-capture)). Saved, so `update` keeps it |
| `--no-skill` | Do not install the note skill (see [Capture from your agent](#-capture-from-your-agent)). Saved as well |

`init` is **idempotent**: in your folders it creates what is missing and never overwrites anything;
`_outpost/` is regenerated as a whole.

### 🛰️ What `init` puts in `_outpost/`

Everything Outpost owns lives in one folder at the mission root, next to `notes/` and the others:

```
_outpost/
├── VERSION                      the release that wrote it
├── notes/AGENTS.md              conventions for agents
├── notes/templates/             daily, daily.private, decision, topic, guide
├── notes/hooks/pre-commit       the private-file check
├── prompts/weekly-review.md     the Friday review prompt
├── shell/commands.sh            outpost, n and np, sourced by your shell profile
└── skills/outpost-note/         the note skill, with this mission's paths filled in
```

Do not edit it: `outpost update` replaces it. It is not in any git repo; it can always be rebuilt
from the clone.

### 📝 What `init` sets up in `notes/`

- 🔧 its own git repo, with a `pre-commit` hook that blocks any `*.private.md` that is not encrypted
  (a relay to `_outpost/notes/hooks/pre-commit`, so `update` refreshes it; if that file is
  missing, every commit is blocked)
- 🔐 git-crypt initialized, with `.gitattributes` committed **before** any private file
- 📚 `context/` `daily/` `topics/` `decisions/` `guides/` `people/`
- 🤖 `AGENTS.md` (read by Copilot) and `CLAUDE.md` (read by Claude Code): yours, they point to
  `../_outpost/notes/AGENTS.md`
  and you can add mission rules below
- 🗒️ `.vscode/settings.json`, and the Foam daily-note template, generated from
  `_outpost/notes/templates/daily.md` so that Foam and `n` create the same daily note

No `git-crypt`? Init still works: private templates are skipped, the hook blocks private files,
and re-running `outpost init` after installing it completes the setup.

## 🔄 Update

When a new release is out, run from anywhere inside the mission (or pass its path):

```sh
outpost update [path] [--dry-run] [--no-fetch] [--verbose]
```

1. **The tool**: the clone fetches the release tags and checks out the latest one, then the new
   version takes over. It does not move if the clone is on a branch (a dev clone), has local
   changes, or cannot reach GitHub: you get a warning and the mission is refreshed with the
   version you have. `--no-fetch` skips this step.
2. **The mission**, through the same code as `init`:
   - `_outpost/` is rebuilt and swapped in as a whole;
   - your folders only get **additions** (a new folder, a new skeleton file): nothing of yours is
     overwritten, renamed or deleted, private files included;
   - the Foam daily-note template, the hook, the note skill and the shell profile block are
     refreshed (choices saved in `.outpost.conf` are kept);
   - in `notes/`, only Outpost's files are committed (`outpost: notes vX.Y.Z`), never your
     pending edits.

Running it twice changes nothing the second time. To go back to a previous release:

```sh
git -C ~/outpost checkout v0.2.0 && outpost update --no-fetch
```

**Missions created before `_outpost/` (v0.1.0)**: the first update creates `_outpost/` and keeps
everything else. It warns about what you can clean up by hand: `notes/templates/` (no longer
used), and an `AGENTS.md` / `CLAUDE.md` that still holds the old conventions instead of pointing to
`../_outpost/notes/AGENTS.md`.

### 🏷️ Releasing (for maintainers)

```sh
# bump VERSION="X.Y.Z" in ./outpost, then
git commit -am "release X.Y.Z" && git tag vX.Y.Z && git push && git push --tags
```

Rule for a release: in the user folders, only **add** (folders, skeleton files). Never rename or
remove: if the layout must change, add the new place, keep the old one, and say so in the release
notes. Anything Outpost must be able to change later belongs in `templates/_outpost/`.

## ⚡ Quick capture

`init` adds a block to your shell profile (`~/.zshrc`, or `~/.bash_profile` on macOS / `~/.bashrc`
elsewhere for bash),
so `OUTPOST_NOTES`, `outpost`, `n` and `np` are available in every new terminal:

```sh
# >>> outpost >>> (managed by outpost: re-running init rewrites this block)
export OUTPOST_NOTES='/path/to/mission/notes'
source '/path/to/mission/_outpost/shell/commands.sh'
# <<< outpost <<<
```

Only the lines between the markers belong to Outpost; the rest of the file is never touched, and a
re-run rewrites the block in place (the last initialized mission wins). Other shells get the two lines
to add by hand, and `--no-profile` skips all of it.

```sh
outpost update     # the outpost command of the clone that set up the mission
n  "text"          # note in today's public daily note
np "text"          # same, in today's private daily note
```

They are shell functions from `_outpost/shell/commands.sh`, so they exist in interactive shells
only; scripts call the clone's `outpost` by its path (the note skill does).

In VS Code with Foam, `Alt+D` opens today's daily note.

## 🤖 Capture from your agent

Mid-conversation with Copilot or Claude Code, say *"note ça"* (or *"note this in the daily"*).
The agent drafts the note from the conversation (reformulated, with context), proposes tags and asks
**public or private**. Once you validate, it writes it to today's daily note, without leaving the
session and without you switching to a terminal.

`init` renders one skill (`outpost-note`, the open `SKILL.md` format) in `_outpost/skills/` and copies
it to your **user folder**, where agents look for skills: `~/.claude/skills/` for Claude Code,
`~/.copilot/skills/` for Copilot. Together with the shell profile block, it is the only
thing `init` writes outside the mission root, and `--no-skill` skips it. The file carries a
`managed by outpost` marker: `init` and `update` refresh it while the marker is there, and leaves it alone once you
remove it (or if a file of yours already exists).

Under the hood the skill calls `outpost note`, which finds the mission from the current folder:

```sh
outpost note [--private] [--tags "type/idea topic/search"] <<'EOF'
Text, Markdown allowed.
EOF
```

`n` and `np` use the same command, so every capture has the same shape:

```markdown
---

<!-- note 14:32 -->
**14:32** · Text, Markdown allowed.

#type/decision #topic/search
<!-- /note -->

---
```

One `---` between notes, explicit start and end markers for the weekly review, tags optional with an
open vocabulary. You can still write freely in the daily note by hand; the review handles both.
The command refuses an empty note, an unclosed code fence, a note marker inside the text, and a
private note when git-crypt is not ready.

## 📅 Weekly review

The review reads the structured notes, free text and old `- HH:MM` lines, and skips what is already linked
(`→ [[note]]`). Launched **manually** on Fridays (no scheduler, nothing leaves the machine):

1. Open your agent (Copilot or Claude Code) in `<mission-root>/notes/`.
2. Ask it to follow `../_outpost/prompts/weekly-review.md`
   ([source](templates/_outpost/prompts/weekly-review.md)).

The agent promotes the week's captures on a `review/<year>-W<week>` branch, commits and stops.
You review the branch and merge it yourself.

## 🔐 Private notes (git-crypt)

After `init`, back up the key outside the repo (password manager), then delete the export:

```sh
cd notes && git-crypt export-key /tmp/notes.key
```

Unlock on a new machine:

```sh
git clone <client-git>/notes.git && cd notes
git-crypt unlock /path/to/notes.key
```

Rules: a file is born private (never rename public → private); private content only goes
in `*.private.md`; links go private → public only; use neutral file names.

## ✅ Check before starting a mission

- [ ] Foam extension allowed in VS Code
- [ ] `git-crypt` installable, and encrypted content accepted by the client's security on their git
- [ ] The local agent that runs the weekly review is allowed on the client machine
- [ ] On Windows: Git for Windows installed (it provides Git Bash)

## 🪟 Windows

Outpost runs in **Git Bash**, the bash that comes with [Git for Windows](https://gitforwindows.org/).
Same script, same commands, nothing to pass: `init` detects Windows by itself. Run every command
(`outpost`, `n`, `np`) from a Git Bash terminal, with `/c/Users/...` style paths.

- **Shell profile**: the block goes to `~/.bashrc`. Git Bash is a login shell and reads
  `~/.bash_profile`, so `init` creates one that loads `~/.bashrc` when you have none; if yours does
  not load it, you get a warning and the line to add.
- **VS Code**: new missions set Git Bash as the default terminal in `notes/.vscode/settings.json`,
  so Copilot runs the note skill in Git Bash. If you open VS Code on another folder, set
  `"terminal.integrated.defaultProfile.windows": "Git Bash"` in your user settings.
  Claude Code already uses Git Bash on Windows.
- **git-crypt**: download the Windows build (`git-crypt-*.exe`) from the
  [releases](https://github.com/AGWA/git-crypt/releases), rename it `git-crypt.exe` and put it in a
  folder on your `PATH` (for example `~/bin`).
- **`outpost update` while VS Code is open**: if a file of `_outpost/` is open, Windows refuses to
  replace the folder. The previous version is kept whole and you get a warning: close it, re-run.

## 🧪 Dry run

```sh
./outpost init my-test --dry-run [--agent claude]
./outpost update my-test --dry-run      # or plain `outpost update` from inside .dry-run/my-test
```

Generates the full instance in `.dry-run/my-test` so you can inspect it, with the skill and shell
profile written to `.dry-run/my-test/.fake-home` instead of your home. `update --dry-run` refreshes
it from your working copy and never moves the clone, so you can try a template change before
releasing it. Re-running is idempotent; reset with `rm -rf .dry-run/my-test`.

## 🧪 Tests

```sh
tests/init.sh     # idempotence of init, your files never overwritten
tests/update.sh   # update: release tags, _outpost/ regenerated, user files kept, idempotence
tests/note.sh     # outpost note, n / np
tests/skill.sh    # skill installation (uses a temporary HOME, never your real one)
tests/profile.sh  # shell profile block (temporary HOME as well)
```

None of them uses the network or your real home: `update.sh` publishes releases from a local copy
of this repo. The Windows paths are covered with `OUTPOST_OS=windows` (it overrides the detection),
and CI runs the whole suite on Linux, macOS and Windows (Git Bash).

## 🛣️ Later

- `outpost review`: helper for the Friday review
- `outpost close`: end-of-mission checklist (retro, nothing confidential leaves)
