---
name: outpost-note
description: Record a note in the daily journal of the current mission (Outpost notes) without leaving the conversation. Use when the user asks to note, log, record or remember something in the daily journal, e.g. "note ça", "ajoute ça au journal", "note this in the daily".
---
<!-- managed by outpost: edit by removing this line, otherwise `outpost init` may overwrite this file -->

# Note to the daily journal

Write what the user wants to keep into today's daily note, through the `outpost note` command.
Never edit the daily files yourself.

## Steps

1. **Draft.** Reformulate what the user asked to keep, in the language they use, and complete it
   with useful context from the conversation (what, why, and the source: repo, branch, file or
   link when relevant). Be concise and factual.
   - Markdown is fine (short paragraphs, lists, fenced code that you close).
   - No `#` headings, and never the text `<!-- note` or `<!-- /note -->`.
   - No secrets, credentials or personal data. No judgment on people.
2. **Tags.** Propose 1 to 4 tags, free vocabulary, no spaces (use `-`): for example
   `type/decision`, `type/idea`, `type/question`, `type/todo`, `type/fact`, `type/command`,
   `topic/<theme>`, `repo/<name>`. They help the weekly review but are optional.
3. **Ask, in one message.** Show the draft and the tags and ask: **public or private?**
   There is no default: the user decides. Private is for anything sensitive (people, tensions,
   confidential client details). Wait for the answer. Apply their edits.
4. **Write**, only after that validation, from the current folder (the command finds the mission by
   itself, and falls back to the notes folder given by `--default-notes` when you are outside it). Pick a heredoc delimiter that does not appear in the text:

   ```sh
   "{{OUTPOST_BIN}}" note --default-notes "{{NOTES_DIR}}" [--private] --tags "type/idea topic/search" <<'NOTE_EOF'
   the validated text
   NOTE_EOF
   ```

5. **Report** the result in one line (the command prints the file it wrote). Do not re-read the file.

## Rules

- Never write without the user's validation, and never choose public or private for them.
- If the command fails (no mission found, git-crypt not ready, unclosed code fence...), show the
  error and stop. Do not work around it by writing the file directly.
- One note per request. If the user gives several unrelated things, ask whether to split them.
