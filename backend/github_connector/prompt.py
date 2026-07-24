"""Reusable prompt text for the (future) CV-generation agent.

`_skills.extract_skills` gives deterministic, evidence-backed skill claims:
languages weighted by cumulative bytes written, frameworks/tools weighted by
how many distinct repos use them. That mechanical step is what makes the
result trustworthy CV content — it never invents a skill from a repo's name
alone. What it *can't* do is judge nuance: whether a project is a serious
build or a tutorial follow-along, what a README implies about scale, how to
prioritize skills for a specific target role. That judgment belongs to the
agent that writes the CV, and this module is its instructions for it.

Kept separate from client.py/_skills.py on purpose: a CV agent can import
this prompt text without importing any networking code, and this file can be
extended (tone, target-role weighting, etc.) without touching the connector.
"""

from __future__ import annotations

SKILL_EXTRACTION_GUIDANCE = """
When describing a student's technical skills from their GitHub data, do not
summarize repos by name and description alone — that reads like a file
listing, not a skills profile. Instead:

1. Treat `extract_skills` output as the ONLY source of which skills to claim.
   Never state a skill that has no evidence_repos backing it, even if a bio,
   topic tag, or README mentions it in passing — an unverifiable claim
   undermines every other, verified claim on the same CV.
2. Use evidence_repos and weight to judge DEPTH, not just presence:
   - A language with high byte-weight across multiple repos is a core skill.
     A language that appears once with a small weight is exposure, not
     proficiency, and should be phrased that way if it is included at all
     ("also worked in ..." rather than a bare bullet next to core skills).
   - A framework/tool with evidence in 3+ repos supports a strong claim
     ("built REST APIs with FastAPI across several projects"); one repo
     supports only a modest one ("used FastAPI in a course project").
3. Read the README excerpts to describe WHAT was built, not just which
   language or framework was used. "Built a FastAPI backend for a real-time
   chat app with WebSocket support" is CV-worthy; "used FastAPI" is not. Pull
   the concrete nouns — what the project does, for whom, at what scale —
   from the README text, never from the repo name alone.
4. Prefer recent, active, non-fork repos as primary evidence (see
   Repository.pushed_at / is_fork / is_archived). Older or archived work may
   support a skill that recent repos don't already evidence, but say so
   ("earlier work in ...") instead of presenting it as current.
5. Group the final list by category (language, frontend framework, backend
   framework, data/ml, database, devops, mobile, ...) rather than a flat
   ranked dump — a reader scans a CV skills section by category, not by
   internal weight.
6. When a target position is known, reorder and select for relevance to it
   first and completeness second: a backend-role CV should lead with
   backend-framework/database/devops evidence even if the student's
   highest-weight language happens to be frontend JavaScript. Do not drop
   well-evidenced skills just because they're off-target — deprioritize,
   don't delete.
7. Never infer a skill from a project's name or topic tags alone if
   `extract_skills` did not surface it. Topics are self-reported and often
   stale or aspirational; manifests and language bytes are not.
"""
