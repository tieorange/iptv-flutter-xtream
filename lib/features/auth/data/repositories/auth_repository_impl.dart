import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/provider_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  TaskEither<Failure, ProviderProfile> login(ProviderProfile profile) {
    return TaskEither.tryCatch(
      () async {
        await _remote.verifyCredentials(profile);
        await _local.saveProfile(profile);
        await _local.setActiveProfileId(profile.id);
        return profile;
      },
      _toFailure,
    );
  }

  @override
  TaskEither<Failure, Unit> logout() {
    return TaskEither.tryCatch(
      () async {
        await _local.clearActiveProfile();
        return unit;
      },
      _toFailure,
    );
  }

  @override
  TaskEither<Failure, ProviderProfile?> getActiveProfile() {
    return TaskEither.tryCatch(() => _local.getActiveProfile(), _toFailure);
  }

  @override
  TaskEither<Failure, List<ProviderProfile>> getSavedProfiles() {
    return TaskEither.tryCatch(() => _local.getSavedProfiles(), _toFailure);
  }

  @override
  TaskEither<Failure, Unit> saveProfile(ProviderProfile profile) {
    return TaskEither.tryCatch(
      () async {
        await _local.saveProfile(profile);
        return unit;
      },
      _toFailure,
    );
  }

  @override
  TaskEither<Failure, Unit> deleteProfile(String profileId) {
    return TaskEither.tryCatch(
      () async {
        await _local.deleteProfile(profileId);
        return unit;
      },
      _toFailure,
    );
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(error.toString());
  }
}
