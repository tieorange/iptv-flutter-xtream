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
(favorites — not sensitive) · `dio`+`dio_smart_retry` (HLS probe only) · `rxdart` (search
debounce) · `bloc_test`+`mocktail` (tests).

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
  (`buildApiClient()`), which wires the scrubbing log interceptor and the retry interceptor.
  `grep -rn "Dio()" lib/` should only ever match that one file.

## Commands

```bash
flutter analyze
flutter test
flutter build ios --simulator --debug   # verifies native plugin builds (media_kit, flutter_to_airplay)
```

AirPlay-to-a-real-receiver and the mpv-fallback-triggering-on-device path cannot be verified in
CI/simulator — the simulator has no real AirPlay routes and `media_kit` needs the actual app
bundle. Both need a real device with a real AirPlay receiver (Apple TV/Mac) per `PLAN.md`'s own
risk list.
