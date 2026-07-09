# 首批 10 个音效 AIGC 生产清单与 Manifest 示例

## 使用方式

这份文档直接服务当前工程的首批音效落地，目标只有 3 个：

- 先把首批 10 个关键事件做出来
- 事件名、导出文件名、`audio_manifest.json` 保持一致
- AIGC 生成出来后，能直接接入 `AudioService`

建议执行顺序：

1. 按下表挑事件生产
2. 用文中的 Prompt 生成候选音
3. 做简单后期清洗
4. 按“导出命名建议”导出文件
5. 把资源路径填进 `configs/audio/audio_manifest.json`
6. 在场景里做业务验收

## 首批 10 个事件总表

| 序号 | `event_id` | 用途 | 推荐模式 | 时长建议 | 推荐生产方式 |
|------|------------|------|----------|----------|--------------|
| 1 | `sfx_shot_fire` | 开枪主反馈 | `2d` | `0.18s - 0.45s` | 素材库 + AIGC/合成叠层 |
| 2 | `sfx_shot_hit_target` | 命中正确目标 | `2d` | `0.12s - 0.30s` | AIGC + 合成微调 |
| 3 | `sfx_shot_hit_wall` | 命中掩体/墙体 | `3d` | `0.18s - 0.50s` | Foley/AIGC |
| 4 | `sfx_shot_hit_wrong` | 误伤平民 | `2d` | `0.20s - 0.45s` | AIGC/合成 |
| 5 | `sfx_shot_miss` | 未命中 | `2d` | `0.10s - 0.22s` | 合成/AIGC |
| 6 | `sfx_scan_activate` | 扫描施放 | `2d` | `0.45s - 0.90s` | AIGC/合成 |
| 7 | `sfx_scan_reveal` | 扫描显露 | `2d` | `0.35s - 0.80s` | AIGC/合成 |
| 8 | `sfx_time_extend` | 加时道具 | `2d` | `0.30s - 0.70s` | AIGC/合成 |
| 9 | `ui_button_click` | 通用按钮点击 | `2d` | `0.04s - 0.12s` | 合成/AIGC |
| 10 | `ui_result_win` | 胜利结算 | `2d` | `0.80s - 1.80s` | AIGC/合成 |

## 导出通用规则

### 命名建议

建议使用下面的命名模式：

`事件名_序号.ogg`

示例：

- `sfx_shot_fire_01.ogg`
- `sfx_shot_fire_02.ogg`
- `sfx_scan_activate_01.ogg`
- `ui_button_click_01.ogg`

### 目录建议

按当前项目建议目录放置：

```text
res://audio/
  sfx/
    weapon/
    impact/
    ability/
  ui/
  amb/
  bgm/
```

对应关系建议：

- `weapon/`：开枪类
- `impact/`：命中、格挡、误伤、未命中
- `ability/`：扫描、加时
- `ui/`：按钮、结算

### 导出参数建议

- 短音效：`OGG`
- 采样率：`44.1kHz` 或 `48kHz`
- 声道：单声道优先；`UI` 也可以立体声
- 峰值控制：避免爆音
- 头尾处理：
  - 去掉开头空白
  - 去掉多余尾音
  - 加极短 `fade in / fade out`

### 后期清洗最低要求

- 去掉杂音和空白
- 音量不要忽大忽小
- 不要留过长混响尾巴
- 同一事件的多个变体听感要同类，但不能完全一样

## 每个事件的可复制 AIGC Prompt

下面每条都按“可直接复制”写。你可以直接投给外部 AIGC 音频平台，再按结果做后期。

---

### 1. `sfx_shot_fire`

用途：玩家开枪瞬间的主反馈。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：开枪主反馈
时长：0.18秒到0.45秒
风格：科幻、利落、清晰、有冲击但不过厚重
结构：短促爆发起音 + 轻微机械尾音 + 干净收尾
用途：玩家点击射击时立即播放，是战斗中的核心动作反馈
要求：声音要清楚、有辨识度，适合与命中确认音连续配合
不要：电影预告片轰鸣、过强低频、过长混响、真实战争重火器风格、语音元素
```

导出命名建议：

- `sfx_shot_fire_01.ogg`
- `sfx_shot_fire_02.ogg`

资源路径建议：

- `res://audio/sfx/weapon/sfx_shot_fire_01.ogg`
- `res://audio/sfx/weapon/sfx_shot_fire_02.ogg`

---

### 2. `sfx_shot_hit_target`

用途：打中正确目标时的正向确认。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：命中真实目标确认音
时长：0.12秒到0.30秒
风格：清脆、明确、正反馈、带轻微科技感
结构：瞬时命中提示 + 短亮音尾巴
用途：玩家开枪命中正确目标时播放，需要让人立刻知道“打对了”
要求：比普通UI点击更强，但不能像爆炸或血腥写实冲击
不要：厚重低频、恐怖感、内脏感、过长拖尾、失败或告警语义
```

导出命名建议：

- `sfx_shot_hit_target_01.ogg`
- `sfx_shot_hit_target_02.ogg`

资源路径建议：

- `res://audio/sfx/impact/sfx_shot_hit_target_01.ogg`
- `res://audio/sfx/impact/sfx_shot_hit_target_02.ogg`

---

### 3. `sfx_shot_hit_wall`

用途：命中掩体、墙体、遮挡物。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：子弹命中掩体或墙体
时长：0.18秒到0.50秒
风格：清楚、偏硬质、带阻挡感
结构：瞬时撞击 + 短促材质回弹 + 干净收尾
用途：玩家打到遮挡物时播放，需要明显区别于命中真实目标
要求：让玩家听出“被挡住了”，而不是“打中了”
不要：正向奖励感、胜利感、血肉感、过长空间混响
```

导出命名建议：

- `sfx_shot_hit_wall_01.ogg`
- `sfx_shot_hit_wall_02.ogg`

资源路径建议：

- `res://audio/sfx/impact/sfx_shot_hit_wall_01.ogg`
- `res://audio/sfx/impact/sfx_shot_hit_wall_02.ogg`

---

### 4. `sfx_shot_hit_wrong`

用途：误伤平民时的负反馈。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：误伤平民警告音
时长：0.20秒到0.45秒
风格：负反馈、警示、克制、明确，不要刺耳到烦躁
结构：短促错误提示 + 轻微下坠感
用途：玩家打错目标时播放，必须和正确命中明显区分
要求：一听就知道这是错误操作
不要：正向成功感、胜利感、过度尖锐报警器、过长拖尾、人声
```

导出命名建议：

- `sfx_shot_hit_wrong_01.ogg`
- `sfx_shot_hit_wrong_02.ogg`

资源路径建议：

- `res://audio/sfx/impact/sfx_shot_hit_wrong_01.ogg`
- `res://audio/sfx/impact/sfx_shot_hit_wrong_02.ogg`

---

### 5. `sfx_shot_miss`

用途：射击未命中。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：未命中提示音
时长：0.10秒到0.22秒
风格：轻、短、偏中性，略带失落感
结构：短促落空提示 + 快速收尾
用途：玩家开枪但没有命中有效目标时播放
要求：存在感要低于误伤音和正确命中音
不要：强烈告警、奖励感、厚重爆炸、太长混响
```

导出命名建议：

- `sfx_shot_miss_01.ogg`
- `sfx_shot_miss_02.ogg`

资源路径建议：

- `res://audio/sfx/impact/sfx_shot_miss_01.ogg`
- `res://audio/sfx/impact/sfx_shot_miss_02.ogg`

---

### 6. `sfx_scan_activate`

用途：点击扫描道具时的施放音。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：扫描技能开启
时长：0.45秒到0.90秒
风格：未来感、电子感、清晰、轻量，不厚重
结构：短促起音 + 中段脉冲扩散 + 干净收尾
用途：玩家点击扫描按钮后立即播放，表示扫描已经发出
要求：有“侦测启动”的感觉，但不要盖过后续战斗反馈
不要：过长混响、过强低频、电影预告片感、人声、魔法吟唱感
```

导出命名建议：

- `sfx_scan_activate_01.ogg`
- `sfx_scan_activate_02.ogg`

资源路径建议：

- `res://audio/sfx/ability/sfx_scan_activate_01.ogg`
- `res://audio/sfx/ability/sfx_scan_activate_02.ogg`

---

### 7. `sfx_scan_reveal`

用途：扫描后目标显露、高亮、生效提示。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：扫描结果显露
时长：0.35秒到0.80秒
风格：科技感、通透、明确、略带上升感
结构：轻脉冲确认 + 亮音展开 + 短收尾
用途：扫描生效后播放，用于提示目标被识别或线索已显露
要求：语义要偏“确认”和“显现”，不要和施放音混成一种
不要：强烈攻击性、过重低频、失败感、恐怖感
```

导出命名建议：

- `sfx_scan_reveal_01.ogg`
- `sfx_scan_reveal_02.ogg`

资源路径建议：

- `res://audio/sfx/ability/sfx_scan_reveal_01.ogg`
- `res://audio/sfx/ability/sfx_scan_reveal_02.ogg`

---

### 8. `sfx_time_extend`

用途：获得加时时的正向提示。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：时间延长奖励提示
时长：0.30秒到0.70秒
风格：积极、清晰、轻盈、带少量科技感
结构：短促起音 + 小幅上扬 + 简短收尾
用途：玩家使用或获得加时道具时播放
要求：要有明确正向收益感，但不能像结算胜利音那么重
不要：厚重史诗感、长旋律、人声、刺耳高频
```

导出命名建议：

- `sfx_time_extend_01.ogg`
- `sfx_time_extend_02.ogg`

资源路径建议：

- `res://audio/sfx/ability/sfx_time_extend_01.ogg`
- `res://audio/sfx/ability/sfx_time_extend_02.ogg`

---

### 9. `ui_button_click`

用途：设置、返回、确认、购买等常用按钮。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：通用按钮点击
时长：0.04秒到0.12秒
风格：短、小、干净、轻科技感
结构：极短点击 + 快速收尾
用途：界面中的通用按钮交互音
要求：高频重复播放也不烦，不抢戏
不要：厚重低频、过强金属感、长尾巴、明显旋律
```

导出命名建议：

- `ui_button_click_01.ogg`
- `ui_button_click_02.ogg`

资源路径建议：

- `res://audio/ui/ui_button_click_01.ogg`
- `res://audio/ui/ui_button_click_02.ogg`

---

### 10. `ui_result_win`

用途：战斗胜利结算时的正向结果音。

可复制 Prompt：

```text
为一款科幻伪装识别类狙击游戏生成音效。
事件：胜利结算提示音
时长：0.80秒到1.80秒
风格：积极、清晰、克制、未来感
结构：短促确认起音 + 简短上扬旋律 + 干净结束
用途：玩家通关并进入胜利结算时播放
要求：有明显“完成任务”的感觉，但不要过于盛大
不要：史诗大片配乐、长段音乐、合唱、人声、过强鼓点
```

导出命名建议：

- `ui_result_win_01.ogg`
- `ui_result_win_02.ogg`

资源路径建议：

- `res://audio/ui/ui_result_win_01.ogg`
- `res://audio/ui/ui_result_win_02.ogg`

## Manifest 填写示例

### 单条模板

下面这段可以直接复制，再替换事件名和路径：

```json
{
  "event_id": "sfx_xxx",
  "display_name": "中文名称",
  "category": "sfx",
  "bus": "SFX",
  "play_mode": "2d",
  "loop": false,
  "default_volume_db": -4.0,
  "pitch_random_min": 0.98,
  "pitch_random_max": 1.03,
  "cooldown_ms": 50,
  "max_instances": 3,
  "status": "planned",
  "notes": "这里写设计说明或验收备注。",
  "variants": [
    {
      "asset_path": "res://audio/sfx/xxx/sfx_xxx_01.ogg",
      "weight": 1
    },
    {
      "asset_path": "res://audio/sfx/xxx/sfx_xxx_02.ogg",
      "weight": 1
    }
  ]
}
```

### 示例 1：`sfx_shot_fire`

```json
{
  "event_id": "sfx_shot_fire",
  "display_name": "开枪",
  "category": "sfx",
  "bus": "SFX",
  "play_mode": "2d",
  "loop": false,
  "default_volume_db": -3.0,
  "pitch_random_min": 0.98,
  "pitch_random_max": 1.03,
  "cooldown_ms": 40,
  "max_instances": 4,
  "status": "planned",
  "notes": "首批核心反馈；前期建议先用 2D 保证清晰度。",
  "variants": [
    {
      "asset_path": "res://audio/sfx/weapon/sfx_shot_fire_01.ogg",
      "weight": 1
    },
    {
      "asset_path": "res://audio/sfx/weapon/sfx_shot_fire_02.ogg",
      "weight": 1
    }
  ]
}
```

### 示例 2：`sfx_shot_hit_wall`

```json
{
  "event_id": "sfx_shot_hit_wall",
  "display_name": "命中掩体/墙体",
  "category": "sfx",
  "bus": "SFX",
  "play_mode": "3d",
  "loop": false,
  "default_volume_db": -5.0,
  "pitch_random_min": 0.96,
  "pitch_random_max": 1.05,
  "cooldown_ms": 30,
  "max_instances": 6,
  "status": "planned",
  "notes": "后续可拆分为 metal / concrete / ground 等材质子事件。",
  "variants": [
    {
      "asset_path": "res://audio/sfx/impact/sfx_shot_hit_wall_01.ogg",
      "weight": 1
    },
    {
      "asset_path": "res://audio/sfx/impact/sfx_shot_hit_wall_02.ogg",
      "weight": 1
    }
  ]
}
```

### 示例 3：`ui_button_click`

```json
{
  "event_id": "ui_button_click",
  "display_name": "按钮点击",
  "category": "ui",
  "bus": "UI",
  "play_mode": "2d",
  "loop": false,
  "default_volume_db": -8.0,
  "pitch_random_min": 1.00,
  "pitch_random_max": 1.02,
  "cooldown_ms": 20,
  "max_instances": 3,
  "status": "planned",
  "notes": "设置、返回、确认等基础 UI 复用。",
  "variants": [
    {
      "asset_path": "res://audio/ui/ui_button_click_01.ogg",
      "weight": 1
    },
    {
      "asset_path": "res://audio/ui/ui_button_click_02.ogg",
      "weight": 1
    }
  ]
}
```

## 贴近业务的最小验收

### 1. 正确命中

- 操作：进入 PVE，开枪击中真实目标
- 期望：
  - 先听到 `sfx_shot_fire`
  - 再听到 `sfx_shot_hit_target`
  - 两者不重复叠播

### 2. 误伤平民

- 操作：击中 civilian
- 期望：
  - 播放 `sfx_shot_hit_wrong`
  - 不应出现正向命中确认语义

### 3. 打中掩体

- 操作：击中 `pve_cover_obstacle_3d`
- 期望：
  - 播放 `sfx_shot_hit_wall`
  - 明显区别于命中目标

### 4. 使用扫描

- 操作：点击扫描道具
- 期望：
  - 先播放 `sfx_scan_activate`
  - 生效时播放 `sfx_scan_reveal`
  - 两者语义清楚，不混成一种

### 5. 点击 UI

- 操作：在设置、商店、返回主页等页面连续点击
- 期望：
  - `ui_button_click` 高频播放也不烦
  - 不刺耳，不拖尾，不抢战斗主反馈

## 最后建议

- 每个事件至少先做 `2` 个变体，不然重复感会很重
- 第一轮先求“语义对”，第二轮再追“质感强”
- AIGC 结果不要直接裸用，至少做一次头尾清洗和响度统一
- 业务脚本只调用 `event_id`，不要直接写死资源路径
