# Rivne Supermarket Discounts — Product & Architecture Plan

> Scope for this iteration: **Сільпо (Silpo) only**. АТБ, Наш край, Новус, Сімі are deliberately
> deferred, but every domain/data shape below is designed so adding them later is a pure addition
> (new scraper module + new `SupermarketEnum` value), never a rewrite.

## 1. Vision & scope

Build a Flutter Web PWA that shows aggregated, de-duplicated discount data for supermarkets in
Rivne, Ukraine. A backend scraper does the actual data extraction (the Flutter Web app can't call
Silpo's API directly from the browser — no CORS headers for arbitrary origins, and it's not that
kind of public API), caches normalized results, and serves them over a small REST API. v1 ships
with a single data source (Silpo) end-to-end: scraper → cache → API → Flutter UI, so the whole
pipeline is proven before more scrapers are bolted on.

Non-goals for v1: user accounts, price-history charts, push notifications, multi-city support.

## 2. Reconnaissance summary (Silpo)

This section was re-verified with a real terminal spike (not just secondary sources) — every
claim below is a reproduced `curl`/Node result, not a guess. See §2.4 for the winning approach.

### 2.1 The main website is behind a Cloudflare bot check — and UA-spoofing makes it *worse*

`GET https://silpo.ua/offers` with a spoofed Chrome `User-Agent` header reliably returns
**HTTP 403** (`cf-mitigated: challenge`, `server: cloudflare`, CSP referencing
`challenges.cloudflare.com`). This was reproduced three times in a row with plain `curl` and
independently with Node's `undici`/`fetch` — 100% consistent.

The counter-intuitive finding: switching to an **honest, non-spoofed `User-Agent`** (curl's own
default `curl/8.5.0`, or even no `User-Agent` header at all) makes the *exact same request* return
**HTTP 200** with the real page, consistently, on both `/offers`, `/offers/vyshukuvach-znyzhok`,
and `/offers/cinotyzhyky`. Cloudflare's bot heuristics appear to flag the mismatch between a
"real browser" UA string and a non-browser TLS/HTTP2 fingerprint far more aggressively than they
flag a client that's honest about not being a browser. **Practical rule for this project: never
set a browser-like `User-Agent` on plain HTTP requests to `silpo.ua`.** No headless browser is
needed to get past this layer at all.

However — this only gets you the *page shell*. Inspecting the fetched `/offers` HTML (3.2 MB)
found zero price-like tokens and no product data anywhere, including inside the one large
server-state script tag (`<script id="serverApp-state">`, ~2.8 MB of feature-flags/branch/delivery
config, not products). The actual discount cards are populated client-side via XHR after page
load — so passing the Cloudflare check on the HTML pages doesn't actually yield discount data,
it just proves the UA-honesty trick works. The real data comes from §2.3.

### 2.2 `pysilpo` / `api.catalog.ecom.silpo.ua` — dead ends, deprioritized

- `pysilpo` (unofficial OSS client) wraps the **personal loyalty/cheque account** GraphQL API
  (`graphql.silpo.ua`), gated behind phone-number OTP login — a different system (purchase
  history for a logged-in shopper), not applicable here.
- `POST https://api.catalog.ecom.silpo.ua/api/2.0/exec/EcomCatalogGlobal` (the endpoint named in
  secondary sources) times out after ~8s (`HTTP 408`) on every attempt in this spike, with a
  plausible `filialId`. Not reliable enough to build on without further investigation — deprioritized
  in favor of §2.3, which works today.

### 2.3 The winning approach: `sf-ecom-api.silpo.ua` — a real, unprotected REST API

`https://sf-ecom-api.silpo.ua` sits behind a **different** gateway than the main site and shows
**no Cloudflare bot-check behavior at all** — verified with a spoofed Chrome UA, curl's default
UA, and *no* `User-Agent` header whatsoever; all three returned `HTTP 200`. Five rapid consecutive
requests all succeeded in ~1-1.5s each with no throttling observed.

**Branch discovery** — `GET /v1/uk/branches?limit=1000` returns all 451 Silpo branches
(`branchId`, `externalId`, `cityFull`, `addressFull`, lat/long, opening hours, `hasPickup`,
`open`). Filtering client-side for `cityFull == "Рівне"` found **5 real Rivne branches**, e.g.:

| branchId | externalId | address |
|---|---|---|
| `1edb6b55-2691-60a6-b134-d54e0a9fe643` | 2092 | вул. Київська, 69 |
| `1edb6b56-9cd8-6768-8cc8-d11f2666a570` | 2105 | вул. Гагаріна, 16 |
| `1edb733d-85e4-686a-87c9-d5cf071d641d` | 2980 | вул. Короленка, 1 |
| `1edf2fda-fcea-6132-badc-838af09f7cce` | 3255 | вул. Бачинського Сергія, 5 |
| `1f077701-19e8-6e6a-9a7a-a70cdbaf9082` | 4197 | вул. Бачинського, 5 |

**Product/discount data** — `GET /v1/uk/branches/{branchId}/products` requires at least one of:
`products, productsIds, productsSlugs, category, set, mustHavePromotion, search, searchV2,
offersIds, isFavorite, isCarousel, promoId, categoriesSlugs` (this exact list came straight back
in a `400` validation error — i.e. it's the API's own documentation of its filter surface).
Calling it with **`mustHavePromotion=true`** returns exactly what we need:

```
GET https://sf-ecom-api.silpo.ua/v1/uk/branches/1edb6b55-2691-60a6-b134-d54e0a9fe643/products?limit=100&offset=0&mustHavePromotion=true
```

→ `HTTP 200`, `{"limit":100,"offset":0,"total":5673,"items":[...]}` — **5,673 discounted products**
in that single Rivne branch alone. Each item looks like:

```json
{
  "id": "1f124c8b-f1cd-6cee-a5aa-05a95385752f",
  "title": "Батончики сиркові глазуровані Злагода Кокос з ароматом карамелі 23%",
  "icon": "b6ee3733-01f8-4398-863d-3202fdd6ccb1.png",
  "price": 44.99,
  "oldPrice": 69.99,
  "displayPrice": 44.99,
  "displayOldPrice": 69.99,
  "ratio": "шт",
  "displayRatio": "6*20г",
  "slug": "batonchyky-syrkovi-glazurovani-zlagoda-kokos-z-aromatom-karameli-23-1020259",
  "sectionSlug": "glazurovani-syrky-4992",
  "externalProductId": 1020259,
  "branchId": "1edb6b55-2691-60a6-b134-d54e0a9fe643",
  "promotions": [{"id": "cinotyzhyky", "type": "promo", "iconPath": "https://content.silpo.ua/hermes/MediaBubbles/MP/1_site.svg"}],
  "createdAt": "2026-04-30T13:42:35+00:00",
  "stock": 14
}
```

This maps almost 1:1 onto the `Discount` shape in §4 (`title`→`productName`, `price`/`oldPrice`→
`discountedPrice`/`originalPrice`, `sectionSlug`→`category`, `ratio`/`displayRatio`→`unit`,
`slug`+branch→`sourceUrl`). `icon` is a bare filename — the CDN base URL to prefix it with (a
`content.silpo.ua`-style host, by analogy with `promotions[].iconPath` above) needs a one-time
confirmation in Phase 1 of the impl plan before it's used in production.

Pagination: `offset`/`limit` as expected, `total` given up front; `limit` accepts up to (at least)
500 in testing, `1000` was rejected with a `range.not_in_range` validation error — page in chunks
of ≤500. A bare `search=<term>` query without a compatible companion param returned an empty body
(`400`) — not needed since `mustHavePromotion` already targets exactly the discount subset we
want, so this wasn't pursued further.

### 2.4 Conclusion — no headless browser needed at all

Contrary to the original plan's assumption, **Playwright/a headless browser is not required** for
Silpo. The whole pipeline works with a plain HTTP client (Node's built-in `fetch`/`undici`,
`axios`, whatever) as long as:
1. Requests to `silpo.ua` itself (if ever needed) don't send a browser-spoofing `User-Agent`.
2. All actual data collection goes through `sf-ecom-api.silpo.ua`, which has no bot-check at all.

This eliminates an entire category of fragility (Cloudflare challenge solving, browser binary
management, headless-detection arms race) from the backend design in §5.

No official public API / developer portal / published rate limits or ToS exist for
`sf-ecom-api.silpo.ua` either — it's still an undocumented internal API that Silpo's own frontend
happens to call, and it can change shape without notice. The resilience posture in §5 (retries,
zero-result alerting, conservative polling) still applies in full; what's changed is *how* the
scraper talks to Silpo, not the need to stay defensive about it.

## 3. System architecture

```
┌─────────────────────┐     ┌───────────────┐     ┌──────────┐     ┌─────────────────┐     ┌────────────────────┐
│ HTTP scraper         │────▶│  Normalizer   │────▶│  SQLite  │────▶│  REST API        │────▶│ Flutter Web (Wasm)  │
│ (scheduled job,      │     │  (raw → Disc- │     │  (cache) │     │  (Express/       │     │ PWA — flutter_bloc  │
│  plain fetch/axios   │     │   ountEntity  │     │          │     │   Fastify)       │     │ Clean Architecture  │
│  against sf-ecom-api)│     │   shape)      │     │          │     │  GET /discounts  │     │                     │
└─────────────────────┘     └───────────────┘     └──────────┘     └─────────────────┘     └────────────────────┘
```

No headless browser sits in this pipeline (see §2.4) — the scraper is a plain HTTP client hitting
`sf-ecom-api.silpo.ua` directly. It never runs synchronously in response to a frontend request —
it's a scheduled job that populates the cache; the API only ever reads from SQLite. This keeps the
user-facing app fast and decoupled from scrape latency/failures.

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

## 5. Backend plan (Node.js + TypeScript, plain HTTP — no browser)

- **Branch resolution**: on startup (or on a slow cache, e.g. weekly), call
  `GET https://sf-ecom-api.silpo.ua/v1/uk/branches?limit=1000`, filter for `cityFull === "Рівне"`,
  store the resulting branch IDs (see §2.3 table) as config rather than hardcoding — Silpo can add
  a branch or renumber one without warning.
- **Data acquisition**: for each configured Rivne `branchId`, page through
  `GET /v1/uk/branches/{branchId}/products?mustHavePromotion=true&limit=500&offset=N` until
  `offset >= total`. No cookies, no session, no browser — a plain `fetch`/`axios` call with a
  normal (non-spoofed) UA is sufficient (§2.3/§2.4).
- **Normalization**: raw item → `Discount[]` per §4 — `title`→`productName`,
  `price`/`displayPrice`→`discountedPrice`, `oldPrice`/`displayOldPrice`→`originalPrice`,
  `sectionSlug`→`category`, `displayRatio`/`ratio`→`unit`, `slug`→`sourceUrl`
  (`https://silpo.ua/product/{slug}`), `icon`→`imageUrl` (prefixed with the CDN base confirmed in
  Phase 1), `discountPercent` computed as `round((1 - price/oldPrice) * 100)`. Drop items missing
  `price`/`oldPrice`/`title`, log a warning, don't crash the run.
- **Storage**: SQLite (`better-sqlite3`), single `discounts` table keyed by `id`, upsert on each
  scrape run so stale items naturally get replaced; keep a `scrape_runs` table (timestamp, item
  count, status) for observability.
- **Scheduling**: cron-style job (e.g. `node-cron`), conservative cadence (a few runs/day, not
  continuous polling) — no published rate limits observed (§2.3 showed no throttling across 5
  rapid requests, but that's not a license to hammer it), so default to being a polite scraper.
- **REST API**: `GET /discounts` (filters: `supermarket`, `category`, pagination via
  `limit`/`offset`), `GET /health`. Read-only, straight off SQLite — no live scraping in the
  request path.
- **Resilience**: retry transient network errors with backoff; if a scrape run yields zero items,
  log/alert loudly (likely means the endpoint shape or the `mustHavePromotion` filter changed)
  rather than silently wiping the cache — keep serving the last good data until a run succeeds.

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

- `sf-ecom-api.silpo.ua` is still an undocumented internal API — it can change its response shape,
  add auth requirements, or start rate-limiting at any time with no notice, no SLA, no docs.
  Mitigate with the retry/alerting strategy in §5, not by assuming stability. If it ever starts
  bot-checking too, the DOM/XHR-interception fallback in the original plan (Playwright against
  `/offers*`) is the documented fallback path, not a rewrite.
- No published ToS/rate-limit guidance for automated access — even though no throttling was
  observed in a 5-request burst, default to low-frequency, polite scraping (a handful of runs per
  day) to minimize risk and load.
- The image CDN base URL for the `icon` filename field is not yet confirmed empirically (see
  §2.3) — needs a one-time check in Phase 1 before `imageUrl` normalization is correct.
- Everything in §2.3 was verified today (2026-07-15) directly against production — but "verified
  today" for an undocumented API is not the same as "stable," so Phase 2's zero-result alerting
  matters more here than it would against a documented, versioned API.
