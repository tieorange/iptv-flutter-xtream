import 'dart:io' show Platform;

import 'package:flutter_chrome_cast/cast_context.dart';
import 'package:flutter_chrome_cast/entities.dart';
import 'package:flutter_chrome_cast/models.dart';

/// Google's unregistered, no-setup "Default Media Receiver" — fine for a
/// generic client that doesn't need a custom receiver UI/business logic.
/// See https://developers.google.com/cast/docs/web_receiver#default_media_receiver
const kDefaultCastReceiverAppId =
    GoogleCastDiscoveryCriteria.kDefaultApplicationId;

/// Initializes the Google Cast SDK once at app startup, mirroring
/// `AVAudioSession` setup in `AppDelegate.swift` for AirPlay — this is the
/// equivalent one-time platform bootstrap for Chromecast.
Future<void> initializeCasting() async {
  if (!Platform.isIOS && !Platform.isAndroid) return;
  final options = Platform.isIOS
      ? IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
            kDefaultCastReceiverAppId,
          ),
        )
      : GoogleCastOptionsAndroid(appId: kDefaultCastReceiverAppId);
  await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
}
