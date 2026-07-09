extends Node

@warning_ignore("unused_signal")
signal battle_finished(result: Dictionary)

var mode_id: String = "default"
var mode_name: String = "默认模式"
var mode_description: String = ""

var battle_core = null
var camera_controller = null
var input_handler = null
var visual_feedback = null
var weapon = null

var level_config = null
var battle_closed: bool = false


func setup(level_cfg, weapon_obj) -> void:
	level_config = level_cfg
	weapon = weapon_obj


func initialize_controllers(core, camera, input, feedback) -> void:
	battle_core = core
	camera_controller = camera
	input_handler = input
	visual_feedback = feedback


func start_battle() -> void:
	pass


func end_battle(_success: bool, _reason: String) -> void:
	pass


func update(_delta: float) -> void:
	pass


func handle_input_event(_event: InputEvent) -> void:
	pass


func get_mode_info() -> Dictionary:
	return {
		"mode_id": mode_id,
		"mode_name": mode_name,
		"mode_description": mode_description,
		"level_id": level_config.level_id if level_config else 0,
	}


func is_battle_active() -> bool:
	return not battle_closed
