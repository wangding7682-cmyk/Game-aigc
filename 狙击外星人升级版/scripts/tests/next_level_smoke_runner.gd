extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"
const RESULT_SCENE_PATH := "res://scenes/ui/ui_panel_result.tscn"
const UPGRADE_SCENE_PATH := "res://scenes/ui/ui_panel_upgrade.tscn"

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
	CoreGameState.tutorial_completed = true

	var root: Node = _find_existing_root()
	if root != null:
		_is_embedded = true
		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, "res://scenes/menu/menu_main_menu.tscn")
	else:
		root = ROOT_SCENE.instantiate()
		add_child(root)
		await _wait_for_scene(root, "res://scenes/menu/menu_main_menu.tscn")

	CoreEventBus.level_requested.emit(1)
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "开始第 1 关后应进入战斗场景")

	var battle: Node = root.get("current_screen")
	if battle == null or not battle.has_method("_finish_battle"):
		_fail("战斗场景未实例化，或缺少 _finish_battle()")
		_finish()
		return

	_assert_actor_counts(battle, 1, "第 1 关")

	battle.call("_finish_battle", true, "下一关烟雾测试通关")
	await _wait_for_scene(root, RESULT_SCENE_PATH)
	_assert_scene(root, RESULT_SCENE_PATH, "第 1 关通关后应进入结算页")

	if not CoreGameState.can_go_next_level():
		_fail("第 1 关通关后应允许进入下一关")

	CoreEventBus.next_level_requested.emit()
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "结算页点击下一关后应进入下一关战斗场景")
	if CoreGameState.current_level_id != 2:
		_fail("结算页点击下一关后，当前关卡应切到第 2 关，实际为 %d" % CoreGameState.current_level_id)

	var battle_l2: Node = root.get("current_screen")
	if battle_l2 != null and battle_l2.has_method("_finish_battle"):
		_assert_actor_counts(battle_l2, 2, "第 2 关")

	CoreEventBus.main_menu_requested.emit()
	await _wait_for_scene(root, "res://scenes/menu/menu_main_menu.tscn")

	CoreGameState.start_level(1)
	CoreGameState.last_result = {
		"success": true,
		"level_name": "城市试炼 01",
		"reason": "下一关烟雾测试通关",
		"reward_gold": 80,
		"base_reward_gold": 60,
		"time_bonus_gold": 20,
		"wrong_hit_penalty_gold": 0,
		"accuracy": 1.0,
		"hit_count": 3,
		"shot_count": 3,
		"wrong_hit_count": 0,
		"scan_used": 1,
		"time_extend_used": 0,
		"no_miss_rounds": 1,
		"elapsed_time": 12.0,
	}
	CoreGameState.unlocked_levels = maxi(CoreGameState.unlocked_levels, 2)
	CoreGameState.player_gold = maxi(CoreGameState.player_gold, 999)

	CoreEventBus.upgrade_requested.emit()
	await _wait_for_scene(root, UPGRADE_SCENE_PATH)
	_assert_scene(root, UPGRADE_SCENE_PATH, "进入升级页后应显示升级场景")

	CoreEventBus.next_level_requested.emit()
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "升级页点击下一关后应进入下一关战斗场景")
	if CoreGameState.current_level_id != 2:
		_fail("升级页点击下一关后，当前关卡应切到第 2 关，实际为 %d" % CoreGameState.current_level_id)

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("[NEXT_LEVEL_SMOKE] PASS")
		_write_result("PASS", [])
		smoke_finished.emit("PASS", [])
		_teardown()
		return

	for failure in _failures:
		print("[NEXT_LEVEL_SMOKE] FAIL: %s" % failure)
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


func _assert_actor_counts(battle: Node, level_id: int, level_label: String) -> void:
	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("%s缺少 battle_core，无法验证外星人数量" % level_label)
		return
	var level_config = battle_core.get("level_config")
	if level_config == null:
		_fail("%s缺少 level_config，无法验证外星人数量" % level_label)
		return
	var expected_targets: int = int(level_config.get("required_targets"))
	var expected_civilians: int = int(level_config.get("civilian_count"))
	var total_targets: int = int(battle_core.get("total_targets"))
	if total_targets != expected_targets:
		_fail("%s外星人数量不对，期望 %d，实际 %d" % [level_label, expected_targets, total_targets])
	
	var civilian_count := 0
	var alien_count := 0
	for actor in battle_core.get("active_actors"):
		if is_instance_valid(actor):
			if str(actor.get("actor_kind")) == "civilian":
				civilian_count += 1
			elif str(actor.get("actor_kind")) == "target":
				alien_count += 1
	if alien_count != expected_targets:
		_fail("%s实际生成的外星人数量不对，期望 %d，实际 %d" % [level_label, expected_targets, alien_count])
	if civilian_count != expected_civilians:
		_fail("%s平民数量不对，期望 %d，实际 %d" % [level_label, expected_civilians, civilian_count])


func _fail(message: String) -> void:
	_failures.append(message)


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://next_level_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 next_level_smoke_result.txt")
		return

	var time_str := Time.get_datetime_string_from_system(true, true)
	file.store_line("NEXT_LEVEL_SMOKE=%s" % status)
	file.store_line("TIMESTAMP=%s" % time_str)
	if not failures.is_empty():
		for failure in failures:
			file.store_line(str(failure))
