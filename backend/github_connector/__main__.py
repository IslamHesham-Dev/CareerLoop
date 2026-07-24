"""Command-line preview: connect to GitHub and print what the connector sees.

    cd backend
    $env:GITHUB_TOKEN = "ghp_..."     # PowerShell; a fine-grained PAT with
                                        # public_repo + read:user is enough
    uv run python -m github_connector

Prints the profile, every non-fork/non-archived repo, and the ranked,
evidence-backed skill list `extract_skills` produces from them. This is the
fastest way to sanity-check the connector against a real account before
anything wires it into the app.
"""

from __future__ import annotations

import argparse
import sys

from ._skills import extract_skills
from .client import GithubConnector


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--token", help="GitHub PAT; defaults to the GITHUB_TOKEN env var."
    )
    parser.add_argument(
        "--max-repos",
        type=int,
        default=8,
        help="Cap how many repos to pull full detail for (languages, README, "
        "and each manifest cost one call apiece) — keep this small on a big "
        "account. Default: 8.",
    )
    args = parser.parse_args()

    try:
        gh = GithubConnector(token=args.token)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)

    profile = gh.get_profile()
    print(f"== {profile.name or profile.login} ({profile.html_url}) ==")
    if profile.bio:
        print(profile.bio)
    print()

    repos = gh.list_repositories()
    print(f"{len(repos)} repo(s) (forks/archived excluded)\n")

    details = []
    for repo in repos[: args.max_repos]:
        print(f"- {repo.full_name}: {repo.description or '(no description)'}")
        details.append(gh.get_repository_detail(repo))
    if len(repos) > args.max_repos:
        skipped = len(repos) - args.max_repos
        print(f"  ... and {skipped} more (raise --max-repos to include them)")

    print("\n== extracted skills ==")
    for evidence in extract_skills(details):
        repos_str = ", ".join(evidence.evidence_repos)
        print(f"[{evidence.category}] {evidence.skill} (weight={evidence.weight:.0f}; {repos_str})")


if __name__ == "__main__":
    main()
