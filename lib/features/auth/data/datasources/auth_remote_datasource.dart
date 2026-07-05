import 'package:xtream_code_client/xtream_code_client.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/provider_profile.dart';

/// Wraps `player_api.php` auth. Xtream panels don't have a dedicated login
/// endpoint — [XtreamClient.serverInformation] IS the credential check: a
/// wrong password commonly comes back as HTTP 200 with `user_info.auth`
/// false/0 rather than a 401, so both paths (transport error and
/// `auth != true`) must be treated as an [AuthFailure].
class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  Future<GeneralInformation> verifyCredentials(ProviderProfile profile) async {
    final client = XtreamClient(
      url: profile.baseUrl,
      username: profile.username,
      password: profile.password,
    );

    try {
      final result = await client.serverInformation();
      final userInfo = result.data.userInfo;

      if (userInfo.auth != true) {
        throw AuthFailure(userInfo.message ?? 'Invalid username or password.');
      }
      if (userInfo.status != null && userInfo.status != 'Active') {
        throw AuthFailure('Account status: ${userInfo.status}.');
      }

      return result.data;
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    } finally {
      client.close();
    }
  }
}
