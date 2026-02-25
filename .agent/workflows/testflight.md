---
description: Build and Prepare for TestFlight
---

Use this workflow when you want to create a new build for TestFlight. It will automatically increment the build number and run the flutter build command.

1. Increment the build number
// turbo
dart scripts/increment_build.dart

2. Clean build cache (optional but recommended for version changes)
// turbo
flutter clean

3. Get dependencies
// turbo
flutter pub get

4. Build for iOS (IPA)
// turbo
flutter build ipa --release

5. The build is now ready in `build/ios/archive/Runner.xcarchive`. You can upload it using Transporter or Xcode.
