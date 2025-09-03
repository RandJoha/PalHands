Frontend — Emergency Bookings (implementation notes)

Summary:
Frontend changes were applied to expose emergency booking capability in the booking dialog and provider UI. The booking dialog shows an "Emergency (short notice)" toggle for eligible services; when toggled the resolved availability query includes `emergency=true` and price estimates immediately reflect the `emergencyRateMultiplier` (or a frontend whitelist fallback multiplier). A provider-side "Emergency only" filter toggle was added to `MyServicesWidget` to help providers see which of their services are emergency-capable.

Key changes:
- `frontend/lib/shared/config/emergency_services.dart`
  - Added a canonical whitelist of service slugs that are allowed to show the emergency toggle in the client UI. This protects the UI from offering emergency where the business doesn't allow it.

- `frontend/lib/shared/widgets/booking_dialog.dart`
  - Emergency toggle UI element added.
  - `_supportsEmergency` now performs a defensive check: it prefers the linked `Service` document's `emergencyEnabled` field, but falls back to provider-level `provider.services` keys for providers using string-keyed service references.
  - Toggles call `AvailabilityService.getResolvedAvailability(..., emergency: true)` so the availability shown matches server-side emergency resolution.
  - Price estimate updates immediately when the toggle is changed — multiplier comes from the service document when present or from frontend fallback logic.

- `frontend/lib/features/provider/presentation/widgets/my_services_widget.dart`
  - Added `_showEmergencyOnly` toggle to filter the displayed services. Note: the current implementation filters a sample `_services` array which contains an `emergency: true|false` flag; it should be wired to call the backend `ServicesService` to reflect live state.

Testing & verification:
- Ran the Flutter analyzer; 245 non-fatal issues (style/warnings/lints) were reported. No syntax errors introduced by the emergency edits.
- Manual UI testing: the emergency toggle updates availability calls and price calculations in the booking dialog during development flows.

Outstanding frontend tasks:
- Replace the sample data in `MyServicesWidget` with real services from `ServicesService` and re-run analyzer and widget tests.
- Clean up analyzer warnings (unused local `screenHeight` variable was introduced by the recent change).

Files of interest:
- `frontend/lib/shared/config/emergency_services.dart`
- `frontend/lib/shared/widgets/booking_dialog.dart`
- `frontend/lib/shared/services/availability_service.dart` (consumes `?emergency=true` parameter)
- `frontend/lib/features/provider/presentation/widgets/my_services_widget.dart`

Status: Implemented (UI + logic). Remaining: production wiring and cleanup.
