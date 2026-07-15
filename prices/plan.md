# Rivne Supermarket Discounts — Product & Architecture Plan

> Scope for this iteration: **Сільпо (Silpo) only**. АТБ, Наш край, Новус, Сімі are deliberately
> deferred, but every domain/data shape below is designed so adding them later is a pure addition
> (new scraper module + new `SupermarketEnum` value), never a rewrite.

## 1. Vision & scope

Build a Flutter Web PWA that shows aggregated, de-duplicated discount data for supermarkets in
Rivne, Ukraine. A backend scraper does the actual data extraction (browsers don't get to talk to
these sites directly — see §2), caches normalized results, and serves them over a small REST API.
v1 ships with a single data source (Silpo) end-to-end: scraper → cache → API → Flutter UI, so the
whole pipeline is proven before more scrapers are bolted on.

Non-goals for v1: user accounts, price-history charts, push notifications, multi-city support.

## 2. Reconnaissance summary (Silpo)

Verified directly against `silpo.ua` from this environment (`curl` with a real browser
`User-Agent`):

- `GET https://silpo.ua/offers` → **HTTP 403**. Response headers show `cf-mitigated: challenge`,
  `server: cloudflare`, and a CSP referencing `challenges.cloudflare.com` — this is a live
  Cloudflare Turnstile/JS challenge, not a simple WAF rule. Plain HTTP clients (curl, `fetch`,
  `axios`, Python `requests`, Cheerio/BeautifulSoup on their own) cannot pass this; they need a
  real browser engine executing JS to solve the challenge and mint a `cf_clearance` cookie.
- A reverse-engineered ecommerce catalog API exists:
  - `POST https://api.catalog.ecom.silpo.ua/api/2.0/exec/EcomCatalogGlobal`
    Body: `{"method":"GetSimpleCatalogItems","data":{"customFilter":"<search term>","filialId":"<store id>","skuPerPage":100,"pageNumber":1}}`
    Header: `Content-Type: application/json;charset=UTF-8`.
  - Alternate REST-shaped endpoint: `GET https://sf-ecom-api.silpo.ua/v1/uk/branches/{branchId}/products`
    with query params `limit`, `offset`, `deliveryType`, `category`, `includeChildCategories`,
    `sortBy`, `sortDirection`.
  - Both are **undocumented** (found via community write-ups, not official docs) and likely sit
    behind the same Cloudflare edge as the main site — a request without a valid
    browser-derived session/cookie almost certainly gets challenged too. This needs empirical
    confirmation (Phase 1 of the impl plan) rather than being assumed.
- `pysilpo` (unofficial OSS client) wraps the **personal loyalty/cheque account** GraphQL API
  (`graphql.silpo.ua`), gated behind phone-number OTP login. That's a different system (purchase
  history for a logged-in shopper) and not applicable to scraping public catalog/discount data —
  no user account is needed for this project.
- No official public API, no developer portal, no published rate limits or ToS for automated
  access. Treat every endpoint/selector as liable to change without notice.
- Human-facing discount pages worth targeting if the direct-API route fails: `/offers`,
  `/offers/vyshukuvach-znyzhok` (discount finder), `/offers/cinotyzhyky` (weekly prices, updated
  Thursdays), `/catalog/den-dovhyy`, `/offers/other`.

**Conclusion:** the scraper must drive a real headless browser (Playwright) to clear Cloudflare
and obtain a session, then prefer calling the reverse-engineered JSON endpoints directly with that
session (fast, structured); if those still get challenged per-request, fall back to scraping the
rendered `/offers*` pages — either their DOM or JSON blobs/XHR responses captured via Playwright's
network interception while the page loads naturally in-browser.

## 3. System architecture

```
┌─────────────────────┐     ┌───────────────┐     ┌──────────┐     ┌─────────────────┐     ┌────────────────────┐
│ Playwright scraper   │────▶│  Normalizer   │────▶│  SQLite  │────▶│  REST API        │────▶│ Flutter Web (Wasm)  │
│ (scheduled job,      │     │  (raw → Disc- │     │  (cache) │     │  (Express/       │     │ PWA — flutter_bloc  │
│  Silpo session +     │     │   ountEntity  │     │          │     │   Fastify)       │     │ Clean Architecture  │
│  catalog/DOM scrape) │     │   shape)      │     │          │     │  GET /discounts  │     │                     │
└─────────────────────┘     └───────────────┘     └──────────┘     └─────────────────┘     └────────────────────┘
```

The scraper never runs synchronously in response to a frontend request — it's a scheduled job
that populates the cache; the API only ever reads from SQLite. This keeps the user-facing app fast
and decoupled from Cloudflare/scrape latency and failures.

## 4. Normalized `Discount` data model

Every current and future supermarket scraper must emit this exact shape so the rest of the
pipeline is supermarket-agnostic:

```ts
type SupermarketId = "silpo" | "atb" | "nash_krai" | "novus" | "simi"; // only "silpo" active in v1

interface Discount {
  id: string;                 // stable hash of supermarketId + sourceProductId
  supermarketId: SupermarketId;
  productName: string;
  category: string | null;
  imageUrl: string | null;
  originalPrice: number;      // in UAH
  discountedPrice: number;    // in UAH
  discountPercent: number;    // derived, rounded
  unit: string | null;        // "кг", "шт", "л", ...
  validFrom: string | null;   // ISO date
  validTo: string | null;     // ISO date
  sourceUrl: string | null;
  scrapedAt: string;          // ISO datetime
}
```

Mirrored on the Flutter side as `DiscountEntity` (domain layer, no JSON knowledge) and
`SupermarketEnum` (Dart enum with `silpo` plus reserved-but-unused values for the other four).

## 5. Backend plan (Node.js + TypeScript + Playwright)

- **Session bootstrap**: Playwright launches Chromium, navigates to `silpo.ua`, waits out the
  Cloudflare challenge, captures cookies (`cf_clearance` etc.) and relevant headers.
- **Data acquisition — try in order**:
  1. Reuse the harvested session to call `EcomCatalogGlobal` / `sf-ecom-api` directly for
     structured JSON (fastest, least brittle to layout changes).
  2. If direct calls are still challenged, navigate the `/offers*` pages in-browser and intercept
     the XHR/GraphQL responses Playwright observes, or parse `__NEXT_DATA__`/embedded JSON from
     the rendered HTML.
  3. Last resort: DOM scraping of rendered discount cards.
- **Normalization**: raw payload → `Discount[]` per §4, computing `discountPercent`, coercing
  price strings to numbers, dropping items missing required fields (log a warning, don't crash
  the run).
- **Storage**: SQLite (`better-sqlite3`), single `discounts` table keyed by `id`, upsert on each
  scrape run so stale items naturally get replaced; keep a `scrape_runs` table (timestamp, item
  count, status) for observability.
- **Scheduling**: cron-style job (e.g. `node-cron`), conservative cadence (a few runs/day, not
  continuous polling) — no published rate limits from Silpo, so default to being a polite
  scraper rather than an aggressive one.
- **REST API**: `GET /discounts` (filters: `supermarket`, `category`, pagination via
  `limit`/`offset`), `GET /health`. Read-only, straight off SQLite — no live scraping in the
  request path.
- **Resilience**: retry transient Playwright/network errors with backoff; if a scrape run yields
  zero items, log/alert loudly (likely means Cloudflare or the endpoint shape changed) rather than
  silently wiping the cache — keep serving the last good data until a run succeeds.

## 6. Flutter Clean Architecture plan

Reuses the proven `lib/core` + `lib/features/<feature>` split already established in this repo's
IPTV app (`lib/features/live_tv` is a good reference for the target shape).

```
prices/app/lib/
├── core/                     # DI (get_it), router (go_router), theme, network (dio/http), error/Failure
├── features/
│   └── discounts/
│       ├── domain/           # DiscountEntity, SupermarketEnum, DiscountsRepository (interface)
│       ├── data/              # DiscountDto + mapper, DiscountsRemoteDataSource, DiscountsRepositoryImpl
│       └── presentation/      # DiscountsFeedCubit, SupermarketFilterCubit, pages, widgets
└── main.dart
```

- **Domain**: pure Dart, zero external deps. `DiscountEntity`, `SupermarketEnum`
  (`silpo` active; `atb`, `nashKrai`, `novus`, `simi` reserved), `DiscountsRepository` abstract
  class.
- **Data**: `DiscountDto` (JSON-serializable) + mapper to `DiscountEntity`;
  `DiscountsRemoteDataSource` (thin `dio`/`http` wrapper around the backend's `GET /discounts`);
  `DiscountsRepositoryImpl` implementing the domain interface, returning `Either<Failure,
  List<DiscountEntity>>` (`fpdart`, matching this repo's existing convention).
- **Presentation**: `DiscountsFeedCubit` (loading/loaded/error states, pagination),
  `SupermarketFilterCubit` (single-select filter, pre-wired for 5 supermarkets even though only
  Silpo has data today), `go_router` route(s), responsive list/grid widgets.

## 7. Web/PWA requirements

- Compile target: **WebAssembly** (`flutter build web --wasm`).
- `web/manifest.json`: installable PWA metadata (name, icons, `display: standalone`,
  `theme_color`/`background_color` matching dark theme).
- Responsive layout: single-column card list on narrow viewports (iPhone-class), multi-column
  grid on desktop/tablet widths — one widget tree, `LayoutBuilder`/breakpoints, not separate
  mobile/desktop code paths.
- **Dark mode is the only theme for v1** (matches the brief's "Dark Mode Dictatorship" — no light
  theme toggle needed yet). Base palette: near-black background, high-contrast text, and a
  per-supermarket accent color used for that supermarket's cards/badges:
  - Silpo → orange (active)
  - ATB → red (reserved token, unused until ATB scraper ships)
  - Novus → green (reserved token)
  - Наш край / Сімі → reserved token slots, colors TBD when implemented.

## 8. Open risks

- Cloudflare configuration or the reverse-engineered endpoints can change at any time with no
  notice — no SLA, no docs. Mitigate with the retry/alerting strategy in §5, not by assuming
  stability.
- No published ToS/rate-limit guidance for automated access — default to low-frequency, polite
  scraping (a handful of runs per day) to minimize risk and load.
- `filialId`/`branchId` values (store selection) aren't yet known for Rivne specifically — Phase 1
  needs to locate the correct branch ID(s) for Rivne stores before the catalog filter is useful.
- Everything here beyond the confirmed 403/Cloudflare finding is based on secondary sources
  (community write-ups, not Silpo docs) — Phase 1's spike is what turns this from "plausible plan"
  into "verified approach."
