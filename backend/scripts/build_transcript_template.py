from __future__ import annotations

import json
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent
CATALOG_PATH = BACKEND_ROOT / "content" / "cms_catalog.json"
MARKDOWN_PATH = BACKEND_ROOT / "content" / "transcript_intake_template.md"
PLACEHOLDER = "[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]"


def build_markdown(catalog: dict) -> str:
    total = sum(len(course["items"]) for course in catalog["courses"])
    lines = [
        "# CareerLoop video transcript intake",
        "",
        f"This file maps {total} videos across {len(catalog['courses'])} "
        "courses to source-grounded transcript context for the study agent.",
        "",
        "## How to fill it",
        "",
        "1. Open the linked recording and generate its transcript.",
        f"2. Replace `{PLACEHOLDER}` only inside that video's START and END "
        "markers.",
        "3. Keep every heading, `video_id`, Drive link, and marker unchanged.",
        "4. Use `[inaudible]` for unclear audio instead of guessing.",
        "5. Leave unprocessed video placeholders unchanged; the importer skips "
        "them.",
        "",
        "Only text between matching transcript markers is ingested. Metadata "
        "outside the markers is used for identification and review.",
        "",
    ]

    for course in catalog["courses"]:
        lines.extend(
            [
                f"## {course['title']} ({course['catalog_code']})",
                "",
                course["description"],
                "",
            ]
        )
        for item in course["items"]:
            lines.extend(
                [
                    f"### {item['title']}",
                    "",
                    f"- `video_id`: `{item['id']}`",
                    f"- `content_type`: `{item['content_type']}`",
                    f"- `source`: [Open Google Drive video]({item['drive_url']})",
                    "",
                    "#### Transcript context",
                    "",
                    f"<!-- TRANSCRIPT START: {item['id']} -->",
                    PLACEHOLDER,
                    f"<!-- TRANSCRIPT END: {item['id']} -->",
                    "",
                ]
            )
    return "\n".join(lines).rstrip() + "\n"


def validate_markdown(catalog: dict, markdown: str) -> None:
    item_ids = [
        item["id"]
        for course in catalog["courses"]
        for item in course["items"]
    ]
    if len(item_ids) != len(set(item_ids)):
        raise RuntimeError("The CMS catalog contains duplicate video IDs.")
    if markdown.count("<!-- TRANSCRIPT START:") != len(item_ids):
        raise RuntimeError("Transcript START marker count is incorrect.")
    if markdown.count("<!-- TRANSCRIPT END:") != len(item_ids):
        raise RuntimeError("Transcript END marker count is incorrect.")
    if markdown.count(PLACEHOLDER) != len(item_ids) + 1:
        raise RuntimeError("Transcript placeholder count is incorrect.")
    for video_id in item_ids:
        if markdown.count(f"<!-- TRANSCRIPT START: {video_id} -->") != 1:
            raise RuntimeError(f"Invalid START marker for {video_id}.")
        if markdown.count(f"<!-- TRANSCRIPT END: {video_id} -->") != 1:
            raise RuntimeError(f"Invalid END marker for {video_id}.")


def main() -> None:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    markdown = build_markdown(catalog)
    validate_markdown(catalog, markdown)
    MARKDOWN_PATH.write_text(markdown, encoding="utf-8")
    total = sum(len(course["items"]) for course in catalog["courses"])
    print(MARKDOWN_PATH)
    print(f"Validated {total} Markdown transcript placeholders.")


if __name__ == "__main__":
    main()
