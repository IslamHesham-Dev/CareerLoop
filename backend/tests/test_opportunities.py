from __future__ import annotations

from types import SimpleNamespace

from app.opportunities import CourseCatalog, OpportunityService
from app.schemas.career import OpportunitySearchResponse
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
                {"course": "Data Structures and Algorithms"},
                {"course": "Software Engineering"},
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
    assert all(
        course["platform"] == "Coursera"
        for course in result["recommended_courses"]
    )


def test_swelist_connector_uses_the_active_python_environment(
    monkeypatch,
) -> None:
    from swelist_connector import client as client_module

    captured = {}

    def fake_run(command, **kwargs):
        captured["command"] = command
        return SimpleNamespace(
            stdout=(
                "Company: Example\n"
                "Title: Software Engineer\n"
                "Location: Berlin, Germany\n"
                "Link: https://example.com/job\n"
            )
        )

    monkeypatch.setattr(client_module.subprocess, "run", fake_run)
    monkeypatch.setattr(
        client_module.SwelistConnector,
        "_load_metadata",
        lambda self, role: {},
    )
    jobs = client_module.SwelistConnector().get_postings(
        role="newgrad",
        timeframe="lastweek",
    )

    assert captured["command"][:4] == [
        client_module.sys.executable,
        "-m",
        "swelist.main",
        "run",
    ]
    assert len(jobs) == 1
    assert jobs[0].link == "https://example.com/job"
    assert jobs[0].company_logo_url


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


def test_match_cites_every_available_profile_source() -> None:
    service = OpportunityService(
        connector=FakeSwelistConnector()  # type: ignore[arg-type]
    )

    result = service.search(
        role_type="newgrad",
        timeframe="all",
        target_market="europe",
        locations=["Berlin"],
        keywords=["backend"],
        work_modes=[],
        transcript={
            "courses": [
                {
                    "course": "Software Engineering",
                    "grade": "A",
                },
                {
                    "course": "Database Systems",
                    "grade": "B+",
                },
            ]
        },
        linkedin_profile={"skills": ["Python"]},
        github_profile={
            "skills": [
                {
                    "skill": "Docker",
                    "evidence_repos": ["careerloop-api"],
                }
            ],
            "repositories": [
                {
                    "name": "careerloop-api",
                    "description": "Dockerized API",
                    "detected_skills": ["Docker"],
                }
            ],
        },
        resume_profile={
            "skills": ["Git", "Software testing"],
            "experience": ["Built and tested backend services"],
        },
    )

    job = result["jobs"][0]
    sources = {
        item["source"] for item in job["profile_evidence_citations"]
    }
    assert sources == {
        "academic_transcript",
        "linkedin_pdf",
        "github",
        "resume",
    }
    assert {"python", "docker", "git", "databases"}.issubset(
        job["profile_skill_matches"]
    )
    assert all(item["evidence"] for item in job["profile_evidence_citations"])
    assert {
        item["source"] for item in result["profile_evidence_sources"]
        if item["available"]
    } == sources
    OpportunitySearchResponse.model_validate(result)


class JavaBackendConnector:
    def get_postings(self, **_kwargs):
        return [
            JobPosting(
                company="Example Bank",
                title="Graduate Java Backend Engineer",
                location="Frankfurt, Germany",
                link="https://example.com/java-backend",
                category="Software",
            )
        ]


def test_role_requirements_are_inferred_without_listing_skills() -> None:
    service = OpportunityService(
        connector=JavaBackendConnector()  # type: ignore[arg-type]
    )

    result = service.search(
        role_type="newgrad",
        timeframe="all",
        target_market="global",
        locations=[],
        keywords=[],
        work_modes=[],
        transcript=None,
        linkedin_profile=None,
        github_profile=None,
        resume_profile=None,
    )

    job = result["jobs"][0]
    assert {"java", "spring", "databases", "rest api"}.issubset(
        job["required_skills"]
    )
    assert "python" not in job["required_skills"]
    assert job["profile_skill_matches"] == []
    assert job["profile_evidence_citations"] == []
    assert job["assessment_confidence"] == "low"
    assert "No connected profile source" in job["assessment_summary"]
    assert "No direct profile-skill" in job["match_reasons"][0]
    assert job["match_score"] <= 20


class SoftwareConnector:
    def get_postings(self, **_kwargs):
        return [
            JobPosting(
                company="Example Product",
                title="Graduate Software Engineer",
                location="Remote",
                link="https://example.com/software",
            )
        ]


def test_each_job_maps_its_gaps_to_curated_courses() -> None:
    service = OpportunityService(
        connector=SoftwareConnector()  # type: ignore[arg-type]
    )

    result = service.search(
        role_type="newgrad",
        timeframe="all",
        target_market="global",
        locations=[],
        keywords=[],
        work_modes=["remote"],
        transcript=None,
        linkedin_profile=None,
        github_profile=None,
        resume_profile=None,
    )

    job = result["jobs"][0]
    courses = {
        course["id"]: course for course in result["recommended_courses"]
    }
    assert "boulder-algorithms" in job["recommended_course_ids"]
    assert set(job["recommended_course_ids"]).issubset(courses)
    assert {"algorithms", "data structures"}.issubset(
        courses["boulder-algorithms"]["addresses_skills"]
    )
    assert courses["boulder-algorithms"]["recommendation_reason"]
