#!/bin/bash
# ============================================================
# OHOS 构建脚本 (Flutter 3.35.8-ohos)
#
# 用法:
#   ./ohos_utils/ohos_build.sh debug --env=dev
#   ./ohos_utils/ohos_build.sh release --env=prod --full
#   ./ohos_utils/ohos_build.sh debug --env=dev --dart-define=FOO=bar
#
# 关键避坑 (K7): OHOS 的 `flutter build hap` 不支持 --dart-define-from-file,
#   本脚本把 env 文件 (KEY=VALUE) 展开为 --dart-define=K=V 注入。
#   骨架在 Android/iOS 用 --dart-define-from-file=env/.env.*，OHOS 必须展开。
#
# 关键避坑 (K1): `flutter build hap` 会重生成 GeneratedPluginRegistrant.ets，
#   若有自定义/本地原生模块会被覆盖；--full 模式在 build 后再次运行
#   ohos_fix.sh 兜底（本骨架目前仅 pub.dev 通用插件，兜底为校验性质）。
#
# 完整模式 (--full): pub get + fix + flutter build hap (注入 dart-define)
#                   + fix(再次) + hvigorw 打包
#   → 改了 Dart 代码/依赖时必须用 --full 重编 kernel_blob.bin
# 快速模式 (默认, 不带 --full): pub get + fix + hvigorw 直接打包
#   → 仅改 ArkTS/ETS、未改 Dart 时（要求已至少有一次 --full 构建）
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OHOS_DIR="$PROJECT_DIR/ohos"
FLUTTER="$PROJECT_DIR/.fvm/flutter_sdk/bin/flutter"
HVIGORW="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"
DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-/Applications/DevEco-Studio.app/Contents/sdk}"
export HOS_SDK_HOME="${HOS_SDK_HOME:-$DEVECO_SDK_HOME}"

BUILD_MODE=""
FULL_MODE=false
ENV_NAME=""
DART_DEFINES=()

# ─── 解析参数 ───
for arg in "$@"; do
  case "$arg" in
    debug|release) BUILD_MODE="$arg" ;;
    --full) FULL_MODE=true ;;
    --env=*) ENV_NAME="${arg#--env=}" ;;
    --dart-define=*) DART_DEFINES+=("${arg#--dart-define=}") ;;
    --dart-define)
      echo "❌ 用法: --dart-define=KEY=VALUE（需要等号）" >&2
      exit 1 ;;
    *)
      if [ -z "$BUILD_MODE" ]; then
        echo "❌ 未知参数: $arg" >&2
        echo "用法: ./ohos_utils/ohos_build.sh [debug|release] [--full] [--env=NAME] [--dart-define=K=V ...]" >&2
        exit 1
      fi ;;
  esac
done
BUILD_MODE="${BUILD_MODE:-debug}"

# ─── 选择 env 源文件: --env=NAME → env/.env.NAME；否则 .env.ohos ───
if [ -n "$ENV_NAME" ]; then
  ENV_FILE="$PROJECT_DIR/env/.env.$ENV_NAME"
  if [ ! -f "$ENV_FILE" ]; then
    echo "❌ 找不到 env 文件: $ENV_FILE" >&2
    exit 1
  fi
else
  ENV_FILE="$PROJECT_DIR/.env.ohos"
fi

echo "📄 读取 env: $ENV_FILE"

# ─── 展开 KEY=VALUE → --dart-define (K7) ───
# 跳过空行与 # 注释；命令行传入的同名 key 优先。
while IFS='=' read -r key value; do
  [ -z "$key" ] && continue
  [[ "$key" =~ ^[[:space:]]*# ]] && continue
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  already=false
  for d in "${DART_DEFINES[@]:-}"; do
    [[ "$d" == "$key="* ]] && already=true && break
  done
  if $already; then
    echo "  ⏭  $key (命令行已指定)"
  else
    DART_DEFINES+=("$key=$value")
    echo "  ➕ $key"
  fi
done < "$ENV_FILE"

DART_DEFINE_ARGS=()
for d in "${DART_DEFINES[@]:-}"; do
  DART_DEFINE_ARGS+=("--dart-define=$d")
done

MODE_LABEL="快速模式"
$FULL_MODE && MODE_LABEL="完整模式(--full)"
echo "🔨 [ohos_build] 鸿蒙构建 ($BUILD_MODE / $MODE_LABEL)"
if [ ${#DART_DEFINES[@]} -gt 0 ]; then
  echo "🏷️  dart-define: ${DART_DEFINES[*]}"
fi

# ─── Step 1: Flutter pub get ───
echo ""
echo "📦 Step 1: flutter pub get ..."
cd "$PROJECT_DIR"
$FLUTTER pub get 2>&1 | tail -3

# ─── Step 2: ohos_fix.sh (registrant / lock 兜底) ───
echo ""
echo "🔧 Step 2: ohos_fix.sh ..."
bash "$SCRIPT_DIR/ohos_fix.sh" 2>&1 | grep -E '✅|➕|⚠️|Fixed' || true

REGISTRANT="$OHOS_DIR/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets"
PLUGIN_COUNT=$(grep -c 'add(new' "$REGISTRANT" 2>/dev/null || echo 0)
echo "  📋 注册插件数: $PLUGIN_COUNT"

# ─── Step 3 (--full): flutter build hap 重编 kernel ───
if $FULL_MODE; then
  echo ""
  echo "🏗️  Step 3a: flutter build hap --$BUILD_MODE ${DART_DEFINE_ARGS[*]} ..."
  echo "   (重编 kernel_blob.bin，dart-define 在此注入)"
  cd "$PROJECT_DIR"
  DEVECO_SDK_HOME="$DEVECO_SDK_HOME" $FLUTTER build hap \
    --"$BUILD_MODE" \
    "${DART_DEFINE_ARGS[@]}" \
    2>&1 | tee /tmp/flutter_build_hap.log | tail -5
  if grep -q 'Error: ' /tmp/flutter_build_hap.log 2>/dev/null; then
    echo "❌ kernel 编译失败！完整日志: /tmp/flutter_build_hap.log"
    grep 'Error:' /tmp/flutter_build_hap.log
    exit 1
  fi

  # 再次修复 registrant（被 flutter build hap 覆盖）
  echo ""
  echo "🔧 Step 3b: 再次修复 registrant ..."
  bash "$SCRIPT_DIR/ohos_fix.sh" 2>&1 | grep -E '✅|➕|⚠️|Fixed' || true
  PLUGIN_COUNT=$(grep -c 'add(new' "$REGISTRANT" 2>/dev/null || echo 0)
  echo "  📋 注册插件数: $PLUGIN_COUNT"
fi

# ─── Step 4: hvigorw 打包 ───
STEP_NUM=3
$FULL_MODE && STEP_NUM=4
echo ""
echo "🏗️  Step $STEP_NUM: hvigorw assembleHap ($BUILD_MODE) ..."
cd "$OHOS_DIR"
DEVECO_SDK_HOME="$DEVECO_SDK_HOME" "$HVIGORW" assembleHap \
  -p product=default \
  -p buildMode="$BUILD_MODE" \
  --no-daemon \
  2>&1 | grep -E 'BUILD|ERROR|Finished :entry:assembleHap'

echo ""
echo "✅ [ohos_build] 构建完成！"
echo "📱 HAP: $OHOS_DIR/entry/build/default/outputs/default/entry-default-signed.hap"

if $FULL_MODE; then
  echo ""
  echo "💡 kernel_blob.bin 已包含 dart-define 常量。"
  echo "   后续只改 ArkTS/ETS 时，可不加 --full 直接打包。"
fi
