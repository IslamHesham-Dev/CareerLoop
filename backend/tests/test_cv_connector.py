from __future__ import annotations

from cv_connector import extract_cv_profile_from_text


def test_extract_cv_profile_from_text_extracts_common_fields() -> None:
    text = """
    Jane Doe
    Senior Software Engineer
    jane@example.com | +1 555 123 4567
    Summary: Experienced engineer with Python and FastAPI expertise.
    Skills: Python, FastAPI, Docker, AWS
    Education: BSc Computer Science, 2021
    Experience: Built APIs for fintech products.
    Certifications: AWS Certified Developer
    """

    profile = extract_cv_profile_from_text(text, file_name="cv.pdf")

    assert profile.name == "Jane Doe"
    assert profile.email == "jane@example.com"
    assert profile.phone == "+1 555 123 4567"
    assert "Python" in profile.skills
    assert "FastAPI" in profile.skills
    assert profile.education
    assert profile.experience
