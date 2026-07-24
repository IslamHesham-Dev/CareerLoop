"""The one object you talk to: `GithubConnector`.

    from github_connector import GithubConnector

    gh = GithubConnector(token="ghp_...")   # or set GITHUB_TOKEN
    profile = gh.get_profile()
    for repo in gh.list_repositories():
        detail = gh.get_repository_detail(repo)
        ...

Auth is a personal access token (fine-grained or classic, `public_repo`/`repo`
+ `read:user` scope) — the same "paste a token" flow GitHub itself recommends
for scripts, so no OAuth app registration or callback URL is needed for this
build. Like GucPortal/GucCms, the token lives only where the caller puts it
(a StudentSession field, once this is wired into one); nothing in this module
persists it anywhere.

Everything below returns plain dataclasses (see models.py), so wrapping these
calls as agent tools later is one `dataclasses.asdict` away, same as the CMS
and portal clients.
"""

from __future__ import annotations

import base64
import os

import requests

from ._skills import KNOWN_MANIFEST_FILES
from .models import GithubProfile, Repository, RepositoryDetail

API_URL = "https://api.github.com"  # GitHub.com only; no GHES site profile yet
API_VERSION = "2022-11-28"


def select_manifest_matches(
    file_paths: list[str],
    manifest_files: tuple[str, ...],
    *,
    max_matches_per_name: int = 2,
) -> dict[str, list[str]]:
    """Which tree paths count as which known manifest, shallowest first.

    Pure and network-free on purpose: this is the "did we find the manifest"
    decision, and it deserves a direct unit test (see
    tests/test_github_client.py) without mocking an HTTP call to exercise it.

    Returns {lowercased manifest name -> matching full paths}, each list
    capped at `max_matches_per_name` and sorted so a shallower match (more
    likely the project's own manifest than a vendored/example copy) wins.
    """
    wanted = {name.lower() for name in manifest_files}
    matches_by_name: dict[str, list[str]] = {}
    for path in file_paths:
        basename = path.rsplit("/", 1)[-1]
        if basename.lower() in wanted:
            matches_by_name.setdefault(basename.lower(), []).append(path)
    return {
        name: sorted(paths, key=lambda p: p.count("/"))[:max_matches_per_name]
        for name, paths in matches_by_name.items()
    }


class GithubConnector:
    """A token-authenticated connection to a student's GitHub account."""

    def __init__(
        self,
        token: str | None = None,
        *,
        api_url: str | None = None,
        timeout: int = 30,
    ) -> None:
        token = token or os.environ.get("GITHUB_TOKEN")
        if not token:
            raise ValueError(
                "Missing credentials: pass a personal access token, or set "
                "GITHUB_TOKEN in your environment."
            )
        self.api_url = (api_url or API_URL).rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": API_VERSION,
            }
        )

    # -- low level -----------------------------------------------------------

    def _get(self, path: str, **params: str | int) -> requests.Response:
        response = self.session.get(
            self.api_url + path, params=params or None, timeout=self.timeout
        )
        response.raise_for_status()
        return response

    def _get_optional(self, path: str) -> requests.Response | None:
        """Like `_get`, but a 404 means "not present", not an error.

        Used for anything that only sometimes exists on a repo (a README, one
        specific manifest file) so a normal absence doesn't look like a
        connector failure.
        """
        response = self.session.get(self.api_url + path, timeout=self.timeout)
        if response.status_code == 404:
            return None
        response.raise_for_status()
        return response

    @staticmethod
    def _repo_key(repo: Repository | str) -> str:
        return repo.full_name if isinstance(repo, Repository) else repo

    # -- profile & repos -------------------------------------------------------

    def get_profile(self) -> GithubProfile:
        """The authenticated student's public profile."""
        data = self._get("/user").json()
        return GithubProfile(
            login=data["login"],
            name=data.get("name"),
            bio=data.get("bio"),
            company=data.get("company"),
            location=data.get("location"),
            public_repos=data.get("public_repos", 0),
            followers=data.get("followers", 0),
            html_url=data["html_url"],
        )

    def list_repositories(
        self, *, include_forks: bool = False, include_archived: bool = False
    ) -> list[Repository]:
        """Repos owned or collaborated on by the authenticated student.

        Forks and archived repos are excluded by default: a fork is someone
        else's work and an archived repo is retired, so neither is good CV
        evidence on its own — both can be opted back in if needed.
        """
        repos: list[Repository] = []
        page = 1
        while True:
            data = self._get(
                "/user/repos",
                per_page=100,
                page=page,
                sort="pushed",
                affiliation="owner,collaborator",
            ).json()
            if not data:
                break
            for item in data:
                if item.get("fork") and not include_forks:
                    continue
                if item.get("archived") and not include_archived:
                    continue
                repos.append(
                    Repository(
                        name=item["name"],
                        full_name=item["full_name"],
                        description=item.get("description"),
                        html_url=item["html_url"],
                        primary_language=item.get("language"),
                        topics=item.get("topics") or [],
                        stargazers_count=item.get("stargazers_count", 0),
                        forks_count=item.get("forks_count", 0),
                        is_fork=item.get("fork", False),
                        is_archived=item.get("archived", False),
                        pushed_at=item.get("pushed_at"),
                        default_branch=item.get("default_branch") or "main",
                    )
                )
            if len(data) < 100:
                break
            page += 1
        return repos

    # -- per-repo detail, the part that matters for skill extraction ---------

    def get_languages(self, repo: Repository | str) -> dict[str, int]:
        """Bytes of code per language, straight from GitHub's linguist.

        A far better skill signal than the single `primary_language` on the
        repo listing: a "Python" repo that is 40% TypeScript means the
        student also wrote a real frontend for it.
        """
        return self._get(f"/repos/{self._repo_key(repo)}/languages").json()

    def get_readme(self, repo: Repository | str, *, max_chars: int = 4000) -> str | None:
        """The decoded README, truncated. None if the repo has no README."""
        response = self._get_optional(f"/repos/{self._repo_key(repo)}/readme")
        if response is None:
            return None
        data = response.json()
        content = base64.b64decode(data["content"]).decode("utf-8", errors="replace")
        return content[:max_chars]

    def get_file(self, repo: Repository | str, path: str) -> str | None:
        """Raw decoded contents of one file, or None if it does not exist.

        Used to pull dependency manifests (package.json, requirements.txt,
        ...) for `_skills.extract_skills`. Only handles files small enough for
        GitHub to inline as base64 (well under 1MB), which every manifest
        this connector looks for is.
        """
        response = self._get_optional(f"/repos/{self._repo_key(repo)}/contents/{path}")
        if response is None:
            return None
        data = response.json()
        if data.get("encoding") != "base64":
            return None
        return base64.b64decode(data["content"]).decode("utf-8", errors="replace")

    def list_file_paths(self, repo: Repository, *, max_entries: int = 5000) -> list[str]:
        """Every file path in the repo's default branch, in one call.

        This is what makes manifest discovery monorepo-safe: a `pyproject.toml`
        under `backend/` or a `package.json` under `mobile/` shows up exactly
        the same way a root-level one would, instead of only being found by
        guessing root paths. An empty/unborn repo (no commits yet) has no tree
        to fetch; that 404s and is treated as "no files" by the caller.

        GitHub truncates very large trees (repos over ~100k entries or a 7MB
        response) rather than erroring; `max_entries` just bounds how many
        paths we look at afterwards in that rare case.
        """
        data = self._get(
            f"/repos/{self._repo_key(repo)}/git/trees/{repo.default_branch}",
            recursive="1",
        ).json()
        return [
            entry["path"]
            for entry in data.get("tree", [])
            if entry.get("type") == "blob"
        ][:max_entries]

    def get_repository_detail(
        self,
        repo: Repository,
        *,
        include_readme: bool = True,
        manifest_files: tuple[str, ...] = KNOWN_MANIFEST_FILES,
        max_matches_per_manifest: int = 2,
    ) -> RepositoryDetail:
        """Everything `_skills.extract_skills` needs for one repo.

        Walks the repo's file tree once (`list_file_paths`) and reads whatever
        matches a name in `manifest_files`, at any depth — a monorepo's
        `backend/pyproject.toml` is found the same way a root one would be.
        When a name matches more than once (e.g. a `package.json` for both a
        frontend and a backend), the shallowest `max_matches_per_manifest`
        matches are read, on the assumption that deeply nested duplicates are
        more likely vendored/example code than the project's own manifests.

        This is the expensive call per repo (one tree listing, plus one
        request per manifest match, plus languages/README) — call it per-repo,
        not for a student's whole account at once, unless you mean to.
        """
        languages = self.get_languages(repo)
        readme_excerpt = self.get_readme(repo) if include_readme else None

        try:
            file_paths = self.list_file_paths(repo)
        except requests.HTTPError:
            file_paths = []  # e.g. an empty repo with no tree yet

        selected = select_manifest_matches(
            file_paths, manifest_files, max_matches_per_name=max_matches_per_manifest
        )
        manifests: dict[str, str] = {}
        for paths in selected.values():
            for path in paths:
                content = self.get_file(repo, path)
                if content is not None:
                    manifests[path] = content

        return RepositoryDetail(
            repository=repo,
            languages=languages,
            readme_excerpt=readme_excerpt,
            manifests=manifests,
        )
