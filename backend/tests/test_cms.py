import json

from app.cms import CmsService, supplemental_video_catalog
from app.cms import SupplementalVideoCatalog
from app.cms_live import CMS_COURSE_LIST_PATH, GiuCmsClient
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
                "season": "Winter 2024",
                "season_id": 64,
            },
            {
                "id": "course_ai",
                "code": "CSEN901",
                "title": "Agentic Artificial Intelligence",
                "cms_label": "Agentic Artificial Intelligence (|CSEN901|)",
                "resource_count": None,
                "season": "Spring 2024",
                "season_id": 65,
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


class FakeGucLiveClient(FakeLiveClient):
    site_name = "guc"


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
    winter = service.list_courses(season="Winter 2024")["courses"]
    assert [course["id"] for course in winter] == ["course_dsa"]

    dsa = service.course_content("course_dsa")
    ai = service.course_content("course_ai")
    assert len(dsa["cms_resources"]) == 1
    assert len(dsa["available_videos"]) == 53
    assert len(ai["cms_resources"]) == 1
    assert ai["available_videos"] == []


def test_guc_cms_uses_guc_paths_without_giu_drive_supplements() -> None:
    client = GiuCmsClient("student", "secret", site="guc")

    assert client.base_url == "https://cms.guc.edu.eg"
    assert client.course_list_path == "/apps/student/ViewAllCourseStn"
    assert client.course_view_path == "/apps/student/CourseViewStn.aspx"

    service = CmsService(FakeGucLiveClient())
    listing = service.list_courses(season="Winter 2024")
    assert listing["source"] == "GUC CMS"
    assert listing["courses"][0]["has_supplemental_videos"] is False
    assert listing["courses"][0]["video_count"] == 0
    assert service.course_content("course_dsa")["available_videos"] == []
    client.close()


def test_live_cms_html_parsers_cover_course_links_and_resources() -> None:
    client = GiuCmsClient("student", "secret")
    table_html = """
    <table>
      <tr>
        <th></th><th>Name</th><th>Active</th><th>Season</th>
        <th>ID</th><th>SeasonId</th>
      </tr>
      <tr>
        <td></td>
        <td>(|CSEN301|) Data Structures and Algorithms (436)</td>
        <td>Active</td><td>Winter 2024</td><td>436</td><td>64</td>
      </tr>
    </table>
    """
    table_courses = client._parse_course_table(table_html)
    assert len(table_courses) == 1
    assert table_courses[0]["code"] == "CSEN301"
    assert table_courses[0]["season"] == "Winter 2024"
    assert (
        client._course_urls[table_courses[0]["id"]]
        == "https://cms.giu-uni.de/apps/student/"
        "CourseViewStn.aspx?id=436&sid=64"
    )

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


def test_cms_explicit_week_labels_keep_their_own_resources() -> None:
    client = GiuCmsClient("student", "secret")
    html = """
    <div class="menu-header-title">
      <span>Data Structures and Algorithms (|CSEN301|)</span>
    </div>
    <div class="card mb-5 weeksdata">
      <div class="card-header"><h2 class="text-big">2026-02-10</h2></div>
      <p class="p2">Final review announcement</p>
      <p class="p2">Week 13</p>
      <div class="card-body">
        <div><strong>13 - Final review (Lecture)</strong></div>
        <div>Final material</div>
        <a id="download" href="/Uploads/final-review.pdf">Download</a>
      </div>
    </div>
    <div class="card mb-5 weeksdata">
      <div class="card-header"><h2 class="text-big">2026-05-10</h2></div>
      <p class="p2">Welcome announcement</p>
      <p class="p2">Week 1</p>
      <div class="card-body">
        <div><strong>1 - Introduction (Lecture)</strong></div>
        <div>First lecture</div>
        <a id="download" href="/Uploads/introduction.pdf">Download</a>
      </div>
    </div>
    """

    _code, _title, resources = client._parse_resources(
        html,
        page_url=(
            "https://cms.giu-uni.de/apps/student/CourseViewStn.aspx?id=42"
        ),
    )
    weeks_by_title = {
        resource["title"]: resource["week"] for resource in resources
    }

    assert weeks_by_title == {
        "Final review (Lecture)": 13,
        "Introduction (Lecture)": 1,
    }
    client.close()


def test_view_all_courses_maps_historical_seasons_and_drive_videos() -> None:
    client = GiuCmsClient("student", "secret")
    html = """
    <div><strong>Season : 68 , Title: Spring 2026</strong></div>
    <div><strong>Current Season</strong></div>
    <table>
      <tr><th>Name</th><th>Active</th></tr>
      <tr>
        <td>(|ICS603|) Advanced Machine Learning (2719)</td>
        <td>Active</td>
      </tr>
    </table>
    <div class="season-heading">
      <span>Season :</span><strong>67</strong>
      <span>, Title: Winter 2025</span>
    </div>
    <table>
      <tr><th>Name</th><th>Active</th></tr>
      <tr>
        <td>(|CSEN301|) Data Structures and Algorithms (2617)</td>
        <td>Active</td>
      </tr>
      <tr>
        <td>
          <a href="/apps/student/CourseViewStn.aspx?id=2620&amp;sid=67">
            (|ICS504|) Machine Learning (2620)
          </a>
        </td>
        <td>Active</td>
      </tr>
    </table>
    """

    courses = client._parse_all_course_seasons(
        html,
        page_url=(
            "https://cms.giu-uni.de/apps/student/ViewAllCourseStn.aspx"
        ),
    )

    assert CMS_COURSE_LIST_PATH == "/apps/student/ViewAllCourseStn.aspx"
    assert [(course["season_id"], course["season"]) for course in courses] == [
        (68, "Spring 2026"),
        (67, "Winter 2025"),
        (67, "Winter 2025"),
    ]
    dsa = next(course for course in courses if course["code"] == "CSEN301")
    assert dsa["title"] == "Data Structures and Algorithms"
    assert dsa["active"] is True
    assert (
        client._course_urls[dsa["id"]]
        == "https://cms.giu-uni.de/apps/student/"
        "CourseViewStn.aspx?id=2617&sid=67"
    )

    class ParsedClient:
        def list_courses(self, *, force: bool = False):
            return courses

        def close(self):
            pass

    service = CmsService(ParsedClient())
    winter = service.list_courses(season="Winter 2025")
    assert [course["code"] for course in winter["courses"]] == [
        "CSEN301",
        "ICS504",
    ]
    dsa_summary = next(
        course
        for course in winter["courses"]
        if course["code"] == "CSEN301"
    )
    assert dsa_summary["has_supplemental_videos"] is True
    assert dsa_summary["video_count"] == 53
    client.close()


def test_video_transcripts_begin_in_pending_state() -> None:
    _, videos = supplemental_video_catalog.videos_for(
        title="Programming 2"
    )
    result = supplemental_video_catalog.video_transcript(videos[0]["id"])

    assert result["status"] == "pending"
    assert result["transcript"] is None


def test_filled_intake_markdown_is_immediately_available_to_the_agent(
    tmp_path,
) -> None:
    video_id = "drive-video-1"
    catalog_path = tmp_path / "catalog.json"
    intake_path = tmp_path / "intake.md"
    transcript_dir = tmp_path / "transcripts"
    catalog_path.write_text(
        json.dumps(
            {
                "courses": [
                    {
                        "slug": "algorithms",
                        "catalog_code": "DSA",
                        "title": "Data Structures and Algorithms",
                        "aliases": ["DSA"],
                        "source_folders": [],
                        "items": [
                            {
                                "id": video_id,
                                "title": "Hash tables",
                                "content_type": "lecture",
                                "transcript_status": "pending",
                                "transcript_file": None,
                            }
                        ],
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    intake_path.write_text(
        f"""
<!-- TRANSCRIPT START: {video_id} -->
Hash tables use a hash function to map keys into buckets.
<!-- TRANSCRIPT END: {video_id} -->
""",
        encoding="utf-8",
    )
    catalog = SupplementalVideoCatalog(
        catalog_path,
        transcript_dir=transcript_dir,
        intake_path=intake_path,
    )

    summary, videos = catalog.videos_for(title="Data Structures and Algorithms")
    transcript = catalog.video_transcript(video_id)

    assert summary["transcribed_count"] == 1
    assert videos[0]["transcript_status"] == "available"
    assert transcript["status"] == "available"
    assert "hash function" in transcript["transcript"]
    assert transcript["source"] == f"transcript_intake_template.md#{video_id}"


def test_cms_routes_are_published() -> None:
    paths = app.openapi()["paths"]

    assert "/v1/cms/courses" in paths
    assert "/v1/cms/courses/{course}/content" in paths
    assert "/v1/cms/items/{video_id}/transcript" in paths
    assert "/v1/cms/resources/{resource_id}/download" in paths
