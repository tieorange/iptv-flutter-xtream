import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/epg/data/datasources/epg_remote_datasource.dart';
import 'package:iptv/features/epg/data/repositories/epg_repository_impl.dart';
import 'package:iptv/features/epg/domain/entities/epg_program.dart';

class _MockRemote extends Mock implements EpgRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late EpgRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = EpgRepositoryImpl(remote);
  });

  test('Right(programs) on success', () async {
    final programs = [const EpgProgram(title: 'News')];
    when(() => remote.getNowNext(1)).thenAnswer((_) async => programs);

    final result = await repository.getNowNext(1).run();

    expect(result, Either<Failure, List<EpgProgram>>.right(programs));
  });

  test('Left(Failure) is preserved rather than dropped on error', () async {
    when(() => remote.getNowNext(1)).thenThrow(const NetworkFailure('down'));

    final result = await repository.getNowNext(1).run();

    expect(result.isLeft(), isTrue);
  });
}
