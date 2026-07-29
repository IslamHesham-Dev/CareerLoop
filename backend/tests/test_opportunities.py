from __future__ import annotations

from datetime import UTC, datetime

import pytest

from app.opportunities import CourseCatalog, OpportunityService
from swelist_connector.models import JobPosting


class FakeSwelistConnector:
    def __init__(self) -> None:
        self.request = None

    def get_postings(self, **kwargs):
        self.request = kwargs
        return [
            JobPosting(
                company="Example Cloud",
                title="Junior Backend Software Engineer",
                location="Berlin, Germany · Remote",
                link="https://example.com/backend",
            ),
            JobPosting(
                company="Example Retail",
                title="Store Operations Graduate",
                location="Berlin, Germany",
                link="https://example.com/retail",
            ),
        ]


class SingleJobConnector:
    def __init__(self, title: str, category: str | None = None) -> None:
        self.title = title
        self.category = category

    def get_postings(self, **_kwargs):
        return [
            JobPosting(
                company="Example",
                title=self.title,
                category=self.category,
                location="Berlin, Germany",
                link=f"https://example.com/{self.title.replace(' ', '-')}",
            )
        ]


def test_profile_aware_swelist_search_returns_gaps_and_courses() -> None:
    connector = FakeSwelistConnector()
    service = OpportunityService(connector=connector)  # type: ignore[arg-type]

    result = service.search(
        role_type="newgrad",
        timeframe="lastweek",
        target_market="europe",
        locations=["Berlin"],
        keywords=["backend", "python"],
        work_modes=["remote"],
        transcript={
            "courses": [
                {
                    "course": "Data Structures and Algorithms",
                    "grade": "A",
                    "numeric": "1.2",
                    "semester": "Winter 2023",
                },
                {"course": "Software Engineering", "grade": "A-"},
            ]
        },
        linkedin_profile={"skills": ["Python", "Git"]},
        github_profile={
            "skills": [
                {
                    "skill": "Docker",
                    "category": "devops",
                    "evidence_repos": ["careerloop"],
                }
            ],
            "repositories": [
                {
                    "name": "careerloop",
                    "description": "FastAPI backend",
                    "detected_skills": ["Docker"],
                }
            ],
        },
        limit=10,
    )

    assert connector.request == {
        "role": "newgrad",
        "timeframe": "lastweek",
        "location": "Berlin",
    }
    assert [job["title"] for job in result["jobs"]] == [
        "Junior Backend Software Engineer"
    ]
    job = result["jobs"][0]
    assert "python" in job["profile_skill_matches"]
    assert "rest api" in job["profile_skill_matches"]
    assert "databases" in job["inferred_skill_gaps"]
    assert job["recommended_course_ids"]
    assert result["evidence"] == {
        "academic_transcript": True,
        "linkedin_pdf": True,
        "github": True,
        "resume": False,
    }
    assert result["recommended_courses"]
    assert "docker" in job["profile_skill_matches"]
    assert job["match_score"] <= 92
    assert any(
        citation["source"] == "academic"
        and citation["title"] == "Data Structures and Algorithms"
        and "Grade A" in citation["detail"]
        for citation in job["evidence_citations"]
    )
    assert any(
        citation["source"] == "github"
        and citation["title"] == "careerloop"
        for citation in job["evidence_citations"]
    )
    assert all(
        course["platform"] == "Coursera"
        for course in result["recommended_courses"]
    )


def test_swelist_connector_filters_structured_feed_without_cli(
    monkeypatch,
) -> None:
    from swelist_connector.client import SwelistConnector

    now = datetime.now(UTC).timestamp()
    recent = {
        "company_name": "Recent",
        "title": "Software Engineer",
        "url": "https://example.com/recent",
        "locations": ["Berlin, Germany"],
        "date_posted": now - 60,
    }
    old = {
        "company_name": "Old",
        "title": "Software Engineer",
        "url": "https://example.com/old",
        "locations": ["Berlin, Germany"],
        "date_posted": now - 20 * 24 * 60 * 60,
    }
    connector = SwelistConnector()
    monkeypatch.setattr(
        connector,
        "_load_metadata",
        lambda role: {
            recent["url"]: recent,
            old["url"]: old,
        },
    )

    jobs = connector.get_postings(
        role="newgrad",
        timeframe="lastweek",
    )

    assert len(jobs) == 1
    assert jobs[0].link == recent["url"]
    assert jobs[0].company_logo_url


def test_opportunity_search_caps_expensive_candidate_evaluation() -> None:
    class LargeConnector:
        def get_postings(self, **_kwargs):
            return [
                JobPosting(
                    company=f"Company {index}",
                    title="Backend Software Engineer",
                    location="Global",
                    link=f"https://example.com/{index}",
                )
                for index in range(500)
            ]

    service = OpportunityService(connector=LargeConnector())  # type: ignore[arg-type]
    original_match = service._match_job  # noqa: SLF001
    evaluated = 0

    def tracked_match(posting, **kwargs):
        nonlocal evaluated
        evaluated += 1
        return original_match(posting, **kwargs)

    service._match_job = tracked_match  # type: ignore[method-assign]  # noqa: SLF001
    result = service.search(
        role_type="newgrad",
        timeframe="all",
        target_market="global",
        locations=[],
        keywords=["backend"],
        work_modes=[],
        transcript=None,
        linkedin_profile=None,
        github_profile=None,
        resume_profile=None,
        limit=24,
    )

    assert len(result["jobs"]) == 24
    assert evaluated == 96


def test_resume_evidence_participates_in_matching() -> None:
    connector = FakeSwelistConnector()
    service = OpportunityService(connector=connector)  # type: ignore[arg-type]

    result = service.search(
        role_type="newgrad",
        timeframe="all",
        target_market="europe",
        locations=["Berlin"],
        keywords=["backend"],
        work_modes=[],
        transcript=None,
        linkedin_profile=None,
        resume_profile={
            "raw_text": "Backend engineer using Python and FastAPI.",
            "skills": ["Python", "FastAPI", "Docker"],
            "experience": ["Built REST APIs"],
        },
    )

    assert result["evidence"]["resume"] is True
    assert "python" in result["jobs"][0]["profile_skill_matches"]
    assert not any(
        "Resume evidence is not connected" in item
        for item in result["limitations"]
    )


def test_swelist_structured_feed_keeps_listing_metadata() -> None:
    from swelist_connector.client import SwelistConnector

    item = {
        "source": "Simplify",
        "category": "Software",
        "company_name": "Example Labs",
        "id": "listing-123",
        "title": "Graduate Software Engineer",
        "active": True,
        "is_visible": True,
        "date_posted": 1_700_000_000,
        "date_updated": 1_700_000_100,
        "url": "https://jobs.lever.co/examplelabs/123",
        "locations": ["Berlin, Germany", "Remote"],
        "company_url": "https://simplify.jobs/c/Example-Labs",
        "sponsorship": "Does Not Offer Sponsorship",
        "degrees": ["Bachelors"],
    }
    connector = SwelistConnector()
    jobs = connector._structured_postings(  # noqa: SLF001
        {item["url"]: item},
        location="Berlin",
    )

    assert len(jobs) == 1
    assert jobs[0].external_id == "listing-123"
    assert jobs[0].locations == ("Berlin, Germany", "Remote")
    assert jobs[0].category == "Software"
    assert jobs[0].sponsorship == "Does Not Offer Sponsorship"
    assert jobs[0].degrees == ("Bachelors",)
    assert jobs[0].posted_at is not None
    assert jobs[0].company_logo_url is not None


def test_curated_course_catalog_has_unique_secure_links() -> None:
    courses = CourseCatalog().courses

    assert len(courses) >= 15
    assert len({course["id"] for course in courses}) == len(courses)
    assert all(
        course["url"].startswith("https://www.coursera.org/")
        for course in courses
    )
    assert all(course["skills"] for course in courses)


@pytest.mark.parametrize(
    ("title", "expected_family", "expected_skill", "expected_course"),
    [
        (
            "Computer Vision Research Engineer",
            "machine-learning",
            "computer vision",
            "ibm-machine-learning",
        ),
        (
            "Site Reliability Platform Engineer",
            "devops",
            "kubernetes",
            "ibm-devops",
        ),
        (
            "QA Automation Engineer",
            "qa",
            "test automation",
            "deeplearning-generative-swd",
        ),
        (
            "SAP Functional Consultant",
            "erp",
            "business analysis",
            "google-business-intelligence",
        ),
        (
            "Frontend React Engineer",
            "frontend",
            "react",
            "microsoft-fullstack",
        ),
        (
            "Cloud Security Engineer",
            "security",
            "cybersecurity",
            "google-cybersecurity",
        ),
    ],
)
def test_hidden_title_taxonomy_drives_related_course_suggestions(
    title: str,
    expected_family: str,
    expected_skill: str,
    expected_course: str,
) -> None:
    service = OpportunityService(connector=SingleJobConnector(title))  # type: ignore[arg-type]
    families = service._role_families(title)  # noqa: SLF001
    skills = service._expected_skills(title, None, families)  # noqa: SLF001
    courses = service.catalog.recommend(
        [],
        families,
        target_skills=skills,
        limit=3,
    )

    assert expected_family in families
    assert expected_skill in skills
    assert expected_course in {course["id"] for course in courses}


def test_qualified_candidate_still_receives_role_related_courses() -> None:
    title = "Backend API Engineer"
    connector = SingleJobConnector(title, category="Software")
    service = OpportunityService(connector=connector)  # type: ignore[arg-type]
    families = service._role_families(title, "Software")  # noqa: SLF001
    expected = service._expected_skills(  # noqa: SLF001
        title,
        "Software",
        families,
    )

    result = service.search(
        role_type="newgrad",
        timeframe="all",
        target_market="europe",
        locations=["Berlin"],
        keywords=[],
        work_modes=[],
        transcript=None,
        linkedin_profile={"skills": sorted(expected)},
        github_profile=None,
        resume_profile=None,
    )

    job = result["jobs"][0]
    assert job["inferred_skill_gaps"] == []
    assert job["recommended_course_ids"]
    assert set(job["recommended_course_ids"]).issubset(
        {course["id"] for course in result["recommended_courses"]}
    )
