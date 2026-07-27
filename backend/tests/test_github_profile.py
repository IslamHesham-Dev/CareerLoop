from __future__ import annotations

from app import github_profile
from github_connector.models import (
    GithubProfile,
    Repository,
    RepositoryDetail,
)


class FakeResponse:
    def __init__(self, payload):
        self.payload = payload

    def raise_for_status(self) -> None:
        return None

    def json(self):
        return self.payload


def test_device_flow_requests_identity_without_private_repo_scope(
    monkeypatch,
) -> None:
    captured = {}

    def fake_post(url, **kwargs):
        captured["url"] = url
        captured["data"] = kwargs["data"]
        return FakeResponse(
            {
                "device_code": "device-secret",
                "user_code": "ABCD-1234",
                "verification_uri": "https://github.com/login/device",
                "expires_in": 900,
                "interval": 5,
            }
        )

    monkeypatch.setattr(github_profile.requests, "post", fake_post)
    result = github_profile.GithubDeviceClient("client-id").start()

    assert captured["url"] == github_profile.DEVICE_CODE_URL
    assert captured["data"]["scope"] == "read:user"
    assert "repo" not in captured["data"]["scope"]
    assert result["user_code"] == "ABCD-1234"


def test_device_flow_maps_pending_authorization(monkeypatch) -> None:
    monkeypatch.setattr(
        github_profile.requests,
        "post",
        lambda *args, **kwargs: FakeResponse(
            {
                "error": "authorization_pending",
                "error_description": "Waiting for approval",
            }
        ),
    )

    result = github_profile.GithubDeviceClient("client-id").poll("device")

    assert result == {
        "status": "pending",
        "message": "Waiting for approval",
    }


def test_profile_extraction_keeps_public_evidence_and_excludes_private(
    monkeypatch,
) -> None:
    public = Repository(
        name="careerloop",
        full_name="student/careerloop",
        description="Academic and career agent",
        html_url="https://github.com/student/careerloop",
        primary_language="Python",
        topics=["fastapi"],
        stargazers_count=4,
        forks_count=1,
        is_fork=False,
        is_archived=False,
        pushed_at="2026-07-01T00:00:00Z",
        default_branch="main",
    )
    private = Repository(
        name="secret",
        full_name="student/secret",
        description=None,
        html_url="https://github.com/student/secret",
        primary_language="Python",
        topics=[],
        stargazers_count=0,
        forks_count=0,
        is_fork=False,
        is_archived=False,
        pushed_at="2026-06-01T00:00:00Z",
        default_branch="main",
        is_private=True,
    )

    class FakeConnector:
        def __init__(self, **kwargs) -> None:
            pass

        def get_profile(self) -> GithubProfile:
            return GithubProfile(
                login="student",
                name="Student",
                bio="Builder",
                company=None,
                location="Berlin",
                public_repos=1,
                followers=2,
                html_url="https://github.com/student",
                avatar_url="https://avatars.githubusercontent.com/u/1",
            )

        def list_repositories(self):
            return [public, private]

        def get_repository_detail(self, repository, **kwargs):
            return RepositoryDetail(
                repository=repository,
                languages={"Python": 9000, "Dart": 3000},
                readme_excerpt="CareerLoop uses FastAPI.",
                manifests={
                    "backend/requirements.txt": "fastapi==0.115.0",
                },
            )

    monkeypatch.setattr(github_profile, "GithubConnector", FakeConnector)
    result = github_profile.extract_github_profile("oauth-token")

    assert result.repository_count == 1
    assert result.analyzed_repository_count == 1
    assert [repo.name for repo in result.repositories] == ["careerloop"]
    assert result.languages == {"Python": 9000, "Dart": 3000}
    assert {skill.skill for skill in result.skills} >= {
        "Python",
        "Dart",
        "FastAPI",
    }


def test_github_connection_routes_are_exposed() -> None:
    from app.api.routes import career

    paths = {route.path for route in career.router.routes}

    assert "/career/github-profile" in paths
    assert "/career/github/connect/start" in paths
    assert "/career/github/connect/poll" in paths
    assert "/career/github-profile/sync" in paths
    assert "/career/github-profile/refresh" in paths
    assert "/career/github-profile/remove" in paths
