"""cv_generator: turn merged career evidence into a compilable LaTeX CV.

    from app.career_context import build_career_context
    from cv_generator import CVGenerator

    context = build_career_context(
        resume_profile=student.resume_profile,
        linkedin_profile=student.linkedin_profile,
        github_profile=student.github_profile,
        transcript=academic.full_transcript(),
    )
    result = CVGenerator(
        anthropic_api_key=api_key, model=settings.anthropic_model
    ).generate(career_context=context, target_position="Backend Engineering Intern")

    result.latex_source   # always present; paste into Overleaf if pdf_bytes is None
    result.pdf_bytes      # present only when a LaTeX engine (tectonic/pdflatex) was found

Three independently testable stages (evidence merging lives one level up, in
app/career_context.py, since email_generator needs the exact same merge):
    content.generate_cv_content      -> one LLM call -> validated CVContent
    latex_template.render_latex      -> CVContent -> .tex source (pure)
    compile.compile_latex_to_pdf     -> .tex source -> PDF bytes or None (best-effort)
"""

from .client import CVGenerationResult, CVGenerator
from .compile import compile_latex_to_pdf
from .content import generate_cv_content
from .latex_template import escape_latex, render_latex
from .models import CVContent

__all__ = [
    "CVGenerator",
    "CVGenerationResult",
    "CVContent",
    "generate_cv_content",
    "render_latex",
    "escape_latex",
    "compile_latex_to_pdf",
]
