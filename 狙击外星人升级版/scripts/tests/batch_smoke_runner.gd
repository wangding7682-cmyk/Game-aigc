extends Node

const FLOW_SMOKE_SCENE_PATH := "res://scenes/tests/flow_smoke_runner.tscn"
const NEXT_LEVEL_SMOKE_SCENE_PATH := "res://scenes/tests/next_level_smoke_runner.tscn"
const INTEGRATION_SMOKE_SCENE_PATH := "res://scenes/tests/integration_smoke_runner.tscn"
const ROUTE_GUARD_SMOKE_SCENE_PATH := "res://scenes/tests/route_guard_smoke_runner.tscn"
const PLACEHOLDER_3D_SMOKE_SCENE_PATH := "res://scenes/tests/placeholder_3d_smoke_runner.tscn"

signal batch_finished(all_passed: bool, results: Dictionary)

var _test_scenes: Array[PackedScene] = []
var _test_names: Array[String] = []
var _results: Dictionary = {}


func _ready() -> void:
	_test_scenes = [
		load(FLOW_SMOKE_SCENE_PATH),
		load(NEXT_LEVEL_SMOKE_SCENE_PATH),
		load(INTEGRATION_SMOKE_SCENE_PATH),
		load(ROUTE_GUARD_SMOKE_SCENE_PATH),
		load(PLACEHOLDER_3D_SMOKE_SCENE_PATH),
	]
	_test_names = [
		"主流程烟雾",
		"下一关烟雾",
		"完整集成烟雾",
		"路由守卫烟雾",
		"3D 占位烟雾",
	]
	call_deferred("_run_all_tests")


func _find_existing_root() -> Node:
	for child in get_tree().root.get_children():
		if child.get_script() and str(child.get_script().resource_path).find("core_game_root.gd") != -1:
			return child
	var current: Node = self
	while current != null:
		if current.get_script() and str(current.get_script().resource_path).find("core_game_root.gd") != -1:
			return current
		current = current.get_parent()
	return null


func _run_all_tests() -> void:
	var root: Node = _find_existing_root()
	if root == null:
		push_error("批量烟雾测试需要在已有的 core_game_root 环境下运行")
		batch_finished.emit(false, {})
		queue_free()
		return

	var all_passed := true
	for i in _test_scenes.size():
		var test_scene: PackedScene = _test_scenes[i]
		var test_name: String = _test_names[i]
		
		var runner: Node = test_scene.instantiate()
		runner.set("auto_quit", false)
		runner.set("skip_return_navigation", true)
		root.add_child(runner)
		
		var signal_data: Array = await runner.smoke_finished
		var status := str(signal_data[0])
		var failures: Array = signal_data[1]
		runner.queue_free()
		
		_results[test_name] = {
			"status": status,
			"failures": failures,
		}
		
		if status != "PASS":
			all_passed = false
		
		# 等待几帧让场景清理完成
		await get_tree().process_frame
		await get_tree().process_frame

	# 所有测试完成后，返回测试中心
	CoreEventBus.test_center_requested.emit()
	await get_tree().process_frame
	
	batch_finished.emit(all_passed, _results)
	queue_free()
