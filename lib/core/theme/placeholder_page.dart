import 'package:flutter/material.dart';

/// Temporary body for routes not yet implemented past M0. Each milestone
/// replaces the corresponding call site with the real feature page.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('TODO: $title')),
    );
  }
}
