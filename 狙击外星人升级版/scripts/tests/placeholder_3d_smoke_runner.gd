extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"

signal smoke_finished(status: String, failures: Array)

var _failures: Array[String] = []
var auto_quit := false
var _is_embedded := false
var skip_return_navigation := false


func _ready() -> void:
	call_deferred("_start_test")


func _start_test() -> void:
	await _run()


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


func _run() -> void:
	CoreGameState.reset_progress()
	CoreGameState.tutorial_completed = true

	var root: Node = _find_existing_root()
	if root != null:
		_is_embedded = true
		CoreEventBus.main_menu_requested.emit()
		await _wait_for_scene(root, MENU_SCENE_PATH)
	else:
		root = ROOT_SCENE.instantiate()
		add_child(root)
		await _wait_for_scene(root, MENU_SCENE_PATH)

	_assert_scene(root, MENU_SCENE_PATH, "启动后应进入主菜单")

	CoreEventBus.level_requested.emit(2)
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "进入战斗后应挂载 3D 战斗场景")

	var battle: Node = root.get("current_screen")
	if battle == null:
		_fail("3D 战斗场景未实例化")
		_finish()
		return

	_assert_method(battle, "_debug_get_weapon_mount_state", "战斗场景缺少 3D 武器挂载调试接口")

	var battle_core = battle.get("battle_core")
	if battle_core == null:
		_fail("缺少 battle_core，无法验证玩法占位")
		_finish()
		return

	var actors: Array = battle_core.get("active_actors")
	var target_count := 0
	var civilian_count := 0
	var expected_targets := 0
	var expected_civilians := 0
	var level_config = battle_core.get("level_config")
	if level_config != null:
		expected_targets = int(level_config.required_targets)
		expected_civilians = int(level_config.civilian_count)
	for actor in actors:
		if not is_instance_valid(actor):
			continue
		if actor.actor_kind == "target":
			target_count += 1
		elif actor.actor_kind == "civilian":
			civilian_count += 1
	if target_count <= 0:
		_fail("3D 占位场景没有目标角色")
	if civilian_count != expected_civilians:
		_fail("3D 占位场景平民数量不对，期望 %d，实际 %d" % [expected_civilians, civilian_count])
	if expected_targets > 0 and target_count != expected_targets:
		_fail("3D 占位场景目标数量不对，期望 %d，实际 %d" % [expected_targets, target_count])

	var level_root: Node = battle.get_node_or_null("WorldRoot/LevelRoot")
	if level_root == null:
		_fail("缺少 LevelRoot，无法验证占位场景")
	else:
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		if _find_child_recursive(level_root, "StreetBase") == null:
			_fail("缺少街道底板占位")
		if _find_child_recursive(level_root, "CenterLandmark") == null:
			_fail("缺少中心地标占位")
		if _find_child_recursive(level_root, "CenterLandmarkRing") == null:
			_fail("缺少中心地标高亮环")
		var has_window_strip := _has_prefixed_child_recursive(level_root, "FacadeBanner")
		if not has_window_strip:
			_fail("缺少远景窗带占位，镜头参考不足")

	var weapon_mount: Dictionary = battle.call("_debug_get_weapon_mount_state")
	if not bool(weapon_mount.get("exists", false)):
		_fail("3D 武器占位未挂到相机")
	if str(weapon_mount.get("geometry_type", "")).is_empty():
		_fail("3D 武器占位缺少几何类型")
	var muzzle_global: Vector3 = weapon_mount.get("muzzle_global_position", Vector3.ZERO)
	if muzzle_global == Vector3.ZERO:
		_fail("3D 武器占位缺少有效枪口点")

	var camera_controller = battle.get("camera_controller")
	if camera_controller == null:
		_fail("缺少 3D 相机控制器")
	else:
		camera_controller.set_zoom(1.6)
		battle.call("_update_hud")
		await get_tree().process_frame
		weapon_mount = battle.call("_debug_get_weapon_mount_state")
		if not bool(weapon_mount.get("scope_visible", false)):
			_fail("放大后武器占位未切到瞄准态")
		camera_controller.set_zoom(1.0)
		battle.call("_update_hud")
		await get_tree().process_frame

	var covers: Array = []
	if level_root != null:
		for child in level_root.get_children():
			if child is PveCoverObstacle3D:
				covers.append(child)
	if covers.size() < 4:
		_fail("掩体占位数量过少，无法充分验证遮挡")
	else:
		var style_texture_hits := {
			"wall_corner": ["env-wall-corner.svg", "wall_corner_cover.glb"],
			"street_lamp": ["env-street-lamp.svg", "street_lamp_cover.glb"],
			"parked_van": ["env-parked-van.svg", "parked_van_cover.glb"],
			"billboard": ["env-billboard.svg", "billboard_cover.glb"],
		}
		for cover_node in covers:
			if cover_node != null and cover_node.has_method("get_visual_asset_state"):
				var cover_visual: Dictionary = cover_node.call("get_visual_asset_state")
				var style_id: String = str(cover_visual.get("style_id", ""))
				var textures: Array = cover_visual.get("textures", [])
				var asset_path: String = str(cover_visual.get("asset_path", ""))
				var expected_fragments: Array = style_texture_hits.get(style_id, [])
				var matched := expected_fragments.is_empty()
				for texture_path in textures:
					for fragment in expected_fragments:
						if str(texture_path).find(str(fragment)) != -1:
							matched = true
							break
					if matched:
						break
				if not matched:
					for fragment in expected_fragments:
						if asset_path.find(str(fragment)) != -1:
							matched = true
							break
				if not matched:
					_fail("环境占位 %s 未挂载对应素材或 3D 资产" % style_id)

		var lamp_cover: PveCoverObstacle3D = null
		var billboard_cover: PveCoverObstacle3D = null
		var wall_cover: PveCoverObstacle3D = null
		for cover_node in covers:
			if cover_node == null:
				continue
			if str(cover_node.style_id) == "street_lamp" and lamp_cover == null:
				lamp_cover = cover_node
			elif str(cover_node.style_id) == "billboard" and billboard_cover == null:
				billboard_cover = cover_node
			elif str(cover_node.style_id) == "wall_corner" and wall_cover == null:
				wall_cover = cover_node

		if lamp_cover != null:
			lamp_cover.apply_impact_feedback(lamp_cover.global_position + Vector3(0.0, 1.4, 0.0), Vector3.BACK, "metal", "light")
			await get_tree().process_frame
			if lamp_cover.has_method("get_visual_asset_state"):
				var lamp_visual: Dictionary = lamp_cover.call("get_visual_asset_state")
				if int(lamp_visual.get("blast_detached_count", 0)) <= 0:
					_fail("路灯受爆炸冲击后未生成弹开件")
				if str(lamp_visual.get("last_blast_tier", "")) != "light":
					_fail("路灯未记录轻爆档位")
		else:
			_fail("未找到可测试的路灯掩体")

		if billboard_cover != null:
			billboard_cover.apply_impact_feedback(billboard_cover.global_position + Vector3(0.0, 1.6, 0.0), Vector3.BACK, "metal", "medium")
			await get_tree().process_frame
			if billboard_cover.has_method("get_visual_asset_state"):
				var billboard_visual: Dictionary = billboard_cover.call("get_visual_asset_state")
				if int(billboard_visual.get("blast_detached_count", 0)) <= 0:
					_fail("广告牌受爆炸冲击后未生成弹开件")
				if str(billboard_visual.get("last_blast_tier", "")) != "medium":
					_fail("广告牌未记录中爆档位")
		else:
			_fail("未找到可测试的广告牌掩体")

		if wall_cover != null:
			wall_cover.apply_impact_feedback(wall_cover.global_position + Vector3(0.0, 1.5, 0.0), Vector3.BACK, "concrete", "heavy")
			await get_tree().process_frame
			if wall_cover.has_method("get_visual_asset_state"):
				var wall_visual: Dictionary = wall_cover.call("get_visual_asset_state")
				if int(wall_visual.get("blast_detached_count", 0)) <= 0:
					_fail("墙角重爆后未生成崩边碎块")
				if str(wall_visual.get("last_blast_tier", "")) != "heavy":
					_fail("墙角未记录重爆档位")
		else:
			_fail("未找到可测试的墙角掩体")

		var cover: PveCoverObstacle3D = covers[0]
		cover.apply_bullet_hit(cover.global_position + Vector3(0.0, 1.2, 0.0), Vector3.BACK)
		cover.apply_bullet_hit(cover.global_position + Vector3(0.1, 1.0, 0.0), Vector3.BACK)
		cover.apply_bullet_hit(cover.global_position + Vector3(-0.1, 0.9, 0.0), Vector3.BACK)
		await get_tree().process_frame
		if cover.has_method("get_visual_asset_state"):
			var hit_visual: Dictionary = cover.call("get_visual_asset_state")
			var decal_textures: Array = hit_visual.get("decal_textures", [])
			var decal_count: int = int(hit_visual.get("decal_count", 0))
			var has_bullet_hole := false
			var has_cover_impact := false
			for decal_path in decal_textures:
				if str(decal_path).find("decal-bullet-hole-placeholder.svg") != -1:
					has_bullet_hole = true
				if str(decal_path).find("decal-cover-impact-mark-placeholder.svg") != -1:
					has_cover_impact = true
			if decal_count > 0:
				has_bullet_hole = true
				has_cover_impact = true
			if not has_bullet_hole:
				_fail("挡弹后未生成弹孔贴花素材")
			if not has_cover_impact:
				_fail("挡弹后未生成挡弹冲击贴花素材")
		if not cover.destroyed:
			_fail("掩体占位未能在多次命中后进入坍塌态")
		if cover.collider != null and not cover.collider.disabled:
			_fail("掩体坍塌后碰撞未关闭")
		cover.apply_bullet_hit(cover.global_position + Vector3(0.0, 0.8, 0.0), Vector3.BACK)
		cover.apply_impact_feedback(cover.global_position + Vector3(0.0, 1.0, 0.0), Vector3.BACK, "concrete", "heavy")
		cover.apply_bullet_hit(cover.global_position + Vector3(0.1, 0.7, 0.0), Vector3.BACK)
		for _i in range(24):
			await get_tree().process_frame
		if is_instance_valid(cover):
			if cover.has_method("get_visual_asset_state"):
				var collapse_visual: Dictionary = cover.call("get_visual_asset_state")
				if not bool(collapse_visual.get("removal_started", false)):
					_fail("掩体坍塌后继续受击未进入移除流程")
				if float(collapse_visual.get("collapse_progress", 0.0)) < 0.95:
					_fail("掩体坍塌后继续受击未持续推进塌陷")
			else:
				_fail("掩体坍塌后未被移除")

	var visual_feedback = battle.get("visual_feedback")
	if visual_feedback == null:
		_fail("缺少 3D 反馈控制器")
	else:
		visual_feedback.spawn_hit_effect(Vector3(0.0, 1.0, 0.0), Vector3.UP, "blocked")
		await get_tree().process_frame
		if visual_feedback.hit_effects.size() <= 0:
			_fail("3D 命中反馈未生成")

	_finish()


func _finish() -> void:
	var status := "PASS" if _failures.is_empty() else "FAIL"
	if status == "PASS":
		print("[PLACEHOLDER_3D_SMOKE] PASS")
	else:
		for failure in _failures:
			print("[PLACEHOLDER_3D_SMOKE] FAIL: %s" % failure)
	_write_result(status, _failures)
	smoke_finished.emit(status, _failures.duplicate())
	_teardown()


func _teardown() -> void:
	if _is_embedded:
		if not skip_return_navigation:
			CoreEventBus.test_center_requested.emit()
			await get_tree().process_frame
	elif auto_quit:
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
			get_tree().quit(0 if _failures.is_empty() else 1)
		)


func _assert_scene(root: Node, expected_path: String, message: String) -> void:
	var current_screen: Node = root.get("current_screen")
	if current_screen == null:
		_fail("%s：当前场景为空" % message)
		return
	var current_path: String = str(root.get("current_scene_path"))
	if current_path != expected_path:
		_fail("%s：实际是 %s" % [message, current_path])


func _wait_for_scene(root: Node, expected_path: String, max_frames: int = 120) -> void:
	for _i in range(max_frames):
		await get_tree().process_frame
		var scene_ready := str(root.get("current_scene_path")) == expected_path and root.get("current_screen") != null
		var transition_done := true
		if root.has_method("_debug_is_transitioning"):
			transition_done = not bool(root.call("_debug_is_transitioning"))
		if scene_ready and transition_done:
			return
	_fail("等待场景切换超时：%s" % expected_path)


func _assert_method(target: Object, method_name: String, message: String) -> void:
	if not target.has_method(method_name):
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://placeholder_3d_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 placeholder_3d_smoke_result.txt")
		return
	var time_str := Time.get_datetime_string_from_system(true, true)
	file.store_line("PLACEHOLDER_3D_SMOKE=%s" % status)
	file.store_line("TIMESTAMP=%s" % time_str)
	if not failures.is_empty():
		for failure in failures:
			file.store_line(str(failure))


func _find_child_recursive(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	for child in root.get_children():
		if str(child.name) == node_name:
			return child
		var found := _find_child_recursive(child, node_name)
		if found != null:
			return found
	return null


func _has_prefixed_child_recursive(root: Node, prefix: String) -> bool:
	if root == null:
		return false
	for child in root.get_children():
		if str(child.name).begins_with(prefix):
			return true
		if _has_prefixed_child_recursive(child, prefix):
			return true
	return false
