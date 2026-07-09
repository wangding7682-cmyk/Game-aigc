extends RefCounted

var _runtime_key := "mock"
var _platform_config: Dictionary = {}


func setup(runtime_key: String, platform_config: Dictionary = {}) -> void:
    _runtime_key = runtime_key
    _platform_config = platform_config.duplicate(true)


func get_runtime_key() -> String:
    return _runtime_key


func get_platform_name() -> String:
    return _runtime_key


func is_runtime_available() -> bool:
    return true


func is_mock_runtime() -> bool:
    return false


func supports_debug_controls() -> bool:
    return false


func build_status_summary() -> String:
    return "平台：%s" % get_platform_name()


func init_platform() -> Dictionary:
    return {
        "ok": true,
        "platform": get_platform_name(),
    }


func init_share_menu() -> Dictionary:
    return {
        "ok": true,
        "platform": get_platform_name(),
        "message": "当前平台无需额外初始化分享菜单",
    }


func request_login() -> Dictionary:
    return _unsupported("login_not_supported", "当前平台未接入登录能力")


func open_share(payload: Dictionary = {}) -> Dictionary:
    return _unsupported("share_not_supported", "当前平台未接入分享能力", payload)


func is_rewarded_ad_available() -> bool:
    return false


func show_rewarded_ad(_placement: String) -> Dictionary:
    return _unsupported("rewarded_ad_not_supported", "当前平台未接入激励视频能力")


func get_rewarded_ad_mode_name() -> String:
    return "真实平台"


func cycle_rewarded_ad_mode() -> String:
    return get_rewarded_ad_mode_name()


func save_game(_payload: Dictionary) -> Dictionary:
    return _unsupported("storage_not_supported", "当前平台未接入本地存档能力")


func load_game() -> Dictionary:
    return _unsupported("storage_not_supported", "当前平台未接入本地存档能力")


func get_debug_snapshot() -> Dictionary:
    return {
        "runtime_key": _runtime_key,
        "platform_name": get_platform_name(),
        "config": _platform_config.duplicate(true),
    }


func request_llm_analysis(_prompt: String) -> Dictionary:
    return _unsupported("llm_not_supported", "当前平台未接入LLM能力")


func _unsupported(reason: String, message: String, extra_payload: Dictionary = {}) -> Dictionary:
    var result := {
        "ok": false,
        "reason": reason,
        "message": message,
        "platform": get_platform_name(),
    }
    for key in extra_payload.keys():
        result[key] = extra_payload[key]
    return result
