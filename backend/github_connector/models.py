"""Plain data holders for what the GitHub API gives back.

Dataclasses on purpose, same reasoning as guc_cms/models.py: no logic, easy to
print, one `dataclasses.asdict` away from the JSON a tool has to return.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class GithubProfile:
    """The authenticated student's public profile."""

    login: str
    name: str | None
    bio: str | None
    company: str | None
    location: str | None
    public_repos: int
    followers: int
    html_url: str


@dataclass
class Repository:
    """One repo row from the authenticated user's repo list."""

    name: str
    full_name: str  # "owner/repo", what every other API call keys on
    description: str | None
    html_url: str
    primary_language: str | None
    topics: list[str]
    stargazers_count: int
    forks_count: int
    is_fork: bool
    is_archived: bool
    pushed_at: str | None  # ISO 8601 timestamp of the last push; a recency signal


@dataclass
class RepositoryDetail:
    """A repo plus the extra pulls needed to reason about skills, not just its blurb."""

    repository: Repository
    languages: dict[str, int]  # language -> bytes written, from GitHub's linguist
    readme_excerpt: str | None  # first N chars of the decoded README
    manifests: dict[str, str]  # filename -> raw contents, for dependency scanning


@dataclass
class SkillEvidence:
    """One inferred skill, with where it came from and how strong the signal is.

    `weight` is only comparable within the same category: for "language" it is
    cumulative bytes written (a depth signal), for everything else it is the
    number of distinct repos that evidence it (a repetition signal). See
    `_skills.extract_skills` for how the two get combined and ranked.
    """

    skill: str
    category: str  # e.g. "language", "backend framework", "database", "devops"
    evidence_repos: list[str] = field(default_factory=list)
    weight: float = 0.0
