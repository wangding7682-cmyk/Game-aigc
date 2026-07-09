# 资源状态模板

## 目的
这份文档用于统一记录每个资源当前处于什么阶段，避免后续出现：

1. 不知道这个资源是不是已经能接
2. 不知道它只是概念参考还是占位可用
3. 不知道它是否已经进入主项目

---

## 1. 推荐状态字段

每个资源建议统一记录：

| 字段 | 说明 |
|---|---|
| `asset_name` | 资源名 |
| `status_level` | 当前阶段状态 |
| `owner_module` | 属于哪个工程化模块 |
| `ready_for_integration` | 是否可进入主项目 |
| `blocking_reason` | 如果不能进入，卡在哪里 |
| `next_action` | 下一步应该做什么 |

---

## 2. 状态等级定义

### `concept_reference`

说明：

- 只有设计方向
- 还不能直接接入

适用场景：

- 参考图
- 方向图
- 情绪板

---

### `rule_defined`

说明：

- 规则已经明确
- 但还没有实际占位产物

适用场景：

- 已写完状态矩阵
- 已写完命名规则
- 已写完挂点说明

---

### `placeholder_ready`

说明：

- 已经有最小可用占位版本
- 可以进入主项目做 MVP 验证

适用场景：

- 角色最小占位结构
- 最小掩体占位体
- 最小反馈占位特效

---

### `integrated_mvp`

说明：

- 已经进入主项目
- 正在服务 MVP 测试

---

### `ready_for_final_replacement`

说明：

- MVP 验证通过
- 可以准备替换成正式资产

---

## 3. 模板示例

```text
asset_name:
status_level:
owner_module:
ready_for_integration:
blocking_reason:
next_action:
```

---

## 4. 角色类示例

```text
asset_name: alien_costume_disguise
status_level: rule_defined
owner_module: 01_character_placeholders
ready_for_integration: 否
blocking_reason: 还缺最小可用占位版本与材质切换参数
next_action: 生成 placeholder_ready 版本并验证近中景可读性
```

---

## 5. 掩体类示例

```text
asset_name: cover_wall_corner_placeholder
status_level: placeholder_ready
owner_module: 02_cover_placeholders
ready_for_integration: 是
blocking_reason:
next_action: 并入主项目 LevelRoot 并验证挡弹结果
```

---

## 6. 反馈类示例

```text
asset_name: fx_hit_confirm_world
status_level: rule_defined
owner_module: 03_feedback_rules
ready_for_integration: 否
blocking_reason: 角色命中点与结果链还需最终确认
next_action: 待 Step 3 射击结果验证通过后生成占位版
```

---

## 7. 使用建议

后续建议：

1. 每个资源至少保留一条状态记录
2. 每次状态变化就更新一次
3. 先看 `status_level`，再决定要不要接入

这样能避免：

- 还只是参考图就被当成正式接入资源
- 已经可接的资源反而没人推进

---

## 8. MVP 阶段的判断标准

在当前第一阶段 MVP 中：

- `concept_reference` 和 `rule_defined` 不应直接接入主项目
- `placeholder_ready` 才适合进入 MVP 验证
- `integrated_mvp` 表示已经正式进入测试链路

一句话：

**只有到 `placeholder_ready`，才值得开始并入主项目。**
