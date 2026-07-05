import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/provider_profile.dart';
import '../repositories/auth_repository.dart';

class AddProfileUseCase {
  const AddProfileUseCase(this._repository);

  final AuthRepository _repository;

  TaskEither<Failure, Unit> call(ProviderProfile profile) =>
      _repository.saveProfile(profile);
}
