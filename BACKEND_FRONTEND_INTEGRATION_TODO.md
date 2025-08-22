# Backend ↔ Frontend Integration Tracker

Purpose: Map every implemented backend feature to a concrete frontend action or UI element so it can be triggered, tested, and marked Done. Use this as the single source of truth while wiring the app end-to-end.

- Scope: Only features marked Done/Implemented in backend docs; defer incomplete phases.
- Status keys: [ ] Todo · [~] In progress · [x] Done · [⏸] Deferred · [⚠] Blocked
- Owners: Backend (BE), Frontend (FE)

## Global prerequisites

- [x] FE: Configure API base URL (dev): http://localhost:3000 (or per .env) and per-env switching
- [x] FE: HTTP client with auth header injection (Dio/HTTP): `Authorization: Bearer <JWT>`
- [x] FE: Persist tokens securely (Hive/SharedPreferences); hydrate on app start; handle logout
- [~] FE: Central error mapper to backend error taxonomy (code/message/details) — basic mapping in place; auth responses include statusCode for better UX
- [ ] FE: File upload helper (multipart + progress) and optional presigned URL flow
- [ ] FE: Pagination helper (page, limit) and unified list models
- [ ] FE: i18n for auth/errors/toasts; RTL verified
- [ ] QA: Postman collection parity smoke tests vs FE flows (`backend/postman_collection.json`)

Assumptions
- API prefix: `/api` (per backend docs)
- JWT auth for protected routes; role guards applied server-side
- Storage: Dev default local uploads; S3 presign available (feature-flagged)

---

## Phase 1 — Auth & Users (BE: Done)

Endpoints (from docs; exact names may vary):
- POST `/api/auth/register`
- POST `/api/auth/login`
- GET `/api/auth/profile`
- PUT `/api/users/profile`
- PUT `/api/users/change-password`
- [Optional] Email verification (flagged)

Frontend wiring
- Login Screen
  - [x] FE: Submit login → POST /auth/login; store JWT, user
  - [x] FE: Loading state, validation, secure error messages
  - [x] FE: Enter key submits (already implemented) → verified
- Signup Screen (Client/Provider)
  - [x] FE: Submit register → POST /auth/register; route to verification or login
  - [x] FE: Provider extra fields (category, documents if any) respected
- Profile Settings (User Dashboard)
  - [x] FE: Load profile → GET /auth/profile on mount
  - [x] FE: Update profile → PUT /users/profile (optimistic UI + toast)
  - [x] FE: Change password → PUT /users/change-password
  - [x] FE: Saved Addresses — client UI now matches provider/admin design (text buttons; right-aligned "Make Default"; default badge and border)
  - [x] FE: Notification Preferences — SMS toggle removed; Email/Push only
- Session
  - [x] FE: Auto-login on app start (hydrate token, fetch me)
  - [x] FE: Logout clears token, resets state
- Rate limiting UX
  - [x] FE: Friendly message for 429 on login (cooldown UI)

Password reset and verification
- [x] BE: Forgot password issues hashed token and sends email (or logs dev fallback)
- [x] BE: Reset password validates token (hashed/plain legacy) and updates password
- [x] FE: Forgot/Reset wired via `AuthService.forgotPassword()` / `resetPassword()`
- [x] QA: Verified admin/client/provider emails accepted; if SMTP not configured, dev fallback logs reset link and token to console
- [x] Docs/Tools: Added `backend/EMAIL_SETUP.md`, `backend/GET_PASSWORD_RESET_TOKEN.md`, and `backend/setup-email.ps1` to guide SMTP setup and dev fallback usage

QA
- [x] BE/FE: E2E happy paths (register, login, profile read/update, change password, forgot/reset) — automated via Jest + supertest (tests/e2e)
- [x] BE/FE: Invalid creds, weak password, expired/tampered token, rate limit

Single-tab verification flow
- [x] BE: Added GET /api/auth/verify/start and /api/auth/confirm-email-change/start landing pages that require explicit user click (prevents mail scanner auto-verify).
- [x] BE: Verification emails now point to the new landing pages.
- [x] FE: Listens for cross-tab signal and refreshes profile in the original tab after completion.
- [x] FE: Redirect from verification page ends on /user?evt=email-updated to force a one-time profile refresh.

Notes
- Auth profile endpoint standardized to `/api/auth/profile` across FE.
- Added change password flow wired to `/api/users/change-password` with validation and toasts.
- Improved login error UX for 429 rate limiting.

---

## Phase 2 — Services Module (BE: Done)

Endpoints
- GET `/api/services` (q text search, pagination, filters)
- GET `/api/services/:id`
- POST `/api/services` (provider/admin)
- PUT `/api/services/:id` (owner/admin)
- DELETE `/api/services/:id` (admin/owner)
- Uploads via multer (images) — multipart

Frontend wiring
- Home / Category / Search
  - [ ] FE: Services list → GET /services with `q`, category, pagination
  - [ ] FE: Service details → GET /services/:id
  - [ ] FE: Geo filters (if available) passed from device location
- Provider Dashboard → My Services
  - [ ] FE: List my services (filter by owner if BE supports `mine=true` else client-side filter)
  - [ ] FE: Add service → POST /services (multipart: title, desc, price, images[])
  - [ ] FE: Edit service → PUT /services/:id (partial updates allowed)
  - [ ] FE: Delete service → DELETE /services/:id (confirm dialog)
  - [ ] FE: Image picker + upload (local dev: direct multipart; prod: presign flow — see Phase 2.1)
- Admin Dashboard → Service Management
  - [ ] FE: Approve/enable/disable/edit/delete via corresponding admin-privileged calls

QA
- [ ] BE/FE: Search accuracy with `q`
- [ ] BE/FE: Image upload size/type validation errors surfaced nicely

---

## Phase 2.1 — Media Storage (BE: Done)

Behavior
- Local (dev): direct multipart upload to API
- S3 (prod): presigned URL, then PUT to S3; save metadata via API

Frontend wiring
- [ ] FE: Env-driven switch: STORAGE_DRIVER=local|s3
- [ ] FE: Implement presign → upload → confirm attach sequence (if s3)
- [ ] FE: Show upload progress; handle cancel/retry
- [ ] FE: Render images via signed/public URLs per backend response

QA
- [ ] Small/large file tests; unsupported mime; network retry

---

## Phase 2.2 — Provider Availability (BE: Done)

Endpoints (typical)
- GET `/api/availability/mine`
- PUT `/api/availability/mine`
- [Optional] Exceptions CRUD

Frontend wiring
- Provider Dashboard → Settings → Availability
  - [ ] FE: Fetch current schedule → GET
  - [ ] FE: Update weekly slots/exceptions → PUT
  - [ ] FE: Timezone handling; 24h/12h UI; DST-safe
- Booking flow
  - [ ] FE: Check slot availability before create (disable unavailable times)

QA
- [ ] Edge cases around DST; overlapping slots prevention UI

---

## Phase 2.3 — Geo & Search (BE: Done)

Frontend wiring
- [ ] FE: Pass lat/lng or location filter when searching services
- [ ] FE: Respect pagination meta from backend (next/prev)
- [ ] FE: Debounced search input; server-side text search via `q`

QA
- [ ] Relevance checks; large result sets; empty states

---

## Phase 3 — Bookings Module (BE: Core Done; FSM/Idempotency Deferred)

Endpoints
- POST `/api/bookings` (create)
- GET `/api/bookings/mine` (for client/provider contexts or use role-aware endpoint)
- GET `/api/bookings/:id`
- PUT `/api/bookings/:id/status` (role-guarded transitions)

Frontend wiring
- Service Details → Book Now
  - [ ] FE: Create booking → POST /bookings (serviceId, time, notes)
  - [ ] FE: Show server-computed pricing in confirmation
- User Dashboard → My Bookings (Default Tab)
  - [ ] FE: List my bookings → GET /bookings/mine; filters (status/date)
  - [ ] FE: Booking details view → GET /bookings/:id
  - [ ] FE: Actions per status (cancel if allowed)
- Provider Dashboard → Bookings
  - [ ] FE: List bookings for my services; role-aware view
  - [ ] FE: Accept/Reject/Complete → PUT :id/status with correct next state
  - [ ] FE: Realtime optional (deferred; see Phase 7)

QA
- [ ] E2E create/list/status-change; ownership/role guard failures rendered properly

### 🚨 **Current Blocker: Provider Authentication Not Working**

**Status**: ⚠️ **BLOCKED** - Cannot test provider-side booking flow

**Issue**: While 79 providers are seeded with complete credentials, the authentication system is not integrated with the Provider model. Providers cannot login to test the booking management flow.

**What's Working**:
- ✅ 79 providers seeded with complete profiles and credentials
- ✅ Provider data exists in MongoDB `providers` collection
- ✅ Services properly linked to provider records
- ✅ Client-side booking creation working

**What's Broken**:
- ❌ Provider login fails with "Incorrect email or password"
- ❌ Authentication system only checks `users` collection
- ❌ Provider password verification not working
- ❌ Cannot test provider dashboard functionality

**Required Fix**:
1. Update authentication controller to check both `users` and `providers` collections
2. Ensure Provider model has same password hashing/verification as User model
3. Test provider login with seeded credentials (e.g., `ahmed0@palhands.com` / `password123`)

**Impact**: End-to-end booking flow testing blocked until providers can authenticate.

---

## Phase 6 — Reports & Disputes (BE: Done)

Endpoints
- POST `/api/reports` (create report)
- GET `/api/reports/mine` (my reports)
- GET `/api/reports/:id`
- POST `/api/reports/:id/evidence` (multer upload)
- Admin: list/update via admin controllers/routes

Frontend wiring
- User Dashboard → Support Help
  - [ ] FE: Create report (type/category, target booking/service, message) → POST /reports
  - [ ] FE: List my reports → GET /reports/mine
  - [ ] FE: Report details → GET /reports/:id
  - [ ] FE: Upload evidence (images/files) → POST /reports/:id/evidence
- Admin Dashboard → Reports & Disputes
  - [ ] FE: List/filter by status/priority/date
  - [ ] FE: Update status/assignment/notes via admin endpoints

QA
- [ ] Evidence upload validations; audit visibility; permission errors surfaced

---

## Admin — Cross-cutting (BE: Routing done; controllers split pending)

- [ ] FE: Ensure admin-only actions show/hide based on role
- [ ] FE: Add admin actions audit breadcrumbs in UI where applicable

---

## Deferrals (Do NOT wire yet)

- Phase 4 — Payments: minimal cash, processors, webhooks [⏸]
- Phase 5 — Reviews & Ratings [⏸]
- Phase 7 — Real-time & Notifications (Socket.io/FCM) [⏸]
- Phase 7.5 — Background Jobs [⏸]

---

## Testing & Quality Gates

- [ ] FE unit tests: auth bloc/cubit, services repo, bookings repo, reports repo
- [ ] FE widget tests: login, service list/detail, booking create, reports submit
- [ ] BE/FE integration smoke: run Postman collection and FE flows against same env
- [ ] Lint/typecheck clean (frontend & backend)
- [ ] Accessibility pass: focus order, labels, RTL

---

## References (from current docs)

- Backend phases and endpoints: `BACKEND_DOCUMENTATION.md`
- Frontend screens and locations:
  - User Dashboard widgets under `frontend/lib/features/profile/presentation/widgets/`
  - Provider Dashboard (e.g., `my_services_widget.dart`); Availability in Settings
  - Admin Dashboard features per `ADMIN_DASHBOARD_DOCUMENTATION.md`
- Environment & Mongo: `backend/ENVIRONMENT_SETUP.md`, `backend/MONGODB_SETUP.md`

---

Checklist hygiene
- Keep items granular and actionable
- When completing, mark [x] and add brief note (date/commit)
- If blocked, mark [⚠] with reason and owner
