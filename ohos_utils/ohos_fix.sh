#!/bin/bash
# ============================================================
# ohos_fix.sh — OHOS 配置兜底 (spine_flutter 骨架, 无自定义本地插件)
#
# 用法:   ./ohos_utils/ohos_fix.sh
# 时机:   每次 flutter pub get / flutter build hap 之前或之后运行
#
# 与参考项目 ovs_upgrade_335 的区别:
#   本骨架仅使用 pub.dev 通用插件 (connectivity_plus / path_provider / hive 等),
#   无 baidu_map / fluwx / app_links 等自定义或本地原生模块,
#   因此:
#     • 不需要把 pub cache 的原生层同步到 ohos/<plugin> 目录;
#     • 不需要从 templates/ 覆盖 GeneratedPluginRegistrant.ets
#       (flutter create --platforms=ohos . 已用 3.35 模板生成正确文件)。
#   本脚本只做「清理 stale lock + 校验插件注册数」, 保持幂等、不破坏生成物。
#
# 若后续引入自定义/本地原生模块 (K1 场景), 在此扩展同步逻辑即可。
# ============================================================
set -e

OHOS_DIR="$(cd "$(dirname "$0")/../ohos" && pwd)"
REGISTRANT="$OHOS_DIR/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets"

# ─── 1. Flutter 版本 (信息) ───
FLUTTER_VERSION=""
if [ -f "$OHOS_DIR/../.fvmrc" ]; then
  FLUTTER_VERSION=$(grep -o '"flutter": *"[^"]*"' "$OHOS_DIR/../.fvmrc" | tail -1 | sed 's/.*"\([^"]*\)".*/\1/')
fi
echo "🔧 [ohos_fix] Flutter: ${FLUTTER_VERSION:-unknown} (OHOS 模板由 flutter create 直接生成)"

# ─── 2. 清理 stale oh-package-lock.json5 ───
# 这些文件由 ohpm 在 install 时重新生成; 残留 lock 可能写死旧绝对路径,
# 导致 "00617202 Fetch Local Package Failed"。清理可避免该坑。
find "$OHOS_DIR" -name "oh-package-lock.json5" -delete 2>/dev/null || true
rm -rf "$OHOS_DIR/oh_modules/.ohpm/lock.json5" 2>/dev/null || true
echo "  ✅ 清理 oh-package-lock.json5"

# ─── 3. 校验插件注册 (K1 兜底) ───
if [ -f "$REGISTRANT" ]; then
  PLUGIN_COUNT=$(grep -c 'add(new' "$REGISTRANT" 2>/dev/null || echo 0)
  echo "  📋 GeneratedPluginRegistrant.ets 注册插件数: $PLUGIN_COUNT"
  if [ "$PLUGIN_COUNT" -eq 0 ]; then
    echo "  ⚠️  注册数为 0: 可能 pub get 尚未解析到带 ohos 支持的插件,"
    echo "      或 flutter build hap 尚未运行。请确认 pubspec 含 ohos 插件后重跑 --full。"
  fi
else
  echo "  ⚠️  未找到 $REGISTRANT (flutter create --platforms=ohos . 是否已执行?)"
fi

echo "🔧 [ohos_fix] 完成 (本骨架无自定义原生模块, 无需覆盖 registrant)。"
