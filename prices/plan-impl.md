# Rivne Supermarket Discounts — Phased Implementation Plan

Scope: **Сільпо only**. Each phase ends with an explicit checkpoint — stop and get sign-off
before starting the next phase, per the original brief ("give me the plan, wait for approval,
execute step by step").

See `prices/plan.md` for the full architecture/data-model rationale behind each step below.

---

## Phase 0 — Recon (done)

Confirmed via `curl` that `silpo.ua` sits behind an active Cloudflare Turnstile challenge (403,
`cf-mitigated: challenge`) when a browser-spoofing `User-Agent` is used. Identified two candidate
reverse-engineered JSON endpoints and a DOM-scrape fallback path over `/offers*` pages. Full
writeup: `prices/plan.md` §2 (original version).

**Checkpoint:** ✅ complete.

---

## Phase 1 — Scraper spike — ✅ done, findings below

Goal was: answer the one open question that determines the rest of the backend design — *can we
reach Silpo's product/discount data without a headless browser?*

**Result: yes.** Re-verified with a live terminal spike (not secondary sources) on 2026-07-15:

1. Confirmed `silpo.ua` 403s a spoofed-Chrome-UA request but returns 200 for the same request with
   an honest/curl UA — reproduced 3x with curl, reproduced independently with Node `fetch`/`undici`
   (3 UA variants tested, consistent results both times). See `prices/plan.md` §2.1.
2. Confirmed the `/offers*` HTML pages carry **no product data** server-side (checked the full
   2.8 MB `serverApp-state` blob and the rendered HTML for price-like tokens — zero matches) — so
   even with the UA fix, HTML scraping of those pages was a dead end for actual discount data.
3. Confirmed `api.catalog.ecom.silpo.ua/api/2.0/exec/EcomCatalogGlobal` times out (`HTTP 408`)
   consistently — deprioritized.
4. **Found the real data source**: `sf-ecom-api.silpo.ua` has no Cloudflare bot-check at all
   (works with any UA, including none). `GET /v1/uk/branches?limit=1000` returns all 451 branches;
   filtering for `cityFull === "Рівне"` gives 5 real branch IDs (recorded in `plan.md` §2.3).
   `GET /v1/uk/branches/{branchId}/products?mustHavePromotion=true&limit=500&offset=N` returns
   real, structured discount data — 5,673 promotional items in one Rivne branch alone, full
   product/price/category/image schema. Full request/response detail in `plan.md` §2.3.

**No headless browser is needed anywhere in this pipeline** — this simplifies Phase 2
significantly versus the original Playwright-based plan.

**Remaining open item carried into Phase 2**: confirm the image CDN base URL to prefix the bare
`icon` filename with (by analogy to `promotions[].iconPath`, likely a `content.silpo.ua` host —
needs a quick empirical check, e.g. fetching a candidate URL and confirming it 200s with an
image).

**Checkpoint:** ✅ findings above are the deliverable for this phase — proceed to Phase 2 with the
plain-HTTP `sf-ecom-api` approach, no fallback path needed unless it breaks later (see
`plan.md` §8 for the documented fallback if it ever starts bot-checking).

---

## Phase 2 — Scraper hardening

Goal: turn the Phase 1 spike into a repeatable, normalized data pipeline.

Steps:
1. `prices/backend/` — scaffold a Node.js + TypeScript project (plain `fetch`/`axios`, no
   Playwright dependency needed per Phase 1 findings).
2. `src/scraper/branches.ts` — fetch `GET /v1/uk/branches?limit=1000`, filter for Rivne, cache the
   5 branch IDs from `plan.md` §2.3 as config (refresh weekly, don't hardcode permanently).
3. `src/scraper/products.ts` — page through
   `GET /v1/uk/branches/{branchId}/products?mustHavePromotion=true&limit=500&offset=N` per branch
   until `offset >= total`.
4. `src/scraper/normalize.ts` — raw item → `Discount[]` per `plan.md` §4/§5 field mapping,
   confirm and hardcode the image CDN base URL (Phase 1's one remaining open item), compute
   `discountPercent`, drop malformed items with a warning log.
5. Set up SQLite (`better-sqlite3`) with a `discounts` table (upsert by `id`) and a `scrape_runs`
   table (timestamp, item count, status) for observability.
6. Add a scheduled job runner (`node-cron`) at a conservative cadence (e.g. 2-4 runs/day).
7. Add minimal alerting/logging: a run that yields 0 items logs an error-level warning instead of
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
