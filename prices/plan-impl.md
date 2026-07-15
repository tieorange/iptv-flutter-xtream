# Rivne Supermarket Discounts — Phased Implementation Plan

Scope: **Сільпо only**. Each phase ends with an explicit checkpoint — stop and get sign-off
before starting the next phase, per the original brief ("give me the plan, wait for approval,
execute step by step").

See `prices/plan.md` for the full architecture/data-model rationale behind each step below.

---

## Phase 0 — Recon (done)

Confirmed via `curl` that `silpo.ua` sits behind an active Cloudflare Turnstile challenge (403,
`cf-mitigated: challenge`). Identified two candidate reverse-engineered JSON endpoints
(`EcomCatalogGlobal`, `sf-ecom-api`) and a DOM-scrape fallback path over `/offers*` pages. Full
writeup: `prices/plan.md` §2.

**Checkpoint:** ✅ complete — this document and `plan.md` are the output.

---

## Phase 1 — Scraper spike (validation, throwaway-quality code OK)

Goal: answer the one open question that determines the rest of the backend design — *can a
Playwright-harvested session call the reverse-engineered catalog API directly, or do we need to
scrape rendered pages?*

Steps:
1. `prices/backend/` — scaffold a minimal Node.js + TypeScript project with Playwright installed.
2. Write a script that launches Chromium, navigates to `silpo.ua`, waits for the Cloudflare
   challenge to clear, and captures cookies.
3. Using that session/cookies, attempt a direct `POST` to `EcomCatalogGlobal` (and/or `GET` to
   `sf-ecom-api`) for a known Rivne branch — first find a valid `filialId`/`branchId` for a Rivne
   store (likely discoverable via the site's store-locator UI or by inspecting network calls made
   when browsing `silpo.ua` with a Rivne location selected).
4. If step 3 works reliably (not challenged): that's the primary data path.
5. If step 3 keeps getting challenged: instead navigate `/offers`, `/offers/vyshukuvach-znyzhok`,
   `/offers/cinotyzhyky` in Playwright, intercept network responses (`page.on('response')`) for
   JSON payloads, or extract embedded state/JSON from the rendered HTML.
6. Write findings to `prices/backend/RECON.md`: which strategy works, the exact request/response
   shapes observed, the Rivne branch ID(s) found, and any Cloudflare quirks (challenge frequency,
   cookie lifetime, whether headless vs headed matters).

**Checkpoint:** share `RECON.md` findings before building the real scraper — the chosen strategy
(direct API vs DOM scrape) changes the Phase 2 implementation shape.

---

## Phase 2 — Scraper hardening

Goal: turn the Phase 1 spike into a repeatable, normalized data pipeline.

Steps:
1. Implement the chosen acquisition strategy as a proper module (`prices/backend/src/scraper/`).
2. Normalize raw results into the `Discount` shape from `plan.md` §4 (price parsing, discount %
   calculation, dropping malformed items with a warning log).
3. Set up SQLite (`better-sqlite3`) with a `discounts` table (upsert by `id`) and a `scrape_runs`
   table (timestamp, item count, status) for observability.
4. Add a scheduled job runner (`node-cron`) at a conservative cadence (e.g. 2-4 runs/day).
5. Add minimal alerting/logging: a run that yields 0 items logs an error-level warning instead of
   wiping the cache; the last good data keeps serving.

**Checkpoint:** demo a manual scrape run populating SQLite with real Silpo discount rows for at
least one Rivne branch.

---

## Phase 3 — REST API

Goal: expose the cached data to the frontend.

Steps:
1. Express or Fastify app in `prices/backend/src/api/`.
2. `GET /discounts` — filters (`supermarket`, `category`), pagination (`limit`/`offset`), reads
   only from SQLite (never triggers a live scrape).
3. `GET /health`.
4. Basic tests (supertest or equivalent) covering filtering/pagination edge cases.

**Checkpoint:** API returns real scraped Silpo data over HTTP; demo with `curl`/Postman.

---

## Phase 4 — Flutter skeleton

Goal: stand up the Clean Architecture shell with no real UI yet beyond a smoke-test screen.

Steps:
1. `flutter create` inside `prices/app/`, target web, add `flutter_bloc`, `go_router`, `get_it`,
   `fpdart`, `dio`, `equatable`.
2. Build `lib/core/` (DI, router, dark theme with Silpo-orange accent, network client, `Failure`
   hierarchy) mirroring this repo's existing `lib/core/` conventions.
3. Build `lib/features/discounts/domain/` (`DiscountEntity`, `SupermarketEnum`,
   `DiscountsRepository` interface) and `lib/features/discounts/data/` (DTO, mapper, remote data
   source, repository impl) wired to the Phase 3 API.
4. Configure `flutter build web --wasm` and a `web/manifest.json` for PWA installability.

**Checkpoint:** app builds for web/Wasm and boots to an empty shell with dark theme applied.

---

## Phase 5 — Feed UI

Goal: end-to-end working feed.

Steps:
1. `DiscountsFeedCubit` (loading/loaded/error, pagination) in
   `lib/features/discounts/presentation/`.
2. List/grid widget consuming the cubit, showing product name, prices, discount %, image,
   Silpo-orange accent badge.
3. Wire into `go_router` as the home route.

**Checkpoint:** live demo — real scraped Silpo discounts rendered in the Flutter Web app.

---

## Phase 6 — Polish

Goal: production-feel pass.

Steps:
1. Responsive breakpoints (mobile single-column ↔ desktop grid).
2. Loading skeletons / error states / empty states.
3. `SupermarketFilterCubit` + filter UI — functionally Silpo-only today, but built
   supermarket-aware (chip list already includes reserved slots for ATB/Novus/etc., disabled or
   hidden until those scrapers exist).
4. PWA install prompt / icons / splash.

**Checkpoint:** final review against the original brief's Laws 1-4 before considering v1 "done."

---

## Explicitly out of scope for this pass

- АТБ, Наш край, Новус, Сімі scrapers — architecture supports adding them later as new modules,
  not attempted now.
- User accounts, favorites, price history, notifications.
- Postgres migration — SQLite is sufficient until more supermarkets are added (see `plan.md` §5).
