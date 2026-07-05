import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/provider_profile.dart';
import '../repositories/auth_repository.dart';

/// Backs "stay logged in across relaunch" — checks local storage for the
/// previously active profile without hitting the panel again.
class GetActiveProfileUseCase {
  const GetActiveProfileUseCase(this._repository);

  final AuthRepository _repository;

  TaskEither<Failure, ProviderProfile?> call() => _repository.getActiveProfile();
}
