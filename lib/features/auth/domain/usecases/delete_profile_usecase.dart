import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class DeleteProfileUseCase {
  const DeleteProfileUseCase(this._repository);

  final AuthRepository _repository;

  TaskEither<Failure, Unit> call(String profileId) =>
      _repository.deleteProfile(profileId);
}
