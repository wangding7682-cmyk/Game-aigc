# 音频资产清单模板

## 用途

这份模板用于统一管理本项目音频资产，解决下面几类问题：

- 程序接入时，不再到处硬编码资源路径
- 音频设计、美术、程序对“事件名”和“资源文件”使用同一套口径
- 后续替换素材时，只改清单，不改业务脚本
- 便于做验收：哪些事件已配音、哪些仍缺失，一眼可见

建议搭配 `configs/audio/audio_manifest.json` 一起使用：

- `docs/audio_asset_manifest_template.md`：给人看，说明规则和字段语义
- `configs/audio/audio_manifest.json`：给程序读，放具体事件与资源映射

## 命名规则

保持当前项目已有规范：

- 事件名：`类别_事件`
- 推荐前缀：
  - `sfx_`：战斗/玩法/世界反馈
  - `ui_`：按钮、界面、结算
  - `bgm_`：背景音乐
  - `amb_`：环境循环氛围

示例：

- `sfx_shot_fire`
- `sfx_shot_hit_target`
- `sfx_shot_hit_wall`
- `sfx_shot_hit_wrong`
- `sfx_scan_activate`
- `sfx_time_extend`
- `ui_button_click`
- `ui_result_win`
- `amb_city_day`

## 目录建议

建议资源目录按下面方式落地：

```text
res://audio/
  sfx/
    weapon/
    impact/
    ability/
  ui/
  bgm/
  amb/
```

如果当前还没有全部目录，可以先按需要逐步创建，不要求一次补齐。

## 字段说明

每一条音频事件建议至少包含以下字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `event_id` | String | 是 | 事件唯一标识，业务层只使用它 |
| `display_name` | String | 是 | 给策划/音频/程序看的中文名称 |
| `category` | String | 是 | `sfx` / `ui` / `bgm` / `amb` |
| `bus` | String | 是 | 推荐 `SFX` / `UI` / `BGM` / `AMB` |
| `play_mode` | String | 是 | `2d` 或 `3d` |
| `loop` | bool | 是 | 是否循环 |
| `default_volume_db` | float | 是 | 默认音量 |
| `pitch_random_min` | float | 是 | 随机音高下限 |
| `pitch_random_max` | float | 是 | 随机音高上限 |
| `cooldown_ms` | int | 否 | 防止高频重复触发 |
| `max_instances` | int | 否 | 同时允许播放的最大实例数 |
| `variants` | Array | 是 | 资源变体列表，至少可为空数组 |
| `status` | String | 是 | `planned` / `placeholder` / `ready` |
| `notes` | String | 否 | 设计说明或验收备注 |

`variants` 中每个元素建议至少包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `asset_path` | String | `res://` 资源路径 |
| `weight` | int | 变体权重，默认 1 |
| `trim_ms` | int | 可选，素材头部裁切参考 |
| `tail_ms` | int | 可选，素材尾部保留参考 |

## 推荐首批事件

建议先做这 10 个，足够支撑当前 MVP 战斗闭环：

| 事件名 | 用途 | 推荐模式 | 备注 |
|------|------|------|------|
| `sfx_shot_fire` | 开枪主反馈 | `2d` | 先保证清晰，不急着做空间化 |
| `sfx_shot_hit_target` | 命中目标 | `2d` | 强反馈，避免和误伤混淆 |
| `sfx_shot_hit_wall` | 命中掩体/墙体 | `3d` | 后续可细分金属/混凝土 |
| `sfx_shot_hit_wrong` | 误伤平民 | `2d` | 明显负反馈 |
| `sfx_shot_miss` | 未命中 | `2d` | 弱于误伤，不要吵 |
| `sfx_scan_activate` | 扫描施放 | `2d` | 科技感短促起音 |
| `sfx_scan_reveal` | 扫描生效/显露 | `2d` 或 `3d` | 可做轻回声 |
| `sfx_time_extend` | 加时道具 | `2d` | 正向提示 |
| `ui_button_click` | 按钮点击 | `2d` | 全局复用 |
| `ui_result_win` | 胜利结算 | `2d` | 短句式正反馈 |

## 接入建议

业务层只关心事件，不直接关心音频文件路径：

```gdscript
AudioService.play_sfx("sfx_shot_fire")
AudioService.play_sfx("sfx_shot_hit_target")
AudioService.play_sfx_3d("sfx_shot_hit_wall", hit_point)
AudioService.play_ui("ui_button_click")
```

也就是说：

- `battle_core_3d.gd` / `visual_feedback_3d.gd` 发起播放事件
- `AudioService` 查询 `audio_manifest.json`
- 再根据 `bus`、`play_mode`、`variants` 选择真实资源

## 验收建议

### 配置验收

- 每个业务事件都有唯一 `event_id`
- 每个 `event_id` 都有 `bus`
- `2d/3d` 语义明确，不混用
- 循环音必须显式标记 `loop=true`

### 贴近业务的烟雾测试

1. 进入 PVE，开一枪命中目标  
   期望：`sfx_shot_fire` 与 `sfx_shot_hit_target` 各触发一次

2. 打到平民  
   期望：只出现 `sfx_shot_hit_wrong`，不能和正向命中音混播

3. 打到掩体  
   期望：触发 `sfx_shot_hit_wall`，并保留后续做材质细分的空间

4. 点击设置、返回、结算按钮  
   期望：统一走 `ui_button_click` 或对应 UI 事件，不要每个页面单独造命名

## 维护原则

- 先稳定事件名，再逐步替换素材
- 一个事件可以有多个变体，但不要多个事件名表达同一业务语义
- 业务脚本里不要直接写 `res://audio/...`，统一通过清单和 `AudioService`
- 当一个事件从占位音升级为正式音，只改 `status` 和资源路径，不改 `event_id`
