Integration & Testing — Emergency Bookings

What was tested during implementation:
- Backend availability resolution (normal vs emergency) using `probeAvailabilityHttp.js` against local/dev backend.
- Backend booking creation paths for emergency vs normal bookings (logic changes applied in `bookingsController.js`).
- Frontend booking dialog: emergency toggle calls `getResolvedAvailability` with `emergency=true` and price displayed updates immediately in the UI.
- Dart analyzer run to ensure no fatal syntax errors were introduced.

Observed outcomes:
- Tagging script updated 16 services to set `emergencyEnabled=true` and `emergencyRateMultiplier=1.6` (and also set `emergencyLeadTimeMinutes` where the script was configured).
- Probe against a provider without a weekly schedule returned zero slots for both normal and emergency modes as expected.

Recommended integration tests to add:
1. Unit test: availability merging
   - Input: a provider with a normal weekly schedule and an `emergencyWeekly` schedule plus exceptions.
   - Assert: resolved availability for `emergency=true` includes all normal slots plus emergency-specific extras and emergency-only windows.
2. End-to-end test: emergency booking creation
   - Setup: create a service with `emergencyEnabled=true`, `emergencyRateMultiplier=1.6`, `emergencyLeadTimeMinutes=120`, and ensure provider availability covers an emergency-only slot.
   - Flow: client requests resolved availability with `emergency=true`, selects an emergency slot within the allowed lead-time, then creates a booking.
   - Assert: booking created successfully, `booking.total` uses the emergency multiplier/surcharge, and booking validation accepts emergency-only time windows.
3. Edge-case tests:
   - Service-specific shorter lead-time (`emergencyLeadTimeMinutes=60`) overrides global default (120) — verify enforcement.
   - Provider with no linked Service documents but string-keyed `provider.services` — verify frontend fallback logic allows the toggle where appropriate but backend still rejects if `service.emergencyEnabled` is false.

How I can help next (pick one):
- Implement the integration tests and the minimal fixtures needed to run them locally. 
- Wire `MyServicesWidget` to the real Services endpoint and add a small widget test.
- Reconcile emergency lead-time defaults across DB and code (perform DB update if you pick 120 as canonical, or change code default to 60).

Status: Test scaffolding recommendations provided; tests not yet added to repo.
