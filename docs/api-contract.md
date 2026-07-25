# API contract

All authenticated routes use:

```http
Authorization: Bearer <opaque-session-token>
```

## Authentication

- `POST /v1/auth/login` with
  `{"username": "...", "password": "...", "enrollment_year": 2021}`
- `GET /v1/auth/session`
- `POST /v1/auth/logout`

Login validates the GIU portal and GIU CMS as one atomic university sign-in.
Successful login/session responses include `cms_connected: true`.

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

## CMS learning content

- `GET /v1/cms/courses?refresh=false&season=Winter%202024` (defaults to the
  active advisory semester)
- `GET /v1/cms/courses/{opaque_course_id}/content`
- `GET /v1/cms/search?query=trees&course_id={opaque_course_id}`
- `GET /v1/cms/resources/{opaque_resource_id}/download`
- `GET /v1/cms/items/{drive_file_id}/transcript`

Courses and `cms_resources` are read live from the authenticated GIU CMS.
`available_videos` is populated only when a live course matches one of the five
approved Drive collections. Video transcripts return `pending` until a matching
`backend/content/transcripts/{drive_file_id}.md` file is added.

The advisor also exposes `read_cms_pdf(resource_id)`, which extracts bounded
text from an authenticated PDF before the model summarizes or explains it.

Completed Markdown intake files can be imported with:

```powershell
cd backend
uv run python scripts/import_transcript_intake.py `
  content/transcript_intake_template.md
```
