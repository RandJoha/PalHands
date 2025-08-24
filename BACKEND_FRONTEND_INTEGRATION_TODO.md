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
- Session
  - [x] FE: Auto-login on app start (hydrate token, fetch me)
  - [x] FE: Logout clears token, resets state
- Rate limiting UX
  - [x] FE: Friendly message for 429 on login (cooldown UI)

QA
- [ ] BE/FE: E2E happy paths (register, login, profile read/update, change password)
- [ ] BE/FE: Invalid creds, weak password, expired token

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

## Phase 2 — Services Module (BE: Done) ✅

Endpoints
- [x] GET `/api/services` (q text search, pagination, filters)
- [x] GET `/api/services/:id`
- [x] POST `/api/services` (provider/admin)
- [x] PUT `/api/services/:id` (owner/admin)
- [x] DELETE `/api/services/:id` (admin/owner)
- [x] Uploads via multer (images) — multipart

**Frontend Integration:**
- [x] ServicesApiService with full CRUD operations
- [x] Data models matching backend structure
- [x] ServicesIntegrationTest page for testing
- [x] Authentication integration
- [x] Error handling and real-time feedback
- [x] Search, pagination, and filtering support

QA
- [ ] BE/FE: Search accuracy with `q`
- [ ] BE/FE: Image upload size/type validation errors surfaced nicely

---

## Phase 2.1 — Media Storage (BE: Done)

Behavior
- Local (dev): direct multipart upload to API
- S3 (prod): presigned URL, then PUT to S3; save metadata via API

Frontend wiring
- [x] FE: Env-driven switch: STORAGE_DRIVER=local|s3
- [x] FE: Implement presign → upload → confirm attach sequence (if s3)
- [x] FE: Show upload progress; handle cancel/retry
- [x] FE: Render images via signed/public URLs per backend response

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
Frontend wiring
- Home / Category / Search
  - [x] FE: Services list → GET /services with `q`, category, pagination
  - [x] FE: Service details → GET /services/:id
  - [x] FE: Geo filters (if available) passed from device location
- Provider Dashboard → My Services
  - [x] FE: List my services (filter by owner if BE supports `mine=true` else client-side filter)
  - [x] FE: Add service → POST /services (multipart: title, desc, price, images[])
  - [x] FE: Edit service → PUT /services/:id (partial updates allowed)
  - [x] FE: Delete service → DELETE /services/:id (confirm dialog)
  - [x] FE: Image picker + upload (local dev: direct multipart; prod: presign flow — see Phase 2.1)
- Admin Dashboard → Service Management
  - [ ] FE: Approve/enable/disable/edit/delete via corresponding admin-privileged calls

- Service Details → Book Now
  - [x] FE: Create booking → POST /bookings (serviceId, time, notes)
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

## Phase 4 — Payments (BE: Done) ✅

Endpoints
- POST `/api/payments` (create payment)
- GET `/api/payments/methods` (available payment methods)
- POST `/api/payments/:id/confirm` (confirm payment)
- POST `/api/payments/:id/refund` (refund payment)
- GET `/api/payments/:id/audit` (payment audit trail)
- GET `/api/payments/health` (payment system health)
- POST `/api/payments/minimal-cash` (admin: immediate cash payment)
- POST `/api/webhooks/test` (test webhook endpoint)

Frontend wiring
- Booking Flow → Payment
  - [x] FE: Show available payment methods → GET /payments/methods
  - [x] FE: Create payment → POST /payments (bookingId, method, amount)
  - [x] FE: Payment confirmation → POST /payments/:id/confirm
  - [x] FE: Handle payment status updates (pending → paid/failed)
- User Dashboard → Payments
  - [x] FE: List payment history → GET /payments/mine (if available)
  - [x] FE: Payment details with audit trail → GET /payments/:id/audit
  - [x] FE: Request refund → POST /payments/:id/refund
- Provider Dashboard → Payments
  - [x] FE: View received payments → GET /payments/received (if available)
  - [x] FE: Payment reconciliation view
- Admin Dashboard → Payment Management
  - [x] FE: Create minimal cash payment → POST /payments/minimal-cash
  - [x] FE: Payment system health monitoring → GET /payments/health
  - [x] FE: Payment audit and reconciliation tools

QA
- [x] BE/FE: Payment creation and confirmation flow
- [x] BE/FE: Refund processing and status updates
- [x] BE/FE: Payment method availability and capabilities
- [x] BE/FE: Admin cash payment creation

## Deferrals (Do NOT wire yet)
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
