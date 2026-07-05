class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String username;
  final String password;
  final DateTime createdAt;

  ProviderProfile copyWith({
    String? name,
    String? baseUrl,
    String? username,
    String? password,
  }) {
    return ProviderProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt,
    );
  }
}
