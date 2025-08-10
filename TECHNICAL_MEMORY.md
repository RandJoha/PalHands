# Our Services Tab Redesign - Technical Memory (Aug 2025)

This entry documents the scope, decisions, and implementation notes for upgrading the "Our Services" tab from single-category selection to a multi-select, cross-category service filter with provider listing, sorting, and location filters. It also tracks responsiveness goals and internationalization coverage.

## Goals
- Multi-select services across all categories without closing dialogs.
- Show providers matching any selected services (OR semantics) and optional city filter.
- Add sorting by rating and by price (both asc/desc).
- Add reset button to clear filters quickly.
- Display complete provider cards: name, city, phone, years of experience, languages, hourly rate, services, actions (Book, Call, Chat).
- Maintain full Arabic/English support and correct RTL behavior.
- Ensure responsive, readable, non-overflowing UI on mobile, tablet, desktop.

## Implementation Summary
- Introduced ProviderModel at `frontend/lib/shared/models/provider.dart`.
- Created ProviderService at `frontend/lib/shared/services/provider_service.dart` with API call + mock fallback.
- Updated `WebCategoryWidget` and `MobileCategoryWidget` to:
	- Maintain a global selection state map: categoryId -> {serviceKeys}.
	- Aggregate selected service keys and fetch providers on changes.
	- Add location filter (city dropdown), sort control, and reset.
	- Render selected service chips with remove action.
	- Render providers list/grid with actions (book/call/chat).
	- Keep RTL via LanguageService.textDirection and localized labels.
- Endpoint assumption: GET `/services/providers?services=a,b&city=CITY&sortBy=rating|price&sortOrder=asc|desc`.
	- If the endpoint is missing, mock data is used for development.

## Responsiveness Notes
- Web: Grid switches 1/2/3 columns based on width; card aspect ratio adjusted to avoid overflow. Controls fall back to Wrap on narrow widths.
- Mobile: List tiles optimized with smaller typography and spacing; chips and controls wrap with adequate padding.
- Shared Navigation unchanged; providers list appears under hero and categories.

## i18n Notes
- Reused existing strings where possible (rating, price, hourly, location, reset, chat, contact, bookNow, cities).
- Avoided adding new keys that duplicate existing ones to keep `app_strings.dart` clean.
- Provider section heading uses inline text with Arabic/English fallback to avoid new key duplication for now.

## Open Backend Task
- Implement `/services/providers` endpoint on backend to support filters and sorting. Query params:
	- services: comma-separated service keys (match any)
	- city: optional city string (exact match by known city labels)
	- sortBy: `rating` | `price`
	- sortOrder: `asc` | `desc`

## Test Matrix (Manual, quick pass)
- No services selected: shows all providers (mock) sorted by rating desc by default.
- Select multiple services across categories: providers include any matching service.
- Change city: providers filtered by selected city only.
- Change sort: order reflects rating/price asc/desc.
- Reset: clears chips, city, sort => default fetch.
- RTL: Controls order and text direction adapt correctly.
- Narrow widths: Controls wrap without overflow, cards readable.

## Future Discussions
- AND vs OR toggle for service filters (currently OR).
- Price ranges and min/max hourly filters.
- Pagination/infinite scroll for provider results.
- Caching selected filters in route state/query parameters.
- Hook up booking and chat navigations.

## Review Checklist (QA after implementation)
- Functionality
	- [ ] Multi-select across categories updates provider list without closing UI.
	- [ ] City filter narrows results correctly.
	- [ ] Sort by rating/price works in both directions.
	- [ ] Reset clears all filters and results return to default.
- Provider Card Completeness
	- [ ] Name, location, phone present.
	- [ ] Experience years, languages, hourly rate present.
	- [ ] Services chips visible; truncation reasonable.
	- [ ] Book, Call, Chat buttons present and responsive.
- Responsiveness & Accessibility
	- [ ] No overflows in 320–1400+ px widths.
	- [ ] Tap targets ≥ 44px on mobile.
	- [ ] Text sizes remain readable; no excessive shrinking.
	- [ ] Layout adapts without wrapping into unusable stacks.
- i18n/RTL
	- [ ] Arabic and English display correctly, with RTL layout where applicable.
	- [ ] City names and service labels localized correctly.
- Backend Integration
	- [ ] When backend endpoint is available, mock fallback disabled seamlessly.
	- [ ] Query params align with backend contract.

---

2025-08-10 Delta

- Layout: Side-by-side web layout implemented. Providers + filters on the left; a compact, scroll-minimized categories panel on the right with expandable groups. Stacked fallback below 1100px.
- Sorting: Weighted rating sort (Bayesian prior) added to mock sorting to prefer many good reviews over very few perfect ones.
- Localization: Language names localized in Arabic UI (e.g., Hebrew -> عبري) while keeping provider names as originally written for consistency.
- Data coverage: Expanded mock providers to guarantee at least one provider per service with realistic Arabic/English names and varied cities.




## 2025-08-10 Roadmap & Open Issues

### Responsiveness Problem Between 1249px and 1091px
- In this width range, buttons overflow and break the layout. Responsive design needs to be fixed for this range.

### Below 1091px Issue
- When width drops below ~1091px, the page reverts to the old stacked layout (categories on top, providers below). This is not correct for mobile. Implement a more suitable mobile design instead of reverting to the old layout.

### Language-Based Layout Direction
- When the interface is in Arabic, categories should appear on the right and providers on the left.
- When in English, categories should be on the left and providers on the right.
- The layout direction should switch based on the language.

### Turkish Language Option
- Consider removing the “Turkish” language option for providers, as it may not be relevant for the Palestinian user base.

### Menu Logo Placement
- The "PALHANDS" logo should always be on the left side of the menu, regardless of language direction.
- Menu buttons should always be on the right.
- The site name is never translated and always remains in English, so it should always stay on the left.

---

### Ongoing/Future Discussion Topics
- Backend: Implement /services/providers endpoint with rating.average, rating.count, and server-side weighted rating.
- Pagination and infinite scroll for providers grid.
- Debounce filter changes for better UX.
- Empty-state messaging for no providers found.
- AND/OR toggle for multi-service selection.
- Price range filter.
- Detection and curation of new services.
- i18n strings file cleanup (resolve duplicate keys in app_strings.dart).
- Wire Book/Chat actions to booking/messaging flows.
- Visual polish and QA based on the above checklist.


## 2025-08-10 — Actionable To‑Do (Service tab)

This checklist translates the reported issues into concrete tasks with acceptance criteria and exact touch points in code.

1) Fix overflow between 1249px and 1091px
- Files: `frontend/lib/features/categories/presentation/pages/widgets/web_category_widget.dart` (filter bar + wide layout), `frontend/lib/shared/services/responsive_service.dart` (breakpoints)
- Changes
	- In `_buildFilterBar(...)` on web: treat widths < 1200 as "narrow" so the controls switch from a single Row to a Wrap earlier. Today threshold is 900; raise to 1200.
	- Make each control container Flexible to avoid intrinsic width overflow; ensure buttons have minWidth and text can ellipsize.
	- Reduce horizontal padding from 40 to 24 when constraints < 1200 to gain space.
	- Verify categories side panel maxWidth (currently 420) doesn’t pinch the provider column; at 1100–1248 allow it to shrink to ~360–380.
- Accept when: no Overflow/RenderFlex errors in 1248, 1200, 1140 px; controls wrap onto two lines gracefully.

2) Proper mobile/tablet layout below ~1091px (use the recommended style in the screenshot)
- Files: same as above + `mobile_category_widget.dart` if we keep dedicated mobile page
- Changes (WebCategoryWidget for <= 1100 width)
	- Replace the full categories grid with a single pill button "Our Services" (icon + text) placed beside filters. Tapping opens an expandable/bottom-sheet style selector (reuse the category panel logic as a dialog).
	- Order of sections: Filters row (Location, Sort, Reset, + Our Services), then Providers list; do NOT show the old categories grid on small widths.
- Changes (MobileCategoryWidget)
	- Hide the categories grid by default; show the same "Our Services" pill which opens the existing bottom sheet `_showCategoryDetails(...)` for selection.
	- Keep providers visible immediately after filters to match the mock.
- Accept when: at 1090, 900, 768, 480 px, the layout shows Filters + Our Services button on top and Providers immediately; no manual scroll-through grid needed.

3) Language-based layout direction (categories vs providers column)
- Files: `web_category_widget.dart`
- Changes
	- In the wide Row layout (>= 1100), flip child order based on language: if Arabic (RTL), categories panel on the right, providers on the left; if English, categories left, providers right.
	- Keep Directionality from `LanguageService.textDirection` for internal widgets, but do not rely on it alone for row order.
- Accept when: toggling language swaps columns while preserving internal RTL for text/controls.

4) Turkish language option visibility
- Files: `web_category_widget.dart`, `mobile_category_widget.dart`, or a small config in `LanguageService`
- Changes
	- Add a simple toggle (e.g., `LanguageService.showTurkishLanguageOption = false`) and filter it out of the provider languages display if disabled.
	- Do not modify provider stored data; only hide in UI.
- Accept when: Turkish doesn’t show on provider cards if the toggle is off; other languages remain intact.

5) Regression tests and polish
- Add viewport QA list (see Deep Review below) and verify no loss in accessibility or RTL behavior.
- Smoke test for provider fetch after each selection change.


## Implementation Notes (where/how)

- Breakpoint alignment
	- `ResponsiveService`: keep canonical breakpoints; we’ll primarily gate compact behavior from 1200 downwards for the filter bar and from 1100 for the two-column split.
- Web wide/stacked switch
	- In `web_category_widget.dart`, `LayoutBuilder` currently uses `wide = maxWidth >= 1100`. Keep 1100, but change the narrow branch to show Filters + Our Services button + Providers (no category grid).
	- For the 1249–1091 band, inside `_buildFilterBar` compute `isNarrow` with a larger threshold (e.g., `< 1200`) and switch to Wrap.
- Our Services button
	- Style: Outlined, rounded pill, small filter icon; label localized via `AppStrings.getString('ourServices', lang)`.
	- On tap: open existing `_buildCategoriesPanel` as a dialog (web) or reuse the mobile bottom sheet. The selection state is already stored in `_selectedServices`.
- RTL flip
	- In the wide Row: choose children order with `languageService.currentLanguage == 'ar' ? [providers, spacer, panel] : [panel, spacer, providers]` to match the requirement.
- Hide Turkish option
	- In `_localizedLanguages`, filter out `turkish` when a config flag is false. Surfacing the flag from `LanguageService` keeps it app-wide.


## Deep Review / QA Checklist (run after implementation)

Viewports to test
- Desktop: 1600, 1440, 1366, 1280
- Band-of-interest: 1248, 1200, 1140, 1100
- Tablet: 1024, 900, 820
- Mobile: 768, 600, 480, 360

Functional
- [ ] Multi-select services persists across dialog/bottom sheet closes and updates providers (without page reload).
- [ ] Location dropdown filters correctly; Reset returns to rating-desc default.
- [ ] Our Services button opens selector; selections reflect as chips; removing chips removes filters.

Layout/Responsiveness
- [ ] No overflow in 1249–1091px band; controls wrap neatly; paddings appropriate.
- [ ] Below 1100px: categories grid is hidden; only button is shown; providers visible immediately.
- [ ] Card grids: 3/2/1 columns as width decreases; aspect ratios remain readable.

RTL/i18n
- [ ] Arabic: categories panel on the right, providers left, copy direction RTL.
- [ ] English: categories left, providers right, LTR.
- [ ] All labels localized; chips and dropdowns follow Directionality.

Content rules
- [ ] If configured off, Turkish language is not displayed in provider chips/metadata.
- [ ] No unintended truncation of essential texts; ellipsis used where necessary.

Performance/UX
- [ ] Dialog/bottom sheet opens quickly; no jank when toggling many services.
- [ ] Network calls are debounced or fast enough; mock data fallback still works.


## What we’ve discussed so far (recap)
- Multi-select, city, sort, reset; OR semantics for service filters.
- Side panel of categories on wide screens; smaller screens prefer a single entry point via an Our Services button, not a large grid.
- Full RTL support plus explicit column order change by language.
- Provider cards include rating, years, languages, hourly, chips, and actions.
- Known pain point: overflow between ~1249 and 1091 widths; grid + filter controls collisions.
- Optional product decision: hide Turkish language in UI for Palestine-focused rollout.


## What we’ll discuss next
- Finalize exact narrow threshold for filter Wrap (1200 vs 1180) after QA.
- Whether to persist chosen filters in URL params for shareability.
- Server-side paging and sorting to align with frontend expectations.
- Visual design pass for the Our Services button and modal to match the provided mock exactly (spacing, iconography).

