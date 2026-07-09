extends Node

signal fire_requested
signal scan_requested
signal time_extend_requested
@warning_ignore("unused_signal")
signal zoom_in_requested
@warning_ignore("unused_signal")
signal zoom_out_requested
@warning_ignore("unused_signal")
signal camera_move_requested(direction: Vector2)
@warning_ignore("unused_signal")
signal aim_position_changed(screen_pos: Vector2)
signal drag_started
signal drag_ended
signal weapon_switch_next
signal weapon_switch_prev

var battle_core = null
var camera_controller = null

var left_pointer_down: bool = false
var left_pointer_dragging: bool = false
var left_press_position: Vector2 = Vector2.ZERO

var right_hold_active: bool = false
var right_last_press_msec: int = 0
var drag_active: bool = false

var hold_tutorial_reported: bool = false


func setup(core, camera) -> void:
	battle_core = core
	camera_controller = camera


func process_input(delta: float) -> void:
	if battle_core.battle_closed or _is_cinematic_active():
		return

	var movement: Vector2 = Vector2.ZERO
	if not _is_cinematic_active():
		movement = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")

	if movement.length() > 0.0:
		camera_controller.move_by_input(movement, delta)
		_handle_camera_move_tutorial(movement)

	if not _is_cinematic_active():
		camera_controller.auto_pan_by_aim(delta)

	var hold_requested: bool = (not _is_cinematic_active()) and battle_core.weapon_ready and (Input.is_action_pressed("aim_hold") or right_hold_active)

	if hold_requested:
		if _can_execute_tutorial_action(&"aim_hold"):
			battle_core.hold_ratio = min(1.0, battle_core.hold_ratio + delta / float(battle_core.weapon.hold_stabilize_sec))
			if battle_core.hold_ratio >= 0.55 and not hold_tutorial_reported:
				hold_tutorial_reported = true
				_try_progress_tutorial(&"aim_hold")
		else:
			battle_core.hold_ratio = max(0.0, battle_core.hold_ratio - delta / float(battle_core.weapon.aim_recover_sec))
	else:
		hold_tutorial_reported = false
		battle_core.hold_ratio = max(0.0, battle_core.hold_ratio - delta / float(battle_core.weapon.aim_recover_sec))

	if battle_core.weapon_ready and Input.is_action_just_pressed("aim_zoom_in"):
		if _can_execute_tutorial_action(&"aim_zoom_in"):
			camera_controller.adjust_zoom(float(battle_core.weapon.zoom_step))
			_try_progress_tutorial(&"aim_zoom_in")

	if battle_core.weapon_ready and Input.is_action_just_pressed("aim_zoom_out"):
		if _can_execute_tutorial_action(&"aim_zoom_out"):
			camera_controller.adjust_zoom(-float(battle_core.weapon.zoom_step))
			_try_progress_tutorial(&"aim_zoom_out")

	if not _is_cinematic_active() and Input.is_action_just_pressed("fire"):
		if _can_execute_tutorial_action(&"fire"):
			fire_requested.emit()

	if not _is_cinematic_active() and Input.is_action_just_pressed("use_scan"):
		scan_requested.emit()

	if not _is_cinematic_active() and Input.is_action_just_pressed("use_time_extend"):
		time_extend_requested.emit()

	if Input.is_action_just_pressed("weapon_switch_next"):
		weapon_switch_next.emit()

	if Input.is_action_just_pressed("weapon_switch_prev"):
		weapon_switch_prev.emit()

	if Input.is_action_just_pressed("ui_back"):
		var parent_controller = get_parent()
		if parent_controller != null and is_instance_valid(parent_controller) and parent_controller.has_method("_request_pause_overlay"):
			parent_controller.call("_request_pause_overlay", "keyboard_back")


func handle_mouse_button(event: InputEventMouseButton) -> void:
	if battle_core.battle_closed or _is_cinematic_active():
		return

	if event.button_index == MOUSE_BUTTON_MIDDLE:
		drag_active = event.pressed
		if event.pressed:
			drag_started.emit()
		else:
			drag_ended.emit()
		return

	if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if _can_execute_tutorial_action(&"aim_zoom_in"):
			camera_controller.adjust_zoom(float(battle_core.weapon.zoom_step))
			_try_progress_tutorial(&"aim_zoom_in")
		return

	if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if _can_execute_tutorial_action(&"aim_zoom_out"):
			camera_controller.adjust_zoom(-float(battle_core.weapon.zoom_step))
			_try_progress_tutorial(&"aim_zoom_out")
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			if not battle_core.weapon_ready:
				return
			camera_controller.set_aim_screen_position(event.position)
			_zoom_focus_to_next_step(event.position)
			left_pointer_down = false
			left_pointer_dragging = false
			return

		if event.pressed:
			camera_controller.set_aim_screen_position(event.position)
			left_pointer_down = true
			left_pointer_dragging = false
			left_press_position = event.position
		else:
			camera_controller.set_aim_screen_position(event.position)
			if left_pointer_down and not left_pointer_dragging and camera_controller.current_zoom >= 1.12:
				if _can_execute_tutorial_action(&"fire"):
					fire_requested.emit()
			left_pointer_down = false
			left_pointer_dragging = false
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if not battle_core.weapon_ready:
				return
			right_hold_active = true
		else:
			var should_release_fire: bool = right_hold_active and camera_controller.current_zoom >= 1.12
			right_hold_active = false
			if should_release_fire:
				if _can_execute_tutorial_action(&"fire"):
					fire_requested.emit()


func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if battle_core.battle_closed or _is_cinematic_active():
		return

	if camera_controller.scope_visible:
		camera_controller.set_aim_screen_position(event.position)

	if drag_active:
		camera_controller.drag_by_motion(event.relative)
		_handle_camera_move_tutorial(-event.relative)
		return

	if left_pointer_down and not camera_controller.scope_visible:
		if not left_pointer_dragging and event.position.distance_to(left_press_position) > 8.0:
			left_pointer_dragging = true

		if left_pointer_dragging:
			camera_controller.drag_by_motion(event.relative)
			_handle_camera_move_tutorial(-event.relative)


func _can_execute_tutorial_action(action_name: StringName) -> bool:
	if not CoreGameState.is_tutorial_active():
		return true

	if CoreGameState.is_tutorial_action_unlocked(action_name):
		return true

	_show_tutorial_blocked()
	return false


func _show_tutorial_blocked() -> void:
	var step_data: Dictionary = CoreGameState.get_tutorial_step_data()
	CoreEventBus.log_event("tutorial_blocked", {
		"step_index": step_data.get("index", 0),
		"expected_text": step_data.get("expected_text", ""),
	})


func _try_progress_tutorial(action_name: StringName) -> void:
	if not CoreGameState.is_tutorial_active():
		return

	var progress: Dictionary = CoreGameState.try_progress_tutorial(action_name, {
		"elapsed_time": battle_core.elapsed_time,
	})
	if not bool(progress.get("progressed", false)):
		return


func _handle_camera_move_tutorial(movement: Vector2) -> void:
	if not CoreGameState.is_tutorial_active():
		return

	var action_name: StringName = StringName()

	if absf(movement.x) >= absf(movement.y):
		action_name = &"camera_right" if movement.x > 0.0 else &"camera_left"
	else:
		action_name = &"camera_down" if movement.y > 0.0 else &"camera_up"

	_try_progress_tutorial(action_name)


func _zoom_focus_to_next_step(screen_pos: Vector2) -> void:
	if not _can_execute_tutorial_action(&"aim_zoom_in"):
		return

	var step: float = maxf(float(battle_core.weapon.zoom_step) * 1.5, 0.22)
	camera_controller.adjust_zoom_at_screen(screen_pos, step)
	_try_progress_tutorial(&"aim_zoom_in")


func _is_cinematic_active() -> bool:
	return false
