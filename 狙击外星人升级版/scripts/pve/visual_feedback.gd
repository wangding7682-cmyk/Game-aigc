extends Node

var battle_core = null
var camera_controller = null

var killcam_active: bool = false
var killcam_timer: float = 0.0
var killcam_duration: float = 1.45
var killcam_zoom: float = 1.85
var killcam_actor = null
var killcam_start_world: Vector2 = Vector2.ZERO
var killcam_target_world: Vector2 = Vector2.ZERO

var misjudgment_review_active: bool = false
var misjudgment_review_timer: float = 0.0
var misjudgment_review_duration: float = 1.9
var misjudgment_review_actor = null

var slowmo_until_msec: int = 0
var slowmo_target_scale: float = 0.35
var slowmo_min_duration: float = 0.45
var slowmo_max_duration: float = 0.6

var recoil_timer: float = 0.0
var recoil_duration: float = 0.18
var recoil_offset: Vector2 = Vector2.ZERO

var post_shot_recover_timer: float = 0.0
var post_shot_recover_duration: float = 0.24

var last_shot_from_world: Vector2 = Vector2.ZERO

var feedback_messages: Array[Dictionary] = []
var feedback_lifespan_sec: float = 3.5

var last_identification_replay: String = ""
var identification_replay_timer: float = 0.0

var locator_target = null
var locator_hint_timer: float = 0.0

var last_shot_result: String = "idle"
var shot_result_timer: float = 0.0
var shot_result_duration: float = 0.35

func setup(core, camera) -> void:
	battle_core = core
	camera_controller = camera
	_connect_signals()


func _connect_signals() -> void:
	if battle_core == null:
		return

	battle_core.target_hit.connect(_on_target_hit)
	battle_core.wrong_hit.connect(_on_wrong_hit)
	battle_core.target_missed.connect(_on_target_missed)
	battle_core.shot_blocked.connect(_on_shot_blocked)
	battle_core.scan_used.connect(_on_scan_used)
	battle_core.time_extend_used.connect(_on_time_extend_used)


func process(delta: float) -> void:
	if battle_core == null or not is_instance_valid(battle_core):
		return
	if battle_core.battle_closed:
		return

	if killcam_active:
		_update_killcam(delta)
		return

	if misjudgment_review_active:
		_update_misjudgment_review(delta)
		return

	if recoil_timer > 0.0:
		recoil_timer -= delta
		if recoil_timer <= 0.0:
			recoil_timer = 0.0
			recoil_offset = Vector2.ZERO

	if post_shot_recover_timer > 0.0:
		post_shot_recover_timer -= delta

	if slowmo_until_msec > 0 and Time.get_ticks_msec() >= slowmo_until_msec:
		_restore_time_scale()

	if locator_hint_timer > 0.0:
		locator_hint_timer -= delta

	if identification_replay_timer > 0.0:
		identification_replay_timer -= delta

	if shot_result_timer > 0.0:
		shot_result_timer -= delta
		if shot_result_timer <= 0.0:
			last_shot_result = "idle"

	for i in range(feedback_messages.size() - 1, -1, -1):
		feedback_messages[i]["lifetime"] -= delta
		if feedback_messages[i]["lifetime"] <= 0.0:
			feedback_messages.remove_at(i)


func begin_killcam(actor, shot_from_world: Vector2) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	killcam_active = true
	killcam_timer = killcam_duration
	killcam_actor = actor
	killcam_start_world = shot_from_world
	killcam_target_world = actor.get_impact_focus_point()

	_set_time_scale(slowmo_target_scale)
	slowmo_until_msec = Time.get_ticks_msec() + int(killcam_duration * 1000.0)


func finish_killcam() -> void:
	if not killcam_active:
		return

	killcam_active = false
	_restore_time_scale()
	finish_post_shot_recover()

	if battle_core != null and is_instance_valid(battle_core):
		battle_core.confirm_victory()


func begin_misjudgment_review(actor) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	misjudgment_review_active = true
	misjudgment_review_timer = misjudgment_review_duration

	_set_time_scale(slowmo_target_scale)
	slowmo_until_msec = Time.get_ticks_msec() + int(misjudgment_review_duration * 1000.0)
	camera_controller.focus_on_world_position(actor.global_position)


func finish_misjudgment_review() -> void:
	if not misjudgment_review_active:
		return

	misjudgment_review_active = false
	_restore_time_scale()


func begin_post_shot_recover(recoil_dur: float, recover_dur: float) -> void:
	recoil_duration = recoil_dur
	post_shot_recover_duration = recover_dur

	recoil_timer = recoil_duration
	post_shot_recover_timer = post_shot_recover_duration

	recoil_offset = Vector2.RIGHT.rotated(RandomNumberGenerator.new().randf_range(0.0, TAU)) * 6.0


func finish_post_shot_recover() -> void:
	recoil_timer = 0.0
	post_shot_recover_timer = 0.0
	recoil_offset = Vector2.ZERO
	if camera_controller != null and battle_core != null and battle_core.weapon != null:
		camera_controller.set_zoom(float(battle_core.weapon.zoom_default))
	battle_core.weapon_ready = true


func trigger_slowmo() -> void:
	var duration: float = slowmo_min_duration + RandomNumberGenerator.new().randf_range(0.0, slowmo_max_duration - slowmo_min_duration)
	_set_time_scale(slowmo_target_scale)
	slowmo_until_msec = Time.get_ticks_msec() + int(duration * 1000.0)


func push_feedback(text: String, color: Color = Color.WHITE) -> void:
	feedback_messages.append({
		"text": text,
		"color": color,
		"lifetime": feedback_lifespan_sec,
		"time": Time.get_ticks_msec(),
	})


func set_identification_replay(text: String, duration: float = 1.6) -> void:
	last_identification_replay = text
	identification_replay_timer = duration


func set_locator_hint(target, duration: float = 3.0) -> void:
	locator_target = target
	locator_hint_timer = duration


func get_feedback_messages() -> Array[Dictionary]:
	return feedback_messages.duplicate()


func get_killcam_state() -> Dictionary:
	return {
		"active": killcam_active,
		"timer": killcam_timer,
	}


func get_slowmo_state() -> Dictionary:
	return {
		"active": slowmo_until_msec > 0,
		"engine_time_scale": Engine.time_scale,
	}


func finish_slowmo() -> void:
	_restore_time_scale()


func finish_post_shot_recover_immediate() -> void:
	post_shot_recover_timer = 0.0
	finish_post_shot_recover()


func _update_killcam(delta: float) -> void:
	killcam_timer -= delta
	if killcam_timer <= 0.0:
		finish_killcam()
		return

	var progress := 1.0 - (killcam_timer / maxf(killcam_duration, 0.001))
	progress = clampf(progress, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - progress, 2.4)
	var cinematic_target := killcam_target_world

	if killcam_actor != null and is_instance_valid(killcam_actor):
		cinematic_target = killcam_actor.get_impact_focus_point()

	camera_controller.camera.position = killcam_start_world.lerp(cinematic_target, eased)
	camera_controller.set_zoom(lerpf(maxf(float(battle_core.weapon.zoom_default), 1.05), killcam_zoom, eased))


func _update_misjudgment_review(delta: float) -> void:
	misjudgment_review_timer -= delta
	if misjudgment_review_timer <= 0.0:
		finish_misjudgment_review()


func _set_time_scale(scale: float) -> void:
	Engine.time_scale = scale


func _restore_time_scale() -> void:
	Engine.time_scale = 1.0


func _on_target_hit(actor, _hit_point: Vector2, reward: int) -> void:
	trigger_slowmo()
	begin_post_shot_recover(battle_core.weapon.recoil_duration, battle_core.weapon.post_shot_recover_duration)
	battle_core.weapon_ready = false
	begin_killcam(actor, last_shot_from_world)
	push_feedback("击杀成功！+%d金币" % reward, Color(0.58, 1.0, 0.72))
	last_shot_result = "hit"
	shot_result_timer = shot_result_duration


func _on_wrong_hit(actor, _hit_point: Vector2) -> void:
	battle_core.weapon_ready = false
	begin_post_shot_recover(battle_core.weapon.recoil_duration, battle_core.weapon.post_shot_recover_duration)
	begin_misjudgment_review(actor)
	push_feedback("误伤平民！生命-1，时间-8秒", Color(1.0, 0.55, 0.55))
	last_shot_result = "wrong_hit"
	shot_result_timer = shot_result_duration


func _on_target_missed(_hit_point: Vector2) -> void:
	push_feedback("未命中目标", Color(1.0, 0.85, 0.55))
	last_shot_result = "miss"
	shot_result_timer = shot_result_duration


func _on_shot_blocked(_actor, _hit_point: Vector2) -> void:
	push_feedback("攻击被格挡", Color(1.0, 0.7, 0.55))
	last_shot_result = "cover"
	shot_result_timer = shot_result_duration


func _on_scan_used(_remaining: int) -> void:
	push_feedback("扫描生效！外星人弱点已高亮，掩体暂时半透明。", Color(0.68, 0.9, 1.0))


func _on_time_extend_used(_remaining: int, added_time: float) -> void:
	push_feedback("时间+%d秒" % int(added_time), Color(0.68, 0.9, 1.0))
