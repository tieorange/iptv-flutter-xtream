# AGENTS.md — Flutter IPTV Xtream Client

Guidance for any agent (Claude, Codex, etc.) working in this repo. See `PLAN.md` for the
original build brief and product framing; this file documents what actually got built, the
conventions to follow, and traps already found the hard way.

## What this is

A generic Xtream Codes IPTV client (Live TV / VOD / Series), iOS-first, Clean Architecture,
bundle id `com.tieorange.iptv`. Phase 1 (M0–M9, the full iOS MVP milestone list from `PLAN.md`)
is done. Phase 2 (PiP, EPG grid, parental lock, diagnostics) and Phase 3 (Android) are not
started.

## Stack

`flutter_bloc` (Cubit per feature, one full `Bloc` for search) · `get_it` (DI, no codegen) ·
`go_router` · `fpdart` (`TaskEither`/`Either`) · `xtream_code_client` v2 (Xtream API) ·
`video_player`+`chewie` (AVPlayer engine) · `media_kit`+`media_kit_video` (mpv fallback engine) ·
`flutter_to_airplay` · `flutter_secure_storage` (credentials) · `shared_preferences`
(favorites — not sensitive) · `dio`+`dio_smart_retry` (HLS probe only, plus the OpenAI client for
`ai_recommendations`) · `rxdart` (search debounce) · `bloc_test`+`mocktail` (tests).

## Repo map — `lib/` folder by folder

```text
lib/
  main.dart
  core/
    config/env.dart
    di/injection.dart
    error/failures.dart
    network/{api_client,retry_interceptor,scrubbing_log_interceptor,xtream_client_factory}.dart
    router/{app_router,auth_refresh_listenable,home_shell}.dart
    storage/{secure_storage,profile_local_store}.dart
    utils/url_scrubber.dart
  features/
    auth/  live_tv/  player/  vod/  series/  epg/  favorites/  search/  ai_recommendations/
```

### `lib/main.dart`

Entry point. Order matters: `MediaKit.ensureInitialized()` first (media_kit needs this before
any `Player()` is constructed anywhere in the app) → `configureDependencies()` →
`getIt<AuthCubit>().restoreActiveProfile()` (fire-and-forget; checks Keychain for a saved
session) → `runApp(IptvApp())`. `IptvApp` wraps `MaterialApp.router` in a single
`BlocProvider.value` for the app-wide `AuthCubit` singleton — every other Cubit/Bloc in the app
is created locally per-page via `BlocProvider(create: ...)`, not here.

### `lib/core/` — shared infrastructure, imported by every feature

- **`di/injection.dart`** — the entire `get_it` registration graph, one big
  `configureDependencies()` function. This is the map of the whole app: read it top-to-bottom to
  see every concrete wiring decision (what implements what, singleton vs factory). New feature →
  add its registrations here, grouped with a comment, roughly in dependency order (a repository's
  registration must be able to resolve its own datasource dependency, but `get_it` factory
  closures resolve lazily so strict ordering only matters for readability, not correctness).
- **`config/env.dart`** — build-time config read via `String.fromEnvironment`, e.g.
  `Env.openAiApiKey` / `Env.hasOpenAiApiKey`. Supplied with `--dart-define-from-file` (see
  `dart_define.example.json` at the repo root, and `dart_define.local.json` — gitignored, holds
  the real key). Never hardcode a real secret in this file or anywhere else in `lib/`.
- **`error/failures.dart`** — the sealed `Failure` hierarchy every repository returns instead of
  throwing: `NetworkFailure`, `AuthFailure`, `ParseFailure`, `CacheFailure`, `PlaybackFailure`,
  `UnknownFailure`, `AiFailure` (OpenAI-specific errors — missing key, 401/429, timeout,
  malformed response). Add a new subtype here if a genuinely new failure mode shows up; don't
  stringly-type errors elsewhere.
- **`network/api_client.dart`** — `buildApiClient()` builds the *one* shared plain `Dio` instance
  (registered as a singleton in `injection.dart`); its only real consumer is
  `HlsAvailabilityProbe`. The Xtream API calls themselves go through `xtream_code_client`'s own
  internal `http.Client`, not this `Dio`. The same file also has `buildOpenAiApiClient()` — a
  second, separately-configured `Dio` (OpenAI base URL, bearer auth header from `Env`, longer
  timeouts) registered under `instanceName: 'openAiDio'` in `injection.dart`, used only by
  `ai_recommendations`'s `OpenAiRemoteDataSource`.
- **`network/retry_interceptor.dart`** — thin wrapper around `dio_smart_retry`'s defaults
  (retries timeouts/connection errors/5xx/408/429 with backoff, never 4xx). Don't write a custom
  retry evaluator unless the defaults are proven wrong for a specific panel.
- **`network/scrubbing_log_interceptor.dart`** — debug-only `Dio` request-failure logger; always
  scrubs the URL first. This is a `Dio` interceptor, so it only sees `Dio` traffic — it does not
  see `XtreamClient`'s internal HTTP calls or `video_player`/`media_kit` errors, which is why
  `scrubMessage()` (see Security) also has to be applied manually at those other call sites.
- **`network/xtream_client_factory.dart`** — `XtreamClientFactory.forProfile(ProviderProfile)`
  builds an `XtreamClient` (from `xtream_code_client`) bound to one profile's
  baseUrl/username/password. Every feature's remote datasource (`LiveTvRemoteDataSource`,
  `VodRemoteDataSource`, `SeriesRemoteDataSource`, `EpgRemoteDataSource`) follows the exact same
  pattern: hold this factory + `AuthCubit`, lazily build and cache one `XtreamClient` keyed by
  `state.profile.id`, rebuild if the active profile changes. If you add a new feature that talks
  to the panel, copy this caching pattern rather than re-deriving it — see any existing
  `*_remote_datasource.dart`'s `_client()` method for the ~10-line template.
- **`router/app_router.dart`** — the single `GoRouter` instance and the entire route table (every
  route in the app is defined here, even though the page widgets themselves live in their
  feature folders). Also owns the one top-level `redirect` callback that reads `AuthCubit.state`
  to bounce between `/profiles` (unauthenticated) and `/home/*` (authenticated). Adding a page
  almost always means adding a `GoRoute` here, not just building the widget.
- **`router/auth_refresh_listenable.dart`** — bridges `AuthCubit`'s `Stream<AuthState>` to the
  `Listenable` that `GoRouter(refreshListenable: ...)` requires — Cubits expose streams, not
  `ChangeNotifier`s, so this glue is mandatory, not optional. Don't call
  `GoRouter.of(context).refresh()` manually from inside a Cubit; this listenable already does it.
- **`router/home_shell.dart`** — the authenticated `/home/*` bottom-nav shell
  (`StatefulShellRoute.indexedStack` wrapper: Live / VOD / Series / Search / Favorites tabs, each
  keeping its own navigation stack). Its `AppBar` has two actions: a sparkle icon
  (`Icons.auto_awesome`) that pushes the `aiPicks` route (`ai_recommendations` feature — not a
  6th bottom-nav tab, 5 is already the practical UX cap for `NavigationBar`), and the logout
  button.
- **`storage/secure_storage.dart`** — thin `FlutterSecureStorage` wrapper (Keychain-backed).
  Everything that touches a profile's username/password goes through this. Never subclass
  `FlutterSecureStorage` directly elsewhere — go through this wrapper so tests can swap it for an
  in-memory fake (see Testing).
- **`storage/profile_local_store.dart`** — saved-profile list + "which profile is active" on top
  of `SecureStorage` (JSON blob per profile under `profile:<id>`, plus an index list and an
  `active_profile_id` key). This is what `AuthLocalDataSource` calls.
- **`utils/url_scrubber.dart`** — see Security section below; `scrubUrl()` vs `scrubMessage()`.

### `lib/features/<name>/` — the Clean Architecture slice, repeated per feature

Every feature has the same three-layer shape. `live_tv` is the fullest worked example — read it
first if you're adding a new feature or don't remember the pattern:

```text
live_tv/
  domain/
    entities/live_category.dart, live_channel.dart      # plain Dart, no Flutter/package imports
    repositories/live_tv_repository.dart                 # abstract interface, TaskEither<Failure, T>
    usecases/get_live_categories_usecase.dart, get_live_channels_usecase.dart   # one class per action, just delegates to the repository
  data/
    datasources/live_tv_remote_datasource.dart           # wraps XtreamClient, catches RequestException/ParseException, throws Failure
    repositories/live_tv_repository_impl.dart             # implements the domain interface, TaskEither.tryCatch(..., _toFailure) around the datasource
  presentation/
    cubit/live_categories_cubit.dart, live_channels_cubit.dart   # sealed *State classes (Loading/Loaded/Error), load() method
    pages/live_categories_page.dart, live_channels_page.dart      # BlocProvider(create: ...load()) + BlocBuilder + switch over sealed state
    widgets/channel_list_tile.dart                        # row widget; embeds NowNextStrip + FavoriteButton from other features
```

The other five content/support features follow this exact shape — only the domain shape and a
couple of specifics differ:

| Feature | Domain entities | Repository | Notable difference from `live_tv` |
|---|---|---|---|
| `vod` | `VodCategory`, `VodItem`, `VodDetail` | `VodRepository` | Has a detail-fetch step (`GetVodDetailUseCase`/`VodDetailCubit`) between list and play — VOD needs `container_extension` from `get_vod_info`, not just the list item. |
| `series` | `SeriesCategory`, `SeriesShow`, `SeriesSeason`, `SeriesEpisode`, `SeriesDetail` | `SeriesRepository` | One extra nesting level (categories → shows → seasons → episodes). `SeriesDetailCubit` fetches seasons+episodes-by-season *once*; `series_episodes_page.dart` is a plain `StatelessWidget` that reads the already-loaded `SeriesDetail` passed via `extra`, it does **not** re-fetch per season tap — see `series_seasons_page.dart` for how `extra: detail` is threaded through `go_router`. |
| `epg` | `EpgProgram` | `EpgRepository` | Single use case (`GetNowNextUseCase`). `NowNextStrip` (presentation/widgets) is the only consumer, self-contained (creates its own `BlocProvider` inline wherever it's dropped) and silently renders nothing on any non-`Loaded` state — EPG is supplementary, never blocking. |
| `favorites` | `FavoriteItem` (+ `FavoriteItemType` enum: live/vod/series) | `FavoritesRepository` | Backed by `shared_preferences`, not `SecureStorage` (not sensitive), keyed per `profileId`. `FavoriteButton` (presentation/widgets) is the same self-contained pattern as `NowNextStrip` — drop it anywhere with a `FavoriteItem`, it manages its own load/toggle state. |
| `search` | `SearchResult` (+ `SearchResultType` enum) | *(none — depends directly on `LiveTvRepository`/`VodRepository`/`SeriesRepository`)* | The one feature using a full `Bloc` (`SearchBloc`) instead of a `Cubit`, because it needs `rxdart`'s `debounceTime`+`switchMap` event transformer on `SearchQueryChanged`. `SearchAllUseCase` (domain, but depends on the *other three features'* repository interfaces — an accepted cross-feature domain dependency) caches the flat `getAllChannels()`/`getAllItems()`/`getAllSeries()` results in memory for the app session; only the *first* search per session hits the network. |
| `ai_recommendations` | `ChannelLanguage` (+ `matchCategoryLanguages()`), `NowPlayingSnapshot`, `AiRecommendation` | `AiRecommendationsRepository` (only wraps the OpenAI call itself) | "Top 40 Now" — see its own section below. `GetTopPicksUseCase` is the second usecase (after `SearchAllUseCase`) that composes across other features' repositories (`LiveTvRepository` + `EpgRepository`) directly instead of being a thin one-repository delegate. |

### `lib/features/player/` — shared by live/VOD/series, worth its own map

This feature has no "list/detail" pages of its own — it's pure playback plumbing that
`live_tv`'s `PlayerPage`, `vod`'s `VodPlayerPage`, and `series`'s `SeriesPlayerPage` all drive.

- **`domain/entities/playback_source.dart`** — `{ url, containerExtension }`, the resolved thing
  a player engine actually opens.
- **`domain/entities/playback_engine_choice.dart`** — `PlaybackEngineKind` enum (`av`/`mpv`) +
  `PlaybackEngineChoice` (kind + source) + the shared
  `engineKindForContainerExtension(String? extension)` helper (mp4/mov/m4v/m3u8 → `av`, else
  `mpv`) used by both VOD and series playback use cases.
- **`domain/repositories/playback_controller.dart`** — abstract `PlaybackController` (`initialize`,
  `dispose`); the two concrete engines implement this.
- **`domain/repositories/playback_engine_selector.dart`** — abstract interface for the
  probe-and-choose logic (implementation is data-layer, see below — this split exists so
  `PlayChannelUseCase` doesn't import a `data/` file).
- **`domain/usecases/play_channel_usecase.dart`** — live TV path: resolves both `.m3u8` and `.ts`
  URLs from `LiveTvRepository`, hands them to `PlaybackEngineSelector.choose()` (which actually
  probes `.m3u8` over HTTP).
- **`domain/usecases/play_vod_item_usecase.dart`** / **`play_series_episode_usecase.dart`** — VOD
  and series paths: no probing, just `engineKindForContainerExtension()` on the panel-reported
  extension.
- **`data/probes/hls_availability_probe.dart`** — `HlsAvailabilityProbe.isAvailable(url)`, HEAD
  request via the shared `Dio`, treats any non-2xx/3xx *or thrown exception* as "unavailable"
  (never throws itself).
- **`data/engines/playback_engine_selector_impl.dart`** — implements the domain selector
  interface using the probe above. This is the one file explicitly named in the plan brief as
  worth a dedicated unit test (`test/features/player/data/engines/playback_engine_selector_test.dart`)
  — no real player involved, just probe-result-in → engine-choice-out.
- **`data/engines/av_player_controller.dart`** — wraps `video_player`'s `VideoPlayerController`.
  Exposes `videoPlayerController` getter for `chewie` to consume. `initialize()` calls
  `scrubMessage(error.toString())` before wrapping into `PlaybackFailure` — see Security.
- **`data/engines/mpv_player_controller.dart`** — wraps `media_kit`'s `Player`/`VideoController`.
  Same `scrubMessage()` treatment on failure.
- **`presentation/cubit/player_cubit.dart`** — one Cubit, three entry points
  (`playChannel`/`playVodItem`/`playEpisode`), all funneling into a private `_resolve()` that
  picks the engine, constructs the right controller, and emits `PlayerReady(controller,
  isFallbackEngine, isLive)`. Disposes the active controller in its own `close()` override —
  `get_it` never manages `PlaybackController` lifetime.
- **`presentation/pages/player_page.dart`** — the live-TV player screen; `vod`/`series` have
  their own thin page wrappers (`vod_player_page.dart`, `series_player_page.dart`) that all
  delegate rendering to:
- **`presentation/widgets/player_body.dart`** — the actual `PlayerState → Widget` switch, shared
  by all three player pages so the engine-selection UI logic isn't triplicated.
- **`presentation/widgets/player_chrome_video_player.dart`** / **`player_chrome_media_kit.dart`**
  — the two engine-specific chrome widgets (see Player strategy above for why they're separate).
- **`presentation/widgets/airplay_button.dart`** / **`fallback_engine_badge.dart`** — small
  standalone widgets embedded in the AV chrome / shown when on the mpv fallback engine.

## `lib/features/ai_recommendations/` — "Top 40 Now" AI picks

Fetches now-playing EPG for channels in English/Russian/Polish/Ukrainian categories, sends a
compact summary to OpenAI's Chat Completions API, and shows the ranked top 40. Entry point:
the sparkle icon in `home_shell.dart`'s `AppBar` → `/ai-picks` route.

- **`domain/entities/channel_language.dart`** — `ChannelLanguage` enum +
  `matchCategoryLanguages(String categoryName)`, a pure heuristic keyword matcher (no Flutter/
  package imports, easily unit-testable). There is no language taxonomy in the Xtream API —
  categories are opaque provider-named strings. Deliberately does **not** match bare
  country-code tokens like `"uk"`/`"us"` — see the real-panel gotcha below for why that's
  unreliable, not just theoretically risky.
- **`domain/entities/now_playing_snapshot.dart`** — `{ LiveChannel, ChannelLanguage,
  EpgProgram }`, a cross-feature domain entity (same accepted pattern as `search`'s
  `SearchResult`).
- **`domain/usecases/get_top_picks_usecase.dart`** — the orchestration: match categories → one
  `getAllChannels()` call (not per-category) → sample up to 120 channels per language → fetch
  `EpgRepository.getNowNext()` in concurrency-8 batches with a 6s per-channel timeout (one slow/
  failing channel never fails the batch — caught and skipped) → if zero snapshots were gathered,
  fail with a specific message (covers the "provider's EPG surface is down" case, see gotcha
  below) rather than calling OpenAI with nothing → delegate ranking to
  `AiRecommendationsRepository`.
- **`data/datasources/openai_remote_datasource.dart`** — POSTs to `/chat/completions` (model
  `gpt-4o`, `response_format: json_object`) via the `openAiDio` named instance, parses `{"picks":
  [...]}` defensively (a malformed individual entry is dropped, not fatal), maps 401/429/timeout
  to `AiFailure`. Also base64-decodes EPG title/description defensively before building the
  prompt — see gotcha below.
- **`presentation/`** — `AiRecommendationsCubit` (Loading/Loaded/Error, no async work in the
  constructor), `AiRecommendationsPage` (BlocProvider + refresh action, Loading state explains
  the ~30s wait), `AiPickTile` (rank badge, language chip, reason).
- No dedicated `openai_remote_datasource_test.dart`/`get_top_picks_usecase_test.dart` exist yet —
  add them (mocktail-mocked `Dio`/repositories) before relying on this feature in CI. All non-
  player tests are currently `@Skip`-disabled anyway, see Testing below.

## Architecture — non-negotiable rules

Each feature under `lib/features/<name>/` has `domain/` (entities, abstract repository
interfaces, use cases — one class per action), `data/` (remote datasource wrapping
`XtreamClient`, repository impl mapping exceptions → `Failure`), `presentation/`
(cubit/bloc, pages, widgets).

- **`domain/` never imports Flutter, `dio`, `xtream_code_client`, `video_player`, `media_kit`,
  or any `data/` file from any feature.** This bit already once — `PlayChannelUseCase`
  originally imported a `data/engines/playback_engine_selector.dart` directly; fixed by
  splitting it into a `domain/repositories/playback_engine_selector.dart` interface +
  `data/engines/playback_engine_selector_impl.dart`. If you're adding a use case that needs
  engine-selection-style logic, follow that interface/impl split, don't shortcut it.
- Repository methods return `TaskEither<Failure, T>`; every repository impl has a private
  `_toFailure(Object error, StackTrace _)` catch-all that (a) passes through if `error is
  Failure` already, (b) otherwise wraps as `UnknownFailure(scrubMessage(error.toString()))` —
  **never `error.toString()` directly**, see Security below.
- Cubits/Blocs never fire async work from their constructor — see `AuthCubit.restoreActiveProfile()`
  (called explicitly once from `main.dart`) instead of the constructor. Constructor-launched
  async work is a real race condition under `bloc_test` (the emission can happen before the
  test's listener attaches) and it's not obvious from the call site that it's happening.
- Cubit/Bloc state classes need custom `==`/`hashCode` on any variant carrying non-primitive
  fields (a `List`, an entity) — plain Dart classes/Lists don't have value equality, so
  `bloc_test`'s `expect: () => [...]` silently fails to match otherwise. See
  `Authenticated`/`AuthError` in `auth_cubit.dart`, `LiveCategoriesLoaded`, `SearchLoaded` for
  the pattern.
- `get_it` lifetimes: `Dio`, storage, remote datasources, and repositories are
  `registerLazySingleton`. Use cases and Cubits/Blocs (`PlayerCubit`, `SearchBloc` via
  `getIt<PlayerCubit>()`) are `registerFactory` — a fresh instance per page. `PlaybackController`
  implementations (`AvPlayerController`/`MpvPlayerController`) are never in `get_it` at all —
  `PlayerCubit` constructs them directly per playback session and disposes them in its own
  `close()`.

## Adding a New Feature

When adding a new feature, follow these steps strictly to maintain the Clean Architecture structure:

1. **Domain Layer First:**
   - Define entities in `domain/entities/` (plain Dart, no Flutter imports).
   - Define abstract repository interfaces in `domain/repositories/`. Methods must return `TaskEither<Failure, T>`.
   - Create use cases in `domain/usecases/`. Each use case should be a single class delegating to the repository.
2. **Data Layer:**
   - Define remote/local datasources. If talking to the Xtream panel, copy the `XtreamClientFactory` caching pattern used in existing datasources.
   - Implement the repository interface in `data/repositories/`. Map all thrown exceptions to the `Failure` hierarchy using `TaskEither.tryCatch` and a catch-all `_toFailure` mapping function.
3. **Presentation Layer:**
   - Create a `Cubit` (or `Bloc` if RxDart event transformers are needed). Define sealed state classes (e.g., Initial, Loading, Loaded, Error).
   - Ensure custom `==` and `hashCode` are implemented for states carrying data (e.g., lists, entities) so `bloc_test` can match them.
   - Build UI pages and inject the Cubit locally using `BlocProvider(create: ...)`. Do not launch async load work from the Cubit constructor.
4. **Dependency Injection:**
   - Register the new feature's components in `core/di/injection.dart`: datasources and repositories as `registerLazySingleton`, use cases and Cubits as `registerFactory`.
5. **Routing:**
   - Add new routes to `core/router/app_router.dart`. Pass required arguments (like entities) via the `extra` parameter rather than path parameters where complex objects are involved.

## State Management & Error Handling

Because repositories and use cases return `TaskEither<Failure, T>`, the standard pattern in any Cubit's `load()` method is to execute the usecase, map the `Either` result, and emit the corresponding state:

```dart
Future<void> load() async {
  emit(const MyFeatureLoading());
  
  final result = await _myUseCase().run();
  
  // Fold handles both the Left (Failure) and Right (Success) cases cleanly.
  result.fold(
    (failure) => emit(MyFeatureError(failure.message)),
    (data) => emit(MyFeatureLoaded(data)),
  );
}
```

- **Never `try/catch` inside a Cubit.** All exceptions should be caught by the Data Layer (`repository_impl.dart`) and converted into `Failure` objects before reaching the Presentation Layer.
- **State Equality:** Remember to implement value equality (`==` and `hashCode`) for states holding data. The easiest way is manually comparing lists using `listEquals` or overriding `==` to ensure that `bloc_test` can match states.

## UI & Theming Conventions

- **Do not hardcode colors or text styles.** Always use the app's standard theme context: `Theme.of(context).colorScheme.primary`, `Theme.of(context).textTheme.bodyMedium`, etc. This ensures the app fully supports Dark Mode out of the box.
- **Avoid arbitrary padding.** Use standard padding sizes (e.g. `8.0`, `16.0`, `24.0`) so the UI spacing remains consistent.
- **Responsive layouts:** Never assume a fixed screen width. Use `Flexible`, `Expanded`, `LayoutBuilder`, or `MediaQuery` appropriately to ensure the interface handles rotation and different device sizes gracefully.

## Player strategy

`PlaybackEngineSelector` (data/) probes `.m3u8` via HTTP HEAD (`HlsAvailabilityProbe`, shared
`Dio`) and picks `AvPlayerController` (video_player/chewie, gets AirPlay) if it checks out,
`MpvPlayerController` (media_kit) otherwise. VOD/series don't probe — `container_extension`
from the panel is authoritative, looked up via `engineKindForContainerExtension()` in
`playback_engine_choice.dart` (mp4/mov/m4v/m3u8 → AV, everything else incl. mkv → mpv). VOD on
the panel used for development actually serves `.mkv`, so the mpv path is exercised for real,
not hypothetical.

`chewie` only wraps `video_player` — it cannot drive `media_kit`. The two engines get separate
chrome widgets (`player_chrome_video_player.dart`, `player_chrome_media_kit.dart`), switched on
in `player_body.dart` by the runtime type of `PlayerReady.controller`.

## Testing

- **All tests except the `player` feature's three files are currently `@Skip`-disabled**
  (library-level `@Skip('Temporarily disabled during AI-picks feature work; re-enable at
  project end. See AGENTS.md.')` at the top of each file) — a deliberate, temporary decision
  while `ai_recommendations` is being built, not a regression. Only
  `test/features/player/data/engines/playback_engine_selector_test.dart`,
  `test/features/player/domain/play_series_episode_usecase_test.dart`, and
  `play_vod_item_usecase_test.dart` still run. Re-enable everything else (delete the `@Skip`
  line from each file) once the project's test suite is revisited — don't add more `@Skip`s to
  new code without being asked; this was a one-time, explicit user decision, not a pattern.
- `flutter analyze` and `flutter test` must both be clean before calling any milestone done.
- Widget tests that touch `flutter_secure_storage` need `getIt.unregister<SecureStorage>()` +
  an in-memory fake registered in its place — the real plugin's platform channel has no handler
  under `flutter test` and calls hang forever rather than throwing (see the fake in
  `test/widget_test.dart` / `test/smoke_test.dart`).
- **Never use `pumpAndSettle()` on a screen with a `CircularProgressIndicator`** — its repeating
  ticker means "no more frames scheduled" never becomes true and the call hangs until timeout.
  Use a bounded loop of `pump(Duration(...))` instead (see `_settle()` helpers in the test files).
- `media_kit`/mpv cannot initialize under plain `flutter test` (`MediaKit.ensureInitialized()`
  throws — no native framework bundle on the host). Any test that reaches
  `PlaybackEngineKind.mpv` will fail for this reason, not because of a real bug. Mock the
  relevant "play" use case to force the AV path if the test doesn't care which engine.
- `test/smoke_test.dart` is the one end-to-end UI smoke test (login → live category → channel
  → player screen renders) — fully mocked (`LoginUseCase`, `GetLiveCategoriesUseCase`,
  `GetLiveChannelsUseCase`, `PlayChannelUseCase`), no network, safe for CI.
- Package model constructors used in tests (e.g. `xtream_code_client`'s `GeneralInformation`,
  `UserInfo`, `ServerInfo`) are all-nullable-field `const` constructors — trivial to build
  minimal fixtures from.

### Verifying against a real panel (do this, but never commit it)

The fastest way to sanity-check a repository/use-case chain against real Xtream server
behavior is a throwaway `test/_e2e_*_tmp_test.dart` file: `HttpOverrides.global = null;` inside
`tester.runAsync(() async { ... })` lets real HTTP through despite `flutter_test`'s default
400-for-everything `HttpOverrides`. **Delete the file immediately after running it** — it's not
committed, ever, because it necessarily embeds real provider credentials. This is exactly how
the mkv-container VOD behavior and the panel-wide `get_short_epg`/`xmltv.php` failure below were
found.

## Known real-panel gotchas (found during development, not hypothetical)

- VOD `container_extension` on the dev panel is `mkv`, not `mp4` — confirms the "never assume
  HLS/mp4 for VOD" rule in `PLAN.md` is load-bearing, not defensive-only.
- Some panels return **HTTP 403 for `get_short_epg` on every channel** and **400 for
  `xmltv.php`** — i.e., no working EPG surface at all, panel-wide, not per-channel. `NowNextStrip`
  already degrades silently (`SizedBox.shrink()` on any non-`Loaded` state incl. error) so this
  doesn't break the UI — just don't be surprised when the now/next strip never shows anything
  against such a panel; it's the provider, not a bug.
- Omitting `category_id` on `get_live_streams`/`get_vod_streams`/`get_series` returns the
  *entire* flat list across all categories in one call — this is what `SearchAllUseCase` relies
  on (`getAllChannels()`/`getAllItems()`/`getAllSeries()`) instead of iterating every category.
  First search costs ~2.5s on a panel with ~1000 live channels; results are cached in-memory in
  `SearchAllUseCase` for the rest of the session.
- **`get_short_epg` `title`/`description` can be base64-encoded** (confirmed on the World8K/
  Strong8K dev panel, e.g. `"QkJDIE5ld3MgYXQgVGVu"` → `"BBC News at Ten"`) — `xtream_code_client`
  does **not** auto-decode this, `EpgRemoteDataSource.getNowNext()` passes it through as-is.
  `ai_recommendations`'s `OpenAiRemoteDataSource` decodes defensively (try base64, fall back to
  the raw string on failure) before building its prompt; if you add another EPG text consumer,
  do the same rather than assuming plain text.
- **Category naming can't be trusted as a reliable per-provider language taxonomy.** On the same
  dev panel, category names follow a `"XX| Name"` prefix convention, but `"UK|"` is overloaded —
  almost all `UK|`-prefixed categories are British, but one, `"UK| UKRAINE HD/4K"`, is Ukrainian
  (its channels are internally named `"UA: ..."`). Separately, several Arabic categories are
  named e.g. `"AR| MBC +6H USA"` (Arabic content, just timezone-shifted for a US audience) — a
  naive substring match on `"usa"` would misclassify them as English. `matchCategoryLanguages()`
  in `ai_recommendations` deliberately matches only explicit, unambiguous whole-word language
  terms (`"russian"`, `"ukraine"`, `"polish"`, etc.) and never bare 2-letter country-code tokens
  for exactly this reason. See `dev_credentials.local.md` for the full account and more quirks.
- Some panels return **HTTP 403 for `get_short_epg` on every channel**, panel-wide (see the
  entry above this one for the general case) — if that's true for the account in use,
  `ai_recommendations`'s `GetTopPicksUseCase` will gather zero snapshots and surface a specific
  "no now-playing data available" error rather than calling OpenAI with nothing; this is
  expected provider behavior, not a bug in the use case.

## Security

- Credentials live only in `flutter_secure_storage` (`core/storage/secure_storage.dart` +
  `profile_local_store.dart`), keyed by profile id. Favorites use `shared_preferences` instead —
  deliberately, they aren't sensitive.
- `core/utils/url_scrubber.dart` has two functions: `scrubUrl()` (input is a bare URL) and
  `scrubMessage()` (input is arbitrary text that might *contain* a URL — e.g. an exception's
  `toString()`). Every repository's catch-all `_toFailure` and both `PlaybackController`
  implementations (`AvPlayerController`, `MpvPlayerController`) route their error message
  through `scrubMessage()` before it becomes a `Failure` that a page might render on-screen.
  `xtream_code_client`'s own `RequestException` messages are already redacted by the package
  itself — the gap this closes is everything *else* that can throw (`SocketException`,
  platform-channel errors from `video_player`/`media_kit`, etc.), which don't go through the
  package's redaction and would otherwise leak the credentialed stream URL straight onto the
  error screen.
- Never construct a bare `Dio()` — always go through `core/network/api_client.dart`
  (`buildApiClient()` or `buildOpenAiApiClient()`), which wires the scrubbing log interceptor and
  the retry interceptor. `grep -rn "Dio()" lib/` should only ever match that one file.
- The OpenAI API key is build-time-only config (`core/config/env.dart`, `Env.openAiApiKey`),
  never stored on-device or in code — see `dart_define.example.json` (committed placeholder) vs
  `dart_define.local.json` (gitignored, real key). `dev_credentials.local.md` at the repo root
  (also gitignored) holds a real Xtream dev account for manual panel testing — never read either
  file's contents into a commit, a log, or an error message shown on-screen.

## Commands & Makefile

A `Makefile` is provided for common development tasks. Avoid running raw `flutter` commands when a `make` target exists:

```bash
make setup          # flutter pub get
make format         # dart format .
make clean          # flutter clean
make analyze        # flutter analyze
make test           # flutter test
make build-ios-sim  # flutter build ios --simulator --debug --dart-define-from-file=... (verifies native plugin builds)
make run-ios        # Opens Simulator app and runs flutter run -d simulator --dart-define-from-file=...
```

`build-ios-sim`/`run-ios` pass `--dart-define-from-file=dart_define.local.json` if that gitignored
file exists, else fall back to the committed `dart_define.example.json` placeholder — so the app
always builds, with the AI picks feature just showing a "not configured" state when no real
OpenAI key is present.

AirPlay-to-a-real-receiver and the mpv-fallback-triggering-on-device path cannot be verified in
CI/simulator — the simulator has no real AirPlay routes and `media_kit` needs the actual app
bundle. Both need a real device with a real AirPlay receiver (Apple TV/Mac) per `PLAN.md`'s own
risk list.
