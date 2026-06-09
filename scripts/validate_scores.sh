#!/bin/bash
# validate_scores.sh - 验证评分报告分数合法性
# 用法: ./validate_scores.sh <report_file>
# 退出码: 0=通过, 1=失败

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "错误: 请提供报告文件路径" >&2
  exit 1
fi

REPORT="$1"

if [ ! -f "$REPORT" ]; then
  echo "错误: 文件不存在: $REPORT" >&2
  exit 1
fi

# 提取各维度分数
STRUCTURE=$(grep -oP '剧本结构.*?(\d+)/40' "$REPORT" | grep -oP '\d+' | head -1)
EMOTION=$(grep -oP '人物与情绪.*?(\d+)/35' "$REPORT" | grep -oP '\d+' | head -1)
MARKET=$(grep -oP '市场潜力.*?(\d+)/25' "$REPORT" | grep -oP '\d+' | head -1)
TOTAL=$(grep -oP '总计.*?(\d+)/100' "$REPORT" | grep -oP '\d+' | head -1)

ERRORS=0

# 验证范围
if [ -n "$STRUCTURE" ] && ([ "$STRUCTURE" -lt 0 ] || [ "$STRUCTURE" -gt 40 ]); then
  echo "❌ 结构分数超出范围: $STRUCTURE/40"
  ERRORS=$((ERRORS + 1))
fi

if [ -n "$EMOTION" ] && ([ "$EMOTION" -lt 0 ] || [ "$EMOTION" -gt 35 ]); then
  echo "❌ 情绪分数超出范围: $EMOTION/35"
  ERRORS=$((ERRORS + 1))
fi

if [ -n "$MARKET" ] && ([ "$MARKET" -lt 0 ] || [ "$MARKET" -gt 25 ]); then
  echo "❌ 市场分数超出范围: $MARKET/25"
  ERRORS=$((ERRORS + 1))
fi

# 验证总分计算
if [ -n "$STRUCTURE" ] && [ -n "$EMOTION" ] && [ -n "$MARKET" ] && [ -n "$TOTAL" ]; then
  EXPECTED=$((STRUCTURE + EMOTION + MARKET))
  if [ "$TOTAL" -ne "$EXPECTED" ]; then
    echo "❌ 总分计算错误: $STRUCTURE + $EMOTION + $MARKET = $EXPECTED, 报告写 $TOTAL"
    ERRORS=$((ERRORS + 1))
  fi
fi

# 验证评级
RATING=$(grep -oP '最终评级：[A-D]级' "$REPORT" | grep -oP '[A-D]')
if [ -n "$TOTAL" ] && [ -n "$RATING" ]; then
  EXPECTED_RATING=""
  if [ "$TOTAL" -ge 90 ]; then EXPECTED_RATING="S"
  elif [ "$TOTAL" -ge 80 ]; then EXPECTED_RATING="A"
  elif [ "$TOTAL" -ge 70 ]; then EXPECTED_RATING="B"
  elif [ "$TOTAL" -ge 60 ]; then EXPECTED_RATING="C"
  else EXPECTED_RATING="D"
  fi
  
  if [ "$RATING" != "$EXPECTED_RATING" ]; then
    echo "❌ 评级不匹配: 总分 $TOTAL 应为 ${EXPECTED_RATING}级, 报告写 ${RATING}级"
    ERRORS=$((ERRORS + 1))
  fi
fi

if [ "$ERRORS" -eq 0 ]; then
  echo "✅ 评分验证通过"
  exit 0
else
  echo "❌ 发现 $ERRORS 个错误"
  exit 1
fi
