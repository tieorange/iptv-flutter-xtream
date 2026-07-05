# Flutter IPTV Client — Xtream Codes, Clean Architecture, iOS-first + AirPlay — Build Brief for Claude Code

## Objective

Build a Flutter IPTV client app that authenticates against Xtream Codes / Xtream-compatible
panels (`player_api.php` + `get.php`) and plays Live TV, VOD, and Series content. Ship iOS
first, with full AirPlay support. Use Clean Architecture throughout so Android can be added
later (Phase 3) without restructuring.

**Stack decisions (already made, not open for debate unless you hit a hard blocker):**
Clean Architecture (presentation / domain / data per feature) · `flutter_bloc` Cubits ·
`get_it` for DI · `go_router` for navigation · `fpdart` (`Either`/`TaskEither`) for error
handling instead of exceptions.

## Product framing (keep in mind while designing onboarding/UI)

This is a generic client: the user enters their own provider's server URL, username, and
password (like TiviMate, IPTV Smarters, GSE). The app is not a content source and doesn't
bundle, host, or resell any streams. Keep onboarding copy framed that way — Apple reviewers
scrutinize generic Xtream/IPTV clients more than most app categories, and vague "watch free TV"
framing is a fast path to rejection.

## Working agreement

1. Start with a short `PLAN.md`: layer/folder structure, DI registration map, route table, and
   a phased milestone list (see Feature scope below). Post it before writing implementation code.
2. After that, don't stop for approval on every subtask — this is a solo prototyping project.
   Optimize for working code and forward momentum over process ceremony.
3. Re-verify package choices below against current pub.dev scores/maintenance/changelogs before
   locking `pubspec.yaml` — this list reflects research as of mid-2026 and the ecosystem moves.
4. Flag any Xtream panel behavior that looks non-standard rather than silently working around it
   — real-world panels vary a lot and silent workarounds hide bugs.

## Recommended stack (verify before locking)

- **Xtream API client**: `xtream_code_client` (v2.x API surface) — has resilient/structured
  parsing and adaptive background parsing, which matters because real panels return
  inconsistent JSON (nulls as strings, inconsistent types, non-standard fields). `muxa_xtream`
  is a viable alternative if `xtream_code_client` looks stale by the time you check — compare
  recent commit activity on both before committing. Wrap whichever you pick behind your own
  domain repository interface (see Architecture) so a future swap doesn't touch the rest of the app.
- **State management**: `flutter_bloc` — one Cubit per feature/screen-cluster. Reach for full
  `Bloc` (event layer) only where you genuinely need event transformers (debounce on search
  input, etc.) — otherwise Cubit's `emit()` is enough and cuts boilerplate.
- **Dependency injection**: `get_it` as the service locator, registered in
  `core/di/injection.dart`. Consider pairing with `injectable` for annotation-driven codegen
  (`@lazySingleton`, `@injectable`, `@factoryMethod`) once the registration list grows past a
  dozen or so entries — optional, your call at implementation time.
- **Routing**: `go_router`. Bridge auth state to its `refreshListenable` via a small
  stream-to-`ChangeNotifier` adapter — Cubit exposes a `Stream<State>`, not a `Listenable`
  directly, so `refreshListenable` needs that shim to react to login/logout.
- **Functional error handling**: `fpdart`. Use `TaskEither<Failure, T>` for anything async
  (which is nearly everything touching the network or disk here) rather than
  `Future<Either<Failure, T>>` — fpdart's own guidance is that `TaskEither` composes correctly
  where the bare `Future<Either<...>>` combination doesn't. Use plain `Either<Failure, T>` only
  for synchronous parsing/validation. Define a sealed `Failure` hierarchy in `core/error/`.
  **Always `.fold()` the result in the Cubit** — never call `.getOrElse()` and silently drop the
  failure branch.
- **Networking & resilience**: `dio` for anything the Xtream client doesn't cover directly
  (HLS-availability probes for the player fallback logic, XMLTV/EPG fetch, channel logo
  loading), with a retry interceptor (`dio_smart_retry` or a small custom one). Retry only
  transient failures — timeouts, connection errors, `502`/`503`/`504` — with exponential
  backoff, and **never** retry `4xx`. A retried bad-credentials request just makes login look
  hung instead of failing fast.
- **Local persistence/cache**: Drift (sqlite) or Hive for channel/category/EPG cache — panels
  can return thousands of channels and slow JSON payloads; don't refetch on every app open.
- **Secure credential storage**: `flutter_secure_storage` (Keychain-backed on iOS).
- **Primary video engine (iOS)**: `video_player` (AVPlayer-backed) — see player strategy below,
  this is the path that gets AirPlay, PiP, and lock-screen controls essentially for free.
- **AirPlay route button**: `flutter_to_airplay` (`AirPlayRoutePickerView`, wraps
  `AVRoutePickerView`) or `flutter_ios_airplay`. Check both for current maintenance; if neither
  looks healthy, a small custom Pigeon bridge exposing `AVRoutePickerView` is a well-trodden
  fallback (search "Flutter AirPlay Pigeon" for reference implementations).
- **Fallback video engine (raw MPEG-TS)**: `media_kit` (mpv-backed, cross-platform, actively
  maintained) preferred over `flutter_vlc_player` unless your research at build time says
  otherwise — confirm current maintenance status for both.
- **Player chrome/controls**: `chewie` on top of `video_player`, or custom controls if chewie's
  API fights the dual-engine setup below.
- **Testing (dev dependencies)**: `bloc_test` + `mocktail` for Cubit/use-case/repository unit
  tests — this is the standard pairing for the Bloc ecosystem and works cleanly with the
  `TaskEither`-returning use cases above.

## Architecture

### Layers (per feature, strict dependency direction)

```
presentation → domain ← data
```

Domain never imports `package:flutter` or knows about `dio`/`drift`/`video_player` — it's pure
Dart contracts and entities. If a Flutter or package import slips into `domain/`, that's a
architecture leak, fix it before moving on.

- **`domain/`**: entities (plain Dart classes), abstract repository/service interfaces
  (`XtreamRepository`, `PlaybackController`, `EpgRepository`, ...), use cases (one class per
  action, e.g. `GetLiveCategoriesUseCase`, `PlayChannelUseCase`). Use cases and repository
  interfaces return `TaskEither<Failure, T>` / `Either<Failure, T>`.
- **`data/`**: repository *implementations* of the domain interfaces, remote data sources (the
  Xtream client wrapper, HTTP), local data sources (Drift/Hive cache), DTOs + mapping to domain
  entities. This is where `try/catch` around the Xtream client lives, converted immediately into
  `Left(Failure(...))`/`Right(entity)`.
- **`presentation/`**: Cubits (call use cases, `.fold()` results into sealed states), pages,
  widgets. No business logic here beyond orchestrating use case calls and mapping state to UI.
  Default to plain Dart 3 `sealed class` state hierarchies with `switch` pattern matching in the
  UI — no `freezed`/codegen needed for straightforward `Loading`/`Loaded`/`Error` shapes. Reach
  for `freezed` only if a state needs `copyWith` across many fields or you want generated value
  equality without hand-writing `==`/`hashCode`.

### Folder structure

```
lib/
  core/
    error/failures.dart          # sealed Failure hierarchy
    di/injection.dart            # get_it setup
    router/app_router.dart       # go_router config + auth-refresh bridge
    network/api_client.dart
  features/
    auth/            {data,domain,presentation}/
    live_tv/         {data,domain,presentation}/
    vod/             {data,domain,presentation}/
    series/          {data,domain,presentation}/
    player/          {data,domain,presentation}/   # PlaybackController lives here
    epg/             {data,domain,presentation}/
    favorites/        ...
  main.dart
```

### Player strategy — this is the part that actually matters

Xtream live stream URLs support multiple output formats via the file extension:

- `.../live/{user}/{pass}/{stream_id}.ts` → raw MPEG-TS. `AVPlayer` does **not** reliably play
  `video/mp2t` content type — this is the #1 cause of "video won't play on iOS" in Xtream
  clients.
- `.../live/{user}/{pass}/{stream_id}.m3u8` → the same panel repackages the stream as segmented
  HLS. This is what `AVPlayer` wants, and it's the only path that gets you AirPlay, PiP, and
  background audio without extra native work.

**Default to requesting `.m3u8` for every live stream.** Only fall back to the mpv/`media_kit`
engine when the `.m3u8` endpoint 404s, times out, or the panel demonstrably doesn't support HLS
output (some older/cheaper panels only emit `.ts`). Surface a small non-blocking indicator when
a channel is playing on the fallback engine, since AirPlay/PiP won't be available there — set
that expectation rather than have the AirPlay button silently disappear.

Model this in the architecture as: `domain/player` defines `abstract class PlaybackController`
with methods returning `TaskEither<PlaybackFailure, T>`; `data/player` provides two
implementations (`AvPlayerController`, `MpvPlayerController`) plus a small
`PlaybackEngineSelector` that tries HLS first and falls back per the rule above;
`presentation/player` has a single `PlayerCubit` that depends only on the abstract interface via
`get_it` and doesn't know which engine is active except to conditionally hide the AirPlay button.

VOD and series content is usually served as direct files (mp4/mkv) or already-HLS — check the
`container_extension` field from the VOD/series API response per-item rather than assuming.

### AirPlay implementation (iOS)

1. Play everything possible through `video_player` (AVPlayer) per the strategy above.
2. Place an `AirPlayRoutePickerView`/`AVRoutePickerView` button in the player control bar.
3. In the iOS runner, configure `AVAudioSession` category to `.playback` (not `.ambient`) so
   audio continues over AirPlay and the lock screen when the app is backgrounded.
4. Test against a real AirPlay receiver (Apple TV or a Mac) — the simulator does not expose real
   AirPlay routes.

### Routing & auth guard

- `go_router` top-level `redirect` checks auth state; `refreshListenable` is a small
  `ChangeNotifier` subclass that subscribes to `AuthCubit.stream` and calls `notifyListeners()`
  on change (Cubit streams aren't `Listenable` on their own — this bridge is required, not
  optional).
- Route auth/session Cubit itself through `get_it` as a lazy singleton so both the router bridge
  and the UI read the same instance.

### Security

- Store server URL/username/password in Keychain via `flutter_secure_storage`, never in
  SharedPreferences/plaintext files.
- Support multiple saved provider profiles (many Xtream users run more than one line) with
  quick switching.

## Testing strategy

Mirror `lib/` under `test/` (`test/features/live_tv/domain/...`,
`test/features/live_tv/presentation/...`). Don't aim for exhaustive coverage on a solo
prototype — prioritize the layers where a silent bug is expensive:

- **Use cases & repositories**: mock the layer below with `mocktail` (mock data sources when
  testing a repository, mock the repository interface when testing a use case). Assert both the
  `Left` and `Right` paths, not just the happy path.
- **Cubits**: `bloc_test`'s `blocTest()` — mock the use case(s) a Cubit depends on, assert the
  exact emitted state sequence for success, failure, and empty-result cases (e.g., a category
  with zero channels shouldn't look the same as a load failure).
- **Player engine selection**: this is the one piece of business logic most worth a dedicated
  unit test — feed the `PlaybackEngineSelector` a probe result (m3u8 available / 404 / timeout)
  and assert it picks the engine you expect, without spinning up a real player.
- **Widget/integration**: skip broad widget/golden test coverage for now; if you add anything
  here, make it a single smoke test that taps through login → live category → channel → player
  renders, since that's the flow most likely to regress silently.

## Feature scope

### Phase 1 — iOS MVP

- Add/edit/switch provider profiles (server, username, password)
- Live TV: category list → channel list → player, with EPG "now/next" strip
- VOD: category → grid/list → detail → player
- Series: category → series → seasons → episodes → player
- Search across live/VOD/series
- Favorites (local, per-profile)
- Player: play/pause, seek (VOD/series), volume, AirPlay button, basic error/retry UI

### Phase 2 — iOS polish

- Picture-in-Picture (native to `AVPlayer`, mostly configuration)
- Background audio continuation
- EPG grid view (not just now/next) with local caching
- Parental lock / adult-category filtering toggle
- Connection diagnostics screen (panel info, active connections, expiry — Xtream exposes this)

### Phase 3 — Android

- Swap `video_player`'s iOS AVPlayer backing for its Android ExoPlayer backing (same package,
  should mostly just work given the `PlaybackController` abstraction above)
- Re-evaluate whether the `media_kit` fallback is even needed on Android — ExoPlayer handles raw
  MPEG-TS far better than AVPlayer does, so the fallback path may rarely trigger there
- Chromecast as the Android equivalent of AirPlay (separate package, e.g. `cast`), behind the
  same `PlaybackController` interface

## Known gotchas to design around from day one

- Xtream panel JSON is inconsistent across implementations — pick a client with resilient
  parsing and don't assume every panel matches the "reference" Xtream Codes schema.
- Channel lists can be huge (thousands of entries) — paginate/virtualize, never build a
  `Column` of all channels.
- Credentials are embedded in every stream URL as plaintext query/path segments — don't log full
  URLs, and scrub them from any crash reporting.
- `.m3u8` vs `.ts` output is a per-panel (sometimes per-stream) capability, not a fixed constant
  — detect and fall back rather than hardcoding one format.
- `go_router`'s `refreshListenable` wants a `Listenable`; Cubit gives you a `Stream`. Bridge it,
  don't fight it by calling `GoRouter.of(context).refresh()` manually from inside Cubit listeners.
- Don't let a `TaskEither` chain silently swallow a `Left` — every Cubit method that calls a use
  case should end in a `.fold(onFailure, onSuccess)` with both branches actually emitting state.
- Don't put business decisions in repository implementations — repositories fetch/cache; use
  cases decide. If a "repository" method starts branching on business rules, that logic belongs
  one layer up.
- A retry interceptor and a user-tapped "retry" button can fire concurrently against the same
  slow panel — guard in-flight requests (e.g. a `CancelToken` per logical request) so you don't
  double up load on an already-struggling server.
- Never let the retry interceptor retry `4xx` responses — a wrong password retried three times
  with backoff just makes the login screen look frozen for several seconds before failing.

## Deliverables for Phase 0 (planning output)

1. `PLAN.md` — folder structure (adapt the skeleton above to your actual feature list), `get_it`
   registration map, `go_router` route table with the auth-redirect bridge described above, and
   the phased milestone breakdown adapted to your actual estimate.
2. A short risk list: anything you're unsure about (e.g., a package's maintenance status, a
   platform API behavior) that's worth a quick spike before committing.
3. Then proceed straight into Phase 1 implementation, with unit tests for use cases, repositories,
   and Cubits landing alongside each feature rather than as a separate pass at the end.

app id (bundle id, etc): com.tieorange.iptv
