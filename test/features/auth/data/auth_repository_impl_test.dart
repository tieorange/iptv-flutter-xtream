import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xtream_code_client/xtream_code_client.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:iptv/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:iptv/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:iptv/features/auth/domain/entities/provider_profile.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late AuthRepositoryImpl repository;

  final profile = ProviderProfile(
    id: '1',
    name: 'Test',
    baseUrl: 'http://example.com',
    username: 'user',
    password: 'pass',
    createdAt: DateTime(2026, 1, 1),
  );

  const generalInformation = GeneralInformation(
    userInfo: UserInfo(auth: true, status: 'Active'),
    serverInfo: ServerInfo(),
  );

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository = AuthRepositoryImpl(remote, local);
  });

  group('login', () {
    test('Right(profile) and persists it as active on success', () async {
      when(() => remote.verifyCredentials(profile))
          .thenAnswer((_) async => generalInformation);
      when(() => local.saveProfile(profile)).thenAnswer((_) async {});
      when(() => local.setActiveProfileId(profile.id)).thenAnswer((_) async {});

      final result = await repository.login(profile).run();

      expect(result, Either<Failure, ProviderProfile>.right(profile));
      verify(() => local.saveProfile(profile)).called(1);
      verify(() => local.setActiveProfileId(profile.id)).called(1);
    });

    test('Left(AuthFailure) when credential verification fails', () async {
      when(() => remote.verifyCredentials(profile))
          .thenThrow(const AuthFailure('Invalid username or password.'));

      final result = await repository.login(profile).run();

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.message, 'message', 'Invalid username or password.'),
      );
      verifyNever(() => local.saveProfile(profile));
    });
  });

  group('logout', () {
    test('Right(unit) clears the active profile', () async {
      when(() => local.clearActiveProfile()).thenAnswer((_) async {});

      final result = await repository.logout().run();

      expect(result, Either<Failure, Unit>.right(unit));
      verify(() => local.clearActiveProfile()).called(1);
    });
  });
}
