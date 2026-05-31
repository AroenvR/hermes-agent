# Tooling reference

The exact tool surface, configuration, and gotchas this skill depends on. Read this when unsure what a tool is called, what parameters it takes, or why archival/recall is silently doing nothing.

## Contents
- The three agent-facing tools
- Direct client access (fallback)
- Configuration this skill assumes
- Critical gotchas (read these — they cause silent failures)

## The three agent-facing tools

When the Hindsight provider is active in a Hermes-style host, three tools are registered. Names are exact:

- **`hindsight_retain`** — store information into long-term memory. Used for archiving. Extracts structured facts/entities, stores the original text, indexes everything.
- **`hindsight_recall`** — search long-term memory. Runs multiple retrieval strategies (semantic, keyword/BM25, entity-graph, temporal) in parallel and reranks. Returns relevant matches. This is the default retrieval path.
- **`hindsight_reflect`** — synthesize a reasoned answer *across* many memories. Costs an additional LLM call. Use only when genuine synthesis is needed, not for ordinary lookups.

Prefer these tools when they are available. Confirm they are registered (e.g. a `/tools` listing shows a `hindsight` toolset) before assuming the brain is reachable.

## Direct client access (fallback)

If the agent has shell/Python access and needs operations the three tools don't expose (notably **fetching a full document verbatim** or **listing documents**), use the Hindsight client directly. The connection target comes from host config/env, not from this skill.

```python
from hindsight_client import Hindsight

client = Hindsight(base_url="<from host config/env>")   # do not hardcode

# Store
client.retain(bank_id="<from config>", content="...", document_id="...", metadata={...})

# Search (returns candidates, not full bodies by default)
client.recall(bank_id="<from config>", query="...")

# Synthesize across memories (LLM call)
client.reflect(bank_id="<from config>", query="...")
```

Document-level operations (verbatim retrieval, listing) are part of the Hindsight document API — retrieving a document's `original_text` by its id, and listing/filtering documents by substring or tag. Use these for the "load" phase of retrieval and for verifying reproduction. Consult the running instance's API for the exact method names if the client version differs; the capability is: **store text → get the same text back by document id.**

## Configuration this skill assumes

This skill reads nothing of its own. It relies on the host's Hindsight configuration (typically a provider config file and/or environment variables). The settings that matter for this skill's behavior:

- **Bank selection** — which memory bank to read/write. Comes from host config (often a bank id or a template like `hermes-{profile}`). Never hardcode a bank name in skill usage; use what the host resolves.
- **`memory_mode`** — `hybrid`, `context`, or `tools`. This skill is written to work in any mode, but is designed for **`tools`** mode (deliberate, agent-driven memory; no automatic injection). In `tools` mode the agent MUST call the tools explicitly — which is exactly what this skill instructs.
- **`recall_types`** — see the gotcha below. This one will silently hide your archived documents if left at its default.

**Connection env vars used by `scripts/make_metadata.py`** (for the collision check): `HINDSIGHT_API_URL`, `HINDSIGHT_BANK_ID`, and optional `HINDSIGHT_API_KEY`. If these aren't set, the script can't run the check and fails open with a warning (see [archiving.md](archiving.md)). These mirror the host's own Hindsight connection settings — do not invent values; use the deployment's configured ones.

**Existence-check endpoint** (what the script calls): `GET /v1/default/banks/{bank_id}/graph?document_id=<id>`. A response with `total_units > 0` (or a non-empty `nodes` array) means a document with that id already exists. This is also the right endpoint if the agent needs to check existence manually.

**Living documents** are a distinct first-class feature (the Mental Models API: `GET /v1/default/banks/{bank_id}/mental-models`), separate from document upsert. This skill manages documents via `document_id` upsert; mental models are out of scope here but exist if a deployment wants curated, auto-refreshing living summaries.

## Critical gotchas

These cause setups that *look* healthy but behave wrong. Check them before concluding a feature is broken.

### 1. `recall_types` defaults to `observation` only — this hides documents
Recent provider versions narrowed the fact types surfaced by recall to **`observation`** by default. Archived documents and raw facts live under other types (`world`, `experience`). **If recall isn't surfacing archived documents, this is the most likely cause.** The fix is to widen the surfaced types (e.g. `observation,world,experience`) in host config — this is a host configuration change, not something the skill can override per call. Flag it to the user rather than silently working around it.

### 2. Retain is asynchronous
A freshly retained memory becomes available on a **later** turn, not the same turn. Do not archive something and immediately test recall in the same turn and conclude it failed — that is normal async behavior. To verify, retain, then check on a subsequent turn.

### 3. Auto-behaviors depend on lifecycle hooks (host version)
Automatic recall/retain rely on the host's lifecycle hooks (e.g. `pre_llm_call` / `post_llm_call`). On older host builds the tools register but the *automatic* behaviors are silently skipped. This skill's **deliberate** archival via `hindsight_retain` does not depend on those hooks and works regardless — but do not assume passive conversation capture is happening unless the host version supports the hooks. When in doubt, archive explicitly.

### 4. Same document id upserts (replaces); the script guards against accidents
Retaining with an existing `document_id` **deletes and replaces** that document (upsert). Retaining the same content under a *new* id creates a parallel copy the brain treats as unrelated. The archival helper (`scripts/make_metadata.py`) guards this: it checks for the id and refuses unless `--update` is passed, so accidental overwrites are blocked and deliberate updates are explicit. Always archive edits as an `--update` under the **same** id. See [archiving.md](archiving.md) and [maintenance.md](maintenance.md).

### 5. Tools silently skip registration when unconfigured
If the Hindsight API target (URL or API key) isn't set, the plugin registers nothing and fails quietly. If the tools aren't present at all, suspect missing connection config before suspecting the skill.
