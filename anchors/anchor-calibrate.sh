#!/bin/bash
# anchor-calibrate.sh - 锚点校准脚本
# 用法: ./anchor-calibrate.sh [anchors_dir]
# 读取所有锚点记录，对比专家分和预设范围，输出偏差报告

set -euo pipefail

ANCHORS_DIR="${1:-$(dirname "$0")}"

if [ ! -d "$ANCHORS_DIR" ]; then
  echo "错误: 目录不存在: $ANCHORS_DIR" >&2
  exit 1
fi

echo "=========================================="
echo "  锚点校准报告"
echo "=========================================="
echo ""

TOTAL=0
CALIBRATED=0
DEVIATED=0

for f in "$ANCHORS_DIR"/anchor_*.json; do
  [ -f "$f" ] || continue
  
  ID=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('id','?'))" 2>/dev/null || echo "?")
  TITLE=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('title','?'))" 2>/dev/null || echo "?")
  RESULT=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('market_result','?'))" 2>/dev/null || echo "?")
  RANGE_MIN=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('score_range',[0])[0])" 2>/dev/null || echo "?")
  RANGE_MAX=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('score_range',[0,0])[1])" 2>/dev/null || echo "?")
  EXPERT=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('expert_scores',{}).get('total','?'))" 2>/dev/null || echo "?")
  STATUS=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('calibration_status','?'))" 2>/dev/null || echo "?")
  
  TOTAL=$((TOTAL + 1))
  
  if [ "$EXPERT" = "?" ] || [ "$EXPERT" = "null" ]; then
    echo "⏳ $ID $TITLE → 专家分: 未评估 | 市场结果: $RESULT | 状态: $STATUS"
    continue
  fi
  
  RANGE_AVG=$(( (RANGE_MIN + RANGE_MAX) / 2 ))
  DEVIATION=$((EXPERT - RANGE_AVG))
  
  if [ "$DEVIATION" -lt -10 ] || [ "$DEVIATION" -gt 10 ]; then
    echo "❌ $ID $TITLE → 专家分: $EXPERT | 预设: $RANGE_MIN-$RANGE_MAX (均$RANGE_AVG) | 偏差: $DEVIATION | 市场: $RESULT"
    DEVIATED=$((DEVIATED + 1))
  else
    echo "✅ $ID $TITLE → 专家分: $EXPERT | 预设: $RANGE_MIN-$RANGE_MAX (均$RANGE_AVG) | 偏差: $DEVIATION | 市场: $RESULT"
    CALIBRATED=$((CALIBRATED + 1))
  fi
done

echo ""
echo "=========================================="
echo "  汇总: 总计 $TOTAL | 已校准 $CALIBRATED | 偏差>$DEVIATED"
echo "=========================================="

if [ "$DEVIATED" -gt 0 ]; then
  echo ""
  echo "⚠️  发现 $DEVIATED 个偏差>10分的锚点，建议调整评分标准。"
  echo "   检查 scoring-anchors-v2.md 和 rating-criteria.md 的锚点定义。"
  exit 1
else
  echo ""
  echo "✅ 所有锚点已校准，偏差在可接受范围内。"
  exit 0
fi
