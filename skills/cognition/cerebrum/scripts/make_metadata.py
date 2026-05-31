#!/usr/bin/env python3
"""Generate normalized archival metadata + a stable document_id for storing a
document in the agent's long-term brain (Hindsight) -- and, when possible, CHECK
the brain to stop accidental overwrites.

Why this exists:
- Consistent metadata makes documents findable AND improves fact extraction.
- A DETERMINISTIC id from type + title is the hinge for in-place updates:
  re-archiving the same document under the same id REPLACES its facts (upsert),
  while a different document sharing type+title would SILENTLY CLOBBER it.
- So this script can query Hindsight for an id collision and refuse to proceed
  unless the caller explicitly asserts an update with --update. This moves the
  collision guard off the agent's memory and into a deterministic check.

Collision logic:
- No existing document with this id            -> emit metadata (safe to archive).
- Existing id AND --update passed              -> emit metadata (deliberate update/upsert).
- Existing id AND no --update                  -> REFUSE (exit 3). Caller must either
                                                  pass --update (deliberate replace) or
                                                  change the title (distinct document).
- Cannot reach the API to check                -> FAIL OPEN: emit metadata with a loud
                                                  warning. --update is still the gate; the
                                                  check is a convenience that catches
                                                  accidents, not the last line of defense.

Connection (never hardcode; resolved from env, matching the Hermes/Hindsight setup):
- HINDSIGHT_API_URL  (e.g. http://localhost:8888 or the embedded daemon URL)
- HINDSIGHT_BANK_ID  (the memory bank to check/write)
- HINDSIGHT_API_KEY  (optional; sent as Authorization if present)
Use --no-check to skip the network check entirely (pure metadata generation).

Usage:
    python make_metadata.py --title "Auth migration handover" --type handover
    python make_metadata.py --title "Auth migration handover" --type handover --update
    python make_metadata.py --title "Q3 caching research" --type research --no-check --json-only

Exit codes:
    0  metadata emitted (no collision, or --update, or fail-open, or --no-check)
    2  bad input (e.g. empty/unsluggable title)
    3  id collision and --update was not passed (deliberate stop)
"""

import argparse
import datetime
import json
import os
import re
import sys
import unicodedata
import urllib.error
import urllib.parse
import urllib.request

# Standard artifact types. Short and stable so filtering/listing stays consistent.
KNOWN_TYPES = ("handover", "research", "decision", "reference", "report", "note")

# Slug ceiling: readable ids, safely under backend id limits.
MAX_SLUG_LEN = 80

# Network check timeout (seconds). Short: the check is a convenience, and we must
# not hang archival waiting on a slow/unreachable brain. 5s balances a real
# local/remote round trip against not blocking the agent.
CHECK_TIMEOUT_SECONDS = 5


def slugify(text: str) -> str:
    """Deterministic, id-safe slug: same input -> same slug (enables in-place update)."""
    normalized = unicodedata.normalize("NFKD", text)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text.lower()).strip("-")
    if len(slug) > MAX_SLUG_LEN:
        slug = slug[:MAX_SLUG_LEN].rstrip("-")
    return slug


def build_document_id(title: str, type_: str) -> str:
    """Compose a deterministic, type-prefixed id.

    Type prefix prevents same-title/different-type collisions (a 'decision' and a
    'report' about the same subject get distinct ids).
    """
    title_slug = slugify(title)
    if not title_slug:
        print(
            "ERROR: title produced an empty slug (no letters/numbers). "
            "Provide a title with at least one alphanumeric character.",
            file=sys.stderr,
        )
        sys.exit(2)
    type_slug = slugify(type_) or "note"
    return f"{type_slug}-{title_slug}"


def build_metadata(title: str, type_: str, tags, date_str: str) -> dict:
    meta = {"title": title.strip(), "type": type_, "date": date_str}
    if tags:
        meta["tags"] = tags
    return meta


def _resolve_connection():
    """Read connection details from env. Returns (api_url, bank_id, api_key) or None
    if the minimum (api_url + bank_id) isn't available."""
    api_url = os.environ.get("HINDSIGHT_API_URL", "").rstrip("/")
    bank_id = os.environ.get("HINDSIGHT_BANK_ID", "")
    api_key = os.environ.get("HINDSIGHT_API_KEY", "")
    if not api_url or not bank_id:
        return None
    return api_url, bank_id, api_key


def document_exists(api_url: str, bank_id: str, api_key: str, document_id: str):
    """Check whether a document_id already has memory units in the bank.

    Uses the graph endpoint filtered by document_id: a non-empty result means the
    document exists. Returns:
        True  -> exists
        False -> does not exist
        None  -> could not determine (network/API error) -> caller should fail open
    """
    # /v1/default/banks/{bank}/graph?document_id=...  -- total_units > 0 means present.
    path = f"/v1/default/banks/{urllib.parse.quote(bank_id)}/graph"
    query = urllib.parse.urlencode({"document_id": document_id, "limit": 1})
    url = f"{api_url}{path}?{query}"

    req = urllib.request.Request(url, method="GET")
    req.add_header("Accept", "application/json")
    if api_key:
        req.add_header("Authorization", api_key)

    try:
        with urllib.request.urlopen(req, timeout=CHECK_TIMEOUT_SECONDS) as resp:
            body = resp.read().decode("utf-8")
        data = json.loads(body)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError,
            ValueError) as exc:
        # Unreachable, auth failure, timeout, or unparseable response -- cannot
        # determine existence. Signal "unknown" so the caller fails open.
        print(f"NOTE: could not verify id against Hindsight ({exc}).", file=sys.stderr)
        return None

    # total_units is the authoritative count; fall back to len(nodes) if absent.
    total = data.get("total_units")
    if total is None:
        nodes = data.get("nodes") or []
        total = len(nodes)
    return total > 0


def parse_args(argv):
    p = argparse.ArgumentParser(
        description="Generate archival metadata + stable document_id, with an optional "
        "live collision check against Hindsight.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument(
        "--title", required=True,
        help="Human-meaningful title. Combined with --type to form the deterministic id; "
        "keep BOTH stable across edits so updates replace in place.",
    )
    p.add_argument(
        "--type", default="note",
        help=f"Artifact category. Recognized: {', '.join(KNOWN_TYPES)}. Unknown types are "
        "accepted but warned about (they fragment later filtering).",
    )
    p.add_argument(
        "--tags", default="",
        help="Optional comma-separated tags for finer filtering (e.g. 'backend,perf').",
    )
    p.add_argument(
        "--date", default=None,
        help="Archive date (YYYY-MM-DD). Defaults to today (UTC).",
    )
    p.add_argument(
        "--update", action="store_true",
        help="Assert that overwriting an existing document under this id is INTENTIONAL "
        "(a deliberate update/upsert). Required to proceed when the id already exists.",
    )
    p.add_argument(
        "--no-check", action="store_true",
        help="Skip the live Hindsight collision check; generate metadata only. Use when "
        "offline by design or when the agent will check existence itself.",
    )
    p.add_argument(
        "--json-only", action="store_true",
        help="Print only the JSON object (id + metadata), no human-readable summary.",
    )
    return p.parse_args(argv)


def emit(payload, json_only, note=None):
    if json_only:
        print(json.dumps(payload, indent=2))
        return
    meta = payload["metadata"]
    print("Archival metadata generated.\n")
    print(f"  document_id : {payload['document_id']}")
    print(f"  title       : {meta['title']}")
    print(f"  type        : {meta['type']}")
    print(f"  date        : {meta['date']}")
    if meta.get("tags"):
        print(f"  tags        : {', '.join(meta['tags'])}")
    if note:
        print(f"\n  {note}")
    print("\nPass these to the retain call:")
    print("  - document_id  -> the retain call's document_id")
    print("  - metadata     -> the retain call's metadata\n")
    print("JSON:")
    print(json.dumps(payload, indent=2))


def main(argv):
    args = parse_args(argv)

    if args.type not in KNOWN_TYPES:
        print(
            f"WARNING: '{args.type}' is not a standard type ({', '.join(KNOWN_TYPES)}). "
            "Using it anyway, but consider a standard type for consistent filtering.",
            file=sys.stderr,
        )

    date_str = args.date or datetime.datetime.now(datetime.timezone.utc).date().isoformat()
    tags = [t.strip() for t in args.tags.split(",") if t.strip()]

    document_id = build_document_id(args.title, args.type)
    metadata = build_metadata(args.title, args.type, tags, date_str)
    payload = {"document_id": document_id, "metadata": metadata}

    # --- Collision check ---------------------------------------------------
    if args.no_check:
        emit(payload, args.json_only,
             note="Collision check SKIPPED (--no-check). Ensure this id is safe to write.")
        return

    conn = _resolve_connection()
    if conn is None:
        # No connection info -> cannot check -> fail open with a loud warning.
        print(
            "WARNING: HINDSIGHT_API_URL / HINDSIGHT_BANK_ID not set, so the id collision "
            "check could NOT run. Proceeding (fail-open). If a document with id "
            f"'{document_id}' already exists, retaining will OVERWRITE it. Pass --update "
            "only if that is intended, or set the env vars to enable the check.",
            file=sys.stderr,
        )
        emit(payload, args.json_only, note="Collision check could not run (no connection).")
        return

    api_url, bank_id, api_key = conn
    exists = document_exists(api_url, bank_id, api_key, document_id)

    if exists is None:
        # API unreachable/errored -> fail open with a loud warning.
        print(
            "WARNING: could not reach Hindsight to check for an id collision. Proceeding "
            f"(fail-open). If a document with id '{document_id}' already exists, retaining "
            "will OVERWRITE it. Pass --update only if that is intended.",
            file=sys.stderr,
        )
        emit(payload, args.json_only, note="Collision check could not run (API unreachable).")
        return

    if not exists:
        # Clean: no collision.
        emit(payload, args.json_only, note="No existing document with this id -- safe to archive.")
        return

    # exists is True from here.
    if args.update:
        emit(payload, args.json_only,
             note="Existing document with this id WILL BE UPDATED in place (--update).")
        return

    # Collision and no --update: deliberate stop.
    print(
        f"COLLISION: a document with id '{document_id}' already exists in bank "
        f"'{bank_id}'.\n"
        "This script will NOT emit metadata, to avoid silently overwriting it.\n\n"
        "Decide which case applies:\n"
        "  - This is an UPDATE to that document  -> re-run with --update.\n"
        "  - This is a DIFFERENT document         -> give it a distinct --title so it "
        "gets its own id.\n"
        "  - The two cover the same topic         -> consider merging into the existing "
        "document, then --update.\n",
        file=sys.stderr,
    )
    sys.exit(3)


if __name__ == "__main__":
    main(sys.argv[1:])
