# Step 8 结算与成长成熟方案

## 信息结构

结算页按 5 层组织：

1. 荣耀头部  
   内容：评级、称号、可分享标题、高光标签、纪录突破。

2. 奖励拆分  
   内容：基础金币、时间奖励、误伤扣减、广告奖励、本局金币合计。

3. 战绩表现  
   内容：命中率、命中/射击、误伤次数、连续稳定回合、扫描使用、时间延长、存活时长。

4. 成长建议  
   内容：推荐升级项、推荐理由、当前成长摘要。

5. 下一步行动  
   内容：一个主按钮 + 若干次级按钮。  
   规则：主按钮只保留一个，优先引导玩家做最值得的动作。

升级页按 4 层组织：

1. 资源与推荐  
   内容：当前金币、推荐升级结论、推荐理由。

2. 成长选项卡  
   内容：稳定性卡、缩放倍率卡。每张卡包含当前效果、升级后效果、花费、是否推荐。

3. 成长概览  
   内容：当前武器成长摘要和说明文案。

4. 流程推进  
   内容：开始下一关、返回主页。

## 评级规则

评级目标不是单纯按通关与否判断，而是综合衡量“完成质量”。

- 成功局基础分更高，失败局基础分更低
- 命中率越高，加分越多
- 连续无失误回合越多，加分越多
- 误伤次数越多，扣分越多
- 零误伤、无道具通关会得到额外加分

建议区间：

- `S`：完美猎手
- `A`：冷静清剿
- `B`：稳定完成
- `C`：惊险过关 / 潜力可见
- `D`：失误偏多
- `E`：任务中断

## 高光标签规则

标签分成两类：

1. 表现标签  
   示例：`零误伤`、`高命中`、`连续稳定`、`无道具通关`、`速通`、`奖励翻倍`

2. 纪录标签  
   示例：`首通达成`、`命中率新高`、`奖励新高`、`最快通关`、`首次零误伤`

输出规则：

- 先生成表现标签
- 再补纪录标签
- 总量控制在 3~5 个，避免页面过满

## 按钮层级

结算页主按钮规则：

- 失败时：主按钮 = `重开当前关`
- 成功且可进下一关时：主按钮 = `开始下一关`
- 成功但更推荐先成长时：主按钮 = `进入升级`
- 没有更强动作时：主按钮 = `返回主页`

结算页次级按钮：

- `进入升级`
- `开始下一关`
- `重开当前关`
- `返回主页`

广告按钮不与主流程按钮抢层级，单独放在“额外收益”区。

升级页主按钮规则：

- 能买推荐升级时：主按钮 = `按建议升级`
- 不能买时：主按钮保留为说明型按钮，提示玩家直接进入下一步验证

## Godot 落地建议

当前方案适合直接用 Godot 代码动态构建，避免频繁改 `.tscn`。

推荐结构：

```text
ScrollContainer
  VBoxContainer
    HeroPanel
      GradeLabel
      TitleLabel
      ShareTitleLabel
      TagFlow
      RecordLabel
    RewardPanel
      TotalRewardLabel
      RewardRows
    StatsPanel
      GridContainer
    GrowthPanel
      RecommendationHeadline
      RecommendationBody
      GrowthSummary
    ActionPanel
      PrimaryActionButton
      SecondaryButtons
    AdPanel
      RewardedAdButton
      AdModeButton
      StatusLabel
```

升级页推荐结构：

```text
ScrollContainer
  VBoxContainer
    HeroPanel
      GoldLabel
      RecommendationLabel
      PrimaryUpgradeButton
    CardsPanel
      StabilityCard
      ZoomCard
    SummaryPanel
      GrowthSummary
    ActionPanel
      NextLevelButton
      MenuButton
```

## 当前实现位置

- 规则层：`scripts/core/core_game_state.gd`
- 结算页：`scripts/ui/ui_panel_result.gd`
- 升级页：`scripts/ui/ui_panel_upgrade.gd`

这套实现重点不是“数据更多”，而是把原始结算数据组织成：

- 可理解
- 有荣耀感
- 有下一步决策引导
- 适合截图传播
