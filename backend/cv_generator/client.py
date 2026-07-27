"""CVGenerator: the single entry point an agent tool calls.

    from cv_generator import CVGenerator

    generator = CVGenerator(anthropic_api_key=api_key, model=settings.anthropic_model)
    result = generator.generate(
        career_context=career_context,
        target_position="Backend Engineering Intern",
        tone_reference=tone_reference,
    )
    result.latex_source   # always present
    result.pdf_bytes      # None if no LaTeX engine was available to compile it
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .compile import compile_latex_to_pdf
from .content import generate_cv_content
from .latex_template import render_latex
from .models import CVContent


@dataclass
class CVGenerationResult:
    content: CVContent
    latex_source: str
    pdf_bytes: bytes | None


class CVGenerator:
    """Ties the three-stage pipeline together: content -> LaTeX -> (maybe) PDF."""

    def __init__(self, *, anthropic_api_key: str, model: str) -> None:
        self.anthropic_api_key = anthropic_api_key
        self.model = model

    def generate(
        self,
        *,
        career_context: dict[str, Any],
        target_position: str = "",
        target_company: str = "",
        custom_input: str = "",
        tone_reference: str = "",
        compile_pdf: bool = True,
    ) -> CVGenerationResult:
        content = generate_cv_content(
            career_context=career_context,
            api_key=self.anthropic_api_key,
            model=self.model,
            target_position=target_position,
            target_company=target_company,
            custom_input=custom_input,
            tone_reference=tone_reference,
        )
        latex_source = render_latex(content)
        pdf_bytes = compile_latex_to_pdf(latex_source) if compile_pdf else None
        return CVGenerationResult(
            content=content, latex_source=latex_source, pdf_bytes=pdf_bytes
        )
