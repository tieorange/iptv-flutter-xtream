import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/provider_profile.dart';

abstract interface class AuthRepository {
  /// Validates [profile]'s credentials against its panel and, on success,
  /// persists it as the active profile.
  TaskEither<Failure, ProviderProfile> login(ProviderProfile profile);

  TaskEither<Failure, Unit> logout();

  TaskEither<Failure, ProviderProfile?> getActiveProfile();

  TaskEither<Failure, List<ProviderProfile>> getSavedProfiles();

  TaskEither<Failure, Unit> saveProfile(ProviderProfile profile);

  TaskEither<Failure, Unit> deleteProfile(String profileId);
}
