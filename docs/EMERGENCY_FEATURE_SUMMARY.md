Emergency Bookings — Feature Summary

Status (as of 2025-09-06):
- End-to-end Emergency flow is live with improved availability editing and inheritance.
- Frontend (Provider dashboard):
  - Per-service Availability editor shows inherited Global slots in blue, service additions in green, and exclusions in red.
  - “Add window” uses a range picker and splits into hourly slots automatically.
  - Emergency tab now inherits from the service’s saved normal effective schedule (or global if no overrides) and only saves emergency additions.
  - Deletions/exclusions now persist; overrides are saved whenever there are exclusions or additions, otherwise we inherit by saving null.
  - Console noise greatly reduced; debug prints limited and marked for removal post-stabilization.
- Backend:
  - Validation updated to accept `emergencyWeekly` and `emergencyExceptions` in Availability upserts.
  - Server bootstrap (`server.js`) restored; request logging and noisy console prints disabled by default.
- DB:
  - No destructive schema changes were applied in this pass. A separate normalization plan is documented to move provider-specific flags from `Service` to `ProviderService` and rely on `Availability` for schedules.

Key files changed in this iteration:
- frontend:
  - `frontend/lib/features/provider/presentation/widgets/my_services_widget.dart` — hourly slot splitting, inherited baseline rendering, exclusion persistence, Emergency baseline from normal effective schedule, clean saves for emergency overrides.
- backend:
  - `backend/src/routes/availability.js` (validator) — allow emergency fields.
  - `backend/server.js` — restored minimal server and toned down logging.

Behavioral details:
- Effective per-service normal schedule = (Global − Exclusions) + Service additions.
- Emergency schedule baseline = Service normal effective schedule; only emergency additions are saved. Empty emergency saves as null to keep inheritance clean.

Known notes:
- If you later normalize DB (see new `DB_RESTRUCTURING_PLAN.md`), update controllers to read emergency flags from `ProviderService` instead of `Service`.
- Pick a canonical default for emergency lead-time (currently 120 minutes by default; some older tags used 60).

Sanity tests to try:
- Add a global slot, open any service: it appears blue; exclude it in one service and save; reopen and verify it’s red (excluded) and not present in effective schedule.
- Add a green (service) slot; save; verify persistence; in Emergency tab, add a green emergency-only slot and save; verify only emergency additions were stored.

Contact/author: Changes applied by developer workflow on repository `PalHands` (branch: master).
