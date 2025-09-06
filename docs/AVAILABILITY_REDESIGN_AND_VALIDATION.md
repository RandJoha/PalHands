# Availability Redesign, Inheritance, and Validation (Sep 2025)

This document summarizes the frontend UX changes and backend API adjustments made during the September 2025 iteration to fix noisy logs, align per‑service availability with global availability, and support a clean emergency workflow.

## Frontend — Provider Dashboard (My Services)

Key improvements in `frontend/lib/features/provider/presentation/widgets/my_services_widget.dart`:

- Time range picker dialog now returns via an `onConfirm` callback; selected ranges are split into hourly slots when added.
- Global vs service inheritance rendering:
  - Global slots render in blue (inherited by default).
  - Service additions render in green.
  - Exclusions render as red toggles; clicking ⊖ excludes an inherited global hour for the specific service.
- Save behavior:
  - Effective normal schedule = (global − exclusions) + service additions.
  - If identical to global, `weeklyOverrides` is saved as `null` (inherit).
  - Otherwise, the full effective schedule is saved in `weeklyOverrides` per day.
- Emergency tab baseline:
  - Baseline inherits from the service’s effective normal schedule when present (`weeklyOverrides`), otherwise from global.
  - Emergency additions are saved separately in `emergencyWeeklyOverrides`.
  - When there are no emergency additions, `emergencyWeeklyOverrides` is sent as `null` to keep the DB clean.

User tips
- Use “Add hour” or “Add service slots” to add green slots specific to the service.
- Click ⊖ on a blue (global) slot to exclude it for this service only.
- In the Emergency tab, add only the extra urgent hours; the base mirrors your normal effective schedule.

## Backend — Provider Service Update Validation

Endpoints: `PATCH /api/provider-services/:providerId/:id`

Validation changes in `backend/src/routes/providerServices.js`:
- Accept `null` as a valid value for:
  - `weeklyOverrides`, `exceptionOverrides`, `emergencyWeeklyOverrides`, `emergencyExceptionOverrides`.

Controller normalization in `backend/src/controllers/providerServicesController.js`:
- When a field is `null`, it is set to `undefined` to remove the override field from the document.
- `weeklyOverrides` and `emergencyWeeklyOverrides` are normalized per-day by filtering out invalid windows.

Error handling
- Celebrate’s error handler is now installed in `backend/src/app-minimal.js` so request validation errors return HTTP 400 with details (instead of generic 500s).

## Logging cleanup
- Suppressed noisy console logs both frontend (API layer) and backend (request logging disabled in minimal app, retained health and route-load logs).

## Data model notes
- `ProviderService.weeklyOverrides` and `ProviderService.emergencyWeeklyOverrides` are optional; `null` requests clear the field.
- `ProviderService` remains the single source of truth for per‑service pricing, experience, and per‑service availability overrides.

## Known behavior and edge cases
- New global slots automatically appear in blue for all services; exclusions are opt‑in per service.
- If you remove all service additions and exclusions, `weeklyOverrides` becomes `null` and the service inherits global availability entirely.
- Emergency baseline reflects the saved effective normal schedule; after changing normal, reopen the dialog to see the updated emergency baseline.

## January 2025 Updates - Service Management Fixes

### Critical Issues Resolved
1. **Global Slot Inheritance Logic (✅ FIXED)**
   - **Problem**: New global slots appeared as excluded (red) by default instead of active (blue)
   - **Solution**: Implemented smart exclusion detection that distinguishes between:
     - Services WITHOUT overrides: All global slots = active (blue) by default
     - Services WITH overrides: Global slots missing from saved schedule = previously excluded (restore section)
   
2. **Emergency Mode Baseline Inheritance (✅ FIXED)**  
   - **Problem**: Emergency mode inherited from old global slots instead of service's current normal schedule
   - **Solution**: Created dedicated `_EmergencyDayEditorRow` component that:
     - Shows service's normal schedule as read-only gray baseline dots
     - Only allows adding/removing emergency-specific green additions
     - Saves only emergency additions, baseline inherited automatically

3. **Slot Exclusion Persistence (✅ FIXED)**
   - **Problem**: User exclusions didn't persist across dialog reopens (circular logic issue)
   - **Solution**: Proper state management distinguishing between:
     - Initial exclusions (from saved data)
     - User exclusions (real-time session changes) 
     - Restore functionality (re-activate previously excluded slots)

4. **Dynamic Booking Rules (✅ FIXED)**
   - **Problem**: Emergency mode still enforced 48-hour booking delay
   - **Solution**: Modified booking dialog to allow:
     - Normal mode: 48-hour minimum delay
     - Emergency mode: Same-day booking allowed

### Implementation Details
- **Files Modified**: `my_services_widget.dart`, `booking_dialog.dart`
- **New Components**: `_EmergencyDayEditorRow` for dedicated emergency mode editing
- **Color Coding**: Blue (global inherited), Green (service additions), Gray (emergency baseline), Red (excluded/restore)
- **Save Logic**: Emergency saves only additions, normal saves effective schedule or null for full inheritance

### Testing Results
- ✅ New global slots appear as blue (active) by default
- ✅ Emergency mode properly inherits from service's normal schedule
- ✅ User exclusions persist across dialog reopens
- ✅ Same-day emergency booking enabled
- ✅ Restore functionality works for previously excluded slots

Last updated: 2025‑01‑15
