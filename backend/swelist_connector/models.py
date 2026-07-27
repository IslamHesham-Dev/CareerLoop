"""Plain data holders for what swelist returns.

These are dataclasses on purpose, making them easy to convert to dictionaries 
for the agent tool response.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class JobPosting:
    """One job posting returned from the swelist CLI."""

    company: str
    title: str
    location: str
    link: str
