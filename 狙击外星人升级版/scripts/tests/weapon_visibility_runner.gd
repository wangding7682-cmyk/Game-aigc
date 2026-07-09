extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"

const WEAPON_IDS := [
	"default_sniper",
	"precision_sniper",
	"auto_sniper",
	"plasma_sniper",
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
	for weapon_id in WEAPON_IDS:
		if not WeaponManager.is_weapon_unlocked(weapon_id):
			WeaponManager.unlock_weapon(weapon_id)
	var root := ROOT_SCENE.instantiate()
	add_child(root)
	await _wait_for_scene(root, MENU_SCENE_PATH)

	for weapon_id in WEAPON_IDS:
		if not WeaponManager.equip_weapon(weapon_id):
			_fail("武器 `%s` 装备失败" % weapon_id)
			continue
		CoreEventBus.level_requested.emit(2)
		await _wait_for_scene(root, BATTLE_SCENE_PATH)
		await get_tree().process_frame
		await get_tree().process_frame
		var battle: Node = root.get("current_screen")
		if battle == null:
			_fail("武器 `%s` 进入战斗失败" % weapon_id)
			continue
		var report := _inspect_weapon_visibility(battle, weapon_id)
		_reports.append(report)
		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, MENU_SCENE_PATH)

	_finish()


func _inspect_weapon_visibility(battle: Node, weapon_id: String) -> Dictionary:
	var report := {
		"weapon_id": weapon_id,
		"status": "unknown",
	}
	var weapon_renderer: Node = battle.get("weapon_renderer")
	if weapon_renderer == null:
		_fail("武器 `%s` 缺少 weapon_renderer" % weapon_id)
		report["status"] = "missing_renderer"
		return report

	var mount_state: Dictionary = {}
	if weapon_renderer.has_method("get_mount_state"):
		mount_state = weapon_renderer.call("get_mount_state")
	report["mount_state"] = mount_state

	var aim_camera: Camera3D = battle.get("aim_camera")
	if aim_camera == null:
		_fail("武器 `%s` 缺少 AimCamera" % weapon_id)
		report["status"] = "missing_camera"
		return report

	var mesh_nodes := _collect_meshes(weapon_renderer)
	report["mesh_count"] = mesh_nodes.size()
	if mesh_nodes.is_empty():
		_fail("武器 `%s` 当前没有可见网格节点" % weapon_id)
		report["status"] = "no_mesh"
		return report

	var visible_points := _collect_visible_points(mesh_nodes)
	report["visible_point_count"] = visible_points.size()
	if visible_points.is_empty():
		_fail("武器 `%s` 无法计算可见性点位" % weapon_id)
		report["status"] = "no_points"
		return report

	var viewport_size: Vector2 = Vector2.ZERO
	if aim_camera.get_viewport() != null:
		viewport_size = aim_camera.get_viewport().get_visible_rect().size
	report["viewport_size"] = viewport_size

	var on_screen_count := 0
	var in_front_count := 0
	var sample_points: Array[Dictionary] = []
	for point in visible_points:
		var behind := aim_camera.is_position_behind(point)
		if not behind:
			in_front_count += 1
		var screen_point := aim_camera.unproject_position(point)
		var inside := not behind and screen_point.x >= -80.0 and screen_point.y >= -80.0 and screen_point.x <= viewport_size.x + 80.0 and screen_point.y <= viewport_size.y + 80.0
		if inside:
			on_screen_count += 1
		if sample_points.size() < 6:
			sample_points.append({
				"world": point,
				"screen": screen_point,
				"behind": behind,
				"inside": inside,
			})
	report["in_front_count"] = in_front_count
	report["on_screen_count"] = on_screen_count
	report["sample_points"] = sample_points
	report["status"] = "visible" if on_screen_count > 0 else "offscreen"

	if in_front_count == 0:
		_fail("武器 `%s` 的所有采样点都在相机后方" % weapon_id)
	elif on_screen_count == 0:
		_fail("武器 `%s` 当前仍未落入战斗视口范围" % weapon_id)
	return report


func _collect_meshes(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in _collect_nodes(root):
		if child is MeshInstance3D and child.visible:
			var mesh_node := child as MeshInstance3D
			if mesh_node.mesh != null and not String(mesh_node.name).contains("Overlay") and not String(mesh_node.name).contains("MuzzleFlash"):
				meshes.append(mesh_node)
	return meshes


func _collect_visible_points(mesh_nodes: Array[MeshInstance3D]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for mesh_node in mesh_nodes:
		var aabb := mesh_node.get_aabb()
		var center := mesh_node.to_global(aabb.position + aabb.size * 0.5)
		result.append(center)
		for x_flag in [0.0, 1.0]:
			for y_flag in [0.0, 1.0]:
				for z_flag in [0.0, 1.0]:
					var corner := aabb.position + Vector3(aabb.size.x * x_flag, aabb.size.y * y_flag, aabb.size.z * z_flag)
					result.append(mesh_node.to_global(corner))
	return result


func _collect_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child in root.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes


func _wait_for_scene(root: Node, expected_path: String, max_frames: int = 180) -> void:
	for _i in range(max_frames):
		await get_tree().process_frame
		var scene_ready := str(root.get("current_scene_path")) == expected_path and root.get("current_screen") != null
		var transition_done := true
		if root.has_method("_debug_is_transitioning"):
			transition_done = not bool(root.call("_debug_is_transitioning"))
		if scene_ready and transition_done:
			return
	_fail("等待场景切换超时：%s" % expected_path)


func _fail(message: String) -> void:
	push_warning(message)
	_failures.append(message)


func _finish() -> void:
	var file := FileAccess.open("user://weapon_visibility_result.txt", FileAccess.WRITE)
	if file != null:
		var status := "PASS" if _failures.is_empty() else "FAIL"
		file.store_line("WEAPON_VISIBILITY=%s" % status)
		for report in _reports:
			file.store_line(JSON.stringify(report))
		if not _failures.is_empty():
			file.store_line("FAILURES=%s" % JSON.stringify(_failures))
		file.close()
	get_tree().quit(0)
