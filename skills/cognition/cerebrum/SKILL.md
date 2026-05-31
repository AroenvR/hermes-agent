---
name: cerebrum
description: Manage an agent's long-term "brain" — deliberately archive finished work (R&D notes, handover reports, decisions, brainstorms, documents) into Hindsight long-term memory, and retrieve it later with discipline. Use this skill whenever the agent finishes a brainstorm, document, report, or research session worth keeping; whenever the user says "remember this", "save this to memory", "archive this", "store this for later"; whenever the agent needs to find something it wrote before ("what did we decide about X", "find the handover report on Y", "do we have notes on Z"); or whenever a full document must be retrieved verbatim rather than as scattered facts. Trigger this even when the request is phrased casually, because reliable archival and recall depend on following the structured workflows here rather than relying on automatic capture alone.
---

# Cerebrum

The agent's brain-management skill. It governs the **deliberate** half of long-term memory: consciously archiving finished artifacts, and retrieving them well. Automatic conversation capture (auto-retain) is handled by the Hindsight provider and needs no skill — this skill exists for the acts that judgment, not automation, should drive.

## Mental model: two layers, two jobs

The agent's memory has layers. This skill operates on the long-term brain (Hindsight) and respects the boundary with the always-on working memory:

- **Working memory** (the host's curated core, e.g. system-prompt memory files): small, agent-maintained, always in context. This skill does **not** touch it. Leave it to the host's default memory system.
- **The brain** (Hindsight long-term memory): a large, queryable store of facts and full documents. This skill **archives to** and **retrieves from** it.

The brain is an *aid on top of* working memory, not a replacement. When both speak to the same fact, working memory wins — that precedence is correct, not a bug.

## What this skill does

1. **Archive** — store a finished artifact (document, report, research summary, decision record) into the brain as a coherent, retrievable unit, with consistent metadata. → [references/archiving.md](references/archiving.md)
2. **Retrieve** — find prior work by meaning, list candidates, and pull full documents back verbatim, using a disciplined two-phase pattern that avoids context bloat. → [references/retrieval.md](references/retrieval.md)
3. **Maintain** — keep the brain healthy: re-archive on edit, verify reproduction, prune correctly. → [references/maintenance.md](references/maintenance.md)

For the exact tool surface, parameters, and configuration this skill assumes, see [references/tooling.md](references/tooling.md). **Read it first if you are unsure which tools exist or what they are called** — tool names and recall defaults have version-specific gotchas that will silently break archival or recall if ignored.

## When to archive (the judgment call)

Archiving is deliberate by design. Auto-retain captures *conversation*; it does **not** reliably capture a *finished artifact* as a clean, whole document. So archive explicitly when:

- A document, report, brainstorm, or handover is **finished** and may be needed again.
- A research/debugging session reached a **conclusion** worth preserving as a unit (not just scattered turns).
- The user asks to remember, save, store, or archive something.
- A decision was made that future sessions should be able to look up.

Do **not** archive: half-finished drafts, trivial chatter, or things working memory already holds. When unsure whether something is "done enough," ask the user — premature archival pollutes the brain with churn.

## Core retrieval discipline: search and load are separate steps

**This is the single most important rule for retrieval. Never skip it.**

When asked to find something, do **not** dump full documents into context immediately. Follow two phases across two turns:

1. **Search / orient** — query the brain, get back a *ranked list of candidates* (titles, summaries, IDs, metadata). Present them. **Stop.**
2. **Load on demand** — only after the right candidate is identified (by you or the user) do you fetch the full document verbatim.

Pulling full bodies in the search step is the most common way to blow the context budget and degrade the agent. Resist it. A search returns pointers; a load returns content. See [references/retrieval.md](references/retrieval.md) for the exact pattern.

## Quick reference

| Intent | Action | Detail |
|---|---|---|
| Archive a finished document | Generate metadata, then retain it as one unit | [archiving.md](references/archiving.md) |
| Find prior work by meaning | Recall → present ranked candidates → stop | [retrieval.md](references/retrieval.md) |
| Get a full document back verbatim | Identify candidate, then fetch the document | [retrieval.md](references/retrieval.md) |
| Synthesize across many memories | Use reflect (costs an LLM call; use sparingly) | [tooling.md](references/tooling.md) |
| Re-archive after an edit | Re-retain under the SAME document id | [maintenance.md](references/maintenance.md) |
| Confirm exact tool names / config | Read this before anything else if unsure | [tooling.md](references/tooling.md) |

## Generating archival metadata (and the built-in collision guard)

Good metadata makes a document findable later and improves how the brain extracts facts from it. **Do not hand-improvise metadata, and do not rely on remembering to check whether a document already exists** — a helper script does both. It produces a normalized metadata block, a stable type-prefixed `document_id`, AND queries Hindsight to detect an id collision:

```bash
python scripts/make_metadata.py --title "Auth migration handover" --type handover
```

The id is deterministic (same type + title → same id), so editing a document and re-archiving it updates in place rather than duplicating. Because Hindsight **upserts** on `document_id` (an existing id is silently replaced), the script refuses to emit metadata when the id already exists *unless* you pass `--update` to assert the overwrite is intentional. This makes accidental clobbering hard and deliberate updates explicit. See [references/archiving.md](references/archiving.md) for the full branch logic (safe / collision-stop / `--update` / fail-open) and the script's `--help` for all flags. The script reads connection details from the host environment — see [references/tooling.md](references/tooling.md).

## Portability

This skill is host- and identity-agnostic. It assumes only:
- A Hindsight long-term memory backend reachable by the agent (local embedded or remote).
- The agent can call the memory tools described in [references/tooling.md](references/tooling.md), OR can run shell/Python to reach the Hindsight client.

## A note on reliability

In tools-only setups the agent must *choose* to archive and recall — nothing here happens automatically. Treat the triggers above as standing obligations: when work is finished, archive it; when prior work is needed, retrieve it before answering from a possibly-stale guess. The brain is only as useful as the discipline of writing to and reading from it.
