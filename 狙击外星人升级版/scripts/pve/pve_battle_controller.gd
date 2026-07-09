extends "res://scripts/pve/pve_battle_controller_base.gd"

const HudScene = preload("res://scenes/ui/ui_hud_pve.tscn")
const TargetActor = preload("res://scripts/pve/pve_target_controller.gd")
const TutorialScene = preload("res://scenes/tutorial/tutorial_flow_intro.tscn")
const CoverObstacle = preload("res://scripts/pve/pve_cover_obstacle.gd")

@onready var aim_camera: Camera2D = $AimCamera
@onready var world_root: Node2D = $WorldRoot

var camera_controller = null
var weapon = null
var battle_core = null
var input_handler = null
var visual_feedback = null
var battle_mode = null
var hud_controller = null

var world_limits := Rect2(-800.0, -450.0, 1600.0, 900.0)
var cover_obstacles: Array = []


func _ready() -> void:
	level_config = CoreGameState.get_level_config()
	_init_modules()
	_setup_battle_mode()
	_spawn_cover_obstacles()
	mount_hud(HudScene)
	mount_tutorial(TutorialScene)
	_setup_hud_connections()
	_setup_intro_focus()
	push_feedback("%s\n%s" % [level_config.display_name, level_config.flavor_text], Color(0.92, 0.95, 1.0))
	log_level_entered()


func _init_modules() -> void:
	camera_controller = preload("res://scripts/pve/camera_controller.gd").new()
	camera_controller.camera = aim_camera
	add_child(camera_controller)

	weapon = preload("res://scripts/pve/weapon.gd").new()
	weapon.setup_from_profile(CoreGameState.get_weapon_profile())
	add_child(weapon)

	battle_core = preload("res://scripts/pve/battle_core.gd").new()
	add_child(battle_core)

	input_handler = preload("res://scripts/pve/input_handler.gd").new()
	add_child(input_handler)

	visual_feedback = preload("res://scripts/pve/visual_feedback.gd").new()
	add_child(visual_feedback)

	hud_controller = preload("res://scripts/pve/hud_controller.gd").new()
	add_child(hud_controller)


func _setup_battle_mode() -> void:
	battle_mode = preload("res://scripts/pve/battle_mode_pve.gd").new()
	battle_mode.setup(level_config, weapon)
	add_child(battle_mode)

	battle_mode.initialize_controllers(battle_core, camera_controller, input_handler, visual_feedback)
	battle_mode.start_battle()

	for actor in battle_core.active_actors:
		world_root.add_child(actor)

	battle_mode.battle_finished.connect(_on_battle_finished)


func _setup_hud_connections() -> void:
	if hud == null or not is_instance_valid(hud):
		return

	hud_controller.setup(battle_core, camera_controller, visual_feedback, hud)

	hud_controller.fire_pressed.connect(_on_fire_pressed)
	hud_controller.scan_pressed.connect(_on_scan_pressed)
	hud_controller.time_extend_pressed.connect(_on_time_extend_pressed)
	hud_controller.zoom_in_pressed.connect(_on_zoom_in_pressed)
	hud_controller.zoom_out_pressed.connect(_on_zoom_out_pressed)
	hud_controller.back_pressed.connect(func() -> void:
		CoreGameState.record_first_exit("battle_hud_back")
		CoreEventBus.log_event("battle_exited", {
			"level_id": level_config.level_id,
			"entry": "hud_back_button",
		})
		CoreEventBus.main_menu_requested.emit()
	)


func _spawn_cover_obstacles() -> void:
	for obstacle in cover_obstacles:
		if obstacle != null and is_instance_valid(obstacle):
			obstacle.queue_free()
	cover_obstacles.clear()

	if not level_config.cover_entries_2d.is_empty():
		for entry in level_config.cover_entries_2d:
			if entry == null:
				continue
			_add_cover(Rect2(Vector2(entry.position), Vector2(entry.size)))
		return

	var cover_count := int(level_config.cover_budget_2d)
	if cover_count < 0:
		cover_count = clampi(int(level_config.required_targets) + 1, 3, 7)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(cover_count):
		var pos := Vector2(
			rng.randf_range(world_limits.position.x + 120.0, world_limits.position.x + world_limits.size.x - 260.0),
			rng.randf_range(world_limits.position.y + 80.0, world_limits.position.y + world_limits.size.y - 220.0)
		)
		var size := Vector2(rng.randf_range(110.0, 180.0), rng.randf_range(160.0, 280.0))
		_add_cover(Rect2(pos, size))


func _add_cover(rect: Rect2) -> void:
	var obstacle = CoverObstacle.new()
	obstacle.position = rect.position
	obstacle.z_index = 20
	obstacle.setup(rect.size, Color(0.20, 0.22, 0.26, 0.92))
	world_root.add_child(obstacle)
	cover_obstacles.append(obstacle)


func _setup_intro_focus() -> void:
	if battle_core.tutorial_primary_target != null and is_instance_valid(battle_core.tutorial_primary_target):
		tutorial_primary_target = battle_core.tutorial_primary_target
		if not CoreGameState.is_tutorial_active():
			camera_controller.focus_on_world_position(battle_core.tutorial_primary_target.global_position + Vector2(-180.0, 60.0))


func _process(delta: float) -> void:
	if battle_core.battle_closed:
		return

	battle_mode.update(delta)

	cover_scan_fade_timer = maxf(0.0, cover_scan_fade_timer - delta)
	update_cover_fade(cover_obstacles)
	_update_hud()


func _input(event: InputEvent) -> void:
	if handle_common_input(event):
		return
	battle_mode.handle_input_event(event)


func _update_hud() -> void:
	hud_controller.update()


func _on_fire_pressed() -> void:
	input_handler.fire_requested.emit()


func _on_scan_pressed() -> void:
	if not battle_core.use_scan():
		visual_feedback.push_feedback("扫描次数已用完。", Color(0.92, 0.74, 0.40))
		return

	cover_scan_fade_total = weapon.scan_highlight_sec
	cover_scan_fade_timer = cover_scan_fade_total
	update_cover_fade(cover_obstacles)


func _on_time_extend_pressed() -> void:
	input_handler.time_extend_requested.emit()


func _on_zoom_in_pressed() -> void:
	input_handler.zoom_in_requested.emit()


func _on_zoom_out_pressed() -> void:
	input_handler.zoom_out_requested.emit()


func _on_battle_finished(result: Dictionary) -> void:
	hud_controller.show_result(result)
	battle_finished.emit(result)


func _build_search_hint() -> String:
	if battle_core.tutorial_primary_target != null and is_instance_valid(battle_core.tutorial_primary_target) and battle_core.tutorial_primary_target.alive and _is_primary_target_in_focus():
		return battle_core.tutorial_primary_target.get_suspicion_summary()

	var observed_actor = _get_observed_actor()
	if observed_actor != null and is_instance_valid(observed_actor):
		return observed_actor.get_suspicion_summary()

	if visual_feedback.locator_hint_timer > 0.0 and visual_feedback.locator_target != null and is_instance_valid(visual_feedback.locator_target) and visual_feedback.locator_target.alive:
		return "定位线索：最可疑目标在%s，留意它的红眼与肩线异常。" % describe_direction_from_position(camera_controller.camera.position, visual_feedback.locator_target.global_position)

	return "搜索提示：优先找红眼脉冲、肩线歪斜和胸口微弱闪动的目标。"


func _build_interaction_hint() -> String:
	if visual_feedback.killcam_active:
		return "击杀回放中：镜头正在跟随子弹命中外星人。"

	if visual_feedback.misjudgment_review_active:
		return "误判复盘中：镜头正在回看被误击目标的真实特征。"

	if not battle_core.weapon_ready:
		return "后坐恢复中：镜头已退回搜索态，请重新定位外星人。"

	if is_tutorial_active():
		var step_data: Dictionary = CoreGameState.get_tutorial_step_data()
		return "教程目标：%s" % str(step_data.get("expected_text", ""))

	if camera_controller.current_zoom < 1.12:
		return "左键拖动画面观察，双击左键或滚轮放大进入瞄准。"

	if input_handler.right_hold_active or Input.is_action_pressed("aim_hold"):
		return "屏息中：把准星移到目标身上，松开右键或按空格开火。"

	return "已进入瞄准：长按屏息稳定准星，松手或单击开火。"


func _get_observed_actor():
	var observation_center: Vector2 = camera_controller.get_aim_world_position()
	var max_distance: float = 128.0 if not camera_controller.scope_visible else 86.0
	var nearest_actor = null
	var nearest_distance: float = INF

	for actor in battle_core.active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue

		var distance: float = actor.global_position.distance_to(observation_center)
		if distance <= max_distance and distance < nearest_distance:
			nearest_actor = actor
			nearest_distance = distance

	return nearest_actor


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


func _debug_focus_tutorial_target() -> void:
	if battle_core.tutorial_primary_target == null or not is_instance_valid(battle_core.tutorial_primary_target):
		return

	camera_controller.focus_on_world_position(battle_core.tutorial_primary_target.global_position)


func _debug_shoot_primary_target() -> void:
	if battle_core.tutorial_primary_target == null or not is_instance_valid(battle_core.tutorial_primary_target):
		return

	camera_controller.focus_on_world_position(battle_core.tutorial_primary_target.global_position)
	camera_controller.set_zoom(maxf(camera_controller.current_zoom, 1.35))
	battle_core.hold_ratio = 1.0

	var aim_world_point: Vector2 = camera_controller.get_aim_world_position()
	battle_core.shoot(aim_world_point)


func _debug_shoot_first_civilian() -> void:
	for actor in battle_core.active_actors:
		if is_instance_valid(actor) and actor.actor_kind == "civilian" and actor.alive:
			camera_controller.focus_on_world_position(actor.global_position)
			camera_controller.set_zoom(maxf(camera_controller.current_zoom, 1.35))
			battle_core.hold_ratio = 1.0

			var aim_world_point: Vector2 = camera_controller.get_aim_world_position()
			battle_core.shoot(aim_world_point)
			return


func _debug_get_camera_motion_bounds() -> Dictionary:
	return camera_controller.get_camera_motion_bounds()


func _debug_get_aim_world_coverage() -> Dictionary:
	return camera_controller.get_aim_world_coverage()


func _debug_step_edge_auto_pan(edge: String) -> Dictionary:
	return camera_controller.step_edge_auto_pan(edge)


func _debug_is_weapon_ready() -> bool:
	return battle_core.weapon_ready


func _debug_finish_post_shot_recover() -> void:
	battle_core.weapon_ready = true
	visual_feedback.finish_post_shot_recover()


func _debug_get_slowmo_state() -> Dictionary:
	return visual_feedback.get_slowmo_state()


func _debug_finish_slowmo() -> void:
	visual_feedback.finish_slowmo()


func _debug_get_search_state() -> Dictionary:
	return {
		"hint": _build_search_hint(),
		"has_locator": visual_feedback.locator_target != null and is_instance_valid(visual_feedback.locator_target) and visual_feedback.locator_target.alive,
	}


func _debug_get_identification_feedback_state() -> Dictionary:
	return {
		"combo_count": battle_core.recognition_combo_count,
		"combo_bonus_gold": battle_core.recognition_combo_bonus_gold,
		"replay_text": visual_feedback.last_identification_replay,
		"replay_active": visual_feedback.identification_replay_timer > 0.0,
		"misjudgment_review_active": visual_feedback.misjudgment_review_active,
	}


func _debug_shoot_next_target() -> void:
	for actor in battle_core.active_actors:
		if is_instance_valid(actor) and actor.actor_kind == "target" and actor.alive:
			camera_controller.focus_on_world_position(actor.global_position)
			camera_controller.set_zoom(maxf(camera_controller.current_zoom, 1.35))
			battle_core.hold_ratio = 1.0

			var aim_world_point: Vector2 = camera_controller.get_aim_world_position()
			battle_core.shoot(aim_world_point)
			return


func _debug_trigger_civilian_false_clue() -> Dictionary:
	for actor in battle_core.active_actors:
		if is_instance_valid(actor) and actor.actor_kind == "civilian" and actor.alive:
			actor.trigger_false_clue(3.0)
			return {
				"summary": actor.get_suspicion_summary(),
				"active": actor.has_false_clue_active(),
			}

	return {
		"summary": "",
		"active": false,
	}


func _debug_get_killcam_state() -> Dictionary:
	return visual_feedback.get_killcam_state()


func _debug_finish_killcam() -> void:
	visual_feedback.finish_killcam()


func _debug_finish_misjudgment_review() -> void:
	visual_feedback.finish_misjudgment_review()
