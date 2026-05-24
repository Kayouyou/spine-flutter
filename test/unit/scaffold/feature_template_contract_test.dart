import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature scaffold contract', () {
    test('feature barrel does not use import side-effect registration', () {
      final file = File(
        'bricks/feature/__brick__/lib/feature_{{name}}.dart',
      );
      final content = file.readAsStringSync();

      expect(
        content.contains('FeatureRegistry.instance.register'),
        isFalse,
        reason: 'Feature 接入必须只在 root composition root 显式注册',
      );
    });

    test('make create-feature output reminds root explicit registration', () {
      final file = File('makefile');
      final content = file.readAsStringSync();

      expect(
        content.contains('lib/core/di/setup.dart'),
        isTrue,
        reason: '创建 feature 后必须提示开发者去 root setup 显式注册',
      );
    });

    test('feature route template does not access GetIt directly', () {
      final file = File(
        'bricks/feature/__brick__/lib/src/routes/{{name}}_route_module.dart',
      );
      final content = file.readAsStringSync();

      expect(
        content.contains('GetIt.instance'),
        isFalse,
        reason: '新生成的 feature route module 不应重新引入直接取 DI 的旧模式',
      );
      expect(
        content.contains('createCubit'),
        isTrue,
        reason: 'route module 应通过 setup.dart 传入 cubit 工厂',
      );
      expect(
        content.contains('ctx.routeWrapper'),
        isTrue,
        reason: '新生成的页面也应套上统一 routeWrapper，如 RequestScope',
      );
    });

    test('feature setup template wires route module with injected factory', () {
      final file = File(
        'bricks/feature/__brick__/lib/src/di/setup.dart',
      );
      final content = file.readAsStringSync();

      expect(
        content.contains('createCubit: () => sl<{{name.pascalCase()}}Cubit>()'),
        isTrue,
        reason: 'setup 模板必须把 cubit 工厂显式传给 route module',
      );
    });

    test('workspace version check includes bricks templates', () {
      final file = File('scripts/check_workspace_versions.dart');
      final content = file.readAsStringSync();

      expect(
        content.contains('/bricks/'),
        isFalse,
        reason: '版本漂移检查不能跳过 Mason 模板，否则新生成代码会重新带入旧版本',
      );
    });

    test('brick pubspec versions are aligned with workspace guard', () {
      final featureBrick =
          File('bricks/feature/__brick__/pubspec.yaml').readAsStringSync();
      final apiBrick =
          File('bricks/api/__brick__/pubspec.yaml').readAsStringSync();

      expect(featureBrick.contains('flutter_bloc: ^9.1.1'), isTrue);
      expect(featureBrick.contains('get_it: ^7.7.0'), isTrue);
      expect(featureBrick.contains('go_router: ^14.2.7'), isTrue);
      expect(featureBrick.contains('build_runner: ^2.4.9'), isTrue);
      expect(featureBrick.contains('freezed: ^2.5.2'), isTrue);
      expect(apiBrick.contains('build_runner: ^2.4.9'), isTrue);
      expect(apiBrick.contains('freezed: ^2.5.2'), isTrue);
    });
  });
}
