# PLAN_BUGFIXES.md — Bug-Fix Pass for Flutter IPTV Xtream Client

## Context

The Phase 1 iOS MVP (M0–M9) is fully built and was previously verified against a real Xtream panel milestone-by-milestone. This is a follow-up **verification and bug-fixing pass**: three parallel Explore agents audited (1) core/DI/router/auth, (2) the six content features (live TV/VOD/series/EPG/favorites/search), and (3) the player feature, specifically hunting for concrete correctness bugs rather than style issues.

I independently re-read and confirmed the highest-impact findings against the actual source (including the `xtream_code_client` package internals for the EPG claim). This plan fixes every confirmed bug, grouped by severity.

**14 distinct bugs confirmed.** Nothing here is hypothetical — each has a concrete input/action sequence that triggers it, and three (EPG garbling, stale cross-profile search, `/profiles/add` unreachable once logged in) are things a real user would hit during ordinary use, not edge cases.

---

## 🔴 P0 — User-Visible Correctness Bugs (Fix First)

1. **EPG now/next titles render as base64 gibberish** (`lib/features/epg/data/datasources/epg_remote_datasource.dart:35-39`).
   - *Bug*: Xtream's `get_short_epg` API returns `title`/`description` base64-encoded; confirmed the `xtream_code_client` package's `EpgMapper._listing()` passes them through `ValueParser.readString` with zero decoding.
   - *Fix*: Decode with `utf8.decode(base64.decode(...))` in `getNowNext()`, wrapped in a `try/catch` that falls back to the raw string if decoding fails (some panels may already send plain text — don't assume the spec is followed universally).

2. **Search results go stale/cross-account after switching profiles** (`lib/features/search/domain/usecases/search_all_usecase.dart:20,28-36` + registration in `lib/core/di/injection.dart`).
   - *Bug*: `SearchAllUseCase` is a `registerLazySingleton` with an in-memory `_cache` that's populated once and never invalidated. Log in as profile A, search (caches A's catalog), switch to profile B — every search still returns A's channels/movies/series, and tapping one opens A's stream ids against B's account.
   - *Fix*: Clear `_cache` whenever the active profile changes. Simplest correct fix: have `SearchAllUseCase` also depend on `AuthCubit` and key/invalidate the cache on profile id change.

3. **Authenticated users can never reach "add profile" or "edit profile"** (`lib/core/router/app_router.dart:48-50`).
   - *Bug*: `location.startsWith('/profiles')` matches `/profiles/add` and `/profiles/:id/edit` too, so the redirect bounces a logged-in user back to `/home/live` the instant they navigate there.
   - *Fix*: Narrow the check to exact match, e.g. `location == '/profiles'`. Also, add an entry point to reach these routes while authenticated — at minimum a "Manage profiles" action from `HomeShell`'s app bar navigating to `/profiles`.

4. **`NowNextCubit` crashes with "emit after close" during fast scrolling** (`lib/features/epg/presentation/cubit/now_next_cubit.dart:31-37`).
   - *Bug*: Each visible channel row creates its own `NowNextCubit`. Scrolling recycles rows, closing the cubit while its request may still be in flight; the eventual `emit()` throws `StateError`.
   - *Fix*: Guard with `if (!isClosed) emit(...)` in `load()`. Apply the same guard to the other page-scoped cubits with the identical pattern (`VodDetailCubit`, `SeriesDetailCubit`, `LiveChannelsCubit`, etc.).

---

## 🟠 P1 — Player Resource Leaks & Race Conditions

5. **Previous `PlaybackController` never disposed when a new one is created** (`lib/features/player/presentation/cubit/player_cubit.dart:60-81`).
   - *Bug*: `_resolve()` builds a fresh controller every call but only `close()` disposes the controller of whatever the *current* state happens to be. If `_resolve()` runs again, the old controller is dropped without `dispose()` — native instance leaks.
   - *Fix*: At the top of `_resolve()`, capture `final previousState = state;` and if it's `PlayerReady`, `await previousState.controller.dispose();` before proceeding.

6. **Race condition: concurrent `_resolve()` calls can leak a controller and apply stale state**.
   - *Bug*: Two overlapping calls each build+initialize their own controller; whichever `Future` resolves *last* wins the emit, even if it was the first call that finishes after the second.
   - *Fix*: Add an `int _resolveGeneration = 0` field; increment it at the start of `_resolve()`, capture the value locally, and only `emit()` if `_resolveGeneration` still equals the captured value.

7. **Controller never disposed when `initialize()` itself fails** (`AvPlayerController` / `MpvPlayerController`).
   - *Bug*: Eagerly allocates `Player()`. If `_player.open()` throws, that native mpv instance is never disposed since `PlayerCubit` only tracks controllers inside `PlayerReady`.
   - *Fix*: In each `initialize()`, wrap in `try/catch` so that on failure the just-created native controller/player is disposed before the failure propagates.

8. **`PlayerChromeVideoPlayer` can end up driving a stale/disposed `ChewieController`** (`lib/features/player/presentation/widgets/player_chrome_video_player.dart:19-30`).
   - *Bug*: `_chewieController` is built once in `initState` with no `didUpdateWidget`.
   - *Fix*: Add `didUpdateWidget` that disposes the old `_chewieController` and rebuilds a new one whenever `widget.controller != oldWidget.controller`.

---

## 🟡 P2 — HLS Probe Correctness

9. **`HlsAvailabilityProbe` has no `connectTimeout`** (`lib/features/player/data/probes/hls_availability_probe.dart:14-21`).
   - *Bug*: Only `sendTimeout`/`receiveTimeout` are set; Dio's default `connectTimeout` is unbounded, so a host that stalls at the TCP-connect stage hangs engine selection.
   - *Fix*: Add `connectTimeout: const Duration(seconds: 5)` to `Options(...)`.

10. **HEAD-unsupported panels (405/403) are misclassified as "no HLS," forcing an unnecessary mpv fallback**.
    - *Bug*: Many panels reject `HEAD` on stream URLs (405) even though `GET` works. Treating 405 as "unavailable" silently routes working HLS streams to the mpv fallback (losing AirPlay).
    - *Fix*: Don't treat 403/405 as failure at the transport level. Treat `405` as inconclusive-but-likely-available rather than a hard failure.

---

## 🟢 P3 — Smaller Correctness/UX Bugs

11. **`scrubUrl` mis-scrubs path-segment credentials and corrupts unrelated URLs** (`lib/core/utils/url_scrubber.dart:14-21`).
    - *Bug*: Logic meant for query params is applied to paths, causing path segment 0 to always get blanked regardless of where the real credentials are. `http://host/live/...` becomes `http://host/***/...`.
    - *Fix*: Rewrite `scrubUrl` to route through `scrubMessage(url)` for the path-credential case (it already handles this shape correctly).

12. **`state.extra as T` (non-nullable) will crash on a null `extra`** (`lib/core/router/app_router.dart`).
    - *Bug*: `extra` doesn't survive a deep link / process-death restore. 
    - *Fix*: If `state.extra` isn't the expected type, redirect to a safe fallback (e.g. the category root) instead of crashing — add a null/type check at the top of each affected builder.

13. **Series with an empty/absent `seasons` array but populated `episodes` become permanently unreachable**.
    - *Bug*: Panels that return `"seasons": []` (common) while `episodes` is fully populated leave the user stuck on "No seasons found."
    - *Fix*: In `SeriesRemoteDataSource.getSeriesDetail()`, if `seasons` list is empty but `episodesBySeason` isn't, synthesize a `SeriesSeason` per key in `episodesBySeason`.

14. **`FavoriteButton` optimistic toggle can desync from real storage state** (`lib/features/favorites/presentation/widgets/favorite_button.dart:44-49`).
    - *Bug*: Tapping before the initial load resolves toggles against a `null`. The toggle's own result is never checked.
    - *Fix*: Disable the button until the initial load completes (`_loading`), and check the `toggleFavorite` result's `Left` branch to revert the optimistic UI update on failure.

15. **`setState` after `await` with no `mounted` guard** (`lib/features/auth/presentation/pages/profile_list_page.dart`).
    - *Bug*: A successful login's router redirect can dispose the page while `await` is still pending, leading to a thrown error on `setState`.
    - *Fix*: Guard each of these `setState` call sites with `if (!mounted) return;`.

---

## 🛠 Verification Strategy

- Run `make test` and `make analyze` after every fix (existing 44 tests must still pass).
- Add regression tests per P0/P1 fix:
  - Extend `test/core/utils/url_scrubber_test.dart` for the path segment bug.
  - Extend `test/features/player/data/engines/playback_engine_selector_test.dart` for the 405 HEAD case.
  - Add a `SearchAllUseCase` test asserting the cache clears on profile-id change.
- Verify EPG base64 fix and router redirect fixes using a temporary real-panel check (as documented in `AGENTS.md`) and delete immediately after.
- Manually confirm in the iOS Simulator (`make run-ios`) that adding a profile works while logged in, and the EPG renders human-readable text.
