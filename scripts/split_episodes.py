#!/usr/bin/env python3
"""
split_episodes.py - 自动按集数切分剧本文本
用法: python3 split_episodes.py <input.txt> [output_dir]
输出: output_dir/ep_01.txt, ep_02.txt, ...
"""

import sys
import os
import re

def split_episodes(text, output_dir="."):
    """按集数边界切分剧本"""
    # 匹配集数标题的模式
    patterns = [
        r'第\s*(\d+)\s*集',           # 第1集, 第 1 集
        r'EP\s*(\d+)',                # EP01, EP1
        r'Episode\s*(\d+)',           # Episode 1
        r'第\s*([一二三四五六七八九十\d]+)\s*集',  # 第一集
    ]
    
    # 找到所有集数边界
    boundaries = []
    for pattern in patterns:
        for m in re.finditer(pattern, text, re.IGNORECASE):
            boundaries.append((m.start(), int(m.group(1)) if m.group(1).isdigit() else len(boundaries) + 1))
    
    if not boundaries:
        print("警告: 未检测到集数边界，将整个文本作为单集输出", file=sys.stderr)
        boundaries = [(0, 1)]
    
    # 去重并排序
    boundaries = sorted(set(boundaries), key=lambda x: x[0])
    
    os.makedirs(output_dir, exist_ok=True)
    
    for i, (start, ep_num) in enumerate(boundaries):
        end = boundaries[i + 1][0] if i + 1 < len(boundaries) else len(text)
        content = text[start:end].strip()
        
        if content:
            filename = os.path.join(output_dir, f"ep_{ep_num:02d}.txt")
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"已提取: 第{ep_num}集 → {filename} ({len(content)} 字符)")
    
    return len(boundaries)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 split_episodes.py <input.txt> [output_dir]", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "."
    
    if not os.path.isfile(input_file):
        print(f"错误: 文件不存在: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        text = f.read()
    
    count = split_episodes(text, output_dir)
    print(f"\n完成: 共提取 {count} 集")
