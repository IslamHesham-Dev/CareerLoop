from pathlib import Path

from app.career_context import build_career_context
from cv_generator.compile import _command_for, _find_engine, compile_latex_to_pdf
from cv_generator.latex_template import escape_latex, render_latex
from cv_generator.models import (
    CVContent,
    ContactInfo,
    EducationEntry,
    ExperienceEntry,
    ProjectEntry,
    SkillGroup,
)


# -- aggregate.build_career_context ------------------------------------------


def test_build_career_context_is_empty_but_valid_with_no_sources() -> None:
    context = build_career_context()

    assert context == {"sources_used": []}


def test_build_career_context_tracks_only_the_sources_actually_present() -> None:
    context = build_career_context(github_profile={"login": "ada", "skills": []})

    assert context["sources_used"] == ["github"]
    assert "resume" not in context
    assert "linkedin" not in context
    assert context["github"]["login"] == "ada"


def test_build_career_context_merges_every_source_when_all_are_present() -> None:
    context = build_career_context(
        resume_profile={"name": "Ada", "skills": ["Python"]},
        linkedin_profile={"name": "Ada Lovelace", "headline": "Engineer"},
        github_profile={"login": "ada", "languages": {"Python": 100}},
        transcript={
            "cumulative_gpa": "1.2",
            "loaded_years": ["2023-2024"],
            "courses": [
                {"course": "Algorithms", "grade": "A"},
                {"course": "Databases", "grade": "B+"},
            ],
        },
        cms_course_titles=["Algorithms", "Databases"],
    )

    assert context["sources_used"] == [
        "resume",
        "linkedin",
        "github",
        "academic_transcript",
        "cms_courses",
    ]
    assert context["academic"]["strong_courses"] == ["Algorithms"]
    assert context["academic"]["course_count"] == 2
    assert context["cms_course_titles"] == ["Algorithms", "Databases"]


def test_build_career_context_strong_courses_are_deduped_and_capped() -> None:
    courses = [{"course": f"Course {i}", "grade": "A"} for i in range(12)]
    courses.append({"course": "Course 0", "grade": "A"})  # duplicate, must not repeat
    courses.append({"course": "Weak Course", "grade": "C"})  # below the A-range cutoff

    context = build_career_context(transcript={"courses": courses})

    strong = context["academic"]["strong_courses"]
    assert len(strong) == 8  # capped at top_n
    assert len(strong) == len(set(strong))  # no duplicates
    assert "Weak Course" not in strong


# -- latex_template.escape_latex ---------------------------------------------


def test_escape_latex_handles_every_special_character_in_one_pass() -> None:
    result = escape_latex("50% & up_down #1 {a} ~b ^c \\d $5")

    assert result == (
        r"50\% \& up\_down \#1 \{a\} \textasciitilde{}b "
        r"\textasciicircum{}c \textbackslash{}d \$5"
    )


def test_escape_latex_does_not_cascade_new_backslashes() -> None:
    # A naive sequential str.replace() implementation would re-match the
    # backslash this itself inserts; a correct one-pass implementation must not.
    result = escape_latex("#")

    assert result == r"\#"
    assert result.count("\\") == 1


def test_escape_latex_is_empty_for_empty_or_none_input() -> None:
    assert escape_latex("") == ""
    assert escape_latex(None) == ""


# -- latex_template.render_latex ---------------------------------------------


def test_render_latex_escapes_special_characters_in_every_field() -> None:
    content = CVContent(
        full_name="A&E Corp Fan",
        summary="Improved throughput by 50% & cut costs.",
        contact=ContactInfo(email="a_b@example.com"),
        skills=[SkillGroup(category="language", skills=["C#"])],
    )

    tex = render_latex(content)

    assert r"A\&E Corp Fan" in tex
    assert r"50\% \& cut costs" in tex
    assert r"a\_b@example.com" in tex
    assert r"C\#" in tex


def test_render_latex_omits_sections_with_no_evidence() -> None:
    content = CVContent(full_name="Ada Lovelace", summary="Engineer.")

    tex = render_latex(content)

    assert r"\section*{Skills}" not in tex
    assert r"\section*{Experience}" not in tex
    assert r"\section*{Projects}" not in tex
    assert r"\section*{Education}" not in tex
    assert r"\section*{Certifications}" not in tex
    assert r"\begin{document}" in tex
    assert r"\end{document}" in tex


def test_render_latex_includes_populated_sections_with_bullets() -> None:
    content = CVContent(
        full_name="Ada Lovelace",
        summary="Engineer.",
        experience=[
            ExperienceEntry(
                title="Intern",
                organization="Analytical Engines Ltd",
                dates="Summer 2025",
                bullets=["Shipped a scraper.", "Cut latency 30%."],
            )
        ],
        projects=[ProjectEntry(name="Notes on Engines", technologies=["Python"])],
        education=[
            EducationEntry(institution="GIU", degree="BSc CS", dates="2022-2026")
        ],
        certifications=["AWS Certified"],
    )

    tex = render_latex(content)

    assert r"\section*{Experience}" in tex
    assert "Analytical Engines Ltd" in tex
    assert r"Cut latency 30\%." in tex
    assert r"\section*{Projects}" in tex
    assert r"\section*{Education}" in tex
    assert r"\section*{Certifications}" in tex
    assert "AWS Certified" in tex


# -- compile.compile_latex_to_pdf --------------------------------------------


def test_find_engine_prefers_tectonic_over_pdflatex(monkeypatch) -> None:
    monkeypatch.setattr(
        "cv_generator.compile.shutil.which",
        lambda name: f"/usr/bin/{name}" if name in ("tectonic", "pdflatex") else None,
    )

    assert _find_engine() == "tectonic"


def test_find_engine_is_none_when_nothing_is_installed(monkeypatch) -> None:
    monkeypatch.setattr("cv_generator.compile.shutil.which", lambda name: None)

    assert _find_engine() is None


def test_compile_latex_to_pdf_degrades_to_none_without_an_engine(monkeypatch) -> None:
    monkeypatch.setattr("cv_generator.compile.shutil.which", lambda name: None)

    assert compile_latex_to_pdf(r"\documentclass{article}") is None


def test_command_for_tectonic_and_pdflatex_differ() -> None:
    tex_path = Path("/tmp/cv.tex")
    out_dir = Path("/tmp")

    tectonic_command = _command_for("tectonic", tex_path, out_dir)
    pdflatex_command = _command_for("pdflatex", tex_path, out_dir)

    assert tectonic_command[0] == "tectonic"
    assert pdflatex_command[0] == "pdflatex"
    assert str(tex_path) in tectonic_command
    assert str(tex_path) in pdflatex_command
