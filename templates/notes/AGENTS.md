# AGENTS.md

Conventions applied by every agent (Copilot, etc.) working in this folder.

1. **Capture**: every capture goes into today's daily note, unsorted, either written by
   hand or through `outpost note` (see "Daily note format").
2. **Promotion**: notes move to `topics/`, `decisions/`, `guides/`, `people/people.md` or
   `context/` during the weekly review only, with a `[[wikilink]]` from the source
   daily note to the promoted note.
3. **context/**: 4 fixed files (`mission`, `stack`, `organization`, `glossary`).
   A 5th only with a real reason.
4. **Public files**: factual content only. No judgment on people, no tensions.
5. **guides/**: client-specific only. Generic material is flagged
   "move to personal toolbox" (outside the client repo).
6. **Agents**: never commit on `main`, never delete or rewrite existing content,
   append only. When in doubt, do not file it: flag it instead.
7. **End of mission**: `retro.md` (nothing confidential) is the only note taken away.

## Daily note format

A daily note is free-form: write however you like. Notes added by the capture channel
(`outpost note`, `n`, `np`, or an agent skill) follow this shape:

```markdown
---

<!-- note 14:32 -->
**14:32** · Text, Markdown allowed (no `#` headings).

#type/decision #topic/search
<!-- /note -->

---
```

- One `---` between notes, always after a blank line. Never add a second one.
- Tags are optional and the vocabulary is open (`#type/...`, `#topic/...`, ...).
- A note that ends with `→ [[note-name]]` has already been promoted.
- Agents never rewrite or delete text in a daily note: they append (a `→ [[link]]`
  before `<!-- /note -->`, or at the end of a free-text line or paragraph).
- Never put `<!-- note` or `<!-- /note -->` inside a note's text.

## Private files (`*.private.md`)

- Encrypted with git-crypt via `.gitattributes`. Any folder may contain one.
- A file is born private: never rename public -> private (history would leak).
- Private content goes only into `*.private.md`.
- Links go private -> public only, never public -> private.
- Neutral file names (they are visible even when encrypted).
- Never print, copy or summarize private content into a public file.

## Layout

- `daily/YYYY-MM-DD.md` and `daily/YYYY-MM-DD.private.md`
- `topics/`: created when a theme has >= 3 mentions in `daily/`
- `decisions/0001-title.md`: context, decision, alternatives, why
- `people/people.md`: one table of all people: role, scope, expectations (factual only)
- `guides/`: one file per procedure; `commands.md` is the single cheat sheet
- `templates/`: daily, daily.private, decision, topic, guide
