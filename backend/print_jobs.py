import sys
from pathlib import Path

from dotenv import load_dotenv

from app.config import Settings
from app.llm import LlmConfigurationError, resolve_llm
from company_jobs_connector import CompanyJobsConnector


def load_env_file(path: str | Path = ".env") -> Path:
    """Load a local env file for the standalone connector demo."""
    env_path = Path(path)
    load_dotenv(env_path, override=False)
    return env_path

def main():
    load_env_file()
    company = input("Enter a company name (e.g. anthropic, stripe): ").strip()
    if not company:
        print("Company name cannot be empty.")
        return

    print("Initializing CompanyJobsConnector...")
    settings = Settings()
    try:
        runtime = resolve_llm(settings)
    except LlmConfigurationError as exc:
        print(f"Error: {exc}")
        return
        
    connector = CompanyJobsConnector(
        anthropic_api_key=runtime.api_key,
        model=runtime.model,
        provider=runtime.provider,
    )
    
    print(
        f"Searching ATS pages for '{company}' and extracting with "
        f"{runtime.model} (this might take a few seconds)...\n"
    )
    try:
        jobs = connector.get_company_jobs(company)
    except Exception as e:
        print(f"Failed to fetch jobs: {e}")
        return

    if not jobs:
        print(f"No open roles found for '{company}', or they use an unsupported ATS platform.")
        return

    print(f"Found {len(jobs)} jobs:\n")
    for i, job in enumerate(jobs, 1):
        print(f"[{i}] {job.title}")
        print(f"    Department: {job.department or 'N/A'}")
        print(f"    Location:   {job.location}")
        print(f"    Link:       {job.link}\n")

if __name__ == "__main__":
    main()
