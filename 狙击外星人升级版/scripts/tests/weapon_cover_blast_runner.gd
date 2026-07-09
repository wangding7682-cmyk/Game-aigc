extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"
const COVER_SCRIPT = preload("res://scripts/pve/pve_cover_obstacle_3d.gd")

const WEAPON_TIERS := {
	"default_sniper": "light",
	"precision_sniper": "medium",
	"auto_sniper": "light",
	"plasma_sniper": "heavy",
}

var _failures: Array[String] = []
var _reports: Array[Dictionary] = []


func _ready() -> void:
	call_deferred("_start")


func _start() -> void:
	await _run()


func _run() -> void:
	CoreGameState.reset_progress()
	CoreGameState.tutorial_completed = true
	for weapon_id in WEAPON_TIERS.keys():
		if not WeaponManager.is_weapon_unlocked(weapon_id):
			WeaponManager.unlock_weapon(weapon_id)

	var root: Node = ROOT_SCENE.instantiate()
	add_child(root)
	await _wait_for_scene(root, MENU_SCENE_PATH)

	for weapon_id in WEAPON_TIERS.keys():
		var expected_tier: String = str(WEAPON_TIERS.get(weapon_id, "medium"))
		if not WeaponManager.equip_weapon(weapon_id):
			_fail("武器 `%s` 装备失败" % weapon_id)
			continue

		CoreEventBus.level_requested.emit(1)
		await _wait_for_scene(root, BATTLE_SCENE_PATH)
		await get_tree().process_frame
		await get_tree().process_frame

		var battle: Node = root.get("current_screen")
		if battle == null:
			_fail("武器 `%s` 进入战斗失败" % weapon_id)
			continue

		var report: Dictionary = await _inspect_weapon_cover_blast(battle, weapon_id, expected_tier)
		_reports.append(report)

		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, MENU_SCENE_PATH)

	_finish()


func _inspect_weapon_cover_blast(battle: Node, weapon_id: String, expected_tier: String) -> Dictionary:
	var report: Dictionary = {
		"weapon_id": weapon_id,
		"expected_tier": expected_tier,
		"status": "unknown",
	}

	var battle_mode: Node = battle.get("battle_mode")
	if battle_mode == null:
		_fail("武器 `%s` 缺少 battle_mode" % weapon_id)
		report["status"] = "missing_battle_mode"
		return report

	var resolved_tier: String = ""
	if battle_mode.has_method("debug_get_cover_blast_tier"):
		resolved_tier = str(battle_mode.call("debug_get_cover_blast_tier"))
	report["resolved_tier"] = resolved_tier
	if resolved_tier != expected_tier:
		_fail("武器 `%s` 的爆炸档位错误，期望 `%s`，实际 `%s`" % [weapon_id, expected_tier, resolved_tier])
		report["status"] = "tier_mismatch"
		return report

	var van = COVER_SCRIPT.new()
	if not (van is Node3D):
		_fail("武器 `%s` 的测试掩体实例化失败" % weapon_id)
		report["status"] = "cover_instance_failed"
		return report
	var van_cover: Node3D = van as Node3D
	battle.add_child(van_cover)
	van_cover.position = Vector3(0.0, 0.0, -4.0)
	if van_cover.has_method("setup"):
		van_cover.call("setup", Vector3(2.5, 1.9, 1.2), "parked_van")
	await get_tree().process_frame

	if van_cover.has_method("apply_impact_feedback"):
		van_cover.call("apply_impact_feedback", van_cover.global_position + Vector3(0.0, 1.0, 0.5), Vector3.BACK, "metal", resolved_tier)
	await get_tree().process_frame

	if van_cover.has_method("get_visual_asset_state"):
		var visual: Dictionary = van_cover.call("get_visual_asset_state")
		report["visual"] = visual
		if str(visual.get("last_blast_tier", "")) != resolved_tier:
			_fail("武器 `%s` 驱动 `parked_van` 后未记录正确档位" % weapon_id)
		if int(visual.get("last_blast_detached_spawn_count", 0)) <= 0:
			_fail("武器 `%s` 驱动 `parked_van` 后未生成弹开件" % weapon_id)
		if int(visual.get("blast_reaction_count", 0)) <= 0:
			_fail("武器 `%s` 驱动 `parked_van` 后未记录爆炸响应" % weapon_id)

	van_cover.queue_free()
	report["status"] = "ok"
	return report


func _wait_for_scene(root: Node, expected_path: String, max_frames: int = 180) -> void:
	for _i in range(max_frames):
		await get_tree().process_frame
		var scene_ready: bool = str(root.get("current_scene_path")) == expected_path and root.get("current_screen") != null
		var transition_done: bool = true
		if root.has_method("_debug_is_transitioning"):
			transition_done = not bool(root.call("_debug_is_transitioning"))
		if scene_ready and transition_done:
			return
	_fail("等待场景切换超时：%s" % expected_path)


func _fail(message: String) -> void:
	push_warning(message)
	_failures.append(message)


func _finish() -> void:
	var file := FileAccess.open("user://weapon_cover_blast_result.txt", FileAccess.WRITE)
	if file != null:
		var status: String = "PASS" if _failures.is_empty() else "FAIL"
		file.store_line("WEAPON_COVER_BLAST=%s" % status)
		for report in _reports:
			file.store_line(JSON.stringify(report))
		if not _failures.is_empty():
			file.store_line("FAILURES=%s" % JSON.stringify(_failures))
		file.close()
	get_tree().quit(0)
