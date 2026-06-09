# Layer 1 提取 Schema（简化版）

## 说明
Layer 1 只做**结构提取，不打分**。输出 JSON 数组，每个元素对应一集。
**字段字数上限为强制要求，超出必须截断浓缩。**

## Schema

```json
[
  {
    "episode_num": 1,
    "key_events": "本集关键剧情摘要，200字以内",
    "last_line": "集尾最后一句原文或场景描述，100字以内",
    "golden_quotes": ["金句1（50字内）", "金句2（50字内）"],
    "emotion_peaks": [
      {"scene": "场景描述（50字内）", "direction": "up或down", "intensity": 1到5}
    ],
    "villain_actions": ["反派招恨行为（100字内）"],
    "foreshadowing": [{"type": "plant或resolve", "desc": "伏笔描述"}]
  }
]
```

## 字段说明

| 字段 | 用途 | 专家使用 |
|------|------|---------|
| `episode_num` | 集数序号 | 全部 |
| `key_events` | 剧情摘要 | 结构专家（判断节奏） |
| `last_line` | 集尾断章 | 结构专家（判断卡点） |
| `golden_quotes` | 金句摘录 | 市场专家（判断传播力） |
| `emotion_peaks` | 情绪峰值 | 情感专家（判断张力） |
| `villain_actions` | 反派行为 | 情感专家（判断招恨度） |
| `foreshadowing` | 伏笔追踪 | 结构专家（判断回收） |

## 完整示例

```json
[
  {
    "episode_num": 1,
    "key_events": "卢修斯宣布推翻百年斗场旧规，废除权贵暗箱操作。奴隶角斗士塞鲁斯擂台连胜。卢修斯越界触碰塞鲁斯，贴耳低语暗示特殊偏爱。",
    "last_line": "他颠覆百年斗场旧规，却唯独为卑微奴隶打破阶级壁垒，点燃权贵杀机。",
    "golden_quotes": [
      "旧规腐朽，所以我来推翻。",
      "我改尽斗场所有规则，唯独为你破例。"
    ],
    "emotion_peaks": [
      {"scene": "塞鲁斯擂台连胜，击败两名老牌角斗士", "direction": "up", "intensity": 3},
      {"scene": "克劳狄当众嘲讽：靠奴隶撑场面", "direction": "down", "intensity": 3},
      {"scene": "卢修斯贴耳低语：唯独为你破例", "direction": "up", "intensity": 5}
    ],
    "villain_actions": [
      "克劳狄当众嘲讽卢修斯靠奴隶撑场面，虚妄可笑"
    ],
    "foreshadowing": [
      {"type": "plant", "desc": "卢修斯为塞鲁斯破例，引发权贵妒火"}
    ]
  }
]
```

## 字数上限（强制）

| 字段 | 上限 | 违反处理 |
|------|------|---------|
| `key_events` | 200字 | 截断，保留核心事件 |
| `last_line` | 100字 | 截断，保留最后一句 |
| `golden_quotes[]` | 50字/条 | 截断，保留核心 |
| `emotion_peaks[].scene` | 50字 | 截断，保留核心动作 |
| `villain_actions[]` | 100字/条 | 截断，保留招恨行为 |
| `foreshadowing[].desc` | 100字 | 截断，保留核心 |

## 与旧版对比（简化了什么）

| 移除字段 | 原因 |
|---------|------|
| `emotion_curve[].score`（-5到+5精确打分） | 主观且专家不用，改为 direction+intensity |
| 精确情绪分数 | 改为方向(up/down)+强度(1-5)，更直观 |
