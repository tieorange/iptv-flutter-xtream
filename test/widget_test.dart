import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptv/core/di/injection.dart';
import 'package:iptv/core/storage/secure_storage.dart';
import 'package:iptv/main.dart';

/// [SecureStorage] talks to the Keychain over a platform channel that has no
/// handler in plain widget tests — calls hang forever rather than throwing,
/// so DI is overridden with this in-memory double before every test.
class _FakeSecureStorage extends SecureStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);
}

void _configureTestDependencies() {
  configureDependencies();
  getIt.unregister<SecureStorage>();
  getIt.registerLazySingleton<SecureStorage>(() => _FakeSecureStorage());
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('lands on /profiles with empty state when no profiles saved', (tester) async {
    _configureTestDependencies();
    await tester.pumpWidget(const IptvApp());
    await _settle(tester);

    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('No profiles yet. Tap + to add one.'), findsOneWidget);
  });

  testWidgets('add-profile form is reachable and shows required fields', (tester) async {
    _configureTestDependencies();
    await tester.pumpWidget(const IptvApp());
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await _settle(tester);

    expect(find.text('Server URL'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
