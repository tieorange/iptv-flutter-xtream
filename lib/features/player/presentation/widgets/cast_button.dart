import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../live_tv/domain/entities/live_channel.dart';
import '../../domain/entities/cast_device.dart';
import '../../domain/entities/cast_session_state.dart';
import '../cubit/cast_cubit.dart';

/// Device-picker button for Chromecast. Unlike [AirplayButton], this is
/// placed once per player screen regardless of which local engine (AV or
/// mpv) is active — casting doesn't depend on local decode support.
class CastButton extends StatelessWidget {
  const CastButton({super.key, required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CastCubit>();
    final state = cubit.state;
    final isConnected = state is CastConnected || state is CastConnecting;
    return IconButton(
      icon: Icon(
        isConnected ? Icons.cast_connected : Icons.cast,
        color: Colors.white,
      ),
      onPressed: () =>
          isConnected ? cubit.stopCasting() : _showDevicePicker(context, cubit),
    );
  }

  Future<void> _showDevicePicker(BuildContext context, CastCubit cubit) async {
    await cubit.startDiscovery();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => StreamBuilder<List<CastDevice>>(
        stream: cubit.devices,
        initialData: const [],
        builder: (context, snapshot) {
          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Searching for Chromecast devices…')),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final device in devices)
                ListTile(
                  leading: const Icon(Icons.cast),
                  title: Text(device.friendlyName),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    cubit.castChannel(channel, device);
                  },
                ),
            ],
          );
        },
      ),
    );
    await cubit.stopDiscovery();
  }
}
