# Retrieval workflow

How to find prior work in the brain and pull it back — without flooding context.

## Contents
- The cardinal rule
- The two-phase pattern
- Phase 1: search / orient
- Phase 2: load on demand
- Verbatim document retrieval
- When to use reflect instead
- Worked examples

## The cardinal rule

**Search and load are separate steps, on separate turns. A search returns pointers; a load returns content.** Pulling full document bodies during the search step is the most common way to blow the context budget and degrade the agent. Do not do it.

## The two-phase pattern

```
Retrieval Progress:
- [ ] Phase 1: Recall → get ranked candidates (titles/summaries/ids) → present → STOP
- [ ] Phase 2: After the right candidate is chosen → fetch full content for that one
```

These are two turns. Phase 1 ends by showing candidates and stopping. Phase 2 begins only once the target is identified — by the user picking one, or by you confidently identifying the single clear match.

## Phase 1: search / orient

Call `hindsight_recall` with the query. It runs semantic + keyword + entity-graph + temporal retrieval in parallel and reranks. It returns *relevant matches* — treat these as candidates, not as the answer.

Present them compactly as a ranked list: for each, show enough to choose — title, a one-line summary, type/date, and the document id (so the load step has it). Then **stop** and let the user (or your own clear judgment) select.

Do **not** in this phase: fetch full bodies, retain anything, or answer a factual question from a half-loaded guess.

If recall returns nothing when you expect hits, check the `recall_types` gotcha in [tooling.md](tooling.md) — archived documents are hidden if recall is limited to `observation` only.

## Phase 2: load on demand

Once the target document is identified, fetch its **full original text by document id** (Hindsight preserves the verbatim text it was given). Use the document-retrieval capability described in [tooling.md](tooling.md) (the `hindsight_recall` tool surfaces facts/snippets; full-document reproduction uses the document API / client by id).

Load only what's needed:
- If the user wants the **whole document** (e.g. to hand it to another agent), fetch the full `original_text` for that id and provide it verbatim.
- If the user wants **an answer**, you may only need the relevant facts/snippets recall already returned — don't load the whole document just to answer a narrow question.

## Verbatim document retrieval

The brain stores the original text of archived documents, so a finished report comes back **whole and unaltered**, not as a fragmented rewrite. This is the path for handoffs ("give the auth migration report to the other agent"):

1. Phase 1: recall "auth migration handover" → identify the candidate + its id.
2. Phase 2: fetch the full `original_text` for that id → output it verbatim.

Recall *finds* by meaning; the document API *reproduces* by id. Use both, in order.

## When to use reflect instead

`hindsight_reflect` synthesizes across many memories and costs an extra LLM call. Use it only for genuinely synthetic questions ("based on everything we've learned about the deployment, what are the open risks?"), not for ordinary lookups or document retrieval. Default to recall; reach for reflect when synthesis is the actual need.

## Worked examples

**Find and answer (no full load needed):**
```
User: "What did we decide about the database failover approach?"
Phase 1: hindsight_recall("database failover decision")
         → present 2-3 candidates with summaries + ids → (clear single match)
Phase 2: the recalled facts already answer it → summarize from those.
         (No need to load a whole document for a narrow question.)
```

**Find and hand off (full verbatim load):**
```
User: "Send the auth migration handover to the new agent."
Phase 1: hindsight_recall("auth migration handover")
         → present candidate(s) + id → confirm the right one
Phase 2: fetch original_text by that document id → provide the full report verbatim.
```

**Ambiguous — let the user choose:**
```
User: "Pull up our notes on caching."
Phase 1: hindsight_recall("caching")
         → several candidates (CDN caching decision, app-layer cache research, ...)
         → present the ranked list, STOP, ask which one.
Phase 2: load the chosen one.
```
