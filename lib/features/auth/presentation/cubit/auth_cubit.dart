import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/logging/app_talker.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/provider_profile.dart';
import '../../domain/usecases/get_active_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Authenticated extends AuthState {
  const Authenticated(this.profile);

  final ProviderProfile profile;

  @override
  bool operator ==(Object other) =>
      other is Authenticated && other.profile.id == profile.id;

  @override
  int get hashCode => profile.id.hashCode;
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is AuthError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._loginUseCase, this._logoutUseCase, this._getActiveProfileUseCase)
      : super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetActiveProfileUseCase _getActiveProfileUseCase;

  /// Called once at app startup (see `main.dart`) to check whether a
  /// profile survived relaunch. Kept out of the constructor so tests can
  /// drive it explicitly instead of racing an implicit side effect.
  Future<void> restoreActiveProfile() async {
    emit(const AuthLoading());
    final result = await _getActiveProfileUseCase().run();
    final profile = result.fold((failure) => null, (profile) => profile);

    if (profile != null) {
      appTalker.info('restoreActiveProfile: restored saved profile ${profile.name}');
      emit(Authenticated(profile));
      return;
    }

    if (Env.hasDevXtreamCredentials) {
      appTalker.info('restoreActiveProfile: no saved profile, using dev auto-login');
      await login(_devProfile());
      return;
    }

    appTalker.info('restoreActiveProfile: no saved profile, no dev credentials');
    emit(const Unauthenticated());
  }

  /// Dev convenience: auto-fills a profile from `DEV_XTREAM_*` dart-defines
  /// (see `Env.hasDevXtreamCredentials`) so a fresh simulator install
  /// doesn't need the "add profile" form filled in by hand every time. Only
  /// used when no profile was already saved — never overrides a real one.
  ProviderProfile _devProfile() {
    return ProviderProfile(
      id: 'dev-autofill',
      name: 'Dev (auto)',
      baseUrl: Env.devXtreamUrl,
      username: Env.devXtreamUsername,
      password: Env.devXtreamPassword,
      createdAt: DateTime.now(),
    );
  }

  Future<void> login(ProviderProfile profile) async {
    emit(const AuthLoading());
    appTalker.info('login: attempting ${profile.name} @ ${scrubUrl(profile.baseUrl)}');
    final result = await _loginUseCase(profile).run();
    result.fold(
      (failure) {
        appTalker.error('login: failed — ${scrubMessage(failure.message)}');
        emit(AuthError(failure.message));
      },
      (profile) {
        appTalker.info('login: succeeded for ${profile.name}');
        emit(Authenticated(profile));
      },
    );
  }

  Future<void> logout() async {
    final result = await _logoutUseCase().run();
    result.fold(
      (failure) {
        appTalker.error('logout: failed — ${scrubMessage(failure.message)}');
        emit(AuthError(failure.message));
      },
      (_) {
        appTalker.info('logout: succeeded');
        emit(const Unauthenticated());
      },
    );
  }

  /// Used only by tests/dev tooling that need to bypass a real panel.
  void debugSetAuthenticated(ProviderProfile profile) =>
      emit(Authenticated(profile));
}
