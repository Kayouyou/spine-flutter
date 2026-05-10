import 'package:get_it/get_it.dart';

/// Feature DI 注册中心
///
/// 每个 Feature 在自己的 barrel 文件中注册 setup 函数，
/// Root DI 只需调用 runAll(sl) 即可运行全部 setup。
///
/// 使用：
///   // Feature barrel 文件中
///   FeatureRegistry.instance.register('feature_home', setupFeatureHome);
///
///   // Root DI
///   FeatureRegistry.instance.runAll(sl);
class FeatureRegistry {
  static final FeatureRegistry instance = FeatureRegistry._();
  FeatureRegistry._();

  final List<void Function(GetIt)> _setups = [];
  final Set<String> _names = {};

  /// 注册 Feature 的 DI setup 函数，返回 name 用于顶层赋值
  String register(String name, void Function(GetIt) setup) {
    if (_names.contains(name)) {
      throw StateError('Feature "$name" already registered');
    }
    _names.add(name);
    _setups.add(setup);
    return name;
  }

  /// 运行所有已注册的 setup 函数
  void runAll(GetIt sl) {
    for (final setup in _setups) {
      setup(sl);
    }
  }

  /// 清空（测试用）
  void clear() {
    _setups.clear();
    _names.clear();
  }
}
