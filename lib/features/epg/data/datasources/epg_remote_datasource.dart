import 'package:xtream_code_client/xtream_code_client.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/xtream_client_factory.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/epg_program.dart';

class EpgRemoteDataSource {
  EpgRemoteDataSource(this._clientFactory, this._authCubit);

  final XtreamClientFactory _clientFactory;
  final AuthCubit _authCubit;

  XtreamClient? _cachedClient;
  String? _cachedProfileId;

  XtreamClient _client() {
    final state = _authCubit.state;
    if (state is! Authenticated) {
      throw const AuthFailure('No active profile to fetch EPG data.');
    }
    if (_cachedClient == null || _cachedProfileId != state.profile.id) {
      _cachedClient?.close();
      _cachedClient = _clientFactory.forProfile(state.profile);
      _cachedProfileId = state.profile.id;
    }
    return _cachedClient!;
  }

  Future<List<EpgProgram>> getNowNext(int channelId) async {
    try {
      final epg = await _client().channelEpgViaStreamIdData(channelId, 2);
      return (epg.epgListings ?? const [])
          .where((listing) => listing.title != null)
          .map((listing) => EpgProgram(
                title: listing.title!,
                start: listing.start ?? listing.startTimestamp,
                end: listing.end ?? listing.stop ?? listing.stopTimestamp,
                description: listing.description,
              ))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }
}
