import 'dart:convert';

import 'secure_storage.dart';

/// Stores saved provider profiles (server/username/password) and which one
/// is active. Backed by [SecureStorage]/Keychain rather than
/// SharedPreferences, since the profile blob includes the account password.
class ProfileLocalStore {
  ProfileLocalStore(this._secureStorage);

  static const _indexKey = 'profiles_index';
  static const _activeProfileKey = 'active_profile_id';

  final SecureStorage _secureStorage;

  Future<List<Map<String, dynamic>>> getAll() async {
    final raw = await _secureStorage.read(_indexKey);
    if (raw == null) return [];
    final ids = (jsonDecode(raw) as List).cast<String>();

    final profiles = <Map<String, dynamic>>[];
    for (final id in ids) {
      final json = await _secureStorage.read(_profileKey(id));
      if (json != null) profiles.add(jsonDecode(json) as Map<String, dynamic>);
    }
    return profiles;
  }

  Future<void> save(Map<String, dynamic> profileJson) async {
    final id = profileJson['id'] as String;
    await _secureStorage.write(_profileKey(id), jsonEncode(profileJson));

    final raw = await _secureStorage.read(_indexKey);
    final ids = raw == null ? <String>[] : (jsonDecode(raw) as List).cast<String>();
    if (!ids.contains(id)) {
      ids.add(id);
      await _secureStorage.write(_indexKey, jsonEncode(ids));
    }
  }

  Future<void> delete(String id) async {
    await _secureStorage.delete(_profileKey(id));

    final raw = await _secureStorage.read(_indexKey);
    if (raw == null) return;
    final ids = (jsonDecode(raw) as List).cast<String>()..remove(id);
    await _secureStorage.write(_indexKey, jsonEncode(ids));

    final activeId = await _secureStorage.read(_activeProfileKey);
    if (activeId == id) {
      await _secureStorage.delete(_activeProfileKey);
    }
  }

  Future<void> setActiveProfileId(String id) =>
      _secureStorage.write(_activeProfileKey, id);

  Future<String?> getActiveProfileId() =>
      _secureStorage.read(_activeProfileKey);

  Future<void> clearActiveProfile() => _secureStorage.delete(_activeProfileKey);

  String _profileKey(String id) => 'profile:$id';
}
