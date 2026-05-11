import 'package:get_it/get_it.dart';

/// Feature DI 注册中心（显式收集器模式）
///
/// 设计意图：
/// 1. 统一收集各 feature 的 setup 函数，runAll 统一执行，降低遗漏风险
/// 2. 提供防重复注册保护（register 的 _names 去重）
/// 3. 为未来可能的 feature 启动顺序控制（如 priority）预留扩展点
///
/// 为什么不直接在 root 调 setupFeatureXxx(sl)？
/// - 直接调用也能工作，但 FeatureRegistry 提供了额外的安全性保障
///   和统一执行入口。当 feature 数量增加时，runAll 比多行 setup 调用
///   更清晰，且防重复机制能避免 hot reload 场景下的 GetIt 冲突。
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
