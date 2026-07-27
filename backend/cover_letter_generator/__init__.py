"""cover_letter_generator: create personalized cover letters from career data and job postings."""

from .client import CoverLetterGenerator, generate_cover_letter

__all__ = [
    "CoverLetterGenerator",
    "generate_cover_letter",
]
