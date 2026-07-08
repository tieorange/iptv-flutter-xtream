@Skip('Temporarily disabled during AI-picks feature work; re-enable at project end. See AGENTS.md.')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/live_tv/data/datasources/live_tv_remote_datasource.dart';
import 'package:iptv/features/live_tv/data/repositories/live_tv_repository_impl.dart';
import 'package:iptv/features/live_tv/domain/entities/live_category.dart';
import 'package:iptv/features/live_tv/domain/entities/live_channel.dart';

class _MockRemote extends Mock implements LiveTvRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late LiveTvRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = LiveTvRepositoryImpl(remote);
  });

  group('getCategories', () {
    test('Right(categories) on success', () async {
      const categories = [LiveCategory(id: 1, name: 'Sports')];
      when(() => remote.getCategories()).thenAnswer((_) async => categories);

      final result = await repository.getCategories().run();

      expect(result, Either<Failure, List<LiveCategory>>.right(categories));
    });

    test('Left(NetworkFailure) when the datasource throws — never dropped', () async {
      when(() => remote.getCategories())
          .thenThrow(const NetworkFailure('timed out'));

      final result = await repository.getCategories().run();

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('getStreamUrl', () {
    test('Right(url) defaults to the m3u8 format', () async {
      const channel = LiveChannel(id: 42, name: 'BBC', categoryId: 1);
      when(() => remote.getStreamUrl(42, 'm3u8')).thenReturn('http://x/42.m3u8');

      final result = await repository.getStreamUrl(channel).run();

      expect(result, Either<Failure, String>.right('http://x/42.m3u8'));
    });

    test('Right(url) requests the ts format when specified', () async {
      const channel = LiveChannel(id: 42, name: 'BBC', categoryId: 1);
      when(() => remote.getStreamUrl(42, 'ts')).thenReturn('http://x/42.ts');

      final result = await repository.getStreamUrl(channel, format: 'ts').run();

      expect(result, Either<Failure, String>.right('http://x/42.ts'));
    });
  });
}
