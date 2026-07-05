sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
