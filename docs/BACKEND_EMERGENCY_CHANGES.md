Backend — Emergency Bookings (implementation notes)

Summary:
The backend was updated to support short-notice ("Emergency") bookings for a curated set of services. The core principle is defense-in-depth: a service must be marked `emergencyEnabled: true` in the `services` collection for emergency bookings to be permitted. The backend also reads `emergencyRateMultiplier`, `emergencySurcharge` and `emergencyLeadTimeMinutes` from the service document.

Key changes:
- Availability resolution
  - `availabilityController.getResolvedAvailability` now merges the provider's normal weekly schedule (`a.weekly`) with `a.emergencyWeekly` when `?emergency=true` is requested.
  - Exceptions are merged (`a.exceptions` + `a.emergencyExceptions`) when emergency mode is active.
  - Default emergency-only extras are appended to the merged weekly windows: 00:00–06:00 and 22:00–23:59 (per weekday). These are applied only for emergency resolution, so normal mode is unaffected.
  - Lead-time calculation: normal bookings use the environment min lead (default 2880 minutes = 48h). Emergency bookings default to 120 minutes (2h), but `Service.emergencyLeadTimeMinutes` on the service document overrides this when present.

- Booking creation
  - `bookingsController.createBooking` enforces min-lead according to emergency vs normal rules (2h default for emergency, 48h normal), honoring per-service `emergencyLeadTimeMinutes`.
  - Availability validation for emergency bookings merges normal + emergency windows and considers merged exceptions so emergency-only windows are recognized as valid times for emergency bookings.
  - Price calculation applies `service.emergencyRateMultiplier` and `service.emergencySurcharge`.

Operational scripts:
- `backend/src/utils/tagSelectedServicesEmergency.js` — a convenience script added to bulk-tag services by slug/subcategory/code and set emergency fields (emergencyEnabled=true, emergencyRateMultiplier, emergencySurcharge, emergencyLeadTimeMinutes). This script was executed during the change and updated 16 services in the live DB.

Testing & probes used:
- A small probe `probeAvailabilityHttp.js` was used to query resolved availability with and without `?emergency=true` for providers during development. Probe results showed no slots for a particular provider that had no configured weekly schedule, which is expected behavior.

Notes & recommended reconciliations:
- Some services were tagged with `emergencyLeadTimeMinutes: 60` during bulk tagging, while the backend default is 120. Decide on a canonical default and update DB or code accordingly.
- Consider making the emergency-only extras (00:00–06:00, 22:00–23:59) configurable per-provider or per-service if business rules need it.

Files of interest:
- `backend/src/controllers/availabilityController.js`
- `backend/src/controllers/bookingsController.js`
- `backend/src/models/Service.js` (schema already supports emergency fields)
- `backend/src/utils/tagSelectedServicesEmergency.js` (new)
- `backend/src/utils/probeAvailabilityHttp.js` (probe helper used during verification)

How to reproduce locally:
1. Ensure `.env` is configured and MongoDB is accessible.
2. Run the tagging script (optional) to enable emergency on selected services:
   - `node src/utils/tagSelectedServicesEmergency.js`
3. Start the backend server (per repo instructions).
4. Use `probeAvailabilityHttp.js` to compare `?emergency=true` vs normal availability for a provider with a weekly schedule.

Status: Completed (implementation and DB tagging performed). Remaining: reconcile emergency lead-time canonical value, and consider making emergency extras configurable.
