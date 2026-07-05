import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../player/presentation/cubit/player_cubit.dart';
import '../../../player/presentation/widgets/player_body.dart';
import '../../domain/entities/vod_detail.dart';

class VodPlayerPage extends StatelessWidget {
  const VodPlayerPage({super.key, required this.detail});

  final VodDetail detail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlayerCubit>()..playVodItem(detail),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(detail.name)),
            body: Center(
              child: PlayerBody(
                onRetry: () => context.read<PlayerCubit>().playVodItem(detail),
              ),
            ),
          );
        },
      ),
    );
  }
}
