# flutter_gen Integration - Learnings

## Version Compatibility
- flutter_gen_runner 5.8.0+ requires `dart_style >=2.3.7` (uses `DartFormatter.latestLanguageVersion`)
- Flutter 3.22.3 pins `meta` to 1.12.0, which conflicts with `dart_style >=2.3.7` (requires `meta ^1.14.0`)
- Solution: Use `flutter_gen_runner: ^5.7.0` (last version compatible with `dart_style 2.3.6`)

## Generated Code
- Output: `lib/gen/assets.gen.dart`
- When no assets exist, generates an empty `Assets` class
- Real assets (images, fonts) auto-generate typed references: `Assets.images.xxx`, `Assets.fonts.xxx`

## Configuration
- Keep `flutter_gen` config block in `pubspec.yaml` with `output: lib/gen/`
- Generated file should be committed (not gitignored) so CI doesn't need build_runner
