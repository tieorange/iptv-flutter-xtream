/// Build-time configuration, supplied via `--dart-define-from-file` (see
/// `dart_define.example.json` / `dart_define.local.json` at the repo root).
/// Never hardcode a real key here — this class only reads what the build
/// was configured with.
class Env {
  const Env._();

  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  static bool get hasOpenAiApiKey => openAiApiKey.trim().isNotEmpty;

  /// Dev convenience only: when set, `AuthCubit.restoreActiveProfile()` auto
  /// signs in with these instead of landing on an empty profile list every
  /// simulator relaunch. See `dev_credentials.local.md` (gitignored) for
  /// where these values come from — never hardcode real credentials here.
  static const devXtreamUrl = String.fromEnvironment('DEV_XTREAM_URL');
  static const devXtreamUsername = String.fromEnvironment('DEV_XTREAM_USERNAME');
  static const devXtreamPassword = String.fromEnvironment('DEV_XTREAM_PASSWORD');

  static bool get hasDevXtreamCredentials =>
      devXtreamUrl.trim().isNotEmpty &&
      devXtreamUsername.trim().isNotEmpty &&
      devXtreamPassword.trim().isNotEmpty;
}
