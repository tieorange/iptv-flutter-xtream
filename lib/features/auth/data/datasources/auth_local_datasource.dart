import '../../../../core/storage/profile_local_store.dart';
import '../../domain/entities/provider_profile.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._profileLocalStore);

  final ProfileLocalStore _profileLocalStore;

  Future<List<ProviderProfile>> getSavedProfiles() async {
    final rows = await _profileLocalStore.getAll();
    return rows.map(_fromJson).toList();
  }

  Future<void> saveProfile(ProviderProfile profile) =>
      _profileLocalStore.save(_toJson(profile));

  Future<void> deleteProfile(String profileId) =>
      _profileLocalStore.delete(profileId);

  Future<void> setActiveProfileId(String profileId) =>
      _profileLocalStore.setActiveProfileId(profileId);

  Future<void> clearActiveProfile() => _profileLocalStore.clearActiveProfile();

  Future<ProviderProfile?> getActiveProfile() async {
    final activeId = await _profileLocalStore.getActiveProfileId();
    if (activeId == null) return null;

    final profiles = await getSavedProfiles();
    for (final profile in profiles) {
      if (profile.id == activeId) return profile;
    }
    return null;
  }

  Map<String, dynamic> _toJson(ProviderProfile profile) => {
        'id': profile.id,
        'name': profile.name,
        'baseUrl': profile.baseUrl,
        'username': profile.username,
        'password': profile.password,
        'createdAt': profile.createdAt.toIso8601String(),
      };

  ProviderProfile _fromJson(Map<String, dynamic> json) => ProviderProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        baseUrl: json['baseUrl'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
