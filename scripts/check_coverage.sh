#!/bin/bash
# 检查所有包的合并覆盖率是否达到最低门槛
# 用法: ./scripts/check_coverage.sh [min_percent]
#   min_percent: 最低覆盖率百分比 (默认 80)

set -e

MIN="${1:-80}"

# 合并所有 lcov.info
MERGED="/tmp/lcov_merged.info"
FILTERED="/tmp/lcov_filtered.info"
> "$MERGED"

found=0
for f in $(find . -name "lcov.info" -not -path "*/.dart_tool/*" -not -path "*/build/*"); do
  cat "$f" >> "$MERGED"
  found=$((found + 1))
done

if [ "$found" -eq 0 ]; then
  echo "❌ 未找到任何 lcov.info 文件，请先运行 melos test:coverage"
  exit 1
fi

echo "📊 合并了 $found 个 lcov.info 文件"

# 过滤生成代码（.g.dart, .freezed.dart）
echo "🔧 过滤生成代码..."
lcov --remove "$MERGED" \
  "*.g.dart" \
  "*.freezed.dart" \
  "*/*.g.dart" \
  "*/*.freezed.dart" \
  -o "$FILTERED" 2>/dev/null || cp "$MERGED" "$FILTERED"

# 用 lcov 计算行覆盖率（使用过滤后的数据）
TOTAL=$(grep "^DA:" "$FILTERED" | wc -l | tr -d ' ')
HIT=$(grep "^DA:" "$FILTERED" | awk -F, '$2 > 0' | wc -l | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
  echo "❌ lcov 中无 DA: 行数据"
  exit 1
fi

PERCENT=$((HIT * 100 / TOTAL))

echo "📈 行覆盖率: ${HIT}/${TOTAL} = ${PERCENT}% (门槛: ${MIN}%)"

if [ "$PERCENT" -lt "$MIN" ]; then
  echo "❌ 覆盖率 ${PERCENT}% 低于门槛 ${MIN}%"
  exit 1
fi

echo "✅ 覆盖率检查通过"
