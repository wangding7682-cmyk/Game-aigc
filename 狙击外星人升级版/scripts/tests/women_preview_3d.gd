extends Node3D

@onready var preview_camera: Camera3D = $PreviewCamera

var camera_target := Vector3(0.0, 1.1, 0.0)
var camera_distance := 14.5
var camera_yaw := 0.0
var camera_pitch := -0.18
var orbit_dragging := false
var pan_dragging := false


func _ready() -> void:
	call_deferred("_setup_preview")


func _setup_preview() -> void:
	var women_base := get_node_or_null("WomenBase") as Node3D
	var women_action_1 := get_node_or_null("WomenAction1") as Node3D
	var women_action_2 := get_node_or_null("WomenAction2") as Node3D
	var floor_node := get_node_or_null("Floor") as Node3D
	var camera := get_node_or_null("PreviewCamera") as Camera3D

	if women_base != null:
		_normalize_model_root(women_base, Vector3(-4.8, 0.0, 0.0), 2.2)
		women_base.rotation_degrees = Vector3(0.0, 12.0, 0.0)
	if women_action_1 != null:
		_normalize_model_root(women_action_1, Vector3(0.0, 0.0, 0.0), 2.2)
		women_action_1.rotation_degrees = Vector3.ZERO
		_autoplay_first_animation(women_action_1)
	if women_action_2 != null:
		_normalize_model_root(women_action_2, Vector3(4.8, 0.0, 0.0), 2.2)
		women_action_2.rotation_degrees = Vector3(0.0, -12.0, 0.0)
		_autoplay_first_animation(women_action_2)
		

	if floor_node != null:
		floor_node.position = Vector3(0.0, -0.1, 0.0)

	if camera != null:
		camera.current = true
		_reset_camera()


func _unhandled_input(event: InputEvent) -> void:
	if preview_camera == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				orbit_dragging = mouse_event.pressed
			MOUSE_BUTTON_MIDDLE:
				pan_dragging = mouse_event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if mouse_event.pressed:
					camera_distance = maxf(6.0, camera_distance - 1.0)
					_update_camera_transform()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_event.pressed:
					camera_distance = minf(28.0, camera_distance + 1.0)
					_update_camera_transform()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if orbit_dragging:
			camera_yaw -= motion.relative.x * 0.008
			camera_pitch = clampf(camera_pitch - motion.relative.y * 0.006, -0.95, 0.18)
			_update_camera_transform()
		elif pan_dragging:
			var pan_scale := camera_distance * 0.005
			var forward := Vector3(sin(camera_yaw), 0.0, cos(camera_yaw))
			var right := Vector3(forward.z, 0.0, -forward.x)
			camera_target += right * (-motion.relative.x * pan_scale)
			camera_target += Vector3.UP * (motion.relative.y * pan_scale * 0.6)
			camera_target += forward * (motion.relative.y * pan_scale * 0.4)
			_update_camera_transform()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_camera()


func _reset_camera() -> void:
	camera_target = Vector3(0.0, 1.1, 0.0)
	camera_distance = 14.5
	camera_yaw = 0.0
	camera_pitch = -0.18
	_update_camera_transform()


func _update_camera_transform() -> void:
	if preview_camera == null:
		return
	var horizontal_distance := camera_distance * cos(camera_pitch)
	var camera_offset := Vector3(
		sin(camera_yaw) * horizontal_distance,
		sin(-camera_pitch) * camera_distance + 1.0,
		cos(camera_yaw) * horizontal_distance
	)
	preview_camera.position = camera_target + camera_offset
	preview_camera.look_at(camera_target, Vector3.UP)


func _normalize_model_root(root: Node3D, target_position: Vector3, target_height: float) -> void:
	root.position = Vector3.ZERO
	root.scale = Vector3.ONE
	var bounds := _compute_global_bounds(root)
	if not bool(bounds.get("has_bounds", false)):
		root.position = target_position
		return
	var min_v: Vector3 = bounds.get("min", Vector3.ZERO)
	var max_v: Vector3 = bounds.get("max", Vector3.ZERO)
	var current_height: float = maxf(max_v.y - min_v.y, 0.001)
	var uniform_scale := clampf(target_height / current_height, 0.02, 4.0)
	root.scale = Vector3.ONE * uniform_scale
	bounds = _compute_global_bounds(root)
	if not bool(bounds.get("has_bounds", false)):
		root.position = target_position
		return
	min_v = bounds.get("min", Vector3.ZERO)
	max_v = bounds.get("max", Vector3.ZERO)
	var center_x: float = (min_v.x + max_v.x) * 0.5
	var center_z: float = (min_v.z + max_v.z) * 0.5
	var min_y: float = min_v.y
	root.position += Vector3(target_position.x - center_x, target_position.y - min_y, target_position.z - center_z)


func _compute_global_bounds(root: Node3D) -> Dictionary:
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(root, meshes)
	var has_bounds := false
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO
	for mesh_instance in meshes:
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var aabb := mesh_instance.mesh.get_aabb()
		for corner in _aabb_corners(aabb):
			var world_corner := mesh_instance.global_transform * corner
			if not has_bounds:
				min_v = world_corner
				max_v = world_corner
				has_bounds = true
			else:
				min_v.x = minf(min_v.x, world_corner.x)
				min_v.y = minf(min_v.y, world_corner.y)
				min_v.z = minf(min_v.z, world_corner.z)
				max_v.x = maxf(max_v.x, world_corner.x)
				max_v.y = maxf(max_v.y, world_corner.y)
				max_v.z = maxf(max_v.z, world_corner.z)
	return {
		"has_bounds": has_bounds,
		"min": min_v,
		"max": max_v,
	}


func _collect_mesh_instances(root: Node, out: Array[MeshInstance3D]) -> void:
	if root is MeshInstance3D:
		out.append(root as MeshInstance3D)
	for child in root.get_children():
		_collect_mesh_instances(child, out)


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p := aabb.position
	var s := aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]


func _autoplay_first_animation(root: Node) -> void:
	var player := _find_animation_player(root)
	if player == null:
		return
	var candidates: Array[String] = []
	for animation_name in player.get_animation_list():
		var key := str(animation_name)
		var lowered := key.to_lower()
		if lowered == "reset" or lowered == "_reset":
			continue
		candidates.append(key)
	if candidates.is_empty():
		return
	player.play(candidates[0])


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
