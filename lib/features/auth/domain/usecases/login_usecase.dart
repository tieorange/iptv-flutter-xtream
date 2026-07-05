import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/provider_profile.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  TaskEither<Failure, ProviderProfile> call(ProviderProfile profile) {
    return _repository.login(profile);
  }
}
