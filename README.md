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

```sh
git clone https://github.com/bdridi/outpost.git ~/outpost   # outside the mission root
```

Requirements: `bash` and `git`. Add [`git-crypt`](https://github.com/AGWA/git-crypt) for the private notes.
No submodule, no remote linking a mission to this repo.

Optional, to call it from anywhere (the script resolves symlinks to find its templates):

```sh
ln -s ~/outpost/outpost ~/.local/bin/outpost
```

## 🧭 Usage

```sh
outpost init [path] [--agent copilot|claude] [--dry-run] [--verbose] [--no-skill] [--no-profile]
```

| Option | Effect |
|--------|--------|
| `path` | Mission root (default: current directory) |
| `--agent` | Local agent for the notes, default `copilot`. `claude` also adds `notes/CLAUDE.md` (it imports `AGENTS.md`). Saved in `<mission-root>/.outpost.conf`, outside the client git, and reused on re-runs |
| `--dry-run` | `path` becomes a folder **name** created under `.dry-run/` (gitignored). No absolute path, no `..` |
| `--verbose` | List every created file |
| `--no-profile` | Do not touch your shell profile (see [Quick capture](#-quick-capture)) |
| `--no-skill` | Do not install the note skill (see [Capture from your agent](#-capture-from-your-agent)) |

`init` is **idempotent**: it creates what is missing and never overwrites anything.

### 📝 What `init` sets up in `notes/`

- 🔧 its own git repo, with a `pre-commit` hook that blocks any `*.private.md` that is not encrypted
- 🔐 git-crypt initialized, with `.gitattributes` committed **before** any private file
- 📚 `context/` `daily/` `topics/` `decisions/` `guides/` `people/` `templates/`
- 🤖 `AGENTS.md` (conventions for agents), `.vscode/settings.json`, the Foam daily-note template

No `git-crypt`? Init still works: private templates are skipped, the hook blocks private files,
and re-running `outpost init` after installing it completes the setup.

## ⚡ Quick capture

`init` adds a block to your shell profile (`~/.zshrc`, or `~/.bash_profile` / `~/.bashrc` for bash),
so `NOTES`, `n` and `np` are available in every new terminal:

```sh
# >>> outpost >>> (managed by outpost: re-running init rewrites this block)
export NOTES='/path/to/mission/notes'
source '/path/to/outpost/shell/notes.sh'
# <<< outpost <<<
```

Only the lines between the markers belong to Outpost; the rest of the file is never touched, and a
re-run rewrites the block in place (the last initialized mission wins). Other shells get the two lines
to add by hand, and `--no-profile` skips all of it.

```sh
n  "text"    # note in today's public daily note
np "text"    # same, in today's private daily note
```

In VS Code with Foam, `Alt+D` opens today's daily note.

## 🤖 Capture from your agent

Mid-conversation with Copilot or Claude Code, say *"note ça"* (or *"note this in the daily"*).
The agent drafts the note from the conversation (reformulated, with context), proposes tags and asks
**public or private**. Once you validate, it writes it to today's daily note, without leaving the
session and without you switching to a terminal.

`init` installs one skill (`outpost-note`, the open `SKILL.md` format) in your **user folder**, for the
chosen agent: `~/.claude/skills/` for Claude Code, `~/.copilot/skills/` for Copilot. Together with the shell profile block, it is the only
thing `init` writes outside the mission root, and `--no-skill` skips it. The file carries a
`managed by outpost` marker: `init` updates it while the marker is there, and leaves it alone once you
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
2. Ask it to follow [`prompts/weekly-review.md`](prompts/weekly-review.md) from this repo.

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

## 🧪 Dry run

```sh
./outpost init my-test --dry-run [--agent claude]
```

Generates the full instance in `.dry-run/my-test` so you can inspect it. Re-running is idempotent;
reset with `rm -rf .dry-run/my-test`.

## 🧪 Tests

```sh
tests/note.sh     # outpost note, n / np
tests/skill.sh    # skill installation (uses a temporary HOME, never your real one)
tests/profile.sh  # shell profile block (temporary HOME as well)
```

## 🛣️ Later

- `outpost review`: helper for the Friday review
- `outpost close`: end-of-mission checklist (retro, nothing confidential leaves)
