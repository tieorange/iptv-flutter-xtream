.PHONY: clean setup analyze test build-ios-sim run-ios

# dart_define.local.json (gitignored) holds real build-time secrets, e.g.
# OPENAI_API_KEY for the "Top 40 Now" AI picks feature. Falls back to the
# committed placeholder so the app still builds/runs with no key configured
# (the AI picks screen just shows a "not configured" error state).
DART_DEFINE_FILE := $(if $(wildcard dart_define.local.json),dart_define.local.json,dart_define.example.json)

# Clean the project workspace
clean:
	flutter clean

# Get dependencies
setup:
	flutter pub get

# Run static analysis
analyze:
	flutter analyze

# Run unit and widget tests
test:
	flutter test

# Build for iOS simulator (debug) - verifies native plugin builds
build-ios-sim:
	flutter build ios --simulator --debug --dart-define-from-file=$(DART_DEFINE_FILE)

# Run the app on the iOS simulator
# Note: This command tries to open the Simulator app first, then runs flutter.
# You can also specify a device ID like: flutter run -d "iPhone 15 Pro"
run-ios:
	open -a Simulator
	flutter run -d iPhone --dart-define-from-file=$(DART_DEFINE_FILE)

# Format code
format:
	dart format .
