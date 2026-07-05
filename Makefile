.PHONY: clean setup analyze test build-ios-sim run-ios

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
	flutter build ios --simulator --debug

# Run the app on the iOS simulator
# Note: This command tries to open the Simulator app first, then runs flutter.
# You can also specify a device ID like: flutter run -d "iPhone 15 Pro"
run-ios:
	open -a Simulator
	flutter run -d iPhone

# Format code
format:
	dart format .
