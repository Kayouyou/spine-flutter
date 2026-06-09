// scripts/check_workspace_versions.dart
import 'dart:io';

const trackedPackages = [
  'get_it',
  'go_router',
  'flutter_bloc',
  'freezed_annotation',
  'freezed',
  'build_runner',
  'mocktail',
  'dio',
  'alice',
  'hive_generator',
  'bloc_test',
  'retrofit',
  'json_annotation',
  'json_serializable',
  'lints',
  'sentry_flutter',
  'flutter_lints',
];

void main() {
  final skipDirs = ['.worktrees', '.fvm', 'ios/.symlinks', '.pub-cache', '/build/'];

  final pubspecs = Directory('.')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('pubspec.yaml'))
      .where((file) => !skipDirs.any((d) => file.path.contains(d)))
      .toList();

  final versions = <String, Map<String, String>>{};

  for (final file in pubspecs) {
    final content = file.readAsStringSync();
    for (final pkg in trackedPackages) {
      final match = RegExp('^\\s{2}$pkg:\\s*(.+)\$', multiLine: true)
          .firstMatch(content);
      if (match != null) {
        versions.putIfAbsent(pkg, () => {});
        final raw = match.group(1)!.trim();
        final version = raw.split('#').first.trim();
        versions[pkg]![file.path] = version;
      }
    }
  }

  var hasDrift = false;
  versions.forEach((pkg, entries) {
    final unique = entries.values.toSet();
    if (unique.length > 1) {
      hasDrift = true;
      stderr.writeln('Version drift for $pkg:');
      entries.forEach((path, version) => stderr.writeln('  $path -> $version'));
    }
  });

  if (hasDrift) exitCode = 1;
}
