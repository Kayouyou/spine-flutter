#!/bin/bash
set -e

cd "$(dirname "$0")/.."
ARB_DIR="lib/core/l10n"
TEMPLATE="$ARB_DIR/app_zh.arb"

extract_keys() {
    python3 -c "
import json, sys
with open('$1') as f:
    data = json.load(f)
for k in sorted(data.keys()):
    if not k.startswith('@'):
        print(k)
"
}

echo "=== 检查 ARB 文件 key 一致性 ==="
template_keys=$(extract_keys "$TEMPLATE")

for arb in "$ARB_DIR"/app_*.arb; do
    [ "$(basename "$arb")" = "$(basename "$TEMPLATE")" ] && continue
    arb_keys=$(extract_keys "$arb")
    missing=$(comm -23 <(echo "$template_keys") <(echo "$arb_keys"))
    extra=$(comm -13 <(echo "$template_keys") <(echo "$arb_keys"))
    if [ -n "$missing" ] || [ -n "$extra" ]; then
        echo "❌ $(basename "$arb"): key 不一致"
        [ -n "$missing" ] && echo "  缺失 key: $missing"
        [ -n "$extra" ] && echo "  多余 key: $extra"
        exit 1
    fi
done

echo "✅ 所有 ARB 文件 key 与模板 ($(basename "$TEMPLATE")) 一致"
echo "   模板 key 数量: $(echo "$template_keys" | wc -l | tr -d ' ')"
