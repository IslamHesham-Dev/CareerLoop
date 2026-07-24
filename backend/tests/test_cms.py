from app.cms import cms_service
from app.main import app


def test_cms_catalog_contains_all_inventoried_drive_videos() -> None:
    result = cms_service.list_courses()
    counts = {
        course["slug"]: course["video_count"]
        for course in result["courses"]
    }

    assert counts == {
        "data-structures-and-algorithms": 53,
        "programming-2": 10,
        "computer-organization": 29,
        "digital-logic-design": 34,
        "math-4": 27,
    }
    assert sum(counts.values()) == 153
    all_items = [
        item
        for course in result["courses"]
        for item in cms_service.course_content(course["slug"])["items"]
    ]
    assert len({item["id"] for item in all_items}) == 153
    assert all(
        item["drive_url"].startswith("https://drive.google.com/file/d/")
        for item in all_items
    )


def test_cms_course_lookup_accepts_alias_and_content_filter() -> None:
    result = cms_service.course_content("DSA", "tutorial")

    assert result["course"]["title"] == "Data Structures and Algorithms"
    assert len(result["items"]) == 33
    assert {item["content_type"] for item in result["items"]} == {
        "tutorial"
    }


def test_video_transcripts_begin_in_pending_state() -> None:
    item = cms_service.course_content("Programming 2")["items"][0]

    result = cms_service.video_transcript(item["id"])

    assert result["status"] == "pending"
    assert result["transcript"] is None


def test_cms_routes_are_published() -> None:
    paths = app.openapi()["paths"]

    assert "/v1/cms/courses" in paths
    assert "/v1/cms/courses/{course}/content" in paths
    assert "/v1/cms/items/{video_id}/transcript" in paths
