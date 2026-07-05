import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/vod/data/datasources/vod_remote_datasource.dart';
import 'package:iptv/features/vod/data/repositories/vod_repository_impl.dart';
import 'package:iptv/features/vod/domain/entities/vod_detail.dart';

class _MockRemote extends Mock implements VodRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late VodRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = VodRepositoryImpl(remote);
  });

  group('getStreamUrl', () {
    test('Right(url) built from the detail container extension', () async {
      const detail = VodDetail(streamId: 7, name: 'Movie', containerExtension: 'mkv');
      when(() => remote.getStreamUrl(7, 'mkv')).thenReturn('http://x/7.mkv');

      final result = await repository.getStreamUrl(detail).run();

      expect(result, Either<Failure, String>.right('http://x/7.mkv'));
    });

    test('defaults to mp4 when the panel omits container_extension', () async {
      const detail = VodDetail(streamId: 7, name: 'Movie');
      when(() => remote.getStreamUrl(7, 'mp4')).thenReturn('http://x/7.mp4');

      final result = await repository.getStreamUrl(detail).run();

      expect(result, Either<Failure, String>.right('http://x/7.mp4'));
    });
  });
}
