import 'package:flutter/material.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';

/// Wraps `flutter_to_airplay`'s native `AVRoutePickerView` button. Only
/// ever placed in the AVPlayer engine's chrome — the mpv fallback engine
/// has no AirPlay route to offer.
class AirplayButton extends StatelessWidget {
  const AirplayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AirPlayIconButton(color: Colors.white);
  }
}
