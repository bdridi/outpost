# Weekly review

Working directory: the `notes/` folder. Follow the rules in `AGENTS.md` (which points to `../_outpost/notes/AGENTS.md`). Task:

1. Read every daily note of the current ISO week, public and private
   (`daily/YYYY-MM-DD.md` and `daily/YYYY-MM-DD.private.md`).
   Their content is a mix of:
   - **structured notes** between `<!-- note HH:MM -->` and `<!-- /note -->`
     (added through the capture channel), with optional `#tags`;
   - **free text** written by hand, with no markers (treat each paragraph or list item as a note);
   - **legacy lines** `- HH:MM text` (same as free text).
2. Skip anything already promoted: a note, paragraph or line that already ends with a
   `→ [[...]]` link.
3. Decide where each remaining note goes. Tags are hints, not truth: the vocabulary is open
   (`#type/decision`, `#topic/search`, ...), variants of the same word count as one theme,
   and notes without tags are classified from their content.
   - theme with >= 3 mentions in the week's dailies (counting `#topic/...` tags and content) -> `topics/`
   - decision -> `decisions/` (next number, e.g. `0004-title.md`)
   - procedure or command -> `guides/` (`commands.md` for one-liners)
   - new person -> a row in `people/people.md`
   - fact imposed by the client -> `context/`
   - anything uncertain -> do not file it, list it in the commit message
4. Create or complete the notes in those folders, appending only. Content coming from a
   private daily goes only into a `*.private.md` file (born private, e.g. `topics/x.private.md`).
5. Link each promoted note from its source: append `→ [[note-name]]` to the end of the
   structured note (just before `<!-- /note -->`) or to the end of the free-text line or
   paragraph. Never edit or reword the original text.
6. Work on a branch `review/<year>-W<week>` (e.g. `review/2026-W41`), commit, then stop.
7. Commit message = summary: what was promoted and where, what was not filed.
8. Open questions: append them at the end of Friday's daily note
   (the private one if they concern private content), as a structured note.
