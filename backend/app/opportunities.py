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

EVIDENCE_SOURCE_NAMES = {
    "academic_transcript": "academic transcript",
    "linkedin_pdf": "LinkedIn PDF",
    "github": "GitHub projects",
    "resume": "resume",
}

ROLE_SKILLS: dict[str, set[str]] = {
    "ai": {
        "python",
        "machine learning",
        "llm",
        "rag",
        "pytorch",
        "sql",
        "cloud",
    },
    "machine-learning": {
        "python",
        "machine learning",
        "statistics",
        "sql",
        "pytorch",
        "data visualization",
    },
    "data": {
        "python",
        "sql",
        "statistics",
        "data visualization",
        "etl",
        "databases",
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
        "linux",
        "docker",
        "networking",
        "terraform",
    },
    "mobile": {
        "mobile",
        "programming",
        "git",
        "rest api",
        "software testing",
    },
    "frontend": {
        "javascript",
        "typescript",
        "web",
        "git",
        "rest api",
        "software testing",
    },
    "backend": {
        "programming",
        "databases",
        "rest api",
        "git",
        "linux",
        "docker",
        "software testing",
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
        "problem solving",
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
    "python": ("python", "django", "flask", "fastapi"),
    "java": ("java", "spring boot", "spring framework"),
    "spring": ("spring boot", "spring framework"),
    "c#": ("c#", "c sharp", ".net"),
    "c++": ("c++", "cpp"),
    "go": ("golang",),
    "rust": ("rust",),
    "kotlin": ("kotlin",),
    "php": ("php", "laravel"),
    "ruby": ("ruby", "ruby on rails", "rails"),
    "scala": ("scala",),
    "javascript": ("javascript", "node.js", "nodejs"),
    "typescript": ("typescript",),
    "react": ("react", "next.js", "nextjs"),
    "vue": ("vue", "vue.js", "vuejs"),
    "angular": ("angular",),
    "node.js": ("node.js", "nodejs", "express.js", "express"),
    ".net": (".net", "dotnet", "asp.net", "blazor"),
    "flutter": ("flutter", "dart"),
    "swift": ("swift", "swiftui", "ios"),
    "sql": ("sql", "mysql", "postgres", "database"),
    "databases": ("database", "sql", "mysql", "postgres"),
    "git": ("git", "github", "version control"),
    "linux": ("linux", "unix"),
    "docker": ("docker", "container"),
    "kubernetes": ("kubernetes", "k8s"),
    "ci/cd": (
        "ci/cd",
        "continuous integration",
        "continuous delivery",
        "github actions",
        "gitlab ci",
    ),
    "terraform": ("terraform", "infrastructure as code"),
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
    "software testing": (
        "testing",
        "quality assurance",
        "unit test",
        "integration test",
    ),
    "rest api": ("rest", "api", "fastapi", "flask", "django"),
    "web": ("web", "html", "css", "frontend"),
    "mobile": ("mobile", "android", "ios", "flutter"),
    "project management": ("project management", "agile", "scrum"),
    "programming": (
        "programming",
        "software development",
        "software engineering",
        "developer",
    ),
    "problem solving": ("problem solving", "competitive programming"),
    "communication": ("communication", "presentation", "stakeholder"),
    "spreadsheets": ("spreadsheet", "excel", "google sheets"),
    "siem": ("siem", "splunk", "security information and event management"),
    "tcp/ip": ("tcp/ip", "tcp", "ip networking"),
    "troubleshooting": ("troubleshooting", "technical support", "helpdesk"),
    "microservices": ("microservices", "distributed systems"),
    "graphql": ("graphql",),
}

TITLE_SKILL_HINTS: list[tuple[tuple[str, ...], set[str]]] = [
    (("java",), {"java", "spring", "databases", "rest api"}),
    (("python",), {"python", "databases", "rest api"}),
    ((".net", "c#"), {"c#", ".net", "databases", "rest api"}),
    (("golang", " go developer", " go engineer"), {"go", "rest api"}),
    (("rust",), {"rust", "programming"}),
    (("react", "next.js", "nextjs"), {"react", "javascript", "typescript"}),
    (("angular",), {"angular", "typescript", "javascript"}),
    (("vue", "vue.js", "vuejs"), {"vue", "javascript", "typescript"}),
    (("node.js", "nodejs"), {"node.js", "javascript", "rest api"}),
    (("flutter",), {"flutter", "mobile", "rest api"}),
    (("ios", "swift"), {"swift", "mobile", "rest api"}),
    (("android",), {"mobile", "programming", "rest api"}),
    (("kotlin",), {"kotlin", "mobile"}),
    (("php", "laravel"), {"php", "databases", "rest api"}),
    (("ruby", "rails"), {"ruby", "databases", "rest api"}),
    (("scala",), {"scala", "programming"}),
    (("data engineer",), {"python", "sql", "etl", "databases", "cloud"}),
    (("data analyst",), {"sql", "statistics", "data visualization"}),
    (("machine learning", "data scientist"), {"python", "machine learning", "statistics"}),
    (
        ("devops", "platform engineer", "site reliability"),
        {"docker", "kubernetes", "ci/cd", "linux", "cloud"},
    ),
    (("cloud",), {"cloud", "linux", "networking"}),
    (("aws", "amazon web services"), {"aws", "cloud"}),
    (("azure",), {"azure", "cloud"}),
    (("gcp", "google cloud"), {"cloud"}),
    (("security", "cyber"), {"cybersecurity", "network security", "linux"}),
]

ACADEMIC_SKILL_HINTS: list[tuple[tuple[str, ...], set[str]]] = [
    (("data structure",), {"data structures", "algorithms", "problem solving"}),
    (("algorithm",), {"algorithms", "problem solving"}),
    (("database",), {"databases", "sql"}),
    (("software engineering",), {"programming", "software testing"}),
    (("software construction", "software testing"), {"programming", "software testing"}),
    (("operating system",), {"linux"}),
    (("computer network", "networking"), {"networking", "tcp/ip"}),
    (("mobile",), {"mobile"}),
    (
        ("machine learning", "artificial intelligence"),
        {"machine learning", "python", "statistics"},
    ),
    (("data engineering",), {"python", "sql", "etl", "data visualization"}),
    (("cloud",), {"cloud"}),
    (("security", "cryptography", "ethical hacking"), {"cybersecurity", "network security"}),
    (("programming",), {"programming"}),
    (("project management",), {"project management", "communication"}),
]

SKILL_IMPLICATIONS: dict[str, set[str]] = {
    "python": {"programming"},
    "java": {"programming"},
    "c#": {"programming"},
    "c++": {"programming"},
    "go": {"programming"},
    "rust": {"programming"},
    "kotlin": {"programming", "mobile"},
    "php": {"programming"},
    "ruby": {"programming"},
    "scala": {"programming"},
    "javascript": {"programming", "web"},
    "typescript": {"programming", "web"},
    "react": {"javascript", "web"},
    "vue": {"javascript", "web"},
    "angular": {"typescript", "web"},
    "node.js": {"javascript", "programming"},
    ".net": {"c#", "programming"},
    "spring": {"java", "rest api"},
    "flutter": {"programming", "mobile"},
    "swift": {"programming", "mobile"},
    "sql": {"databases"},
    "pytorch": {"machine learning", "python"},
    "rag": {"llm"},
    "algorithms": {"problem solving"},
}


def _normalized_text(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip().casefold()


def _contains_alias(text: str, alias: str) -> bool:
    """Match a skill as a phrase instead of as an accidental substring."""
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


def _skill_hints(
    text: Any,
    hints: list[tuple[tuple[str, ...], set[str]]],
) -> set[str]:
    normalized = _normalized_text(text)
    return {
        skill
        for patterns, skills in hints
        if any(pattern in normalized for pattern in patterns)
        for skill in skills
    }


def _excerpt(value: Any, *, limit: int = 180) -> str:
    normalized = re.sub(r"\s+", " ", str(value or "")).strip()
    if len(normalized) <= limit:
        return normalized
    return f"{normalized[: limit - 1].rstrip()}…"


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
        gap_set = {_canonical_skill(gap) for gap in gaps}
        role_set = set(role_families)
        ranked: list[tuple[int, dict[str, Any], list[str]]] = []
        for course in self.courses:
            course_skills: set[str] = set()
            for skill in course["skills"]:
                course_skills.add(_canonical_skill(skill))
                course_skills.update(_skills_in_text(skill))
            course_skills = _expand_skills(course_skills)
            matched = sorted(gap_set.intersection(course_skills))
            role_overlap = role_set.intersection(course["roles"])
            score = len(matched) * 6 + len(role_overlap) * 2
            if matched:
                ranked.append((score, course, matched))
        ranked.sort(key=lambda item: (-item[0], item[1]["title"]))
        return [
            {
                **course,
                "addresses_skills": matched,
                "catalog_source": self.source,
                "recommendation_reason": (
                    "Addresses "
                    f"{', '.join(matched)} for the selected role profile."
                ),
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
            evidence_index,
            evidence_sources,
            academic_ready,
            linkedin_ready,
            github_ready,
            resume_ready,
        ) = self._profile_evidence(
            transcript,
            linkedin_profile,
            github_profile,
            resume_profile,
        )
        known_skills = set(evidence_index)
        normalized_keywords = [
            value.strip().casefold()
            for value in keywords
            if value.strip()
        ]

        matches = [
            self._match_job(
                posting,
                known_skills=known_skills,
                evidence_index=evidence_index,
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
        courses_by_id: dict[str, dict[str, Any]] = {}
        for match in matches:
            targeted = self.catalog.recommend(
                match["inferred_skill_gaps"],
                [match["role_family"]],
                limit=2,
            )
            match["recommended_course_ids"] = [
                course["id"] for course in targeted
            ]
            for course in targeted:
                courses_by_id.setdefault(course["id"], course)
        for course in self.catalog.recommend(
            prioritized_gaps,
            role_families,
            limit=8,
        ):
            courses_by_id.setdefault(course["id"], course)
        courses = list(courses_by_id.values())
        visible_course_ids = {course["id"] for course in courses}
        for match in matches:
            match["recommended_course_ids"] = [
                course_id
                for course_id in match["recommended_course_ids"]
                if course_id in visible_course_ids
            ][:2]

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
            "profile_evidence_sources": evidence_sources,
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
                    if academic_ready
                    else [
                        (
                            "The full academic transcript was unavailable and "
                            "was not used in the ranking."
                        )
                    ]
                ),
                *(
                    []
                    if linkedin_ready
                    else [
                        (
                            "LinkedIn PDF evidence is not connected yet and "
                            "was not used in the ranking."
                        )
                    ]
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
    def _profile_evidence(
        transcript: dict[str, Any] | None,
        linkedin_profile: dict[str, Any] | None,
        github_profile: dict[str, Any] | None,
        resume_profile: dict[str, Any] | None = None,
    ) -> tuple[
        dict[str, list[dict[str, str]]],
        list[dict[str, Any]],
        bool,
        bool,
        bool,
        bool,
    ]:
        academic_ready = bool(transcript and transcript.get("courses"))
        linkedin_ready = bool(linkedin_profile)
        github_ready = bool(
            github_profile
            and (
                github_profile.get("repositories")
                or github_profile.get("skills")
            )
        )
        resume_ready = bool(resume_profile)
        source_available = {
            "academic_transcript": academic_ready,
            "linkedin_pdf": linkedin_ready,
            "github": github_ready,
            "resume": resume_ready,
        }
        source_skills: dict[str, set[str]] = {
            source: set() for source in source_available
        }
        source_items: Counter[str] = Counter()
        evidence_index: dict[str, list[dict[str, str]]] = {}
        seen_citations: set[tuple[str, str, str, str]] = set()

        def add_evidence(
            source: str,
            evidence_type: str,
            label: str,
            text: Any,
            *,
            explicit_skills: set[str] | None = None,
        ) -> None:
            clean_label = _excerpt(label)
            if not clean_label:
                return
            source_items[source] += 1
            skills = _skills_in_text(text)
            if explicit_skills:
                skills.update(
                    _canonical_skill(skill)
                    for skill in explicit_skills
                    if _canonical_skill(skill)
                )
            skills = _expand_skills(skills)
            for skill in sorted(skills):
                citation_key = (skill, source, evidence_type, clean_label)
                if citation_key in seen_citations:
                    continue
                seen_citations.add(citation_key)
                source_skills[source].add(skill)
                evidence_index.setdefault(skill, []).append(
                    {
                        "skill": skill,
                        "source": source,
                        "evidence_type": evidence_type,
                        "evidence": clean_label,
                    }
                )

        if transcript:
            for course in transcript.get("courses", []):
                if not isinstance(course, dict):
                    continue
                name = str(course.get("course", "")).strip()
                if not name:
                    continue
                grade = str(course.get("grade", "")).strip()
                # A failed course is still part of the academic profile, but
                # must not be presented as evidence of a demonstrated skill.
                if grade.casefold() in {"f", "fail", "failed"}:
                    source_items["academic_transcript"] += 1
                    continue
                academic_skills = _skill_hints(
                    name,
                    ACADEMIC_SKILL_HINTS,
                )
                label = f"Coursework: {name}"
                if grade:
                    label = f"{label} (grade {grade})"
                add_evidence(
                    "academic_transcript",
                    "coursework",
                    label,
                    name,
                    explicit_skills=academic_skills,
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
                    for item in value:
                        add_evidence(
                            "linkedin_pdf",
                            "self_reported",
                            f"LinkedIn {field}: {_excerpt(item)}",
                            item,
                        )
                elif value:
                    add_evidence(
                        "linkedin_pdf",
                        "self_reported",
                        f"LinkedIn {field}: {_excerpt(value)}",
                        value,
                    )
        if github_profile:
            for skill in github_profile.get("skills", []):
                if isinstance(skill, dict):
                    name = str(skill.get("skill", "")).strip()
                    repositories = [
                        str(value)
                        for value in skill.get("evidence_repos", [])
                        if str(value).strip()
                    ]
                    label = f"GitHub skill signal: {name}"
                    if repositories:
                        label = f"{label} ({', '.join(repositories[:3])})"
                    add_evidence(
                        "github",
                        "project",
                        label,
                        name,
                        explicit_skills={name},
                    )
            for repository in github_profile.get("repositories", []):
                if not isinstance(repository, dict):
                    continue
                name = str(repository.get("name", "repository")).strip()
                details = " ".join(
                    str(repository.get(field, ""))
                    for field in (
                        "description",
                        "primary_language",
                        "topics",
                        "languages",
                        "detected_skills",
                        "readme_excerpt",
                    )
                )
                explicit = {
                    str(value)
                    for value in repository.get("detected_skills", [])
                    if str(value).strip()
                }
                primary_language = repository.get("primary_language")
                if primary_language:
                    explicit.add(str(primary_language))
                add_evidence(
                    "github",
                    "project",
                    f"GitHub repository {name}: {_excerpt(details)}",
                    details,
                    explicit_skills=explicit,
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
                    for item in value:
                        add_evidence(
                            "resume",
                            "resume_claim",
                            f"Resume {field}: {_excerpt(item)}",
                            item,
                        )
                elif value:
                    add_evidence(
                        "resume",
                        "resume_claim",
                        f"Resume {field}: {_excerpt(value)}",
                        value,
                    )
        source_summaries = [
            {
                "source": source,
                "available": available,
                "skills": sorted(source_skills[source]),
                "evidence_items": source_items[source],
            }
            for source, available in source_available.items()
        ]
        return (
            evidence_index,
            source_summaries,
            academic_ready,
            linkedin_ready,
            github_ready,
            resume_ready,
        )

    @staticmethod
    def _skills_in(text: str) -> set[str]:
        return _skills_in_text(text)

    @staticmethod
    def _role_family(title: str) -> str:
        normalized = _normalized_text(title)
        for family, patterns in ROLE_PATTERNS:
            if any(pattern in normalized for pattern in patterns):
                return family
        return "general"

    @staticmethod
    def _required_skills(posting: Any, family: str) -> set[str]:
        metadata = posting.metadata or {}
        listing_text = " ".join(
            str(value or "")
            for value in (
                posting.title,
                posting.category,
                metadata.get("source"),
                metadata.get("skills"),
                metadata.get("tags"),
                metadata.get("description"),
                metadata.get("requirements"),
            )
        )
        required = set(ROLE_SKILLS[family])
        required.update(_skills_in_text(listing_text))
        required.update(_skill_hints(listing_text, TITLE_SKILL_HINTS))
        explicit_languages = required.intersection(
            {
                "java",
                "c#",
                "c++",
                "go",
                "rust",
                "kotlin",
                "php",
                "ruby",
                "scala",
                "javascript",
                "typescript",
                "swift",
                "flutter",
            }
        )
        if family == "backend" and not explicit_languages:
            required.add("python")
        return {_canonical_skill(skill) for skill in required if skill}

    def _match_job(
        self,
        posting,
        *,
        known_skills: set[str],
        evidence_index: dict[str, list[dict[str, str]]],
        keywords: list[str],
        locations: list[str],
        target_market: str,
        work_modes: list[str],
    ) -> dict[str, Any]:
        family = self._role_family(
            f"{posting.title} {posting.category or ''}"
        )
        expected_skills = self._required_skills(posting, family)
        job_text = (
            f"{posting.title} {posting.company} {posting.location} "
            f"{posting.category or ''}"
        ).casefold()
        direct_keyword_matches = sorted(
            keyword for keyword in keywords if keyword in job_text
        )
        inferred_keyword_matches = sorted(
            keyword
            for keyword in keywords
            if keyword not in direct_keyword_matches
            and _canonical_skill(keyword) in expected_skills
        )
        keyword_matches = sorted(
            {*direct_keyword_matches, *inferred_keyword_matches}
        )
        skill_matches = sorted(expected_skills.intersection(known_skills))
        gaps = sorted(expected_skills - known_skills)[:8]
        all_citations = [
            citation
            for skill in skill_matches
            for citation in evidence_index.get(skill, [])[:3]
        ]
        evidence_citations: list[dict[str, str]] = []
        for source in (
            "academic_transcript",
            "linkedin_pdf",
            "github",
            "resume",
        ):
            citation = next(
                (
                    value
                    for value in all_citations
                    if value["source"] == source
                ),
                None,
            )
            if citation is not None:
                evidence_citations.append(citation)
        evidence_citations.extend(
            citation
            for citation in all_citations
            if citation not in evidence_citations
        )
        evidence_citations = evidence_citations[:16]
        cited_sources = sorted(
            {citation["source"] for citation in evidence_citations}
        )
        location_matches = sorted(
            location
            for location in locations
            if location.casefold() in posting.location.casefold()
        )

        coverage = (
            len(skill_matches) / len(expected_skills)
            if expected_skills
            else 0
        )
        score = 10
        score += round(coverage * 50)
        score += min(20, len(keyword_matches) * 10)
        if location_matches:
            score += 15
        elif target_market == "global":
            score += 5
        if "remote" in work_modes and "remote" in posting.location.casefold():
            score += 5
        if len(cited_sources) >= 2:
            score += 5
        score = min(score, 100)

        reasons = []
        if direct_keyword_matches:
            reasons.append(
                "Listing metadata matches preference: "
                f"{', '.join(direct_keyword_matches[:3])}."
            )
        if inferred_keyword_matches:
            reasons.append(
                "Inferred role profile aligns with preference: "
                f"{', '.join(inferred_keyword_matches[:3])}."
            )
        if skill_matches:
            reasons.append(
                "Verified profile evidence for "
                f"{', '.join(skill_matches[:4])} "
                "("
                f"{', '.join(EVIDENCE_SOURCE_NAMES[source] for source in cited_sources)}"
                ")."
            )
        if location_matches:
            reasons.append(
                f"Location match: {', '.join(location_matches[:2])}"
            )
        if (
            "remote" in work_modes
            and "remote" in posting.location.casefold()
        ):
            reasons.append("Listing metadata indicates remote work.")
        if not reasons:
            reasons.append(
                "No direct profile-skill, preference, or location match was "
                "verified; this listing is shown from the selected live feed."
            )

        if coverage >= 0.75:
            assessment_summary = (
                "Connected evidence supports most of the skills inferred for "
                "this role, but the employer page still needs verification."
            )
        elif coverage >= 0.4:
            assessment_summary = (
                "Connected evidence supports part of this role profile; "
                "several inferred skills remain unverified."
            )
        elif skill_matches:
            assessment_summary = (
                "Only a small part of this role profile is supported by "
                "connected evidence. Treat this as a stretch opportunity."
            )
        else:
            assessment_summary = (
                "No connected profile source currently verifies the inferred "
                f"{family.replace('-', ' ')} requirements for this role."
            )
        assessment_confidence = (
            "medium"
            if family != "general"
            and len(expected_skills) >= 4
            and evidence_citations
            else "low"
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
            "required_skills": sorted(expected_skills),
            "match_score": score,
            "match_reasons": reasons,
            "keyword_matches": keyword_matches,
            "profile_skill_matches": skill_matches,
            "profile_evidence_citations": evidence_citations,
            "inferred_skill_gaps": gaps,
            "assessment_summary": assessment_summary,
            "assessment_confidence": assessment_confidence,
            "recommended_course_ids": [],
        }
