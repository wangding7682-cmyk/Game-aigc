extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
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


func _run() -> void:
	CoreGameState.reset_progress()
	CoreGameState.tutorial_completed = false
	CoreGameState.tutorial_step_index = 0

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

	CoreEventBus.level_requested.emit(1)
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "进入第 1 关应进入战斗场景")

	var battle: Node = root.get("current_screen")
	if battle == null:
		_fail("战斗场景未实例化，无法继续测试")
		_finish()
		return

	_assert_method(battle, "_finish_battle", "战斗场景缺少结束战斗能力")
	_assert_method(battle, "_on_fire_pressed", "战斗场景缺少开火入口")
	_assert_method(battle, "_debug_get_camera_motion_bounds", "战斗场景缺少相机调试边界接口")
	_assert_method(battle, "_debug_get_aim_world_coverage", "战斗场景缺少准星覆盖范围调试接口")
	_assert_method(battle, "_debug_step_edge_auto_pan", "战斗场景缺少边缘自动跟镜调试接口")
	_assert_method(battle, "_debug_is_weapon_ready", "战斗场景缺少武器状态调试接口")
	_assert_method(battle, "_debug_finish_post_shot_recover", "战斗场景缺少射后恢复调试接口")
	_assert_method(battle, "_debug_get_slowmo_state", "战斗场景缺少慢镜调试接口")
	_assert_method(battle, "_debug_finish_slowmo", "战斗场景缺少结束慢镜调试接口")
	_assert_method(battle, "_debug_get_killcam_state", "战斗场景缺少击杀回放调试接口")
	_assert_method(battle, "_debug_finish_killcam", "战斗场景缺少结束击杀回放调试接口")
	_assert_method(battle, "_debug_get_search_state", "战斗场景缺少搜索状态调试接口")
	_assert_method(battle, "_debug_get_identification_feedback_state", "战斗场景缺少识别反馈调试接口")
	_assert_method(battle, "_debug_shoot_next_target", "战斗场景缺少连击击杀调试接口")
	_assert_method(battle, "_debug_trigger_civilian_false_clue", "战斗场景缺少动态假线索调试接口")
	_assert_method(battle, "_debug_finish_misjudgment_review", "战斗场景缺少结束误判复盘调试接口")

	var aim_coverage: Dictionary = battle.call("_debug_get_aim_world_coverage")
	if float(aim_coverage.get("width", 0.0)) < 300.0 or float(aim_coverage.get("height", 0.0)) < 500.0:
		_fail("当前默认机位覆盖范围过小，无法在固定视角下完整搜索地图")

	var edge_pan: Dictionary = battle.call("_debug_step_edge_auto_pan", "right")
	var edge_delta: Vector2 = edge_pan.get("delta", Vector2.ZERO)
	if absf(edge_delta.x) > 0.01 or absf(edge_delta.y) > 0.01:
		_fail("新设计要求固定机位，准星贴近边缘时镜头不应再自动跟随")

	var tutorial_flow: Node = battle.get("tutorial_flow")
	if tutorial_flow == null:
		_fail("第 1 关首次进入应挂载教程引导面板（tutorial_flow == null）")
	else:
		if not tutorial_flow.has_method("show_step"):
			_fail("教程引导脚本缺少 show_step()，无法推进教程文案")
		if not tutorial_flow.has_method("show_blocked_action"):
			_fail("教程引导脚本缺少 show_blocked_action()，无法提示锁步原因")
		if not tutorial_flow.has_method("show_completed"):
			_fail("教程引导脚本缺少 show_completed()，无法展示完成态")

	var shot_before: int = int(battle.get("shot_count"))
	battle.call("_on_fire_pressed")
	await get_tree().process_frame
	var shot_after: int = int(battle.get("shot_count"))
	if shot_after != shot_before:
		_fail("教程第一步未完成前不应允许开火（shot_count 不应增加）")

	battle.call("_handle_camera_move_tutorial", Vector2(1.0, 0.0))
	await get_tree().process_frame
	battle.call("_debug_focus_tutorial_target")
	await get_tree().process_frame
	var search_state: Dictionary = battle.call("_debug_get_search_state")
	if str(search_state.get("hint", "")).find("可疑点") == -1:
		_fail("将可疑目标移入观察区后，应能看到可疑特征提示")
	shot_before = int(battle.get("shot_count"))
	battle.call("_on_fire_pressed")
	await get_tree().process_frame
	shot_after = int(battle.get("shot_count"))
	if shot_after != shot_before:
		_fail("锁定外星人后、放大之前不应允许直接开火")
	battle.call("_on_scan_pressed")
	await get_tree().process_frame
	search_state = battle.call("_debug_get_search_state")
	if not bool(search_state.get("has_locator", false)):
		_fail("扫描后应激活一条定位类搜索线索")
	battle.call("_zoom_focus_to_next_step")
	await get_tree().process_frame
	battle.set("hold_ratio", 0.7)
	battle.call("_try_progress_tutorial", &"aim_hold")
	await get_tree().process_frame
	var hits_before := int(battle.get("hit_count"))
	battle.call("_debug_shoot_primary_target")
	await get_tree().process_frame
	var hits_after := int(battle.get("hit_count"))
	if hits_after <= hits_before:
		_fail("第 1 关教程主目标应可被命中，但 hit_count 未增加")
	if int(battle.get("recognition_bonus_gold")) <= 0:
		_fail("正确识别并击杀外星人后，应获得识别奖励")
	var feedback_state: Dictionary = battle.call("_debug_get_identification_feedback_state")
	if int(feedback_state.get("combo_count", 0)) != 1:
		_fail("首次正确识别后，应进入 1 层识别连击")
	if bool(battle.call("_debug_is_weapon_ready")):
		_fail("开火命中后不应立刻允许连续射击，应进入后坐恢复阶段")
	var slowmo_state: Dictionary = battle.call("_debug_get_slowmo_state")
	if not bool(slowmo_state.get("active", false)):
		_fail("命中正确目标后应进入短暂慢镜反馈")
	var killcam_state: Dictionary = battle.call("_debug_get_killcam_state")
	if not bool(killcam_state.get("active", false)):
		_fail("击杀外星人后应触发短暂的跟弹击杀回放")
	battle.call("_debug_finish_post_shot_recover")
	battle.call("_debug_finish_slowmo")
	battle.call("_debug_finish_killcam")
	await get_tree().process_frame
	if not bool(battle.call("_debug_is_weapon_ready")):
		_fail("射后恢复结束后应重新允许进入下一轮搜索与瞄准")
	if bool(battle.get("scope_visible")):
		_fail("射后恢复完成后应退出瞄准状态，回到重新搜索阶段")
	if float(battle.get("current_zoom")) > 1.12:
		_fail("射后恢复完成后应回到默认倍率，而不是停留在放大瞄准态")
	var combo_bonus_before := int(battle.get("recognition_combo_bonus_gold"))
	battle.call("_debug_shoot_next_target")
	await get_tree().process_frame
	feedback_state = battle.call("_debug_get_identification_feedback_state")
	if int(feedback_state.get("combo_count", 0)) < 2:
		_fail("连续正确识别第二个外星人后，应累计更高连击层数")
	if int(battle.get("recognition_combo_bonus_gold")) <= combo_bonus_before:
		_fail("连续正确识别后，应获得递增的连击奖励")
	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("缺少 battle_core，无法验证第 1 关自动结算")
	else:
		if int(battle_core.get("total_targets")) != 2:
			_fail("第 1 关 total_targets 应为 2，而不是 %s" % str(battle_core.get("total_targets")))
		if int(battle_core.get("killed_targets")) < 2:
			_fail("连续击杀两个目标后，killed_targets 应至少为 2")
		battle.call("_debug_finish_post_shot_recover")
		battle.call("_debug_finish_slowmo")
		battle.call("_debug_finish_killcam")
		await get_tree().process_frame
		await get_tree().process_frame
		if not bool(battle_core.get("battle_closed")):
			_fail("第 1 关击杀第二个目标后应自动结束战斗（battle_closed 应为 true）")

	battle_core = battle.get("battle_core")
	if battle_core != null:
		var civilian_count := 0
		for actor in battle_core.get("active_actors"):
			if is_instance_valid(actor) and str(actor.get("actor_kind")) == "civilian":
				civilian_count += 1
		if civilian_count != 4:
			_fail("第 1 关当前 3D 战斗应生成 4 个平民角色，实际为 %d" % civilian_count)
	if int(battle.get("wrong_hit_count")) != 0:
		_fail("当前教程测试流程没有误伤平民，wrong_hit_count 应保持为 0")

	if not CoreGameState.tutorial_completed:
		_fail("按教程顺序完成后应标记 tutorial_completed = true")

	battle.call("_finish_battle", true, "自动测试通关")
	await _wait_for_scene(root, RESULT_SCENE_PATH)
	_assert_scene(root, RESULT_SCENE_PATH, "战斗结束后应进入结算页")

	var result_panel: Node = root.get("current_screen")
	if result_panel == null:
		_fail("结算页未实例化，无法继续测试")
		_finish()
		return

	PlatformService.cycle_rewarded_ad_mode()
	if result_panel.has_method("_on_rewarded_ad_pressed"):
		var state_fail = result_panel.call("_on_rewarded_ad_pressed")
		if state_fail != null:
			await state_fail
		await get_tree().process_frame

	if bool(CoreGameState.last_result.get("rewarded_ad_claimed", false)):
		_fail("广告失败时不应标记 rewarded_ad_claimed = true")

	PlatformService.cycle_rewarded_ad_mode()
	if result_panel.has_method("_on_rewarded_ad_pressed"):
		var state_success = result_panel.call("_on_rewarded_ad_pressed")
		if state_success != null:
			await state_success
		await get_tree().process_frame
	else:
		_fail("结算页缺少 _on_rewarded_ad_pressed()，无法验证平台 mock 激励视频")

	if not bool(CoreGameState.last_result.get("rewarded_ad_claimed", false)):
		_fail("广告成功后应标记 rewarded_ad_claimed = true")

	CoreGameState.player_gold = maxi(CoreGameState.player_gold, 999)
	CoreEventBus.upgrade_requested.emit()
	await _wait_for_scene(root, UPGRADE_SCENE_PATH)
	_assert_scene(root, UPGRADE_SCENE_PATH, "结算页进入升级后应打开升级页")

	var upgrade_panel: Node = root.get("current_screen")
	var before_level := CoreGameState.get_upgrade_level("stability")
	if upgrade_panel != null and upgrade_panel.has_method("_try_upgrade"):
		upgrade_panel.call("_try_upgrade", "stability")
		await get_tree().process_frame
	var after_level := CoreGameState.get_upgrade_level("stability")
	if after_level <= before_level:
		_fail("升级页点击升级后稳定性等级应提升（before=%d after=%d）" % [before_level, after_level])

	CoreEventBus.main_menu_requested.emit()
	await _wait_for_scene(root, MENU_SCENE_PATH)
	_assert_scene(root, MENU_SCENE_PATH, "从升级页返回主页应回到主菜单")

	CoreEventBus.level_requested.emit(2)
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "进入第 2 关应进入战斗场景")

	var fail_battle: Node = root.get("current_screen")
	if fail_battle == null:
		_fail("第 2 关战斗场景未实例化，无法验证失败埋点")
	else:
		if fail_battle.has_method("_finish_battle"):
			fail_battle.call("_finish_battle", false, "自动测试失败")
			await _wait_for_scene(root, RESULT_SCENE_PATH)
		else:
			_fail("第 2 关战斗场景缺少 _finish_battle()，无法验证失败埋点")

	_assert_scene(root, RESULT_SCENE_PATH, "失败结算后应进入结算页")
	CoreEventBus.main_menu_requested.emit()
	await _wait_for_scene(root, MENU_SCENE_PATH)
	_assert_scene(root, MENU_SCENE_PATH, "失败结算返回主页后应回到主菜单")

	var log_path := PlatformService.get_analytics_log_path()
	if not FileAccess.file_exists(log_path):
		_fail("埋点日志未落盘：%s 不存在" % log_path)
	else:
		var analytics_text := FileAccess.get_file_as_string(log_path)
		_assert_contains(analytics_text, "\"event\":\"tutorial_started\"", "埋点日志应包含 tutorial_started")
		_assert_contains(analytics_text, "\"event\":\"tutorial_completed\"", "埋点日志应包含 tutorial_completed")
		_assert_contains(analytics_text, "\"event\":\"first_hit_recorded\"", "埋点日志应包含 first_hit_recorded")
		_assert_contains(analytics_text, "\"event\":\"level_checkpoint\"", "埋点日志应包含 level_checkpoint")
		_assert_contains(analytics_text, "\"event\":\"battle_finished\"", "埋点日志应包含 battle_finished")
		_assert_contains(analytics_text, "\"event\":\"first_failure_recorded\"", "埋点日志应包含 first_failure_recorded")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("[INTEGRATION_SMOKE] PASS")
		_write_result("PASS", [])
		smoke_finished.emit("PASS", [])
		_teardown()
		return

	for failure in _failures:
		print("[INTEGRATION_SMOKE] FAIL: %s" % failure)
	_write_result("FAIL", _failures)
	smoke_finished.emit("FAIL", _failures.duplicate())
	_teardown()


func _teardown() -> void:
	if _is_embedded:
		if not skip_return_navigation:
			CoreEventBus.test_center_requested.emit()
			await get_tree().process_frame
	elif auto_quit:
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
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


func _assert_method(target: Object, method_name: String, message: String) -> void:
	if not target.has_method(method_name):
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _assert_contains(text: String, expected: String, message: String) -> void:
	if text.find(expected) == -1:
		_fail("%s：缺少 %s" % [message, expected])


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://integration_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 integration_smoke_result.txt")
		return

	var time_str := Time.get_datetime_string_from_system(true, true)
	file.store_line("INTEGRATION_SMOKE=%s" % status)
	file.store_line("TIMESTAMP=%s" % time_str)
	if not failures.is_empty():
		for failure in failures:
			file.store_line(str(failure))
