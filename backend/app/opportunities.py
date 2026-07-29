from __future__ import annotations

import hashlib
import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from app.opportunity_taxonomy import (
    EXTRA_ROLE_PATTERNS,
    EXTRA_ROLE_SKILLS,
    EXTRA_SKILL_ALIASES,
    ROLE_COURSE_AFFINITY,
    SKILL_IMPLICATIONS,
    TITLE_SKILL_HINTS,
)
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

for _family, _skills in EXTRA_ROLE_SKILLS.items():
    ROLE_SKILLS.setdefault(_family, set()).update(_skills)
ROLE_PATTERNS = [*EXTRA_ROLE_PATTERNS, *ROLE_PATTERNS]
for _skill, _aliases in EXTRA_SKILL_ALIASES.items():
    SKILL_ALIASES[_skill] = tuple(
        dict.fromkeys((*SKILL_ALIASES.get(_skill, ()), *_aliases))
    )


def _normalized_text(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip().casefold()


def _contains_alias(text: str, alias: str) -> bool:
    normalized_alias = _normalized_text(alias)
    if not normalized_alias:
        return False
    return (
        re.search(
            rf"(?<![\w+#.]){re.escape(normalized_alias)}(?![\w+#.])",
            text,
        )
        is not None
    )


def _canonical_skill(value: Any) -> str:
    normalized = _normalized_text(value)
    for skill, aliases in SKILL_ALIASES.items():
        if normalized == skill or normalized in aliases:
            return skill
    return normalized


def _skills_in_text(text: Any) -> set[str]:
    normalized = _normalized_text(text)
    return {
        skill
        for skill, aliases in SKILL_ALIASES.items()
        if _contains_alias(normalized, skill)
        or any(_contains_alias(normalized, alias) for alias in aliases)
    }


def _expand_skills(skills: set[str]) -> set[str]:
    expanded = set(skills)
    pending = list(skills)
    while pending:
        skill = pending.pop()
        for implied in SKILL_IMPLICATIONS.get(skill, set()):
            if implied in expanded:
                continue
            expanded.add(implied)
            pending.append(implied)
    return expanded


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
        target_skills: list[str] | set[str] | None = None,
        limit: int = 6,
    ) -> list[dict[str, Any]]:
        gap_set = {_canonical_skill(skill) for skill in gaps}
        target_set = {
            _canonical_skill(skill) for skill in (target_skills or [])
        }
        role_set = set(role_families)
        affinity_ids = {
            course_id
            for role in role_set
            for course_id in ROLE_COURSE_AFFINITY.get(role, ())
        }
        ranked: list[tuple[int, dict[str, Any], list[str]]] = []
        for course in self.courses:
            course_skills = {
                _canonical_skill(skill) for skill in course["skills"]
            }
            course_skills.update(
                _skills_in_text(
                    f"{course['title']} {' '.join(course['skills'])}"
                )
            )
            course_skills = _expand_skills(course_skills)
            matched_gaps = sorted(gap_set.intersection(course_skills))
            matched_targets = sorted(target_set.intersection(course_skills))
            role_overlap = role_set.intersection(course["roles"])
            affinity = course["id"] in affinity_ids
            score = (
                len(matched_gaps) * 10
                + len(matched_targets) * 4
                + len(role_overlap) * 6
                + (24 if affinity else 0)
            )
            if score:
                addressed = list(
                    dict.fromkeys([*matched_gaps, *matched_targets])
                )[:6]
                ranked.append((score, course, addressed))
        ranked.sort(key=lambda item: (-item[0], item[1]["title"]))

        # Unknown titles should still receive broadly useful learning options.
        # These are relevance fallbacks, not claims about employer requirements.
        if not ranked:
            fallback_ids = ROLE_COURSE_AFFINITY["general"]
            by_id = {course["id"]: course for course in self.courses}
            ranked = [
                (1, by_id[course_id], [])
                for course_id in fallback_ids
                if course_id in by_id
            ]

        return [
            {
                **course,
                "addresses_skills": addressed,
                "catalog_source": self.source,
            }
            for _score, course, addressed in ranked[:limit]
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
        github_profile: dict[str, Any] | None = None,
        resume_profile: dict[str, Any] | None = None,
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
        (
            evidence_text,
            academic_ready,
            linkedin_ready,
            github_ready,
            resume_ready,
        ) = self._evidence_text(
            transcript,
            linkedin_profile,
            github_profile,
            resume_profile,
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
                transcript=transcript,
                linkedin_profile=linkedin_profile,
                github_profile=github_profile,
                resume_profile=resume_profile,
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

        # Recommend for each opening independently. Missing skills improve a
        # course's rank, but role relevance alone is sufficient, so qualified
        # candidates still receive useful adjacent/upskilling suggestions.
        courses_by_id: dict[str, dict[str, Any]] = {}
        for match in matches:
            job_courses = self.catalog.recommend(
                match["inferred_skill_gaps"],
                match.pop("_role_families"),
                target_skills=match.pop("_expected_skills"),
                limit=3,
            )
            match["recommended_course_ids"] = [
                course["id"] for course in job_courses
            ]
            for course in job_courses:
                courses_by_id.setdefault(course["id"], course)
        courses = list(courses_by_id.values())

        message = None
        if not matches:
            message = (
                "No openings matched these filters. Try a broader location "
                "or fewer role and technology preferences."
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
                "github": github_ready,
                "resume": resume_ready,
            },
            "jobs": matches,
            "recommended_courses": courses,
            "message": message,
            "limitations": [
                (
                    "The live feed supplies listing metadata, not the complete job "
                    "description. Skill gaps are role-family inferences and "
                    "must be confirmed on the employer application page."
                ),
                *(
                    []
                    if resume_ready
                    else [
                        (
                            "Resume evidence is not connected yet and was "
                            "not used in the ranking."
                        )
                    ]
                ),
                *(
                    []
                    if github_ready
                    else [
                        (
                            "GitHub project evidence is not connected yet "
                            "and was not used in the ranking."
                        )
                    ]
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
            return ", ".join(values)
        return MARKET_LOCATIONS.get(target_market, "")

    @staticmethod
    def _evidence_text(
        transcript: dict[str, Any] | None,
        linkedin_profile: dict[str, Any] | None,
        github_profile: dict[str, Any] | None,
        resume_profile: dict[str, Any] | None = None,
    ) -> tuple[str, bool, bool, bool, bool]:
        pieces: list[str] = []
        academic_ready = bool(transcript and transcript.get("courses"))
        linkedin_ready = bool(linkedin_profile)
        github_ready = bool(
            github_profile and github_profile.get("repositories")
        )
        resume_ready = bool(resume_profile and resume_profile.get("raw_text"))
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
        if github_profile:
            for skill in github_profile.get("skills", []):
                if isinstance(skill, dict):
                    pieces.append(str(skill.get("skill", "")))
            for repository in github_profile.get("repositories", []):
                if not isinstance(repository, dict):
                    continue
                pieces.extend(
                    str(repository.get(field, ""))
                    for field in (
                        "name",
                        "description",
                        "primary_language",
                        "topics",
                        "languages",
                        "detected_skills",
                    )
                )
        if resume_profile:
            for field in (
                "headline",
                "summary",
                "skills",
                "experience",
                "education",
                "certifications",
            ):
                value = resume_profile.get(field)
                if isinstance(value, list):
                    pieces.extend(str(item) for item in value)
                elif value:
                    pieces.append(str(value))
        return (
            " ".join(pieces).casefold(),
            academic_ready,
            linkedin_ready,
            github_ready,
            resume_ready,
        )

    @staticmethod
    def _skills_in(text: str) -> set[str]:
        return _expand_skills(_skills_in_text(text))

    @classmethod
    def _role_families(
        cls,
        title: str,
        category: str | None = None,
    ) -> list[str]:
        normalized = _normalized_text(f"{title} {category or ''}")
        families: list[str] = []
        for family, patterns in ROLE_PATTERNS:
            if any(_contains_alias(normalized, pattern) for pattern in patterns):
                families.append(family)
        if not families:
            return ["general"]
        return list(dict.fromkeys(families))

    @classmethod
    def _role_family(
        cls,
        title: str,
        category: str | None = None,
    ) -> str:
        return cls._role_families(title, category)[0]

    @staticmethod
    def _expected_skills(
        title: str,
        category: str | None,
        role_families: list[str],
    ) -> set[str]:
        normalized = _normalized_text(f"{title} {category or ''}")
        expected = {
            skill
            for family in role_families
            for skill in ROLE_SKILLS.get(family, ROLE_SKILLS["general"])
        }
        expected.update(_skills_in_text(normalized))
        for patterns, skills in TITLE_SKILL_HINTS:
            if any(_contains_alias(normalized, pattern) for pattern in patterns):
                expected.update(skills)
        return _expand_skills(expected)

    @staticmethod
    def _evidence_citations(
        *,
        matched_skills: set[str],
        transcript: dict[str, Any] | None,
        linkedin_profile: dict[str, Any] | None,
        github_profile: dict[str, Any] | None,
        resume_profile: dict[str, Any] | None,
        limit: int = 6,
    ) -> list[dict[str, str | None]]:
        """Return only claims that can point back to a concrete profile record."""

        candidates: dict[str, list[dict[str, str | None]]] = {
            "academic": [],
            "github": [],
            "linkedin": [],
            "resume": [],
        }

        def supported_skills(value: Any) -> list[str]:
            present = _expand_skills(_skills_in_text(value))
            return sorted(matched_skills.intersection(present))

        def add(
            source: str,
            source_label: str,
            title: Any,
            detail: Any,
            value: Any,
            *,
            url: Any = None,
        ) -> None:
            clean_title = " ".join(str(title or "").split()).strip()
            clean_detail = " ".join(str(detail or "").split()).strip()
            if not clean_title:
                return
            for skill in supported_skills(value):
                candidates[source].append(
                    {
                        "source": source,
                        "source_label": source_label,
                        "title": clean_title[:180],
                        "detail": clean_detail[:320],
                        "skill": skill,
                        "url": str(url).strip() or None,
                    }
                )

        for course in (transcript or {}).get("courses", []):
            if not isinstance(course, dict):
                continue
            course_name = course.get("course", "")
            grade = course.get("grade")
            numeric = course.get("numeric")
            period = course.get("semester") or course.get("academic_year")
            grade_bits = [
                value
                for value in (
                    f"Grade {grade}" if grade else None,
                    f"numeric {numeric}" if numeric else None,
                    str(period) if period else None,
                )
                if value
            ]
            add(
                "academic",
                "Academic transcript",
                course_name,
                " · ".join(grade_bits) or "Completed course on the transcript",
                course_name,
            )

        for repository in (github_profile or {}).get("repositories", []):
            if not isinstance(repository, dict):
                continue
            evidence_value = " ".join(
                str(repository.get(field, ""))
                for field in (
                    "name",
                    "description",
                    "primary_language",
                    "topics",
                    "languages",
                    "detected_skills",
                )
            )
            detail_bits = [
                str(value).strip()
                for value in (
                    repository.get("description"),
                    (
                        f"Primary language: {repository.get('primary_language')}"
                        if repository.get("primary_language")
                        else None
                    ),
                )
                if value
            ]
            add(
                "github",
                "GitHub",
                repository.get("name", "Repository"),
                " · ".join(detail_bits) or "Verified public repository",
                evidence_value,
                url=repository.get("html_url"),
            )

        def add_profile_entries(
            profile: dict[str, Any] | None,
            *,
            source: str,
            source_label: str,
        ) -> None:
            labels = {
                "certifications": "Certification",
                "experience": "Experience",
                "education": "Education",
                "skills": "Skill",
                "headline": "Profile headline",
                "summary": "Profile summary",
            }
            for field in (
                "certifications",
                "experience",
                "education",
                "skills",
                "headline",
                "summary",
            ):
                raw = (profile or {}).get(field)
                values = raw if isinstance(raw, list) else [raw]
                for value in values:
                    if not value:
                        continue
                    if isinstance(value, dict):
                        title = (
                            value.get("name")
                            or value.get("title")
                            or value.get("role")
                            or value.get("company")
                            or labels[field]
                        )
                        evidence_value = json.dumps(value, ensure_ascii=False)
                    else:
                        evidence_value = str(value)
                        title = evidence_value
                    add(
                        source,
                        source_label,
                        title,
                        f"{labels[field]} in the imported {source_label}",
                        evidence_value,
                    )

        add_profile_entries(
            linkedin_profile,
            source="linkedin",
            source_label="LinkedIn PDF",
        )
        add_profile_entries(
            resume_profile,
            source="resume",
            source_label="Resume",
        )

        selected: list[dict[str, str | None]] = []
        seen: set[tuple[str | None, str | None, str | None]] = set()
        covered_skills: set[str | None] = set()

        def take(candidate: dict[str, str | None]) -> None:
            key = (
                candidate.get("source"),
                candidate.get("title"),
                candidate.get("skill"),
            )
            if key in seen or len(selected) >= limit:
                return
            seen.add(key)
            covered_skills.add(candidate.get("skill"))
            selected.append(candidate)

        # Start with source diversity, then fill remaining slots with distinct
        # skills. This prevents a long transcript from hiding GitHub/LinkedIn.
        for source in ("academic", "github", "linkedin", "resume"):
            if candidates[source]:
                take(candidates[source][0])
        for source in ("academic", "github", "linkedin", "resume"):
            for candidate in candidates[source]:
                if candidate.get("skill") not in covered_skills:
                    take(candidate)
                if len(selected) >= limit:
                    return selected
        return selected

    def _match_job(
        self,
        posting,
        *,
        known_skills: set[str],
        keywords: list[str],
        locations: list[str],
        target_market: str,
        work_modes: list[str],
        transcript: dict[str, Any] | None,
        linkedin_profile: dict[str, Any] | None,
        github_profile: dict[str, Any] | None,
        resume_profile: dict[str, Any] | None,
    ) -> dict[str, Any]:
        role_families = self._role_families(
            posting.title,
            posting.category,
        )
        family = role_families[0]
        expected_skills = self._expected_skills(
            posting.title,
            posting.category,
            role_families,
        )
        job_text = (
            f"{posting.title} {posting.category or ''} "
            f"{posting.company} {posting.location}"
        ).casefold()
        keyword_matches = sorted(
            keyword
            for keyword in keywords
            if keyword in job_text or keyword in expected_skills
        )
        skill_matches = sorted(expected_skills.intersection(known_skills))
        gaps = sorted(expected_skills - known_skills)[:8]
        evidence_citations = self._evidence_citations(
            matched_skills=set(skill_matches),
            transcript=transcript,
            linkedin_profile=linkedin_profile,
            github_profile=github_profile,
            resume_profile=resume_profile,
        )
        location_matches = sorted(
            location
            for location in locations
            if location.casefold() in posting.location.casefold()
        )

        coverage = len(skill_matches) / max(1, len(expected_skills))
        score = round(coverage * 55)
        score += min(15, len(keyword_matches) * 7)
        score += min(15, len(evidence_citations) * 4)
        if location_matches:
            score += 10
        elif target_market == "global":
            score += 4
        if "remote" in work_modes and "remote" in posting.location.casefold():
            score += 5
        score -= min(20, len(gaps) * 2)
        score = max(5, min(score, 92))

        reasons = []
        if keyword_matches:
            reasons.append(
                f"Matches preference: {', '.join(keyword_matches[:3])}"
            )
        if skill_matches:
            reasons.append(
                f"Verified skills: {', '.join(skill_matches[:3])}"
            )
        if evidence_citations:
            reasons.append(
                f"{len(evidence_citations)} source-level profile citations"
            )
        if gaps:
            reasons.append(
                f"No verified evidence for: {', '.join(gaps[:3])}"
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
            "locations": list(posting.locations),
            "url": posting.link,
            "source": "Swelist",
            "category": posting.category,
            "posted_at": posting.posted_at,
            "updated_at": posting.updated_at,
            "sponsorship": posting.sponsorship,
            "degrees": list(posting.degrees),
            "company_profile_url": posting.company_profile_url,
            "company_logo_url": posting.company_logo_url,
            "active": posting.active,
            "role_family": family,
            "match_score": score,
            "match_reasons": reasons,
            "keyword_matches": keyword_matches,
            "profile_skill_matches": skill_matches,
            "inferred_skill_gaps": gaps,
            "recommended_course_ids": [],
            "evidence_citations": evidence_citations,
            "_role_families": role_families,
            "_expected_skills": sorted(expected_skills),
        }
