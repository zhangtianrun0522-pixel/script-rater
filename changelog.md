# Changelog

## v0.2.0 (2026-06-09) - 巴爷改造版

### 新增
- **解析脚本** `scripts/parse_docx.sh` — 真实可执行的 docx 解析
- **集数切分脚本** `scripts/split_episodes.py` — 自动识别集数边界（支持"第X集"/"EPXX"等格式）
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
