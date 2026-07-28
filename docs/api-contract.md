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
  "timeframe": "all",
  "target_market": "europe",
  "locations": ["Berlin", "Remote"],
  "keywords": ["backend", "python"],
  "work_modes": ["remote", "hybrid"],
  "limit": 24
}
```

The endpoint reads live Swelist metadata, ranks openings against the student's
four-year transcript, imported LinkedIn PDF, and connected GitHub project
snapshot when available, and returns explainable match signals. Skill gaps are
explicitly marked as role-family
inferences because Swelist does not provide complete job descriptions. Course
recommendations come from the structured catalogue derived from
`docs/Courses resources.txt`. Imported resume evidence participates in ranking
when connected. Adzuna remains reported as unconnected.

## GitHub career evidence

- `GET /v1/career/github-profile`
- `POST /v1/career/github/connect/start`
- `POST /v1/career/github/connect/poll`
- `POST /v1/career/github-profile/sync`
- `POST /v1/career/github-profile/refresh`
- `POST /v1/career/github-profile/remove`

The start endpoint returns a GitHub device `user_code` and verification URI.
The backend keeps the device code and eventual OAuth token inside the
short-lived student session. Flutter persists only the extracted public profile
snapshot and can sync that snapshot into a new university session.

## Resume career evidence

- `GET /v1/career/resume`
- `POST /v1/career/resume/import` with multipart PDF field `file`
- `POST /v1/career/resume/sync`
- `POST /v1/career/resume/remove`

Import accepts a text-based PDF up to 10 MB and returns a structured profile
containing identity, contact, summary, skill, experience, education, and
certification evidence. Flutter keeps the original PDF and extracted snapshot
in private app storage, then syncs the snapshot into each short-lived backend
session before relevant agent and opportunity tasks.

## Tone of voice

- `GET /v1/career/tone/questions` - returns the fixed list of onboarding
  prompts (`app.tone.ONBOARDING_QUESTIONS`) as a bare JSON array of strings,
  not an object.
- `GET /v1/career/tone` - `ToneStatus{connected, answers}`
- `POST /v1/career/tone/sync` with `{"answers": {"<question>": "<answer>"}}`
  - a partial set of answers is accepted and still improves generation
- `POST /v1/career/tone/remove`

The four onboarding questions elicit short, real writing samples (a
self-introduction, a project story, a reflection on a setback, an email
sign-off) rather than a self-reported formality label - deliberately, since
self-rated tone is unreliable and the raw samples are what the agent actually
imitates. Answers live only in the short-lived `StudentSession` (there is no
database in this project), so Flutter caches them on-device and re-syncs
after each login, exactly like the LinkedIn/GitHub/resume connectors above.
Saving a new tone profile clears the cached agent, career documents, and
conversation for the session so the next chat call and the next CV, cover
letter, or email all pick up the fresh reference. Once set, the tone
reference shapes CV generation, cover letters, drafted emails, and - via the
main agent's `ToneMiddleware` - the agent's own free-form chat replies.

## Reviewed Gmail applications

- `GET /v1/integrations/gmail/status`
- `POST /v1/integrations/gmail/connect`
- `GET /v1/integrations/gmail/callback`
- `POST /v1/integrations/gmail/disconnect`
- `POST /v1/career/applications/preview`
- `POST /v1/career/applications/send` as multipart form data with
  `application_id`, `subject`, `body`, and PDF field `cv`

The preview accepts `linkedin_post_url` and optional `post_text`. The resulting
draft is temporary and does not send anything. The send route requires the
reviewed draft ID, the candidate's connected Gmail, and a valid PDF up to
10 MB. It ignores all client/post recipient values and uses the
server-configured prototype recipient. A reviewed draft is deleted only after
Gmail returns a message ID and cannot be reused.

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
