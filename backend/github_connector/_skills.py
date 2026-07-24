"""Turn raw GitHub data into skill claims, not just repo names.

A CV built from "3 repos: name + description" is thin. The signal that
actually says "this student can build a REST API in FastAPI" lives one level
deeper: which files are in the repo, what they import, and how much of the
codebase is which language. This module reads that deeper layer.

Two kinds of functions live here:

  * parsers: raw manifest text -> the package/dependency names inside it.
    Pure string-in, list-out, so they are trivial to unit test without ever
    hitting the network (see tests/test_github_skills.py).
  * extract_skills / extract_repository_skills: the aggregation step that
    turns a pile of per-repo evidence (a RepositoryDetail) into a ranked,
    evidence-backed skill list.

Nothing here calls the network; that stays GithubConnector's job.
"""

from __future__ import annotations

import json
import re

from .models import RepositoryDetail, SkillEvidence

# Manifest/marker files worth reading on every repo. Cheap to check (one HTTP
# call each, tolerant of a 404) and each one is a strong, unambiguous signal
# compared to a repo's self-reported description or topics.
KNOWN_MANIFEST_FILES: tuple[str, ...] = (
    "package.json",
    "requirements.txt",
    "pyproject.toml",
    "Pipfile",
    "go.mod",
    "Cargo.toml",
    "pom.xml",
    "build.gradle",
    "Gemfile",
    "composer.json",
    "Dockerfile",
    "docker-compose.yml",
)


def _parse_package_json(text: str) -> list[str]:
    """dependencies + devDependencies keys. A bad JSON body just yields nothing
    rather than failing the whole extraction — manifests in the wild are messy."""
    try:
        data = json.loads(text)
    except (json.JSONDecodeError, TypeError):
        return []
    names: list[str] = []
    for section in ("dependencies", "devDependencies"):
        names.extend((data.get(section) or {}).keys())
    return names


def _parse_requirements_txt(text: str) -> list[str]:
    names = []
    for line in text.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line or line.startswith("-"):
            continue
        match = re.match(r"^[A-Za-z0-9_.\-]+", line)
        if match:
            names.append(match.group(0))
    return names


def _parse_pyproject_toml(text: str) -> list[str]:
    # Good enough without a TOML dependency: PEP 621's `dependencies = [...]`
    # is a list of quoted requirement strings, and Poetry's dependency tables
    # are `name = "..."` lines. We just pull the package-looking tokens out of
    # both shapes rather than fully parsing TOML.
    names: list[str] = []
    for block in re.findall(r"dependencies\s*=\s*\[(.*?)\]", text, re.DOTALL):
        names.extend(re.findall(r'"([A-Za-z0-9_.\-]+)', block))
    for section in re.findall(
        r"\[tool\.poetry\.(?:dev-)?dependencies\]\s*(.*?)(?=\n\[|\Z)",
        text,
        re.DOTALL,
    ):
        for line in section.splitlines():
            match = re.match(r"^\s*([A-Za-z0-9_.\-]+)\s*=", line)
            if match:
                names.append(match.group(1))
    return names


def _parse_go_mod(text: str) -> list[str]:
    names = []
    for line in text.splitlines():
        match = re.match(r"^\s*([\w.\-/]+)\s+v\d", line.strip())
        if match:
            names.append(match.group(1).rsplit("/", 1)[-1])
    return names


def _parse_cargo_toml(text: str) -> list[str]:
    names = []
    in_deps = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("["):
            in_deps = stripped.startswith("[dependencies")
            continue
        if in_deps:
            match = re.match(r"^([A-Za-z0-9_\-]+)\s*=", stripped)
            if match:
                names.append(match.group(1))
    return names


def _parse_gemfile(text: str) -> list[str]:
    return re.findall(r"gem\s+[\"']([\w\-]+)[\"']", text)


def _parse_composer_json(text: str) -> list[str]:
    try:
        data = json.loads(text)
    except (json.JSONDecodeError, TypeError):
        return []
    names = []
    for section in ("require", "require-dev"):
        names.extend((data.get(section) or {}).keys())
    return names


def _parse_pom_xml(text: str) -> list[str]:
    return re.findall(r"<artifactId>([\w\-.]+)</artifactId>", text)


def _parse_build_gradle(text: str) -> list[str]:
    # "group:artifact:version" coordinate strings, e.g. 'org.springframework:spring-web:6.1'
    return [
        coord.split(":")[1]
        for coord in re.findall(r"['\"]([\w.\-]+:[\w.\-]+:[\w.\-]+)['\"]", text)
    ]


# Keyed by lowercased filename, since `RepositoryDetail.manifests` is keyed by
# full path (a repo can have a manifest of the same name at several depths).
_MANIFEST_PARSERS = {
    "package.json": _parse_package_json,
    "requirements.txt": _parse_requirements_txt,
    "pyproject.toml": _parse_pyproject_toml,
    "pipfile": _parse_requirements_txt,  # close enough: also `name = "..."` per line
    "go.mod": _parse_go_mod,
    "cargo.toml": _parse_cargo_toml,
    "pom.xml": _parse_pom_xml,
    "build.gradle": _parse_build_gradle,
    "gemfile": _parse_gemfile,
    "composer.json": _parse_composer_json,
}

# dependency/marker-file token (lowercased) -> (display skill, category).
# Deliberately a plain dict: extend coverage by adding a line, no code changes
# needed elsewhere. Keys are what a parser above returns or a marker filename.
SKILL_SIGNATURES: dict[str, tuple[str, str]] = {
    # frontend
    "react": ("React", "frontend framework"),
    "react-dom": ("React", "frontend framework"),
    "next": ("Next.js", "frontend framework"),
    "vue": ("Vue.js", "frontend framework"),
    "@angular/core": ("Angular", "frontend framework"),
    "svelte": ("Svelte", "frontend framework"),
    "tailwindcss": ("Tailwind CSS", "frontend styling"),
    "redux": ("Redux", "frontend state management"),
    # backend
    "fastapi": ("FastAPI", "backend framework"),
    "flask": ("Flask", "backend framework"),
    "django": ("Django", "backend framework"),
    "express": ("Express.js", "backend framework"),
    "nestjs": ("NestJS", "backend framework"),
    "@nestjs/core": ("NestJS", "backend framework"),
    "spring-boot-starter": ("Spring Boot", "backend framework"),
    "gin": ("Gin", "backend framework"),
    "actix-web": ("Actix", "backend framework"),
    "rails": ("Ruby on Rails", "backend framework"),
    "laravel/framework": ("Laravel", "backend framework"),
    # data & ml
    "numpy": ("NumPy", "data/ml"),
    "pandas": ("Pandas", "data/ml"),
    "scikit-learn": ("scikit-learn", "data/ml"),
    "torch": ("PyTorch", "data/ml"),
    "tensorflow": ("TensorFlow", "data/ml"),
    "langchain": ("LangChain", "data/ml"),
    "openai": ("OpenAI API", "data/ml"),
    "anthropic": ("Anthropic API", "data/ml"),
    # databases
    "psycopg2": ("PostgreSQL", "database"),
    "psycopg2-binary": ("PostgreSQL", "database"),
    "pymongo": ("MongoDB", "database"),
    "mongoose": ("MongoDB", "database"),
    "redis": ("Redis", "database"),
    "sqlalchemy": ("SQLAlchemy", "database"),
    "mysql2": ("MySQL", "database"),
    # mobile
    "flutter": ("Flutter", "mobile"),
    "react-native": ("React Native", "mobile"),
    # devops / infra
    "dockerfile": ("Docker", "devops"),
    "docker-compose.yml": ("Docker Compose", "devops"),
    "kubernetes": ("Kubernetes", "devops"),
    "terraform": ("Terraform", "devops"),
}


def _repo_manifest_skills(detail: RepositoryDetail) -> list[tuple[str, str]]:
    """(skill, category) pairs evidenced by one repo's manifest files, deduped.

    `detail.manifests` is keyed by full path (e.g. `backend/pyproject.toml`),
    so every lookup here matches on the path's basename rather than the path
    itself — that's what makes a manifest found anywhere in the tree work the
    same as one found at the repo root.
    """
    found: dict[str, str] = {}
    for path, content in detail.manifests.items():
        basename = path.rsplit("/", 1)[-1].lower()
        if basename in ("dockerfile", "docker-compose.yml"):
            signature = SKILL_SIGNATURES.get(basename)
            if signature:
                found[signature[0]] = signature[1]
            continue
        parser = _MANIFEST_PARSERS.get(basename)
        if not parser:
            continue
        for raw_name in parser(content):
            signature = SKILL_SIGNATURES.get(raw_name.strip().lower())
            if signature:
                found[signature[0]] = signature[1]
    return list(found.items())


def extract_repository_skills(detail: RepositoryDetail) -> list[SkillEvidence]:
    """Skills evidenced by one repo: its languages, plus manifest and topic hits.

    Each non-language skill appears at most once per repo here, so when
    `extract_skills` merges repos, its weight is a clean "how many repos show
    this" count rather than double-counting a dependency that shows up in
    both package.json and a topic tag.
    """
    evidence = [
        SkillEvidence(
            skill=language,
            category="language",
            evidence_repos=[detail.repository.name],
            weight=float(bytes_written),
        )
        for language, bytes_written in detail.languages.items()
    ]

    seen_skills: set[str] = {item.skill for item in evidence}
    for skill, category in _repo_manifest_skills(detail):
        if skill in seen_skills:
            continue
        seen_skills.add(skill)
        evidence.append(
            SkillEvidence(
                skill=skill,
                category=category,
                evidence_repos=[detail.repository.name],
                weight=1.0,
            )
        )
    for topic in detail.repository.topics:
        signature = SKILL_SIGNATURES.get(topic.strip().lower())
        if signature and signature[0] not in seen_skills:
            seen_skills.add(signature[0])
            evidence.append(
                SkillEvidence(
                    skill=signature[0],
                    category=signature[1],
                    evidence_repos=[detail.repository.name],
                    weight=1.0,
                )
            )
    return evidence


def extract_skills(details: list[RepositoryDetail]) -> list[SkillEvidence]:
    """Merge per-repo evidence into one ranked, evidence-backed skill list.

    Ranking within "language" is proportional to cumulative bytes written (a
    real depth signal); ranking within every other category is the number of
    distinct repos that show it (a framework used once could be a tutorial
    follow-along; used across three repos, it is a real skill). Languages
    always sort ahead of everything else — see `prompt.py` for how a CV agent
    is expected to use that split.
    """
    merged: dict[tuple[str, str], SkillEvidence] = {}
    for detail in details:
        for item in extract_repository_skills(detail):
            key = (item.skill, item.category)
            existing = merged.setdefault(
                key, SkillEvidence(skill=item.skill, category=item.category)
            )
            for repo in item.evidence_repos:
                if repo not in existing.evidence_repos:
                    existing.evidence_repos.append(repo)
            existing.weight += item.weight

    return sorted(
        merged.values(),
        key=lambda item: (item.category != "language", -item.weight),
    )
