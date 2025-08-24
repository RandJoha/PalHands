# PalHands — Tech Memory

This document captures key technical decisions and context about the Reports module and adjacent backend concerns. Keep it updated as requirements evolve.

## Current scope (Aug 2025)

- Public Reports endpoints implemented: create, list mine, get by id, add evidence (two-step).
- Admin endpoints: list with filters, update (with FSM), resolve, dismiss, request-info, and stats.
- Data model aligned to frontend forms, supporting five categories.
- Evidence: placeholder array on create; multipart upload afterward. Local storage in dev, S3 in prod. Image pipeline TBD.
- Security: per-user rate limit for create; RBAC (owner vs. admin); assignedAdmin validated; status FSM enforced.
- Idempotency: Create supports Idempotency-Key header/body with unique sparse index per reporter.

## Data model highlights

- Report.reportCategory enum: user_issue | technical_issue | feature_suggestion | service_category_request | other
- user_issue
  - Required: reportedName, issueType (enum), description, partyInfo.reporterName, partyInfo.reporterEmail
  - Optional: reportedType, reportedId, reportedUserRole (required when reportedType = user), partyInfo.reportedEmail, relatedBookingId, reportedServiceId
- technical_issue
  - Required: description, contactName, contactEmail
  - Optional: device, os, appVersion
- feature_suggestion
  - Required: ideaTitle, description, communityBenefit, contactName, contactEmail
- service_category_request
  - Required: serviceName, categoryFit, importanceReason, contactName, contactEmail
- other
  - Required: description, contactName, contactEmail
- Status FSM: pending → under_review → (awaiting_user | investigating) → resolved | dismissed
- Status history array records transitions; illegal jumps rejected in admin controller.

## API surface

Public
- POST /api/reports
- GET /api/reports/me?status&reportCategory&issueType&hasEvidence&createdFrom&createdTo
- GET /api/reports/:id
- POST /api/reports/:id/evidence (multipart form field: files[])

Admin
- GET /api/admin/reports?status&priority&reportCategory&issueType&hasEvidence&assignedAdmin&awaiting_user&sort
- PUT /api/admin/reports/:reportId
- PUT /api/admin/reports/:reportId/resolve
- PUT /api/admin/reports/:reportId/dismiss
- POST /api/admin/reports/:reportId/request-info
- GET /api/admin/reports/stats?since=YYYY-MM-DD

## Validation rules

Create validators branch on reportCategory and enforce per-type requirements listed above. ContactName/Email are required for feature_suggestion, service_category_request, technical_issue, and other. Evidence is always accepted as array (empty by default) and can be augmented via multipart.

## Operational guards

- Rate limiting: create reports per user (e.g., 5 per 10 minutes; see middleware/rateLimiters.js).
- Idempotency: header/body key prevents duplicates.
- Ownership checks on read/evidence; admins see all.

## Deferred items / TODOs

- Image privacy pipeline (EXIF stripping) and signed URL returns consistently for evidence when S3 is enabled.
- OpenAPI spec update to mirror new endpoints and validators.
- Integration tests covering all categories and admin flows.
- Additional admin filters (text search, date ranges) and exports if needed.
- SLA tracking (breach counts) and dashboard widgets.
