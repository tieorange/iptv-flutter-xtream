import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/live_category.dart';
import '../entities/live_channel.dart';

abstract interface class LiveTvRepository {
  TaskEither<Failure, List<LiveCategory>> getCategories();

  TaskEither<Failure, List<LiveChannel>> getChannels(int categoryId);

  /// All channels across every category in one call (the panel returns the
  /// full list when `category_id` is omitted) — used by search rather than
  /// fetching category-by-category.
  TaskEither<Failure, List<LiveChannel>> getAllChannels();

  /// Resolves a channel's playback URL for the given output [format]
  /// (`m3u8` or `ts`). Building the URL is pure string work against the
  /// cached Xtream client — the only failure mode is "not logged in".
  TaskEither<Failure, String> getStreamUrl(LiveChannel channel, {String format});
}
