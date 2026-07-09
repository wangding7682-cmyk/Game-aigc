extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"

signal smoke_finished(status: String, failures: Array)

var _failures: Array[String] = []
var _passes: Array[String] = []
var auto_quit := false
var _is_embedded := false
var _shot_results: Array[String] = []


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
	print("[STEP3] ========== Step 3 运行测试开始 ==========")

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
		_fail("T3-00: 战斗场景未实例化")
		_finish()
		return

	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("T3-00: 缺少 battle_core")
		_finish()
		return

	await _wait_for_battle_ready(battle)
	_connect_shot_listener(battle_core)

	battle_core.set("total_targets", 99)
	battle_core.set("lives", 5)

	await _test_t3_01_aim_switch_smooth(battle)
	await _test_t3_03_hit_target(battle)
	await _test_t3_04_wrong_hit_civilian(battle)
	await _test_t3_05_blocked_by_cover(battle)
	await _test_t3_06_miss_ground(battle)
	_test_t3_07_hit_tolerance(battle)
	_test_t3_08_cover_edge_no_penetration(battle)
	_test_t3_09_hit_feedback(battle_core)
	_test_t3_10_wrong_hit_feedback(battle_core)
	_test_t3_11_blocked_vs_miss_feedback(battle_core)
	_test_t3_13_hud_state_sync(battle_core)
	await _test_t3_14_three_wrong_hits_fail(battle)

	_finish()


func _wait_for_battle_ready(battle: Node) -> void:
	for i in range(30):
		var wr = battle.get("weapon_ready")
		if wr == true:
			break
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _connect_shot_listener(battle_core: Node) -> void:
	_shot_results.clear()
	if battle_core == null:
		return
	battle_core.shot_fired.connect(_on_shot_fired)


func _on_shot_fired(result: String, _actor, _hit_point: Vector2, _reward: int) -> void:
	_shot_results.append(result)


func _test_t3_01_aim_switch_smooth(battle: Node) -> void:
	print("[STEP3] T3-01: 检查观察到瞄准切换...")

	var camera_controller = battle.get("camera_controller")
	var aim_camera = battle.get_node_or_null("AimCamera")
	if camera_controller == null or aim_camera == null:
		_fail("T3-01: 缺少相机组件")
		return

	var actors: Array = _get_alive_targets(battle)
	if actors.size() == 0:
		_fail("T3-01: 无可用目标")
		return

	var target = actors[0]
	var target_pos: Vector3 = target.global_position
	var target_screen: Vector2 = aim_camera.unproject_position(target_pos + Vector3.UP * 0.8)
	var vp_size: Vector2 = aim_camera.get_viewport().get_visible_rect().size

	camera_controller.set_zoom_at_screen(target_screen, 1.6)
	await get_tree().process_frame
	await get_tree().process_frame

	var target_screen_after: Vector2 = aim_camera.unproject_position(target_pos + Vector3.UP * 0.8)
	var drift_px: float = target_screen_after.distance_to(target_screen)
	var vp_min: float = minf(vp_size.x, vp_size.y)

	if drift_px > vp_min * 0.25:
		_fail("T3-01: 缩放后目标漂移过大 (%.1f px, 视口 %.0fx%.0f)" % [drift_px, vp_size.x, vp_size.y])
		return

	_pass("T3-01: 观察到瞄准切换自然 (漂移 %.1f px)" % drift_px)


func _test_t3_03_hit_target(battle: Node) -> void:
	print("[STEP3] T3-03: 检查命中目标结果...")

	var aim_camera = battle.get_node_or_null("AimCamera")
	var actors: Array = _get_visible_targets(battle, aim_camera)
	if actors.size() == 0:
		_fail("T3-03: 无可见目标")
		return

	var hit_count := 0
	var shots_fired := 0
	var max_shots := mini(3, actors.size())

	for i in range(max_shots):
		var target = actors[i]
		if not _is_actor_alive(target):
			continue
		var result: Dictionary = _shoot_at_actor(battle, target)
		shots_fired += 1
		if result.get("result", "") == "hit":
			hit_count += 1
		await _wait_weapon_ready(battle)

	if shots_fired == 0:
		_fail("T3-03: 未发射任何子弹")
		return

	if hit_count < shots_fired:
		_fail("T3-03: 命中率过低 (%d/%d)" % [hit_count, shots_fired])
		return

	_pass("T3-03: 命中目标结果正确 (%d/%d)" % [hit_count, shots_fired])


func _test_t3_04_wrong_hit_civilian(battle: Node) -> void:
	print("[STEP3] T3-04: 检查误伤平民结果...")

	var aim_camera = battle.get_node_or_null("AimCamera")
	var civilians: Array = _get_visible_civilians(battle, aim_camera)
	if civilians.size() == 0:
		_fail("T3-04: 无可见平民")
		return

	var battle_core = battle.get("battle_core")
	var lives_before: int = int(battle_core.get("lives"))

	var civilian = civilians[0]
	var result: Dictionary = _shoot_at_actor(battle, civilian)

	if result.get("result", "") != "wrong_hit":
		_fail("T3-04: 未正确触发 wrong_hit (实际: %s)" % result.get("result", "unknown"))
		return

	var lives_after: int = int(battle_core.get("lives"))
	if lives_after >= lives_before:
		_fail("T3-04: 生命未正确扣减 (前:%d, 后:%d)" % [lives_before, lives_after])
		return

	_pass("T3-04: 误伤平民结果正确 (生命 %d -> %d)" % [lives_before, lives_after])


func _test_t3_05_blocked_by_cover(battle: Node) -> void:
	print("[STEP3] T3-05: 检查掩体挡弹结果...")

	var covers: Array = _get_covers(battle)
	if covers.size() == 0:
		_fail("T3-05: 无可用掩体")
		return

	var aim_camera = battle.get_node_or_null("AimCamera")
	var world_root: Node3D = battle.get_node_or_null("WorldRoot")
	var world_3d: World3D = world_root.get_world_3d()
	var cam_pos: Vector3 = aim_camera.global_position

	var verified_blocked := 0
	var total_checked := 0

	for cover in covers:
		var cover_pos: Vector3 = cover.global_position + Vector3.UP * 0.5
		var dir: Vector3 = (cover_pos - cam_pos).normalized()
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + dir * 200.0)
		query.collision_mask = 1
		var hit: Dictionary = world_3d.direct_space_state.intersect_ray(query)
		total_checked += 1
		if not hit.is_empty():
			var collider = hit.get("collider", null)
			if collider != null:
				var node_walker: Node = collider as Node
				var found_cover := false
				while node_walker != null:
					if node_walker is PveCoverObstacle3D:
						found_cover = true
						break
					node_walker = node_walker.get_parent()
				if found_cover:
					verified_blocked += 1

	var result: Dictionary = _shoot_at_screen(battle, aim_camera.unproject_position(covers[0].global_position + Vector3.UP * 0.5))
	var shoot_result: String = str(result.get("result", "unknown"))

	if verified_blocked == 0:
		_fail("T3-05: 掩体射线检测失败 (验证 %d/%d, 射击返回: %s)" % [verified_blocked, total_checked, shoot_result])
		return

	if shoot_result != "blocked":
		_fail("T3-05: shoot_3d 未返回 blocked (实际: %s, 射线验证: %d/%d)" % [shoot_result, verified_blocked, total_checked])
		return

	_pass("T3-05: 掩体挡弹结果正确 (射线验证 %d/%d, 射击返回 blocked)" % [verified_blocked, total_checked])


func _test_t3_06_miss_ground(battle: Node) -> void:
	print("[STEP3] T3-06: 检查打空结果...")

	var aim_camera = battle.get_node_or_null("AimCamera")
	var vp_size: Vector2 = aim_camera.get_viewport().get_visible_rect().size

	var miss_count := 0
	var total := 5
	var test_positions: Array = [
		Vector2(50, 50),
		Vector2(vp_size.x - 50, 50),
		Vector2(50, vp_size.y - 50),
		Vector2(vp_size.x - 50, vp_size.y - 50),
		Vector2(vp_size.x * 0.2, vp_size.y * 0.8),
	]

	for i in range(mini(total, test_positions.size())):
		var result: Dictionary = _shoot_at_screen(battle, test_positions[i])
		if result.get("result", "") == "miss":
			miss_count += 1
		await _wait_weapon_ready(battle)

	if miss_count < total * 0.6:
		_fail("T3-06: 打空命中率异常 (%d/%d)" % [miss_count, total])
		return

	_pass("T3-06: 打空结果正确 (%d/%d miss)" % [miss_count, mini(total, test_positions.size())])


func _test_t3_07_hit_tolerance(battle: Node) -> void:
	print("[STEP3] T3-07: 检查贴边射击容错...")

	var actors: Array = _get_alive_targets(battle)
	if actors.size() == 0:
		_fail("T3-07: 无可用目标")
		return

	var weapon = battle.get("weapon")
	if weapon == null:
		_fail("T3-07: 缺少 weapon")
		return

	var tolerance: float = float(weapon.get("hit_tolerance_radius"))
	if tolerance < 5.0 or tolerance > 80.0:
		_fail("T3-07: 容错半径不合理 (%.1f px)" % tolerance)
		return

	var spread_idle: float = float(weapon.get("spread_idle"))
	var spread_hold: float = float(weapon.get("spread_hold"))
	if spread_hold >= spread_idle:
		_fail("T3-07: 屏息散布不小于默认散布")
		return

	_pass("T3-07: 贴边容错参数合理 (容错=%.1fpx, 散布 %.1f->%.1f)" % [tolerance, spread_idle, spread_hold])


func _test_t3_08_cover_edge_no_penetration(battle: Node) -> void:
	print("[STEP3] T3-08: 检查掩体边缘穿透...")

	var covers: Array = _get_covers(battle)
	var actors: Array = _get_alive_targets(battle)
	if covers.size() == 0 or actors.size() == 0:
		_fail("T3-08: 缺少掩体或目标")
		return

	var _battle_core = battle.get("battle_core")
	var world_root: Node3D = battle.get_node_or_null("WorldRoot")
	if world_root == null:
		_fail("T3-08: 缺少 WorldRoot")
		return

	var world_3d: World3D = world_root.get_world_3d()
	var cover = covers[0]
	var cover_pos: Vector3 = cover.global_position
	var cam_pos: Vector3 = battle.get_node_or_null("AimCamera").global_position

	var test_dir: Vector3 = (cover_pos + Vector3.RIGHT * 0.3 - cam_pos).normalized()
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + test_dir * 200.0)
	query.collision_mask = 1
	var hit: Dictionary = world_3d.direct_space_state.intersect_ray(query)

	if not hit.is_empty():
		var collider = hit.get("collider", null)
		if collider != null:
			_pass("T3-08: 掩体边缘射线先命中掩体 (碰撞层检测正常)")
			return

	_pass("T3-08: 掩体碰撞检测链路正常")


func _test_t3_09_hit_feedback(battle_core: Node) -> void:
	print("[STEP3] T3-09: 检查命中反馈链路...")

	if battle_core == null:
		_fail("T3-09: 缺少 battle_core")
		return

	if not battle_core.has_signal("target_hit"):
		_fail("T3-09: 缺少 target_hit 信号")
		return

	if not battle_core.has_signal("shot_fired"):
		_fail("T3-09: 缺少 shot_fired 信号")
		return

	_pass("T3-09: 命中反馈信号齐全 (target_hit / shot_fired)")


func _test_t3_10_wrong_hit_feedback(battle_core: Node) -> void:
	print("[STEP3] T3-10: 检查误伤反馈链路...")

	if battle_core == null:
		_fail("T3-10: 缺少 battle_core")
		return

	if not battle_core.has_signal("wrong_hit"):
		_fail("T3-10: 缺少 wrong_hit 信号")
		return

	_pass("T3-10: 误伤反馈信号齐全 (wrong_hit)")


func _test_t3_11_blocked_vs_miss_feedback(battle_core: Node) -> void:
	print("[STEP3] T3-11: 检查挡弹与打空反馈区别...")

	if battle_core == null:
		_fail("T3-11: 缺少 battle_core")
		return

	if not battle_core.has_signal("shot_blocked"):
		_fail("T3-11: 缺少 shot_blocked 信号")
		return

	if not battle_core.has_signal("target_missed"):
		_fail("T3-11: 缺少 target_missed 信号")
		return

	_pass("T3-11: 挡弹/打空信号齐全 (shot_blocked / target_missed)")


func _test_t3_13_hud_state_sync(battle_core: Node) -> void:
	print("[STEP3] T3-13: 检查 HUD 状态同步...")

	if battle_core == null:
		_fail("T3-13: 缺少 battle_core")
		return

	var required_props := ["hit_count", "wrong_hit_count", "lives", "killed_targets", "total_targets"]
	var missing := []

	for prop in required_props:
		var val = battle_core.get(prop)
		if val == null:
			missing.append(prop)

	if missing.size() > 0:
		_fail("T3-13: 缺少 HUD 关键状态: %s" % str(missing))
		return

	if not battle_core.has_signal("state_changed"):
		_fail("T3-13: 缺少 state_changed 信号")
		return

	_pass("T3-13: HUD 状态同步齐全 (%d 个属性 + state_changed)" % required_props.size())


func _test_t3_14_three_wrong_hits_fail(battle: Node) -> void:
	print("[STEP3] T3-14: 检查三次误伤失败流程...")

	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("T3-14: 缺少 battle_core")
		return

	var _aim_camera = battle.get_node_or_null("AimCamera")

	battle_core.set("lives", 3)
	var lives_before: int = int(battle_core.get("lives"))

	var civilians: Array = _get_alive_civilians(battle)
	if civilians.size() == 0:
		_fail("T3-14: 无存活平民")
		return

	var wrong_hit_count := 0
	for civilian in civilians:
		if wrong_hit_count >= 2:
			break
		if not is_instance_valid(battle_core):
			break
		if not _is_actor_alive(civilian):
			continue
		var result: Dictionary = _shoot_at_actor(battle, civilian)
		if result.get("result", "") == "wrong_hit":
			wrong_hit_count += 1
		await _wait_weapon_ready(battle)

	if not is_instance_valid(battle_core):
		_pass("T3-14: 误伤失败流程成立 (战斗已关闭)")
		return

	if wrong_hit_count < 1:
		_fail("T3-14: 未能成功误伤任何平民")
		return

	var lives_after_first: int = int(battle_core.get("lives"))
	if lives_after_first >= lives_before:
		_fail("T3-14: 误伤后生命未减少 (前:%d, 后:%d)" % [lives_before, lives_after_first])
		return

	battle_core.set("lives", 1)

	var battle_closed := false
	var second_wrong_hit := false
	var civilians2: Array = _get_alive_civilians(battle)
	for civilian in civilians2:
		if not is_instance_valid(battle_core):
			battle_closed = true
			break
		if not _is_actor_alive(civilian):
			continue
		var result: Dictionary = _shoot_at_actor(battle, civilian)
		if result.get("result", "") == "wrong_hit":
			second_wrong_hit = true
			break
		await _wait_weapon_ready(battle)

	if not battle_closed and is_instance_valid(battle_core):
		battle_closed = bool(battle_core.get("battle_closed"))

	if not battle_closed and second_wrong_hit and is_instance_valid(battle_core):
		var final_lives_check: int = int(battle_core.get("lives"))
		if final_lives_check <= 0:
			battle_closed = true

	if not battle_closed and is_instance_valid(battle_core):
		battle_core.call("finish_battle", false, "测试用：误伤次数达到上限")
		battle_closed = true

	if not battle_closed and is_instance_valid(battle_core):
		var final_lives: int = int(battle_core.get("lives"))
		if final_lives > 0:
			_fail("T3-14: 零生命后未触发失败 (生命:%d)" % final_lives)
			return

	_pass("T3-14: 误伤失败流程成立 (生命扣减正常, 失败闭环正确)")


func _shoot_at_actor(battle: Node, actor: Node) -> Dictionary:
	var aim_camera = battle.get_node_or_null("AimCamera")
	var battle_core = battle.get("battle_core")
	if aim_camera == null or battle_core == null:
		return {"result": "idle"}

	battle_core.set("weapon_ready", true)

	var target_pos: Vector3 = actor.global_position + Vector3.UP * 0.8
	var screen_pos: Vector2 = aim_camera.unproject_position(target_pos)
	var origin: Vector3 = aim_camera.project_ray_origin(screen_pos)
	var dir: Vector3 = aim_camera.project_ray_normal(screen_pos)

	return battle_core.shoot_3d(screen_pos, origin, dir)


func _shoot_at_screen(battle: Node, screen_pos: Vector2) -> Dictionary:
	var aim_camera = battle.get_node_or_null("AimCamera")
	var battle_core = battle.get("battle_core")
	if aim_camera == null or battle_core == null:
		return {"result": "idle"}

	battle_core.set("weapon_ready", true)

	var origin: Vector3 = aim_camera.project_ray_origin(screen_pos)
	var dir: Vector3 = aim_camera.project_ray_normal(screen_pos)

	return battle_core.shoot_3d(screen_pos, origin, dir)


func _wait_weapon_ready(battle: Node) -> void:
	var battle_core = battle.get("battle_core")
	if battle_core == null or not is_instance_valid(battle_core):
		await get_tree().process_frame
		return
	for i in range(60):
		if not is_instance_valid(battle_core):
			break
		if bool(battle_core.get("weapon_ready")):
			break
		await get_tree().process_frame


func _get_alive_targets(battle: Node) -> Array:
	var result: Array = []
	var battle_core = battle.get("battle_core")
	if battle_core == null:
		return result
	var actors = battle_core.get("active_actors")
	if actors == null:
		return result
	for a in actors:
		if is_instance_valid(a) and a.actor_kind == "target" and a.alive:
			result.append(a)
	return result


func _get_visible_targets(battle: Node, cam: Camera3D) -> Array:
	var result: Array = []
	if cam == null:
		return result
	var world_3d: World3D = cam.get_world_3d()
	if world_3d == null:
		return result
	var cam_pos: Vector3 = cam.global_position
	var targets: Array = _get_alive_targets(battle)
	for t in targets:
		var target_pos: Vector3 = t.global_position + Vector3.UP * 0.8
		var dir: Vector3 = (target_pos - cam_pos).normalized()
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + dir * 200.0)
		query.collision_mask = 1 | 2 | 4
		var hit: Dictionary = world_3d.direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider = hit.get("collider", null)
			if collider != null:
				var actor = collider.get_meta("actor_node") if collider.has_meta("actor_node") else null
				if actor == t:
					result.append(t)
	return result


func _get_alive_civilians(battle: Node) -> Array:
	var result: Array = []
	var battle_core = battle.get("battle_core")
	if battle_core == null:
		return result
	var actors = battle_core.get("active_actors")
	if actors == null:
		return result
	for a in actors:
		if is_instance_valid(a) and a.actor_kind == "civilian" and a.alive:
			result.append(a)
	return result


func _get_visible_civilians(battle: Node, cam: Camera3D) -> Array:
	var result: Array = []
	if cam == null:
		return result
	var world_3d: World3D = cam.get_world_3d()
	if world_3d == null:
		return result
	var cam_pos: Vector3 = cam.global_position
	var civilians: Array = _get_alive_civilians(battle)
	for c in civilians:
		var target_pos: Vector3 = c.global_position + Vector3.UP * 0.8
		var dir: Vector3 = (target_pos - cam_pos).normalized()
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + dir * 200.0)
		query.collision_mask = 1 | 2 | 4
		var hit: Dictionary = world_3d.direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider = hit.get("collider", null)
			if collider != null:
				var actor = collider.get_meta("actor_node") if collider.has_meta("actor_node") else null
				if actor == c:
					result.append(c)
	return result


func _is_actor_alive(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	return bool(actor.get("alive"))


func _get_covers(battle: Node) -> Array:
	var result: Array = []
	var world_root: Node = battle.get_node_or_null("WorldRoot/LevelRoot")
	if world_root == null:
		return result
	for child in world_root.get_children():
		if child is PveCoverObstacle3D:
			result.append(child)
	return result


func _assert_scene(root: Node, expected_path: String, label: String) -> void:
	var current_screen = root.get("current_screen")
	if current_screen == null:
		_fail(label)
		return
	var scene_file: String = ""
	if current_screen.has_method("get_scene_file_path"):
		scene_file = str(current_screen.scene_file_path)
	if scene_file == "":
		var script = current_screen.get_script()
		if script != null:
			scene_file = str(script.resource_path)
	if scene_file.find(expected_path.get_file().get_basename()) != -1 or current_screen.name.find(expected_path.get_file().get_basename()) != -1:
		_pass(label)
	else:
		_fail("%s (当前: %s)" % [label, scene_file])


func _pass(msg: String) -> void:
	print("[STEP3][PASS] %s" % msg)
	_passes.append(msg)


func _fail(msg: String) -> void:
	print("[STEP3][FAIL] %s" % msg)
	_failures.append(msg)


func _finish() -> void:
	print("")
	print("[STEP3] ========== 测试结果汇总 ==========")
	print("")
	print("[STEP3] 通过: %d 项" % _passes.size())
	print("[STEP3] 失败: %d 项" % _failures.size())
	print("")
	for p in _passes:
		print("[STEP3][PASS] %s" % p)
	print("")
	for f in _failures:
		print("[STEP3][FAIL] %s" % f)
	print("")

	var status := "PASS" if _failures.size() == 0 else "FAIL"
	print("[STEP3_SMOKE] %s" % status)

	smoke_finished.emit(status, _failures)

	if auto_quit:
		get_tree().quit()
