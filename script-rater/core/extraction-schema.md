# Layer 1 提取 JSON Schema 模板

## 说明
Layer 1 提取 Agent 必须严格按照以下 Schema 输出 JSON 数组。每个元素对应一集的提取结果。**字段字数上限为强制要求，超出必须截断浓缩，不得违反。**

## Schema 定义

```json
[
  {
    "episode_num": "integer, 集数序号",
    "emotion_curve": [
      {
        "scene_desc": "string, 场景描述，50字以内",
        "score": "integer, 情绪分数, 范围 -5 到 +5"
      }
    ],
    "last_line": "string, 集尾最后一句原文或场景描述, 100字以内",
    "golden_quotes": [
      "string, 金句1, 50字以内",
      "string, 金句2, 50字以内（最多2条）"
    ],
    "villain_actions": [
      "string, 反派招恨行为原文片段, 100字以内（可多条）"
    ],
    "foreshadowing": [
      {
        "type": "string, 枚举值: plant（埋下） 或 resolve（回收）",
        "desc": "string, 伏笔描述"
      }
    ],
    "key_events": "string, 本集关键剧情事件摘要, 200字以内"
  }
]
```

## 完整示例 JSON

```json
[
  {
    "episode_num": 1,
    "emotion_curve": [
      {
        "scene_desc": "婚礼现场，女主发现新郎出轨闺蜜",
        "score": -4
      },
      {
        "scene_desc": "女主当众撕毁婚约，怒扇渣男",
        "score": 5
      },
      {
        "scene_desc": "男主从天而降，提出契约结婚",
        "score": 4
      }
    ],
    "last_line": ""签字，我帮你虐渣，你做我的妻。"顾寒将红本本摔在她面前，眼神危险而迷人。",
    "golden_quotes": [
      ""我林晚不需要施舍的爱，只需要势均力敌的恨。"",
      ""签了它，整个顾家都是你的陪嫁。""
    ],
    "villain_actions": [
      "新郎婚礼上公然和闺蜜挽手出现，嘲笑女主是没妈的野种。",
      "婆婆当众撕毁女主的陪嫁清单，将她推倒在玻璃渣上。"
    ],
    "foreshadowing": [
      {
        "type": "plant",
        "desc": "男主手腕上的半块玉佩，与女主小时候收到的如出一辙"
      },
      {
        "type": "plant",
        "desc": "新郎拿出的那份神秘遗嘱，似乎隐藏着女主身世的秘密"
      }
    ],
    "key_events": "林晚在婚礼遭新郎背叛，绝地反击撕毁婚约。首富顾寒突然现身提出契约结婚，林晚为夺回母亲遗物被迫答应，两人在拉扯中闪婚，暗涌频出。"
  },
  {
    "episode_num": 2,
    "emotion_curve": [
      {
        "scene_desc": "女主入住男主豪宅，遭女配下马威",
        "score": -3
      },
      {
        "scene_desc": "男主霸气护妻，赶走女配",
        "score": 4
      }
    ],
    "last_line": ""记住你的身份，我的女人，谁也不能动。"顾寒捏住她的下巴，语气不容置疑。",
    "golden_quotes": [
      ""顾太太这个位置，只有你坐得稳。""
    ],
    "villain_actions": [
      "绿茶女配故意打翻滚烫红茶淋在女主裙子上，嘲讽她土鳖配不上顾寒。"
    ],
    "foreshadowing": [
      {
        "type": "resolve",
        "desc": "第一集新郎嚣张拿走的遗嘱，被顾寒的黑客团队半路截获"
      }
    ],
    "key_events": "林晚入住顾家，遭顾寒青梅竹马挑衅。顾寒及时出现护短，并暗中出手夺回林晚母亲遗嘱。两人在同一屋檐下防备又相互吸引，契约关系开始变质。"
  }
]
```

## 字段字数上限（强制）

| 字段 | 上限 | 违反处理 |
|------|------|----------|
| `emotion_curve[].scene_desc` | 50字 | 截断，保留核心动作+情绪 |
| `last_line` | 100字 | 截断，保留最后一句台词 |
| `golden_quotes[]` | 50字/条 | 截断，保留金句核心 |
| `villain_actions[]` | 100字/条 | 截断，保留招恨行为描述 |
| `key_events` | 200字 | 截断，保留核心事件 |
