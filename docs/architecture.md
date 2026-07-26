# Architecture

```text
Flutter UI
  -> HTTPS JSON API
FastAPI
  -> opaque session token -> isolated StudentSession
  -> CareerLoop agent -> per-session academic tools/cache
  -> GucPortal -> GIU read-only pages
  -> GiuCmsClient -> complete authenticated CMS course/resources view
  -> CmsService -> merges optional Drive videos into matched courses
```

## Mobile

The Flutter app separates:

- UI screens and reusable visual components
- API services and JSON models
- authentication, academic, and advisor repositories
- secure device storage for only the opaque CareerLoop session token

The app contains no GIU credentials and no Anthropic key.

CMS PDFs are downloaded with the opaque CareerLoop bearer token and rendered
from a private temporary file inside the native app. Supplemental Drive videos
use Google's preview player inside an embedded WebView. Course, resource, PDF,
and video surfaces all provide contextual handoffs to the advisor.

## Backend

Every successful login creates a separate `StudentSession` containing:

- one authenticated `GucPortal`
- one authenticated `GiuCmsClient`, or an explicit unavailable-CMS capability
- one `AcademicService` and cache
- one agent conversation
- a short expiry and revocable random token

Portal authentication is required before the backend issues a CareerLoop token.
CMS is an optional capability because final-year and graduate accounts may
retain portal access after CMS course access ends. Login and session responses
report `cms_connected` and a friendly `cms_message` when that capability is
unavailable.

Only a SHA-256 digest of the opaque token is stored in the server lookup table.
Sessions are serialized per chat, and portal access is locked because the
underlying `requests.Session` is stateful.

CMS courses and official files are fetched per student through the student's
isolated NTLM session. Official file URLs never go to Flutter directly: the
backend exposes opaque resource IDs and streams downloads through the same
authenticated session. The shared catalog contains only supplemental Drive
metadata; transcript text is stored by immutable Drive file ID.

## Scaling boundary

The initial deployment deliberately uses one process. Multiple workers would
not share in-memory sessions. A later multi-instance release needs a shared
encrypted session design or an official university authentication/API flow.
