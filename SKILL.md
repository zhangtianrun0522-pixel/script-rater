# Skill: script-rater

## 触发条件
当用户要求对短剧剧本进行评级、审查、评估或打分时触发。

## 输入格式支持
`.txt` / `.docx` / `.pdf`

## 输入级别

### 模式 A：完整剧本模式（Deep Dive）
**触发条件：** 用户提供了完整的分集剧本（30集逐集文本）
**流程：** 标准 3 层流水线（见下方执行流程）

### 模式 B：梗概模式（Quick Scan）
**触发条件：** 用户只提供了 logline + 人物小传 + 大纲/分集梗概
**注意：** 此模式不依赖文件预处理和 Layer 1 分批提取，由主 Agent 直接基于梗概内容分析。
- 快速判断赛道匹配度、结构完整性、CP 张力、市场定位
- 保留三个专家 + 毒舌评审的分析框架
- 输出保留评级（标注"基于梗概"），完整剧本产出后建议重评
- 不可用于校准模式（校准需要完整剧本数据）

### 评估模式（默认）
**触发：** "评这个剧本" / "打分" / "用剧本评估skill"
**输出：** 评级报告 → 飞书文档
- 完整剧本 → 跑完整 Deep Dive 流水线
- 梗概/大纲 → 自动降级为 Quick Scan

### 校准模式
**触发：** "这个作为案例" / "加入锚点库" / "做校准"
**流程：** 跑完整评估流程 → 保存锚点记录到 `anchors/` 目录
**额外输入：** 用户需提供市场结果（爆款/中等/扑街）+ 市场数据（播放量/充值等）
**输出：** 锚点 JSON 记录（不生成飞书文档）
**限制：** 仅支持完整剧本模式输入

---

## 执行流程

### Step 0: 文件预处理
1. 检查文件是否存在，不存在则提示用户上传
2. 根据文件类型调用对应解析脚本：
   ```bash
   bash scripts/parse_docx.sh <file.docx> > /tmp/script_raw.txt
   ```
3. 用切分脚本自动识别集数边界：
   ```bash
   python3 scripts/split_episodes.py /tmp/script_raw.txt /tmp/episodes/
   ```
4. 输出：`/tmp/episodes/ep_01.txt`, `ep_02.txt`, ...

### Step 1: Layer 1 分批提取（轻量模型可选）
**目标：** 从每集文本中提取结构化摘要，不做打分。

**执行方式：** 用 `sessions_spawn` 启动提取子 Agent，每 3-5 集一批。

```
对每批剧本，spawn 一个 subagent：
- runtime: "subagent"
- mode: "run"
- task: 读取提供的剧本片段，按 extraction-schema.md 输出 JSON 数组
```

**模型选择：** 不强制指定具体模型，按执行时的 OpenClaw 默认配置走。建议：
- 完整剧本（数据量大）：使用当前配置的轻量模型以降低成本
- 片段/未成型剧本：使用主模型以保证提取质量

**断点续跑：** 每批提取结果立即写入 `checkpoints/layer1/batch_N.json`。

### Step 2: Layer 2 两阶段评审

#### Stage 1: 观察 Agent（只描述事实，不打分）
**目标：** 从 Layer 1 数据中提取客观事实，不做任何判断。

**执行方式：** spawn 一个 subagent：
```
- runtime: "subagent"
- mode: "run"
- task: 读取 Layer 1 JSON，输出事实清单 JSON
```

**Stage 1 输出格式：**
```json
{
  "cp_proactive_count": 3,
  "cp_proactive_details": ["E1 卢修斯贴耳低语", "E3 卢修斯扣肩甲", "E8 卢修斯贴身穿甲"],
  "cp_passive_count": 1,
  "cp_passive_details": ["E10 塞鲁斯'不能负他'"],
  "cliffhanger_types": ["E1: 画面定格", "E5: 悬念词", ...],
  "cliffhanger_drama_based": 8,
  "cliffhanger_word_based": 2,
  "side_character_actions": 2,
  "side_character_names": ["老场监"],
  "midpoint_reversal": false,
  "midpoint_description": "反派阴谋曝光，非局势逆转",
  "finale_resolved": false
}
```

**注意：** 格式中不再包含预评分字段。评分由 Stage 2 专家独立完成。

#### Stage 2: 四专家并行打分（基于 Stage 1 事实）
**目标：** 四个专家独立打分，互不干扰。

**执行方式：** 并行 spawn 4 个 subagent：

```
并行启动四个 subagent（模型按当前 OpenClaw 默认配置执行）：
1. 结构专家 — task: 读 Layer 1 JSON + Stage 1 事实清单 + scoring-anchors-v2.md，打 0-40 分
2. 情感专家 — task: 读 Layer 1 JSON + Stage 1 事实清单 + scoring-anchors-v2.md，打 0-35 分
3. 市场专家 — task: 读 Layer 1 JSON + Stage 1 事实清单 + scoring-anchors-v2.md，打 0-25 分
4. 毒舌评审 — task: 读三个专家报告 + Stage 1 事实清单 + critic-prompt.md，逐项复核并强制扣分
```

**关键约束：** 专家打分时**必须基于 Stage 1 的事实清单**，不允许直接引用剧本原文做判断。每个分数必须对应 Stage 1 的事实条目。

**专家输出：** 每个专家写入 `checkpoints/layer2/[structure|emotion|market|critic]-expert.md`。

### Step 3: Layer 3 聚合报告
**目标：** 汇总四份报告，计算最终分数，输出评级。

**执行方式：** 在主 Agent 中完成：
1. 读取三个专家的分数
2. 读取毒舌评审的修正分数
3. **最终分 = min(专家总分 - 毒舌常规扣分 - 动机一致性扣分, 毒舌总分)**
   - 毒舌评审已经基于专家分做了逐项复核，取 min 确保"从严"原则
   - 毒舌分 ≥ 专家分的极端情况不会发生（毒舌默认所有高分都虚高）
   - 动机一致性扣分为附加项（上限：梗概-3，完整剧本-6），由毒舌评审在 Step 4 中评估
4. 匹配评级：
   | 总分 | 评级 |
   |------|------|
   | 90-100 | S级 |
   | 80-89 | A级 |
   | 70-79 | B级 |
   | 60-69 | C级 |
   | <60 | D级 |
5. 生成最终报告，包含：
   - 各维度评分表（单列，无执行潜力分）
   - **完整度置信度标记**（输入类型 + 置信度评级）
   - 制作可行性参考信息（不计入评分）
   - **动机一致性检验报告**（毒舌评审强制项，逐角色检查）
   - 毒舌评审强制扣分项
   - 各维度核心优势（引用 Stage 1 事实）
   - 改进空间
   - 投流素材建议

### Step 4: 验证与输出
1. 运行验证脚本：
   ```bash
   bash scripts/validate_scores.sh <report_file>
   ```
2. 验证通过 → 评估模式写入飞书文档；校准模式保存锚点记录
3. 验证失败 → 报告错误，人工介入

### Step 5: 校准模式特殊处理
如果是校准模式：
1. 从用户输入获取市场结果和预设分数范围
2. 将专家分和毒舌分写入锚点模板
3. 保存到 `anchors/anchor_XXX.json`
4. 运行校准脚本检查偏差：
   ```bash
   bash anchors/anchor-calibrate.sh anchors/
   ```

---

## 引用文件
- `core/rating-criteria.md` — 评分标准全文
- `core/scoring-anchors-v2.md` — 专家评分锚点校准 v2
- `core/critic-prompt.md` — 毒舌评审指令（含反事实检验）
- `core/extraction-schema.md` — Layer 1 提取 Schema
- `anchors/anchor-template.json` — 锚点记录模板
- `scripts/parse_docx.sh` — docx 解析
- `scripts/split_episodes.py` — 集数切分
- `scripts/validate_scores.sh` — 分数验证 + 高分警报

## 错误处理
| 场景 | 处理方式 |
|------|---------|
| 文件不存在 | 提示用户上传文件 |
| 解析失败 | 明确报错原因，建议检查文件格式 |
| 集数识别失败 | 提示用户手动指定集数范围 |
| 分数验证失败 | 报告具体错误，不输出最终评级 |
| 高分警报 | 总分≥85 时触发毒舌评审强制复核 |
| Agent 超时 | 重试一次，仍失败则汇报用户 |
