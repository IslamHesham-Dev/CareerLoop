import sys
from app.config import Settings
from company_jobs_connector import CompanyJobsConnector

def main():
    company = input("Enter a company name (e.g. anthropic, stripe): ").strip()
    if not company:
        print("Company name cannot be empty.")
        return

    print("Initializing CompanyJobsConnector...")
    settings = Settings()
    api_key = settings.anthropic_api_key.get_secret_value()
    if not api_key:
        print("Error: ANTHROPIC_API_KEY is not configured in your environment/settings.")
        return
        
    connector = CompanyJobsConnector(anthropic_api_key=api_key)
    
    print(f"Searching ATS pages for '{company}' and extracting with Claude (this might take a few seconds)...\n")
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
