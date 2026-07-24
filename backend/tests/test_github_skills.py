from github_connector._skills import (
    _parse_cargo_toml,
    _parse_package_json,
    _parse_pyproject_toml,
    _parse_requirements_txt,
    extract_repository_skills,
    extract_skills,
)
from github_connector.models import Repository, RepositoryDetail


def _repo(name: str, topics: list[str] | None = None) -> Repository:
    return Repository(
        name=name,
        full_name=f"student/{name}",
        description=None,
        html_url=f"https://github.com/student/{name}",
        primary_language=None,
        topics=topics or [],
        stargazers_count=0,
        forks_count=0,
        is_fork=False,
        is_archived=False,
        pushed_at="2026-01-01T00:00:00Z",
        default_branch="main",
    )


def test_parse_package_json_reads_both_dependency_sections() -> None:
    text = """
    {"dependencies": {"react": "^18.0.0", "express": "^4.0.0"},
     "devDependencies": {"tailwindcss": "^3.0.0"}}
    """

    names = _parse_package_json(text)

    assert set(names) == {"react", "express", "tailwindcss"}


def test_parse_package_json_tolerates_invalid_json() -> None:
    assert _parse_package_json("not json") == []


def test_parse_requirements_txt_strips_versions_and_comments() -> None:
    text = """
    fastapi==0.115.0
    # a comment line
    -e git+https://example.com/pkg.git
    pandas>=2.0
    """

    names = _parse_requirements_txt(text)

    assert names == ["fastapi", "pandas"]


def test_parse_pyproject_toml_reads_pep621_dependency_list() -> None:
    text = """
    [project]
    dependencies = [
        "fastapi>=0.115",
        "langchain>=1.0",
    ]
    """

    names = _parse_pyproject_toml(text)

    assert set(names) == {"fastapi", "langchain"}


def test_parse_cargo_toml_reads_dependencies_table() -> None:
    text = """
    [package]
    name = "demo"

    [dependencies]
    actix-web = "4"
    serde = "1"

    [dev-dependencies]
    criterion = "0.5"
    """

    names = _parse_cargo_toml(text)

    assert names == ["actix-web", "serde"]


def test_extract_repository_skills_combines_languages_manifests_and_topics() -> None:
    detail = RepositoryDetail(
        repository=_repo("careerloop-api", topics=["fastapi", "unrelated-topic"]),
        languages={"Python": 5000, "Dockerfile": 40},
        readme_excerpt=None,
        manifests={
            "requirements.txt": "fastapi==0.115.0\nrequests==2.31\n",
            "Dockerfile": "FROM python:3.12",
        },
    )

    evidence = extract_repository_skills(detail)
    by_skill = {item.skill: item for item in evidence}

    assert by_skill["Python"].category == "language"
    assert by_skill["Python"].weight == 5000
    assert by_skill["FastAPI"].category == "backend framework"
    assert by_skill["Docker"].category == "devops"
    # requests has no entry in SKILL_SIGNATURES, so it must not appear
    assert "requests" not in by_skill
    # the topic "fastapi" duplicates the manifest hit and must not double-count
    assert evidence.count(by_skill["FastAPI"]) == 1


def test_extract_repository_skills_finds_manifests_nested_in_a_subdirectory() -> None:
    # This is the monorepo case that was previously missed: a manifest that
    # lives under a subfolder (e.g. this project's backend/pyproject.toml)
    # rather than at the repo root.
    detail = RepositoryDetail(
        repository=_repo("careerloop"),
        languages={"Python": 100, "Dart": 100},
        readme_excerpt=None,
        manifests={
            "backend/pyproject.toml": 'dependencies = ["fastapi>=0.115", "langchain>=1.0"]',
        },
    )

    by_skill = {item.skill: item for item in extract_repository_skills(detail)}

    assert by_skill["FastAPI"].category == "backend framework"
    assert by_skill["LangChain"].category == "data/ml"


def test_extract_skills_ranks_languages_by_bytes_and_frameworks_by_repo_count() -> None:
    repo_a = RepositoryDetail(
        repository=_repo("repo-a"),
        languages={"Python": 8000},
        readme_excerpt=None,
        manifests={"requirements.txt": "fastapi==0.115.0"},
    )
    repo_b = RepositoryDetail(
        repository=_repo("repo-b"),
        languages={"Python": 2000, "TypeScript": 6000},
        readme_excerpt=None,
        manifests={"requirements.txt": "fastapi==0.115.0"},
    )

    ranked = extract_skills([repo_a, repo_b])
    by_skill = {item.skill: item for item in ranked}

    # languages sort ahead of frameworks regardless of weight
    language_positions = [i for i, item in enumerate(ranked) if item.category == "language"]
    framework_positions = [i for i, item in enumerate(ranked) if item.category != "language"]
    assert max(language_positions) < min(framework_positions)

    assert by_skill["Python"].weight == 10000
    assert set(by_skill["Python"].evidence_repos) == {"repo-a", "repo-b"}
    assert by_skill["FastAPI"].weight == 2  # evidenced in both repos
    assert set(by_skill["FastAPI"].evidence_repos) == {"repo-a", "repo-b"}
