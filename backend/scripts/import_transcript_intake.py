from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent
CATALOG_PATH = BACKEND_ROOT / "content" / "cms_catalog.json"
TRANSCRIPT_DIR = BACKEND_ROOT / "content" / "transcripts"
PLACEHOLDERS = {
    "[PASTE TRANSCRIPT OR DETAILED SUMMARY HERE]",
    "[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]",
}
BLOCK = re.compile(
    r"<!-- TRANSCRIPT START: (?P<id>[^ ]+) -->\s*"
    r"(?P<text>.*?)\s*"
    r"<!-- TRANSCRIPT END: (?P=id) -->",
    re.DOTALL,
)


def read_blocks(path: Path, item_ids: list[str]) -> dict[str, str]:
    if path.suffix.lower() not in {".md", ".markdown"}:
        raise SystemExit("Transcript intake must be a Markdown file.")
    text = path.read_text(encoding="utf-8")
    matches = list(BLOCK.finditer(text))
    matched_ids = [match.group("id") for match in matches]
    duplicates = sorted(
        video_id
        for video_id in set(matched_ids)
        if matched_ids.count(video_id) > 1
    )
    if duplicates:
        raise SystemExit(f"Duplicate transcript markers: {duplicates}")
    blocks = {
        match.group("id"): match.group("text").strip()
        for match in matches
    }
    missing = sorted(set(item_ids) - set(blocks))
    if missing:
        raise SystemExit(
            f"Missing {len(missing)} catalog transcript block(s). "
            "Use a fresh generated template and keep blank placeholders."
        )
    return blocks


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Import a completed CareerLoop transcript Markdown file."
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
    blocks = read_blocks(args.input, list(items))
    unknown = sorted(set(blocks) - set(items))
    if unknown:
        raise SystemExit(f"Unknown Drive file IDs: {unknown}")

    TRANSCRIPT_DIR.mkdir(parents=True, exist_ok=True)
    imported = 0
    skipped = 0
    for video_id, text in blocks.items():
        if not text or text in PLACEHOLDERS:
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
