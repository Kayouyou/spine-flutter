/// Solo 项目默认最小化，高级能力需显式打开。
class BootstrapOptions {
  final bool enableDebugTools;
  final bool enableDataSync;
  final bool enableUpgradePrompt;

  const BootstrapOptions({
    this.enableDebugTools = false,
    this.enableDataSync = false,
    this.enableUpgradePrompt = false,
  });
}
