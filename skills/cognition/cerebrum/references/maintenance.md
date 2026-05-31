# Maintenance workflow

Keeping the brain healthy over time: updates, verification, and correct pruning.

## Contents
- Re-archiving an edited document
- Verifying an archive
- Pruning and superseding
- What not to do

## Re-archiving an edited document

When an already-archived document changes, re-archive it under the **same** `document_id`. Hindsight upserts on `document_id`: retaining under an existing id deletes the old document and its facts and replaces them in place. Using a *new* id instead silently creates a duplicate the brain treats as unrelated, leaving two versions with no link between them.

```
Update Progress:
- [ ] Run make_metadata.py with the SAME title + type AND --update
      (same title+type → same id; --update authorizes the in-place overwrite)
- [ ] Confirm the script reports it WILL update an existing document
- [ ] Retain the full updated text under that id
- [ ] Note the update is async — verify next turn if needed
```

Because `scripts/make_metadata.py` derives the id deterministically from **type + title**, running it again with the same title and type yields the same id — so an edit re-archives in place automatically. Two things to keep stable for this to work: the **title** and the **type**. If either changes, you get a *different* id, i.e. effectively a new document; decide deliberately whether that's intended (a genuinely new artifact) or whether you should preserve the original title+type to keep the document's identity.

## Living documents

Hindsight has a first-class notion of "living documents" — documents that are curated to stay current rather than versioned into separate copies. A document you repeatedly re-archive under the same id *is* a living document: each upsert moves it forward. Prefer this pattern for things meant to evolve (a running handover, an updated decision record) over keeping multiple dated copies. If you need to enumerate these, the host's Hindsight instance exposes a way to list living documents — consult [tooling.md](tooling.md) / the running API for the exact call.

## The same-id collision is a decision point, not an automatic overwrite

Because upsert silently replaces, treat a pre-existing id as a fork in the road (this mirrors Step 2a in [archiving.md](archiving.md)):

- **Updating the same document →** upsert is correct; proceed.
- **A different document that happens to share type + title →** do not overwrite. Either **merge** the two if they truly cover the same topic, or give the new one a **differentiating title** so it gets its own id.

The decision is the agent's (with the user where unclear). Never resolve it by letting the upsert clobber an unrelated document.

## Verifying an archive

Verification is a **next-turn** activity (retain is asynchronous; same-turn checks mislead). To confirm a document archived correctly:

1. On a later turn, recall by a phrase from the document (Phase 1 of [retrieval.md](retrieval.md)).
2. Confirm the candidate appears with the expected id/metadata.
3. For a strict check, fetch the full `original_text` by id and confirm it matches what was stored — verbatim reproduction is the real test that the document (not just scattered facts) is retrievable.

If recall finds nothing, before assuming failure check the `recall_types` gotcha in [tooling.md](tooling.md) — documents are hidden when recall is limited to `observation` only.

## Pruning and superseding

- **Superseding:** the brain handles contradictions over time by updating rather than blind-overwriting; re-archiving an updated document under the same id is the normal way to move it forward. Prefer this over manual deletion.
- **Deleting:** when a document genuinely should be removed, delete it by `document_id` (its facts/chunks go with it). There is no external file to leave dangling — the document lived in the brain, so a clean delete is complete.
- **Accidental duplicates:** if a duplicate was created (e.g. an edit archived under a new id by mistake), delete the stale id and keep the canonical one. Going forward, keep titles stable so ids stay stable.

## What not to do

- **Do not** maintain your own external index of document ids/paths. The brain is the store; there is no filesystem pointer to keep in sync. Adding a parallel index reintroduces exactly the drift this design removed.
- **Do not** pre-chunk documents or store summaries in place of full text — that breaks verbatim reproduction.
- **Do not** touch the host's working-memory files (system-prompt memory). That layer is maintained by the host's default memory system, not by this skill.
- **Do not** treat same-turn recall failure as broken — it's async (see [tooling.md](tooling.md)).
