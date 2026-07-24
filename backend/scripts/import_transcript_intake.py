from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent
CATALOG_PATH = BACKEND_ROOT / "content" / "cms_catalog.json"
TRANSCRIPT_DIR = BACKEND_ROOT / "content" / "transcripts"
PLACEHOLDER = "[PASTE TRANSCRIPT OR DETAILED SUMMARY HERE]"
BLOCK = re.compile(
    r"<!-- TRANSCRIPT START: (?P<id>[^ ]+) -->\s*"
    r"(?P<text>.*?)\s*"
    r"<!-- TRANSCRIPT END: (?P=id) -->",
    re.DOTALL,
)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Import completed CareerLoop transcript intake Markdown."
    )
    parser.add_argument("input", type=Path)
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace transcript files that already exist.",
    )
    args = parser.parse_args()

    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    items = {
        item["id"]: (course, item)
        for course in catalog["courses"]
        for item in course["items"]
    }
    blocks = {
        match.group("id"): match.group("text").strip()
        for match in BLOCK.finditer(args.input.read_text(encoding="utf-8"))
    }
    unknown = sorted(set(blocks) - set(items))
    if unknown:
        raise SystemExit(f"Unknown Drive file IDs: {unknown}")

    TRANSCRIPT_DIR.mkdir(parents=True, exist_ok=True)
    imported = 0
    skipped = 0
    for video_id, text in blocks.items():
        if not text or text == PLACEHOLDER:
            skipped += 1
            continue
        course, item = items[video_id]
        destination = TRANSCRIPT_DIR / f"{video_id}.md"
        if destination.exists() and not args.overwrite:
            raise SystemExit(
                f"{destination.name} already exists; use --overwrite "
                "only after reviewing the replacement."
            )
        document = (
            f"# {item['title']}\n\n"
            f"- Course: {course['title']}\n"
            f"- Drive file ID: `{video_id}`\n"
            f"- Type: {item['content_type']}\n"
            f"- Video: {item['drive_url']}\n\n"
            "## Transcript or detailed summary\n\n"
            f"{text}\n"
        )
        destination.write_text(document, encoding="utf-8")
        item["transcript_status"] = "available"
        item["transcript_file"] = f"transcripts/{video_id}.md"
        imported += 1

    temporary_catalog = CATALOG_PATH.with_suffix(".json.tmp")
    temporary_catalog.write_text(
        json.dumps(catalog, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary_catalog.replace(CATALOG_PATH)
    print(f"Imported {imported} transcript(s); skipped {skipped} blank entry(s).")


if __name__ == "__main__":
    main()
