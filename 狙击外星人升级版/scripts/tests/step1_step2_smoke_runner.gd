extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"

signal smoke_finished(status: String, failures: Array)

var _failures: Array[String] = []
var _passes: Array[String] = []
var auto_quit := false
var _is_embedded := false


func _ready() -> void:
	call_deferred("_start_test")


func _start_test() -> void:
	await _run()


func _find_existing_root() -> Node:
	for child in get_tree().root.get_children():
		if child.get_script() and str(child.get_script().resource_path).find("core_game_root.gd") != -1:
			return child
		var current: Node = child
		while current != null:
			if current.get_script() and str(current.get_script().resource_path).find("core_game_root.gd") != -1:
				return current
			current = current.get_parent()
	var current: Node = self
	while current != null:
		if current.get_script() and str(current.get_script().resource_path).find("core_game_root.gd") != -1:
			return current
		current = current.get_parent()
	return null


func _run() -> void:
	print("[STEP1-2] ========== Step 1 + Step 2 运行测试开始 ==========")

	CoreGameState.reset_progress()
	CoreGameState.tutorial_completed = true

	var root: Node = _find_existing_root()
	if root != null:
		_is_embedded = true
		CoreEventBus.main_menu_requested.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		root = ROOT_SCENE.instantiate()
		add_child(root)
		await get_tree().process_frame
		await get_tree().process_frame

	_assert_scene(root, MENU_SCENE_PATH, "启动后应进入主菜单")

	CoreEventBus.level_requested.emit(2)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var battle: Node = root.get("current_screen")
	if battle == null:
		_fail("T1-01: 战斗场景未实例化")
		_finish()
		return

	if battle.name == "BattleRoot" or battle.has_method("_debug_is_weapon_ready"):
		_pass("T1-01: 3D 主战斗场景可进入")
	else:
		_fail("T1-01: 当前场景不是战斗场景 (实际: %s)" % battle.name)
		_finish()
		return

	_test_t1_02_root_hierarchy(battle)
	_test_t1_03_default_camera(battle)
	await _test_t1_04_zoom_stability(battle)
	await _test_t1_05_hold_stabilize(battle)
	_test_t1_06_hud_visibility(battle)
	_test_t1_07_actor_readability(battle)
	_test_t2_01_street_structure(battle)
	_test_t2_02_spawn_band(battle)
	_test_t2_03_cover_types(battle)
	_test_t2_04_cover_blocks_ray(battle)
	_test_t2_05_spawn_no_clip(battle)
	_test_t2_06_cover_recognition(battle)
	_test_t2_07_light_cover_interference(battle)

	_finish()


func _test_t1_02_root_hierarchy(battle: Node) -> void:
	print("[STEP1-2] T1-02: 检查根层级完整性...")

	var world_root = battle.get("world_root")
	var level_root = battle.get("level_root")
	var actor_root = battle.get("actor_root")
	var decal_root = battle.get("decal_root")
	var fx_root = battle.get("fx_root")
	var ui_root = battle.get_node_or_null("UiRoot")

	var missing: Array[String] = []
	if world_root == null:
		missing.append("WorldRoot")
	if level_root == null:
		missing.append("LevelRoot")
	if actor_root == null:
		missing.append("ActorRoot")
	if decal_root == null:
		missing.append("DecalRoot")
	if fx_root == null:
		missing.append("FxRoot")
	if ui_root == null:
		missing.append("UiRoot")

	if not missing.is_empty():
		_fail("T1-02: 缺少根层级节点: %s" % ", ".join(missing))
		return

	var cover_in_level := 0
	var cover_in_actor := 0
	if level_root != null:
		for child in level_root.get_children():
			if child.is_class("StaticBody3D") or (child.has_method("set_scan_fade_ratio")):
				cover_in_level += 1
	if actor_root != null:
		for child in actor_root.get_children():
			if child.is_class("StaticBody3D") or (child.has_method("set_scan_fade_ratio")):
				cover_in_actor += 1

	if cover_in_actor > 0:
		_fail("T1-02: 有 %d 个掩体错误挂在 ActorRoot 下，应在 LevelRoot" % cover_in_actor)
		return

	_pass("T1-02: 6 个核心层级完整，掩体挂在 LevelRoot (%d 个)" % cover_in_level)


func _test_t1_03_default_camera(battle: Node) -> void:
	print("[STEP1-2] T1-03: 检查默认镜头构图...")

	var aim_camera = battle.get_node_or_null("AimCamera")
	if aim_camera == null:
		_fail("T1-03: 缺少 AimCamera")
		return

	var cam_pos: Vector3 = aim_camera.position
	var cam_fov: float = aim_camera.fov

	var height_ok := cam_pos.y > 3.0 and cam_pos.y < 12.0
	var distance_ok := cam_pos.z > 5.0 and cam_pos.z < 20.0
	var fov_ok := cam_fov > 40.0 and cam_fov < 80.0

	if not height_ok:
		_fail("T1-03: 相机高度异常 (y=%.2f)，预期 3-12 范围" % cam_pos.y)
		return
	if not distance_ok:
		_fail("T1-03: 相机距离异常 (z=%.2f)，预期 5-20 范围" % cam_pos.z)
		return
	if not fov_ok:
		_fail("T1-03: 相机 FOV 异常 (%.2f)，预期 40-80 范围" % cam_fov)
		return

	var coverage: Dictionary = battle.call("_debug_get_aim_world_coverage")
	var _center: Vector3 = coverage.get("center", Vector3.ZERO)
	var top_left: Vector3 = coverage.get("top_left", Vector3.ZERO)
	var bottom_right: Vector3 = coverage.get("bottom_right", Vector3.ZERO)

	var coverage_width := absf(bottom_right.x - top_left.x)
	var coverage_depth := absf(top_left.z - bottom_right.z)

	if coverage_width < 8.0:
		_fail("T1-03: 默认视角水平覆盖不足 (%.2f 单位)，应能覆盖主要道路区域" % coverage_width)
		return
	if coverage_depth < 6.0:
		_fail("T1-03: 默认视角纵深覆盖不足 (%.2f 单位)，应能分辨近中远景" % coverage_depth)
		return

	_pass("T1-03: 默认镜头构图正常 (高度=%.2f, 距离=%.2f, FOV=%.2f, 覆盖宽=%.2f, 深=%.2f)" % [
		cam_pos.y, cam_pos.z, cam_fov, coverage_width, coverage_depth
	])


func _test_t1_04_zoom_stability(battle: Node) -> void:
	print("[STEP1-2] T1-04: 检查连续缩放稳定性...")

	var camera_controller = battle.get("camera_controller")
	if camera_controller == null:
		_fail("T1-04: 缺少 camera_controller")
		return

	var aim_camera = battle.get_node_or_null("AimCamera")
	if aim_camera == null:
		_fail("T1-04: 缺少 AimCamera")
		return

	var aim_screen_before: Vector2 = camera_controller.aim_screen_position
	var anchor_world_before: Vector3 = _ray_to_ground_3d(aim_camera, aim_screen_before)

	for i in range(10):
		camera_controller.adjust_zoom_at_screen(aim_screen_before, 0.1)
		await get_tree().process_frame

	for i in range(10):
		camera_controller.adjust_zoom_at_screen(aim_screen_before, -0.1)
		await get_tree().process_frame

	var anchor_world_after: Vector3 = _ray_to_ground_3d(aim_camera, aim_screen_before)

	var drift_x := absf(anchor_world_after.x - anchor_world_before.x)
	var drift_z := absf(anchor_world_after.z - anchor_world_before.z)

	if drift_x > 0.5 or drift_z > 0.5:
		_fail("T1-04: 缩放后锚点漂移过大 (dx=%.3f, dz=%.3f)" % [drift_x, drift_z])
		return

	_pass("T1-04: 连续缩放稳定 (漂移 dx=%.3f, dz=%.3f)" % [drift_x, drift_z])


func _ray_to_ground_3d(cam: Camera3D, screen_pos: Vector2) -> Vector3:
	var origin := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return origin
	var t := (0.0 - origin.y) / dir.y
	return origin + dir * t


func _test_t1_05_hold_stabilize(battle: Node) -> void:
	print("[STEP1-2] T1-05: 检查屏息稳定效果...")

	if not battle.has_method("_debug_is_weapon_ready"):
		_fail("T1-05: 缺少武器就绪状态接口")
		return

	var weapon_ready: bool = battle.call("_debug_is_weapon_ready")
	if not weapon_ready:
		battle.call("_debug_finish_post_shot_recover")
		battle.call("_debug_finish_slowmo")
		battle.call("_debug_finish_killcam")
		battle.call("_debug_finish_misjudgment_review")
		await get_tree().process_frame

	var camera_controller = battle.get("camera_controller")
	if camera_controller == null:
		_fail("T1-05: 缺少 camera_controller")
		return

	var aim_camera = battle.get_node_or_null("AimCamera")
	if aim_camera == null:
		_fail("T1-05: 缺少 AimCamera")
		return

	var vp_center: Vector2 = aim_camera.get_viewport().get_visible_rect().size * 0.5

	camera_controller.set_zoom(2.0)
	camera_controller.set_camera_locked(false)
	battle.set("hold_ratio", 0.0)
	camera_controller.set_base_aim_screen_position(vp_center)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var sway_before: float = await _sample_sway_magnitude(battle, 30)

	camera_controller.set_camera_locked(true)
	battle.set("hold_ratio", 1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var sway_after: float = await _sample_sway_magnitude(battle, 30)

	if sway_after >= sway_before * 0.9:
		_fail("T1-05: 屏息后抖动未明显减弱 (前=%.2f, 后=%.2f)" % [sway_before, sway_after])
		return

	_pass("T1-05: 屏息稳定有效 (抖动从 %.2f 降至 %.2f, 减弱 %.1f%%)" % [
		sway_before, sway_after, (1.0 - sway_after / sway_before) * 100.0
	])


func _sample_sway_magnitude(battle: Node, frames: int) -> float:
	var camera_controller = battle.get("camera_controller")
	var positions: Array[Vector2] = []
	for i in range(frames):
		var offset: Vector2 = camera_controller.breathing_aim_offset
		positions.append(offset)
		await get_tree().process_frame

	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for pos in positions:
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_y = minf(min_y, pos.y)
		max_y = maxf(max_y, pos.y)

	return maxf(max_x - min_x, max_y - min_y)


func _test_t1_06_hud_visibility(battle: Node) -> void:
	print("[STEP1-2] T1-06: 检查 HUD 不挡主识别区...")

	var ui_root = battle.get_node_or_null("UiRoot")
	if ui_root == null:
		_fail("T1-06: 缺少 UiRoot")
		return

	var hud_controller = battle.get("hud_controller")
	if hud_controller == null:
		_fail("T1-06: 缺少 hud_controller")
		return

	var hud = battle.get("hud")
	if hud == null:
		_fail("T1-06: 缺少 hud 实例")
		return

	var vp_size: Vector2 = get_tree().root.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(1280, 720)

	var top_safe_ratio := 0.15
	var bottom_safe_ratio := 0.25
	var center_area_height := vp_size.y * (1.0 - top_safe_ratio - bottom_safe_ratio)

	if center_area_height < 300:
		_fail("T1-06: 中央瞄准区域高度不足 (%.0f px)，HUD 可能遮挡过多" % center_area_height)
		return

	_pass("T1-06: HUD 布局合理，中央识别区约 %.0f px 高 (占屏 %.1f%%)" % [
		center_area_height, center_area_height / vp_size.y * 100.0
	])


func _test_t1_07_actor_readability(battle: Node) -> void:
	print("[STEP1-2] T1-07: 检查近中远景角色可读性...")

	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("T1-07: 缺少 battle_core")
		return

	var active_actors: Array = battle_core.get("active_actors")
	if active_actors.is_empty():
		_fail("T1-07: 没有活动角色，无法测试可读性")
		return

	var target_count := 0
	var civilian_count := 0
	for actor in active_actors:
		if is_instance_valid(actor):
			if actor.actor_kind == "target":
				target_count += 1
			elif actor.actor_kind == "civilian":
				civilian_count += 1

	if target_count == 0:
		_fail("T1-07: 没有目标角色，无法验证外星人可读性")
		return
	if civilian_count == 0:
		_fail("T1-07: 没有平民角色，无法验证平民辨识度")
		return

	var near_actors: Array = []
	var mid_actors: Array = []
	var far_actors: Array = []

	var cam: Camera3D = battle.get_node_or_null("AimCamera")
	if cam == null:
		_fail("T1-07: 缺少相机")
		return

	for actor in active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue
		var dist: float = cam.global_position.distance_to(actor.global_position)
		if dist < 8.0:
			near_actors.append(actor)
		elif dist < 14.0:
			mid_actors.append(actor)
		else:
			far_actors.append(actor)

	_pass("T1-07: 角色分布正常 - 近景:%d, 中景:%d, 远景:%d, 目标:%d, 平民:%d" % [
		near_actors.size(), mid_actors.size(), far_actors.size(), target_count, civilian_count
	])


func _test_t2_01_street_structure(battle: Node) -> void:
	print("[STEP1-2] T2-01: 检查基础街区结构...")

	var level_root: Node3D = battle.get("level_root")
	if level_root == null:
		_fail("T2-01: 缺少 LevelRoot")
		return

	var has_street := false
	var has_lane := false
	var has_sidewalk := 0
	var has_backdrop := 0

	for child in level_root.get_children():
		if child.is_class("MeshInstance3D"):
			var child_name: String = child.name
			if child_name.find("StreetBase") != -1:
				has_street = true
			elif child_name.find("LaneStrip") != -1:
				has_lane = true
			elif child_name.find("Sidewalk") != -1:
				has_sidewalk += 1
			elif child_name.find("Backdrop") != -1:
				has_backdrop += 1

	if not has_street:
		_fail("T2-01: 缺少地面 (StreetBase)")
		return
	if not has_lane:
		_fail("T2-01: 缺少车道线 (LaneStrip)")
		return
	if has_sidewalk < 2:
		_fail("T2-01: 缺少人行道 (应有左右两侧，实际 %d 个)" % has_sidewalk)
		return
	if has_backdrop < 2:
		_fail("T2-01: 缺少背板 (应有左右两侧，实际 %d 个)" % has_backdrop)
		return

	_pass("T2-01: 基础街区结构完整 - 地面+车道线+人行道(%d)+背板(%d)" % [has_sidewalk, has_backdrop])


func _test_t2_02_spawn_band(battle: Node) -> void:
	print("[STEP1-2] T2-02: 检查刷点可读带...")

	var level_root: Node3D = battle.get("level_root")
	if level_root == null:
		_fail("T2-02: 缺少 LevelRoot")
		return

	var spawn_band = level_root.get_node_or_null("SpawnReadableBand")
	if spawn_band == null:
		_fail("T2-02: 缺少刷点可读带 (SpawnReadableBand)")
		return

	var band_mesh = spawn_band.mesh
	if band_mesh == null:
		_fail("T2-02: 刷点可读带没有网格")
		return

	var size: Vector3 = Vector3.ZERO
	if band_mesh is BoxMesh:
		size = (band_mesh as BoxMesh).size

	if size.x < 10.0 or size.z < 5.0:
		_fail("T2-02: 刷点可读带尺寸过小 (%.2f x %.2f)，不足以标示生成区" % [size.x, size.z])
		return

	_pass("T2-02: 刷点可读带正常 (尺寸 %.2f x %.2f)" % [size.x, size.z])


func _test_t2_03_cover_types(battle: Node) -> void:
	print("[STEP1-2] T2-03: 检查四类掩体生成...")

	var level_root: Node3D = battle.get("level_root")
	if level_root == null:
		_fail("T2-03: 缺少 LevelRoot")
		return

	var cover_obstacles: Array = battle.get("cover_obstacles_3d")
	if cover_obstacles == null or cover_obstacles.is_empty():
		_fail("T2-03: 没有掩体对象")
		return

	var styles: Dictionary = {}
	for obstacle in cover_obstacles:
		if is_instance_valid(obstacle):
			var style: String = obstacle.style_id
			styles[style] = styles.get(style, 0) + 1

	var required_styles: Array[String] = ["wall_corner", "street_lamp", "parked_van", "billboard"]
	var missing_styles: Array[String] = []
	for style in required_styles:
		if not styles.has(style):
			missing_styles.append(style)

	if not missing_styles.is_empty():
		_fail("T2-03: 缺少掩体类型: %s (当前有: %s)" % [", ".join(missing_styles), JSON.stringify(styles)])
		return

	_pass("T2-03: 四类掩体齐全 - %s" % JSON.stringify(styles))


func _test_t2_04_cover_blocks_ray(battle: Node) -> void:
	print("[STEP1-2] T2-04: 检查掩体挡弹...")

	var cover_obstacles: Array = battle.get("cover_obstacles_3d")
	if cover_obstacles.is_empty():
		_fail("T2-04: 没有掩体可测试")
		return

	var cam: Camera3D = battle.get_node_or_null("AimCamera")
	if cam == null:
		_fail("T2-04: 缺少相机")
		return

	var world_root: Node3D = battle.get("world_root")
	if world_root == null:
		_fail("T2-04: 缺少 world_root")
		return

	var world_3d: World3D = world_root.get_world_3d()
	if world_3d == null:
		_fail("T2-04: 无法获取 World3D")
		return

	var blocked_count := 0
	var tested_count := 0

	for obstacle in cover_obstacles:
		if not is_instance_valid(obstacle):
			continue

		var obstacle_pos: Vector3 = obstacle.global_position
		var cam_pos: Vector3 = cam.global_position

		var to_obstacle: Vector3 = obstacle_pos - cam_pos
		var distance: float = to_obstacle.length()
		if distance < 1.0:
			continue

		var dir: Vector3 = to_obstacle.normalized()
		var query := PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + dir * (distance + 2.0))
		query.collision_mask = 1 | 2 | 4

		var hit: Dictionary = world_3d.direct_space_state.intersect_ray(query)
		tested_count += 1

		if not hit.is_empty():
			var collider = hit.get("collider", null)
			if collider != null:
				var node_walker: Node = collider
				var found_cover := false
				while node_walker != null:
					if node_walker == obstacle:
						found_cover = true
						break
					node_walker = node_walker.get_parent()
				if found_cover:
					blocked_count += 1

	if tested_count == 0:
		_fail("T2-04: 没有可测试的掩体")
		return

	if blocked_count < tested_count * 0.5:
		_fail("T2-04: 掩体挡弹率过低 (%d/%d = %.0f%%)，应有 50%% 以上" % [
			blocked_count, tested_count, float(blocked_count) / float(tested_count) * 100.0
		])
		return

	_pass("T2-04: 掩体挡弹正常 (命中 %d/%d = %.0f%%)" % [
		blocked_count, tested_count, float(blocked_count) / float(tested_count) * 100.0
	])


func _test_t2_05_spawn_no_clip(battle: Node) -> void:
	print("[STEP1-2] T2-05: 检查刷点不穿模...")

	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("T2-05: 缺少 battle_core")
		return

	var active_actors: Array = battle_core.get("active_actors")
	var cover_obstacles: Array = battle.get("cover_obstacles_3d")

	var clipped_count := 0

	for actor in active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue
		var actor_pos: Vector3 = actor.global_position
		var actor_radius: float = actor.body_radius

		if actor_pos.y < -0.1:
			clipped_count += 1
			continue

		for obstacle in cover_obstacles:
			if not is_instance_valid(obstacle):
				continue
			var obs_pos: Vector3 = obstacle.global_position
			var obs_size: Vector3 = obstacle.size
			var dx := absf(actor_pos.x - obs_pos.x)
			var dz := absf(actor_pos.z - obs_pos.z)

			if dx < obs_size.x * 0.5 + actor_radius * 0.8 and dz < obs_size.z * 0.5 + actor_radius * 0.8:
				if actor_pos.y < obs_size.y:
					clipped_count += 1
					break

	if clipped_count > 0:
		_fail("T2-05: 有 %d 个角色刷在掩体/地面内" % clipped_count)
		return

	_pass("T2-05: 刷点正常，无穿模 (角色 %d 个, 掩体 %d 个)" % [active_actors.size(), cover_obstacles.size()])


func _test_t2_06_cover_recognition(battle: Node) -> void:
	print("[STEP1-2] T2-06: 检查角色靠掩体时的识别机会...")

	var battle_core = battle.get("battle_core")
	var cover_obstacles: Array = battle.get("cover_obstacles_3d")
	if battle_core == null or cover_obstacles.is_empty():
		_fail("T2-06: 缺少 battle_core 或掩体")
		return

	var active_actors: Array = battle_core.get("active_actors")

	var near_cover_targets := 0
	var near_cover_civilians := 0

	for actor in active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue
		var actor_pos: Vector3 = actor.global_position

		for obstacle in cover_obstacles:
			if not is_instance_valid(obstacle):
				continue
			var dist: float = actor_pos.distance_to(obstacle.global_position)
			if dist < 2.5:
				if actor.actor_kind == "target":
					near_cover_targets += 1
				elif actor.actor_kind == "civilian":
					near_cover_civilians += 1
				break

	_pass("T2-06: 角色与掩体组合正常 - 靠近掩体的目标:%d, 平民:%d" % [near_cover_targets, near_cover_civilians])


func _test_t2_07_light_cover_interference(battle: Node) -> void:
	print("[STEP1-2] T2-07: 检查轻型掩体干扰度...")

	var cover_obstacles: Array = battle.get("cover_obstacles_3d")
	if cover_obstacles.is_empty():
		_fail("T2-07: 没有掩体")
		return

	var lamp_count := 0
	var billboard_count := 0
	var lamp_volume_total := 0.0
	var billboard_volume_total := 0.0
	var wall_volume_total := 0.0
	var _van_volume_total := 0.0

	for obstacle in cover_obstacles:
		if not is_instance_valid(obstacle):
			continue
		var size: Vector3 = obstacle.size
		var volume: float = size.x * size.y * size.z
		match obstacle.style_id:
			"street_lamp":
				lamp_count += 1
				lamp_volume_total += volume
			"billboard":
				billboard_count += 1
				billboard_volume_total += volume
			"wall_corner":
				wall_volume_total += volume
			"parked_van":
				_van_volume_total += volume

	var avg_lamp_vol := lamp_volume_total / maxf(lamp_count, 1)
	var avg_billboard_vol := billboard_volume_total / maxf(billboard_count, 1)
	var avg_wall_vol := wall_volume_total / maxf(1, 1)

	if lamp_count > 0 and avg_lamp_vol > avg_wall_vol * 0.6:
		_fail("T2-07: 路灯体积过大 (%.2f)，不应形成重型遮挡 (墙体积=%.2f)" % [avg_lamp_vol, avg_wall_vol])
		return

	_pass("T2-07: 轻型掩体干扰合理 - 路灯:%d (均体%.1f), 广告牌:%d (均体%.1f)" % [
		lamp_count, avg_lamp_vol, billboard_count, avg_billboard_vol
	])


func _finish() -> void:
	print("")
	print("[STEP1-2] ========== 测试结果汇总 ==========")
	print("[STEP1-2] 通过: %d 项" % _passes.size())
	print("[STEP1-2] 失败: %d 项" % _failures.size())
	print("")

	for p in _passes:
		print("[STEP1-2][PASS] %s" % p)
	if not _failures.is_empty():
		print("")
		for f in _failures:
			print("[STEP1-2][FAIL] %s" % f)

	print("")

	if _failures.is_empty():
		print("[STEP1-2_SMOKE] PASS")
		_write_result("PASS", [])
		smoke_finished.emit("PASS", [])
	else:
		print("[STEP1-2_SMOKE] FAIL")
		_write_result("FAIL", _failures)
		smoke_finished.emit("FAIL", _failures.duplicate())

	_teardown()


func _teardown() -> void:
	if _is_embedded:
		CoreEventBus.test_center_requested.emit()
		await get_tree().process_frame
	elif auto_quit:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
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
	else:
		_pass(message)


func _pass(message: String) -> void:
	_passes.append(message)
	print("[STEP1-2][PASS] %s" % message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("[STEP1-2][FAIL] %s" % message)


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://step1_step2_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 step1_step2_smoke_result.txt")
		return

	file.store_line("STEP1_STEP2_SMOKE=%s" % status)
	file.store_line("PASS_COUNT=%d" % _passes.size())
	file.store_line("FAIL_COUNT=%d" % failures.size())
	if not _passes.is_empty():
		file.store_line("--- PASSES ---")
		for p in _passes:
			file.store_line(str(p))
	if not failures.is_empty():
		file.store_line("--- FAILURES ---")
		for failure in failures:
			file.store_line(str(failure))
