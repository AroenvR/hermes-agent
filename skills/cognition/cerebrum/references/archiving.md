# Archiving workflow

How to deliberately store a finished artifact into the brain as a coherent, retrievable unit.

## Contents
- When to use this
- The workflow
- Metadata: what to capture and why
- What "one unit" means
- Worked example

## When to use this

Use this workflow when archiving a finished document, report, handover, research summary, or decision record — anything the agent should be able to find and reproduce later. For the judgment of *whether* something is worth archiving, see the "When to archive" section of SKILL.md. This file covers *how*.

## The workflow

Copy this checklist and work through it:

```
Archive Progress:
- [ ] Step 1: Confirm the artifact is finished and worth keeping
- [ ] Step 2: Run make_metadata.py (generates id + checks Hindsight for a collision)
- [ ] Step 2a: Respond to the outcome (safe / collision-stop / --update / fail-open)
- [ ] Step 3: Retain the full artifact as one unit, with metadata
- [ ] Step 4: Note that verification happens on a later turn (async)
```

**Step 1 — Confirm.** Is this a finished unit, or churn? If unsure, ask the user. Do not archive half-drafts.

**Step 2 — Generate metadata and check for collisions in one step.** Do not improvise fields ad hoc, and do not rely on remembering to check whether the id exists — the helper does both. Run it:

```bash
python scripts/make_metadata.py --title "<document title>" --type <type>
```

`<type>` is one of (but not limited to): `handover`, `research`, `decision`, `reference`, `report`, `note`, ..., The script:
1. Composes a deterministic `document_id` from **type + title** (e.g. `handover-auth-migration`), so same-title/different-type documents never collide.
2. **Queries Hindsight for that id** (using connection details from the host's env: `HINDSIGHT_API_URL`, `HINDSIGHT_BANK_ID`, optional `HINDSIGHT_API_KEY`).
3. Decides what to do based on whether the id already exists — see the branches below.

This moves the collision guard out of your judgment and into a deterministic check. You do not separately "look it up first" — the script is the check.

**Step 2a — Respond to the script's outcome.** The script's exit behavior tells you which case you're in:

- **Emits metadata, "safe to archive" (exit 0) →** no existing document with this id. Proceed to Step 3.
- **Refuses, "COLLISION" (exit 3) →** a document with this id already exists and you did **not** assert an update. Stop and decide:
  - This is an **update** to that document → re-run with `--update` to proceed deliberately.
  - This is a **different** document → give it a distinct `--title` or different `--type` so it gets its own id.
  - The two cover the **same topic** → merge into the existing document, then `--update`.
- **Emits metadata, "WILL BE UPDATED" (exit 0, only with `--update`) →** you have deliberately asserted an in-place update; the upsert will replace the existing document. Proceed to Step 3.
- **Emits metadata with a fail-open WARNING (exit 0) →** the script could not reach Hindsight to check (no env config, or API unreachable). It proceeds so archival isn't blocked, but the collision guard did not run. Treat `--update` as your deliberate signal: only archive over a possibly-existing id if you mean to. If unsure, verify the id another way before retaining or consult the user directly.

The `--update` flag is the **deliberateness gate**: an accidental re-archive (you didn't realize the id existed) is stopped; an intentional update passes because you consciously set the flag.

**Step 3 — Retain as one unit.** Pass the document's full text as the content, with the generated id and metadata. Prefer the `hindsight_retain` tool; fall back to the client if you need finer control.

Via the tool: call `hindsight_retain` with the full document text, the generated `document_id`, and the metadata block.

Via the client (fallback):
```python
client.retain(
    bank_id="<from host config>",     # never hardcode
    content=full_document_text,        # the WHOLE artifact, not a summary
    document_id="<from make_metadata>",
    metadata={...},                    # from make_metadata
)
```

**Step 4 — Verification is deferred.** Retain is asynchronous; the document becomes retrievable on a later turn. Don't immediately recall-and-panic in the same turn. If the user wants confirmation, verify next turn (see [maintenance.md](maintenance.md)).

## Metadata: what to capture and why

Metadata does double duty: it makes documents findable (filter/list by type, title, date) and it improves extraction (the brain feeds metadata into its fact-extraction step, so a good title/type yields better-resolved facts). Capture, at minimum:

- **title** — human-meaningful, used for the id and for listing.
- **type** — the artifact category, for filtering.
- **date** — when archived.
- **document_id** — deterministic, composed from **type + title**. The hinge for in-place updates, and type-prefixed so same-title/different-type documents don't collide.

Keep metadata small and consistent. Do not stuff the document body into metadata — the body is the `content`.

## What "one unit" means

Archive a document as a single retain call with the **entire** text as content. Do not pre-chop it into fragments yourself — the brain chunks internally for retrieval while preserving the original text for verbatim reproduction. Your job is to hand it one coherent artifact, not to do the chunking. Summarizing the document instead of storing its full text defeats verbatim retrieval — store the real thing.

## Worked example

Input: the agent has just finished a handover report titled "Auth migration handover" and the user (or the agent's own judgment) decides to keep it.

```
1. Finished? Yes — it's a complete handover.
2. Run the helper (it generates the id AND checks Hindsight):
   python scripts/make_metadata.py --title "Auth migration handover" --type handover
   → document_id: "handover-auth-migration-handover" (type-prefixed, deterministic)
   → metadata: {"title": "...", "type": "handover", "date": "<today>", ...}
2a. The script's outcome decides the branch:
   → "safe to archive" (exit 0)        → proceed to 3.
   → "COLLISION" (exit 3)              → this id exists. If this is an update, re-run with
                                         --update; if it's a different doc, rename; if same
                                         topic, merge then --update.
   → fail-open WARNING (exit 0)        → couldn't reach Hindsight; proceed only if you mean
                                         to (use --update deliberately for a known update).
3. Retain:
   hindsight_retain(content=<full report text>, document_id=<above>, metadata=<above>)
4. Tell the user it's archived; note it will be recallable from the next turn on.
```

Later, retrieval (see [retrieval.md](retrieval.md)) finds it by meaning and can pull the full report back verbatim by its document id.
