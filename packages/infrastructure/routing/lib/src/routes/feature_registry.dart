import 'package:get_it/get_it.dart';

/// Feature DI 注册中心（收集器模式）
///
/// 各 Feature 的 setup 函数通过显式注册收集到此，
/// Root DI 调用 runAll(sl) 统一执行。
///
/// 使用：
///   // Root DI (setup.dart)
///   FeatureRegistry.instance.register('feature_home', setupFeatureHome);
///   FeatureRegistry.instance.register('feature_detail', setupFeatureDetail);
///   FeatureRegistry.instance.runAll(sl);
class FeatureRegistry {
  static final FeatureRegistry instance = FeatureRegistry._();
  FeatureRegistry._();

  final List<void Function(GetIt)> _setups = [];
  final Set<String> _names = {};

  /// 注册 Feature 的 DI setup 函数，返回 name 用于顶层赋值
  String register(String name, void Function(GetIt) setup) {
    if (_names.contains(name)) return name; // 防重复注册
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
