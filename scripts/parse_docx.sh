#!/bin/bash
# parse_docx.sh - 解析 .docx 剧本文件为纯文本
# 用法: ./parse_docx.sh <file.docx>
# 输出: 纯文本到 stdout

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "错误: 请提供 .docx 文件路径" >&2
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "错误: 文件不存在: $FILE" >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# 解压 docx
unzip -o -q "$FILE" -d "$TMPDIR" 2>/dev/null || {
  echo "错误: 无法解压文件，可能不是有效的 .docx 格式" >&2
  exit 1
}

XML_FILE="$TMPDIR/word/document.xml"
if [ ! -f "$XML_FILE" ]; then
  echo "错误: 找不到 document.xml，文件可能已损坏" >&2
  exit 1
fi

# 提取文本内容
python3 -c "
import sys, re

with open('$XML_FILE', 'r', encoding='utf-8') as f:
    xml = f.read()

# 段落之间加换行
xml = xml.replace('</w:p>', '\n')
# 换行符
xml = xml.replace('<w:br/>', '\n')
# 移除所有 XML 标签
text = re.sub(r'<[^>]+>', ' ', xml)
# 解码 HTML 实体
text = text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '\"').replace('&apos;', \"'\")
# 清理空白
text = re.sub(r'[ \t]+', ' ', text)
text = re.sub(r'\n\s*\n', '\n', text)
text = text.strip()

# 输出
print(text)
" 2>/dev/null || {
  echo "错误: 文本提取失败" >&2
  exit 1
}
