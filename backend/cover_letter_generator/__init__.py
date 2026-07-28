"""cover_letter_generator: create personalized cover letters from career data and job postings."""

from .client import (
    CoverLetterGenerationResult,
    CoverLetterGenerator,
    generate_cover_letter,
    generate_cover_letter_pdf,
)
from .latex_template import render_cover_letter_latex
from .models import CoverLetterContent

__all__ = [
    "CoverLetterGenerator",
    "CoverLetterGenerationResult",
    "generate_cover_letter",
    "generate_cover_letter_pdf",
    "CoverLetterContent",
    "render_cover_letter_latex",
]
