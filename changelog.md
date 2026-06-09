# Changelog

## v0.4.0 (2026-06-09) - 架构升级版

### P0: 锚点库架构
- **新增** `anchors/` 目录 + `anchor-template.json` 模板
- **新增** `anchors/anchor-calibrate.sh` 校准脚本（对比专家分和预设范围）
- **新增** 校准模式触发逻辑（"这个作为案例"→存锚点）
- **新增** 评估模式 vs 校准模式双模式设计

### P1: 两阶段评审
- **新增** Layer 2 Stage 1 观察 Agent（只描述事实，不打分）
- **改进** Layer 2 Stage 2 专家打分（基于 Stage 1 事实清单，不直接读剧本）
- **改进** 专家约束：每个分数必须对应 Stage 1 的事实条目

### P2: 毒舌反事实检验
- **改进** critic-prompt.md 加入反事实检验流程
- **新增** 基于分数预测市场表现 → 对比自洽性 → 倒推合理分数

### P3: 维度拆分
- **改进** rating-criteria.md 每个维度拆成"文本实现分"和"执行潜力分"两列
- **新增** 决策权重逻辑（低成本试水看文本分，找资方看综合分）
- **新增** 输出格式双列评分表

### v0.3.0 (2026-06-09) - 反虚高版

### 新增
- **毒舌评审 Agent** `core/critic-prompt.md` — 专门挑刺、强制扣分的第四位专家
- **评分锚点 v2** `core/scoring-anchors-v2.md` — 提高标准+行业基准线，80分=前15%
- **高分警报** `scripts/validate_scores.sh` — 总分≥85 自动触发复核

### 改进
- **打分标准提高** — 行业平均分 65-70，80分=前15%，85分=前5%
- **CP张力区分单向/双向** — 单向偏爱最多6分，7分以上必须双向奔赴
- **视觉执行评估去掉成本限制** — 只看AI执行效果
- **打分自检清单** — 每个专家打分前必查5个问题

### v0.2.0 (2026-06-09) - 巴爷改造版

### 新增
- **解析脚本** `scripts/parse_docx.sh` — 真实可执行的 docx 解析
- **集数切分脚本** `scripts/split_episodes.py` — 自动识别集数边界
- **分数验证脚本** `scripts/validate_scores.sh` — 验证分数范围、总分计算、评级匹配
- **错误处理** — 文件不存在/解析失败/集数识别失败/分数验证失败的明确处理流程

### 改进
- **重写 SKILL.md** — 从"文字描述"变为"可执行指令"，加入 sessions_spawn 调度逻辑
- **简化 Layer 1 Schema** — 移除无用的 emotion_curve 精确打分，改为 direction+intensity
- **断点续跑** — checkpoints 目录结构规范化

### 修复
- 目录结构修复 — SKILL.md 现在直接在 skill 根目录
- 模型调度 — Layer 1 用 qwen-turbo（轻量），Layer 2 用 qwen-plus（主力）

## v0.1.0 (2026-05-28)
- 初始版本
- 三层 Agent 集群架构：分批提取 → 三专家分析 → 聚合报告
- 评分标准来源：飞书文档 VLtDdcO3vo9bVRxFUlPcRiq8npd
- 断点续跑机制（checkpoints/）
- 强制 JSON Schema 提取（extraction-schema.md）
- 专家评分锚点校准（scoring-anchors.md）
