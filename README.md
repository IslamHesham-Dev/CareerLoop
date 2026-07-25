# CareerLoop

**Academic insight. Career momentum.**

CareerLoop is a private academic and career advisory prototype. It currently
combines GIU portal records, a Flutter mobile experience, and a
FastAPI/LangChain backend. The same short-lived university login now opens a
read-only GIU CMS session for the student's full course and resource catalog.

## Repository

```text
mobile/       Flutter app for Android and iOS
backend/      FastAPI API, agent, session isolation, and GIU portal client
notebooks/    Verified portal experiments kept as references
docs/         Architecture, API, and security decisions
scripts/      Local development helpers
```

## 1. Backend configuration

Create `backend/.env` from `backend/.env.example` and set:

```env
ANTHROPIC_API_KEY=your-real-key
ANTHROPIC_MODEL=claude-haiku-4-5
DEGREELENS_ENVIRONMENT=development
DEGREELENS_SESSION_TTL_MINUTES=45
DEGREELENS_CURRENT_SEASON=Winter 2024
DEGREELENS_ADVISORY_YEAR=2024-2025
```

Do not add GIU usernames or passwords to the backend environment. The login
screen sends credentials over HTTPS to establish short-lived, isolated portal
and CMS sessions. Credential material is retained only by their in-memory NTLM
authentication objects and is destroyed at logout or expiry.

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

The course list and official resources come from the authenticated GIU CMS at
runtime and follow the selected advisory semester. PDFs open inside CareerLoop
and can be read by the advisor through a bounded authenticated extraction tool.
Five approved Drive collections are matched to their corresponding
courses and shown under a separate **Available videos** section; they are not
treated as the complete CMS. Drive videos play in an in-app viewer. Video
substance is available to the advisor only after a transcript is added under
`backend/content/transcripts/`.

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
