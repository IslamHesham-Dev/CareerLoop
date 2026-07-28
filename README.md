# CareerLoop

**Academic insight. Career momentum.**

CareerLoop is a private academic and career advisory prototype. It currently
combines GUC or GIU portal records, a Flutter mobile experience, and a
FastAPI/LangChain backend. The university selected at login controls both the
portal and CMS connectors, and the same short-lived credentials open their
read-only sessions. Portal-only operation remains available when CMS access has
ended.

## Repository

```text
mobile/       Flutter app for Android and iOS
backend/      FastAPI API, agent, session isolation, and GUC/GIU clients
notebooks/    Verified portal experiments kept as references
docs/         Architecture, API, and security decisions
scripts/      Local development helpers
```

## 1. Backend configuration

Create `backend/.env` from `backend/.env.example` and set:

```env
LLM_PROVIDER=openrouter
OPENROUTER_API_KEY=your-server-side-openrouter-key
OPENROUTER_MODEL=google/gemma-4-31b-it:free
OPENROUTER_APP_URL=https://careerloop.onrender.com
OPENROUTER_APP_TITLE=CareerLoop
DEGREELENS_ENVIRONMENT=development
DEGREELENS_SESSION_TTL_MINUTES=45
DEGREELENS_CURRENT_SEASON=Winter 2024
DEGREELENS_ADVISORY_YEAR=2024-2025
```

The OpenRouter key belongs only in `backend/.env` locally and in the Render
web service environment when deployed. It must never be compiled into Flutter
or stored in GitHub Actions. To switch back later, set
`LLM_PROVIDER=anthropic`, `ANTHROPIC_API_KEY`, and `ANTHROPIC_MODEL`; the agent,
structured document generators, career email writer, and job extraction all
use the same provider selection.

Do not add GUC/GIU usernames or passwords to the backend environment. The login
screen sends credentials over HTTPS to establish a short-lived, isolated portal
session and, when the account permits it, a CMS session. Credential material is
retained only by the in-memory authentication objects and is destroyed at
logout or expiry.

Run locally:

```powershell
cd "D:\My Folder\UNI\Workshop\in_class_task\degreelens\backend"
uv sync
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

API documentation is available at `http://127.0.0.1:8000/docs` in development.

## 2. Flutter

```powershell
cd "D:\My Folder\UNI\Workshop\in_class_task\degreelens\mobile"
flutter pub get
flutter analyze
flutter test
```

Android emulator:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Physical Android phone on the same Wi-Fi:

```powershell
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<PC_LAN_IP>:8000
```

Development builds allow cleartext LAN HTTP. Release builds should always point
to a deployed HTTPS backend.

## Deployment

The backend is container-ready:

```powershell
docker build -t careerloop-api .\backend
docker run --rm -p 8000:8000 --env-file .\backend\.env careerloop-api
```

Use one backend worker while sessions are stored in memory. Before horizontal
scaling, replace `SessionStore` with an encrypted shared store and maintain
strict per-student cache separation.

## CMS and supplemental videos

The course list and official resources come from the authenticated CMS selected
at login and follow the advisory semester. PDFs open inside CareerLoop and can
be read by the advisor through a bounded authenticated extraction tool. For the
GIU prototype only, five approved Drive collections are matched to their
corresponding courses and shown under a separate **Available videos** section;
they are not treated as the complete CMS. Drive videos play in an in-app viewer.
Video substance is available to the advisor only after a transcript is added
under `backend/content/transcripts/`.

The canonical transcript intake format is Markdown:
`backend/content/transcript_intake_template.md`. Each video has immutable
START/END markers keyed by its Drive file ID. After transcript placeholders are
filled, the importer validates the mapping and splits the intake file into one
retrieval source per completed video:

```powershell
cd backend
uv run python scripts/import_transcript_intake.py `
  content/transcript_intake_template.md
```

## Opportunity matching

The Career Studio includes a live **Opportunity Match** workspace backed by
Swelist. Students can filter internships or new-graduate roles by market,
location, work mode, role family, and technology preferences.
CareerLoop ranks the returned listing metadata against the four-year
transcript, imported LinkedIn PDF, and connected GitHub project evidence,
shows the evidence behind each match, and labels role-family skill gaps as
inferences that must be confirmed on the employer page.

Recommended learning paths come from
`backend/content/career/course_catalog.json`, the deployable structured subset
of `docs/Courses resources.txt`. Imported resume evidence now participates in
matching when connected. Adzuna remains an upcoming connector rather than being
implied as live.

## GitHub project evidence

CareerLoop uses GitHub's OAuth device flow. Create a GitHub OAuth App, enable
**Device Flow**, and add its public client ID to the backend/Render environment:

```env
GITHUB_OAUTH_CLIENT_ID=your_oauth_app_client_id
```

The mobile app displays and copies GitHub's one-time code, opens
`github.com/login/device`, and polls the backend until authorization completes.
No client secret or OAuth token is placed in Flutter.

The current build intentionally requests only `read:user` and analyzes public,
non-fork, non-archived repositories. It extracts language byte counts, project
descriptions, topics, README excerpts, and technologies found in dependency
manifests. A maximum of 12 recent owned/collaborative repositories is analyzed
per refresh. The extracted snapshot is stored in the app's private support
directory and rehydrated into short-lived CareerLoop sessions. The agent calls
`get_github_project_profile` when technical project evidence is relevant.

## Resume evidence

**Career Studio → Resume evidence** accepts a text-based resume or CV PDF up to
10 MB. The backend extracts name, headline, contact details, summary, skills,
experience, education, and certifications into the current short-lived
CareerLoop session. The original PDF and its structured snapshot are stored in
the mobile app's private support directory; the backend does not persist the
original file.

The mobile app rehydrates the structured snapshot into every new university
session before chat, opportunity matching, or application drafting. The agent
uses `get_resume_profile` when relevant and can combine it with
`get_full_transcript`, `get_linkedin_pdf_profile`, and
`get_github_project_profile`. Resume text is treated as untrusted user data,
not as instructions, and source conflicts must be disclosed instead of merged
silently.

## LinkedIn post to reviewed Gmail application

**Career Studio → Post to Application** turns a public LinkedIn job-post link
into an editable application email. CareerLoop uses pasted post text first when
provided; otherwise it reads only public Open Graph metadata and asks for a
paste when LinkedIn does not expose the post. It does not log in to, scrape, or
claim private LinkedIn post access.

The current CV is selected once and stored in the mobile app's private support
directory. The backend combines the post with connected LinkedIn PDF and GitHub
evidence to prepare a bounded draft, then pauses. The candidate can edit the
subject and body and must tap **Approve & send application** before the PDF is
uploaded and Gmail is called.

For the prototype, the backend ignores any contact email found in a post and
enforces `islammheshamm7@gmail.com` as the recipient. Configure that lock and
Google OAuth on the Render backend service:

```env
GOOGLE_OAUTH_CLIENT_ID=your_google_web_client_id
GOOGLE_OAUTH_CLIENT_SECRET=your_google_web_client_secret
GOOGLE_OAUTH_REDIRECT_URI=https://careerloop.onrender.com/v1/integrations/gmail/callback
CAREERLOOP_PROTOTYPE_APPLICATION_RECIPIENT=islammheshamm7@gmail.com
```

In Google Cloud, enable the Gmail API, configure the OAuth consent screen, add
the Gmail accounts used for the demo as test users while the app is in testing,
and create a **Web application** OAuth client. Add the redirect URI above
exactly under **Authorized redirect URIs**. CareerLoop requests identity plus
the narrow `gmail.send` permission; it cannot read the inbox through this
connection. Keep the client secret only in `backend/.env` locally and Render
Environment in deployment—never in Flutter or GitHub Actions.

## Notion response export

Every Copilot answer, including answers from the floating content assistant,
can be exported as a structured Notion page. The AI response remains Markdown
throughout the pipeline, while Notion credentials stay on the backend.

For the quickest single-workspace demo, create an internal Notion integration,
share a regular parent page with that integration, and add these values to
`backend/.env`:

```env
NOTION_API_KEY=ntn_your_internal_integration_token
NOTION_PARENT_PAGE_ID=the_parent_page_id
NOTION_API_VERSION=2026-03-11
```

For a multi-user public connection, leave those two values empty and configure:

```env
NOTION_OAUTH_CLIENT_ID=your_public_connection_client_id
NOTION_OAUTH_CLIENT_SECRET=your_public_connection_client_secret
NOTION_OAUTH_REDIRECT_URI=https://careerloop.onrender.com/v1/integrations/notion/callback
NOTION_API_VERSION=2026-03-11
```

The public connection must allow inserting content and its exact redirect URI
must match the value configured in Notion. OAuth tokens currently live only for
the short CareerLoop session, just like the university portal session. Use encrypted
persistent user storage before supporting long-lived production accounts.

## LinkedIn PDF professional profile

CareerLoop does not log into or scrape LinkedIn. The user exports the
LinkedIn-generated profile PDF from the web profile page and imports it through
**Career Studio → LinkedIn profile**. The app provides a three-step guide for
finding **Save to PDF**.

The original PDF and its extracted metadata are stored in the mobile app's
private application-support directory. The backend reads the uploaded PDF only
to extract professional evidence into the current short-lived CareerLoop
session; it does not persist the original file. Supported evidence includes
name, headline, summary, contact details, experience, education, skills, and
certification names.

When a new backend session starts, the app rehydrates the extracted local
profile before the next Copilot message. The agent can then call
`get_linkedin_pdf_profile` for relevant CV, job-fit, cover-letter, career,
experience, education, skills, or certification questions. Replacing or
removing the PDF clears the previous Copilot context to prevent stale career
claims from being reused.
