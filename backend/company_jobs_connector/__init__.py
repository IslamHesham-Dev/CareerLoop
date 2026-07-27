"""company_jobs_connector: dynamically fetch ATS pages and LLM-parse them.

    from company_jobs_connector import CompanyJobsConnector

    connector = CompanyJobsConnector(anthropic_api_key="...")
    jobs = connector.get_company_jobs("anthropic")
"""

from .client import CompanyJobsConnector
from .models import CompanyJob

__all__ = [
    "CompanyJobsConnector",
    "CompanyJob",
]
