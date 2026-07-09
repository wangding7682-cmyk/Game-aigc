# 微信 / 抖音小游戏上线前准备

## 这次已完成

- 平台层已支持运行时自动识别：`mock` / `wechat` / `douyin`
- 已接入统一能力入口：
  - 登录
  - 分享
  - 激励视频广告
  - 本地存档
  - 生命周期感知（前后台）
- 业务层仍只调用 `PlatformService`
- 桌面调试继续走 `mock`，不阻塞现有主流程
- 测试中心已增加：
  - `平台登录自检`
  - `平台分享自检`
  - `平台存档自检`
  - `平台广告自检`

## 关键文件

- 平台总入口：`scripts/platform/platform_service.gd`
- 微信适配器：`scripts/platform/platform_adapter_wechat.gd`
- 抖音适配器：`scripts/platform/platform_adapter_douyin.gd`
- Web/小游戏桥：`scripts/platform/platform_bridge_web.gd`
- 渠道配置：`configs/platform/cfg_platform_channels.json`
- 自检入口：`scripts/ui/ui_panel_test_center.gd`

## 你现在只需要补的配置

编辑 `configs/platform/cfg_platform_channels.json`：

```json
{
  "runtime_target": "auto",
  "storage_key": "sniper_alien_profile_v1",
  "wechat": {
    "app_id": "你的微信小游戏 AppID",
    "rewarded_ad_unit_id": "你的微信激励视频广告位 ID"
  },
  "douyin": {
    "app_id": "你的抖音小游戏 AppID",
    "rewarded_ad_unit_id": "你的抖音激励视频广告位 ID",
    "share_template_id": "你的抖音分享模板 ID"
  }
}
```

## 上线前必做

### 微信小游戏

1. 在微信开放平台申请小游戏 AppID
2. 在广告能力后台创建激励视频广告位，拿到 `rewarded_ad_unit_id`
3. 如果要做更完整分享素材，补充分享图与 query 约定
4. 准备服务端登录接口：接收 `wx.login` 返回的 `code`，换取 `openid / session_key / unionid`

### 抖音小游戏

1. 在抖音开放平台申请小游戏 AppID
2. 开通流量主并创建激励视频广告位，拿到 `rewarded_ad_unit_id`
3. 如果要主动分享卡片，先在后台配置分享模板，拿到 `share_template_id`
4. 准备服务端登录接口：接收 `tt.login` 返回的 `code` 或 `anonymousCode`

## 验收顺序

### 第一步：桌面不回归

在桌面直接运行项目：

- 主流程能正常进入战斗
- 结算页点击奖励翻倍仍能走 mock
- 存档、读档不报错

### 第二步：平台开发者工具验证

在微信 / 抖音开发者工具中打开项目后，进入 `测试中心`，顺序点击：

1. `平台登录自检`
2. `平台分享自检`
3. `平台存档自检`
4. `平台广告自检`

通过标准：

- 登录接口返回成功或返回明确可处理的失败原因
- 分享能正常调起系统分享面板
- 存档写入后能读回
- 激励视频关闭后能返回完整结果，业务层可据此决定是否发奖

## 当前设计口径

- 真实平台优先走平台原生存储：`wx/tt.setStorageSync`
- 若平台存储不可用，自动回退到 `CoreSaveService`
- 广告结果只通过统一返回值给业务层，不让业务层依赖 `wx` / `tt`
- 微信与抖音的登录都只拿“临时凭证”，正式用户态交换仍由你的服务端完成

## 还未自动化的部分

- 平台后台的 AppID / 广告位 / 分享模板申请
- 服务端 `code -> session/openid` 交换
- 各平台最终提审材料、分级、合规配置

## 建议的最终提审前复核

- 第 1 关完整跑通
- 结算页广告奖励成功一次、失败一次
- 分享拉起一次
- 登录凭证打到后端一次
- 本地存档写入和恢复各一次
- 开关到后台再回前台一次，确认不会丢状态
