import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/auth/domain/entities/provider_profile.dart';
import 'package:iptv/features/auth/domain/usecases/get_active_profile_usecase.dart';
import 'package:iptv/features/auth/domain/usecases/login_usecase.dart';
import 'package:iptv/features/auth/domain/usecases/logout_usecase.dart';
import 'package:iptv/features/auth/presentation/cubit/auth_cubit.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

class _MockGetActiveProfileUseCase extends Mock
    implements GetActiveProfileUseCase {}

void main() {
  late _MockLoginUseCase loginUseCase;
  late _MockLogoutUseCase logoutUseCase;
  late _MockGetActiveProfileUseCase getActiveProfileUseCase;

  final profile = ProviderProfile(
    id: '1',
    name: 'Test',
    baseUrl: 'http://example.com',
    username: 'user',
    password: 'pass',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    loginUseCase = _MockLoginUseCase();
    logoutUseCase = _MockLogoutUseCase();
    getActiveProfileUseCase = _MockGetActiveProfileUseCase();
  });

  AuthCubit buildCubit() =>
      AuthCubit(loginUseCase, logoutUseCase, getActiveProfileUseCase);

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'restoreActiveProfile emits Unauthenticated when no profile is stored',
      setUp: () => when(() => getActiveProfileUseCase())
          .thenReturn(TaskEither.right(null)),
      build: buildCubit,
      act: (cubit) => cubit.restoreActiveProfile(),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'restoreActiveProfile emits Authenticated when a profile is already stored',
      setUp: () => when(() => getActiveProfileUseCase())
          .thenReturn(TaskEither.right(profile)),
      build: buildCubit,
      act: (cubit) => cubit.restoreActiveProfile(),
      expect: () => [const AuthLoading(), Authenticated(profile)],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits Authenticated on success — never drops the Right branch',
      setUp: () => when(() => loginUseCase(profile))
          .thenReturn(TaskEither.right(profile)),
      build: buildCubit,
      act: (cubit) => cubit.login(profile),
      expect: () => [const AuthLoading(), Authenticated(profile)],
    );

    blocTest<AuthCubit, AuthState>(
      'login emits AuthError on failure — never drops the Left branch',
      setUp: () => when(() => loginUseCase(profile)).thenReturn(
        TaskEither.left(const AuthFailure('Invalid username or password.')),
      ),
      build: buildCubit,
      act: (cubit) => cubit.login(profile),
      expect: () => [
        const AuthLoading(),
        const AuthError('Invalid username or password.'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout emits Unauthenticated on success',
      setUp: () =>
          when(() => logoutUseCase()).thenReturn(TaskEither.right(unit)),
      build: buildCubit,
      act: (cubit) => cubit.logout(),
      expect: () => [const Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'logout emits AuthError on failure — never drops the Left branch',
      setUp: () => when(() => logoutUseCase()).thenReturn(
        TaskEither.left(const CacheFailure('Could not clear storage.')),
      ),
      build: buildCubit,
      act: (cubit) => cubit.logout(),
      expect: () => [const AuthError('Could not clear storage.')],
    );
  });
}
