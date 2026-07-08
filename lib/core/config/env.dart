/// Build-time configuration, supplied via `--dart-define-from-file` (see
/// `dart_define.example.json` / `dart_define.local.json` at the repo root).
/// Never hardcode a real key here — this class only reads what the build
/// was configured with.
class Env {
  const Env._();

  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  static bool get hasOpenAiApiKey => openAiApiKey.trim().isNotEmpty;
}
