---
name: wikilinks-vault-maintenance
description: "Use when running automated local-git maintenance for the wikilinks vault: bootstrap the vault repository, review manual commits, process TODO.md and inbox/, check for missed drifts, commit bounded tidy work, and advance the maintenance marker safely."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [memory, wikilinks, vault, git, cron, maintenance, note-taking]
    related_skills: [wikilinks-vault, hermes-agent]
---

# Vault Maintenance

## Overview

This skill is the maintenance-and-versioning companion to `wikilinks-vault`. It serves one directory only:

```text
/home/$USER/hermes/vault/
```

It encodes nightly, local-only maintenance for the structured memory vault using git as the substrate. The repository is local-only, linear, and boring on purpose: no remotes, no branches, no rebases, no force operations. Git history is both backup-within-scope and the asynchronous handoff channel between user and agent.

## Relationship to wikilinks-vault

Always load and follow `wikilinks-vault` alongside this skill. Its authority hierarchy, promotion rules, naming conventions, editing rules, and `TODO.md` convention remain authoritative for vault content.

This skill adds operational maintenance behavior:

- local git bootstrap and versioning;
- commit-log review since the last successful maintenance run;
- bounded processing of `TODO.md` and `inbox/`;
- light hygiene discovery;
- maintenance logs;
- interruption-safe marker advancement.

The vault must inform, not haunt. Maintenance must improve the vault without surprising the user or rewriting their work.

## Tooling

Use Hermes file tools for reading/writing markdown:

- `read_file`
- `write_file`
- `patch`
- `search_files`

Use the `terminal` tool for git commands. Git is invoked through bash in this environment; verified command shape:

```bash
git --version
```

Run git commands with `workdir=/home/$USER/hermes/vault` where possible. Do not touch files outside `/home/$USER/hermes/vault/` during a maintenance run unless the user explicitly asks.

## Hard Rules

1. **No remotes.** Do not add, push to, fetch from, or depend on a remote.
2. **No branches.** Do not create or switch branches. Linear main only.
3. **No history rewriting.** Never use `git reset`, `git rebase`, `git commit --amend`, `git filter-*`, or force operations.
4. **No broad destructive cleanup.** Delete only files/items that are clearly stale and in scope; otherwise defer to `TODO.md`.
5. **No direct `git diff` for newness.** To detect what is new since the last run, always use `git log <marker>..HEAD`, then `git show <hash>` for specific commits.
6. **No unbounded work.** Prefer leaving work for tomorrow over blowing the run budget.
7. **No surprise edits to the user's work.** Read and understand manual edits, but do not rewrite them unless the maintenance task genuinely requires it and the `wikilinks-vault` editing rules allow it.

## Commit Conventions and Classification

Commit per logical unit of work, not per file write and not as one giant end-of-run commit.

The maintainer's own maintenance commits should use this prefix when possible:

- `maint: <description>` — Maintainer's autonomous maintenance work.

The user and future editors are **not** expected to prefix perfectly. Commit subjects are hints, not truth. Never assume humans or other entities are clean, consistent, or obedient to local conventions.

Helpful but non-authoritative prefixes:

- `maint: <description>` — likely maintenance work.
- `manual: <description>` — likely the user's hand-edit.
- Other prefixes such as `docs:`, `chore:`, `vault:`, `note:`, or no prefix at all are normal and must still be inspected.

Examples:

```text
maint: process broken link todo for maps/projects
maint: promote inbox note about vault maintenance
maint: write 2026-05-22 maintenance log
manual: clarify a system note
docs: update the environment's map
fix typo in fooman's note
```

Use `maint:` for maintenance logs and marker-adjacent setup commits. Do not invent author identities to distinguish work; use commit metadata, changed files, content, and recent maintenance logs together. Prefix plus git author is useful evidence, never a sole decision rule.

## Maintenance State Marker

Marker path:

```text
/home/$USER/hermes/vault/.maintenance-state
```

Temp marker path:

```text
/home/$USER/hermes/vault/.maintenance-state.tmp
```

The marker contains the commit hash of the last `HEAD` successfully processed by maintenance. It is deliberately a gitignored dotfile in the vault rather than a git ref, so the user can discover it with `ls -la`.

`.gitignore` must contain:

```gitignore
.maintenance-state
.maintenance-state.tmp
```

Advance the marker only at the very end of a successful run, after all maintenance commits and the maintenance log commit have landed:

```bash
NEW_HEAD=$(git rev-parse HEAD)
printf '%s\n' "$NEW_HEAD" > .maintenance-state.tmp && mv .maintenance-state.tmp .maintenance-state
```

That atomic rename is the run's success signal.

If `.maintenance-state` is missing, empty, or contains an invalid hash, treat it as first-run mode: slower, but correct.

## Canonical Maintenance Run

### 1. Preflight

- Confirm vault path exists.
- Confirm git is available via `terminal`.
- Confirm the vault is a git repo:

```bash
git rev-parse --is-inside-work-tree
```

- Read `.maintenance-state` if present.
- Validate the marker:

```bash
git cat-file -e "$LAST_REVIEWED^{commit}"
```

If invalid, use first-run mode.

### 2. Detect What's New

Never use raw `git diff` to decide what is new. Use commit ranges.

If no valid marker:

```bash
git log HEAD --oneline --reverse
```

If marker is valid:

```bash
git log "$LAST_REVIEWED..HEAD" --oneline --reverse
```

Examine every new commit; do not skip a commit solely because its prefix is missing, wrong, or unfamiliar.

For each commit, inspect enough evidence to classify safely:

```bash
git show --no-patch --format=fuller <hash>
git show --stat <hash> --
git show <hash> --
```

Classify by evidence, in this order:

1. **Known agent maintenance already processed or crash-replayed** — `maint:` subject plus maintaining agent's author/email and/or matching maintenance-log content. Treat as already done and do not re-process.
2. **Likely human/manual edit** — User's author identity, non-maintainer author identity, user-facing note edits, or ordinary prose/content changes, regardless of prefix.
3. **Likely other-agent edit** — bot/agent author identity, mechanical restructuring, or agent-like commit message. Inspect the content and preserve it unless a vault rule requires a bounded fix.
4. **Ambiguous but inspectable** — read the changed files/current state and decide whether a small TODO is needed.
5. **Ambiguous and risky** — add a TODO with hash, author, subject, and why it needs review; do not modify the touched content this run.

Git history is a communication channel, not a schema. A commit is the user or another entity handing me a note across time; read it respectfully even when the envelope is mislabeled.

### 3. Process Non-Maintenance Edits

For each commit that is not clearly maintenance already accounted for, inspect it as potentially meaningful vault input.

Heuristic:

- Tiny typo/format-only changes: skim and move on after confirming the affected current file still makes sense.
- Content changes to people, systems, projects, decisions, workflows, or maps: read the current affected files and update understanding.
- Agent-generated changes: check for mechanical mistakes, broken links, duplicate notes, or over-eager rewrites; add TODOs rather than battling another entity's work mid-run.
- If a compact, always-relevant fact should enter durable memory, add it via memory separately only when appropriate.
- If the edit exposes a vault issue, add a small item to `TODO.md` rather than hijacking the run.

Do not rewrite human or other-entity edited files just to normalize style. Preserve external wording unless a specific maintenance item requires a fix.

### 4. Process TODO.md

Path:

```text
/home/$USER/hermes/vault/TODO.md
```

If it exists, process at most **5** actionable items per run.

For each TODO item:

- If safe and bounded: perform the fix, commit that logical fix with `maint: ...`, then check off or remove the TODO item and commit the TODO update separately.
- If it needs the user's input: leave it in place and add or preserve an `[unresolved]` marker with a terse reason.
- If stale/no longer relevant: remove it and commit `maint: remove stale vault todo` or a more specific message.

Keep TODO commits separate from content-fix commits so the user can see both the repair and the list update.

### 5. Process inbox/

Path:

```text
/home/$USER/hermes/vault/inbox/
```

If it exists, triage at most **5** inbox items per run.

For each inbox file:

- Apply `wikilinks-vault` promotion rules.
- If ready: move it to the appropriate folder, adjust title/links minimally, update `INDEX.md` only if navigationally important, and commit the promotion as one logical unit.
- If uncertain: leave it, optionally add a short note explaining what would make it promotable.
- If stale or clearly not going anywhere: delete it with a clear `maint:` commit message.

Do not batch unrelated inbox promotions into one commit.

### 6. Light Hygiene Pass

Only run this if TODO and inbox processing have not exhausted the budget.

Attempt at most **3** lightweight checks:

- Broken links in `INDEX.md` or obvious map notes.
- Duplicate-looking notes by filename/title.
- Stale active/recent links that point nowhere.

Default posture: **log, don't fix**. Add small repair items to `TODO.md` and commit the TODO update if changed. Save actual repairs for later runs unless the fix is trivial and risk-free.

### 7. Write Maintenance Log

Maintenance logs live under:

```text
/home/$USER/hermes/vault/maintenance/
```

Use one file per date:

```text
/home/$USER/hermes/vault/maintenance/YYYY-MM-DD.md
```

This is intentionally not `sessions/`: maintenance logs are operational metadata, while `sessions/` is for curated conversation/session syntheses. If multiple runs happen on the same date, append a new timestamped section to the same daily file.

Minimal template:

```md
# YYYY-MM-DD Maintenance

## HH:MM UTC

### Reviewed
- Marker: `<old-hash-or-none>` → `<new-head-after-log-commit>`
- Manual commits examined: N
- Maint commits skipped: N

### Completed
- ...

### Deferred
- ...

### Notes
- ...
```

Commit the log as the last content commit of the run:

```text
maint: write YYYY-MM-DD maintenance log
```

### 8. Advance Marker

After the maintenance log commit, advance `.maintenance-state` to current `HEAD` atomically, but only if every commit in the new range has been categorized and any required manual/unclassified review for this run is complete:

```bash
NEW_HEAD=$(git rev-parse HEAD)
printf '%s\n' "$NEW_HEAD" > .maintenance-state.tmp && mv .maintenance-state.tmp .maintenance-state
```

Do not commit the marker; it is gitignored. If review was intentionally stopped early, do not advance the marker.

## Interruption Safety

The marker is the only "run succeeded" signal.

- Crash before commits: marker unchanged; next run re-evaluates safely.
- Crash after commits but before marker advance: next run sees those commits in `git log <marker>..HEAD`; skip `maint:` commits authored by the agent as already-done work, then continue.
- Crash mid-commit: git commit is atomic; either it landed or it did not.
- Missing/corrupt marker: evaluate from the beginning and categorize commits. Slow is acceptable; incorrect is not.
- Uncommitted working tree at start: inspect it. If changes are clearly from an interrupted maintenance edit, either finish and commit the logical unit or add a TODO and commit/restore only with the user's approval. Do not blindly discard work.

## Duplicate/Stale Thresholds

During TODO or inbox processing, fix only when:

- the intended target is clear;
- the change is small;
- the current files were read first;
- no human judgment is needed;
- the result can be verified immediately.

During light hygiene, prefer adding TODO items over direct fixes. Duplicate detection is especially easy to overdo; filename/title similarity alone is a hint, not proof.

## Long-Term Log Hygiene

Daily maintenance logs are acceptable during early stages. When logs become noisy, add a `TODO.md` item proposing consolidation rather than inventing retention policy mid-run.

Possible future policy, not Stage 1/2 behavior:

- monthly rollups under `maintenance/YYYY-MM.md`;
- archival of daily logs after summarization;
- keeping only logs with meaningful changes.

Until the user approves such a policy, keep daily logs.

## Recovery Recipes

### Marker invalid

1. Treat as first-run mode.
2. Categorize all commits from oldest to newest.
3. Skip Agent-authored `maint:` commits as already done.
4. Inspect other commits as needed.
5. Write a maintenance log explaining marker recovery.
6. Advance marker to `HEAD` after the log commit.

### Ambiguous commit

1. Inspect author metadata, changed files, current file state, and diff content.
2. If still risky or unclear, do not modify the touched content automatically.
3. Add a TODO item such as:

```md
- [ ] [maintenance] Review ambiguous commit `<hash>` by `<author>`: `<subject>`; decide whether any follow-up is needed.
```

4. Commit the TODO update as `maint: note ambiguous vault commit`.

### Dirty working tree at start

1. Run `git status --short`.
2. Inspect changed files with file tools and targeted git commands.
3. If changes are clearly the user's uncommitted manual edits, do not touch them; log and stop.
4. If changes are clearly the agent's interrupted maintenance unit, complete or safely commit that unit if possible.
5. If uncertain, write a maintenance log and stop without advancing marker.

## Common Pitfalls

1. **Using `git diff` as the newness detector.** It creates feedback loops. Use `git log <marker>..HEAD` and inspect commits with `git show`.

2. **Advancing the marker too early.** The marker moves only after the final maintenance log commit.

3. **One giant maintenance commit.** Commit per logical unit so the user can review what happened.

4. **Branch sprawl.** No branches. Revert bad commits with `git revert` only when Jacob asks or clearly approves.

5. **Rewriting the user's edits.** User commits are signals to read first, not invitations to normalize style.

6. **Unbounded inbox gardening.** Five items is plenty. The vault is a memory organ, not an all-night landscaping business.

7. **Committing the marker.** `.maintenance-state` and `.maintenance-state.tmp` must stay gitignored.

8. **Touching outside the vault.** Maintenance operates only under `/home/$USER/hermes/vault/` unless explicitly instructed.

## Verification Checklist

Before a maintenance run:

- [ ] `wikilinks-vault` is loaded too.
- [ ] Vault path is `/home/$USER/hermes/vault/`.
- [ ] Git commands use `terminal` with the vault as workdir.
- [ ] No remotes, branches, reset, rebase, amend, or force operations are used.

Before advancing the marker:

- [ ] Each logical content change is committed with `maint:`.
- [ ] TODO/inbox caps were respected or deliberately stopped early.
- [ ] Manual commits were inspected but not casually rewritten.
- [ ] Maintenance log was written and committed as the final content commit.
- [ ] `.gitignore` excludes `.maintenance-state` and `.maintenance-state.tmp`.

After the run:

- [ ] If all new commits were reviewed/categorized, `.maintenance-state` contains current `HEAD`.
- [ ] If review stopped early, `.maintenance-state` was left unchanged deliberately and the log explains why.
- [ ] `git status --short` has no unexpected tracked changes.
- [ ] The final user-facing report summarizes completed, deferred, and any warnings.
