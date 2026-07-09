extends Node3D

const TARGET_3D := preload("res://scripts/pve/pve_target_controller_3d.gd")

@onready var preview_camera: Camera3D = $PreviewCamera
@onready var actor_root: Node3D = $ActorRoot

var camera_target := Vector3(0.0, 1.2, 0.0)
var camera_distance := 16.0
var camera_yaw := 0.0
var camera_pitch := -0.26
var orbit_dragging := false
var pan_dragging := false


func _ready() -> void:
	_build_preview()
	_reset_camera()


func _process(delta: float) -> void:
	var pan_input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_input.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_input.y -= 1.0

	if pan_input != Vector2.ZERO:
		var speed := 6.5 * delta
		var forward := Vector3(sin(camera_yaw), 0.0, cos(camera_yaw))
		var right := Vector3(forward.z, 0.0, -forward.x)
		camera_target += right * pan_input.x * speed
		camera_target += forward * pan_input.y * speed
		_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		match mouse_event.button_index:
			MOUSE_BUTTON_RIGHT:
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
			camera_pitch = clampf(camera_pitch - motion.relative.y * 0.006, -0.95, 0.1)
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


func _build_preview() -> void:
	for child in actor_root.get_children():
		child.queue_free()
	preview_camera.current = true

	_add_actor(
		"平民",
		Vector3(-8.0, 0.0, 0.0),
		"civilian",
		"static",
		{
			"disguise_strength": 0.82,
			"clue_profile": ["肩线自然", "腰侧没有异常亮线"],
		}
	)

	var civilian_false := _add_actor(
		"可疑平民",
		Vector3(-4.0, 0.0, 0.0),
		"civilian",
		"static",
		{
			"disguise_strength": 0.84,
			"clue_profile": ["肩线自然", "腰侧没有异常亮线"],
			"false_clue_profile": ["胸针或拉链头反光"],
		}
	)
	civilian_false.trigger_false_clue(9999.0)
	civilian_false.highlight_for(9999.0)

	_add_actor(
		"潜伏者",
		Vector3(0.0, 0.0, 0.0),
		"target",
		"static",
		{
			"disguise_strength": 0.66,
			"clue_profile": ["头部外壳过紧", "肩袖连接偏硬"],
			"suspicion_tier": 1,
			"search_signal_strength": 0.55,
		}
	)

	var scan_target := _add_actor(
		"显形者",
		Vector3(4.0, 0.0, 0.0),
		"target",
		"moving",
		{
			"disguise_strength": 0.74,
			"move_range": 2.2,
			"move_speed": 0.72,
			"clue_profile": ["肩袖连接偏硬", "手套与手臂像一体件"],
			"suspicion_tier": 2,
			"search_signal_strength": 0.72,
		}
	)
	scan_target.trigger_scan_burst(9999.0, 1.0)

	var weakpoint_target := _add_actor(
		"裂隙体",
		Vector3(8.0, 0.0, 0.0),
		"target",
		"weakpoint",
		{
			"tutorial_primary": true,
			"disguise_strength": 0.80,
			"reveal_cycle_sec": 6.8,
			"reveal_window_sec": 1.65,
			"clue_profile": ["头部外壳过紧", "腰侧细亮线短暂显露"],
			"suspicion_tier": 3,
			"search_signal_strength": 0.88,
		}
	)
	weakpoint_target.trigger_scan_burst(9999.0, 0.45)


func _add_actor(label_text: String, spawn_position: Vector3, actor_kind: String, behavior_type: String, extra: Dictionary) -> Node3D:
	var actor := TARGET_3D.new()
	actor_root.add_child(actor)
	actor.setup(actor_kind, behavior_type, spawn_position, randf_range(0.0, 100.0), extra)

	var label := Label3D.new()
	label.text = label_text
	label.font_size = 36
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 6
	label.modulate = Color(0.96, 0.97, 1.0)
	label.position = spawn_position + Vector3(0.0, 2.45, 0.0)
	actor_root.add_child(label)
	return actor


func _reset_camera() -> void:
	camera_target = Vector3(0.0, 1.25, 0.0)
	camera_distance = 16.0
	camera_yaw = 0.0
	camera_pitch = -0.26
	_update_camera_transform()


func _update_camera_transform() -> void:
	var horizontal_distance := camera_distance * cos(camera_pitch)
	var camera_offset := Vector3(
		sin(camera_yaw) * horizontal_distance,
		sin(-camera_pitch) * camera_distance + 1.0,
		cos(camera_yaw) * horizontal_distance
	)
	preview_camera.position = camera_target + camera_offset
	preview_camera.look_at(camera_target, Vector3.UP)
