from swelist_connector import SwelistConnector

def main():
    print("Initializing swelist connector...")
    connector = SwelistConnector()
    
    print("Fetching the latest tech internships from the last day (this might take a few seconds)...\n")
    try:
        jobs = connector.get_postings(role="internship", timeframe="lastday")
    except Exception as e:
        print(f"Failed to fetch jobs: {e}")
        return

    print(f"Found {len(jobs)} internships:\n")
    for i, job in enumerate(jobs, 1):
        print(f"[{i}] {job.title}")
        print(f"    Company:  {job.company}")
        print(f"    Location: {job.location}")
        print(f"    Link:     {job.link}\n")

if __name__ == "__main__":
    main()
