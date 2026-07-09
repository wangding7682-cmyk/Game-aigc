extends Node

signal feedback_changed(status: String, message: String, visible: bool)

const STATUS_IDLE := "idle"
const STATUS_PENDING := "pending"
const STATUS_SUCCESS := "success"
const STATUS_FAILED := "failed"
const ROUTE_TIMEOUT_SEC := 3.0
const FAILED_FEEDBACK_AUTO_HIDE_SEC := 4.0

var _timed_out_expected_scene_path := ""
var _timed_out_label := ""

const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"
const UPGRADE_SCENE_PATH := "res://scenes/ui/ui_panel_upgrade.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/ui/ui_panel_settings.tscn"
const TUNING_SCENE_PATH := "res://scenes/ui/ui_panel_tuning.tscn"
const WEAPON_LIBRARY_SCENE_PATH := "res://scenes/ui/ui_panel_weapon_library.tscn"
const SHOP_SCENE_PATH := "res://scenes/ui/ui_panel_shop.tscn"
const TEST_CENTER_SCENE_PATH := "res://scenes/ui/ui_panel_test_center.tscn"
const PVP_LOBBY_SCENE_PATH := "res://scenes/pvp/pvp_lobby.tscn"
const PVP_NETWORK_ROOM_SCENE_PATH := "res://scenes/pvp/pvp_network_room.tscn"

var last_status: String = STATUS_IDLE
var last_message: String = ""
var last_route_id: String = ""
var last_origin: String = ""

var _pending_request_id := 0
var _pending_route_id := ""
var _pending_origin := ""
var _pending_label := ""
var _pending_expected_scene_path := ""


func request_route(route_id: String, origin: String = "", payload: Variant = null) -> bool:
	if _pending_request_id != 0:
		_set_feedback(STATUS_FAILED, "跳转失败：请等待当前页面切换完成。", true)
		return false

	var route_data := _resolve_route_data(route_id, payload)
	if route_data.is_empty():
		_set_feedback(STATUS_FAILED, "跳转失败：未定义入口 `%s`。" % route_id, true)
		return false

	_pending_request_id += 1
	_pending_route_id = route_id
	_pending_origin = origin
	_pending_label = str(route_data.get("label", route_id))
	_pending_expected_scene_path = str(route_data.get("expected_scene_path", ""))

	last_route_id = route_id
	last_origin = origin
	_set_feedback(STATUS_PENDING, "正在打开%s..." % _pending_label, true)
	_dispatch_route(route_id, payload)
	_watch_pending_request(_pending_request_id)
	return true


func confirm_scene(scene_path: String) -> void:
	if _pending_request_id == 0:
		if _timed_out_expected_scene_path != "" and scene_path == _timed_out_expected_scene_path:
			var resolved_label := _timed_out_label
			_timed_out_expected_scene_path = ""
			_timed_out_label = ""
			_set_feedback(STATUS_SUCCESS, "已打开%s" % resolved_label, false)
		elif _is_known_scene_path(scene_path):
			_timed_out_expected_scene_path = ""
			_timed_out_label = ""
			_set_feedback(STATUS_SUCCESS, "", false)
		return

	if scene_path == _pending_expected_scene_path:
		_timed_out_expected_scene_path = ""
		_timed_out_label = ""
		_clear_pending()
		_set_feedback(STATUS_SUCCESS, "已打开%s" % _pending_label, false)
		return

	var label := _pending_label
	_clear_pending()
	_set_feedback(STATUS_FAILED, "打开%s失败：实际进入了 `%s`。" % [label, scene_path], true)


func _watch_pending_request(request_id: int) -> void:
	await get_tree().create_timer(ROUTE_TIMEOUT_SEC).timeout
	if _pending_request_id != request_id:
		return

	var label := _pending_label
	_timed_out_expected_scene_path = _pending_expected_scene_path
	_timed_out_label = label
	_clear_pending()
	_set_feedback(STATUS_FAILED, "打开%s失败：目标页未在 %.1f 秒内就绪，请查看日志。" % [label, ROUTE_TIMEOUT_SEC], true)


func _resolve_route_data(route_id: String, payload: Variant) -> Dictionary:
	match route_id:
		"main_menu":
			return {"label": "主页", "expected_scene_path": MENU_SCENE_PATH}
		"level":
			var level_id := int(payload if payload != null else CoreGameState.current_level_id)
			return {"label": "第 %d 关" % level_id, "expected_scene_path": BATTLE_SCENE_PATH}
		"retry_current":
			return {"label": "当前关卡", "expected_scene_path": BATTLE_SCENE_PATH}
		"upgrade":
			return {"label": "升级页", "expected_scene_path": UPGRADE_SCENE_PATH}
		"next_level":
			if CoreGameState.can_go_next_level():
				return {"label": "下一关", "expected_scene_path": BATTLE_SCENE_PATH}
			return {"label": "主页", "expected_scene_path": MENU_SCENE_PATH}
		"settings":
			return {"label": "操作手感设置", "expected_scene_path": SETTINGS_SCENE_PATH}
		"tuning":
			return {"label": "关卡调参面板", "expected_scene_path": TUNING_SCENE_PATH}
		"weapon_library":
			return {"label": "武器库", "expected_scene_path": WEAPON_LIBRARY_SCENE_PATH}
		"shop":
			return {"label": "商店", "expected_scene_path": SHOP_SCENE_PATH}
		"test_center":
			return {"label": "测试中心", "expected_scene_path": TEST_CENTER_SCENE_PATH}
		"pvp_lobby":
			return {"label": "局域网大厅", "expected_scene_path": PVP_LOBBY_SCENE_PATH}
		"pvp_network_room":
			return {"label": "联机对战房间", "expected_scene_path": PVP_NETWORK_ROOM_SCENE_PATH}
		_:
			return {}


func _dispatch_route(route_id: String, payload: Variant) -> void:
	match route_id:
		"main_menu":
			CoreEventBus.main_menu_requested.emit()
		"level":
			CoreEventBus.level_requested.emit(int(payload if payload != null else CoreGameState.current_level_id))
		"retry_current":
			CoreEventBus.retry_requested.emit()
		"upgrade":
			CoreEventBus.upgrade_requested.emit()
		"next_level":
			CoreEventBus.next_level_requested.emit()
		"settings":
			CoreEventBus.settings_requested.emit()
		"tuning":
			CoreEventBus.tuning_requested.emit()
		"weapon_library":
			CoreEventBus.weapon_library_requested.emit()
		"shop":
			CoreEventBus.shop_requested.emit()
		"test_center":
			CoreEventBus.test_center_requested.emit()
		"pvp_lobby":
			CoreEventBus.pvp_lobby_requested.emit()
		"pvp_network_room":
			CoreEventBus.pvp_network_room_requested.emit()


func _set_feedback(status: String, message: String, visible: bool) -> void:
	last_status = status
	last_message = message
	feedback_changed.emit(status, message, visible)
	if status == STATUS_FAILED and visible:
		_auto_hide_failed_feedback()


func _auto_hide_failed_feedback() -> void:
	await get_tree().create_timer(FAILED_FEEDBACK_AUTO_HIDE_SEC).timeout
	if last_status == STATUS_FAILED:
		last_status = STATUS_IDLE
		feedback_changed.emit(STATUS_IDLE, "", false)


func _clear_pending() -> void:
	_pending_request_id = 0
	_pending_route_id = ""
	_pending_origin = ""
	_pending_label = ""
	_pending_expected_scene_path = ""


func _is_known_scene_path(scene_path: String) -> bool:
	return scene_path == MENU_SCENE_PATH \
	or scene_path == BATTLE_SCENE_PATH \
	or scene_path == UPGRADE_SCENE_PATH \
	or scene_path == SETTINGS_SCENE_PATH \
	or scene_path == TUNING_SCENE_PATH \
	or scene_path == WEAPON_LIBRARY_SCENE_PATH \
	or scene_path == SHOP_SCENE_PATH \
	or scene_path == TEST_CENTER_SCENE_PATH \
	or scene_path == PVP_LOBBY_SCENE_PATH \
	or scene_path == PVP_NETWORK_ROOM_SCENE_PATH
