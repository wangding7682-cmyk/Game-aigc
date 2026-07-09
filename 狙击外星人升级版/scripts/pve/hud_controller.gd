extends Node

signal fire_pressed
signal scan_pressed
signal time_extend_pressed
signal zoom_in_pressed
signal zoom_out_pressed
signal back_pressed

var battle_core = null
var camera_controller = null
var visual_feedback = null

var hud = null


func setup(core, camera, feedback, hud_scene) -> void:
	battle_core = core
	camera_controller = camera
	visual_feedback = feedback

	hud = hud_scene
	_connect_hud_signals()
	_refresh_display()


func update() -> void:
	if battle_core == null or not is_instance_valid(battle_core):
		return
	if camera_controller == null or not is_instance_valid(camera_controller):
		return
	if visual_feedback == null or not is_instance_valid(visual_feedback):
		return
	_refresh_display()


func _connect_hud_signals() -> void:
	if hud == null or not is_instance_valid(hud):
		return

	hud.fire_pressed.connect(_on_hud_fire_pressed)
	hud.scan_pressed.connect(_on_hud_scan_pressed)
	hud.time_extend_pressed.connect(_on_hud_time_extend_pressed)
	hud.zoom_in_pressed.connect(_on_hud_zoom_in_pressed)
	hud.zoom_out_pressed.connect(_on_hud_zoom_out_pressed)
	hud.back_pressed.connect(_on_hud_back_pressed)


func _refresh_display() -> void:
	if hud == null or not is_instance_valid(hud):
		return

	hud.update_state(build_hud_state())


func build_hud_state() -> Dictionary:
	var weapon_config = battle_core.weapon if battle_core.weapon != null else null
	var viewport_size: Vector2 = Vector2.ZERO
	if camera_controller.camera != null and is_instance_valid(camera_controller.camera) and camera_controller.camera.get_viewport() != null:
		viewport_size = camera_controller.camera.get_viewport().get_visible_rect().size
	var aim_pos: Vector2 = camera_controller.aim_screen_position if camera_controller.scope_visible else (viewport_size * 0.5)
	var spread_radius: float = 28.0
	if weapon_config != null:
		spread_radius = camera_controller.get_spread_radius_screen_px(
			battle_core.hold_ratio,
			weapon_config.spread_idle,
			weapon_config.spread_hold
		)

	var shot_result: String = "idle"
	var shot_flash: float = 0.0
	var muzzle_flash: float = 0.0
	var slowmo: bool = false
	var killcam_active: bool = false
	var misjudgment_active: bool = false
	if visual_feedback != null and is_instance_valid(visual_feedback):
		shot_result = visual_feedback.last_shot_result
		shot_flash = clampf(1.0 - (visual_feedback.recoil_timer / maxf(visual_feedback.recoil_duration, 0.001)), 0.0, 1.0) if visual_feedback.recoil_timer > 0.0 else 0.0
		muzzle_flash = shot_flash
		slowmo = visual_feedback.slowmo_until_msec > 0
		killcam_active = visual_feedback.killcam_active
		misjudgment_active = visual_feedback.misjudgment_review_active

	var feedback_messages: Array = []
	var last_id_replay: String = ""
	var id_replay_text: String = ""
	var scan_feedback_ratio: float = 0.0
	if visual_feedback != null and is_instance_valid(visual_feedback):
		feedback_messages = visual_feedback.get_feedback_messages()
		last_id_replay = visual_feedback.last_identification_replay
		id_replay_text = visual_feedback.last_identification_replay if visual_feedback.identification_replay_timer > 0.0 else ""
		if visual_feedback.has_method("get_scan_feedback_ratio"):
			scan_feedback_ratio = float(visual_feedback.call("get_scan_feedback_ratio"))

	return {
		"remaining_time": battle_core.remaining_time,
		"elapsed_time": battle_core.elapsed_time,
		"lives": battle_core.lives,
		"killed_targets": battle_core.killed_targets,
		"total_targets": battle_core.total_targets,
		"scan_count": battle_core.scan_count,
		"time_extend_count": battle_core.time_extend_count,
		"zoom": camera_controller.current_zoom,
		"hold_ratio": battle_core.hold_ratio,
		"weapon_ready": battle_core.weapon_ready,
		"feedback_messages": feedback_messages,
		"identification_replay": last_id_replay,
		"search_hint": _build_search_hint(),
		"interaction_hint": _build_interaction_hint(),
		"scope_visible": camera_controller.scope_visible,
		"aim_screen_position": aim_pos,
		"spread_radius_px": spread_radius,
		"shot_flash_ratio": shot_flash,
		"shot_result": shot_result,
		"muzzle_flash_ratio": muzzle_flash,
		"scan_feedback_ratio": scan_feedback_ratio,
		"slowmo_active": slowmo,
		"killcam_active": killcam_active,
		"misjudgment_active": misjudgment_active,
		"crosshair_style": str(CoreGameState.player_feel_settings.get("crosshair_style", "plus")),
		"crosshair_color": str(CoreGameState.player_feel_settings.get("crosshair_color", "amber")),
		"hold_vignette_strength": float(CoreGameState.player_feel_settings.get("hold_vignette_strength", 1.0)),
		"search_hint_text": _build_search_hint(),
		"identification_replay_text": id_replay_text,
		"time_extend_sec": 15.0,
		"wrong_identification_time_penalty": 8.0,
	}


func show_result(result: Dictionary) -> void:
	if hud == null or not is_instance_valid(hud):
		return
	hud.show_result(result)


func _build_search_hint() -> String:
	if battle_core.tutorial_primary_target != null and is_instance_valid(battle_core.tutorial_primary_target) and battle_core.tutorial_primary_target.alive and _is_primary_target_in_focus():
		return battle_core.tutorial_primary_target.get_suspicion_summary()

	var observed_actor = _get_observed_actor()
	if observed_actor != null and is_instance_valid(observed_actor):
		return observed_actor.get_suspicion_summary()

	if visual_feedback != null and is_instance_valid(visual_feedback) and visual_feedback.locator_hint_timer > 0.0 and visual_feedback.locator_target != null and is_instance_valid(visual_feedback.locator_target) and visual_feedback.locator_target.alive:
		return "定位线索：最可疑目标在%s，留意它的红眼与肩线异常。" % _describe_direction_from_camera(visual_feedback.locator_target.global_position)

	return "搜索提示：优先找红眼脉冲、肩线歪斜和胸口微弱闪动的目标。"


func _build_interaction_hint() -> String:
	if visual_feedback != null and is_instance_valid(visual_feedback):
		if visual_feedback.killcam_active:
			return "击杀回放中：镜头正在跟随子弹命中外星人。"

		if visual_feedback.misjudgment_review_active:
			return "误判复盘中：镜头正在回看被误击目标的真实特征。"

	if not battle_core.weapon_ready:
		return "后坐恢复中：镜头已退回搜索态，请重新定位外星人。"

	if CoreGameState.is_tutorial_active():
		var step_data: Dictionary = CoreGameState.get_tutorial_step_data()
		return "教程目标：%s" % str(step_data.get("expected_text", ""))

	if camera_controller.current_zoom < 1.12:
		return "左键拖动画面观察，双击左键或滚轮放大进入瞄准。"

	if camera_controller.camera_locked:
		return "屏息锁定中：准星随呼吸晃动，等稳定后松手开火。"

	return "已进入瞄准：鼠标移动即准星移动，靠近屏幕边缘自动扫视，按住左键/Shift屏息，松开火。"


func _get_observed_actor():
	if camera_controller == null or not is_instance_valid(camera_controller) or battle_core == null or not is_instance_valid(battle_core):
		return null
	var observation_center = camera_controller.get_aim_world_position()
	var observation_center_2d: Vector2 = _to_plane_vector(observation_center)
	var max_distance: float = 128.0 if not camera_controller.scope_visible else 86.0
	var nearest_actor = null
	var nearest_distance: float = INF

	for actor in battle_core.active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue

		var actor_pos_2d: Vector2 = _to_plane_vector(actor.global_position)
		var distance: float = actor_pos_2d.distance_to(observation_center_2d)
		if distance <= max_distance and distance < nearest_distance:
			nearest_actor = actor
			nearest_distance = distance

	return nearest_actor


func _to_plane_vector(pos) -> Vector2:
	if pos is Vector2:
		return pos
	elif pos is Vector3:
		return Vector2(pos.x, pos.z)
	return Vector2.ZERO


func _is_primary_target_in_focus() -> bool:
	var focus_radius_world := lerpf(180.0, 90.0, clampf((camera_controller.current_zoom - 1.0) / 0.6, 0.0, 1.0))
	var target_pos_2d: Vector2 = _to_plane_vector(battle_core.tutorial_primary_target.global_position)
	var camera_pos_2d: Vector2 = _to_plane_vector(camera_controller.camera.position)
	return target_pos_2d.distance_to(camera_pos_2d) <= focus_radius_world


func _describe_direction_from_camera(target_pos) -> String:
	var target_2d: Vector2 = _to_plane_vector(target_pos)
	var camera_2d: Vector2 = _to_plane_vector(camera_controller.camera.position)
	var delta: Vector2 = target_2d - camera_2d
	var horizontal := ""
	var vertical := ""

	if delta.x < -40.0:
		horizontal = "左侧"
	elif delta.x > 40.0:
		horizontal = "右侧"

	if delta.y < -40.0:
		vertical = "上方"
	elif delta.y > 40.0:
		vertical = "下方"

	if not horizontal.is_empty() and not vertical.is_empty():
		return "%s%s" % [vertical, horizontal]
	if not vertical.is_empty():
		return vertical
	if not horizontal.is_empty():
		return horizontal
	return "正前方"


func _on_hud_fire_pressed() -> void:
	fire_pressed.emit()


func _on_hud_scan_pressed() -> void:
	scan_pressed.emit()


func _on_hud_time_extend_pressed() -> void:
	time_extend_pressed.emit()


func _on_hud_zoom_in_pressed() -> void:
	zoom_in_pressed.emit()


func _on_hud_zoom_out_pressed() -> void:
	zoom_out_pressed.emit()


func _on_hud_back_pressed() -> void:
	back_pressed.emit()
