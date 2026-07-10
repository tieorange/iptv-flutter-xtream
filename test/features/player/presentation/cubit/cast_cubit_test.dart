import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/live_tv/domain/entities/live_channel.dart';
import 'package:iptv/features/player/domain/entities/cast_device.dart';
import 'package:iptv/features/player/domain/entities/cast_media_request.dart';
import 'package:iptv/features/player/domain/entities/cast_session_state.dart';
import 'package:iptv/features/player/domain/services/cast_controller.dart';
import 'package:iptv/features/player/domain/usecases/cast_channel_usecase.dart';
import 'package:iptv/features/player/presentation/cubit/cast_cubit.dart';

class _MockCastController extends Mock implements CastController {}

class _MockCastChannelUseCase extends Mock implements CastChannelUseCase {}

void main() {
  late _MockCastController controller;
  late _MockCastChannelUseCase useCase;
  late StreamController<CastSessionState> sessionStateController;
  late CastCubit cubit;

  const channel = LiveChannel(id: 1, name: 'Test Channel', categoryId: 1);
  const device = CastDevice(id: 'dev-1', friendlyName: 'Living Room TV');
  const request = CastMediaRequest(
    url: 'http://panel/live/u/p/1.ts',
    container: CastStreamContainer.mpegTs,
    title: 'Test Channel',
  );

  setUpAll(() {
    registerFallbackValue(
      const CastMediaRequest(url: '', container: CastStreamContainer.mpegTs, title: ''),
    );
  });

  setUp(() {
    controller = _MockCastController();
    useCase = _MockCastChannelUseCase();
    sessionStateController = StreamController<CastSessionState>.broadcast();
    when(() => controller.sessionState).thenAnswer((_) => sessionStateController.stream);
    when(() => controller.connect(device)).thenAnswer((_) async {});
    when(() => controller.disconnect()).thenAnswer((_) async {});
    when(() => controller.loadMedia(any())).thenAnswer((_) async {});
    when(() => controller.dispose()).thenReturn(null);
    cubit = CastCubit(controller, useCase);
  });

  tearDown(() async {
    await cubit.close();
    await sessionStateController.close();
  });

  test('connect starts the session and loads media once it reports connected', () async {
    when(() => useCase(channel)).thenReturn(TaskEither.right(request));

    await cubit.castChannel(channel, device);
    sessionStateController.add(const CastConnected(device));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    verify(() => controller.connect(device)).called(1);
    verify(() => controller.loadMedia(request)).called(1);
    expect(cubit.state, isA<CastConnected>());
  });

  test('stopCasting disconnects the session', () async {
    await cubit.stopCasting();

    verify(() => controller.disconnect()).called(1);
  });

  test('surfaces a CastSessionError if resolving the castable URL fails', () async {
    when(() => useCase(channel)).thenReturn(
      TaskEither.left(const PlaybackFailure('resolve failed')),
    );

    await cubit.castChannel(channel, device);
    sessionStateController.add(const CastConnected(device));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<CastSessionError>());
    verifyNever(() => controller.loadMedia(any()));
  });
}
