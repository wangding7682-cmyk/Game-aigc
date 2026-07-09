extends "res://scripts/platform/platform_adapter_base.gd"

const PlatformBridgeWeb = preload("res://scripts/platform/platform_bridge_web.gd")

var _bridge := PlatformBridgeWeb.new()


func get_platform_name() -> String:
    return "wechat_mini_game"


func is_runtime_available() -> bool:
    return _bridge.is_available() and _bridge.detect_platform() == "wechat"


func build_status_summary() -> String:
    var runtime_info := _bridge.call_sync("getRuntimeInfo")
    return "平台：微信小游戏 | SDK：%s | 广告位：%s" % [
        str(runtime_info.get("sdkVersion", "")),
        "已配置" if bool(runtime_info.get("adUnitConfigured", false)) else "未配置",
    ]


func init_platform() -> Dictionary:
    return _bridge.call_sync("getRuntimeInfo")


func init_share_menu() -> Dictionary:
    return _bridge.call_sync("initShareMenu")


func request_login() -> Dictionary:
    return await _bridge.call_async("requestLogin")


func open_share(payload: Dictionary = {}) -> Dictionary:
    return await _bridge.call_async("openShare", payload)


func is_rewarded_ad_available() -> bool:
    var runtime_info := _bridge.call_sync("getRuntimeInfo")
    return bool(runtime_info.get("adUnitConfigured", false))


func show_rewarded_ad(placement: String) -> Dictionary:
    return await _bridge.call_async("showRewardedAd", {
        "placement": placement,
    }, 15.0)


func save_game(payload: Dictionary) -> Dictionary:
    return _bridge.call_sync("saveGame", payload)


func load_game() -> Dictionary:
    return _bridge.call_sync("loadGame")
