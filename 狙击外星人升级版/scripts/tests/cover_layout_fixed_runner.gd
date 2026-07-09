extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"

const EXPECTED_COVER_COUNTS := {
	2: 12,
	3: 15,
}

const REQUIRED_STYLES := [
	"wall_corner",
	"street_lamp",
	"parked_van",
	"billboard",
]

var _failures: Array[String] = []
var _reports: Array[Dictionary] = []


func _ready() -> void:
	call_deferred("_start")


func _start() -> void:
	await _run()


func _run() -> void:
	CoreGameState.reset_progress()
	CoreGameState.tutorial_completed = true
	var root: Node = ROOT_SCENE.instantiate()
	add_child(root)
	await _wait_for_scene(root, MENU_SCENE_PATH)

	for level_id in EXPECTED_COVER_COUNTS.keys():
		CoreGameState.start_level(int(level_id))
		CoreEventBus.level_requested.emit(level_id)
		await _wait_for_scene(root, BATTLE_SCENE_PATH)
		await get_tree().process_frame
		await get_tree().process_frame

		var battle: Node = root.get("current_screen")
		if battle == null:
			_fail("关卡 `%d` 未能进入战斗场景" % level_id)
			continue
		_reports.append(_inspect_cover_layout(battle, int(level_id)))

		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, MENU_SCENE_PATH)

	_finish()


func _inspect_cover_layout(battle: Node, level_id: int) -> Dictionary:
	var report: Dictionary = {
		"level_id": level_id,
		"status": "unknown",
	}
	var covers: Array = battle.get("cover_obstacles_3d")
	report["cover_count"] = covers.size()
	var expected_count: int = int(EXPECTED_COVER_COUNTS.get(level_id, 0))
	if covers.size() != expected_count:
		_fail("关卡 `%d` 的固定障碍物数量不对，期望 `%d`，实际 `%d`" % [level_id, expected_count, covers.size()])
		report["status"] = "count_mismatch"
		return report

	var style_counts: Dictionary = {}
	for cover in covers:
		if cover == null or not is_instance_valid(cover):
			continue
		var style_id: String = str(cover.get("style_id"))
		style_counts[style_id] = int(style_counts.get(style_id, 0)) + 1
	report["style_counts"] = style_counts

	for style_id in REQUIRED_STYLES:
		if int(style_counts.get(style_id, 0)) <= 0:
			_fail("关卡 `%d` 缺少固定掩体类型 `%s`" % [level_id, style_id])
			report["status"] = "missing_style"
			return report

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
	var file := FileAccess.open("user://cover_layout_fixed_result.txt", FileAccess.WRITE)
	if file != null:
		var status: String = "PASS" if _failures.is_empty() else "FAIL"
		file.store_line("COVER_LAYOUT_FIXED=%s" % status)
		for report in _reports:
			file.store_line(JSON.stringify(report))
		if not _failures.is_empty():
			file.store_line("FAILURES=%s" % JSON.stringify(_failures))
		file.close()
	get_tree().quit(0)
