extends Node

var camera: Camera3D = null
var world_root: Node3D = null
var level_root: Node3D = null
var actor_root: Node3D = null
var decal_root: Node3D = null
var fx_root: Node3D = null

var current_zoom: float = 1.0
var scope_visible: bool = false
var camera_locked: bool = false

var aim_screen_position: Vector2 = Vector2.ZERO
var base_aim_screen_position: Vector2 = Vector2.ZERO
var breathing_aim_offset: Vector2 = Vector2.ZERO

var default_camera_position: Vector3 = Vector3.ZERO
var default_camera_height: float = 9.6
var search_focus_world: Vector3 = Vector3.ZERO
var world_bounds_x: Vector2 = Vector2(-12.0, 12.0)
var world_bounds_z: Vector2 = Vector2(-9.0, 9.0)

var zoom_default: float = 1.0
var zoom_min: float = 0.9
var zoom_max: float = 2.4
var zoom_step: float = 0.15
var zoom_quick_aim: float = 1.6

var base_fov: float = 60.0
var hold_stabilize_sec: float = 1.0
var aim_recover_sec: float = 0.35

var camera_drag_speed: float = 0.026
var camera_pan_speed: float = 4.6
var edge_pan_speed: float = 7.0
var edge_pan_border_px: float = 80.0
var edge_pan_bottom_deadzone_px: float = 210.0
var edge_pan_active: bool = false
var locked_aim_position: Vector2 = Vector2.ZERO


func setup(weapon_profile: Dictionary, world_3d: Node3D, cam: Camera3D) -> void:
	camera = cam
	world_root = world_3d
	level_root = world_3d
	actor_root = world_3d
	decal_root = world_3d
	fx_root = world_3d

	zoom_default = float(weapon_profile.get("zoom_default", 1.0))
	zoom_min = float(weapon_profile.get("zoom_min", 0.9))
	zoom_max = float(weapon_profile.get("zoom_max", 2.2))
	zoom_quick_aim = float(weapon_profile.get("zoom_quick_aim", clampf(zoom_max * 0.72, 1.5, zoom_max)))
	zoom_step = float(weapon_profile.get("zoom_step", 0.15))
	hold_stabilize_sec = float(weapon_profile.get("hold_stabilize_sec", 1.0))
	aim_recover_sec = float(weapon_profile.get("aim_recover_sec", 0.35))

	zoom_quick_aim = clampf(zoom_quick_aim, 1.2, zoom_max)

	current_zoom = zoom_default
	default_camera_position = camera.position
	default_camera_height = camera.position.y
	search_focus_world = Vector3.ZERO
	call_deferred("_deferred_init_viewport")


func _deferred_init_viewport() -> void:
	if camera == null:
		return
	var vp := camera.get_viewport()
	if vp == null:
		call_deferred("_deferred_init_viewport")
		return
	_reset_to_search_center()


func configure_scene_roots(level_3d: Node3D, actor_3d: Node3D, decal_3d: Node3D, fx_3d: Node3D) -> void:
	level_root = level_3d if level_3d != null else world_root
	actor_root = actor_3d if actor_3d != null else world_root
	decal_root = decal_3d if decal_3d != null else world_root
	fx_root = fx_3d if fx_3d != null else world_root


func _reset_to_search_center() -> void:
	if camera == null:
		return
	camera.position = default_camera_position
	camera.look_at(search_focus_world, Vector3.UP)
	current_zoom = zoom_default
	scope_visible = false
	camera_locked = false
	_update_fov()
	breathing_aim_offset = Vector2.ZERO
	var vp_center := _get_viewport_center()
	base_aim_screen_position = vp_center
	locked_aim_position = vp_center
	aim_screen_position = vp_center


func _exit_scope_mode() -> void:
	if camera == null:
		return
	camera.position = default_camera_position
	camera.look_at(search_focus_world, Vector3.UP)
	current_zoom = zoom_default
	scope_visible = false
	camera_locked = false
	_update_fov()
	breathing_aim_offset = Vector2.ZERO
	var vp_center := _get_viewport_center()
	base_aim_screen_position = vp_center
	locked_aim_position = vp_center
	aim_screen_position = vp_center


func get_aim_world_position() -> Vector3:
	if camera == null:
		return Vector3.ZERO
	return _ray_to_ground(aim_screen_position)


func _ray_to_ground(screen_pos: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO

	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return origin
	var t := (0.0 - origin.y) / dir.y
	return origin + dir * t


func _get_viewport_center() -> Vector2:
	if camera == null or camera.get_viewport() == null:
		return Vector2.ZERO
	return camera.get_viewport().get_visible_rect().size * 0.5


func _get_viewport_size() -> Vector2:
	if camera == null or camera.get_viewport() == null:
		return Vector2.ZERO
	return camera.get_viewport().get_visible_rect().size


func set_zoom(new_zoom: float) -> void:
	current_zoom = clampf(new_zoom, zoom_min, zoom_max)
	_update_fov()
	var was_scope := scope_visible
	scope_visible = current_zoom >= 1.12
	if was_scope and not scope_visible:
		camera_locked = false
		breathing_aim_offset = Vector2.ZERO
		var vp_center := _get_viewport_center()
		base_aim_screen_position = vp_center
		locked_aim_position = vp_center
		aim_screen_position = vp_center


func set_zoom_at_screen(screen_pos: Vector2, new_zoom: float) -> void:
	if camera == null:
		set_zoom(new_zoom)
		return

	var anchor_screen: Vector2 = screen_pos
	var anchor_world_target: Vector3 = _ray_to_ground(anchor_screen)
	var was_scope := scope_visible
	set_zoom(new_zoom)

	var max_iterations := 3
	for i in range(max_iterations):
		var anchor_world_current: Vector3 = _ray_to_ground(anchor_screen)
		var delta_world: Vector3 = anchor_world_target - anchor_world_current
		if absf(delta_world.x) < 0.001 and absf(delta_world.z) < 0.001:
			break
		var new_focus_x: float = search_focus_world.x + delta_world.x
		var new_focus_z: float = search_focus_world.z + delta_world.z
		new_focus_x = clampf(new_focus_x, world_bounds_x.x + 1.4, world_bounds_x.y - 1.4)
		new_focus_z = clampf(new_focus_z, world_bounds_z.x + 1.0, world_bounds_z.y - 2.0)
		if absf(new_focus_x - search_focus_world.x) < 0.001 and absf(new_focus_z - search_focus_world.z) < 0.001:
			break
		search_focus_world.x = new_focus_x
		search_focus_world.z = new_focus_z
		_restore_search_camera()

	if not was_scope and scope_visible:
		base_aim_screen_position = screen_pos
		locked_aim_position = screen_pos


func _update_fov() -> void:
	if camera == null:
		return
	camera.fov = base_fov / maxf(current_zoom, 0.9)


func adjust_zoom(step: float) -> void:
	set_zoom(current_zoom + step)


func adjust_zoom_at_screen(screen_pos: Vector2, step: float) -> void:
	set_zoom_at_screen(screen_pos, current_zoom + step)


func focus_on_world_position(world_pos: Vector3) -> void:
	search_focus_world = Vector3(
		clampf(world_pos.x, world_bounds_x.x + 1.4, world_bounds_x.y - 1.4),
		0.0,
		clampf(world_pos.z, world_bounds_z.x + 1.0, world_bounds_z.y - 2.0)
	)
	_restore_search_camera()


func _restore_search_camera() -> void:
	if camera == null:
		return
	camera.position = default_camera_position
	camera.look_at(search_focus_world, Vector3.UP)


func pan_search_focus(delta_focus: Vector2) -> void:
	search_focus_world.x = clampf(search_focus_world.x + delta_focus.x, world_bounds_x.x + 1.4, world_bounds_x.y - 1.4)
	search_focus_world.z = clampf(search_focus_world.z + delta_focus.y, world_bounds_z.x + 1.0, world_bounds_z.y - 2.0)
	_restore_search_camera()


func move_camera(movement: Vector2, delta: float) -> void:
	pan_search_focus(movement * camera_pan_speed * delta)


func drag_camera_by_motion(relative: Vector2) -> void:
	pan_search_focus(Vector2(relative.x, relative.y) * camera_drag_speed)


func set_camera_locked(locked: bool) -> void:
	if camera_locked == locked:
		return
	camera_locked = locked
	if locked:
		locked_aim_position = base_aim_screen_position
	else:
		var vp_center := _get_viewport_center()
		base_aim_screen_position = vp_center
		locked_aim_position = vp_center


func set_base_aim_screen_position(screen_pos: Vector2) -> void:
	base_aim_screen_position = screen_pos
	aim_screen_position = base_aim_screen_position + breathing_aim_offset


func update_edge_pan(mouse_pos: Vector2, delta: float) -> void:
	edge_pan_active = false
	if not scope_visible or camera == null:
		return

	var vp_size: Vector2 = _get_viewport_size()
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	var border: float = edge_pan_border_px
	var pan_dir := Vector2.ZERO
	var speed_scale: float = edge_pan_speed / maxf(current_zoom * 0.8, 1.0)

	if mouse_pos.x < border:
		pan_dir.x = -1.0 * (1.0 - mouse_pos.x / border)
		edge_pan_active = true
	elif mouse_pos.x > vp_size.x - border:
		pan_dir.x = 1.0 * (1.0 - (vp_size.x - mouse_pos.x) / border)
		edge_pan_active = true

	if mouse_pos.y < border:
		pan_dir.y = -1.0 * (1.0 - mouse_pos.y / border)
		edge_pan_active = true
	elif mouse_pos.y > vp_size.y - edge_pan_bottom_deadzone_px:
		pass
	elif mouse_pos.y > vp_size.y - border:
		pan_dir.y = 1.0 * (1.0 - (vp_size.y - mouse_pos.y) / border)
		edge_pan_active = true

	if pan_dir.length() > 0.001:
		pan_dir = pan_dir.normalized() * pan_dir.length()
		pan_search_focus(pan_dir * speed_scale * delta)


func update_breathing_sway(_delta: float, hold_ratio: float) -> void:
	if not scope_visible:
		breathing_aim_offset = Vector2.ZERO
		aim_screen_position = base_aim_screen_position
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var zoom_factor := clampf(current_zoom, 0.9, 6.0)
	var sway_amplitude: float

	if camera_locked:
		sway_amplitude = lerpf(55.0 + zoom_factor * 16.0, 23.0 + zoom_factor * 9.0, hold_ratio)
	else:
		sway_amplitude = 31.0 + zoom_factor * 18.0

	var breath_cycle: float = fmod(now, 4.0) / 4.0
	var breath_wave: float = 0.0
	if breath_cycle < 0.35:
		breath_wave = sin(breath_cycle / 0.35 * PI * 0.5)
	elif breath_cycle < 0.55:
		breath_wave = 1.0
	else:
		var exhale_t: float = (breath_cycle - 0.55) / 0.45
		breath_wave = cos(exhale_t * PI * 0.5)

	var heartbeat_t: float = fmod(now * 1.3, 1.0)
	var heartbeat: float = sin(heartbeat_t * PI) * 0.14

	var micro_tremor_x: float = sin(now * 6.7 + 0.3) * 0.09 + sin(now * 11.2) * 0.05
	var micro_tremor_y: float = cos(now * 7.3 + 1.1) * 0.07 + sin(now * 9.8) * 0.04

	if camera_locked:
		var hold_factor := 0.25 + (1.0 - hold_ratio) * 0.75
		breathing_aim_offset = Vector2(
			sin(now * 1.4 + breath_wave * 0.5) * sway_amplitude * 0.22 * hold_factor + heartbeat * sway_amplitude * 0.12 + micro_tremor_x * sway_amplitude * 0.25,
			(breath_wave * 0.12 - 0.04) * sway_amplitude * hold_factor + cos(now * 1.1 + breath_wave * 0.4) * sway_amplitude * 0.18 * hold_factor + sin(now * 2.3) * sway_amplitude * 0.06 + heartbeat * sway_amplitude * 0.08 + micro_tremor_y * sway_amplitude * 0.2
		)
	else:
		breathing_aim_offset = Vector2(
			sin(now * 1.4 + breath_wave * 0.5) * sway_amplitude * 0.55 + micro_tremor_x * sway_amplitude * 0.6,
			(breath_wave * 0.3 - 0.12) * sway_amplitude + cos(now * 1.1 + breath_wave * 0.4) * sway_amplitude * 0.4 + micro_tremor_y * sway_amplitude * 0.5
		)

	aim_screen_position = base_aim_screen_position + breathing_aim_offset


func get_spread_radius_screen_px(hold_ratio: float, spread_idle: float, spread_hold: float) -> float:
	var current_spread: float = lerpf(spread_idle, spread_hold, hold_ratio)
	return clampf(current_spread * 0.55 / maxf(current_zoom, 1.0), 6.0, 28.0)


func get_camera_motion_bounds() -> Dictionary:
	return {
		"world_bounds_x": world_bounds_x,
		"world_bounds_z": world_bounds_z,
		"search_focus": search_focus_world,
		"default_position": default_camera_position,
	}


func get_aim_world_coverage() -> Dictionary:
	var center: Vector3 = get_aim_world_position()
	var viewport_center: Vector2 = _get_viewport_center()
	var top_left: Vector3 = _ray_to_ground(Vector2.ZERO)
	var bottom_right: Vector3 = _ray_to_ground(viewport_center * 2.0)
	var viewport_size: Vector2 = _get_viewport_size()
	return {
		"center": center,
		"top_left": top_left,
		"bottom_right": bottom_right,
		"width": viewport_size.x,
		"height": viewport_size.y,
		"scope_visible": scope_visible,
		"zoom": current_zoom,
		"edge_pan_active": edge_pan_active,
	}


func step_edge_auto_pan(edge: String) -> Dictionary:
	var step_size := 1.0
	if not camera_locked:
		match edge:
			"left":
				pan_search_focus(Vector2(-step_size, 0.0))
			"right":
				pan_search_focus(Vector2(step_size, 0.0))
			"up":
				pan_search_focus(Vector2(0.0, -step_size))
			"down":
				pan_search_focus(Vector2(0.0, step_size))
	return {
		"search_focus": search_focus_world,
		"scope_visible": scope_visible,
		"camera_locked": camera_locked,
	}


func set_aim_screen_position(screen_pos: Vector2) -> void:
	set_base_aim_screen_position(screen_pos)


func auto_pan_by_aim(_delta: float) -> void:
	pass


func move_by_input(movement: Vector2, delta: float) -> void:
	move_camera(movement, delta)


func drag_by_motion(relative: Vector2) -> void:
	drag_camera_by_motion(relative)
