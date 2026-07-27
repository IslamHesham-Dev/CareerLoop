from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from swelist_connector import SwelistConnector


CATALOG_PATH = (
    Path(__file__).resolve().parents[1]
    / "content"
    / "career"
    / "course_catalog.json"
)

MARKET_LOCATIONS = {
    "europe": (
        "Europe, Germany, Berlin, Munich, Netherlands, Amsterdam, France, "
        "Paris, Belgium, Brussels, Spain, Madrid, Italy, Ireland, Dublin, "
        "Sweden, Stockholm, Denmark, Copenhagen, Finland, Helsinki, Austria, "
        "Vienna, Switzerland, Poland, Warsaw, Portugal, Lisbon, United Kingdom, "
        "London"
    ),
    "local": "Egypt, Cairo, Giza",
    "remote": "Remote",
    "global": "",
}

ROLE_SKILLS: dict[str, set[str]] = {
    "ai": {
        "python",
        "machine learning",
        "llm",
        "rag",
        "pytorch",
        "sql",
    },
    "machine-learning": {
        "python",
        "machine learning",
        "statistics",
        "sql",
        "pytorch",
    },
    "data": {
        "python",
        "sql",
        "statistics",
        "data visualization",
        "etl",
    },
    "security": {
        "cybersecurity",
        "network security",
        "linux",
        "python",
        "siem",
    },
    "devops": {
        "docker",
        "kubernetes",
        "ci/cd",
        "linux",
        "cloud",
        "terraform",
    },
    "cloud": {
        "cloud",
        "aws",
        "azure",
        "linux",
        "docker",
        "networking",
    },
    "mobile": {
        "mobile",
        "flutter",
        "swift",
        "git",
        "rest api",
    },
    "frontend": {
        "javascript",
        "typescript",
        "web",
        "git",
        "rest api",
    },
    "backend": {
        "python",
        "databases",
        "rest api",
        "git",
        "linux",
        "docker",
    },
    "fullstack": {
        "javascript",
        "python",
        "databases",
        "rest api",
        "git",
        "web",
    },
    "software": {
        "programming",
        "algorithms",
        "data structures",
        "git",
        "software testing",
    },
    "networking": {
        "networking",
        "tcp/ip",
        "linux",
        "python",
        "cybersecurity",
    },
    "it-support": {
        "troubleshooting",
        "networking",
        "linux",
        "cloud",
        "cybersecurity",
    },
    "business": {
        "sql",
        "data visualization",
        "spreadsheets",
        "project management",
        "communication",
    },
    "general": {"communication", "problem solving", "git"},
}

ROLE_PATTERNS: list[tuple[str, tuple[str, ...]]] = [
    ("ai", ("artificial intelligence", "generative ai", "llm", "nlp")),
    (
        "machine-learning",
        ("machine learning", "ml engineer", "data scientist"),
    ),
    (
        "data",
        (
            "data engineer",
            "data analyst",
            "analytics",
            "business intelligence",
            "bi engineer",
        ),
    ),
    (
        "security",
        ("security", "cyber", "penetration", "soc analyst", "threat"),
    ),
    (
        "devops",
        ("devops", "site reliability", "sre", "platform engineer"),
    ),
    ("cloud", ("cloud", "solutions architect")),
    (
        "mobile",
        ("mobile", "flutter", "ios", "android", "swift"),
    ),
    ("frontend", ("front end", "frontend", "react", "web developer")),
    (
        "fullstack",
        ("full stack", "fullstack"),
    ),
    (
        "backend",
        ("back end", "backend", "api engineer"),
    ),
    (
        "networking",
        ("network engineer", "network operations"),
    ),
    (
        "it-support",
        ("technical support", "it support", "helpdesk", "systems administrator"),
    ),
    (
        "business",
        ("business analyst", "product manager", "project manager"),
    ),
    (
        "software",
        ("software", "developer", "engineer", "programmer"),
    ),
]

SKILL_ALIASES: dict[str, tuple[str, ...]] = {
    "python": ("python",),
    "java": ("java",),
    "c#": ("c#", "c sharp", ".net"),
    "javascript": ("javascript", "react", "node.js", "nodejs"),
    "typescript": ("typescript",),
    "flutter": ("flutter", "dart"),
    "swift": ("swift", "swiftui", "ios"),
    "sql": ("sql", "mysql", "postgres", "database"),
    "databases": ("database", "sql", "mysql", "postgres"),
    "git": ("git", "github", "version control"),
    "linux": ("linux", "unix"),
    "docker": ("docker", "container"),
    "kubernetes": ("kubernetes", "k8s"),
    "cloud": ("cloud", "aws", "azure", "gcp"),
    "aws": ("aws", "amazon web services"),
    "azure": ("azure",),
    "machine learning": ("machine learning", "data science"),
    "pytorch": ("pytorch", "tensorflow", "keras"),
    "llm": ("llm", "large language model", "generative ai"),
    "rag": ("rag", "retrieval augmented generation", "langchain"),
    "cybersecurity": ("cybersecurity", "security", "ethical hacking"),
    "network security": ("network security", "it security"),
    "networking": ("networking", "computer networks"),
    "statistics": ("statistics", "probability"),
    "data visualization": ("visualization", "tableau", "power bi"),
    "etl": ("etl", "data engineering"),
    "algorithms": ("algorithm",),
    "data structures": ("data structure",),
    "software testing": ("testing", "quality assurance", "qa"),
    "rest api": ("rest", "api", "fastapi", "flask", "django"),
    "web": ("web", "html", "css", "frontend"),
    "mobile": ("mobile", "android", "ios", "flutter"),
    "project management": ("project management", "agile", "scrum"),
}


class CourseCatalog:
    def __init__(self, path: Path = CATALOG_PATH) -> None:
        payload = json.loads(path.read_text(encoding="utf-8"))
        self.source = str(payload["source"])
        self.platform = str(payload["platform"])
        self.courses = list(payload["courses"])

    def recommend(
        self,
        gaps: list[str],
        role_families: list[str],
        *,
        limit: int = 6,
    ) -> list[dict[str, Any]]:
        gap_set = set(gaps)
        role_set = set(role_families)
        ranked: list[tuple[int, dict[str, Any], list[str]]] = []
        for course in self.courses:
            matched = sorted(gap_set.intersection(course["skills"]))
            role_overlap = role_set.intersection(course["roles"])
            score = len(matched) * 4 + len(role_overlap)
            if score:
                ranked.append((score, course, matched))
        ranked.sort(key=lambda item: (-item[0], item[1]["title"]))
        return [
            {
                **course,
                "addresses_skills": matched,
                "catalog_source": self.source,
            }
            for _score, course, matched in ranked[:limit]
        ]


class OpportunityService:
    def __init__(
        self,
        connector: SwelistConnector | None = None,
        catalog: CourseCatalog | None = None,
    ) -> None:
        self.connector = connector or SwelistConnector(timeout=60)
        self.catalog = catalog or CourseCatalog()

    def search(
        self,
        *,
        role_type: str,
        timeframe: str,
        target_market: str,
        locations: list[str],
        keywords: list[str],
        work_modes: list[str],
        transcript: dict[str, Any] | None,
        linkedin_profile: dict[str, Any] | None,
        limit: int = 24,
    ) -> dict[str, Any]:
        resolved_location = self._location_filter(
            target_market,
            locations,
            work_modes,
        )
        postings = self.connector.get_postings(
            role=role_type,  # type: ignore[arg-type]
            timeframe=timeframe,  # type: ignore[arg-type]
            location=resolved_location or None,
        )
        evidence_text, academic_ready, linkedin_ready = self._evidence_text(
            transcript,
            linkedin_profile,
        )
        known_skills = self._skills_in(evidence_text)
        normalized_keywords = [
            value.strip().casefold()
            for value in keywords
            if value.strip()
        ]

        matches = [
            self._match_job(
                posting,
                known_skills=known_skills,
                keywords=normalized_keywords,
                locations=locations,
                target_market=target_market,
                work_modes=work_modes,
            )
            for posting in postings
        ]
        if normalized_keywords:
            keyword_matches = [
                match for match in matches if match["keyword_matches"]
            ]
            if keyword_matches:
                matches = keyword_matches
        matches.sort(
            key=lambda job: (
                -job["match_score"],
                job["company"].casefold(),
                job["title"].casefold(),
            )
        )
        matches = matches[:limit]

        gap_counter: Counter[str] = Counter()
        role_families: list[str] = []
        for match in matches[:10]:
            role_families.append(match["role_family"])
            gap_counter.update(match["inferred_skill_gaps"])
        prioritized_gaps = [
            skill for skill, _count in gap_counter.most_common(10)
        ]
        courses = self.catalog.recommend(
            prioritized_gaps,
            role_families,
        )
        courses_by_skill: dict[str, list[str]] = {}
        for course in courses:
            for skill in course["addresses_skills"]:
                courses_by_skill.setdefault(skill, []).append(course["id"])
        for match in matches:
            match["recommended_course_ids"] = list(
                dict.fromkeys(
                    course_id
                    for gap in match["inferred_skill_gaps"]
                    for course_id in courses_by_skill.get(gap, [])
                )
            )[:2]

        message = None
        if not matches:
            message = (
                "Swelist returned no matching openings for these filters. "
                "Try a broader location, a longer timeframe, or fewer keywords."
            )
        return {
            "source": "Swelist",
            "source_detail": (
                "Live internship and new-grad listings aggregated from "
                "public technology-job repositories."
            ),
            "searched_at": datetime.now(UTC).isoformat(),
            "preferences": {
                "role_type": role_type,
                "timeframe": timeframe,
                "target_market": target_market,
                "locations": locations,
                "keywords": keywords,
                "work_modes": work_modes,
            },
            "evidence": {
                "academic_transcript": academic_ready,
                "linkedin_pdf": linkedin_ready,
                "github": False,
                "resume": False,
            },
            "jobs": matches,
            "recommended_courses": courses,
            "message": message,
            "limitations": [
                (
                    "Swelist supplies listing metadata, not the complete job "
                    "description. Skill gaps are role-family inferences and "
                    "must be confirmed on the employer application page."
                ),
                (
                    "GitHub and resume evidence are not connected yet and "
                    "were not used in the ranking."
                ),
                (
                    "Swelist has no dedicated remote/hybrid/on-site field; "
                    "work-mode matching uses words present in listing locations."
                ),
            ],
        }

    @staticmethod
    def _location_filter(
        target_market: str,
        locations: list[str],
        work_modes: list[str],
    ) -> str:
        values = [value.strip() for value in locations if value.strip()]
        if values:
            if "remote" in work_modes and not any(
                value.casefold() == "remote" for value in values
            ):
                values.append("Remote")
            return ", ".join(values)
        return MARKET_LOCATIONS.get(target_market, "")

    @staticmethod
    def _evidence_text(
        transcript: dict[str, Any] | None,
        linkedin_profile: dict[str, Any] | None,
    ) -> tuple[str, bool, bool]:
        pieces: list[str] = []
        academic_ready = bool(transcript and transcript.get("courses"))
        linkedin_ready = bool(linkedin_profile)
        if transcript:
            pieces.extend(
                str(course.get("course", ""))
                for course in transcript.get("courses", [])
            )
        if linkedin_profile:
            for field in (
                "headline",
                "summary",
                "skills",
                "experience",
                "education",
                "certifications",
            ):
                value = linkedin_profile.get(field)
                if isinstance(value, list):
                    pieces.extend(str(item) for item in value)
                elif value:
                    pieces.append(str(value))
        return " ".join(pieces).casefold(), academic_ready, linkedin_ready

    @staticmethod
    def _skills_in(text: str) -> set[str]:
        return {
            skill
            for skill, aliases in SKILL_ALIASES.items()
            if any(alias in text for alias in aliases)
        }

    @staticmethod
    def _role_family(title: str) -> str:
        normalized = title.casefold()
        for family, patterns in ROLE_PATTERNS:
            if any(pattern in normalized for pattern in patterns):
                return family
        return "general"

    def _match_job(
        self,
        posting,
        *,
        known_skills: set[str],
        keywords: list[str],
        locations: list[str],
        target_market: str,
        work_modes: list[str],
    ) -> dict[str, Any]:
        family = self._role_family(posting.title)
        expected_skills = ROLE_SKILLS[family]
        job_text = (
            f"{posting.title} {posting.company} {posting.location}"
        ).casefold()
        keyword_matches = sorted(
            keyword
            for keyword in keywords
            if keyword in job_text or keyword in expected_skills
        )
        skill_matches = sorted(expected_skills.intersection(known_skills))
        gaps = sorted(expected_skills - known_skills)[:6]
        location_matches = sorted(
            location
            for location in locations
            if location.casefold() in posting.location.casefold()
        )

        score = 30
        score += min(25, len(keyword_matches) * 12)
        score += min(25, len(skill_matches) * 5)
        if location_matches:
            score += 15
        elif target_market == "global":
            score += 8
        if "remote" in work_modes and "remote" in posting.location.casefold():
            score += 5
        score = min(score, 100)

        reasons = []
        if keyword_matches:
            reasons.append(
                f"Matches preference: {', '.join(keyword_matches[:3])}"
            )
        if skill_matches:
            reasons.append(
                f"Profile evidence: {', '.join(skill_matches[:3])}"
            )
        if location_matches:
            reasons.append(
                f"Location match: {', '.join(location_matches[:2])}"
            )
        if not reasons:
            reasons.append(
                f"Recent {family.replace('-', ' ')} opening in the selected feed"
            )

        digest = hashlib.sha256(posting.link.encode("utf-8")).hexdigest()[:20]
        return {
            "id": f"swelist_{digest}",
            "company": posting.company,
            "title": posting.title,
            "location": posting.location or "Location not specified",
            "url": posting.link,
            "source": "Swelist",
            "role_family": family,
            "match_score": score,
            "match_reasons": reasons,
            "keyword_matches": keyword_matches,
            "profile_skill_matches": skill_matches,
            "inferred_skill_gaps": gaps,
            "recommended_course_ids": [],
        }
