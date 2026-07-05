import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_now_next_usecase.dart';
import '../cubit/now_next_cubit.dart';

/// Drop-in "now/next" strip for a channel row or the player chrome. Loads
/// lazily per instance (so, embedded in a `ListView.builder` row, it only
/// fires for channels actually scrolled into view) and never blocks or
/// visibly errors — EPG is supplementary, not critical path.
class NowNextStrip extends StatelessWidget {
  const NowNextStrip({super.key, required this.channelId});

  final int channelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NowNextCubit(getIt<GetNowNextUseCase>())..load(channelId),
      child: BlocBuilder<NowNextCubit, NowNextState>(
        builder: (context, state) {
          if (state is! NowNextLoaded || state.programs.isEmpty) {
            return const SizedBox.shrink();
          }

          final now = state.programs.first;
          final next = state.programs.length > 1 ? state.programs[1] : null;
          final timeFormat = DateFormat.Hm();

          return Text(
            [
              'Now: ${now.title}${now.end != null ? ' (until ${timeFormat.format(now.end!)})' : ''}',
              if (next != null) 'Next: ${next.title}',
            ].join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          );
        },
      ),
    );
  }
}
