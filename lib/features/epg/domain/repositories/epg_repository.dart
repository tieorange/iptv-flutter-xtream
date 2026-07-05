import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/epg_program.dart';

abstract interface class EpgRepository {
  /// Returns up to 2 entries: the currently airing program and the next
  /// one, from the panel's `get_short_epg` action.
  TaskEither<Failure, List<EpgProgram>> getNowNext(int channelId);
}
