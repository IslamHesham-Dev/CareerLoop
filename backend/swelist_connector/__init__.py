"""swelist_connector: Programmatic wrapper for the swelist CLI tool.

    from swelist_connector import SwelistConnector

    connector = SwelistConnector()
    jobs = connector.get_postings(role="internship", timeframe="lastweek")

This package enables agent tools to fetch real-time tech internships and 
new-grad roles without needing to use subprocess directly inside the agent.
"""

from .client import SwelistConnector
from .models import JobPosting

__all__ = [
    "SwelistConnector",
    "JobPosting",
]
