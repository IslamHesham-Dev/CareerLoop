"""github_connector: extract a student's GitHub profile, repos, and
evidence-backed technical skills.

    from github_connector import GithubConnector, extract_skills

    gh = GithubConnector(token="github_access_token")
    profile = gh.get_profile()
    repos = gh.list_repositories()
    details = [gh.get_repository_detail(repo) for repo in repos]
    skills = extract_skills(details)

FastAPI session and agent integration live under app/. Nothing in this package
persists a token or writes to disk.

For a no-code sanity check against a real account, run:

    uv run python -m github_connector
"""

from ._skills import extract_skills
from .client import API_URL, GithubConnector, select_manifest_matches
from .models import GithubProfile, Repository, RepositoryDetail, SkillEvidence
from .prompt import SKILL_EXTRACTION_GUIDANCE

__all__ = [
    "GithubConnector",
    "GithubProfile",
    "Repository",
    "RepositoryDetail",
    "SkillEvidence",
    "extract_skills",
    "select_manifest_matches",
    "SKILL_EXTRACTION_GUIDANCE",
    "API_URL",
]
