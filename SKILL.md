# Skill: script-rater

## 触发条件
当用户要求对短剧剧本进行评级、审查、评估或打分时触发。

## 输入格式支持
`.txt` / `.docx` / `.pdf`

## 执行流程

### Step 0: 文件预处理
1. 检查文件是否存在，不存在则提示用户上传
2. 根据文件类型调用对应解析脚本：
   ```bash
   # .docx
   bash scripts/parse_docx.sh <file.docx> > /tmp/script_raw.txt
   
   # .pdf（用 pdftotext 或 python）
   # .txt 直接读取
   ```
3. 用切分脚本自动识别集数边界：
   ```bash
   python3 scripts/split_episodes.py /tmp/script_raw.txt /tmp/episodes/
   ```
4. 输出：`/tmp/episodes/ep_01.txt`, `ep_02.txt`, ...

### Step 1: Layer 1 分批提取（轻量模型）
**目标：** 从每集文本中提取结构化摘要，不做打分。

**执行方式：** 用 `sessions_spawn` 启动提取子 Agent，每 3-5 集一批。

```
对每批剧本，spawn 一个 subagent：
- runtime: "subagent"
- mode: "run"
- model: "qwen-turbo"（轻量降成本）
- task: 读取提供的剧本片段，按以下 schema 输出 JSON 数组
```

**提取 Schema（简化版）：**
```json
[
  {
    "episode_num": 1,
    "key_events": "本集关键剧情，200字以内",
    "last_line": "集尾最后一句原文或场景描述，100字以内",
    "golden_quotes": ["金句1（50字内）", "金句2（50字内）"],
    "emotion_peaks": [
      {"scene": "场景描述（50字内）", "direction": "up或down", "intensity": 1-5}
    ],
    "villain_actions": ["反派招恨行为（100字内）"],
    "foreshadowing": [{"type": "plant或resolve", "desc": "伏笔描述"}]
  }
]
```

**断点续跑：** 每批提取结果立即写入 `checkpoints/layer1/batch_N.json`，失败重试时跳过已成功批次。

### Step 2: Layer 2 三专家并行分析（主力模型）
**目标：** 三个专家独立打分，互不干扰。

**执行方式：** 并行 spawn 3 个 subagent：

```
并行启动三个 subagent：
1. 结构专家 — model: qwen-plus, task: 读 Layer 1 JSON + rating-criteria.md 的结构部分，打 0-40 分
2. 情感专家 — model: qwen-plus, task: 读 Layer 1 JSON + rating-criteria.md 的情感部分，打 0-35 分
3. 市场专家 — model: qwen-plus, task: 读 Layer 1 JSON + rating-criteria.md 的市场部分，打 0-25 分
```

**专家输出格式：**
```markdown
# [专家类型]评分报告

## 维度1: X/满分分
**判断依据：** 引用原文具体场景

## 维度2: X/满分分
...

## 小计: X/满分分
```

**断点续跑：** 每个专家结果写入 `checkpoints/layer2/[structure|emotion|market]-expert.md`。

### Step 3: Layer 3 聚合报告
**目标：** 汇总三份专家报告，计算总分，输出评级。

**执行方式：** 在主 Agent 中完成（无需 spawn）：
1. 读取三个专家的分数
2. 计算总分 = 结构 + 情感 + 市场
3. 匹配评级：
   | 总分 | 评级 |
   |------|------|
   | 90-100 | S级 |
   | 80-89 | A级 |
   | 70-79 | B级 |
   | 60-69 | C级 |
   | <60 | D级 |
4. 生成最终报告，包含：
   - 三维评分总览表
   - 各维度核心优势（引用专家原文）
   - 改进空间
   - 投流素材建议（从市场专家提取）
   - 经典台词摘录

### Step 4: 验证与输出
1. 运行验证脚本：
   ```bash
   bash scripts/validate_scores.sh <report_file>
   ```
2. 验证通过 → 写入飞书文档
3. 验证失败 → 报告错误，人工介入

## 引用文件
- `core/rating-criteria.md` — 评分标准全文
- `core/scoring-anchors.md` — 专家评分锚点校准示例
- `scripts/parse_docx.sh` — docx 解析
- `scripts/split_episodes.py` — 集数切分
- `scripts/validate_scores.sh` — 分数验证

## 错误处理
| 场景 | 处理方式 |
|------|---------|
| 文件不存在 | 提示用户上传文件 |
| 解析失败 | 明确报错原因，建议检查文件格式 |
| 集数识别失败 | 提示用户手动指定集数范围 |
| 分数验证失败 | 报告具体错误，不输出最终评级 |
| Agent 超时 | 重试一次，仍失败则汇报用户 |
