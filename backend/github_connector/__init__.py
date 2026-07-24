"""github_connector: extract a student's GitHub profile, repos, and
evidence-backed technical skills.

    from github_connector import GithubConnector, extract_skills

    gh = GithubConnector(token="ghp_...")   # or set GITHUB_TOKEN
    profile = gh.get_profile()
    repos = gh.list_repositories()
    details = [gh.get_repository_detail(repo) for repo in repos]
    skills = extract_skills(details)

Like guc_portal and guc_cms, this package knows nothing about agents or
FastAPI sessions — that wiring (a StudentSession field, agent tools under
app/agent/) happens where those two connectors are wired in, so this one
follows the same seam when it's time to plug in the CV-generation feature.
Nothing here persists a token or writes to disk.

For a no-code sanity check against a real account, run:

    uv run python -m github_connector
"""

from ._skills import extract_skills
from .client import API_URL, GithubConnector
from .models import GithubProfile, Repository, RepositoryDetail, SkillEvidence
from .prompt import SKILL_EXTRACTION_GUIDANCE

__all__ = [
    "GithubConnector",
    "GithubProfile",
    "Repository",
    "RepositoryDetail",
    "SkillEvidence",
    "extract_skills",
    "SKILL_EXTRACTION_GUIDANCE",
    "API_URL",
]
