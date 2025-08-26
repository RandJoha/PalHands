# Booking Rules and Implementation To‑Do

This document defines the rules and the implementation checklist for booking status controls and cancellations across client and provider dashboards.

## Business rules (authoritative)

- Time thresholds
  - Production: 48 hours minimum lead/cancel window.
  - Test/dev: use 1 minute for fast validation.
  - Config via env:
    - `BOOKING_MIN_LEAD_MINUTES` (default 2880 = 48h; test 1)
    - `CANCELLATION_MIN_LEAD_MINUTES` (default 2880 = 48h; test 1)
- Booking restrictions
  - Clients must not book for the same day or the following day.
  - Earliest allowed booking start = now + BOOKING_MIN_LEAD_MINUTES.
- Cancellation rules
  - If time-to-start >= CANCELLATION_MIN_LEAD_MINUTES: either side can cancel directly.
  - If time-to-start < CANCELLATION_MIN_LEAD_MINUTES: neither side can directly cancel.
    - Instead, a cancellation request must be sent to the other party and accepted to finalize the cancel.
- Provider controls
  - Provider can mark booking: Confirmed, Completed, or Cancelled (subject to the time rules above).
- Client controls
  - Client only needs Cancel now (Reschedule/Contact later), subject to the rules above.
- Filters (client dashboard)
  - Upcoming: future bookings with status in [pending, confirmed, in_progress].
  - Completed: status = completed.
  - Cancelled: status = cancelled.

## Button rules (visibility + allowed actions)

- Client dashboard
  - Cancel button
    - Visible when booking.status in [pending, confirmed] and booking is not in a final state.
    - Action when time-to-start >= threshold: direct cancel (set status=cancelled).
    - Action when time-to-start < threshold: open dialog to send cancellation request to provider; no direct cancel.
  - Pending, Confirmed, Completed buttons: not shown for client (future phases may add Confirm receipt etc.).

- Provider dashboard
  - Confirm button
    - Visible when status=pending; action sets status=confirmed.
  - Complete button
    - Visible when status in [confirmed, in_progress]; action sets status=completed.
  - Cancel button
    - Visible when status in [pending, confirmed, in_progress];
    - If time-to-start >= threshold: direct cancel.
    - If time-to-start < threshold: open dialog to send cancellation request to client.
  - Note: Final states (completed, cancelled) hide all state-change buttons.

## State machine (high‑level)

- pending → confirmed (by provider)
- confirmed → in_progress (auto/on start; optional, can be skipped)
- confirmed/in_progress → completed (by provider)
- any(non-final) → cancelled (direct if >= threshold, otherwise via accepted cancellation request)
- Final states: completed, cancelled

## Backend tasks

- [x] Config: add `BOOKING_MIN_LEAD_MINUTES`, `CANCELLATION_MIN_LEAD_MINUTES` with defaults and docs (edit `backend/env.example`, read from `process.env` with sensible defaults; prefer 1 minute if `NODE_ENV!=='production'` and unspecified).
- [x] Model (file: `backend/src/models/Booking.js`): extend with `cancellationRequests: [{
      status: 'pending'|'accepted'|'declined'|'expired',
      requestedBy: ObjectId (User/Provider),
      requestedByRole: 'client'|'provider',
      requestedTo: ObjectId,
      reason: String,
      requestedAt: Date,
      respondedAt: Date,
      expiresAt: Date
  }]` and indexes on `{ 'cancellationRequests.status': 1 }`.
- [x] Controller (file: `backend/src/controllers/bookingsController.js`): enforce booking min lead time in create flow using `schedule.startUtc` (or compute from date+time+timezone via Luxon) → 422 with code `booking_min_lead_time`.
- [x] Endpoint: POST `/api/bookings/:id/cancel`
      - If time-to-start >= threshold → cancel directly; set `status='cancelled'`, `cancellation.cancelledBy`, `cancelledAt`.
      - Else → create a pending `cancellationRequest` targeting the counterparty; 202 Accepted with the request payload.
  - [x] Endpoint: POST `/api/bookings/:id/confirm` (provider only) → allowed from `pending`.
  - [x] Endpoint: POST `/api/bookings/:id/complete` (provider only) → allowed from `confirmed` or `in_progress`; set `status='completed'`, `completion.providerConfirmation=true`, `completion.completedAt`.
  - [x] Endpoint: POST `/api/bookings/:id/cancellation-requests/:requestId/accept` (only counterparty) → set accepted and perform cancel. (Implemented as unified respond endpoint)
  - [x] Endpoint: POST `/api/bookings/:id/cancellation-requests/:requestId/decline` (only counterparty) → set declined. (Implemented as unified respond endpoint)
  - [x] Routes wiring (file: `backend/src/routes/bookings.js`) with appropriate auth middleware and celebrate validators.
  - [x] Policies (file: `backend/src/policies/bookingPolicies.js`): add helpers to decide button visibility and allowed transitions based on role + time threshold; expose `canCancelDirectly(booking, now)`, `canSendCancellationRequest(user, booking)` etc. (added helper variants)
  - [ ] Populate: ensure list/get endpoints include `cancellationRequests` summary and `schedule.startUtc` in responses.
  - [x] Validation and guards: block cancel/confirm/complete in final states; idempotency.
  - [ ] Tests (set thresholds to 1 minute):
      - create booking blocked if < min lead.
      - client cancel > threshold succeeds; < threshold returns 202 + request.
      - provider cancel > threshold succeeds; < threshold returns 202 + request.
      - accept/decline flows update state.
      - confirm/complete transitions.

## Frontend tasks (client dashboard)

- [ ] Filters: ensure Upcoming/Completed/Cancelled tabs actually filter local list by status and date.
- [ ] Cancel button behavior
      - On tap → call `/cancel` and handle:
        - 200: update card to `cancelled` and move to Cancelled tab.
        - 202: show toast "Cancellation request sent"; show a small badge on the card ("Awaiting provider approval").
      - If backend blocks for other reasons → show small popup with i18n message.
- [ ] Popup when less than threshold
      - Dialog text: "You can’t cancel within 48 hours. Send a cancellation request to the provider?"
      - Buttons: Send Request / Keep Booking
      - Collect optional reason and pass to API.
- [ ] UI: show pending cancellation request indicator on booking cards.
- [ ] i18n: add strings for labels, errors, popups, and statuses if missing.
- [ ] Booking dialog (service tab): block selecting dates that violate min lead; display helper text explaining earliest date.

## Frontend tasks (provider dashboard)

- [ ] Action buttons per card
      - Confirm (visible when status=pending) → call `/confirm` → update to confirmed.
      - Complete (visible when status in [confirmed, in_progress]) → call `/complete` → update to completed.
      - Cancel → if >= threshold, cancel directly; else open dialog to send cancellation request to client (optional reason), then call API.
- [ ] Handle incoming cancellation requests
      - If a pending request exists from client, render inline banner with Accept / Decline.
      - Accept → cancel booking; Decline → mark declined.
- [ ] Visual badges: show "Request sent" / "Awaiting your decision" states.
- [ ] i18n strings for provider actions and banners.

## Cross‑cutting

- [ ] Time calc utility: unify time comparisons using `schedule.startUtc`; if absent, compute from `schedule.date + startTime + timezone`.
- [ ] Feature flag/test mode: when `NODE_ENV !== 'production'`, default thresholds to 1 minute unless overridden.
- [ ] Analytics/logging: basic audit of status transitions and cancellation requests (optional now).
- [ ] Docs: update `BACKEND_DOCUMENTATION.md`, `USER_DASHBOARD_DOCUMENTATION.md`, and `PROVIDER_DASHBOARD_DOCUMENTATION.md` with the new flows.

## Acceptance criteria (summary)

- Client cannot create bookings starting before NOW + 48h (prod) or 1m (test).
- Client Cancel
  - > threshold: direct cancel OK.
  - < threshold: sees dialog and can send a request; card shows pending status.
- Provider controls
  - Can mark Confirmed/Completed; can Cancel under same time rules; can Accept/Decline incoming cancellation requests.
- Client filters show correct items in Upcoming/Completed/Cancelled.
- All new actions reflected immediately on the cards without full page refresh.

## File-by-file touchpoints (quick nav)

- Backend
  - `backend/src/models/Booking.js` → add `cancellationRequests` + indexes
  - `backend/src/controllers/bookingsController.js` → createBlock, cancel/confirm/complete, accept/decline
  - `backend/src/routes/bookings.js` → wire endpoints + validators
  - `backend/src/policies/bookingPolicies.js` → add `canCancelDirectly`, transition checks
  - `backend/env.example` → add new env keys; document in `BACKEND_DOCUMENTATION.md`

- Frontend (Flutter)
  - `frontend/lib/shared/services/booking_service.dart` → add `cancelBooking`, `confirmBooking`, `completeBooking`, `respondCancellationRequest`, plus threshold-aware messages
  - Client UI: `features/profile/presentation/widgets/responsive_user_dashboard.dart` → cancel flow + tabs filter
  - Provider UI: `features/provider/presentation/widgets/bookings_widget.dart` → buttons, banners, actions
  - Booking dialog: `features/.../booking_dialog.dart` (or equivalent) → date picker min-date logic
  - i18n: `shared/localization/app_strings.dart` (or strings source) → add new keys

## Test mode switch (how to run)

- For development, set:
  - `BOOKING_MIN_LEAD_MINUTES=1`
  - `CANCELLATION_MIN_LEAD_MINUTES=1`
- In production, omit or set both to `2880`.
