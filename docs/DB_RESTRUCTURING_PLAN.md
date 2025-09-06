# Database Restructuring & Migration Plan

Date: 2025-09-06
Owner: Platform/Backend
Status: Draft (safe to execute in phases)

Goal
- Normalize data so Service holds only catalog basics.
- Move provider-specific properties to ProviderService.
- Keep all schedules in Availability (global) + ProviderService overrides.
- Prepare for cleaner queries and simpler availability resolution.

Target model boundaries
- Service (catalog):
  - Keep: title, description, category, subcategory, images, requirements, equipment (if catalog), isActive/featured, createdAt/updatedAt.
  - Optional: price template/duration defaults (catalog defaults only).
  - Remove/move out: emergencyEnabled, emergencyLeadTimeMinutes, emergencyRateMultiplier, emergencySurcharge, emergencyTypes, location/serviceArea/radius/onSite/remote/geo, rating, totalBookings.
- ProviderService (per provider offering):
  - Keep/add: provider, service, hourlyRate, experienceYears, status/publishable/publishedAt, completenessScore.
  - Emergency settings: emergencyEnabled, emergencyLeadTimeMinutes, emergencyRateMultiplier, emergencySurcharge, emergencyTypes.
  - Availability overrides: weeklyOverrides, exceptionOverrides, emergencyWeeklyOverrides, emergencyExceptionOverrides.
  - Location: serviceArea, radius, onSite, remote, geo (move from Service here if truly provider-specific).
  - Derived/analytics fields (e.g., rating aggregates) should live in separate collections or be computed.
- Availability (per provider global):
  - Keep: weekly, emergencyWeekly, exceptions, emergencyExceptions, timezone, provider identity fields.

High-level steps
1) Schema updates (non-breaking, additive first)
- Ensure ProviderService already contains all emergency fields and override structures (it does).
- Add optional ProviderService.location subdocument if not yet present.
- Mark Service emergency/location/rating/usage fields as deprecated in code comments and stop writing to them in controllers.

2) Backfill/migrate data (idempotent scripts)
- Script A: migrate emergency flags from Service → ProviderService for each (provider, service) mapping.
  - For each ProviderService doc:
    - If serviceRef has emergency fields, copy to ProviderService if absent.
- Script B: migrate Service.location → ProviderService.location using provider’s service area (if varies per provider) or Provider defaults.
- Script C: recalculate ProviderService.completenessScore and publishable after migration.

3) Read path switch-over
- Update controllers and services to read emergency config from ProviderService.
- Availability resolution: effectiveNormal = Availability.weekly ⊖ ProviderService.exclusions ⊕ ProviderService.weeklyOverrides; emergencyBaseline = effectiveNormal ⊕ ProviderService.emergencyWeeklyOverrides.
- Stop reading any emergency/location fields from Service in runtime.

4) Cleanup (breaking – gated)
- Remove deprecated fields from Service schema after verifying scripts and read paths in production for at least one release:
  - Remove: emergencyEnabled, emergencyLeadTimeMinutes, emergencyRateMultiplier, emergencySurcharge, emergencyTypes, location*, rating*, totalBookings.
- Add indexes on ProviderService for frequently queried fields (provider,status,publishable), location.geo (2dsphere), and emergencyEnabled as needed.

Validation & safety
- Dry-run scripts in staging; snapshot counts of affected docs.
- Each script logs a summary: matched, updated, skipped.
- Idempotent: re-running yields 0 changes after first pass.
- Backups: take a pre-migration backup or point-in-time restore marker.

Roll-out checklist
- [ ] Land code that stops writing deprecated Service fields.
- [ ] Run Script A+B in staging; validate spot samples.
- [ ] Deploy read-path changes; monitor logs/metrics.
- [ ] Run Script A+B in production off-peak; verify.
- [ ] Recompute completeness/publishable (Script C); verify.
- [ ] After 1 release cycle, remove deprecated fields from Service.

Mongo scripts (pseudo-code)
- Script A (emergency → ProviderService):
```
db.providerservices.find({}).forEach(ps => {
  const svc = db.services.findOne({_id: ps.service});
  if (!svc) return;
  const updates = {};
  if (svc.emergencyEnabled !== undefined && ps.emergencyEnabled === undefined) updates.emergencyEnabled = !!svc.emergencyEnabled;
  if (svc.emergencyLeadTimeMinutes !== undefined && ps.emergencyLeadTimeMinutes === undefined) updates.emergencyLeadTimeMinutes = svc.emergencyLeadTimeMinutes;
  if (svc.emergencyRateMultiplier !== undefined && ps.emergencyRateMultiplier === undefined) updates.emergencyRateMultiplier = svc.emergencyRateMultiplier;
  if (svc.emergencySurcharge !== undefined && ps.emergencySurcharge === undefined) updates.emergencySurcharge = svc.emergencySurcharge;
  if (Array.isArray(svc.emergencyTypes) && (!Array.isArray(ps.emergencyTypes) || ps.emergencyTypes.length===0)) updates.emergencyTypes = svc.emergencyTypes;
  if (Object.keys(updates).length) {
    db.providerservices.updateOne({_id: ps._id}, {$set: updates});
  }
});
```
- Script B (location → ProviderService):
```
db.providerservices.find({}).forEach(ps => {
  const svc = db.services.findOne({_id: ps.service});
  if (!svc || !svc.location) return;
  const updates = { location: svc.location };
  db.providerservices.updateOne({_id: ps._id}, {$set: updates});
});
```
- Script C (recompute publishable/score):
```
db.providerservices.find({}).forEach(ps => {
  let score = 0;
  if (Number(ps.hourlyRate) > 0) score += 35;
  if (Number(ps.experienceYears) >= 0) score += 25;
  const hasWeekly = ps.weeklyOverrides && Object.values(ps.weeklyOverrides).some(arr => (arr||[]).length>0);
  const hasExceptions = Array.isArray(ps.exceptionOverrides) && ps.exceptionOverrides.length>0;
  if (hasWeekly || hasExceptions) score += 25;
  if (ps.emergencyEnabled) score += 5;
  const publishable = (Number(ps.hourlyRate) > 0) && (Number(ps.experienceYears) >= 0);
  db.providerservices.updateOne({_id: ps._id}, {$set: {completenessScore: score, publishable: publishable}});
});
```

Indexes
- ProviderService: `{ provider:1, service:1 }` unique (exists), `{ provider:1, status:1, publishable:1 }` (exists), consider `{ emergencyEnabled:1 }`, `{ 'location.geo': '2dsphere' }`.
- Service: retain text index for catalog search; drop location/rating indexes after cleanup.

Post-migration updates
- Update OpenAPI and Postman collections to reflect new read paths.
- Remove console/debug logs related to availability once verified.

Contact
- Create a ticket for each script run with timestamps and affected counts.
