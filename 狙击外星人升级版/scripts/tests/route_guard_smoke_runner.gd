extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"
const SHOP_SCENE_PATH := "res://scenes/ui/ui_panel_shop.tscn"

signal smoke_finished(status: String, failures: Array)

var _failures: Array[String] = []
var auto_quit := true
var _is_embedded := false
var skip_return_navigation := false


func _ready() -> void:
	call_deferred("_start_test")


func _start_test() -> void:
	await _run()


func _find_existing_root() -> Node:
	for child in get_tree().root.get_children():
		if child.get_script() and str(child.get_script().resource_path).find("core_game_root.gd") != -1:
			return child
	var current: Node = self
	while current != null:
		if current.get_script() and str(current.get_script().resource_path).find("core_game_root.gd") != -1:
			return current
		current = current.get_parent()
	return null


func _wait_for_scene(root: Node, expected_path: String, max_frames: int = 120) -> void:
	for _i in range(max_frames):
		await get_tree().process_frame
		var scene_ready := str(root.get("current_scene_path")) == expected_path and root.get("current_screen") != null
		var transition_done := true
		if root.has_method("_debug_is_transitioning"):
			transition_done = not bool(root.call("_debug_is_transitioning"))
		if scene_ready and transition_done:
			return
	_fail("等待场景切换超时：%s" % expected_path)


func _run() -> void:
	var root: Node = _find_existing_root()
	if root != null:
		_is_embedded = true
		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, MENU_SCENE_PATH)
	else:
		root = ROOT_SCENE.instantiate()
		add_child(root)
		await _wait_for_scene(root, MENU_SCENE_PATH)

	var opened := RouteGuard.request_route("shop", "路由守卫烟雾-商店")
	if not opened:
		_fail("合法路由 `shop` 未能发起跳转")
	else:
		await _wait_for_scene(root, SHOP_SCENE_PATH)
		_assert_scene(root, SHOP_SCENE_PATH, "商店路由应成功打开商店页")
		if RouteGuard.last_status != RouteGuard.STATUS_SUCCESS:
			_fail("商店路由成功后，RouteGuard 状态应为 success")

	var rejected := RouteGuard.request_route("missing_route", "路由守卫烟雾-非法路由")
	if rejected:
		_fail("非法路由不应返回成功")
	await get_tree().process_frame
	await get_tree().process_frame

	if RouteGuard.last_status != RouteGuard.STATUS_FAILED:
		_fail("非法路由后，RouteGuard 状态应为 failed")
	if RouteGuard.last_message.find("未定义入口") == -1:
		_fail("非法路由后，应给出明确的未定义入口提示")
	if not root.route_feedback_panel.visible:
		_fail("非法路由后，反馈层应保持可见")

	RouteGuard.request_route("main_menu", "路由守卫烟雾-返回主页")
	await _wait_for_scene(root, MENU_SCENE_PATH)
	_assert_scene(root, MENU_SCENE_PATH, "返回主页路由应成功打开主菜单")

	var level_opened := RouteGuard.request_route("level", "路由守卫烟雾-关卡", 1)
	if not level_opened:
		_fail("合法路由 `level` 未能发起跳转")
	else:
		await _wait_for_scene(root, BATTLE_SCENE_PATH)
		_assert_scene(root, BATTLE_SCENE_PATH, "关卡路由应成功打开战斗页")
		if RouteGuard.last_status != RouteGuard.STATUS_SUCCESS:
			_fail("关卡路由成功后，RouteGuard 状态应为 success")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("[ROUTE_GUARD_SMOKE] PASS")
		_write_result("PASS", [])
		smoke_finished.emit("PASS", [])
		_teardown()
		return

	for failure in _failures:
		print("[ROUTE_GUARD_SMOKE] FAIL: %s" % failure)
	_write_result("FAIL", _failures)
	smoke_finished.emit("FAIL", _failures.duplicate())
	_teardown()


func _teardown() -> void:
	if _is_embedded:
		if not skip_return_navigation:
			CoreEventBus.test_center_requested.emit()
			await get_tree().process_frame
	elif auto_quit:
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			get_tree().quit(0 if _failures.is_empty() else 1)
		)


func _assert_scene(root: Node, expected_path: String, message: String) -> void:
	var current_screen: Node = root.get("current_screen")
	if current_screen == null:
		_fail("%s：当前场景为空" % message)
		return
	var current_path: String = str(root.get("current_scene_path"))
	if current_path != expected_path:
		_fail("%s：实际是 %s" % [message, current_path])


func _fail(message: String) -> void:
	_failures.append(message)


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://route_guard_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 route_guard_smoke_result.txt")
		return

	var time_str := Time.get_datetime_string_from_system(true, true)
	file.store_line("ROUTE_GUARD_SMOKE=%s" % status)
	file.store_line("TIMESTAMP=%s" % time_str)
	if not failures.is_empty():
		for failure in failures:
			file.store_line(str(failure))
