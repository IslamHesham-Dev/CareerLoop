"""Plain data holders for what swelist returns.

These are dataclasses on purpose, making them easy to convert to dictionaries 
for the agent tool response.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class JobPosting:
    """One structured posting exposed through the swelist data source."""

    company: str
    title: str
    location: str
    link: str
    external_id: str | None = None
    locations: tuple[str, ...] = ()
    category: str | None = None
    posted_at: str | None = None
    updated_at: str | None = None
    sponsorship: str | None = None
    degrees: tuple[str, ...] = ()
    company_profile_url: str | None = None
    company_logo_url: str | None = None
    active: bool = True
    metadata: dict[str, Any] | None = None
