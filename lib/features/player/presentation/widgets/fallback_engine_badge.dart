import 'package:flutter/material.dart';

/// Shown whenever playback fell back to the mpv engine, so the missing
/// AirPlay button reads as an explained limitation rather than a bug.
class FallbackEngineBadge extends StatelessWidget {
  const FallbackEngineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Compatibility mode — AirPlay unavailable',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
