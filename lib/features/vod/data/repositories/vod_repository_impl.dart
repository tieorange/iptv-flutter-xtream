import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/vod_category.dart';
import '../../domain/entities/vod_detail.dart';
import '../../domain/entities/vod_item.dart';
import '../../domain/repositories/vod_repository.dart';
import '../datasources/vod_remote_datasource.dart';

class VodRepositoryImpl implements VodRepository {
  VodRepositoryImpl(this._remote);

  final VodRemoteDataSource _remote;

  @override
  TaskEither<Failure, List<VodCategory>> getCategories() {
    return TaskEither.tryCatch(() => _remote.getCategories(), _toFailure);
  }

  @override
  TaskEither<Failure, List<VodItem>> getItems(int categoryId) {
    return TaskEither.tryCatch(() => _remote.getItems(categoryId), _toFailure);
  }

  @override
  TaskEither<Failure, VodDetail> getDetail(VodItem item) {
    return TaskEither.tryCatch(() => _remote.getDetail(item), _toFailure);
  }

  @override
  TaskEither<Failure, String> getStreamUrl(VodDetail detail) {
    return TaskEither.tryCatch(
      () async => _remote.getStreamUrl(detail.streamId, detail.containerExtension ?? 'mp4'),
      _toFailure,
    );
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(error.toString());
  }
}
