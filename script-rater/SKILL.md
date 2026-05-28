# Skill: script-rater

## 触发条件
当用户要求对短剧剧本进行评级、审查、评估或打分时触发。

## 输入格式支持
.txt / .docx / .pdf

## 执行流程

### Step 1: 预处理
- 格式解析：识别剧本文件集数边界，兼容"第一集""EP01""第1话"等多种格式。
- 文本清洗：去除无关乱码，统一样式。
- 分批切分：按照每批 3-5 集的容量切分剧本，准备进入 Layer 1。

### Step 2: Layer 1 分批提取
- 将切分后的批次并行发送给提取 Agent。
- 提取 Agent **只做结构提取，不打分**。
- 强制按照 `core/extraction-schema.md` 输出 JSON 格式，防止粒度不一致。
- 模型选型：可用轻量模型降成本。
- 断点续跑：每批提取结果立即落盘至 `checkpoints/layer1/` 目录。

### Step 3: Layer 2 三专家分析
- 读取 `checkpoints/layer1/` 中的所有提取摘要，分别发送给三个专家 Agent：
  - 结构专家 Agent（专注剧本结构，满分40分）
  - 情感专家 Agent（专注人物与情绪，满分35分）
  - 市场专家 Agent（专注市场潜力，满分25分）
- 专家 Agent 打分时**必须附上判断依据的原文引用**。
- Prompt 中注入 `core/scoring-anchors.md` 进行评分尺度校准。
- 模型选型：必须使用主力模型。
- 断点续跑：每个专家的分析结果落盘至 `checkpoints/layer2/` 目录。

### Step 4: Layer 3 聚合报告
- 汇总三个专家 Agent 的报告与分数。
- 加权计算总分，匹配最终评级（S/A/B/C/D）。
- 合并生成结构化的最终评级报告。

## 断点续跑机制
- 中间结果以 JSON 文件形式存储在 `checkpoints/` 目录下。
- `checkpoints/layer1/`：保存每批次的提取结果，失败重试时跳过已成功批次。
- `checkpoints/layer2/`：保存各专家分析结果，失败重试时跳过已完成的专家。
- 任何层级中途失败，均可从断点继续，无需从头重跑。

## 引用文件列表
- `core/rating-criteria.md` — 评分标准全文（供 Layer 2 专家使用）
- `core/extraction-schema.md` — 第一层提取 JSON Schema 模板（供 Layer 1 提取使用）
- `core/scoring-anchors.md` — 专家评分锚点校准示例（供 Layer 2 专家使用）

## 进化机制
- 定期根据市场爆款短剧数据，校准 `core/scoring-anchors.md` 中的锚点分值与场景。
- 根据新题材趋势，更新 `core/rating-criteria.md` 中的赛道契合与视觉执行评估权重。
- 优化提取 Schema，增加对新型叙事结构（如倒叙、多视角）的提取字段支持。
