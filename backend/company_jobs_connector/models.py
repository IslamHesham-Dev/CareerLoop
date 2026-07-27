"""Structured outputs for the company job fetcher.

We use Pydantic models because `ChatAnthropic.with_structured_output` 
requires them to enforce schema compliance from the LLM. 
Then we convert them to plain dataclasses to keep the rest of the app decoupled 
from Pydantic if needed.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from pydantic import BaseModel, Field


# The strict schema we force the LLM to output
class LLMJobPosting(BaseModel):
    title: str = Field(description="The job title (e.g. 'Software Engineer').")
    location: str = Field(description="The job location (e.g. 'San Francisco, CA' or 'Remote').")
    department: Optional[str] = Field(description="The department or team, if specified.")
    link: str = Field(description="The full URL to apply to the job.")


class LLMJobExtraction(BaseModel):
    jobs: list[LLMJobPosting] = Field(description="List of all available jobs found in the text.")


# The plain data holder we return to the agent
@dataclass
class CompanyJob:
    title: str
    location: str
    department: str | None
    link: str
