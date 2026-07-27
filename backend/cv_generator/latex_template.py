"""Deterministic, pure rendering of `CVContent` into a compilable `.tex` file.

No network, no LLM calls, no templating engine dependency — just string
building, so this is fully unit-testable and the one place in the CV
pipeline you can trust never to produce broken LaTeX from good input. The
template intentionally only uses core packages (geometry, enumitem,
titlesec, hyperref) that any LaTeX engine — including a from-scratch
`tectonic` fetch — resolves without custom fonts or extra scheme installs.
"""

from __future__ import annotations

from .models import (
    ContactInfo,
    CVContent,
    EducationEntry,
    ExperienceEntry,
    ProjectEntry,
    SkillGroup,
)

_LATEX_SPECIAL_CHARS = {
    "&": r"\&",
    "%": r"\%",
    "$": r"\$",
    "#": r"\#",
    "_": r"\_",
    "{": r"\{",
    "}": r"\}",
    "~": r"\textasciitilde{}",
    "^": r"\textasciicircum{}",
    "\\": r"\textbackslash{}",
}

_PREAMBLE = r"""\documentclass[11pt]{article}
\usepackage[margin=0.75in]{geometry}
\usepackage{enumitem}
\usepackage{titlesec}
\usepackage{hyperref}
\hypersetup{colorlinks=true, urlcolor=blue}
\pagestyle{empty}
\setlist[itemize]{leftmargin=*, itemsep=1pt, topsep=2pt}
\titleformat{\section}{\large\bfseries}{}{0em}{}[\titlerule]
\titlespacing{\section}{0pt}{10pt}{4pt}
"""


def escape_latex(text: str | None) -> str:
    """Escape LaTeX's special characters, one pass, character by character.

    Character-by-character (rather than sequential `str.replace` calls) is
    what makes this correct: a sequential approach would re-match the
    backslashes it just inserted for an earlier character (e.g. escaping `#`
    to `\\#` and then the `\\` from THAT getting escaped again by a later
    backslash rule). Walking the string once and looking each character up
    means an inserted replacement is never rescanned.
    """
    if not text:
        return ""
    return "".join(_LATEX_SPECIAL_CHARS.get(char, char) for char in text)


def _escape_url(url: str) -> str:
    """Minimal escaping for a `\\href`/`\\url` target, not body text.

    `%`/`#`/`&` are the characters that actually break LaTeX's parsing of a
    URL argument; a full `escape_latex` pass would also mangle legitimate
    URL characters like `_`, so this is deliberately narrower.
    """
    return url.replace("%", r"\%").replace("#", r"\#").replace("&", r"\&")


def _contact_line(contact: ContactInfo) -> str:
    parts: list[str] = []
    if contact.email:
        parts.append(escape_latex(contact.email))
    if contact.phone:
        parts.append(escape_latex(contact.phone))
    if contact.location:
        parts.append(escape_latex(contact.location))
    if contact.linkedin_url:
        parts.append(rf"\href{{{_escape_url(contact.linkedin_url)}}}{{LinkedIn}}")
    if contact.github_url:
        parts.append(rf"\href{{{_escape_url(contact.github_url)}}}{{GitHub}}")
    if contact.website_url:
        parts.append(rf"\href{{{_escape_url(contact.website_url)}}}{{Website}}")
    return r" $\vert$ ".join(parts)


def _skills_section(groups: list[SkillGroup]) -> str:
    lines = [group for group in groups if group.skills]
    if not lines:
        return ""
    out = [r"\section*{Skills}"]
    for group in lines:
        category = escape_latex(group.category.title())
        skills = ", ".join(escape_latex(skill) for skill in group.skills)
        out.append(rf"\textbf{{{category}:}} {skills} \\")
    return "\n".join(out) + "\n"


def _bulleted(bullets: list[str]) -> list[str]:
    if not bullets:
        return []
    return [
        r"\begin{itemize}",
        *(rf"\item {escape_latex(bullet)}" for bullet in bullets),
        r"\end{itemize}",
    ]


def _experience_section(entries: list[ExperienceEntry]) -> str:
    if not entries:
        return ""
    out = [r"\section*{Experience}"]
    for entry in entries:
        title = escape_latex(entry.title)
        org = escape_latex(entry.organization)
        dates = escape_latex(entry.dates)
        out.append(rf"\textbf{{{title}}}, {org} \hfill {dates}\\")
        out.extend(_bulleted(entry.bullets))
    return "\n".join(out) + "\n"


def _projects_section(entries: list[ProjectEntry]) -> str:
    if not entries:
        return ""
    out = [r"\section*{Projects}"]
    for entry in entries:
        header = rf"\textbf{{{escape_latex(entry.name)}}}"
        if entry.technologies:
            tech = ", ".join(escape_latex(t) for t in entry.technologies)
            header += f" ({tech})"
        if entry.dates:
            header += rf" \hfill {escape_latex(entry.dates)}"
        out.append(header + r"\\")
        out.extend(_bulleted(entry.bullets))
    return "\n".join(out) + "\n"


def _education_section(entries: list[EducationEntry]) -> str:
    if not entries:
        return ""
    out = [r"\section*{Education}"]
    for entry in entries:
        institution = escape_latex(entry.institution)
        degree = escape_latex(entry.degree)
        dates = escape_latex(entry.dates)
        out.append(rf"\textbf{{{institution}}}, {degree} \hfill {dates}\\")
        if entry.gpa_or_honors:
            out.append(escape_latex(entry.gpa_or_honors) + r"\\")
        out.extend(_bulleted(entry.highlights))
    return "\n".join(out) + "\n"


def _certifications_section(items: list[str]) -> str:
    if not items:
        return ""
    out = [r"\section*{Certifications}", *_bulleted(items)]
    return "\n".join(out) + "\n"


def render_latex(content: CVContent) -> str:
    """Fill the fixed one-page template from validated `CVContent`.

    Every piece of `content` passes through `escape_latex`/`_escape_url`
    before reaching the template — this function is the only place user- or
    LLM-supplied text touches the `.tex` source, so it's the only place that
    needs to guard a broken compile.
    """
    header_lines = [rf"{{\Huge {escape_latex(content.full_name)}}}\\[4pt]"]
    if content.headline:
        header_lines.append(rf"{escape_latex(content.headline)}\\[2pt]")
    contact_line = _contact_line(content.contact)
    if contact_line:
        header_lines.append(contact_line)
    header = "\\begin{center}\n" + "\n".join(header_lines) + "\n\\end{center}\n"

    summary = ""
    if content.summary:
        summary = r"\section*{Summary}" + "\n" + escape_latex(content.summary) + "\n"

    body = "".join(
        [
            summary,
            _skills_section(content.skills),
            _experience_section(content.experience),
            _projects_section(content.projects),
            _education_section(content.education),
            _certifications_section(content.certifications),
        ]
    )

    return f"{_PREAMBLE}\n\\begin{{document}}\n{header}\n{body}\n\\end{{document}}\n"
