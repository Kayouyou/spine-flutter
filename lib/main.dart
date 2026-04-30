import 'app.dart';
import 'core/startup/launcher.dart';

void main() {
  // 启动App（内部已处理依赖注入、binding初始化）
  AppLauncher.launch(const MyApp());
}
