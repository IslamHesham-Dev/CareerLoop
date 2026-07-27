"""cover_letter_generator: create personalized cover letters from career data and job postings."""

from .client import CoverLetterGenerator, generate_cover_letter, generate_cover_letter_pdf

__all__ = [
    "CoverLetterGenerator",
    "generate_cover_letter",
    "generate_cover_letter_pdf",
]
