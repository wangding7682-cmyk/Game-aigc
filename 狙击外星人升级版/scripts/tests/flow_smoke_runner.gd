extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"
const RESULT_SCENE_PATH := "res://scenes/ui/ui_panel_result.tscn"

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
	CoreGameState.reset_progress()

	var root: Node = _find_existing_root()
	if root != null:
		_is_embedded = true
		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, MENU_SCENE_PATH)
	else:
		root = ROOT_SCENE.instantiate()
		add_child(root)
		await _wait_for_scene(root, MENU_SCENE_PATH)

	_assert_scene(root, MENU_SCENE_PATH, "启动后应进入主菜单")

	CoreGameState.tutorial_completed = true
	CoreEventBus.level_requested.emit(1)
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "点击开始后应进入战斗场景")

	var battle: Node = root.get("current_screen")
	if battle == null:
		_fail("战斗场景未实例化，无法继续测试")
	else:
		_assert_method(battle, "_finish_battle", "战斗场景缺少结束战斗能力")
		
		var battle_core = battle.get("battle_core")
		if battle_core == null:
			_fail("缺少 battle_core，无法验证外星人数量")
		else:
			var level_config = battle_core.get("level_config")
			if level_config != null:
				var expected_targets: int = int(level_config.get("required_targets"))
				var expected_civilians: int = int(level_config.get("civilian_count"))
				var total_targets: int = int(battle_core.get("total_targets"))
				if total_targets != expected_targets:
					_fail("第 1 关外星人数量不对，期望 %d，实际 %d" % [expected_targets, total_targets])
				
				var civilian_count := 0
				var alien_count := 0
				for actor in battle_core.get("active_actors"):
					if is_instance_valid(actor):
						if str(actor.get("actor_kind")) == "civilian":
							civilian_count += 1
						elif str(actor.get("actor_kind")) == "target":
							alien_count += 1
				if alien_count != expected_targets:
					_fail("第 1 关实际生成的外星人数量不对，期望 %d，实际 %d" % [expected_targets, alien_count])
				if civilian_count != expected_civilians:
					_fail("第 1 关平民数量不对，期望 %d，实际 %d" % [expected_civilians, civilian_count])
		
		if battle.has_method("_finish_battle"):
			battle.call("_finish_battle", true, "自动测试通关")

	await _wait_for_scene(root, RESULT_SCENE_PATH)
	_assert_scene(root, RESULT_SCENE_PATH, "战斗结束后应进入结算页")

	var result_panel: Node = root.get("current_screen")
	if result_panel == null:
		_fail("结算页未实例化")
	else:
		var buttons: Array = _collect_nodes(result_panel, "Button")
		var labels: Array = _collect_nodes(result_panel, "Label")
		if buttons.is_empty():
			_fail("结算页没有任何按钮，用户无法执行再来一局/下一关/返回主页")
		if labels.is_empty():
			_fail("结算页没有结算信息文本，用户无法看到本局结果")

	CoreEventBus.retry_requested.emit()
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "结算页触发重开后应返回战斗场景")

	var has_record_first_exit := CoreGameState.has_method("record_first_exit")
	if not has_record_first_exit:
		_fail("CoreGameState 缺少 record_first_exit()，战斗场景点击返回时会报错")

	if _failures.is_empty():
		print("[FLOW_SMOKE] PASS")
		_write_result("PASS", [])
		smoke_finished.emit("PASS", [])
		_teardown()
		return

	for failure in _failures:
		print("[FLOW_SMOKE] FAIL: %s" % failure)
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


func _assert_method(target: Object, method_name: String, message: String) -> void:
	if not target.has_method(method_name):
		_fail(message)


func _collect_nodes(node_ref, node_type_name):
	var results: Array = []
	if node_ref.is_class(node_type_name):
		results.append(node_ref)

	for child in node_ref.get_children():
		if child is Node:
			results.append_array(_collect_nodes(child, node_type_name))

	return results


func _fail(message: String) -> void:
	_failures.append(message)


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://flow_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 flow_smoke_result.txt")
		return

	var time_str := Time.get_datetime_string_from_system(true, true)
	file.store_line("FLOW_SMOKE=%s" % status)
	file.store_line("TIMESTAMP=%s" % time_str)
	if not failures.is_empty():
		for failure in failures:
			file.store_line(str(failure))
