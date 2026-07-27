from __future__ import annotations

from collections import Counter
from dataclasses import asdict
from datetime import UTC, datetime
from typing import Any

import requests

from github_connector import GithubConnector, extract_skills
from github_connector._skills import extract_repository_skills

from app.schemas.career import GithubProfileEvidence


DEVICE_CODE_URL = "https://github.com/login/device/code"
ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token"
MAX_ANALYZED_REPOSITORIES = 12


class GithubConfigurationError(RuntimeError):
    pass


class GithubConnectionError(RuntimeError):
    pass


class GithubDeviceClient:
    """GitHub OAuth device flow without exposing an OAuth secret to Flutter."""

    def __init__(self, client_id: str, *, timeout: int = 30) -> None:
        if not client_id.strip():
            raise GithubConfigurationError(
                "GitHub connection is not configured on this deployment."
            )
        self.client_id = client_id.strip()
        self.timeout = timeout

    def start(self) -> dict[str, Any]:
        try:
            response = requests.post(
                DEVICE_CODE_URL,
                headers={
                    "Accept": "application/json",
                    "User-Agent": "CareerLoop/1.0",
                },
                data={
                    "client_id": self.client_id,
                    # CareerLoop deliberately evaluates recruiter-visible public
                    # repositories. It does not request the broad `repo` scope.
                    "scope": "read:user",
                },
                timeout=self.timeout,
            )
            response.raise_for_status()
        except requests.RequestException as exc:
            raise GithubConnectionError(
                "GitHub authorization is temporarily unavailable."
            ) from exc
        payload = response.json()
        if payload.get("error"):
            raise GithubConnectionError(
                str(payload.get("error_description") or payload["error"])
            )
        required = {
            "device_code",
            "user_code",
            "verification_uri",
            "expires_in",
            "interval",
        }
        if not required.issubset(payload):
            raise GithubConnectionError(
                "GitHub returned an incomplete device authorization response."
            )
        return payload

    def poll(self, device_code: str) -> dict[str, Any]:
        try:
            response = requests.post(
                ACCESS_TOKEN_URL,
                headers={
                    "Accept": "application/json",
                    "User-Agent": "CareerLoop/1.0",
                },
                data={
                    "client_id": self.client_id,
                    "device_code": device_code,
                    "grant_type": (
                        "urn:ietf:params:oauth:grant-type:device_code"
                    ),
                },
                timeout=self.timeout,
            )
            response.raise_for_status()
        except requests.RequestException as exc:
            raise GithubConnectionError(
                "GitHub authorization is temporarily unavailable."
            ) from exc
        payload = response.json()
        if payload.get("access_token"):
            return {
                "status": "connected",
                "access_token": str(payload["access_token"]),
            }
        error = str(payload.get("error") or "")
        statuses = {
            "authorization_pending": "pending",
            "slow_down": "slow_down",
            "expired_token": "expired",
            "access_denied": "denied",
        }
        if error in statuses:
            return {
                "status": statuses[error],
                "message": payload.get("error_description"),
            }
        raise GithubConnectionError(
            str(
                payload.get("error_description")
                or error
                or "GitHub authorization could not be completed."
            )
        )


def extract_github_profile(
    access_token: str,
    *,
    max_repositories: int = MAX_ANALYZED_REPOSITORIES,
) -> GithubProfileEvidence:
    """Create a bounded, evidence-backed snapshot of public GitHub work."""
    connector = GithubConnector(token=access_token, timeout=35)
    profile = connector.get_profile()
    repositories = [
        repo
        for repo in connector.list_repositories()
        if not repo.is_private
    ]
    # The API is already sorted by most recently pushed. Ownership comes
    # before collaboration so the strongest authorship signal wins ties.
    repositories.sort(
        key=lambda repo: not repo.full_name.casefold().startswith(
            f"{profile.login.casefold()}/"
        )
    )

    details = []
    for repository in repositories[:max_repositories]:
        try:
            details.append(
                connector.get_repository_detail(
                    repository,
                    include_readme=True,
                    max_matches_per_manifest=2,
                )
            )
        except requests.RequestException:
            # One empty, deleted, or policy-restricted repository should not
            # discard every other piece of portfolio evidence.
            continue

    aggregate_languages: Counter[str] = Counter()
    for detail in details:
        aggregate_languages.update(detail.languages)

    skills = extract_skills(details)
    repository_evidence: list[dict[str, Any]] = []
    for detail in details:
        repository = detail.repository
        repository_skills = extract_repository_skills(detail)
        repository_evidence.append(
            {
                "name": repository.name,
                "full_name": repository.full_name,
                "description": repository.description,
                "html_url": repository.html_url,
                "primary_language": repository.primary_language,
                "languages": detail.languages,
                "topics": repository.topics,
                "stars": repository.stargazers_count,
                "forks": repository.forks_count,
                "pushed_at": repository.pushed_at,
                "readme_excerpt": (
                    detail.readme_excerpt[:1600]
                    if detail.readme_excerpt
                    else None
                ),
                "detected_skills": list(
                    dict.fromkeys(item.skill for item in repository_skills)
                ),
            }
        )

    return GithubProfileEvidence(
        login=profile.login,
        name=profile.name,
        bio=profile.bio,
        company=profile.company,
        location=profile.location,
        avatar_url=profile.avatar_url,
        html_url=profile.html_url,
        public_repos=profile.public_repos,
        followers=profile.followers,
        repository_count=len(repositories),
        analyzed_repository_count=len(details),
        refreshed_at=datetime.now(UTC).isoformat(),
        languages=dict(aggregate_languages.most_common()),
        skills=[asdict(item) for item in skills[:100]],
        repositories=repository_evidence,
    )
