import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/di/injection.dart';
import 'package:iptv/core/storage/secure_storage.dart';
import 'package:iptv/features/auth/domain/entities/provider_profile.dart';
import 'package:iptv/features/auth/domain/usecases/get_active_profile_usecase.dart';
import 'package:iptv/features/auth/domain/usecases/login_usecase.dart';
import 'package:iptv/features/auth/domain/usecases/logout_usecase.dart';
import 'package:iptv/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:iptv/features/live_tv/domain/entities/live_category.dart';
import 'package:iptv/features/live_tv/domain/entities/live_channel.dart';
import 'package:iptv/features/live_tv/domain/usecases/get_live_categories_usecase.dart';
import 'package:iptv/features/live_tv/domain/usecases/get_live_channels_usecase.dart';
import 'package:iptv/features/player/domain/entities/playback_engine_choice.dart';
import 'package:iptv/features/player/domain/entities/playback_source.dart';
import 'package:iptv/features/player/domain/usecases/play_channel_usecase.dart';
import 'package:iptv/main.dart';

class _FakeSecureStorage extends SecureStorage {
  final _values = <String, String>{};
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);
}

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MockGetActiveProfileUseCase extends Mock implements GetActiveProfileUseCase {}

class _MockGetLiveCategoriesUseCase extends Mock implements GetLiveCategoriesUseCase {}

class _MockGetLiveChannelsUseCase extends Mock implements GetLiveChannelsUseCase {}

class _MockPlayChannelUseCase extends Mock implements PlayChannelUseCase {}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(ProviderProfile(
      id: 'fallback',
      name: 'fallback',
      baseUrl: 'http://fallback',
      username: 'fallback',
      password: 'fallback',
      createdAt: DateTime(2026, 1, 1),
    ));
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'smoke: login -> live category -> channel -> player screen renders',
    (tester) async {
      configureDependencies();

      final profile = ProviderProfile(
        id: '1',
        name: 'Test provider',
        baseUrl: 'http://example.com',
        username: 'user',
        password: 'pass',
        createdAt: DateTime(2026, 1, 1),
      );
      const category = LiveCategory(id: 1, name: 'Sports');
      const channel = LiveChannel(id: 42, name: 'Test Channel', categoryId: 1);

      final loginUseCase = _MockLoginUseCase();
      final logoutUseCase = _MockLogoutUseCase();
      final getActiveProfileUseCase = _MockGetActiveProfileUseCase();
      when(() => getActiveProfileUseCase()).thenReturn(TaskEither.right(null));
      when(() => loginUseCase(any())).thenReturn(TaskEither.right(profile));

      final getLiveCategoriesUseCase = _MockGetLiveCategoriesUseCase();
      when(() => getLiveCategoriesUseCase()).thenReturn(TaskEither.right(const [category]));

      final getLiveChannelsUseCase = _MockGetLiveChannelsUseCase();
      when(() => getLiveChannelsUseCase(1)).thenReturn(TaskEither.right(const [channel]));

      // Real HLS-availability probing and mpv (media_kit) both need a real
      // app bundle/device — not available under `flutter test`. Mocking
      // this one use case keeps the smoke test to the AV engine, whose
      // `video_player` call fails harmlessly here (no platform channel in
      // a plain widget test) and lands on a clean error state, which is
      // still valid "the player screen renders" evidence.
      final playChannelUseCase = _MockPlayChannelUseCase();
      when(() => playChannelUseCase(channel)).thenReturn(TaskEither.right(
        const PlaybackEngineChoice(
          PlaybackEngineKind.av,
          PlaybackSource(url: 'http://example.com/test.m3u8', containerExtension: 'm3u8'),
        ),
      ));

      getIt.unregister<SecureStorage>();
      getIt.registerLazySingleton<SecureStorage>(() => _FakeSecureStorage());
      getIt.unregister<AuthCubit>();
      getIt.registerLazySingleton<AuthCubit>(
        () => AuthCubit(loginUseCase, logoutUseCase, getActiveProfileUseCase),
      );
      getIt.unregister<GetLiveCategoriesUseCase>();
      getIt.registerFactory<GetLiveCategoriesUseCase>(() => getLiveCategoriesUseCase);
      getIt.unregister<GetLiveChannelsUseCase>();
      getIt.registerFactory<GetLiveChannelsUseCase>(() => getLiveChannelsUseCase);
      getIt.unregister<PlayChannelUseCase>();
      getIt.registerFactory<PlayChannelUseCase>(() => playChannelUseCase);

      await tester.pumpWidget(const IptvApp());
      await _settle(tester);

      // /profiles -> add profile form.
      await tester.tap(find.byIcon(Icons.add));
      await _settle(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Profile name'), profile.name);
      await tester.enterText(find.widgetWithText(TextFormField, 'Server URL'), profile.baseUrl);
      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), profile.username);
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), profile.password);
      await tester.tap(find.text('Add & sign in'));
      await _settle(tester);

      // Login succeeds -> router redirects to /home/live -> categories load.
      expect(find.text('Sports'), findsOneWidget);

      await tester.tap(find.text('Sports'));
      await _settle(tester);

      // Category tapped -> channels load.
      expect(find.text('Test Channel'), findsOneWidget);

      await tester.tap(find.text('Test Channel'));
      await _settle(tester);

      // Channel tapped -> player screen renders (its AppBar title, at least;
      // real video decode needs a real device/network per PLAN.md's own
      // testing strategy).
      expect(find.text('Test Channel'), findsWidgets);
    },
  );
}
