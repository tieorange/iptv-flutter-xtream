import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/provider_profile.dart';
import '../repositories/auth_repository.dart';

class GetSavedProfilesUseCase {
  const GetSavedProfilesUseCase(this._repository);

  final AuthRepository _repository;

  TaskEither<Failure, List<ProviderProfile>> call() =>
      _repository.getSavedProfiles();
}
