"""Generate grounded cover letters and compile the fixed LaTeX template."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from cv_generator.compile import compile_latex_to_pdf

from .content import generate_cover_letter_content
from .latex_template import render_cover_letter_latex
from .models import CoverLetterContent


@dataclass
class CoverLetterGenerationResult:
    content: CoverLetterContent
    latex_source: str
    pdf_bytes: bytes | None


class CoverLetterGenerator:
    """Generates personalized cover letters based on career evidence and job requirements."""

    def __init__(
        self,
        anthropic_api_key: str,
        model: str = "claude-haiku-4-5",
    ) -> None:
        self.anthropic_api_key = anthropic_api_key
        self.model = model

    def generate(
        self,
        *,
        career_context: dict[str, Any],
        job_posting: dict[str, Any],
        custom_input: str = "",
        tone_reference: str = "",
        compile_pdf: bool = True,
    ) -> CoverLetterGenerationResult:
        content = generate_cover_letter_content(
            career_context=career_context,
            job_posting=job_posting,
            api_key=self.anthropic_api_key,
            model=self.model,
            custom_input=custom_input,
            tone_reference=tone_reference,
        )
        latex_source = render_cover_letter_latex(content)
        pdf_bytes = compile_latex_to_pdf(latex_source) if compile_pdf else None
        return CoverLetterGenerationResult(
            content=content,
            latex_source=latex_source,
            pdf_bytes=pdf_bytes,
        )

    def generate_cover_letter(
        self,
        career_data: dict,
        job_posting: dict,
        custom_input: str = "",
    ) -> str:
        """Generate a personalized cover letter.
        
        Args:
            career_data: Extracted CV/profile with name, skills, experience, education, summary
            job_posting: Job posting with title, description, company, requirements
            custom_input: User-provided context, preferences, or specific details
            
        Returns:
            A formatted cover letter as a string
        """
        result = self.generate(
            career_context={
                "resume": career_data,
                "sources_used": ["resume"],
            },
            job_posting=job_posting,
            custom_input=custom_input,
            compile_pdf=False,
        )
        return "\n\n".join(
            [
                result.content.greeting,
                *result.content.paragraphs,
                result.content.signoff,
                result.content.candidate_name,
            ]
        )

    def _build_prompt(self, career_data: dict, job_posting: dict, custom_input: str) -> str:
        """Build the prompt for Claude to generate the cover letter."""
        career_section = self._format_career_data(career_data)
        job_section = self._format_job_posting(job_posting)
        
        prompt = f"""You are an expert cover letter writer. Generate a personalized, compelling cover letter based on the following information.

## Candidate Information
{career_section}

## Job Posting
{job_section}

## Additional Context from Candidate
{custom_input if custom_input else "(No additional input provided)"}

## Instructions
- Write a professional, one-page cover letter (3-4 paragraphs)
- Start with "Dear Hiring Manager," (or address a specific name if provided in the job posting)
- Highlight specific skills and experiences that match the job requirements
- Show genuine enthusiasm for the role and company
- Use concrete examples from the candidate's experience
- End with a call to action requesting an interview
- Keep tone professional yet personable
- Do not include the candidate's contact information in the letter itself

Generate only the cover letter text, without any additional commentary or metadata."""
        
        return prompt

    def _format_career_data(self, data: dict) -> str:
        """Format career data for the prompt."""
        lines = []
        if data.get("name"):
            lines.append(f"Name: {data['name']}")
        if data.get("headline"):
            lines.append(f"Professional Title: {data['headline']}")
        if data.get("email"):
            lines.append(f"Email: {data['email']}")
        if data.get("phone"):
            lines.append(f"Phone: {data['phone']}")
        if data.get("summary"):
            lines.append(f"Summary: {data['summary']}")
        if data.get("skills"):
            skills_list = data['skills'] if isinstance(data['skills'], list) else [data['skills']]
            lines.append(f"Skills: {', '.join(str(s) for s in skills_list[:15])}")
        if data.get("experience"):
            exp_list = data['experience'] if isinstance(data['experience'], list) else [data['experience']]
            lines.append(f"Experience:\n" + "\n".join(f"  - {exp}" for exp in exp_list[:5]))
        if data.get("education"):
            edu_list = data['education'] if isinstance(data['education'], list) else [data['education']]
            lines.append(f"Education:\n" + "\n".join(f"  - {edu}" for edu in edu_list[:3]))
        if data.get("certifications"):
            cert_list = data['certifications'] if isinstance(data['certifications'], list) else [data['certifications']]
            lines.append(f"Certifications: {', '.join(str(c) for c in cert_list[:5])}")
        return "\n".join(lines)

    def _format_job_posting(self, posting: dict) -> str:
        """Format job posting data for the prompt."""
        lines = []
        if posting.get("company"):
            lines.append(f"Company: {posting['company']}")
        if posting.get("title"):
            lines.append(f"Position: {posting['title']}")
        if posting.get("description"):
            lines.append(f"Description: {posting['description']}")
        if posting.get("requirements"):
            lines.append(f"Requirements: {posting['requirements']}")
        if posting.get("location"):
            lines.append(f"Location: {posting['location']}")
        if posting.get("link"):
            lines.append(f"Posting Link: {posting['link']}")
        return "\n".join(lines)

    def generate_cover_letter_pdf(
        self,
        career_data: dict,
        job_posting: dict,
        custom_input: str = "",
        filename: str | None = None,
    ) -> bytes:
        """Generate a cover letter as a PDF file.
        
        Args:
            career_data: Extracted CV/profile with name, skills, experience, education, summary
            job_posting: Job posting with title, description, company, requirements
            custom_input: User-provided context, preferences, or specific details
            filename: Optional filename for the PDF (used in metadata)
            
        Returns:
            PDF file as bytes
        """
        result = self.generate(
            career_context={
                "resume": career_data,
                "sources_used": ["resume"],
            },
            job_posting=job_posting,
            custom_input=custom_input,
        )
        if result.pdf_bytes is None:
            raise RuntimeError(
                "No LaTeX engine is available to compile the cover letter."
            )
        return result.pdf_bytes


def generate_cover_letter(
    career_data: dict,
    job_posting: dict,
    custom_input: str = "",
    anthropic_api_key: str = "",
) -> str:
    """Standalone function to generate a cover letter.
    
    Args:
        career_data: Extracted CV/profile data
        job_posting: Job posting information
        custom_input: User-provided context or preferences
        anthropic_api_key: Anthropic API key
        
    Returns:
        Generated cover letter text
    """
    if not anthropic_api_key:
        raise ValueError("ANTHROPIC_API_KEY is required")
    generator = CoverLetterGenerator(anthropic_api_key=anthropic_api_key)
    return generator.generate_cover_letter(career_data, job_posting, custom_input)


def generate_cover_letter_pdf(
    career_data: dict,
    job_posting: dict,
    custom_input: str = "",
    anthropic_api_key: str = "",
    filename: str | None = None,
) -> bytes:
    """Standalone function to generate a cover letter PDF.
    
    Args:
        career_data: Extracted CV/profile with name, skills, experience, education, summary
        job_posting: Job posting with title, description, company, requirements
        custom_input: User-provided context, preferences, or specific details
        anthropic_api_key: Anthropic API key
        filename: Optional filename for PDF metadata
        
    Returns:
        PDF file as bytes
    """
    if not anthropic_api_key:
        raise ValueError("ANTHROPIC_API_KEY is required")
    generator = CoverLetterGenerator(anthropic_api_key=anthropic_api_key)
    return generator.generate_cover_letter_pdf(career_data, job_posting, custom_input, filename)
