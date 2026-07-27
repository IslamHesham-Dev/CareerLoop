"""Generate personalized cover letters using career data, job postings, and user input."""

from __future__ import annotations

from langchain_anthropic import ChatAnthropic


class CoverLetterGenerator:
    """Generates personalized cover letters based on career evidence and job requirements."""

    def __init__(self, anthropic_api_key: str, model: str = "claude-3-5-sonnet-20241022") -> None:
        self.model = ChatAnthropic(
            model=model,
            temperature=0.7,
            api_key=anthropic_api_key,
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
        prompt = self._build_prompt(career_data, job_posting, custom_input)
        response = self.model.invoke(prompt)
        return response.content

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
