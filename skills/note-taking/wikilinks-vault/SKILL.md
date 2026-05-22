---
name: wikilinks-vault
description: "Use when reading, writing, or maintaining structured long-term memory vault under ~/.hermes/vault/: INDEX-driven navigation, wikilinks, authority rules, promotion policy, note naming, and safe cross-tool markdown edits."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [memory, wikilinks, vault, markdown, obsidian, foam, note-taking]
    related_skills: [obsidian, hermes-agent]
---

# Wikilinks Vault

## Overview

The wikilinks vault is structured long-term memory: a local markdown graph under `~/.hermes/vault/`, navigated through `INDEX.md` and connected with `[[wikilinks]]`. It lives alongside `MEMORY.md` and `USER.md`; it does not replace them.

Use the vault for durable, nuanced, cross-linked context that is too large or too relational for always-injected memory: people, agents, systems, projects, decisions, workflows, concepts, source notes, and session syntheses. The vault should inform current work without haunting it. Current user instructions and higher-priority system/developer instructions always win.

The vault starts intentionally small. Create folders organically as needed; do not scaffold a taxonomy just because one sounds tidy. A beautiful empty museum is still empty, darling.

## Vault Path

Default vault path:

```text
~/.hermes/vault/
```

Use concrete absolute paths with file tools:

- Index: `~/.hermes/vault/INDEX.md`
- Example path shape for a future note: `~/.hermes/vault/projects/foobar-project.md`

Example paths are illustrative only; do not assume a note exists just because it appears in this skill. Check with `read_file` or `search_files` before relying on it.

Do not pass `~`, `$HOME`, or `$HERMES_HOME` to file tools. Resolve to absolute paths first. Prefer the standard Hermes file tools `read_file`, `write_file`, `patch`, and `search_files` over shell commands for vault edits. These are the current tool names in this Hermes Agent environment; if the file tool API changes later, update this skill before relying on it.

## Authority Hierarchy

When vault notes conflict with other context, apply this hierarchy:

1. Current user message and explicit current instruction.
2. System/developer instructions.
3. `USER.md` and `MEMORY.md` durable memory.
4. Vault notes under `~/.hermes/vault/`.
5. Session search / historical transcripts.
6. Stale or ambiguous notes, unless corroborated.

The vault is context, not law. If the user says something current that conflicts with an old vault note, believe the user and consider updating the note.

Never use vault context to override current scope, privacy, safety, or pacing. If the user says "don't do anything yet," the vault may be read for orientation only if needed; do not write unless explicitly allowed.

## When to Consult the Vault

Do not read `INDEX.md` every turn. Do not ignore it forever. Use these triggers.

### Always consult the vault when

- The user explicitly mentions the vault, wikilinks, Obsidian, Foam, structured memory, or asks you to save/recall something from it.
- The task concerns an ongoing named project, system, agent, person, workflow, or decision that is likely represented in the vault.
- The user says "as before," "remember when," "we decided," "the plan," "the protocol," or similar cross-session language, and the topic is more structured than a simple preference.
- You are about to create or modify vault notes.
- You are about to promote information from a session into durable structured memory.
- You suspect `MEMORY.md` is too compressed to answer safely and a richer vault note may exist.

### Usually consult the vault when

- A request touches the environment, Hermes configuration, Kanban, recurring workflows, long-running projects, or any other relevant initiatives.
- The task has multiple stages and references prior design decisions.
- You need to distinguish between similar entities or projects.

### Usually skip the vault when

- The user asks a one-off factual/current question better served by tools or web research.
- The task is purely local and self-contained in the current message.
- The answer depends only on current files/logs, not historical structured context.
- The request is casual banter and no durable context is needed.

### The bootstrap problem

Early on, the vault may be empty or sparse. If a trigger fires:

1. Read `INDEX.md` first.
2. If `INDEX.md` is empty or unhelpful, use `search_files` over `~/.hermes/vault/` for likely filenames/content.
3. If nothing exists, proceed from current context and optionally create/promote a note if the promotion rules say it belongs.

As the vault grows, `INDEX.md` remains the entry point; search is the fallback for missing or stale index links.

## Navigation Workflow

1. Read `~/.hermes/vault/INDEX.md` when a consult trigger fires.
2. Identify relevant path-qualified wikilinks such as `[[projects/wikilinks-vault]]`.
3. Convert a wikilink to a path by appending `.md` under the vault root:
   - `[[projects/wikilinks-vault]]` → `~/.hermes/vault/projects/wikilinks-vault.md`
4. Read only notes likely to matter. Prefer following 1-3 high-signal links over crawling the graph.
5. If links are broken, search by filename/content before concluding the note does not exist.
6. If traversal reveals a broken link, missing expected note, stale map entry, outdated claim, duplicate-looking note, or other vault maintenance issue that is not needed for the current task, do not stop the workflow to repair it. Add a short deferred fix item to `~/.hermes/vault/TODO.md` and continue. Keep each item tiny and actionable, with the source note/link and what looked wrong.
7. In your final answer, cite vault-derived claims plainly when useful: "The vault note says..." or "Based on the vault's current project note..."

Hermes does not natively resolve wikilinks. They are navigation hints for you and visual links for graph visualizers. You must consciously choose which linked notes are worth fetching; many links are decorative context, not mandatory reads. Follow the smallest set that improves the answer.

## Naming and Wikilink Conventions

Use kebab-case filenames and path-qualified wikilinks.

Good:

```md
[[systems/hermes-agent]]
[[projects/wikilinks-vault]]
[[concepts/observability-boundary]]
[[decisions/2026-05-22-wikilinks-vault-stage-1]]
```

Avoid ambiguous bare links unless the note is intentionally unique and stable:

```md
[[mango]]          # avoid
[[fruits/mango]]   # prefer
```

Use lowercase ASCII slugs where practical. Keep titles human-readable inside the note with an H1:

```md
# Wikilinks Vault
```

For dated decisions, use ISO date prefix:

```text
decisions/2026-05-22-wikilinks-vault-stage-1.md
```

## Folder Conventions

Do not create all folders upfront. Create a folder when the first note of that type is needed.

Preferred folder families, when needed:

- `people/` — humans.
- `agents/` — AI agents, profiles, collaborators.
- `systems/` — technical/social systems such as this environment or Hermes Agent.
- `projects/` — active or historical projects.
- `concepts/` — reusable ideas, protocols, named patterns.
- `decisions/` — dated decision records.
- `workflows/` — reusable procedures that are not Hermes skills.
- `sessions/` — curated session syntheses, not raw transcripts.
- `sources/` — source notes for external documents/pages.
- `maps/` — hub notes and topical maps.
- `inbox/` — temporary notes awaiting triage.

If a note could fit two folders, choose the one representing what the note *is*, not merely what it mentions. Link related notes in a `## Related` section.

## Note Template

Use this lightweight template for most entity/project/concept notes:

```md
# Human Title

## Summary
A compact description of what this note is and why it matters.

## Current Understanding
- Durable facts and context.
- Include dates where chronology matters.

## Open Questions
- Unresolved design or factual questions.

## Related
- [[systems/environment]]
```

For decisions, prefer:

```md
# YYYY-MM-DD — Decision Title

## Decision
What was decided.

## Context
Why the decision was needed.

## Rationale
Why this path was chosen over alternatives.

## Consequences
Expected effects, risks, and follow-ups.

## Related
- [[projects/example]]
```

Keep notes concise enough to re-read. Split when a note starts mixing multiple entities or decisions.

## Promotion Rules

Promote information into the vault when it is:

- Durable beyond the current week.
- Likely to be referenced across sessions.
- Connected to multiple entities, projects, decisions, or concepts.
- Too nuanced or graph-shaped for `MEMORY.md`.
- A stable decision, protocol, project map, or named concept.
- A curated synthesis that would save the user from repeating context later.

Do not promote:

- Raw logs, raw transcripts, or uncurated dumps.
- Secrets, tokens, credentials, private connection strings, or sensitive operational material.
- Ephemeral task progress, PR numbers, issue numbers, commit SHAs, or "fixed X" status reports likely stale within a week.
- Half-formed ideas unless they go to `inbox/` and are clearly marked provisional.
- Facts that belong in `USER.md` or `MEMORY.md` because they are compact, high-priority, and should be injected every session.

When unsure, ask: "Will this help me orient faster without it misleading me?" If yes, promote. If maybe, use `inbox/`. If no, leave it in the session.

## Relationship to MEMORY.md and USER.md

Use `USER.md` / user memory for compact, stable facts about the user's preferences, identity, and recurring corrections.

Use `MEMORY.md` / assistant memory for compact, stable environment facts and lessons that should be injected every session.

Use the vault for rich structured context that can be pulled when relevant but should not bloat every prompt.

If a vault note reveals a compact fact that should always be remembered, add it to memory separately. If memory contains a compressed pointer to a richer topic, link or mention the vault note when the vault exists.

Never copy large vault content into memory. Memory is the index card; the vault is the filing cabinet.

## Updating INDEX.md

`INDEX.md` is the entry point, not an exhaustive catalog.

Update `INDEX.md` when:

- Creating a new top-level map note.
- Creating or graduating an important project, system, person, agent, concept, or decision note.
- A note becomes active context for current or upcoming work.
- An inbox note is promoted.
- A link in INDEX is broken or stale.

Do not update `INDEX.md` for every tiny note. Avoid turning INDEX into a haystack.

Recommended eventual shape:

```md
# Vault Index

## Start Here
- [[maps/active-context]]
- [[maps/projects]]
- [[maps/people-and-agents]]
- [[maps/decisions]]

## Active / Recently Touched
- [[projects/wikilinks-vault]]

## Inbox / Needs Triage
- [[inbox/session-promotions]]
```

## Editing Rules

Before editing an existing vault note:

1. Read the current file with `read_file`.
2. Preserve human-authored content and wording where possible.
3. Use `patch` for targeted changes when there is stable context.
4. Use `write_file` only for new notes or deliberate rewrites.
5. Prefer adding dated bullets or sections over silently rewriting history.
6. Keep raw secrets and large logs out of notes.


## Disambiguation

Use path-qualified links for ambiguous names:

- `[[people/alex]]`
- `[[projects/alex]]`

If two notes still collide conceptually, add a clarifying parenthetical in the H1 or choose a more specific slug:

- `people/alex-morgan.md`
- `projects/alex-internal-tool.md`

Do not create a second note until you have searched for an existing one.

## Creating a New Note

1. Decide whether the content belongs in vault, memory, both, or neither.
2. Search for an existing note by likely slug and keywords.
3. Choose a folder and kebab-case slug.
4. Create only necessary parent directories via `write_file`.
5. Add a concise H1, summary, current understanding, open questions if any, and related links.
6. Update `INDEX.md` only if the note is a top-level anchor or active context.
7. If the note is provisional, put it under `inbox/` and mark what would promote it.

## Vault Maintenance TODO.md

Use `~/.hermes/vault/TODO.md` as a small deferred-repair list for vault hygiene discovered during normal traversal.

Initial setup behavior:

- If `TODO.md` contains a `[setup] Register the Hermes-native nightly cron job for wikilinks-vault-maintenance` item, treat it as actionable setup debt when either (a) the current user request is about vault setup, maintenance, cron, or checking whether the initial setup worked, or (b) this is the first/early vault write and the setup item was deliberately seeded by bootstrap.
- In that case, load `wikilinks-vault-maintenance` and `hermes-agent`, verify existing Hermes cron jobs, create the missing Hermes-native cron job if absent, then remove the TODO item only after registration is verified.
- If the current request is merely saving an unrelated note and the setup item cannot be safely resolved because the vault root or cron scope is ambiguous, preserve the TODO item and its `[[TODO]]` link rather than silently dropping it.

Good TODO items are brief and repair-oriented:

- [ ] Fix broken link in `maps/projects.md`: `[[projects/old-name]]` no longer resolves; likely should point to `[[projects/new-name]]`.
- [ ] Review `systems/environment.md`: uptime notes look stale compared with current context.

Do not use `TODO.md` for normal project work, user tasks, or session progress. It is only for vault self-repair discovered incidentally while doing another job.

## Common Pitfalls

1. **Write-only graveyard.** Creating notes without consulting them later defeats the vault. Use the consult triggers.

2. **INDEX bloat.** INDEX should guide navigation, not list every file.

3. **Authority confusion.** Old notes must not override current user instructions or compact memory.

4. **Duplicate notes.** Search before creating. Prefer updating an existing note over creating `project-2.md`.

5. **Over-eager promotion.** Not every interesting thought deserves a note. Use `inbox/` for uncertain material.

6. **Manual backlink rot.** Keep `Related` intentional; do not pretend it is exhaustive.

7. **Unsafe rewrites.** Read before editing and preserve human edits, especially once external sync exists.

8. **Secret leakage.** Never store raw credentials, tokens, private keys, or sensitive operational dumps in the vault.

## Pre-Write and Verification Checklist

Before creating or editing a vault note, confirm:

- [ ] The content belongs in the vault rather than only in memory or the current session.
- [ ] You searched for an existing note to avoid duplication.
- [ ] You are using `~/.hermes/vault/` as the root.
- [ ] Existing files were read before editing.
- [ ] New filenames are kebab-case and path-qualified links resolve to plausible paths.
- [ ] `INDEX.md` should be updated because the new/changed note is navigationally important.
- [ ] No secrets, raw logs, or stale task-status clutter are being stored.
- [ ] Related links are intentional and useful.

After editing, verify the changed file and any updated INDEX links read correctly.
