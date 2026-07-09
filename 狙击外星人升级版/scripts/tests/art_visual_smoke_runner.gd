extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const MENU_SCENE_PATH := "res://scenes/menu/menu_main_menu.tscn"
const SHOP_SCENE_PATH := "res://scenes/ui/ui_panel_shop.tscn"
const WEAPON_LIBRARY_SCENE_PATH := "res://scenes/ui/ui_panel_weapon_library.tscn"
const BATTLE_SCENE_PATH := "res://scenes/pve/pve_battle_main.tscn"

signal smoke_finished(status: String, failures: Array)

var _failures: Array[String] = []
var auto_quit := true


func _ready() -> void:
	call_deferred("_start_test")


func _start_test() -> void:
	await _run()


func _run() -> void:
	CoreGameState.reset_progress()
	CoreGameState.tutorial_completed = true
	var root := ROOT_SCENE.instantiate()
	add_child(root)
	await _wait_for_scene(root, MENU_SCENE_PATH)

	_assert_scene(root, MENU_SCENE_PATH, "启动后应进入主菜单")
	var menu: Node = root.get("current_screen")
	if menu == null:
		_fail("主菜单未实例化")
		_finish()
		return
	_assert_has_texture(menu, "menu-key-art.jpg", "主菜单背景未挂载 menu-key-art.jpg")
	_assert_main_menu_actions(menu)

	CoreEventBus.shop_requested.emit()
	await _wait_for_scene(root, SHOP_SCENE_PATH)
	_assert_scene(root, SHOP_SCENE_PATH, "进入商店应打开商店页")
	var shop: Node = root.get("current_screen")
	if shop == null:
		_fail("商店页未实例化")
		_finish()
		return
	_assert_has_label_text(shop, "金币：", "商店页未显示金币徽标信息")
	_assert_has_texture(shop, "shop-tab-weapon-active.svg", "商店页未挂载武器页签素材")
	_assert_has_named_texture_rect(shop, "WeaponShopPreview_", "商店武器页未挂载武器预览卡")
	if shop.has_method("_switch_tab"):
		shop.call("_switch_tab", "skin")
		await get_tree().process_frame
		_assert_has_texture(shop, "shop-tab-skin-active.svg", "商店皮肤页未挂载皮肤页签素材")
		_assert_has_named_texture_rect(shop, "SkinShopPreview_", "商店皮肤页未挂载皮肤预览卡")
		shop.call("_switch_tab", "item")
		await get_tree().process_frame
		_assert_has_texture(shop, "shop-tab-item-active.svg", "商店道具页未挂载道具页签素材")

	CoreEventBus.weapon_library_requested.emit()
	await _wait_for_scene(root, WEAPON_LIBRARY_SCENE_PATH)
	_assert_scene(root, WEAPON_LIBRARY_SCENE_PATH, "进入武器库应打开武器库页")
	var library: Node = root.get("current_screen")
	if library == null:
		_fail("武器库页未实例化")
		_finish()
		return
	_assert_has_texture(library, "armory-detail-panel.svg", "武器库详情面板未挂载 armory-detail-panel.svg")
	_assert_has_named_button_icon(library, "WeaponEntry_", "武器库列表未挂载武器预览素材")
	if library.has_method("_selected_weapon"):
		var all_weapons = WeaponManager.get_all_weapon_configs()
		if not all_weapons.is_empty():
			library.call("_selected_weapon", all_weapons[0])
			await get_tree().process_frame
			_assert_has_button_icon(library, "armory-equip-button.svg", "武器库未挂载装备按钮素材")

	CoreEventBus.level_requested.emit(2)
	await _wait_for_scene(root, BATTLE_SCENE_PATH)
	_assert_scene(root, BATTLE_SCENE_PATH, "进入第 2 关应打开战斗场景")
	var battle: Node = root.get("current_screen")
	if battle == null:
		_fail("战斗场景未实例化")
		_finish()
		return
	var hud: Node = battle.get("hud")
	if hud == null:
		_fail("战斗 HUD 未实例化")
	else:
		_assert_has_texture(hud, "hud-health-bar.svg", "战斗 HUD 未挂载生命条素材")
		_assert_has_texture(hud, "hud-time-bar.svg", "战斗 HUD 未挂载时间条素材")
		_assert_has_texture(hud, "hud-target-lock-frame.svg", "战斗 HUD 未挂载锁定框素材")
		_assert_has_button_icon(hud, "icon-scan-radar.svg", "战斗 HUD 未挂载扫描按钮图标")
		_assert_has_button_icon(hud, "icon-time-extend.svg", "战斗 HUD 未挂载加时按钮图标")
		if hud.has_method("show_feedback"):
			hud.call("show_feedback", "扫描已触发", Color(0.8, 0.95, 1.0))
			await get_tree().process_frame
			_assert_has_texture(hud, "fx-scan-pulse.svg", "战斗 HUD 反馈未挂载扫描反馈素材")

	var weapon_renderer: Node = battle.get("weapon_renderer")
	if weapon_renderer == null:
		_fail("战斗内 3D 武器占位未挂载")
	elif weapon_renderer.has_method("get_mount_state"):
		var mount_state: Dictionary = weapon_renderer.call("get_mount_state")
		if str(mount_state.get("scene_track", "")).is_empty():
			_fail("战斗内 3D 武器未返回当前样枪轨道状态")
		elif str(mount_state.get("weapon_id", "")) == "default_sniper":
			var scene_track := str(mount_state.get("scene_track", ""))
			var attempted_scene_track := str(mount_state.get("attempted_scene_track", ""))
			var refined_available := bool(mount_state.get("sample_refined_available", false))
			if refined_available and attempted_scene_track != "sample_refined":
				_fail("标准狙击枪已存在样枪资源，但未切入 refined 轨道")
			elif not refined_available and attempted_scene_track != "legacy_default":
				_fail("标准狙击枪在样枪资源缺失时未尝试 legacy 轨道")
			if scene_track not in ["legacy_default", "procedural", "sample_refined"]:
				_fail("标准狙击枪返回了未知的实际显示轨道：%s" % scene_track)
		if str(mount_state.get("muzzle_flash_texture", "")).find("fx-muzzle-flash.svg") == -1:
			_fail("战斗内 3D 武器未挂载枪口火焰素材")

	_finish()


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


func _assert_has_texture(root: Node, path_fragment: String, message: String) -> void:
	if not _node_tree_has_texture(root, path_fragment):
		_fail(message)


func _assert_has_button_icon(root: Node, path_fragment: String, message: String) -> void:
	if not _node_tree_has_button_icon(root, path_fragment):
		_fail(message)


func _assert_has_named_button_icon(root: Node, name_fragment: String, message: String) -> void:
	if not _node_tree_has_named_button_icon(root, name_fragment):
		_fail(message)


func _assert_has_named_texture_rect(root: Node, name_fragment: String, message: String) -> void:
	if not _node_tree_has_named_texture_rect(root, name_fragment):
		_fail(message)


func _assert_has_label_text(root: Node, text_fragment: String, message: String) -> void:
	if not _node_tree_has_label_text(root, text_fragment):
		_fail(message)


func _assert_main_menu_actions(root: Node) -> void:
	var menu_buttons: Array[Button] = []
	for child in _collect_nodes(root):
		if child is Button and child.visible:
			menu_buttons.append(child)

	if menu_buttons.size() < 5:
		_fail("主菜单缺少足够的可操作入口，至少应保留继续、开局、设置与功能页按钮")
		return

	var has_continue_button := false
	var has_large_cta := false
	for button in menu_buttons:
		if button.text.find("继续当前关") != -1:
			has_continue_button = true
		if button.size.x >= 260.0 and button.size.y >= 46.0:
			has_large_cta = true

	if not has_continue_button:
		_fail("主菜单缺少继续当前关入口，玩家无法快速续接当前进度")

	if not has_large_cta:
		_fail("主菜单入口按钮可点击区域过小，已退化成接近纯文本的展示效果")


func _node_tree_has_texture(root: Node, path_fragment: String) -> bool:
	for child in _collect_nodes(root):
		if child is TextureRect:
			var texture: Texture2D = child.texture
			if texture != null and texture.resource_path.find(path_fragment) != -1:
				return true
	return false


func _node_tree_has_button_icon(root: Node, path_fragment: String) -> bool:
	for child in _collect_nodes(root):
		if child is Button:
			var icon: Texture2D = child.icon
			if icon != null and icon.resource_path.find(path_fragment) != -1:
				return true
	return false


func _node_tree_has_named_button_icon(root: Node, name_fragment: String) -> bool:
	for child in _collect_nodes(root):
		if child is Button and str(child.name).find(name_fragment) != -1:
			var icon: Texture2D = child.icon
			if icon != null:
				return true
	return false


func _node_tree_has_named_texture_rect(root: Node, name_fragment: String) -> bool:
	for child in _collect_nodes(root):
		if child is TextureRect and str(child.name).find(name_fragment) != -1 and child.texture != null:
			return true
	return false


func _node_tree_has_label_text(root: Node, text_fragment: String) -> bool:
	for child in _collect_nodes(root):
		if child is Label and str(child.text).find(text_fragment) != -1:
			return true
	return false


func _collect_nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = [root]
	for child in root.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _finish() -> void:
	var status := "PASS" if _failures.is_empty() else "FAIL"
	if status == "PASS":
		print("[ART_VISUAL_SMOKE] PASS")
	else:
		for failure in _failures:
			print("[ART_VISUAL_SMOKE] FAIL: %s" % failure)
	_write_result(status, _failures)
	smoke_finished.emit(status, _failures.duplicate())
	if auto_quit:
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
			get_tree().quit(0 if _failures.is_empty() else 1)
		)


func _fail(message: String) -> void:
	_failures.append(message)


func _write_result(status: String, failures: Array) -> void:
	var file := FileAccess.open("user://art_visual_smoke_result.txt", FileAccess.WRITE)
	if file == null:
		push_warning("无法写入 art_visual_smoke_result.txt")
		return
	file.store_line("ART_VISUAL_SMOKE=%s" % status)
	file.store_line("TIMESTAMP=%s" % Time.get_datetime_string_from_system(true, true))
	for failure in failures:
		file.store_line(str(failure))
