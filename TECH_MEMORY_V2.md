# PalHands — Tech Memory v2 (Authoritative Reference)

Purpose
- Single source of truth for technical context, decisions, wiring maps, and QA gates across backend and frontend.
- Authoritative gate: this file MUST be reviewed and updated before any code change. Treat it as a pre-change checklist and design guardrail.

Scope and status
- Date: 2025-08-17
- Phase focus: Phase 1 — Auth & Users (Profile flows). Further Profile polish and wiring are pending; this file is the single source of truth to consult first.
- Tracks what’s implemented and what’s next, grouped by phases. Future requests should reference and extend this file prior to implementation.

Working agreement (review policy)
- Before any implementation, update this Tech Memory to reflect intent, scope, contracts, and QA. Do not proceed until this document is aligned.
- Every PR that changes behavior should include a delta to this file and, when applicable, the Integration Tracker.

## Project snapshot

Stack
- Backend: Node.js (Express), MongoDB/Mongoose, JWT, Multer, optional S3.
- Frontend: Flutter, Provider for state, HTTP client, SharedPreferences/Hive, responsive dashboards, Google Fonts, ScreenUtil.
- API prefix: /api

Global conventions
- Auth header: Authorization: Bearer <JWT> on protected routes.
- Env-driven base URL; dev default http://localhost:3000.
- Error handling: Surface meaningful message and statusCode; friendly UX for rate limits (429) and auth.
- Role-aware UIs (user/provider/admin) must hide unauthorized actions.

Quality gates (must-run before merging or shipping)
- Build & analyzer/lint: 0 errors; warnings tolerated short-term if non-blocking.
- Minimal happy-path smoke: login, fetch profile, update profile, change password (user), forgot/reset password.
- Backend and FE use the same environment; validate CORS and auth headers.

---

## Phase 1 — Auth & Users (Implemented)

Canonical endpoints
- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/logout
- GET  /api/auth/validate
- GET  /api/auth/profile
- POST /api/auth/request-verification            (sends account verification email; no token is returned)
- POST /api/auth/verify                          (body { token }) — first-time account verification
- POST /api/auth/confirm-email-change            (body { token }) — confirms email change and moves pendingEmail -> email
- POST /api/auth/forgot-password
- POST /api/auth/reset-password                  (body { token, newPassword })
- POST /api/auth/change-password-direct          (body { email, currentPassword, newPassword })
- PUT  /api/users/profile                        (auth) — updates name/phone/age/addresses; email change stored in pendingEmail
- PUT  /api/users/change-password                (auth)

Contracts (inputs/outputs; high level)
- Auth responses (register/login): { token, user }
- User shape (subset): { _id, firstName, lastName, email, pendingEmail?, phone, role, age, addresses[], isVerified, isActive, createdAt, updatedAt }
- Request verification: { success, message } — email is sent; client never receives the token
- Verify email: body { token } → marks isVerified=true
- Confirm email change: body { token } → moves pendingEmail -> email
- Update profile: accepts firstName?, lastName?, phone?, age?, address? (legacy), addresses? (normalized, single default), email? (stored to pendingEmail and emails token)

Frontend wiring and decisions
  - Persist JWT; hydrate on app start; fetch /auth/profile to populate currentUser.
  - Logout clears token and in-memory state.
  - Dynamic header and personal info render from AuthService.currentUser; no placeholders. Header edit button is hidden until avatar upload is implemented.
  - "Members since" computed from createdAt (Month Year).
  - Edit is gated by verification; use request-verification flow if needed (email change requires re-verification and validates format client-side).
  - Addresses: Multi-address support with addresses[] (type home/work/other, street, city, area, coordinates?, isDefault). UI supports:
    - Add/Edit/Delete per address via a dialog (type, city dropdown aligned with backend whitelist, street, area, default checkbox)
    - Set as Default action on each non-default card; BE also normalizes to ensure single default
    - Auto-number duplicate types in display (e.g., Home 1, Home 2) and renumber after deletions
    - Rendering shows a Default badge and consistent styling
  - Age is used instead of DOB and is editable (0–120) with server persistence.
  - Phone numbers are unique; UI surfaces a friendly message if duplicate is attempted.
  - Selected tab index in the user dashboard persists via SharedPreferences to restore across sessions.
  - Provider dashboard includes Profile Settings reusing the shared ProfileSettingsWidget and the same API flows.
  - Change Password — two entry points:
    1) Authenticated (Profile > Security): calls PUT /users/change-password.
    2) Unauthenticated (small dialog from Login): collects Email + Current Password + New Password; calls POST /auth/change-password-direct. Backend validates current password and updates securely with generic error on mismatch. Throttled.
  - Forgot Password from Login: POST /auth/forgot-password returns a neutral message; Reset page consumes token via /reset-password route.
  - Password fields disable suggestions/autocorrect and use appropriate AutofillHints to reduce confusing browser manager prompts.
  - Brand-aligned AppToast component standardizes toasts/snackbars site-wide:
    - error → AppColors.primary (brand red)
    - success/info/warning → AppColors.primaryLight (soft light red)
  - Rate-limit friendly copy for 429 on login using surfaced statusCode.

Deep links (Flutter Web)
  - onGenerateRoute + onGenerateInitialRoutes to parse the browser URL.
  - Route /reset-password reads token from query parameters: /reset-password?token=...
  - Route /verify-email (legacy fallback) still exists but is not used in new emails; verification now starts from backend “start” pages (see below). Legacy links require explicit button click to proceed.
  - Safety net: AuthWrapper detects /reset-password on web if needed and redirects to the screen.

Implementation notes (password flows)
  - Storage: We now store a hashed token `passwordResetTokenHash` plus `passwordResetExpires` on User. The legacy `passwordResetToken` is no longer populated for new requests but is still accepted during the transition for older tokens.
  - Validation: Reset accepts a raw token and compares its SHA-256 hash to `passwordResetTokenHash` (or falls back to legacy equality if present) and checks expiry.
  - Messaging: Forgot-password always responds with a neutral message to avoid user enumeration.
  - Rate limits: Tight limiter applied to forgot/reset routes in addition to global limits.
  - Endpoint: POST /auth/change-password-direct with body { email, currentPassword, newPassword }.
  - Behavior: Verifies credentials; on mismatch returns a generic 401 without revealing which field failed. Rate-limited.
  - mailer.js supports SMTP_* and EMAIL_* envs. If not configured, dev fallback logs the email contents to the server console so QA can copy the link/token.
  - APP_BASE_URL must point to the frontend origin (dev: http://localhost:8080) to build links:
    - Reset: `${APP_BASE_URL}/reset-password?token=...`
  - Verify: `${APP_BASE_URL}/verify-email?token=...&r=/user` (opens in the same tab; FE requires explicit click to avoid auto-verify by email clients).

Frontend UX alignment (login-related)

Email verification hardening and one-tab UX
- Problem: Some email providers follow links which auto-called POST /api/auth/verify from server-side previews, setting isVerified before the user clicked.
- Backend fix: Introduced GET landing pages /api/auth/verify/start and /api/auth/confirm-email-change/start that render a small HTML page requiring an explicit user click. The page uses progressive enhancement:
  - No-JS/strict-CSP: a real HTML <form method="POST" action="/api/auth/(verify|confirm-email-change)"> submits only when the user clicks.
  - With JS enabled: intercepts submit, calls the API via fetch, shows success text, signals the app, and redirects.
  - Uses a same-origin relative action (/api/...) to avoid CORS/env mismatches.
- Frontend fix: The landing page notifies any existing app tab (localStorage key palhands:event + postMessage {source:'palhands', type:'email:updated'}) and then redirects to APP_BASE_URL + /user?evt=email-updated. The app listens and refreshes the profile in the original tab, avoiding duplicate tabs.
- Env: Supports APP_BASE_URL (for app) and API_BASE_URL (optional). Backend CORS now also allows the API’s own origin via SERVER_ORIGIN and, in development, localhost/127.0.0.1 origins.

Known non-blockers to clean later

User model snapshot (data contracts)
  - Exactly one default address enforced (BE also normalizes FE submissions)
  - Phone/email unique; duplicate key (E11000) mapped to user-friendly messages
  - Email change is deferred: store new email in `pendingEmail`, email a confirmation link to that address; only after clicking the link is `email` updated. `isVerified` remains unchanged by email change.

Email verification: strict email-link flow only. Two tokens:
- emailVerificationToken (account activation) handled by POST /api/auth/verify.
- emailChangeToken (confirm changing email) handled by POST /api/auth/confirm-email-change.
Profile updates no longer mutate `email` immediately; they set `pendingEmail` and send a link to the new address. Only after clicking the email link (same-tab route /verify-email?token=...) do we move pendingEmail -> email. FE no longer attempts in-tab verification without the email link.

Security invariants (must stay true)
- No email verification without a token received via email; UI must not “auto-verify” on page load.
- Profile email must not change in DB until confirm-email-change token is validated; use `pendingEmail` interim field.
- Verification/confirmation tokens are single-use and cleared when applied.
- Links carry an optional r param so the app can return to the original tab and route.

## Phase 2 — Services (Planned)

Endpoints
- GET  /services (q, pagination, filters)
- GET  /services/:id
- POST /services (provider/admin)
- PUT  /services/:id (owner/admin)
- DELETE /services/:id (owner/admin)
- Multipart upload for images (local dev) or S3 presign (prod)

Front-end wiring (to implement)
- Lists, detail pages, provider “My Services” CRUD with image upload and progress.
- Admin moderation actions (approve/enable/disable/edit/delete).

QA
- Search relevance with q; pagination; upload size/type validation.

---

## Phase 2.1 — Media Storage (Planned)

Behavior
- Dev: direct multipart to API.
- Prod: presigned URL → PUT to S3 → confirm attach.

Front-end
- Env switch STORAGE_DRIVER=local|s3; show progress, cancel, retry; render via signed/public URLs.

---

## Phase 2.2 — Provider Availability (Planned)

Endpoints
- GET /availability/mine
- PUT /availability/mine

Front-end
- Weekly slots editor and exceptions; timezone and 24h/12h modes; booking flow respects unavailability.

---

## Phase 3 — Bookings (Core planned)

Endpoints
- POST /bookings
- GET  /bookings/mine
- GET  /bookings/:id
- PUT  /bookings/:id/status (role-guarded transitions)

Front-end
- Create from service detail; list and detail views; actions per status; provider role view.

QA
- E2E create/list/status transitions; permission failures render cleanly.

---

## Phase 6 — Reports & Disputes (Backend done; FE pending)

High-level (from v1 Tech Memory)
- Categories: user_issue | technical_issue | feature_suggestion | service_category_request | other
- Status FSM: pending → under_review → (awaiting_user | investigating) → resolved | dismissed (with history and guards)
- Public endpoints: create/list mine/get by id/add evidence
- Admin endpoints: list with filters, update, resolve, dismiss, request-info, stats
- Evidence: array on create; multipart upload afterward; local in dev, S3 in prod
- Guards: per-user rate limit; idempotency key; ownership checks

FE work (pending)
- Submit report forms per category; list mine; details; evidence uploads.
- Admin views for triage and state transitions.

---

## Deferred phases
- Payments: processors, webhooks.
- Reviews & Ratings.
- Real-time & Notifications (Socket.io/FCM).
- Background jobs scheduling.

---

## Cross-cutting policies

Security & privacy
- Never store plaintext passwords; respect backend validators; do not leak detailed auth errors to users.
- Avoid user enumeration: use neutral responses for forgot-password; use generic 401 for invalid email/currentPassword on change-password-direct.
- For uploads: strip EXIF when applicable; prefer signed URLs in prod.

Internationalization
- All user-facing strings must route through the localization layer; avoid hardcoded text.

Accessibility
- Ensure focus order, labels, and RTL correctness.

Performance
- Prefer const widgets and memoized expensive trees; paginate large lists from the backend.

Error taxonomy (frontend)

---

Recent Changes — Phase 1 integration (2025-08-17)
- Enabled email verification in backend env: ENABLE_EMAIL_VERIFICATION=true.
- Backend: request-verification sends email via mailer (fallback logs link). Verify URL pattern: ${APP_BASE_URL}/verify-email?token=...&r=/user.
- Backend: Profile update accepts firstName, lastName, email, phone, age, address (legacy) or addresses[]. Email change resets isVerified and emails a new verification token. Duplicate phone/email errors are handled and surfaced.
- Backend: User model includes age (0–120) and addresses[] with single-default enforcement; legacy address migrated if needed.
- Frontend: Profile Settings
  - Edit dialogs for Full Name, Email (format validation + reverify flow), Phone (friendly duplicate message), and Age.
  - Saved Addresses supports multiple entries with type and localized city dropdown aligned with registration, plus default checkbox; list renders multiple cards with default badge.
  - Header edit button hidden until avatar upload exists; user full name and "Members since" render dynamically.
  - User dashboard tab persistence via SharedPreferences.
  - Notification toggles are local-only for now (persistence deferred).
- Deep links: Implemented /verify-email route that requires explicit user action, refreshes profile on success, and returns to same tab/path via r.
  - New default for emails: backend landing pages /api/auth/verify/start and /api/auth/confirm-email-change/start which require a human click and then POST to /api/auth/(verify|confirm-email-change). These pages emit cross-tab signals and redirect to /user?evt=email-updated.
  - Legacy FE route /verify-email remains for old links and continues to require an explicit click.
- QA notes: With SMTP configured, verification and reset links deliver; otherwise tokens/links are logged in server console. Ensure APP_BASE_URL points to frontend origin.

Dev/runbook: CORS FORBIDDEN during confirm/verify
- Symptom: { success:false, code:'CORS_FORBIDDEN', message:'Not allowed by CORS' } on POST /api/auth/confirm-email-change.
- Cause: API origin wasn’t in CORS_ORIGIN; email landing form now posts to same origin (/api/...), but server still blocked origin check.
- Fixes now in code:
  - backend/src/app.js auto-adds the API origin (http://localhost:${PORT}) and, in development, allows localhost/127.0.0.1 origins.
  - Optional env override: SERVER_ORIGIN=http://localhost:3000
  - Ensure CORS_ORIGIN includes the frontend origin (http://localhost:8080) for app calls.

UI refresh consistency after email update
- Problem: After confirming the email via link, the profile dialog showed the new value but the profile card still showed the old email until a hard refresh.
- Fixes:
  - Frontend: AuthService.initialize() now calls getProfile() on startup to sync persisted sessions.
  - ResponsiveUserDashboard now listens to AuthService (Provider.of(context)) for the profile card and address list; they rebuild on notifyListeners().
  - WebEventBridge enhanced: storage/message listeners clear one-shot flags and run an on-load check to catch same-tab redirects.
  - Route handler: visiting /user?evt=email-updated wraps UserDashboardScreen in a one-time _ProfileRefresh that pulls /auth/profile.

Security invariants confirmed
- Email verification and email change confirmation require a human click on the landing page; crawler prefetch cannot auto-verify.
- Tokens are single-use and cleared; email is updated only after token validation (pendingEmail -> email).

Environment variables (updated)
- APP_BASE_URL: frontend origin (dev: http://localhost:8080)
- CORS_ORIGIN: comma-separated allowlist including frontend origin
- SERVER_ORIGIN: API origin (auto-derived as http://localhost:PORT if unset); added to CORS allowlist automatically
- API_BASE_URL (optional): used for composing legacy links; new landing pages use same-origin /api paths

Follow-ups
- Saved Addresses: optional granular endpoints on BE (POST/PUT/DELETE /users/addresses/:idx) if needed; currently FE updates the whole array with PUT /users/profile.
- Define a notifications preferences schema and backend endpoints; wire toggles to persist and preload.
- Clean duplicate switch cases and unused variables flagged in responsive_user_dashboard.dart; centralize strings.
- Map backend errors to: validation_error, unauthorized, forbidden, rate_limited, not_found, server_error; include statusCode where helpful.

---

## Pre-change checklist (review and update this file first)
- Does the change touch any listed endpoints or flows? Update the relevant phase section here.
- If modifying Profile flows (current phase), confirm the intended UX here first.
- Are we adding/changing a user-facing string? Update localization keys.
- Will this affect auth/session/state? Update AuthService contract notes here.
- Do new APIs need QA steps? Add them to the relevant phase QA list.
- Did you run analyzer (0 errors) and a minimal smoke (login/profile/change password)?
- If backend changes, sync Postman and openapi.yaml as needed.
- Are toast colors consistent with the brand mapping? (error=primary red, others=primaryLight)

---

## Current deltas (latest session)
- Deep-link fix for Flutter Web: use onGenerateRoute/onGenerateInitialRoutes; /reset-password reads token from URL. Added AuthWrapper safety fallback.
- Unified AppToast component; brand-aligned colors (error=primary red, success/info/warning=primaryLight). Replaced ad-hoc SnackBars in login/reset/security.
- Password reset security: hash tokens (passwordResetTokenHash), accept legacy tokens temporarily, and apply rate limiting for forgot/reset.
- Added unauthenticated change-password endpoint /auth/change-password-direct and FE dialog path that collects email + currentPassword.
- Mailer supports EMAIL_* and SMTP_* envs; dev fallback logs messages; APP_BASE_URL added and used to generate reset links to frontend.
- Minor lints addressed; remaining warnings are non-blocking.

---

## Phase 1 — Integration hardening (this session, 2025-08-17)

What changed (backend)
- User schema: ensured age exists globally and is returned on register/login/profile/validate. Addresses[] kept alongside legacy address. Added indexes for email and phone uniqueness; helper index on addresses.isDefault.
- Validation: addresses[i].coordinates.latitude/longitude now accept null in addition to numbers to match FE placeholders. City is validated against a predefined lowercase list (aligned with FE dropdown); empty string is allowed during transition.
- Controller: server normalizes addresses submission, enforces exactly one default, mirrors legacy address if array absent, and normalizes city to lowercase.
- Phone uniqueness: controller checks and DB unique index handle conflicts for updates and registration.

Email flows (backend)
- Account verification: `request-verification` issues `emailVerificationToken` and emails `${APP_BASE_URL}/verify-email?token=...&r=/user`. `verify` marks `isVerified=true` and clears the token.
- Email change: `PUT /users/profile` with a new email sets `pendingEmail` (does not change `email`) and emails a link with `emailChangeToken` to the pending address. `confirm-email-change` validates token and moves `pendingEmail -> email`.

Updated flows (safer defaults)
- Verification email link now points to: `${API_ORIGIN}/api/auth/verify/start?token=...&redirect=%2Fuser`
- Email-change link now points to: `${API_ORIGIN}/api/auth/confirm-email-change/start?token=...&redirect=%2Fuser`
- These render a confirm page requiring a click, submit to /api/auth/(verify|confirm-email-change), then signal and redirect to the app.

Cities whitelist (lowercase)
jerusalem, ramallah, nablus, hebron, bethlehem, jericho, tulkarm, qalqilya, jenin, salfit, tubas, gaza, rafah, khan yunis, deir al-balah, north gaza

QA to run
- PUT /api/users/profile with addresses where coordinates are null should pass and persist.
- City validation: non-empty invalid city should 400 with Celebrate details; empty city should be accepted.
- Exactly one default enforced: multiple defaults collapse to first; none defaults → first becomes default.
- Updating phone to existing user’s phone returns 400 Conflict.
- Auth flows return age and addresses consistently across register, login, validate, and profile.
- Registration verify: open `${APP_BASE_URL}/verify-email?token=...`; click Verify Email; observe `isVerified=true` and return path respected.
- Email change: update email; confirm no DB change in `email`, `pendingEmail` populated; open the emailed link; after clicking Verify Email, `email` updated, `pendingEmail` cleared.
- Confirm that the original app tab updates profile automatically (or upon redirect to /user?evt=email-updated) without duplicate tabs. Verify AuthService.getProfile() is called and profile card reflects the new email.

Next small follow-ups
- Optional endpoint: GET /api/users/cities to serve this whitelist to FE from BE source of truth.
- Consider GeoJSON Point for coordinates in Phase 2.3 (search/geo).

---

## Next actionable items
- Saved Addresses management: implement edit/remove/default controls in UI and update via PUT /users/profile; consider BE endpoints for granular CRUD later.
- Notifications persistence: add BE model/endpoint for preferences; load/save toggles.
- Localization cleanup: dedupe keys and route strings through AppStrings; ensure AR/EN coverage for new toasts.
- Tests: add unit/widget tests for login/register/profile update/change password/verify email; add integration smoke.
- Optional: Avatar upload (dev local; prod presign) and provider profile parity.
- Add a subtle “Profile updated” toast triggered by the bridge when profile refresh occurs.
- UI banner to show `pendingEmail` when present, with “Resend confirmation link” action.
- E2E automation for the full register→verify→email-change→confirm→profile-refresh path.

---

## References
- Backend docs: BACKEND_DOCUMENTATION.md
- Integration tracker: BACKEND_FRONTEND_INTEGRATION_TODO.md
- Previous Tech Memory (Reports focus): TECH_MEMORY.md
- Notebooks/diagrams: project docs as added per phase

How to use this file
- Treat v2 as the first stop before any change: confirm decisions, update impacts, then implement.
- Keep sections concise but up to date; use the Pre-change checklist each time.
