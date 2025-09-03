Emergency Bookings — Feature Summary

Status (as of 2025-09-03):
- Implemented end-to-end feature to support "Emergency" bookings for a curated set of services.
- Frontend: emergency toggle in booking dialog, immediate price multiplier applied in the UI, emergency badge on bookings, and a provider-side "Emergency only" filter toggle added to `MyServicesWidget` (currently wired to sample data; needs production wiring to ServicesService).
- Backend: service-level flags exist and are respected (`service.emergencyEnabled`, `service.emergencyRateMultiplier`, `service.emergencySurcharge`, `service.emergencyLeadTimeMinutes`). Availability resolution and booking creation now merge the normal weekly schedule with emergency-specific windows and append default emergency-only extra windows (late-night / early-morning). Emergency lead-time defaults to 120 minutes (2h) unless a service-specific `emergencyLeadTimeMinutes` is set.
- DB: A tagging script was added and run to mark a set of services as emergency-enabled. The script updated 16 services in the live MongoDB during this work.

Files changed / created by the implementation:
- frontend:
  - `frontend/lib/shared/config/emergency_services.dart` — whitelist of emergency-eligible service slugs (extended).
  - `frontend/lib/shared/widgets/booking_dialog.dart` — emergency toggle + immediate price behavior + provider.services fallback.
  - `frontend/lib/features/provider/presentation/widgets/my_services_widget.dart` — emergency filter toggle (uses sample data currently).
- backend:
  - `backend/src/controllers/availabilityController.js` — merged normal + emergency weekly windows; appended emergency-only extras; emergency lead-time handling.
  - `backend/src/controllers/bookingsController.js` — emergency min-lead enforcement; merged emergency windows for booking validation; multiplier/surcharge preserved.
  - `backend/src/utils/tagSelectedServicesEmergency.js` — tagging script to bulk-enable emergency for service documents.

Known mismatches and notes:
- Tagging script set `emergencyLeadTimeMinutes: 60` for some services while the backend default emergency lead-time is 120 minutes; the code honors per-service values. Recommendation: pick a canonical default (60 or 120) and update either DB or code to match.
- `MyServicesWidget` currently filters local sample data. It should be wired to call the backend `ServicesService` so the emergency-filter reflects real DB state.
- Dart analyzer reported many non-fatal lints (245 issues); recent edits don't introduce syntax errors but a small unused-variable lint exists in `my_services_widget.dart`.

Quick test notes:
- A probe run against a provider with no weekly schedule returned zero slots for both normal and emergency probes; to validate emergency-only extra windows, run a probe against a provider with a configured weekly schedule or create a temporary availability record.

Next steps (pick one or more):
- Wire `MyServicesWidget` to the real Services API and test the emergency filter with live service documents.
- Reconcile the emergency lead-time canonical value and update DB or code.
- Add unit and integration tests: availability merging test; emergency booking creation within lead-time and price verification.
- Clean up lint warnings and remove unused local variables in frontend widgets.

Contact/author: Changes applied by developer workflow on repository `PalHands` (branch: master).
