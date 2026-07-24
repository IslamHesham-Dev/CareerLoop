# Security decisions

- GIU credentials are never compiled into Flutter.
- The Anthropic key remains only on the backend.
- Login and all authenticated requests require HTTPS outside local development.
- Request bodies and passwords must never be logged.
- Portal, CMS, cache, and conversation objects are isolated per session.
- Opaque tokens are random, revocable, short-lived, and stored as digests.
- Flutter stores only the opaque session token in platform secure storage.
- Logout and expiration close both university connections and clear credential
  material, cached academic data, and conversation state.
- Official CMS URLs remain server-side behind opaque IDs. The backend streams
  requested files through the authenticated session without persisting them.
- Supplemental video metadata contains only explicitly supplied Drive links;
  Drive continues to enforce access for those videos.

This is a private prototype, not an official university service. A public
multi-student release should obtain university approval and ideally use an
official delegated authentication/API flow instead of collecting portal
passwords.
