extends Node

const PlatformAdapterMock = preload("res://scripts/platform/platform_adapter_mock.gd")
const PlatformAdapterWechat = preload("res://scripts/platform/platform_adapter_wechat.gd")
const PlatformAdapterDouyin = preload("res://scripts/platform/platform_adapter_douyin.gd")
const PlatformBridgeWeb = preload("res://scripts/platform/platform_bridge_web.gd")

const ANALYTICS_LOG_PATH := "user://analytics_events.jsonl"
const PLATFORM_CONFIG_PATH := "res://configs/platform/cfg_platform_channels.json"

const DISPLAY_MODE_AUTO := "auto"
const DISPLAY_MODE_MOBILE := "mobile"
const DISPLAY_MODE_PC := "pc"

var _bridge = PlatformBridgeWeb.new()
var _adapter = PlatformAdapterMock.new()
var _platform_config: Dictionary = {}
var _runtime_target := "mock"
var _mock_enabled := true
var _display_mode := DISPLAY_MODE_AUTO
signal display_mode_changed(mode: String)


func _ready() -> void:
	_platform_config = _load_platform_config()
	_bridge.ensure_initialized(_platform_config)
	_runtime_target = _resolve_runtime_target()
	_adapter = _create_adapter(_runtime_target)
	if _adapter != null and _adapter.has_method("setup"):
		_adapter.setup(_runtime_target, _platform_config.get(_runtime_target, {}))
		_adapter.init_platform()
		_adapter.init_share_menu()
	_load_display_mode()


func get_platform_name() -> String:
	return _adapter.get_platform_name()


func get_runtime_target() -> String:
	return _runtime_target


func is_mobile_device() -> bool:
	var os_name := OS.get_name().to_lower()
	if os_name == "android" or os_name == "ios":
		return true
	if _runtime_target == "wechat" or _runtime_target == "douyin":
		return true
	if os_name == "web":
		return _detect_web_mobile()
	return false


func get_display_mode() -> String:
	return _display_mode


func set_display_mode(mode: String) -> void:
	if mode != DISPLAY_MODE_AUTO and mode != DISPLAY_MODE_MOBILE and mode != DISPLAY_MODE_PC:
		return
	if _display_mode == mode:
		return
	_display_mode = mode
	_save_display_mode()
	display_mode_changed.emit(_display_mode)


func cycle_display_mode() -> String:
	match _display_mode:
		DISPLAY_MODE_AUTO:
			_display_mode = DISPLAY_MODE_MOBILE
		DISPLAY_MODE_MOBILE:
			_display_mode = DISPLAY_MODE_PC
		DISPLAY_MODE_PC:
			_display_mode = DISPLAY_MODE_AUTO
		_:
			_display_mode = DISPLAY_MODE_AUTO
	_save_display_mode()
	display_mode_changed.emit(_display_mode)
	return _display_mode


func is_portrait_display_mode() -> bool:
	match _display_mode:
		DISPLAY_MODE_MOBILE:
			return true
		DISPLAY_MODE_PC:
			return false
		_:
			return is_mobile_device()


func get_display_mode_name() -> String:
	match _display_mode:
		DISPLAY_MODE_AUTO:
			return "自动"
		DISPLAY_MODE_MOBILE:
			return "移动端"
		DISPLAY_MODE_PC:
			return "PC/Web"
		_:
			return "自动"


func _load_display_mode() -> void:
	var saved: Dictionary = CoreSaveService.load_profile()
	var mode = str(saved.get("display_mode", DISPLAY_MODE_AUTO))
	if mode == DISPLAY_MODE_MOBILE or mode == DISPLAY_MODE_PC or mode == DISPLAY_MODE_AUTO:
		_display_mode = mode
	else:
		_display_mode = DISPLAY_MODE_AUTO


func _save_display_mode() -> void:
	var saved: Dictionary = CoreSaveService.load_profile()
	saved["display_mode"] = _display_mode
	CoreSaveService.save_profile(saved)


func _detect_web_mobile() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return false
	var aspect := maxf(viewport_size.x, viewport_size.y) / minf(viewport_size.x, viewport_size.y)
	var smaller_side := minf(viewport_size.x, viewport_size.y)
	return smaller_side < 900.0 and aspect > 1.4


func is_mock_enabled() -> bool:
	return _adapter.is_mock_runtime() and _mock_enabled


func set_mock_enabled(enabled: bool) -> void:
	if not _adapter.is_mock_runtime():
		return
	_mock_enabled = enabled


func build_mock_status() -> String:
	if _adapter.is_mock_runtime():
		return "%s | 平台 mock：%s" % [
			_adapter.build_status_summary(),
			"开启" if _mock_enabled else "关闭",
		]
	return _adapter.build_status_summary()


func get_platform_config() -> Dictionary:
	return _platform_config.duplicate(true)


func get_analytics_log_path() -> String:
	return ANALYTICS_LOG_PATH


func supports_debug_ad_mode_toggle() -> bool:
	return _adapter.supports_debug_controls() and is_mock_enabled()


func request_login() -> Dictionary:
	if _adapter.is_mock_runtime() and not _mock_enabled:
		return {
			"ok": false,
			"reason": "mock_disabled",
			"message": "平台 mock 已关闭，无法执行登录",
			"platform": get_platform_name(),
		}

	var result: Dictionary = await _adapter.request_login()
	_log_platform_event("platform_login_result", result)
	return result


func open_share(payload: Dictionary = {}) -> Dictionary:
	if _adapter.is_mock_runtime() and not _mock_enabled:
		return {
			"ok": false,
			"reason": "mock_disabled",
			"message": "平台 mock 已关闭，无法执行分享",
			"platform": get_platform_name(),
		}

	var result: Dictionary = await _adapter.open_share(payload)
	_log_platform_event("platform_share_result", {
		"ok": bool(result.get("ok", false)),
		"platform": get_platform_name(),
		"from": str(payload.get("from", "")),
		"reason": str(result.get("reason", "")),
	})
	return result


func is_rewarded_ad_available() -> bool:
	if _adapter.is_mock_runtime() and not _mock_enabled:
		return false
	return _adapter.is_rewarded_ad_available()


func show_rewarded_ad(placement: String) -> Dictionary:
	if _adapter.is_mock_runtime() and not _mock_enabled:
		return {
			"ok": false,
			"placement": placement,
			"reason": "mock_disabled",
			"message": "平台 mock 已关闭，无法执行激励视频",
			"platform": get_platform_name(),
		}

	var result: Dictionary = await _adapter.show_rewarded_ad(placement)
	_log_platform_event("rewarded_ad_result", {
		"ok": bool(result.get("ok", false)),
		"placement": placement,
		"platform": get_platform_name(),
		"reason": str(result.get("reason", "")),
		"completed": bool(result.get("completed", false)),
	})
	return result


func cycle_rewarded_ad_mode() -> String:
	return _adapter.cycle_rewarded_ad_mode()


func get_rewarded_ad_mode_name() -> String:
	return _adapter.get_rewarded_ad_mode_name()


func save_game(payload: Dictionary) -> bool:
	var save_result: Dictionary = _adapter.save_game(payload)
	if bool(save_result.get("ok", false)):
		return true
	return CoreSaveService.save_profile(payload)


func load_game() -> Dictionary:
	var load_result: Dictionary = _adapter.load_game()
	if bool(load_result.get("ok", false)):
		var payload = load_result.get("payload", {})
		if payload is Dictionary:
			return payload
	return CoreSaveService.load_profile()


func request_llm_analysis(prompt: String) -> Dictionary:
	if _adapter.is_mock_runtime() and not _mock_enabled:
		return {
			"ok": false,
			"reason": "mock_disabled",
			"message": "平台 mock 已关闭，无法执行LLM分析",
			"platform": get_platform_name(),
		}
	var result: Dictionary = await _adapter.request_llm_analysis(prompt)
	return result


func get_runtime_debug_snapshot() -> Dictionary:
	return {
		"runtime_target": _runtime_target,
		"platform_name": get_platform_name(),
		"mock_enabled": is_mock_enabled(),
		"adapter": _adapter.get_debug_snapshot(),
		"config": _platform_config.duplicate(true),
	}


func _load_platform_config() -> Dictionary:
	if not FileAccess.file_exists(PLATFORM_CONFIG_PATH):
		return {}

	var raw_text := FileAccess.get_file_as_string(PLATFORM_CONFIG_PATH)
	var parsed = JSON.parse_string(raw_text)
	if parsed is Dictionary:
		return parsed
	return {}


func _resolve_runtime_target() -> String:
	var configured_target := str(_platform_config.get("runtime_target", "auto")).to_lower()
	var detected_target := _bridge.detect_platform()

	if configured_target == "wechat" and detected_target == "wechat":
		return "wechat"
	if configured_target == "douyin" and detected_target == "douyin":
		return "douyin"
	if configured_target == "mock":
		return "mock"
	if detected_target == "wechat":
		return "wechat"
	if detected_target == "douyin":
		return "douyin"
	return "mock"


func _create_adapter(runtime_target: String):
	match runtime_target:
		"wechat":
			return PlatformAdapterWechat.new()
		"douyin":
			return PlatformAdapterDouyin.new()
		_:
			return PlatformAdapterMock.new()


func _log_platform_event(event_name: String, payload: Dictionary) -> void:
	var analytics_service := get_node_or_null("/root/AnalyticsService")
	if analytics_service != null:
		analytics_service.track_event(event_name, payload)
