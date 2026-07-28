"""Deterministically fill the supplied entry-level cover-letter design."""

from __future__ import annotations

from datetime import date

from cv_generator.latex_template import _escape_url, escape_latex

from .models import CoverLetterContent


def _link(url: str | None, label: str) -> str:
    if not url:
        return ""
    return rf"\textbf{{\href{{{_escape_url(url)}}}{{{label}}}}}"


def render_cover_letter_latex(content: CoverLetterContent) -> str:
    contact = content.contact
    left_lines = [
        escape_latex(value)
        for value in (contact.phone, contact.email)
        if value
    ]
    right_lines = [
        link
        for link in (
            _link(contact.linkedin_url, "LinkedIn"),
            _link(contact.github_url, "GitHub"),
        )
        if link
    ]
    paragraphs = "\n\n".join(escape_latex(item) for item in content.paragraphs)
    signature_lines = [
        escape_latex(content.signoff),
        escape_latex(content.candidate_name),
    ]
    if contact.phone:
        signature_lines.append(escape_latex(contact.phone))
    if contact.email:
        signature_lines.append(
            rf"\href{{mailto:{_escape_url(contact.email)}}}"
            rf"{{{escape_latex(contact.email)}}}"
        )
    left_block = " \\\\\n".join(left_lines)
    right_block = " \\\\\n".join(right_lines)
    signature_block = " \\\\\n".join(signature_lines)

    return rf"""\documentclass[11pt,a4paper]{{article}}
\usepackage[margin=1cm]{{geometry}}
\usepackage[usenames,dvipsnames]{{color}}
\usepackage[hidelinks]{{hyperref}}
\usepackage{{fancyhdr}}
\usepackage{{tabularx}}
\usepackage{{ragged2e}}
\usepackage[T1]{{fontenc}}
\usepackage[utf8]{{inputenc}}
\usepackage[scaled=0.96]{{helvet}}
\renewcommand{{\familydefault}}{{\sfdefault}}
\definecolor{{UIBlue}}{{RGB}}{{32,64,151}}
\definecolor{{FooterGray}}{{RGB}}{{130,130,130}}
\pagestyle{{fancy}}
\fancyhf{{}}
\fancyfoot[R]{{\color{{FooterGray}}\small 1 of 1, Updated \today}}
\renewcommand{{\headrulewidth}}{{0pt}}
\renewcommand{{\footrulewidth}}{{0pt}}
\setlength{{\footskip}}{{15pt}}
\setlength{{\parindent}}{{0pt}}
\setlength{{\parskip}}{{11pt}}
\urlstyle{{same}}
\begin{{document}}
\begin{{center}}
\begin{{minipage}}[b]{{0.24\textwidth}}
\large {left_block}
\end{{minipage}}%
\begin{{minipage}}[b]{{0.50\textwidth}}
\centering
{{\Huge {escape_latex(content.candidate_name)}}}\\
\vspace{{0.1cm}}
{{\color{{UIBlue}}\Large {escape_latex(content.professional_title)}}}
\end{{minipage}}%
\begin{{minipage}}[b]{{0.24\textwidth}}
\flushright\large {right_block}
\end{{minipage}}\par
\vspace{{-0.1cm}}
{{\color{{UIBlue}}\hrulefill}}\par
\end{{center}}
\justify
\vspace{{0.15cm}}
\begin{{center}}{{\color{{UIBlue}}\Large COVER LETTER}}\end{{center}}
Date: {escape_latex(date.today().strftime("%B %d, %Y"))}\\
To: {escape_latex(content.recipient)}\\
Subject: {escape_latex(content.subject)}

{escape_latex(content.greeting)}

{paragraphs}

\vspace{{0.35cm}}
\raggedright
{signature_block}
\end{{document}}
"""
