import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';

/// Single shared [Talker] instance for the whole app — colored, leveled
/// console output printed straight to the `flutter run` terminal so it can
/// be copy/pasted for diagnosis. Terminal-only: no file writer, no in-app
/// viewer. Disabled outside debug/profile builds so nothing is ever printed
/// in a release build.
final Talker appTalker = Talker(
  settings: TalkerSettings(enabled: kDebugMode || kProfileMode),
);
