import 'package:flutter_bloc/flutter_bloc.dart';

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
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (profile) => emit(profile == null ? const Unauthenticated() : Authenticated(profile)),
    );
  }

  Future<void> login(ProviderProfile profile) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(profile).run();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (profile) => emit(Authenticated(profile)),
    );
  }

  Future<void> logout() async {
    final result = await _logoutUseCase().run();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Used only by tests/dev tooling that need to bypass a real panel.
  void debugSetAuthenticated(ProviderProfile profile) =>
      emit(Authenticated(profile));
}
