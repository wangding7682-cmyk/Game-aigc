extends "res://scripts/pve/visual_feedback.gd"

const HIT_CONFIRM_FRAMES := [
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-01.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-02.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-03.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-04.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-05.svg"),
]
const WRONG_HIT_FRAMES := [
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-01.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-02.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-03.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-04.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-05.svg"),
]
const SCAN_PULSE_FRAMES := [
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-01.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-02.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-03.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-04.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-05.svg"),
]

var camera_3d = null
var battle_core_3d = null
var world_root_3d: Node3D = null
var fx_root_3d: Node3D = null
var decal_root_3d: Node3D = null

var killcam_start_world_3d: Vector3 = Vector3.ZERO
var killcam_target_world_3d: Vector3 = Vector3.ZERO
var killcam_actor_3d = null
var killcam_bullet_dir: Vector3 = Vector3.FORWARD
var killcam_bullet_node: Node3D = null
var killcam_bullet_tip: MeshInstance3D = null
var killcam_bullet_body: MeshInstance3D = null
var killcam_trail_nodes: Array[Dictionary] = []
var killcam_trail_count: int = 14
var killcam_shake: float = 0.0
var pending_feedback: Dictionary = {}
var exit_scope_after_shot: bool = false
var killcam_spin: float = 0.0
var killcam_shot_dist: float = 15.0
var killcam_cam_start: Vector3 = Vector3.ZERO
var killcam_start_zoom: float = 4.0
var killcam_hit_fired: bool = false
var killcam_hit_callbacks: Array = []

var misjudgment_review_start_world_3d: Vector3 = Vector3.ZERO
var misjudgment_review_target_world_3d: Vector3 = Vector3.ZERO
var misjudgment_review_actor_3d = null
var misjudgment_review_hit_fired: bool = false
var misjudgment_review_hit_callbacks: Array = []
var misjudgment_review_hit_normal: Vector3 = Vector3.UP

var last_shot_from_world_3d: Vector3 = Vector3.ZERO
var last_shot_hit_point: Vector3 = Vector3.ZERO
var last_shot_dir: Vector3 = Vector3.FORWARD
var scan_feedback_timer: float = 0.0
const SCAN_FEEDBACK_DURATION: float = 0.45

var hit_effects: Array[Dictionary] = []
var hit_effect_duration: float = 0.6
var scan_wave_effects: Array[Dictionary] = []

var bullet_trails: Array[Dictionary] = []
const BULLET_TRAIL_DURATION: float = 0.22
const BULLET_TRAIL_SEGMENTS: int = 16

func _get_current_trail_config() -> Dictionary:
	var skin_config = null
	if WeaponManager != null and WeaponManager.get_equipped_skin() != null:
		skin_config = WeaponManager.get_equipped_skin()
	var effect_type := "default"
	var ring_count := 2
	var outer_radius := 0.088
	var glow_intensity := 1.0
	var colors: Array[Color] = [Color(1.0, 0.85, 0.45), Color(1.0, 0.65, 0.25)]
	if skin_config != null and skin_config.has_method("get_trail_colors"):
		effect_type = skin_config.trail_effect_type if "trail_effect_type" in skin_config else "default"
		ring_count = skin_config.trail_ring_count if "trail_ring_count" in skin_config else 2
		outer_radius = skin_config.trail_outer_radius if "trail_outer_radius" in skin_config else 0.088
		glow_intensity = skin_config.trail_glow_intensity if "trail_glow_intensity" in skin_config else 1.0
		colors = skin_config.get_trail_colors()
	return {
		"effect_type": effect_type,
		"ring_count": ring_count,
		"outer_radius": outer_radius,
		"glow_intensity": glow_intensity,
		"colors": colors,
	}


func setup_3d(core_3d, camera_3d_ctrl) -> void:
	battle_core_3d = core_3d
	battle_core = core_3d
	camera_3d = camera_3d_ctrl
	camera_controller = null
	world_root_3d = camera_3d.world_root if camera_3d != null else null
	fx_root_3d = camera_3d.fx_root if camera_3d != null else world_root_3d
	decal_root_3d = camera_3d.decal_root if camera_3d != null else world_root_3d
	_connect_signals_3d()


func _connect_signals_3d() -> void:
	if battle_core_3d == null:
		return

	battle_core_3d.target_hit.connect(_on_target_hit_3d)
	battle_core_3d.target_damaged.connect(_on_target_damaged_3d)
	battle_core_3d.ineffective_hit.connect(_on_ineffective_hit_3d)
	battle_core_3d.wrong_hit.connect(_on_wrong_hit_3d)
	battle_core_3d.target_missed.connect(_on_target_missed_3d)
	battle_core_3d.shot_blocked.connect(_on_shot_blocked_3d)
	battle_core_3d.scan_used.connect(_on_scan_used)
	battle_core_3d.time_extend_used.connect(_on_time_extend_used)


func begin_killcam_3d(actor, from_world: Vector3, hit_point: Vector3, shot_dir: Vector3) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not _is_available_for_cinematic():
		return

	killcam_active = true
	killcam_timer = killcam_duration
	killcam_actor_3d = actor
	killcam_actor = actor
	killcam_bullet_dir = shot_dir.normalized()
	killcam_shake = 0.0
	killcam_spin = 0.0
	killcam_hit_fired = false

	var cam_pos_now: Vector3 = camera_3d.camera.global_position if camera_3d != null and camera_3d.camera != null else from_world
	killcam_cam_start = cam_pos_now
	killcam_start_zoom = camera_3d.current_zoom if camera_3d != null else 4.0

	var muzzle_offset: float = 1.5
	killcam_start_world_3d = cam_pos_now + killcam_bullet_dir * muzzle_offset
	killcam_target_world_3d = hit_point
	killcam_start_world = Vector2.ZERO
	killcam_target_world = Vector2.ZERO
	killcam_shot_dist = maxf(killcam_start_world_3d.distance_to(hit_point), 5.0)

	_set_time_scale(slowmo_target_scale)
	slowmo_until_msec = Time.get_ticks_msec() + int(killcam_duration * 1000.0)

	killcam_hit_callbacks.clear()
	for bt in bullet_trails:
		var cbs: Array = bt.get("on_arrive_callbacks", [])
		for cb in cbs:
			if cb is Callable and cb.is_valid():
				killcam_hit_callbacks.append(cb)
		var br: Node3D = bt.get("root", null)
		if is_instance_valid(br):
			br.queue_free()
	bullet_trails.clear()

	_create_killcam_bullet()


func _create_killcam_bullet() -> void:
	if fx_root_3d == null:
		return
	_clear_killcam_bullet()

	var trail_cfg: Dictionary = _get_current_trail_config()
	var is_rainbow: bool = trail_cfg["effect_type"] == "rainbow"
	var trail_colors: Array[Color] = trail_cfg["colors"]
	var color_count: int = trail_colors.size()
	var glow_mult: float = float(trail_cfg.get("glow_intensity", 1.0))

	var bullet := Node3D.new()
	bullet.position = killcam_start_world_3d
	fx_root_3d.add_child(bullet)
	bullet.look_at(killcam_start_world_3d + killcam_bullet_dir, Vector3.UP)
	killcam_bullet_node = bullet

	var tip := MeshInstance3D.new()
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.040
	cone_mesh.height = 0.20
	tip.mesh = cone_mesh
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = trail_colors[0] if color_count > 0 else Color(1.0, 0.85, 0.45)
	tip_mat.emission_enabled = true
	tip_mat.emission = (trail_colors[0] if color_count > 0 else Color(1.0, 0.78, 0.32)) * (4.5 * glow_mult)
	tip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tip.material_override = tip_mat
	tip.rotation_degrees = Vector3(-90, 0, 0)
	tip.position.z = -0.10
	bullet.add_child(tip)
	killcam_bullet_tip = tip

	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.036
	body_mesh.bottom_radius = 0.032
	body_mesh.height = 0.14
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = trail_colors[0].lerp(trail_colors[1] if color_count > 1 else trail_colors[0], 0.5) if color_count > 0 else Color(0.95, 0.78, 0.32)
	body_mat.emission_enabled = true
	body_mat.emission = (trail_colors[0] if color_count > 0 else Color(1.0, 0.68, 0.22)) * (2.5 * glow_mult)
	body_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	body.material_override = body_mat
	body.rotation_degrees = Vector3(-90, 0, 0)
	body.position.z = 0.07
	bullet.add_child(body)
	killcam_bullet_body = body

	if is_rainbow:
		var halo_rings: int = int(trail_cfg.get("ring_count", 4))
		var halo_radius: float = float(trail_cfg.get("outer_radius", 0.16))
		for ri in range(halo_rings):
			var ring_t: float = float(ri) / float(maxf(halo_rings - 1, 1))
			var ring_color_idx: int = ri % color_count
			var ring_color: Color = trail_colors[ring_color_idx]
			var ring_offset: float = -0.05 - float(ri) * 0.025
			var ring := MeshInstance3D.new()
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = halo_radius * (0.55 + ring_t * 0.45)
			ring_mesh.outer_radius = halo_radius * (0.75 + ring_t * 0.45)
			ring_mesh.radial_segments = 16
			ring_mesh.rings = 24
			ring.mesh = ring_mesh
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, 0.85)
			ring_mat.emission_enabled = true
			ring_mat.emission = ring_color * (2.8 * glow_mult * (0.6 + ring_t * 0.4))
			ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ring.material_override = ring_mat
			ring.rotation_degrees = Vector3(0, 0, 0)
			ring.position.z = ring_offset
			ring.set_meta("is_halo_ring", true)
			ring.set_meta("ring_index", ri)
			ring.set_meta("base_offset", ring_offset)
			ring.set_meta("ring_color", ring_color)
			bullet.add_child(ring)

	for i in range(killcam_trail_count):
		var trail := MeshInstance3D.new()
		var t_mesh := SphereMesh.new()
		var t: float = float(i) / float(killcam_trail_count)
		var base_r: float = 0.056 * (1.0 - t * 0.5)
		if is_rainbow:
			base_r *= 1.2
		t_mesh.radius = base_r
		t_mesh.height = base_r * 0.5
		trail.mesh = t_mesh
		var t_mat := StandardMaterial3D.new()
		var color_idx: int = i % color_count
		var trail_color: Color = trail_colors[color_idx]
		var bright: float = 0.5 + 0.5 * (1.0 - t)
		if is_rainbow:
			t_mat.albedo_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.85 * (1.0 - t * 0.55))
			t_mat.emission_enabled = true
			t_mat.emission = trail_color * (2.6 * glow_mult * (1.0 - t * 0.3))
		else:
			t_mat.albedo_color = Color(1.0, 0.9 * bright, 0.5 * bright, 0.8 * (1.0 - t * 0.6))
			t_mat.emission_enabled = true
			t_mat.emission = Color(1.0, 0.78, 0.35) * (2.2 * (1.0 - t * 0.4))
		t_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		t_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail.material_override = t_mat
		trail.position = killcam_start_world_3d
		trail.scale = Vector3(1.0, 0.35, 1.0)
		fx_root_3d.add_child(trail)
		var angle_offset: float = float(i) * 0.85
		if is_rainbow:
			angle_offset = float(i) * (TAU / float(maxf(color_count, 1))) + float(i) * 0.25
		var spiral_r: float = 0.08 * (1.0 - t * 0.7)
		if is_rainbow:
			spiral_r = float(trail_cfg.get("outer_radius", 0.12)) * (0.7 + 0.3 * float(color_idx) / float(maxf(color_count - 1, 1))) * (1.0 - t * 0.6)
		killcam_trail_nodes.append({
			"node": trail,
			"base_t": t,
			"angle_offset": angle_offset,
			"spiral_r": spiral_r,
			"color_idx": color_idx,
			"color": trail_color,
		})


func _clear_killcam_bullet() -> void:
	if killcam_bullet_node != null and is_instance_valid(killcam_bullet_node):
		killcam_bullet_node.queue_free()
	killcam_bullet_node = null
	killcam_bullet_tip = null
	killcam_bullet_body = null
	for td in killcam_trail_nodes:
		var tn: MeshInstance3D = td.get("node", null)
		if is_instance_valid(tn):
			tn.queue_free()
	killcam_trail_nodes.clear()


func begin_misjudgment_review_3d(actor) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not _is_available_for_cinematic():
		return

	misjudgment_review_active = true
	misjudgment_review_timer = misjudgment_review_duration
	misjudgment_review_actor_3d = actor
	misjudgment_review_start_world_3d = camera_3d.camera.global_position if camera_3d and camera_3d.camera else Vector3.ZERO
	misjudgment_review_target_world_3d = actor.get_impact_focus_point()
	misjudgment_review_hit_fired = false

	misjudgment_review_hit_callbacks.clear()
	for bt in bullet_trails:
		var cbs: Array = bt.get("on_arrive_callbacks", [])
		for cb in cbs:
			if cb is Callable and cb.is_valid():
				misjudgment_review_hit_callbacks.append(cb)
		var hit_n: Vector3 = bt.get("hit_normal", Vector3.UP)
		if hit_n != Vector3.UP:
			misjudgment_review_hit_normal = hit_n

	_set_time_scale(slowmo_target_scale)
	slowmo_until_msec = Time.get_ticks_msec() + int(misjudgment_review_duration * 1000.0)

	var review_text: String = actor.get_identification_review()
	last_identification_replay = "误判回放：%s" % review_text
	identification_replay_timer = misjudgment_review_duration + 0.6


func finish_killcam() -> void:
	killcam_active = false
	killcam_actor_3d = null
	killcam_actor = null
	killcam_shake = 0.0
	_clear_killcam_bullet()
	_restore_time_scale()
	_reset_camera_after_cinematic()
	finish_post_shot_recover()

	if battle_core_3d != null and is_instance_valid(battle_core_3d):
		battle_core_3d.confirm_victory()


func finish_misjudgment_review() -> void:
	misjudgment_review_active = false
	misjudgment_review_actor_3d = null
	_restore_time_scale()
	_reset_camera_after_cinematic()


func _reset_camera_after_cinematic() -> void:
	if camera_3d != null:
		camera_3d._exit_scope_mode()
		camera_3d.set_camera_locked(false)
	battle_core_3d.weapon_ready = true
	recoil_timer = 0.0
	post_shot_recover_timer = 0.0
	recoil_offset = Vector2.ZERO

	if not pending_feedback.is_empty():
		push_feedback(pending_feedback["text"], pending_feedback["color"])
		pending_feedback.clear()


func finish_post_shot_recover() -> void:
	recoil_timer = 0.0
	post_shot_recover_timer = 0.0
	recoil_offset = Vector2.ZERO
	battle_core_3d.weapon_ready = true
	if exit_scope_after_shot:
		exit_scope_after_shot = false
		if camera_3d != null and camera_3d.scope_visible:
			camera_3d._exit_scope_mode()
			camera_3d.set_camera_locked(false)


func add_pending_hit_callback(cb: Callable) -> void:
	if not cb.is_valid():
		return
	if killcam_active:
		killcam_hit_callbacks.append(cb)
	elif misjudgment_review_active:
		misjudgment_review_hit_callbacks.append(cb)
	else:
		for bt in bullet_trails:
			var cbs: Array = bt.get("on_arrive_callbacks", [])
			cbs.append(cb)
			bt["on_arrive_callbacks"] = cbs
			return


func _has_pending_hit_arrival_path() -> bool:
	return killcam_active or misjudgment_review_active or not bullet_trails.is_empty()


func _queue_arrival_sfx(event_id: String) -> void:
	if AudioService == null or not AudioService.has_method("play_sfx"):
		return
	if _has_pending_hit_arrival_path():
		add_pending_hit_callback(Callable(self, "_play_arrival_sfx").bind(event_id))
		return
	_play_arrival_sfx(event_id)


func _play_arrival_sfx(event_id: String) -> void:
	if AudioService != null and AudioService.has_method("play_sfx"):
		AudioService.play_sfx(event_id)


func update_3d(delta: float) -> void:
	if battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return
	if battle_core_3d.battle_closed:
		return

	if killcam_active:
		_update_killcam_3d(delta)
		if killcam_timer <= 0.0:
			finish_killcam()

	if misjudgment_review_active:
		_update_misjudgment_review_3d(delta)
		if misjudgment_review_timer <= 0.0:
			finish_misjudgment_review()

	if slowmo_until_msec > 0 and Time.get_ticks_msec() >= slowmo_until_msec:
		_restore_time_scale()

	if post_shot_recover_timer > 0.0:
		post_shot_recover_timer = maxf(0.0, post_shot_recover_timer - delta)
		if post_shot_recover_timer <= 0.0 and not _is_cinematic_active():
			finish_post_shot_recover()

	if recoil_timer > 0.0:
		recoil_timer = maxf(0.0, recoil_timer - delta)
		if recoil_timer <= 0.0:
			recoil_offset = Vector2.ZERO

	if locator_hint_timer > 0.0:
		locator_hint_timer -= delta

	if identification_replay_timer > 0.0:
		identification_replay_timer -= delta

	if shot_result_timer > 0.0:
		shot_result_timer -= delta
		if shot_result_timer <= 0.0:
			last_shot_result = "idle"
	if scan_feedback_timer > 0.0:
		scan_feedback_timer = maxf(0.0, scan_feedback_timer - delta)

	_update_hit_effects(delta)
	_update_scan_wave_effects(delta)
	_update_bullet_trails(delta)
	_update_feedback_messages(delta)


func _update_killcam_3d(delta: float) -> void:
	killcam_timer -= delta
	if killcam_timer <= 0.0:
		return

	var progress: float = 1.0 - (killcam_timer / maxf(killcam_duration, 0.001))
	progress = clampf(progress, 0.0, 1.0)
	var cinematic_target: Vector3 = killcam_target_world_3d

	if killcam_actor_3d != null and is_instance_valid(killcam_actor_3d):
		cinematic_target = killcam_actor_3d.get_impact_focus_point()

	var _unused_dist: float = maxf(killcam_start_world_3d.distance_to(cinematic_target), 1.0)
	var D: float = killcam_shot_dist
	var bullet_t: float
	var cam_blend: float
	var cam_behind_factor: float
	var cam_height_factor: float
	var zoom_val: float
	var shake: float = 0.0

	if progress < 0.12:
		var t: float = progress / 0.12
		bullet_t = ease(t, 2.4) * 0.08
		cam_blend = ease(t, 2.0) * 0.35
		cam_behind_factor = lerpf(0.25, 0.30, t)
		cam_height_factor = lerpf(0.20, 0.18, t)
		zoom_val = lerpf(killcam_start_zoom, killcam_start_zoom * 1.15, t)
	elif progress < 0.80:
		var t: float = (progress - 0.12) / 0.68
		bullet_t = 0.08 + ease(t, 1.1) * 0.72
		cam_blend = 0.35 + ease(t, 1.0) * 0.65
		cam_behind_factor = lerpf(0.30, 0.12, t)
		cam_height_factor = lerpf(0.18, 0.10, t)
		zoom_val = lerpf(killcam_start_zoom * 1.15, killcam_start_zoom * 1.8, t)
	else:
		var t: float = (progress - 0.80) / 0.20
		bullet_t = 0.80 + ease(t, 2.2) * 0.20
		cam_blend = 1.0
		cam_behind_factor = lerpf(0.12, 0.06, t)
		cam_height_factor = lerpf(0.10, 0.05, t)
		zoom_val = lerpf(killcam_start_zoom * 1.8, killcam_start_zoom * 2.5, t)
		shake = sin(t * PI * 6.0) * 0.025 * t

	var bullet_pos: Vector3 = killcam_start_world_3d.lerp(cinematic_target, clampf(bullet_t, 0.0, 1.0))
	var bullet_forward: Vector3 = killcam_bullet_dir

	var cam_behind: float = D * cam_behind_factor
	var cam_height: float = D * cam_height_factor
	var follow_pos: Vector3 = bullet_pos - bullet_forward * cam_behind + Vector3.UP * cam_height
	var look_target: Vector3 = bullet_pos.lerp(cinematic_target, 0.3)
	var cam_pos: Vector3 = killcam_cam_start.lerp(follow_pos, cam_blend)

	if killcam_bullet_node != null and is_instance_valid(killcam_bullet_node):
		killcam_bullet_node.position = bullet_pos
		killcam_bullet_node.look_at(bullet_pos + bullet_forward, Vector3.UP)
		killcam_spin += delta * 40.0
		killcam_bullet_node.rotate(bullet_forward, killcam_spin)

		var trail_cfg: Dictionary = _get_current_trail_config()
		var is_rainbow: bool = trail_cfg["effect_type"] == "rainbow"

		for child in killcam_bullet_node.get_children():
			if child is MeshInstance3D and bool(child.get_meta("is_halo_ring", false)):
				var ring_idx: int = int(child.get_meta("ring_index", 0))
				var _base_off: float = float(child.get_meta("base_offset", 0.0))
				var _ring_color: Color = child.get_meta("ring_color", Color.WHITE)
				var pulse: float = 0.85 + 0.15 * sin(killcam_spin * 3.0 + float(ring_idx) * 0.7)
				child.scale = Vector3.ONE * pulse
				if child.material_override is StandardMaterial3D:
					var fade: float = 1.0
					if bullet_t > 0.85:
						fade = 1.0 - (bullet_t - 0.85) / 0.15
					child.material_override.albedo_color.a = maxf(0.85 * fade, 0.0)

		var trail_t: float = clampf(bullet_t, 0.0, 1.0)
		var k_up: Vector3 = Vector3.UP
		if absf(bullet_forward.y) > 0.9:
			k_up = Vector3.RIGHT
		var k_right: Vector3 = bullet_forward.cross(k_up).normalized()
		var k_actual_up: Vector3 = k_right.cross(bullet_forward).normalized()
		for ti in range(killcam_trail_nodes.size()):
			var td: Dictionary = killcam_trail_nodes[ti]
			var trail_node: MeshInstance3D = td.get("node", null)
			if not is_instance_valid(trail_node):
				continue
			var base_t: float = float(td.get("base_t", 0.0))
			var angle_off: float = float(td.get("angle_offset", 0.0))
			var spiral_r: float = float(td.get("spiral_r", 0.03))
			var back_t: float = base_t * 0.20
			var seg_t: float = clampf(trail_t - back_t, 0.0, 1.0)
			var seg_center: Vector3 = killcam_start_world_3d.lerp(cinematic_target, seg_t)
			var spin_speed: float = 2.0
			if is_rainbow:
				spin_speed = 3.5
			var seg_angle: float = killcam_spin * spin_speed + angle_off
			var spiral_offset: Vector3 = (k_right * cos(seg_angle) + k_actual_up * sin(seg_angle)) * spiral_r * (1.0 - trail_t * 0.3)
			trail_node.position = seg_center + spiral_offset
			var fade_scale: float = (1.0 - base_t * 0.5) * (1.0 - trail_t * 0.2)
			if is_rainbow:
				fade_scale *= 1.15
			trail_node.scale = Vector3(1.0, 0.3, 1.0) * maxf(fade_scale, 0.0)
			if trail_node.material_override is StandardMaterial3D:
				var alpha_val: float = 0.8 * (1.0 - trail_t * 0.3) * (1.0 - base_t * 0.6)
				if is_rainbow:
					alpha_val = 0.88 * (1.0 - trail_t * 0.25) * (1.0 - base_t * 0.5)
				trail_node.material_override.albedo_color.a = maxf(alpha_val, 0.0)

		if not killcam_hit_fired and bullet_t >= 0.92:
			var hit_n: Vector3 = Vector3.UP
			if killcam_actor_3d != null and is_instance_valid(killcam_actor_3d):
				hit_n = (killcam_actor_3d.global_position - cinematic_target).normalized()
				if hit_n.length_squared() < 0.01:
					hit_n = Vector3.UP
			for cb in killcam_hit_callbacks:
				if cb is Callable and cb.is_valid():
					cb.call()
			killcam_hit_callbacks.clear()
			spawn_hit_effect(cinematic_target, hit_n, "hit")
			killcam_hit_fired = true

	if camera_3d != null and camera_3d.camera != null:
		if shake > 0.0:
			cam_pos += Vector3(randf_range(-shake, shake), randf_range(-shake, shake), randf_range(-shake, shake))
		camera_3d.camera.global_position = cam_pos
		_safe_look_at(camera_3d.camera, look_target)
		camera_3d.set_zoom(zoom_val)
	killcam_shake = shake


func _update_misjudgment_review_3d(delta: float) -> void:
	misjudgment_review_timer -= delta
	if misjudgment_review_timer <= 0.0:
		return

	var progress: float = 1.0 - (misjudgment_review_timer / maxf(misjudgment_review_duration, 0.001))
	progress = clampf(progress, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - progress, 2.0)

	var target_pos: Vector3 = Vector3.ZERO
	if camera_3d != null and camera_3d.camera != null and misjudgment_review_actor_3d != null and is_instance_valid(misjudgment_review_actor_3d):
		target_pos = misjudgment_review_actor_3d.get_impact_focus_point()
		var start_pos: Vector3 = misjudgment_review_start_world_3d
		camera_3d.camera.global_position = start_pos.lerp(target_pos + Vector3(0.0, 1.2, 0.0), eased)
		_safe_look_at(camera_3d.camera, target_pos)

	if not misjudgment_review_hit_fired and progress >= 0.96:
		misjudgment_review_hit_fired = true
		for cb in misjudgment_review_hit_callbacks:
			if cb is Callable and cb.is_valid():
				cb.call()
		misjudgment_review_hit_callbacks.clear()
		spawn_hit_effect(target_pos, misjudgment_review_hit_normal, "wrong_hit")


func _safe_look_at(cam: Camera3D, target: Vector3) -> void:
	var dir: Vector3 = (target - cam.global_position).normalized()
	var up: Vector3 = Vector3.UP
	if absf(dir.y) > 0.92:
		up = Vector3.RIGHT
	cam.look_at(target, up)


func _update_feedback_messages(delta: float) -> void:
	for i in range(feedback_messages.size() - 1, -1, -1):
		feedback_messages[i]["lifetime"] -= delta
		if feedback_messages[i]["lifetime"] <= 0.0:
			feedback_messages.remove_at(i)


func _is_cinematic_active() -> bool:
	return killcam_active or misjudgment_review_active


func _is_available_for_cinematic() -> bool:
	return not killcam_active and not misjudgment_review_active


func _on_target_hit_3d(actor, _hit_point: Vector2, reward: int) -> void:
	if battle_core_3d != null and battle_core_3d.weapon != null:
		begin_post_shot_recover(battle_core_3d.weapon.recoil_duration, battle_core_3d.weapon.post_shot_recover_duration)
		battle_core_3d.weapon_ready = false
	_queue_arrival_sfx("sfx_shot_hit_target")
	if actor is PveTargetController3D:
		var hit_pt: Vector3 = last_shot_hit_point if last_shot_hit_point != Vector3.ZERO else actor.get_impact_focus_point()
		begin_killcam_3d(actor, last_shot_from_world_3d, hit_pt, last_shot_dir)
	pending_feedback = {"text": "击杀成功！+%d金币" % reward, "color": Color(0.58, 1.0, 0.72)}
	last_shot_result = "hit"
	shot_result_timer = shot_result_duration

	if battle_core_3d != null and is_instance_valid(battle_core_3d) and not killcam_active:
		battle_core_3d.confirm_victory()


func _on_target_damaged_3d(actor, _hit_point: Vector2, remaining_hp: int, max_hp: int) -> void:
	if battle_core_3d != null and battle_core_3d.weapon != null:
		begin_post_shot_recover(battle_core_3d.weapon.recoil_duration, battle_core_3d.weapon.post_shot_recover_duration)
		battle_core_3d.weapon_ready = false
	var has_arrival_path := _has_pending_hit_arrival_path()
	_queue_arrival_sfx("sfx_shot_hit_target")
	exit_scope_after_shot = true
	var hit_pt: Vector3 = last_shot_hit_point
	if hit_pt == Vector3.ZERO and actor is PveTargetController3D:
		hit_pt = actor.get_impact_focus_point()
	if hit_pt != Vector3.ZERO and not has_arrival_path:
		spawn_hit_effect(hit_pt, Vector3.UP, "hit")
	pending_feedback = {"text": "命中目标，剩余 %d/%d" % [remaining_hp, max_hp], "color": Color(1.0, 0.86, 0.48)}
	last_shot_result = "hit"
	shot_result_timer = shot_result_duration


func _on_ineffective_hit_3d(actor, _hit_point: Vector2) -> void:
	if battle_core_3d != null and battle_core_3d.weapon != null:
		begin_post_shot_recover(battle_core_3d.weapon.recoil_duration, battle_core_3d.weapon.post_shot_recover_duration)
		battle_core_3d.weapon_ready = false
	exit_scope_after_shot = true
	var hit_pt: Vector3 = last_shot_hit_point
	if hit_pt == Vector3.ZERO and actor is PveTargetController3D:
		hit_pt = actor.get_impact_focus_point()
	if hit_pt != Vector3.ZERO:
		spawn_hit_effect(hit_pt, Vector3.UP, "ineffective")
	pending_feedback = {"text": "护盾未破，等待弱点暴露", "color": Color(0.7, 0.85, 1.0)}
	last_shot_result = "ineffective"
	shot_result_timer = shot_result_duration


func _on_wrong_hit_3d(actor, _hit_point: Vector2) -> void:
	if battle_core_3d != null and battle_core_3d.weapon != null:
		battle_core_3d.weapon_ready = false
		begin_post_shot_recover(battle_core_3d.weapon.recoil_duration, battle_core_3d.weapon.post_shot_recover_duration)
	_queue_arrival_sfx("sfx_shot_hit_wrong")
	exit_scope_after_shot = true
	if actor is PveTargetController3D:
		begin_misjudgment_review_3d(actor)
	pending_feedback = {"text": "误伤平民！生命-1，时间-8秒", "color": Color(1.0, 0.55, 0.55)}
	last_shot_result = "wrong_hit"
	shot_result_timer = shot_result_duration


func _on_target_missed_3d(_hit_point: Vector2) -> void:
	if battle_core_3d.weapon_ready and battle_core_3d.weapon != null:
		battle_core_3d.weapon_ready = false
		begin_post_shot_recover(battle_core_3d.weapon.recoil_duration, battle_core_3d.weapon.post_shot_recover_duration)
	exit_scope_after_shot = true
	push_feedback("未命中目标", Color(1.0, 0.85, 0.55))
	last_shot_result = "miss"
	shot_result_timer = shot_result_duration


func _on_shot_blocked_3d(_actor, _hit_point: Vector2) -> void:
	if battle_core_3d.weapon_ready and battle_core_3d.weapon != null:
		battle_core_3d.weapon_ready = false
		begin_post_shot_recover(battle_core_3d.weapon.recoil_duration, battle_core_3d.weapon.post_shot_recover_duration)
	if AudioService != null:
		var blocked_hit_point: Vector3 = last_shot_hit_point
		if blocked_hit_point != Vector3.ZERO and AudioService.has_method("play_sfx_3d"):
			AudioService.play_sfx_3d("sfx_shot_hit_wall", blocked_hit_point)
		elif AudioService.has_method("play_sfx"):
			AudioService.play_sfx("sfx_shot_hit_wall")
	exit_scope_after_shot = true
	push_feedback("攻击被格挡", Color(1.0, 0.7, 0.55))
	last_shot_result = "cover"
	shot_result_timer = shot_result_duration


func _on_scan_used(_remaining: int) -> void:
	if AudioService != null and AudioService.has_method("play_sfx"):
		AudioService.play_sfx("sfx_scan_activate")
	push_feedback("扫描生效！外星人弱点已高亮，掩体暂时半透明。", Color(0.68, 0.9, 1.0))
	if battle_core_3d == null or not is_instance_valid(battle_core_3d):
		return
	var scan_center: Vector3 = camera_3d.get_aim_world_position() if camera_3d != null and camera_3d.has_method("get_aim_world_position") else Vector3.ZERO
	scan_center.y = 0.03
	_spawn_scan_ground_ring(scan_center, 0.46, 7.8, 0.52, 0.95)
	_spawn_scan_ground_ring(scan_center, 0.82, 12.8, 0.74, 0.68, 0.08)
	_spawn_scan_ground_ring(scan_center, 1.18, 17.2, 0.92, 0.42, 0.14)
	var best_target = null
	var best_weight: float = -1.0
	for actor in battle_core_3d.active_actors:
		if not is_instance_valid(actor) or not actor.alive or actor.actor_kind != "target":
			continue
		var actor_focus: Vector3 = actor.get_impact_focus_point()
		var dist_ratio := clampf(scan_center.distance_to(actor_focus) / 18.0, 0.0, 1.0)
		if actor.has_method("trigger_scan_burst"):
			actor.call("trigger_scan_burst", 0.9 + (1.0 - dist_ratio) * 0.55, 1.0 - dist_ratio * 0.35)
		_spawn_sequence_effect(actor_focus + Vector3(0.0, 0.28, 0.0), SCAN_PULSE_FRAMES, Color(0.86, 0.96, 1.0, 0.88), 1.35 + (1.0 - dist_ratio) * 0.45, SCAN_FEEDBACK_DURATION + (1.0 - dist_ratio) * 0.08)
		var weight: float = actor.get_locator_weight()
		if weight > best_weight:
			best_weight = weight
			best_target = actor
	if best_target != null:
		locator_target = best_target
		locator_hint_timer = 5.0
		_spawn_sequence_effect(best_target.get_impact_focus_point() + Vector3(0.0, 0.24, 0.0), SCAN_PULSE_FRAMES, Color(0.86, 0.96, 1.0, 0.92), 1.55, SCAN_FEEDBACK_DURATION)
	scan_feedback_timer = SCAN_FEEDBACK_DURATION
	if AudioService != null and AudioService.has_method("play_sfx"):
		AudioService.play_sfx("sfx_scan_reveal")


func spawn_hit_effect(hit_point: Vector3, hit_normal: Vector3, effect_type: String) -> void:
	if fx_root_3d == null:
		return

	# 命中特效（爆闪/火花/冲击波）如果没有配音，会在“子弹轨迹结束→爆炸特效出现”阶段产生明显静音。
	# 这里补一层与特效同帧触发的“命中冲击音”，优先走 3D 位置播放，保证体感和落点一致。
	# 为了让“命中确认 -> 爆炸冲击”更顺，不直接把爆炸音硬贴在同一帧，而是延后极短一拍。
	if AudioService != null and AudioService.has_method("play_sfx_3d_delayed"):
		match effect_type:
			"hit":
				AudioService.play_sfx_3d_delayed("sfx_hit_explosion", hit_point, 0.04)
			"wrong_hit":
				AudioService.play_sfx_3d_delayed("sfx_hit_explosion", hit_point, 0.04)
	elif AudioService != null and AudioService.has_method("play_sfx_3d"):
		match effect_type:
			"hit":
				AudioService.play_sfx_3d("sfx_hit_explosion", hit_point)
			"wrong_hit":
				AudioService.play_sfx_3d("sfx_hit_explosion", hit_point)

	var effect_root := Node3D.new()
	effect_root.position = hit_point
	fx_root_3d.add_child(effect_root)

	var flash_color: Color = Color.WHITE
	var spark_color: Color = Color(1.0, 0.9, 0.6)
	var spark_count: int = 12
	var spark_speed_base: float = 1.5
	var spark_up_bias: float = 0.5
	var dust_color: Color = Color.BLACK
	var has_dust: bool = false
	var has_shockwave: bool = false
	var shockwave_color: Color = Color.WHITE
	var shockwave_radius: float = 1.0

	match effect_type:
		"hit":
			flash_color = Color(0.4, 1.0, 0.5)
			spark_color = Color(1.0, 0.95, 0.5)
			spark_count = 56
			spark_speed_base = 4.5
			spark_up_bias = 0.6
			dust_color = Color(0.6, 0.8, 0.5, 0.8)
			has_dust = true
			has_shockwave = true
			shockwave_color = Color(0.5, 1.0, 0.6, 0.9)
			shockwave_radius = 2.4
		"wrong_hit":
			flash_color = Color(1.0, 0.3, 0.3)
			spark_color = Color(1.0, 0.5, 0.3)
			spark_count = 48
			spark_speed_base = 4.0
			spark_up_bias = 0.5
			dust_color = Color(0.9, 0.4, 0.3, 0.75)
			has_dust = true
			has_shockwave = true
			shockwave_color = Color(1.0, 0.4, 0.4, 0.9)
			shockwave_radius = 2.0
		"ineffective":
			flash_color = Color(0.7, 0.85, 1.0)
			spark_color = Color(0.9, 0.95, 1.0)
			spark_count = 24
			spark_speed_base = 5.5
			spark_up_bias = 0.3
			has_dust = false
			has_shockwave = true
			shockwave_color = Color(0.6, 0.8, 1.0, 0.7)
			shockwave_radius = 1.2
		"blocked":
			flash_color = Color(0.6, 0.8, 1.0)
			spark_color = Color(0.8, 0.9, 1.0)
			spark_count = 32
			spark_speed_base = 5.0
			spark_up_bias = 0.5
			has_dust = true
			dust_color = Color(0.5, 0.65, 0.85, 0.7)
			has_shockwave = true
			shockwave_color = Color(0.7, 0.85, 1.0, 0.8)
			shockwave_radius = 1.6
		"foliage":
			flash_color = Color(0.46, 1.0, 0.58, 0.85)
			spark_color = Color(0.98, 0.88, 0.42, 0.92)
			spark_count = 20
			spark_speed_base = 2.8
			spark_up_bias = 0.7
			dust_color = Color(0.28, 0.62, 0.26, 0.72)
			has_dust = true
			has_shockwave = false
		"ground":
			flash_color = Color(0.65, 0.55, 0.4)
			spark_color = Color(0.55, 0.45, 0.32)
			spark_count = 28
			spark_speed_base = 3.6
			spark_up_bias = 0.4
			dust_color = Color(0.45, 0.38, 0.30, 0.7)
			has_dust = true
			has_shockwave = true
			shockwave_color = Color(0.65, 0.55, 0.4, 0.7)
			shockwave_radius = 1.4
		"concrete":
			flash_color = Color(0.75, 0.72, 0.68)
			spark_color = Color(0.62, 0.58, 0.52)
			spark_count = 36
			spark_speed_base = 4.4
			spark_up_bias = 0.5
			dust_color = Color(0.55, 0.52, 0.48, 0.75)
			has_dust = true
			has_shockwave = true
			shockwave_color = Color(0.7, 0.68, 0.62, 0.8)
			shockwave_radius = 1.8
		"metal":
			flash_color = Color(0.9, 0.85, 0.6)
			spark_color = Color(1.0, 0.92, 0.55)
			spark_count = 44
			spark_speed_base = 6.4
			spark_up_bias = 0.6
			has_shockwave = true
			shockwave_color = Color(1.0, 0.9, 0.6, 0.85)
			shockwave_radius = 1.7

	var tangent: Vector3 = hit_normal.cross(Vector3.UP).normalized()
	if tangent.length_squared() < 0.01:
		tangent = hit_normal.cross(Vector3.RIGHT).normalized()
	var bitangent: Vector3 = hit_normal.cross(tangent).normalized()

	for i in range(spark_count):
		var spark := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.025 + randf() * 0.035
		mesh.height = mesh.radius * 2.0
		spark.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = spark_color
		mat.emission_enabled = true
		mat.emission = spark_color * 1.5
		spark.material_override = mat
		var angle: float = randf() * TAU
		var radial: float = randf() * 0.8 + 0.2
		var speed: float = spark_speed_base + randf() * spark_speed_base
		var vel: Vector3 = (tangent * cos(angle) + bitangent * sin(angle)) * radial * speed + hit_normal * (spark_up_bias + randf() * 0.8)
		spark.set_meta("vel", vel)
		spark.set_meta("scale_start", spark.scale.x)
		effect_root.add_child(spark)

	if has_dust:
		for i in range(6):
			var dust := MeshInstance3D.new()
			var dmesh := SphereMesh.new()
			var dr: float = 0.06 + randf() * 0.08
			dmesh.radius = dr
			dmesh.height = dr * 2.0
			dust.mesh = dmesh
			var dmat := StandardMaterial3D.new()
			dmat.albedo_color = dust_color
			dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			dust.material_override = dmat
			var d_angle: float = randf() * TAU
			var d_speed: float = 0.4 + randf() * 0.8
			var d_radial: float = randf() * 0.9 + 0.1
			var d_vel: Vector3 = (tangent * cos(d_angle) + bitangent * sin(d_angle)) * d_radial * d_speed + Vector3.UP * (0.3 + randf() * 0.5)
			dust.set_meta("vel", d_vel)
			dust.set_meta("is_dust", true)
			dust.set_meta("scale_start", 1.0 + randf() * 0.5)
			effect_root.add_child(dust)

	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	var flash_radius: float = 0.12
	var flash_scale_max: float = 2.5
	if effect_type == "hit" or effect_type == "wrong_hit":
		flash_radius = 0.44
		flash_scale_max = 5.0
	flash_mesh.radius = flash_radius
	flash_mesh.height = flash_radius * 2.0
	flash.mesh = flash_mesh
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = flash_color
	flash_mat.emission_enabled = true
	flash_mat.emission = flash_color * 2.5
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = flash_mat
	flash.set_meta("is_flash", true)
	flash.set_meta("scale_max", flash_scale_max)
	effect_root.add_child(flash)

	if has_shockwave:
		var shockwave := MeshInstance3D.new()
		var sw_mesh := CylinderMesh.new()
		sw_mesh.top_radius = 0.08
		sw_mesh.bottom_radius = 0.08
		sw_mesh.height = 0.02
		shockwave.mesh = sw_mesh
		var sw_mat := StandardMaterial3D.new()
		sw_mat.albedo_color = shockwave_color
		sw_mat.emission_enabled = true
		sw_mat.emission = shockwave_color * 2.0
		sw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sw_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		shockwave.material_override = sw_mat
		shockwave.set_meta("is_shockwave", true)
		shockwave.set_meta("target_radius", shockwave_radius)
		effect_root.add_child(shockwave)

	if effect_type == "hit":
		_attach_sequence_quad(effect_root, HIT_CONFIRM_FRAMES, Color(1.0, 1.0, 1.0, 0.96), 1.16)
	elif effect_type == "wrong_hit":
		_attach_sequence_quad(effect_root, WRONG_HIT_FRAMES, Color(1.0, 0.92, 0.92, 0.96), 1.10)

	hit_effects.append({
		"root": effect_root,
		"timer": hit_effect_duration,
		"duration": hit_effect_duration,
		"type": effect_type,
		"normal": hit_normal,
	})


func _update_hit_effects(delta: float) -> void:
	for i in range(hit_effects.size() - 1, -1, -1):
		var effect: Dictionary = hit_effects[i]
		effect["timer"] -= delta
		var root: Node3D = effect["root"]
		if not is_instance_valid(root):
			hit_effects.remove_at(i)
			continue
		var effect_duration: float = maxf(float(effect.get("duration", hit_effect_duration)), 0.001)
		var t: float = clampf(1.0 - (effect["timer"] / effect_duration), 0.0, 1.0)
		for child in root.get_children():
			if child is MeshInstance3D:
				var is_flash: bool = bool(child.get_meta("is_flash", false))
				var is_dust: bool = bool(child.get_meta("is_dust", false))
				var is_shockwave: bool = bool(child.get_meta("is_shockwave", false))
				var is_sequence: bool = bool(child.get_meta("is_sequence", false))
				if is_shockwave:
					var target_r: float = float(child.get_meta("target_radius", 1.0))
					var sw_scale: float = lerpf(0.12, target_r / 0.08, ease(t, 2.5))
					child.scale = Vector3(sw_scale, 1.0, sw_scale)
					if child.material_override is StandardMaterial3D:
						var sw_alpha: float = maxf(1.0 - t * 1.4, 0.0)
						child.material_override.albedo_color.a = sw_alpha
				elif is_flash:
					var flash_scale: float = lerpf(0.3, 2.5, t)
					child.scale = Vector3.ONE * flash_scale
					if child.material_override is StandardMaterial3D:
						child.material_override.albedo_color.a = 1.0 - t
				elif is_sequence:
					var seq_frames: Array = child.get_meta("frames", [])
					var seq_size: float = float(child.get_meta("sequence_size", 1.0))
					child.scale = Vector3.ONE * lerpf(0.82, 1.18, t)
					if child.material_override is StandardMaterial3D:
						child.material_override.albedo_texture = _resolve_sequence_frame(seq_frames, t)
						child.material_override.albedo_color.a = maxf(0.96 - t * 0.84, 0.0)
					if child.mesh is QuadMesh:
						(child.mesh as QuadMesh).size = Vector2(seq_size, seq_size)
				elif is_dust:
					var vel: Vector3 = child.get_meta("vel", Vector3.ZERO)
					child.position += vel * delta
					vel.y -= 2.0 * delta
					vel.x *= 0.98
					vel.z *= 0.98
					child.set_meta("vel", vel)
					var dust_scale: float = lerpf(1.0, 2.5, t)
					child.scale = Vector3.ONE * dust_scale
					if child.material_override is StandardMaterial3D:
						child.material_override.albedo_color.a = maxf(0.75 - t * 0.95, 0.0)
				else:
					var vel: Vector3 = child.get_meta("vel", Vector3.ZERO)
					child.position += vel * delta
					vel.y -= 5.0 * delta
					child.set_meta("vel", vel)
					var spark_scale: float = lerpf(1.0, 0.1, t)
					child.scale = Vector3.ONE * spark_scale
					if child.material_override is StandardMaterial3D:
						child.material_override.albedo_color.a = 1.0 - t
		if effect["timer"] <= 0.0:
			root.queue_free()
			hit_effects.remove_at(i)


func _spawn_scan_ground_ring(center_world: Vector3, start_radius: float, end_radius: float, duration: float, alpha: float, start_delay: float = 0.0) -> void:
	if fx_root_3d == null:
		return
	var ring_root := Node3D.new()
	ring_root.position = center_world
	fx_root_3d.add_child(ring_root)
	var ring_quad := MeshInstance3D.new()
	var ring_mesh := QuadMesh.new()
	ring_mesh.size = Vector2(start_radius, start_radius)
	ring_quad.mesh = ring_mesh
	ring_quad.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_texture = _resolve_sequence_frame(SCAN_PULSE_FRAMES, 0.0)
	ring_mat.albedo_color = Color(0.76, 0.92, 1.0, alpha)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	ring_quad.material_override = ring_mat
	ring_root.add_child(ring_quad)
	scan_wave_effects.append({
		"root": ring_root,
		"quad": ring_quad,
		"timer": duration,
		"duration": duration,
		"start_radius": start_radius,
		"end_radius": end_radius,
		"alpha": alpha,
		"delay": start_delay,
	})


func _update_scan_wave_effects(delta: float) -> void:
	for i in range(scan_wave_effects.size() - 1, -1, -1):
		var effect: Dictionary = scan_wave_effects[i]
		var root: Node3D = effect.get("root", null)
		var quad: MeshInstance3D = effect.get("quad", null)
		if not is_instance_valid(root) or not is_instance_valid(quad):
			scan_wave_effects.remove_at(i)
			continue
		var delay := maxf(float(effect.get("delay", 0.0)) - delta, 0.0)
		effect["delay"] = delay
		if delay > 0.0:
			quad.visible = false
			scan_wave_effects[i] = effect
			continue
		quad.visible = true
		effect["timer"] = float(effect.get("timer", 0.0)) - delta
		var duration := maxf(float(effect.get("duration", 0.001)), 0.001)
		var t := clampf(1.0 - (float(effect.get("timer", 0.0)) / duration), 0.0, 1.0)
		var radius := lerpf(float(effect.get("start_radius", 1.0)), float(effect.get("end_radius", 6.0)), t)
		if quad.mesh is QuadMesh:
			(quad.mesh as QuadMesh).size = Vector2(radius, radius)
		if quad.material_override is StandardMaterial3D:
			var mat := quad.material_override as StandardMaterial3D
			mat.albedo_texture = _resolve_sequence_frame(SCAN_PULSE_FRAMES, t)
			mat.albedo_color.a = maxf(float(effect.get("alpha", 0.6)) * (1.0 - t), 0.0)
			mat.emission_enabled = true
			mat.emission = Color(0.42, 0.92, 1.0) * maxf((1.0 - t) * 1.4, 0.0)
		scan_wave_effects[i] = effect
		if float(effect.get("timer", 0.0)) <= 0.0:
			root.queue_free()
			scan_wave_effects.remove_at(i)


func _attach_sequence_quad(effect_root: Node3D, frames: Array, tint: Color, base_size: float) -> void:
	if effect_root == null or frames.is_empty():
		return
	var seq_quad := MeshInstance3D.new()
	var seq_mesh := QuadMesh.new()
	seq_mesh.size = Vector2(base_size, base_size)
	seq_quad.mesh = seq_mesh
	var seq_mat := StandardMaterial3D.new()
	seq_mat.albedo_texture = _resolve_sequence_frame(frames, 0.0)
	seq_mat.albedo_color = tint
	seq_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	seq_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	seq_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	seq_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	seq_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	seq_quad.material_override = seq_mat
	seq_quad.set_meta("is_sequence", true)
	seq_quad.set_meta("frames", frames)
	seq_quad.set_meta("sequence_size", base_size)
	effect_root.add_child(seq_quad)


func _spawn_sequence_effect(world_pos: Vector3, frames: Array, tint: Color, base_size: float, duration: float) -> void:
	if fx_root_3d == null or frames.is_empty():
		return
	var effect_root := Node3D.new()
	effect_root.position = world_pos
	fx_root_3d.add_child(effect_root)
	_attach_sequence_quad(effect_root, frames, tint, base_size)
	hit_effects.append({
		"root": effect_root,
		"timer": duration,
		"duration": duration,
		"type": "sequence_only",
		"normal": Vector3.UP,
	})


func _resolve_sequence_frame(frames: Array, ratio: float) -> Texture2D:
	if frames.is_empty():
		return null
	var normalized := clampf(ratio, 0.0, 0.9999)
	var index := clampi(int(floor(normalized * float(frames.size()))), 0, frames.size() - 1)
	var texture: Variant = frames[index]
	return texture if texture is Texture2D else null


func get_scan_feedback_ratio() -> float:
	if SCAN_FEEDBACK_DURATION <= 0.0:
		return 0.0
	return clampf(1.0 - (scan_feedback_timer / SCAN_FEEDBACK_DURATION), 0.0, 1.0)


func spawn_bullet_trail(from_pos: Vector3, to_pos: Vector3, shot_dir: Vector3, hit_effect_type: String = "", hit_normal: Vector3 = Vector3.UP) -> Dictionary:
	if fx_root_3d == null or not is_instance_valid(fx_root_3d):
		if world_root_3d == null or not is_instance_valid(world_root_3d):
			return {}
		fx_root_3d = world_root_3d

	var trail_cfg: Dictionary = _get_current_trail_config()
	var is_rainbow: bool = trail_cfg["effect_type"] == "rainbow"
	var trail_colors: Array[Color] = trail_cfg["colors"]
	var color_count: int = trail_colors.size()
	var glow_mult: float = float(trail_cfg.get("glow_intensity", 1.0))

	var trail_root := Node3D.new()
	fx_root_3d.add_child(trail_root)

	var bullet := Node3D.new()
	bullet.position = from_pos
	trail_root.add_child(bullet)
	bullet.look_at(from_pos + shot_dir, Vector3.UP)

	var tip := MeshInstance3D.new()
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.055
	cone_mesh.height = 0.24
	tip.mesh = cone_mesh
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = trail_colors[0] if color_count > 0 else Color(1.0, 0.85, 0.45)
	tip_mat.emission_enabled = true
	tip_mat.emission = (trail_colors[0] if color_count > 0 else Color(1.0, 0.75, 0.3)) * (4.0 * glow_mult)
	tip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tip.material_override = tip_mat
	tip.rotation_degrees = Vector3(-90, 0, 0)
	tip.position.z = -0.12
	bullet.add_child(tip)

	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.050
	body_mesh.bottom_radius = 0.044
	body_mesh.height = 0.16
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = trail_colors[0].lerp(trail_colors[1] if color_count > 1 else trail_colors[0], 0.5) if color_count > 0 else Color(0.95, 0.75, 0.3)
	body_mat.emission_enabled = true
	body_mat.emission = (trail_colors[0] if color_count > 0 else Color(1.0, 0.65, 0.2)) * (2.0 * glow_mult)
	body_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	body.material_override = body_mat
	body.rotation_degrees = Vector3(-90, 0, 0)
	body.position.z = 0.08
	bullet.add_child(body)

	if is_rainbow:
		var halo_rings: int = int(trail_cfg.get("ring_count", 4))
		var halo_radius: float = float(trail_cfg.get("outer_radius", 0.16))
		for ri in range(halo_rings):
			var ring_t: float = float(ri) / float(maxf(halo_rings - 1, 1))
			var ring_color_idx: int = ri % color_count
			var ring_color: Color = trail_colors[ring_color_idx]
			var ring_offset: float = -0.06 - float(ri) * 0.028
			var ring := MeshInstance3D.new()
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = halo_radius * (0.55 + ring_t * 0.45)
			ring_mesh.outer_radius = halo_radius * (0.75 + ring_t * 0.45)
			ring_mesh.radial_segments = 12
			ring_mesh.rings = 20
			ring.mesh = ring_mesh
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, 0.85)
			ring_mat.emission_enabled = true
			ring_mat.emission = ring_color * (2.5 * glow_mult * (0.6 + ring_t * 0.4))
			ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ring.material_override = ring_mat
			ring.position.z = ring_offset
			ring.set_meta("is_halo_ring", true)
			ring.set_meta("ring_index", ri)
			ring.set_meta("ring_color", ring_color)
			bullet.add_child(ring)

	var trail_segments: Array[Dictionary] = []
	for i in range(BULLET_TRAIL_SEGMENTS):
		var seg := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		var t: float = float(i) / float(BULLET_TRAIL_SEGMENTS)
		var base_r: float = 0.064 * (1.0 - t * 0.5)
		if is_rainbow:
			base_r *= 1.2
		s_mesh.radius = base_r
		s_mesh.height = base_r * 0.5
		seg.mesh = s_mesh
		var s_mat := StandardMaterial3D.new()
		var color_idx: int = i % color_count
		var seg_color: Color = trail_colors[color_idx]
		var bright: float = 0.5 + 0.5 * (1.0 - t)
		if is_rainbow:
			s_mat.albedo_color = Color(seg_color.r, seg_color.g, seg_color.b, 0.88 * (1.0 - t * 0.55))
			s_mat.emission_enabled = true
			s_mat.emission = seg_color * (2.4 * glow_mult * (1.0 - t * 0.3))
		else:
			s_mat.albedo_color = Color(1.0, 0.9 * bright, 0.5 * bright, 0.85 * (1.0 - t * 0.6))
			s_mat.emission_enabled = true
			s_mat.emission = Color(1.0, 0.8, 0.35) * (2.0 * (1.0 - t * 0.4))
		s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		seg.material_override = s_mat
		seg.position = from_pos
		seg.scale = Vector3(1.0, 0.35, 1.0)
		trail_root.add_child(seg)
		var angle_offset: float = float(i) * 0.85
		if is_rainbow:
			angle_offset = float(i) * (TAU / float(maxf(color_count, 1))) + float(i) * 0.25
		var spiral_r: float = 0.088 * (1.0 - t * 0.7)
		if is_rainbow:
			spiral_r = float(trail_cfg.get("outer_radius", 0.12)) * (0.7 + 0.3 * float(color_idx) / float(maxf(color_count - 1, 1))) * (1.0 - t * 0.6)
		trail_segments.append({
			"node": seg,
			"base_t": t,
			"angle_offset": angle_offset,
			"spiral_r": spiral_r,
			"color_idx": color_idx,
			"color": seg_color,
		})

	var trail: Dictionary = {
		"root": trail_root,
		"bullet": bullet,
		"tip": tip,
		"body": body,
		"segments": trail_segments,
		"from": from_pos,
		"to": to_pos,
		"dir": shot_dir.normalized(),
		"timer": BULLET_TRAIL_DURATION,
		"duration": BULLET_TRAIL_DURATION,
		"dist": maxf(from_pos.distance_to(to_pos), 1.0),
		"spin_angle": 0.0,
		"hit_effect_type": hit_effect_type,
		"hit_normal": hit_normal,
		"hit_fired": false,
		"on_arrive_callbacks": [],
		"is_rainbow": is_rainbow,
	}
	bullet_trails.append(trail)
	return trail


func _update_bullet_trails(delta: float) -> void:
	for i in range(bullet_trails.size() - 1, -1, -1):
		var trail: Dictionary = bullet_trails[i]
		trail["timer"] -= delta
		var root: Node3D = trail["root"]
		if not is_instance_valid(root):
			bullet_trails.remove_at(i)
			continue

		var t: float = 1.0 - clampf(trail["timer"] / trail["duration"], 0.0, 1.0)
		var eased_t: float = ease(t, 1.5)
		var bullet: Node3D = trail["bullet"]
		var from_p: Vector3 = trail["from"]
		var to_p: Vector3 = trail["to"]
		var dir: Vector3 = trail["dir"]
		var bullet_pos: Vector3 = from_p.lerp(to_p, clampf(eased_t, 0.0, 1.0))
		var is_rainbow: bool = bool(trail.get("is_rainbow", false))

		var spin_angle: float = float(trail.get("spin_angle", 0.0))
		var spin_speed: float = 35.0
		if is_rainbow:
			spin_speed = 55.0
		spin_angle += delta * spin_speed
		trail["spin_angle"] = spin_angle

		if is_instance_valid(bullet):
			bullet.position = bullet_pos
			bullet.look_at(bullet_pos + dir, Vector3.UP)
			bullet.rotate(dir, spin_angle)

			for child in bullet.get_children():
				if child is MeshInstance3D and bool(child.get_meta("is_halo_ring", false)):
					var ring_idx: int = int(child.get_meta("ring_index", 0))
					var pulse: float = 0.82 + 0.18 * sin(spin_angle * 2.5 + float(ring_idx) * 0.8)
					child.scale = Vector3.ONE * pulse
					if child.material_override is StandardMaterial3D:
						var ring_fade: float = 1.0
						if t > 0.8:
							ring_fade = 1.0 - (t - 0.8) / 0.2
						child.material_override.albedo_color.a = maxf(0.85 * ring_fade, 0.0)

			var fade: float = 1.0
			if t > 0.85:
				fade = 1.0 - (t - 0.85) / 0.15
			bullet.scale = Vector3.ONE * fade
			var tip_mi: MeshInstance3D = trail.get("tip", null)
			var body_mi: MeshInstance3D = trail.get("body", null)
			if tip_mi != null and is_instance_valid(tip_mi) and tip_mi.material_override is StandardMaterial3D:
				tip_mi.material_override.albedo_color.a = fade
			if body_mi != null and is_instance_valid(body_mi) and body_mi.material_override is StandardMaterial3D:
				body_mi.material_override.albedo_color.a = fade

		var segments: Array = trail["segments"]
		var up: Vector3 = Vector3.UP
		if absf(dir.y) > 0.9:
			up = Vector3.RIGHT
		var right: Vector3 = dir.cross(up).normalized()
		var actual_up: Vector3 = right.cross(dir).normalized()
		var seg_spin_mult: float = 2.2
		if is_rainbow:
			seg_spin_mult = 3.8
		for si in range(segments.size()):
			var seg_dict: Dictionary = segments[si]
			var seg: MeshInstance3D = seg_dict.get("node", null)
			if not is_instance_valid(seg):
				continue
			var base_t: float = float(seg_dict.get("base_t", 0.0))
			var angle_off: float = float(seg_dict.get("angle_offset", 0.0))
			var spiral_r: float = float(seg_dict.get("spiral_r", 0.02))
			var back: float = base_t * 0.18
			var seg_t: float = clampf(eased_t - back, 0.0, 1.0)
			var seg_center: Vector3 = from_p.lerp(to_p, seg_t)
			var seg_angle: float = spin_angle * seg_spin_mult + angle_off
			var spiral_offset: Vector3 = (right * cos(seg_angle) + actual_up * sin(seg_angle)) * spiral_r * (1.0 - t * 0.3)
			seg.position = seg_center + spiral_offset
			var seg_alpha: float = (1.0 - t) * (1.0 - base_t * 0.8)
			if is_rainbow:
				seg_alpha = (1.0 - t * 0.85) * (1.0 - base_t * 0.7)
			var seg_scale_mult: float = 1.0
			if is_rainbow:
				seg_scale_mult = 1.15
			seg.scale = Vector3(1.0, 0.3, 1.0) * maxf(seg_alpha * seg_scale_mult, 0.0)
			if seg.material_override is StandardMaterial3D:
				seg.material_override.albedo_color.a = maxf(seg_alpha, 0.0)

		var hit_fired: bool = bool(trail.get("hit_fired", false))
		var hit_type: String = str(trail.get("hit_effect_type", ""))
		if not hit_fired and t >= 0.96:
			trail["hit_fired"] = true
			var callbacks: Array = trail.get("on_arrive_callbacks", [])
			for cb in callbacks:
				if cb is Callable and cb.is_valid():
					cb.call()
			if hit_type != "":
				var hit_n: Vector3 = trail.get("hit_normal", Vector3.UP)
				spawn_hit_effect(to_p, hit_n, hit_type)

		if trail["timer"] <= 0.0:
			root.queue_free()
			bullet_trails.remove_at(i)
