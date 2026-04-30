import 'app.dart';
import 'core/startup/launcher.dart';
import 'core/di/setup.dart';

void main() {
  // 配置依赖注入
  setupDependencies();
  configureEasyLoading();

  // 启动App
  AppLauncher.launch(const MyApp());
}