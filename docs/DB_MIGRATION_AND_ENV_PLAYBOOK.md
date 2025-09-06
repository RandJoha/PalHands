# Database attribute moves and environment checklist

This playbook explains how to move attributes between collections, how to keep read models in sync, and what to add to .env during and after the migration. Keep this file under the .env file for quick access during ops.

Date: 2025-09-06
Owner: Backend Team

## Principles
- Backward compatibility first: writes move to the new source of truth; reads remain dual until migration completes.
- Idempotent scripts: rerunnable without side effects.
- Safe defaults: when in doubt, prefer `undefined` over empty objects so resolvers can fall back cleanly.

## Common moves we perform
- Provider->Service scalar fields (hourlyRate, experienceYears) → ProviderService documents (per provider+service).
- Availability from provider-level (global) → remain global, with per-service overrides in ProviderService.weeklyOverrides/emergencyWeeklyOverrides.

## Step-by-step migration template
1) Design the target model
- Define the destination collection and schema fields.
- Add mongoose indexes (unique pairs, lookups) but do NOT drop legacy indexes yet.

2) Add feature flags and env vars
- Add to .env:
  - MIGRATION_DRY_RUN=true
  - MIGRATION_BATCH_SIZE=500
  - USE_PROVIDER_SERVICES_PUBLIC_ONLY=true (example read-switch for listings)
  - VALIDATE_STRICT=false (if needed to loosen validation while migrating)
- Optional toggles for resolvers:
  - AVAILABILITY_INHERIT_EMERGENCY_FROM_NORMAL=true
  - AVAILABILITY_HOURLY_STEP_MINUTES=60

3) Build migration script
- Place under `backend/src/utils/your_migration.js`.
- Script contract:
  - Reads from source collection in batches (cursor).
  - Upserts into destination, preserving `_id` references.
  - Writes are idempotent (use upsert with unique keys, e.g., `{ provider, service }`).
  - Logs progress every N docs.
- Example upsert:
```js
await ProviderService.updateOne(
  { provider, service },
  { $set: { hourlyRate, experienceYears } },
  { upsert: true }
);
```

4) Dual-read period
- Update controllers to read from the new collection when present, otherwise fall back to legacy fields.
- Keep write path on the new collection only.

5) Verification
- Add a probe script to diff counts and sample values.
- Run E2E tests on staging.

6) Cutover and cleanup
- Flip env flags to prefer only new sources.
- Drop legacy indexes and fields once consumers confirm.

## Env checklist (paste below in your .env)

# ===== Migration toggles =====
MIGRATION_DRY_RUN=true
MIGRATION_BATCH_SIZE=500
USE_PROVIDER_SERVICES_PUBLIC_ONLY=true
VALIDATE_STRICT=false
AVAILABILITY_INHERIT_EMERGENCY_FROM_NORMAL=true
AVAILABILITY_HOURLY_STEP_MINUTES=60

# ===== Safety nets =====
READ_TIMEOUT_MS=15000
WRITE_TIMEOUT_MS=15000

# ===== Logging =====
LOG_LEVEL=info

## Operational tips
- When moving fields, ensure validators accept `null` for cleared overrides (e.g., weeklyOverrides) so clients can revert to inheritance.
- For availability, store only meaningful overrides; treat `null` as “inherit from base”.
- For emergency, persist only additions; baseline should be computed from normal.
