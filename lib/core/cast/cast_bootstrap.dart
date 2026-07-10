import 'dart:io' show Platform;

import 'package:flutter_chrome_cast/cast_context.dart';

/// Google's unregistered, no-setup "Default Media Receiver" — fine for a
/// generic client that doesn't need a custom receiver UI/business logic.
/// See https://developers.google.com/cast/docs/web_receiver#default_media_receiver
const kDefaultCastReceiverAppId = 'CC1AD845';

/// Initializes the Google Cast SDK once at app startup, mirroring
/// `AVAudioSession` setup in `AppDelegate.swift` for AirPlay — this is the
/// equivalent one-time platform bootstrap for Chromecast.
///
/// NOTE: constructor/field names here should be re-verified against
/// `flutter_chrome_cast`'s current API once `flutter pub get` has run —
/// this was written without access to a Flutter/Dart toolchain to compile
/// against the installed package version.
Future<void> initializeCasting() async {
  if (!Platform.isIOS && !Platform.isAndroid) return;
  final options = Platform.isIOS
      ? IOSGoogleCastOptions(appId: kDefaultCastReceiverAppId)
      : GoogleCastOptionsAndroid(appId: kDefaultCastReceiverAppId);
  await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
}
