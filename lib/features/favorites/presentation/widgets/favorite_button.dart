import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/favorite_item.dart';
import '../../domain/usecases/is_favorite_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

/// Self-contained favorite toggle for a channel/VOD/series row or detail
/// page — reads/writes through the use cases directly rather than needing
/// a shared page-level cubit, mirroring `NowNextStrip`'s pattern.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.item});

  final FavoriteItem item;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _profileId {
    final state = getIt<AuthCubit>().state;
    return state is Authenticated ? state.profile.id : null;
  }

  Future<void> _load() async {
    final profileId = _profileId;
    if (profileId == null) return;
    final result = await getIt<IsFavoriteUseCase>()(profileId, widget.item).run();
    result.fold((_) {}, (isFavorite) {
      if (mounted) setState(() => _isFavorite = isFavorite);
    });
  }

  Future<void> _toggle() async {
    final profileId = _profileId;
    if (profileId == null) return;
    setState(() => _isFavorite = !(_isFavorite ?? false));
    await getIt<ToggleFavoriteUseCase>()(profileId, widget.item).run();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isFavorite == true ? Icons.favorite : Icons.favorite_border),
      onPressed: _profileId == null ? null : _toggle,
    );
  }
}
