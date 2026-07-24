from app.cms import CmsService, supplemental_video_catalog
from app.cms_live import GiuCmsClient
from app.main import app


class FakeLiveClient:
    def list_courses(self, *, force: bool = False):
        return [
            {
                "id": "course_dsa",
                "code": "CSEN301",
                "title": "Data Structures and Algorithms",
                "cms_label": "Data Structures and Algorithms (|CSEN301|)",
                "resource_count": None,
            },
            {
                "id": "course_ai",
                "code": "CSEN901",
                "title": "Agentic Artificial Intelligence",
                "cms_label": "Agentic Artificial Intelligence (|CSEN901|)",
                "resource_count": None,
            },
        ]

    def course_content(self, course_id: str):
        course = next(
            course
            for course in self.list_courses()
            if course["id"] == course_id
        )
        return {
            **course,
            "resource_count": 1,
            "resources": [
                {
                    "id": "resource_1",
                    "title": "Week 1 slides",
                    "subtitle": "Introduction",
                    "content_type": "Lecture",
                    "file_extension": "pdf",
                    "week": 1,
                    "week_label": "Week 1",
                    "is_vod": False,
                    "download_path": (
                        "/v1/cms/resources/resource_1/download"
                    ),
                }
            ],
        }

    def close(self):
        pass


def test_supplemental_catalog_contains_all_drive_videos() -> None:
    counts = {
        course["slug"]: len(course["items"])
        for course in supplemental_video_catalog._catalog["courses"]
    }
    assert counts == {
        "data-structures-and-algorithms": 53,
        "programming-2": 10,
        "computer-organization": 29,
        "digital-logic-design": 34,
        "math-4": 27,
    }
    assert sum(counts.values()) == 153


def test_live_catalog_is_complete_and_videos_are_only_supplemental() -> None:
    service = CmsService(FakeLiveClient())
    courses = service.list_courses()["courses"]

    assert [course["id"] for course in courses] == [
        "course_dsa",
        "course_ai",
    ]
    assert courses[0]["video_count"] == 53
    assert courses[0]["has_supplemental_videos"] is True
    assert courses[1]["video_count"] == 0
    assert courses[1]["has_supplemental_videos"] is False

    dsa = service.course_content("course_dsa")
    ai = service.course_content("course_ai")
    assert len(dsa["cms_resources"]) == 1
    assert len(dsa["available_videos"]) == 53
    assert len(ai["cms_resources"]) == 1
    assert ai["available_videos"] == []


def test_live_cms_html_parsers_cover_course_links_and_resources() -> None:
    client = GiuCmsClient("student", "secret")
    list_html = """
    <html><body>
      <a href="/apps/student/Course/Details?id=42">
        Data Structures and Algorithms (|CSEN301|)
      </a>
      <a href="/apps/student/profile">Profile</a>
    </body></html>
    """
    courses = client._parse_course_links(
        list_html,
        page_url="https://cms.giu-uni.de/apps/student/",
    )
    assert len(courses) == 1
    assert courses[0]["code"] == "CSEN301"

    detail_html = """
    <div class="menu-header-title">
      <span>Data Structures and Algorithms (|CSEN301|)</span>
    </div>
    <div class="card mb-5 weeksdata">
      <div class="card-header"><h2 class="text-big">2026-02-10</h2></div>
      <div><div><div><div class="card-body">
        <div><strong>1 - Complexity slides (Lecture)</strong></div>
        <div>Asymptotic analysis</div>
        <a id="download" href="/apps/student/files/week1.pdf">Download</a>
      </div></div></div></div>
    </div>
    """
    code, title, resources = client._parse_resources(
        detail_html,
        page_url=(
            "https://cms.giu-uni.de/apps/student/Course/Details?id=42"
        ),
    )
    assert code == "CSEN301"
    assert title == "Data Structures and Algorithms"
    assert resources[0]["title"] == "Complexity slides (Lecture)"
    assert resources[0]["file_extension"] == "pdf"
    assert resources[0]["download_path"].startswith("/v1/cms/resources/")
    client.close()


def test_video_transcripts_begin_in_pending_state() -> None:
    _, videos = supplemental_video_catalog.videos_for(
        title="Programming 2"
    )
    result = supplemental_video_catalog.video_transcript(videos[0]["id"])

    assert result["status"] == "pending"
    assert result["transcript"] is None


def test_cms_routes_are_published() -> None:
    paths = app.openapi()["paths"]

    assert "/v1/cms/courses" in paths
    assert "/v1/cms/courses/{course}/content" in paths
    assert "/v1/cms/items/{video_id}/transcript" in paths
    assert "/v1/cms/resources/{resource_id}/download" in paths
