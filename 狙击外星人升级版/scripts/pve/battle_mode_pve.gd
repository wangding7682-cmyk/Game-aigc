extends "res://scripts/pve/battle_mode.gd"


func _ready() -> void:
	mode_id = "pve"
	mode_name = "PVE对战"
	mode_description = "标准PVE狙击对战模式"


func start_battle() -> void:
	battle_closed = false

	camera_controller.setup(weapon.get_profile(), level_config.world_limits)
	battle_core.setup(level_config, weapon, camera_controller)
	input_handler.setup(battle_core, camera_controller)
	visual_feedback.setup(battle_core, camera_controller)

	battle_core.spawn_actors()

	for actor in battle_core.active_actors:
		get_tree().current_scene.add_child(actor)

	input_handler.fire_requested.connect(_on_fire_requested)
	input_handler.scan_requested.connect(_on_scan_requested)
	input_handler.time_extend_requested.connect(_on_time_extend_requested)
	input_handler.weapon_switch_next.connect(_on_weapon_switch_next)
	input_handler.weapon_switch_prev.connect(_on_weapon_switch_prev)

	battle_core.battle_finished.connect(_on_battle_finished)


func end_battle(success: bool, reason: String) -> void:
	battle_closed = true


func update(delta: float) -> void:
	if battle_closed:
		return

	battle_core.update(delta)
	input_handler.process_input(delta)
	visual_feedback.process(delta)

	_check_tutorial_target_focus()


func handle_input_event(event: InputEvent) -> void:
	if battle_closed:
		return

	if event is InputEventMouseButton:
		input_handler.handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		input_handler.handle_mouse_motion(event)


func _on_fire_requested() -> void:
	if visual_feedback.killcam_active or visual_feedback.misjudgment_review_active:
		return

	if not battle_core.weapon_ready:
		return

	var aim_world_point: Vector2 = camera_controller.get_aim_world_position()
	visual_feedback.last_shot_from_world = aim_world_point
	battle_core.shoot(aim_world_point)


func _on_scan_requested() -> void:
	if not battle_core.use_scan():
		visual_feedback.push_feedback("扫描道具已用完", Color(1.0, 0.7, 0.55))


func _on_time_extend_requested() -> void:
	if not battle_core.use_time_extend():
		visual_feedback.push_feedback("时间道具已用完", Color(1.0, 0.7, 0.55))


func _on_weapon_switch_next() -> void:
	var new_weapon_id := WeaponManager.switch_to_next_weapon()
	var new_weapon_config := WeaponManager.get_weapon_config(new_weapon_id)
	if new_weapon_config:
		weapon.setup_from_profile(new_weapon_config.get_profile())
		camera_controller.setup(weapon.get_profile(), level_config.world_limits)
		visual_feedback.push_feedback("已切换: %s" % new_weapon_config.display_name, Color(0.68, 0.9, 1.0))


func _on_weapon_switch_prev() -> void:
	var new_weapon_id := WeaponManager.switch_to_previous_weapon()
	var new_weapon_config := WeaponManager.get_weapon_config(new_weapon_id)
	if new_weapon_config:
		weapon.setup_from_profile(new_weapon_config.get_profile())
		camera_controller.setup(weapon.get_profile(), level_config.world_limits)
		visual_feedback.push_feedback("已切换: %s" % new_weapon_config.display_name, Color(0.68, 0.9, 1.0))


func _on_battle_finished(result: Dictionary) -> void:
	battle_closed = true
	battle_finished.emit(result)


func _check_tutorial_target_focus() -> void:
	if not CoreGameState.is_tutorial_active():
		return

	if battle_core.tutorial_primary_target == null or not is_instance_valid(battle_core.tutorial_primary_target) or not battle_core.tutorial_primary_target.alive:
		return

	if _is_primary_target_in_focus():
		_try_progress_tutorial(&"focus_target")


func _is_primary_target_in_focus() -> bool:
	if camera_controller == null or camera_controller.camera == null or not is_instance_valid(camera_controller.camera):
		return false

	var viewport = camera_controller.camera.get_viewport()
	if viewport == null:
		return false

	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var crosshair_screen_pos: Vector2 = viewport_size * 0.5
	if "aim_screen_position" in camera_controller and bool(camera_controller.scope_visible):
		crosshair_screen_pos = camera_controller.aim_screen_position
	var target_screen_pos: Vector2 = viewport.get_canvas_transform() * battle_core.tutorial_primary_target.global_position
	var crosshair_radius_px: float = 28.0
	return target_screen_pos.distance_to(crosshair_screen_pos) <= crosshair_radius_px


func _try_progress_tutorial(action_name: StringName) -> void:
	if not CoreGameState.is_tutorial_active():
		return

	var progress: Dictionary = CoreGameState.try_progress_tutorial(action_name, {
		"elapsed_time": battle_core.elapsed_time,
	})
	if not bool(progress.get("progressed", false)):
		return

	if bool(progress.get("completed", false)):
		visual_feedback.push_feedback("教程完成，道具和战斗操作已全部开放。", Color(0.58, 1.0, 0.72))
		return

	var next_step: Dictionary = progress.get("step", {})
	visual_feedback.push_feedback("教程推进：%s" % str(next_step.get("title", "")), Color(0.68, 0.9, 1.0))
