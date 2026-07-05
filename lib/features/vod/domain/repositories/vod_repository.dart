import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/vod_category.dart';
import '../entities/vod_detail.dart';
import '../entities/vod_item.dart';

abstract interface class VodRepository {
  TaskEither<Failure, List<VodCategory>> getCategories();

  TaskEither<Failure, List<VodItem>> getItems(int categoryId);

  /// All VOD items across every category — used by search.
  TaskEither<Failure, List<VodItem>> getAllItems();

  TaskEither<Failure, VodDetail> getDetail(VodItem item);

  /// Builds the playback URL using [detail.containerExtension] as reported
  /// by the panel — VOD is usually a direct file (mp4/mkv) or already-HLS,
  /// never assume one format like live TV's `.m3u8`-first default.
  TaskEither<Failure, String> getStreamUrl(VodDetail detail);
}
