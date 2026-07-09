extends "res://scripts/pve/battle_mode.gd"

var battle_core_3d = null
var camera_3d = null
var visual_feedback_3d = null
var input_handler_3d = null
var hold_tutorial_reported_3d: bool = false

var world_root: Node3D = null
var actor_root: Node3D = null
var rng_3d: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mode_id = "pve_3d"
	mode_name = "PVE对战(3D)"
	mode_description = "3D版本PVE狙击对战模式"
	rng_3d.randomize()


func setup_3d(level_cfg, weapon_obj, world_3d: Node3D, actor_root_3d: Node3D = null) -> void:
	level_config = level_cfg
	weapon = weapon_obj
	world_root = world_3d
	actor_root = actor_root_3d if actor_root_3d != null else world_3d


func initialize_controllers_3d(core_3d, cam_3d, input_h, feedback_3d) -> void:
	battle_core_3d = core_3d
	battle_core = core_3d
	camera_3d = cam_3d
	camera_controller = null
	input_handler_3d = input_h
	input_handler = input_h
	visual_feedback_3d = feedback_3d
	visual_feedback = feedback_3d


func start_battle_3d() -> void:
	battle_closed = false

	camera_3d.setup(weapon.get_profile(), world_root, camera_3d.camera)
	battle_core_3d.setup_3d(level_config, weapon, camera_3d, world_root)
	if actor_root != null:
		battle_core_3d.world_root = actor_root
	input_handler_3d.setup(battle_core_3d, camera_3d)
	visual_feedback_3d.setup_3d(battle_core_3d, camera_3d)

	if camera_3d.camera != null and camera_3d.camera.get_viewport() != null:
		var vp_center: Vector2 = camera_3d.camera.get_viewport().get_visible_rect().size * 0.5
		camera_3d.set_base_aim_screen_position(vp_center)
	else:
		camera_3d.set_base_aim_screen_position(Vector2(960, 540))

	battle_core_3d.spawn_actors_3d()

	input_handler_3d.fire_requested.connect(_on_fire_requested)
	input_handler_3d.scan_requested.connect(_on_scan_requested)
	input_handler_3d.time_extend_requested.connect(_on_time_extend_requested)
	input_handler_3d.zoom_in_requested.connect(_on_zoom_in_requested)
	input_handler_3d.zoom_out_requested.connect(_on_zoom_out_requested)

	battle_core_3d.battle_finished.connect(_on_battle_finished)


func end_battle(_success: bool, _reason: String) -> void:
	battle_closed = true


func update_3d(delta: float) -> void:
	if battle_closed:
		return
	if battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return
	if visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d):
		return
	if camera_3d == null or not is_instance_valid(camera_3d):
		return

	battle_core_3d.update(delta)
	_update_breathing(delta)
	_update_input(delta)
	visual_feedback_3d.update_3d(delta)

	_check_tutorial_target_focus_3d()


func _get_current_mouse_pos() -> Vector2:
	if camera_3d != null and is_instance_valid(camera_3d) and camera_3d.camera != null and is_instance_valid(camera_3d.camera) and camera_3d.camera.get_viewport() != null:
		return camera_3d.camera.get_viewport().get_mouse_position()
	return Vector2.ZERO


func _update_input(delta: float) -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return
	if visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d):
		return
	if camera_3d == null or not is_instance_valid(camera_3d):
		return
	if weapon == null:
		return
	if input_handler_3d == null or not is_instance_valid(input_handler_3d):
		return
	if battle_core_3d.battle_closed or visual_feedback_3d.killcam_active or visual_feedback_3d.misjudgment_review_active:
		return

	var mouse_pos: Vector2 = _get_current_mouse_pos()
	var in_scope: bool = camera_3d.scope_visible

	if not in_scope:
		var movement: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		if movement.length() > 0.0:
			camera_3d.move_camera(movement, delta)
			_handle_camera_move_tutorial_3d(movement)
	else:
		camera_3d.set_base_aim_screen_position(mouse_pos)
		camera_3d.update_edge_pan(mouse_pos, delta)
		var movement: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		if movement.length() > 0.0:
			camera_3d.move_camera(movement, delta)

	var hold_key_pressed: bool = Input.is_action_pressed("aim_hold")
	if left_pointer_down and in_scope and not left_pointer_dragging:
		hold_duration += delta
	else:
		hold_duration = 0.0
	var left_hold_in_scope: bool = left_pointer_down and in_scope and not left_pointer_dragging and hold_duration >= 0.15
	var hold_requested: bool = battle_core_3d.weapon_ready and in_scope and (hold_key_pressed or left_hold_in_scope)

	if hold_requested:
		camera_3d.set_camera_locked(true)
		if _can_execute_tutorial_action_3d(&"aim_hold"):
			battle_core_3d.hold_ratio = min(1.0, battle_core_3d.hold_ratio + delta / float(weapon.hold_stabilize_sec))
			if battle_core_3d.hold_ratio >= 0.55 and not hold_tutorial_reported_3d:
				hold_tutorial_reported_3d = true
				_try_progress_tutorial(&"aim_hold")
		else:
			battle_core_3d.hold_ratio = max(0.0, battle_core_3d.hold_ratio - delta / float(weapon.aim_recover_sec))
	else:
		camera_3d.set_camera_locked(false)
		hold_tutorial_reported_3d = false
		battle_core_3d.hold_ratio = max(0.0, battle_core_3d.hold_ratio - delta / float(weapon.aim_recover_sec))

	if battle_core_3d.weapon_ready and Input.is_action_just_pressed("aim_zoom_in") and _can_execute_tutorial_action_3d(&"aim_zoom_in"):
		camera_3d.adjust_zoom(weapon.zoom_step)
		_try_progress_tutorial(&"aim_zoom_in")

	if battle_core_3d.weapon_ready and Input.is_action_just_pressed("aim_zoom_out") and _can_execute_tutorial_action_3d(&"aim_zoom_out"):
		camera_3d.adjust_zoom(-weapon.zoom_step)
		_try_progress_tutorial(&"aim_zoom_out")

	if Input.is_action_just_pressed("use_scan") and _can_execute_tutorial_action_3d(&"use_scan"):
		_on_scan_requested()

	if Input.is_action_just_pressed("use_time_extend") and _can_execute_tutorial_action_3d(&"use_time_extend"):
		_on_time_extend_requested()


func handle_input_event_3d(event: InputEvent) -> void:
	if battle_closed:
		return
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d) or camera_3d == null or not is_instance_valid(camera_3d):
		return

	if event is InputEventMouseButton:
		_handle_mouse_button_3d(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion_3d(event)


func _update_breathing(delta: float) -> void:
	if camera_3d == null or not is_instance_valid(camera_3d) or battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return
	camera_3d.update_breathing_sway(delta, battle_core_3d.hold_ratio)


var left_pointer_down: bool = false
var left_pointer_dragging: bool = false
var left_press_position: Vector2 = Vector2.ZERO
var hold_duration: float = 0.0


func _handle_mouse_button_3d(event: InputEventMouseButton) -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d) or camera_3d == null or not is_instance_valid(camera_3d) or weapon == null or input_handler_3d == null or not is_instance_valid(input_handler_3d):
		return
	if battle_core_3d.battle_closed or visual_feedback_3d.killcam_active or visual_feedback_3d.misjudgment_review_active:
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if battle_core_3d.weapon_ready and _can_execute_tutorial_action_3d(&"aim_zoom_in"):
			camera_3d.adjust_zoom_at_screen(event.position, weapon.zoom_step)
			_try_progress_tutorial(&"aim_zoom_in")
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if battle_core_3d.weapon_ready and _can_execute_tutorial_action_3d(&"aim_zoom_out"):
			camera_3d.adjust_zoom_at_screen(event.position, -weapon.zoom_step)
			_try_progress_tutorial(&"aim_zoom_out")
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			if battle_core_3d.weapon_ready and _can_execute_tutorial_action_3d(&"aim_zoom_in"):
				var target_zoom: float = maxf(camera_3d.current_zoom, camera_3d.zoom_quick_aim)
				camera_3d.set_zoom_at_screen(event.position, target_zoom)
				_try_progress_tutorial(&"aim_zoom_in")
			left_pointer_down = false
			left_pointer_dragging = false
			return

		if event.pressed:
			left_pointer_down = true
			left_pointer_dragging = false
			left_press_position = event.position
		else:
			if camera_3d.scope_visible:
				if left_pointer_down and not left_pointer_dragging:
					_on_fire_requested()
			left_pointer_down = false
			left_pointer_dragging = false
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if not battle_core_3d.weapon_ready:
				return
			if not camera_3d.scope_visible:
				return
			input_handler_3d.right_hold_active = true
			input_handler_3d.right_last_press_msec = Time.get_ticks_msec()
		else:
			input_handler_3d.right_hold_active = false
		return


func _handle_mouse_motion_3d(event: InputEventMouseMotion) -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d) or camera_3d == null or not is_instance_valid(camera_3d):
		return
	if battle_core_3d.battle_closed or visual_feedback_3d.killcam_active or visual_feedback_3d.misjudgment_review_active:
		return

	if not camera_3d.scope_visible:
		if left_pointer_down:
			if not left_pointer_dragging and event.position.distance_to(left_press_position) > 8.0:
				left_pointer_dragging = true
			if left_pointer_dragging:
				camera_3d.drag_camera_by_motion(event.relative)
				_handle_camera_move_tutorial_3d(-event.relative)


func _on_fire_requested() -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d) or camera_3d == null or not is_instance_valid(camera_3d) or weapon == null:
		return
	if visual_feedback_3d.killcam_active or visual_feedback_3d.misjudgment_review_active:
		return

	if not battle_core_3d.weapon_ready:
		return

	if not _can_execute_tutorial_action_3d(&"fire"):
		return

	if not camera_3d.scope_visible:
		visual_feedback_3d.push_feedback("先放大进入瞄准状态后再开火。", Color(1.0, 0.8, 0.42))
		return

	var aim_pos: Vector2 = camera_3d.aim_screen_position
	var spread_px: float = camera_3d.get_spread_radius_screen_px(battle_core_3d.hold_ratio, weapon.spread_idle, weapon.spread_hold)
	var jitter: Vector2 = Vector2.RIGHT.rotated(rng_3d.randf_range(0.0, TAU)) * rng_3d.randf_range(0.0, spread_px)
	var jittered: Vector2 = aim_pos + jitter

	var cam_node: Camera3D = camera_3d.camera
	if cam_node == null or not is_instance_valid(cam_node):
		return
	var origin: Vector3 = cam_node.project_ray_origin(jittered)
	var dir: Vector3 = cam_node.project_ray_normal(jittered).normalized()

	visual_feedback_3d.last_shot_from_world_3d = origin
	visual_feedback_3d.last_shot_dir = dir

	var pre_hit_point: Vector3 = _ray_ground_intersect(origin, dir, 50.0)
	if cam_node.get_world_3d() != null:
		var space: PhysicsDirectSpaceState3D = cam_node.get_world_3d().direct_space_state
		if space != null:
			var pre_q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 200.0)
			pre_q.collision_mask = 1 | 2 | 4
			var pre_hit: Dictionary = space.intersect_ray(pre_q)
			if not pre_hit.is_empty():
				pre_hit_point = pre_hit.get("position", pre_hit_point)
	visual_feedback_3d.last_shot_hit_point = pre_hit_point

	var cam_pos: Vector3 = cam_node.global_position
	var muzzle_pos: Vector3 = cam_pos + dir * 1.5
	var active_trail: Dictionary = visual_feedback_3d.spawn_bullet_trail(muzzle_pos, pre_hit_point, dir)

	var shot_result: Dictionary = battle_core_3d.shoot_3d(jittered, origin, dir)
	_trigger_shot_effect(shot_result, dir, active_trail)
	_try_progress_tutorial(&"fire")


func _on_scan_requested() -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d) or weapon == null:
		return
	if not battle_core_3d.use_scan_3d(weapon.scan_highlight_sec):
		visual_feedback_3d.push_feedback("扫描道具已用完", Color(1.0, 0.7, 0.55))
		return
	_try_progress_tutorial(&"use_scan")


func _on_time_extend_requested() -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d):
		return
	if not battle_core_3d.use_time_extend():
		visual_feedback_3d.push_feedback("时间道具已用完", Color(1.0, 0.7, 0.55))
		return
	_try_progress_tutorial(&"use_time_extend")


func _on_zoom_in_requested() -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or camera_3d == null or not is_instance_valid(camera_3d) or weapon == null:
		return
	if not battle_core_3d.weapon_ready:
		return
	camera_3d.adjust_zoom(weapon.zoom_step)


func _on_zoom_out_requested() -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or camera_3d == null or not is_instance_valid(camera_3d) or weapon == null:
		return
	if not battle_core_3d.weapon_ready:
		return
	camera_3d.adjust_zoom(-weapon.zoom_step)


func _on_battle_finished(result: Dictionary) -> void:
	battle_closed = true
	battle_finished.emit(result)


func _check_tutorial_target_focus_3d() -> void:
	if not CoreGameState.is_tutorial_active():
		return
	if battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return

	if battle_core_3d.tutorial_primary_target == null or not is_instance_valid(battle_core_3d.tutorial_primary_target) or not battle_core_3d.tutorial_primary_target.alive:
		return

	if _is_primary_target_in_focus_3d():
		_try_progress_tutorial(&"focus_target")


func _is_primary_target_in_focus_3d() -> bool:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d) or camera_3d == null or not is_instance_valid(camera_3d):
		return false
	if battle_core_3d.tutorial_primary_target == null or not is_instance_valid(battle_core_3d.tutorial_primary_target):
		return false
	var cam_node: Camera3D = camera_3d.camera
	if cam_node == null or not is_instance_valid(cam_node) or cam_node.get_viewport() == null:
		return false
	var target_pos: Vector3 = battle_core_3d.tutorial_primary_target.global_position
	var screen_pos: Vector2 = cam_node.unproject_position(target_pos)
	var aim_pos: Vector2 = camera_3d.aim_screen_position
	var viewport_size: Vector2 = cam_node.get_viewport().get_visible_rect().size
	var focus_radius_screen: float = lerpf(
		viewport_size.x * 0.18,
		viewport_size.x * 0.12,
		clampf((camera_3d.current_zoom - 1.0) / 0.6, 0.0, 1.0)
	)
	var delta: Vector2 = screen_pos - aim_pos
	return delta.length() <= focus_radius_screen


func _try_progress_tutorial(action_name: StringName) -> void:
	if not CoreGameState.is_tutorial_active():
		return
	if battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return
	if visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d):
		return

	var progress: Dictionary = CoreGameState.try_progress_tutorial(action_name, {
		"elapsed_time": battle_core_3d.elapsed_time,
	})
	if not bool(progress.get("progressed", false)):
		return

	if bool(progress.get("completed", false)):
		_refresh_tutorial_ui(progress)
		visual_feedback_3d.push_feedback("教程完成，道具和战斗操作已全部开放。", Color(0.58, 1.0, 0.72))
		return

	var next_step: Dictionary = progress.get("step", {})
	_refresh_tutorial_ui(progress)
	visual_feedback_3d.push_feedback("教程推进：%s" % str(next_step.get("title", "")), Color(0.68, 0.9, 1.0))


func _handle_camera_move_tutorial_3d(movement: Vector2) -> void:
	if not CoreGameState.is_tutorial_active():
		return

	var action_name: StringName = StringName()
	if absf(movement.x) >= absf(movement.y):
		action_name = &"camera_right" if movement.x > 0.0 else &"camera_left"
	else:
		action_name = &"camera_down" if movement.y > 0.0 else &"camera_up"
	_try_progress_tutorial(action_name)


func _can_execute_tutorial_action_3d(action_name: StringName) -> bool:
	if not CoreGameState.is_tutorial_active():
		return true
	if CoreGameState.is_tutorial_action_unlocked(action_name):
		return true
	_show_tutorial_blocked_3d()
	return false


func _show_tutorial_blocked_3d() -> void:
	if visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d):
		return
	var step_data: Dictionary = CoreGameState.get_tutorial_step_data()
	visual_feedback_3d.push_feedback("教程未完成：先%s" % str(step_data.get("expected_text", "")), Color(1.0, 0.72, 0.72))
	var parent_controller = get_parent()
	if parent_controller == null or not is_instance_valid(parent_controller):
		return
	var tutorial_flow = parent_controller.get("tutorial_flow")
	if tutorial_flow != null and is_instance_valid(tutorial_flow) and tutorial_flow.has_method("show_blocked_action"):
		tutorial_flow.show_blocked_action(step_data)


func _refresh_tutorial_ui(progress: Dictionary) -> void:
	var parent_controller = get_parent()
	if parent_controller == null or not is_instance_valid(parent_controller):
		return
	var tutorial_flow = parent_controller.get("tutorial_flow")
	if tutorial_flow == null or not is_instance_valid(tutorial_flow):
		return
	if bool(progress.get("completed", false)):
		if tutorial_flow.has_method("show_completed"):
			tutorial_flow.show_completed()
		return
	var next_step: Dictionary = progress.get("step", {})
	if tutorial_flow.has_method("show_step"):
		tutorial_flow.show_step(next_step)


func _trigger_shot_effect(shot_result: Dictionary, _shot_dir: Vector3, active_trail: Dictionary = {}) -> void:
	if visual_feedback_3d == null or not is_instance_valid(visual_feedback_3d):
		return
	var result_type: String = str(shot_result.get("result", "miss"))
	var hit_point: Vector3 = shot_result.get("hit_point", Vector3.ZERO)
	var hit_normal: Vector3 = shot_result.get("hit_normal", Vector3.UP)
	var hit_actor = shot_result.get("actor", null)

	var effect_type: String = ""
	match result_type:
		"hit", "wrong_hit":
			effect_type = result_type
		"ineffective":
			effect_type = "ground"
		"blocked":
			effect_type = "blocked"
		"foliage":
			effect_type = "foliage"
		"miss":
			effect_type = "ground"

	var obstacle_hit_callback: Callable = Callable()
	if result_type == "blocked" and hit_actor != null and is_instance_valid(hit_actor) and hit_actor is PveCoverObstacle3D:
		var obstacle: PveCoverObstacle3D = hit_actor as PveCoverObstacle3D
		var obstacle_style: String = obstacle.style_id
		var blast_tier: String = _resolve_cover_blast_tier()
		match obstacle_style:
			"parked_van":
				effect_type = "metal"
			"billboard", "street_lamp":
				effect_type = "metal"
			_:
				effect_type = "concrete"
		obstacle_hit_callback = obstacle.apply_impact_feedback.bind(hit_point, hit_normal, effect_type, blast_tier)

	if not active_trail.is_empty():
		active_trail["hit_effect_type"] = effect_type
		active_trail["hit_normal"] = hit_normal
		if hit_point != Vector3.ZERO:
			active_trail["to"] = hit_point
			active_trail["dist"] = maxf(active_trail["from"].distance_to(hit_point), 1.0)
		var callbacks: Array = active_trail.get("on_arrive_callbacks", [])
		if obstacle_hit_callback.is_valid():
			callbacks.append(obstacle_hit_callback)
			visual_feedback_3d.add_pending_hit_callback(obstacle_hit_callback)
		var visual_hit_cb: Callable = shot_result.get("visual_hit_callback", Callable())
		if visual_hit_cb is Callable and visual_hit_cb.is_valid():
			callbacks.append(visual_hit_cb)
			visual_feedback_3d.add_pending_hit_callback(visual_hit_cb)
		if not callbacks.is_empty():
			active_trail["on_arrive_callbacks"] = callbacks


func _resolve_cover_blast_tier() -> String:
	if weapon != null:
		var weapon_tier: String = str(weapon.get("cover_blast_tier"))
		if weapon_tier in ["light", "medium", "heavy"]:
			return weapon_tier
		if weapon.has_method("get_profile"):
			var weapon_profile: Dictionary = weapon.get_profile()
			var profile_tier: String = str(weapon_profile.get("cover_blast_tier", "medium"))
			if profile_tier in ["light", "medium", "heavy"]:
				return profile_tier
	return "medium"


func debug_get_cover_blast_tier() -> String:
	return _resolve_cover_blast_tier()


func _ray_ground_intersect(origin: Vector3, dir: Vector3, fallback_dist: float) -> Vector3:
	if absf(dir.y) > 0.0001:
		var t: float = (0.0 - origin.y) / dir.y
		if t > 0.0 and t < 200.0:
			return origin + dir * t
	return origin + dir * fallback_dist
