// 资源强类型访问（由 flutter_gen 自动生成 lib/gen/assets.gen.dart）:
//   Assets.images.xxx  /  Assets.fonts.xxx
// 使用: Image.asset(Assets.images.icon.path)

// Package imports:
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:error/error.dart';

// Project imports:
import 'app.dart';
import 'core/startup/launcher.dart';
import 'config.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = EnvironmentConfig.sentryDsn;
      options.tracesSampleRate = 0.1;
    },
    appRunner: () {
      // DSN 不为空时才注册 SentryReporter
      if (EnvironmentConfig.sentryDsn.isNotEmpty) {
        AppErrorHandler.instance.setReporter(SentryReporter());
      }
      // 启动App（内部已处理依赖注入、binding初始化）
      AppLauncher.launch(const MyApp());
    },
  );
}