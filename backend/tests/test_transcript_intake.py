from __future__ import annotations

import json
from pathlib import Path

from scripts.import_transcript_intake import read_blocks


BACKEND_ROOT = Path(__file__).resolve().parent.parent
CATALOG_PATH = BACKEND_ROOT / "content" / "cms_catalog.json"
MARKDOWN_PATH = BACKEND_ROOT / "content" / "transcript_intake_template.md"


def _item_ids() -> list[str]:
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    return [
        item["id"]
        for course in catalog["courses"]
        for item in course["items"]
    ]


def test_generated_markdown_maps_every_marker_to_its_video_id() -> None:
    item_ids = _item_ids()
    blocks = read_blocks(MARKDOWN_PATH, item_ids)

    assert list(blocks) == item_ids
    assert len(blocks) == 153
