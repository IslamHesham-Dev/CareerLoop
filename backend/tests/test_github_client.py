from github_connector.client import select_manifest_matches


def test_select_manifest_matches_finds_a_manifest_nested_in_a_subdirectory() -> None:
    file_paths = ["README.md", "backend/pyproject.toml", "mobile/pubspec.yaml"]

    matches = select_manifest_matches(file_paths, ("pyproject.toml",))

    assert matches == {"pyproject.toml": ["backend/pyproject.toml"]}


def test_select_manifest_matches_prefers_shallower_paths_and_caps_the_count() -> None:
    file_paths = [
        "examples/vendor/deep/nested/package.json",
        "backend/package.json",
        "package.json",
        "frontend/admin/package.json",
    ]

    matches = select_manifest_matches(file_paths, ("package.json",), max_matches_per_name=2)

    assert matches["package.json"] == ["package.json", "backend/package.json"]


def test_select_manifest_matches_is_case_insensitive_on_the_basename() -> None:
    file_paths = ["deploy/Dockerfile"]

    matches = select_manifest_matches(file_paths, ("Dockerfile",))

    assert matches == {"dockerfile": ["deploy/Dockerfile"]}


def test_select_manifest_matches_ignores_unrelated_files() -> None:
    file_paths = ["README.md", "src/main.py"]

    matches = select_manifest_matches(file_paths, ("package.json", "requirements.txt"))

    assert matches == {}
