# API contract

All authenticated routes use:

```http
Authorization: Bearer <opaque-session-token>
```

## Authentication

- `POST /v1/auth/login` with
  `{"username": "...", "password": "...", "enrollment_year": 2021, "institution": "guc"}`
- `GET /v1/auth/session`
- `POST /v1/auth/logout`

`institution` accepts `guc` or `giu` and defaults to `giu` for older clients.
Login requires a valid portal session for that institution and attempts its CMS
with the same credentials. Successful login/session responses include
`institution` and `cms_connected`; when CMS is unavailable, `cms_message`
explains the limitation while the remaining portal and advisory features work.

## Academic data

- `GET /v1/academic/context`
- `POST /v1/academic/advisory-semester` with
  `{"current_season": "Winter 2024"}`
- `GET /v1/academic/seasons`
- `GET /v1/academic/courses?season=Winter%202024`
- `GET /v1/academic/course-grades?course=ICS501`
- `GET /v1/academic/transcript-years`
- `GET /v1/academic/transcript?year=2024-2025`
- `GET /v1/academic/transcript-window` (the four academic years beginning
  with the login enrollment year)
- `POST /v1/academic/cache/clear`

## Advisor

- `POST /v1/chat`
- `POST /v1/chat/reset`

Chat responses include the answer, completed tool names, and human-readable
source labels so the mobile interface can distinguish portal facts from advice.

## Career opportunities

- `GET /v1/career/opportunities/status`
- `POST /v1/career/opportunities/search` with:

```json
{
  "role_type": "newgrad",
  "timeframe": "lastweek",
  "target_market": "europe",
  "locations": ["Berlin", "Remote"],
  "keywords": ["backend", "python"],
  "work_modes": ["remote", "hybrid"],
  "limit": 24
}
```

The endpoint reads live Swelist metadata, ranks openings against the student's
four-year transcript and imported LinkedIn PDF when available, and returns
explainable match signals. Skill gaps are explicitly marked as role-family
inferences because Swelist does not provide complete job descriptions. Course
recommendations come from the structured catalogue derived from
`docs/Courses resources.txt`. GitHub, resume, and Adzuna are reported as
unconnected until their integrations are implemented.

## CMS learning content

- `GET /v1/cms/courses?refresh=false&season=Winter%202024` (defaults to the
  active advisory semester)
- `GET /v1/cms/courses/{opaque_course_id}/content`
- `GET /v1/cms/search?query=trees&course_id={opaque_course_id}`
- `GET /v1/cms/resources/{opaque_resource_id}/download`
- `GET /v1/cms/items/{drive_file_id}/transcript`

Courses and `cms_resources` are read live from the authenticated GUC or GIU CMS.
`available_videos` is a GIU-only prototype supplement populated when a live
course matches one of the five approved Drive collections. Video transcripts
return `pending` until a matching
`backend/content/transcripts/{drive_file_id}.md` file is added.

The advisor also exposes `read_cms_pdf(resource_id)`, which extracts bounded
text from an authenticated PDF before the model summarizes or explains it.

Completed Markdown intake files can be imported with:

```powershell
cd backend
uv run python scripts/import_transcript_intake.py `
  content/transcript_intake_template.md
```
