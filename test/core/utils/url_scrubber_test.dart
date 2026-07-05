import 'package:flutter_test/flutter_test.dart';

import 'package:iptv/core/utils/url_scrubber.dart';

void main() {
  group('scrubUrl', () {
    test('redacts username/password path segments and query params', () {
      final scrubbed = scrubUrl(
        'http://panel.example/player_api.php?username=alice&password=secret123',
      );

      expect(scrubbed, isNot(contains('alice')));
      expect(scrubbed, isNot(contains('secret123')));
    });
  });

  group('scrubMessage', () {
    test('redacts credentials embedded inside an exception message', () {
      const message = 'SocketException: Failed host lookup '
          '(uri: http://panel.example/live/alice/secret123/42.m3u8)';

      final scrubbed = scrubMessage(message);

      expect(scrubbed, isNot(contains('alice')));
      expect(scrubbed, isNot(contains('secret123')));
      expect(scrubbed, contains('/live/***/***/'));
    });

    test('redacts username=/password= query params inside a message', () {
      const message = 'Request to http://x/player_api.php?username=alice&password=secret123 failed';

      final scrubbed = scrubMessage(message);

      expect(scrubbed, isNot(contains('alice')));
      expect(scrubbed, isNot(contains('secret123')));
    });

    test('leaves non-credential text untouched', () {
      const message = 'Connection timed out after 5 seconds';

      expect(scrubMessage(message), message);
    });
  });
}
