import 'package:xtream_code_client/xtream_code_client.dart';

import '../../features/auth/domain/entities/provider_profile.dart';

/// Builds an [XtreamClient] per profile. A client is bound to one
/// baseUrl/username/password at construction, so it's never a get_it
/// singleton — callers cache one per active profile and rebuild on switch.
class XtreamClientFactory {
  XtreamClient forProfile(ProviderProfile profile) {
    return XtreamClient(
      url: profile.baseUrl,
      username: profile.username,
      password: profile.password,
    );
  }
}
