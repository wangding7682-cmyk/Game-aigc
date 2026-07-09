extends "res://scripts/pve/battle_core.gd"

const PVE_TARGET_CONTROLLER_3D_SCRIPT = preload("res://scripts/pve/pve_target_controller_3d.gd")
const FOLIAGE_PROP_3D_SCRIPT = preload("res://scripts/pve/pve_foliage_prop_3d.gd")

var world_root: Node3D = null
var camera_3d = null
var cover_obstacles: Array = []

var world_bounds_x: Vector2 = Vector2(-14.0, 14.0)
var world_bounds_z: Vector2 = Vector2(-11.0, 11.0)

var rng_3d: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng_3d.randomize()


func setup_3d(level_cfg, weapon_obj, camera_ctrl, world_3d: Node3D) -> void:
	level_config = level_cfg
	weapon = weapon_obj
	camera_controller = null
	camera_3d = camera_ctrl
	world_root = world_3d
	pending_victory_reason = ""

	_reset_battle_stats()
	remaining_time = level_config.time_limit_sec
	scan_count = int(level_config.scan_count)
	time_extend_count = int(level_config.time_extend_count)
	total_targets = int(level_config.required_targets)

	var tutorial_active: bool = int(level_config.level_id) == 1 and CoreGameState.is_tutorial_active()
	if tutorial_active:
		scan_count = maxi(scan_count, 2)
		time_extend_count = maxi(time_extend_count, 1)

	active_actors.clear()
	tutorial_primary_target = null

	battle_closed = false
	weapon_ready = true


func spawn_actors_3d() -> void:
	var target_behaviors: Array[String] = []
	var tutorial_layout_active: bool = level_config.level_id == 1 and CoreGameState.is_tutorial_active()
	var total_spawn_count: int = int(level_config.required_targets + level_config.civilian_count)
	var spawn_plan: Array[Dictionary] = _build_level_spawn_plan_from_config_3d()

	for _i in range(level_config.moving_targets):
		target_behaviors.append("moving")

	for _i in range(level_config.weakpoint_targets):
		target_behaviors.append("weakpoint")

	while target_behaviors.size() < int(level_config.required_targets):
		target_behaviors.append("static")

	if not tutorial_layout_active:
		target_behaviors.shuffle()

	var target_positions: Array[Vector3] = _generate_positions_3d(total_spawn_count)
	if not spawn_plan.is_empty():
		target_positions.clear()
		for entry in spawn_plan:
			target_positions.append(entry.get("position", Vector3.ZERO))
	elif tutorial_layout_active:
		target_positions = [
			Vector3(2.4, 0.0, -1.2),
			Vector3(-2.6, 0.0, 1.1),
			Vector3(-0.6, 0.0, -0.8),
			Vector3(0.8, 0.0, 2.6),
			Vector3(4.0, 0.0, -0.5),
			Vector3(-3.6, 0.0, 1.8),
		]

	for index in range(int(level_config.required_targets)):
		var actor = PVE_TARGET_CONTROLLER_3D_SCRIPT.new()
		var is_tutorial_primary: bool = tutorial_layout_active and index == 0
		var target_behavior: String = target_behaviors[index]
		var target_extra: Dictionary = {
			"tutorial_primary": is_tutorial_primary,
			"disguise_strength": _pick_women_variant_strength(is_tutorial_primary),
		}
		target_extra.merge(_build_3d_behavior_defaults(target_behavior), false)
		if not spawn_plan.is_empty():
			var plan_entry: Dictionary = spawn_plan[index]
			target_behavior = str(plan_entry.get("behavior", target_behavior))
			target_extra = plan_entry.get("extra", {}).duplicate(true)
			target_extra["tutorial_primary"] = is_tutorial_primary or bool(target_extra.get("tutorial_primary", false))
			target_extra.merge(_build_3d_behavior_defaults(target_behavior), false)
		_maybe_apply_women1_action_variant(target_extra, target_behavior, is_tutorial_primary)
		target_extra.merge(_build_actor_search_profile_3d("target", target_behavior, is_tutorial_primary, index, float(target_extra.get("disguise_strength", 1.0))), false)
		actor.setup(
			"target",
			target_behavior,
			target_positions[index],
			rng_3d.randf_range(0.0, 100.0),
			target_extra
		)
		world_root.add_child(actor)
		active_actors.append(actor)
		if is_tutorial_primary:
			tutorial_primary_target = actor

	for offset in range(int(level_config.civilian_count)):
		var actor = PVE_TARGET_CONTROLLER_3D_SCRIPT.new()
		var civilian_behavior: String = "static"
		var civilian_extra: Dictionary = {
			"disguise_strength": 0.8,
		}
		if not spawn_plan.is_empty():
			var civilian_plan_entry: Dictionary = spawn_plan[int(level_config.required_targets) + offset]
			civilian_behavior = str(civilian_plan_entry.get("behavior", "static"))
			civilian_extra = civilian_plan_entry.get("extra", {}).duplicate(true)
		civilian_extra.merge(_build_actor_search_profile_3d("civilian", civilian_behavior, false, offset, float(civilian_extra.get("disguise_strength", 0.8))), false)
		actor.setup(
			"civilian",
			civilian_behavior,
			target_positions[int(level_config.required_targets) + offset],
			rng_3d.randf_range(0.0, 100.0),
			civilian_extra
		)
		world_root.add_child(actor)
		active_actors.append(actor)


func shoot_3d(_screen_pos: Vector2, origin: Vector3, dir: Vector3) -> Dictionary:
	if battle_closed or not weapon_ready:
		return {"result": "idle"}

	shot_count += 1

	if camera_3d == null or world_root == null:
		return {"result": "miss", "hit_point": Vector3.ZERO}

	var world_3d: World3D = world_root.get_world_3d()
	if world_3d == null:
		return {"result": "miss", "hit_point": Vector3.ZERO}

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + dir * 200.0)
	query.collision_mask = 1 | 2 | 4
	var hit: Dictionary = world_3d.direct_space_state.intersect_ray(query)

	if hit.is_empty():
		var assisted_actor = _find_action_target_near_ray(origin, dir)
		if assisted_actor != null:
			var assisted_hit_point: Vector3 = assisted_actor.get_impact_focus_point()
			return _apply_actor_hit_3d(assisted_actor, assisted_hit_point, Vector3.UP)
		no_miss_rounds = 0
		var ground_hit: Vector3 = _ray_to_y_plane(origin, dir, 0.0)
		if ground_hit == Vector3.ZERO:
			ground_hit = origin + dir * 50.0
		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "miss",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
		})
		target_missed.emit(Vector2.ZERO)
		shot_fired.emit("miss", null, Vector2.ZERO, 0)
		state_changed.emit()
		return {"result": "miss", "hit_point": ground_hit, "hit_normal": Vector3.UP}

	var collider: Object = hit.get("collider", null)
	if collider == null or not is_instance_valid(collider):
		return {"result": "miss", "hit_point": hit.get("position", Vector3.ZERO), "hit_normal": Vector3.UP}

	var actor = collider.get_meta("actor_node") if collider.has_meta("actor_node") else null
	var hit_point: Vector3 = hit.get("position", Vector3.ZERO)
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)

	if actor == null or not is_instance_valid(actor):
		no_miss_rounds = 0
		var obstacle_node: Node = null
		var foliage_node: Node = null
		var node_walker: Node = collider as Node
		while node_walker != null:
			if node_walker is PveCoverObstacle3D:
				obstacle_node = node_walker
				break
			if node_walker is FOLIAGE_PROP_3D_SCRIPT:
				foliage_node = node_walker
				break
			node_walker = node_walker.get_parent()
		if foliage_node != null and is_instance_valid(foliage_node):
			if foliage_node.has_method("apply_shot_hit"):
				foliage_node.call("apply_shot_hit", hit_point, hit_normal)
			record_tactical_shot(Vector2.ZERO)
			CoreEventBus.log_event("shot_fired", {
				"level_id": level_config.level_id,
				"result": "foliage",
				"shot_count": shot_count,
				"hit_count": hit_count,
				"wrong_hit_count": wrong_hit_count,
				"tactical_shot_count": tactical_shot_count,
			})
			shot_fired.emit("foliage", foliage_node, Vector2.ZERO, 0)
			state_changed.emit()
			return {"result": "foliage", "actor": foliage_node, "hit_point": hit_point, "hit_normal": hit_normal}
		record_tactical_shot(Vector2.ZERO)
		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "blocked",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
			"tactical_shot_count": tactical_shot_count,
		})
		shot_blocked.emit(obstacle_node, Vector2.ZERO)
		shot_fired.emit("blocked", obstacle_node, Vector2.ZERO, 0)
		state_changed.emit()
		return {"result": "blocked", "actor": obstacle_node, "hit_point": hit_point, "hit_normal": hit_normal}

	return _apply_actor_hit_3d(actor, hit_point, hit_normal)


func _find_action_target_near_ray(origin: Vector3, dir: Vector3):
	var best_actor = null
	var best_distance := INF
	var ray_dir := dir.normalized()
	for actor in active_actors:
		if actor == null or not is_instance_valid(actor):
			continue
		if not bool(actor.get("women_action_enabled")):
			continue
		if not actor.is_hittable():
			continue
		var target_point: Vector3 = actor.get_impact_focus_point()
		var projection := (target_point - origin).dot(ray_dir)
		if projection < 0.0 or projection > 200.0:
			continue
		var closest_point := origin + ray_dir * projection
		var lateral_distance := target_point.distance_to(closest_point)
		var allowed_distance := maxf(float(actor.get("body_radius")) * 1.55, 1.10)
		if lateral_distance <= allowed_distance and lateral_distance < best_distance:
			best_distance = lateral_distance
			best_actor = actor
	return best_actor


func _apply_actor_hit_3d(actor, hit_point: Vector3, hit_normal: Vector3 = Vector3.UP) -> Dictionary:
	if not actor.is_hittable():
		no_miss_rounds = 0
		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "blocked",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
		})
		shot_blocked.emit(actor, Vector2.ZERO)
		shot_fired.emit("blocked", actor, Vector2.ZERO, 0)
		state_changed.emit()
		return {"result": "blocked", "actor": actor, "hit_point": hit_point, "hit_normal": hit_normal}

	if actor == tutorial_primary_target:
		actor.set_tutorial_primary(false)

	if actor.actor_kind == "civilian":
		actor.mark_hit("wrong_hit", false)
		var visual_hit_callback: Callable = actor.hide_dead_body
		wrong_hit_count += 1
		wrong_identification_count += 1
		recognition_combo_count = 0
		lives -= 1
		no_miss_rounds = 0
		_apply_wrong_identification_penalty()

		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "wrong_hit",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
			"elapsed_time": elapsed_time,
		})

		wrong_hit.emit(actor, Vector2.ZERO)
		shot_fired.emit("wrong_hit", actor, Vector2.ZERO, 0)
		state_changed.emit()

		if lives <= 0:
			finish_battle(false, "误伤次数达到上限")

		return {"result": "wrong_hit", "actor": actor, "hit_point": hit_point, "hit_normal": hit_normal, "visual_hit_callback": visual_hit_callback}
	else:
		var damage_result: Dictionary = actor.apply_shot_damage("hit", false)
		var ineffective: bool = bool(damage_result.get("ineffective", false))
		if ineffective:
			no_miss_rounds = 0
			var remaining_hp: int = int(damage_result.get("remaining_hp", 1))
			var max_hp: int = int(damage_result.get("max_hp", 1))
			CoreEventBus.log_event("shot_fired", {
				"level_id": level_config.level_id,
				"result": "ineffective",
				"shot_count": shot_count,
				"hit_count": hit_count,
				"wrong_hit_count": wrong_hit_count,
				"elapsed_time": elapsed_time,
				"remaining_hp": remaining_hp,
				"max_hp": max_hp,
			})
			ineffective_hit.emit(actor, Vector2.ZERO)
			shot_fired.emit("ineffective", actor, Vector2.ZERO, 0)
			state_changed.emit()
			return {
				"result": "ineffective",
				"actor": actor,
				"hit_point": hit_point,
				"hit_normal": hit_normal,
				"reward": 0,
				"remaining_hp": remaining_hp,
				"max_hp": max_hp,
			}
		var defeated: bool = bool(damage_result.get("defeated", true))
		if not defeated:
			no_miss_rounds += 1
			var remaining_hp: int = int(damage_result.get("remaining_hp", 1))
			var max_hp: int = int(damage_result.get("max_hp", 1))
			CoreEventBus.log_event("shot_fired", {
				"level_id": level_config.level_id,
				"result": "damage",
				"shot_count": shot_count,
				"hit_count": hit_count,
				"wrong_hit_count": wrong_hit_count,
				"elapsed_time": elapsed_time,
				"remaining_hp": remaining_hp,
				"max_hp": max_hp,
			})
			target_damaged.emit(actor, Vector2.ZERO, remaining_hp, max_hp)
			shot_fired.emit("hit", actor, Vector2.ZERO, 0)
			state_changed.emit()
			return {
				"result": "hit",
				"actor": actor,
				"hit_point": hit_point,
				"hit_normal": hit_normal,
				"reward": 0,
				"remaining_hp": remaining_hp,
				"max_hp": max_hp,
			}
		var visual_hit_callback: Callable = actor.hide_dead_body
		hit_count += 1
		killed_targets += 1
		no_miss_rounds += 1
		recognition_success_count += 1
		recognition_combo_count += 1

		var recognition_reward: int = _apply_recognition_reward(actor)
		_record_first_hit_if_needed()
		_record_level_checkpoints_after_kill()

		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "hit",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
			"elapsed_time": elapsed_time,
		})

		target_hit.emit(actor, Vector2.ZERO, recognition_reward)
		shot_fired.emit("hit", actor, Vector2.ZERO, recognition_reward)
		state_changed.emit()

		if killed_targets >= total_targets:
			pending_victory_reason = "全部目标已完成清除"

		return {"result": "hit", "actor": actor, "hit_point": hit_point, "hit_normal": hit_normal, "reward": recognition_reward, "visual_hit_callback": visual_hit_callback}


func use_scan_3d(scan_highlight_sec: float) -> bool:
	if not use_scan():
		return false

	for actor in active_actors:
		if is_instance_valid(actor) and actor.actor_kind == "target" and actor.alive:
			actor.highlight_for(scan_highlight_sec)

	return true


func _generate_positions_3d(count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var min_distance: float = 2.2

	for _i in range(count):
		var attempts := 0
		while attempts < 80:
			var candidate: Vector3 = Vector3(
				rng_3d.randf_range(world_bounds_x.x + 1.2, world_bounds_x.y - 1.2),
				0.0,
				rng_3d.randf_range(world_bounds_z.x + 0.8, world_bounds_z.y - 1.5)
			)
			var valid := true
			for pos in positions:
				if pos.distance_to(candidate) < min_distance:
					valid = false
					break
			if valid:
				positions.append(candidate)
				break
			attempts += 1
		if attempts >= 80:
			positions.append(Vector3(
				rng_3d.randf_range(world_bounds_x.x + 1.2, world_bounds_x.y - 1.2),
				0.0,
				rng_3d.randf_range(world_bounds_z.x + 0.8, world_bounds_z.y - 1.5)
			))

	return positions


func _build_level_spawn_plan_from_config_3d() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var config_entries: Array = level_config.spawn_entries
	if config_entries.is_empty():
		return entries

	for entry_resource in config_entries:
		if entry_resource == null:
			continue
		var original_actor_kind := str(entry_resource.actor_kind)
		var normalized_actor_kind := original_actor_kind

		var plan_entry: Dictionary = {
			"position": _map_config_position_to_world_3d(Vector2(entry_resource.position)),
			"behavior": str(entry_resource.behavior_type),
			"actor_kind": normalized_actor_kind,
			"extra": {
				"tutorial_primary": bool(entry_resource.tutorial_primary),
				"disguise_strength": float(entry_resource.disguise_strength),
			},
		}

		if float(entry_resource.move_range) >= 0.0:
			plan_entry["extra"]["move_range"] = float(entry_resource.move_range)
		if float(entry_resource.move_speed) >= 0.0:
			plan_entry["extra"]["move_speed"] = float(entry_resource.move_speed)
		if float(entry_resource.reveal_cycle_sec) >= 0.0:
			plan_entry["extra"]["reveal_cycle_sec"] = float(entry_resource.reveal_cycle_sec)
		if float(entry_resource.reveal_window_sec) >= 0.0:
			plan_entry["extra"]["reveal_window_sec"] = float(entry_resource.reveal_window_sec)
		if int(entry_resource.suspicion_tier) >= 0:
			plan_entry["extra"]["suspicion_tier"] = int(entry_resource.suspicion_tier)
		if not entry_resource.clue_profile.is_empty():
			plan_entry["extra"]["clue_profile"] = entry_resource.clue_profile
		if float(entry_resource.search_signal_strength) >= 0.0:
			plan_entry["extra"]["search_signal_strength"] = float(entry_resource.search_signal_strength)
		if not entry_resource.false_clue_profile.is_empty():
			plan_entry["extra"]["false_clue_profile"] = entry_resource.false_clue_profile
		if float(entry_resource.false_clue_cycle_sec) >= 0.0:
			plan_entry["extra"]["false_clue_cycle_sec"] = float(entry_resource.false_clue_cycle_sec)
		if float(entry_resource.false_clue_window_sec) >= 0.0:
			plan_entry["extra"]["false_clue_window_sec"] = float(entry_resource.false_clue_window_sec)

		entries.append(plan_entry)

	var expected_total: int = int(level_config.required_targets + level_config.civilian_count)
	if entries.size() != expected_total:
		push_warning("3D 关卡 %d 的 spawn_entries 数量不匹配，期望 %d，实际 %d，将回退随机刷点。" % [
			int(level_config.level_id),
			expected_total,
			entries.size(),
		])
		return []

	return entries


func _map_config_position_to_world_3d(config_position: Vector2) -> Vector3:
	var world_width: float = maxf(level_config.world_size.x, 1.0)
	var world_height: float = maxf(level_config.world_size.y, 1.0)
	var x_ratio: float = clampf(config_position.x / (world_width * 0.5), -1.0, 1.0)
	var z_ratio: float = clampf(config_position.y / (world_height * 0.5), -1.0, 1.0)
	return Vector3(
		lerpf(world_bounds_x.x, world_bounds_x.y, (x_ratio + 1.0) * 0.5),
		0.0,
		lerpf(world_bounds_z.x, world_bounds_z.y, (z_ratio + 1.0) * 0.5)
	)


func _build_3d_behavior_defaults(behavior: String) -> Dictionary:
	match behavior:
		"moving":
			return {
				"move_range": 2.4,
				"move_speed": 0.70,
			}
		"weakpoint":
			return {
				"reveal_cycle_sec": 6.8,
				"reveal_window_sec": 1.65,
			}
		_:
			return {}


func _maybe_apply_women1_action_variant(extra: Dictionary, _behavior: String, is_tutorial_primary: bool) -> void:
	if is_tutorial_primary:
		return
	if int(level_config.level_id) == 1:
		return
	if float(extra.get("disguise_strength", 1.0)) <= 0.35:
		return
	if rng_3d.randf() > 0.35:
		return
	extra["women_action_enabled"] = true
	extra["women_action_scene_key"] = 1 if rng_3d.randf() < 0.5 else 2
	extra["women_action_range"] = 0.42 + rng_3d.randf_range(0.0, 0.26)
	extra["women_action_speed"] = 0.34 + rng_3d.randf_range(0.0, 0.18)
	extra["move_range"] = minf(float(extra.get("move_range", 0.0)), 0.75)
	extra["move_speed"] = minf(maxf(float(extra.get("move_speed", 0.0)), 0.22), 0.55)


func _build_actor_search_profile_3d(kind: String, behavior: String, _is_primary: bool, index: int, _disguise_strength: float) -> Dictionary:
	var tier := 0
	var clues: Array[String] = []
	var search_signal: float = 0.0

	if kind == "target":
		clues.append("头部外壳过紧")
		clues.append("肩袖连接偏硬")
		tier = 1 + int(index % 3)
		search_signal = 0.2 + float(tier) * 0.18
		if behavior == "weakpoint":
			clues.append("腰侧细亮线短暂显露")
			tier = 3
			search_signal = 0.85
		elif behavior == "moving":
			clues.append("手套与手臂像一体件")
			search_signal += 0.15
	else:
		tier = 0
		search_signal = 0.05 + rng_3d.randf_range(0.0, 0.1)
		if rng_3d.randf() < 0.45:
			clues.append("发卡或耳饰反光")
		if rng_3d.randf() < 0.35:
			clues.append("围巾或衣领晃动")

	var false_clues: Array[String] = []
	if kind == "civilian" and rng_3d.randf() < 0.5:
		false_clues.append("胸针或拉链头反光")

	return {
		"suspicion_tier": tier,
		"clue_profile": clues,
		"false_clue_profile": false_clues,
		"search_signal_strength": search_signal,
		"body_radius": 0.55 + rng_3d.randf_range(-0.05, 0.08),
	}


func _pick_women_variant_strength(is_tutorial_primary: bool = false) -> float:
	if is_tutorial_primary:
		return 0.85
	return 0.22 if rng_3d.randf() < 0.5 else 0.92


func _ray_to_y_plane(origin: Vector3, dir: Vector3, y_plane: float) -> Vector3:
	if absf(dir.y) < 0.0001:
		return Vector3.ZERO
	var t: float = (y_plane - origin.y) / dir.y
	if t < 0.0:
		return Vector3.ZERO
	return origin + dir * t
