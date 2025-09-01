# Restore Data (Providers)

This guide restores all Provider records and their basic Services to a known-good state that matches the current frontend and booking flows.

## What this does
- Upserts providers from a canonical dataset (`src/utils/data/providers.dataset.js`).
- Resets each provider’s password to a known value (default `Provider123!`, override with `PROVIDER_DEFAULT_PASSWORD`).
- Ensures each provider has 2–4 services aligned to our current categories.
- Optionally prunes unknown providers that aren’t in the dataset (and their services).

## Prereqs
- .env has a valid `MONGODB_URI`.
- Node 16+ installed.

## Run

Windows PowerShell:

```powershell
# From backend folder
node src/utils/restoreProviders.js

# Optional: custom default password and prune unknown providers
$env:PROVIDER_DEFAULT_PASSWORD = 'Provider123!'; $env:PRUNE_UNKNOWN_PROVIDERS = 'true'; node src/utils/restoreProviders.js
```

Or via npm scripts:

```powershell
npm run restore:providers
```

## Notes
- Dataset includes English and Arabic providers used throughout demos and tests.
- Services are created per provider service categories (hourly, ILS).
- Safe to run multiple times; it upserts by email.

