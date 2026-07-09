extends Node

const InputBootstrap = preload("res://scripts/core/core_input_bootstrap.gd")
const LOADING_SCOPE_ART = preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const MenuScene = preload("res://scenes/menu/menu_main_menu.tscn")
const BattleScene = preload("res://scenes/pve/pve_battle_main.tscn")
const ResultScene = preload("res://scenes/ui/ui_panel_result.tscn")
const UpgradeScene = preload("res://scenes/ui/ui_panel_upgrade.tscn")
const SettingsScene = preload("res://scenes/ui/ui_panel_settings.tscn")
const TuningScene = preload("res://scenes/ui/ui_panel_tuning.tscn")
const WeaponLibraryScene = preload("res://scenes/ui/ui_panel_weapon_library.tscn")
const ShopScene = preload("res://scenes/ui/ui_panel_shop.tscn")
const TestCenterScene = preload("res://scenes/ui/ui_panel_test_center.tscn")
const PvpLobbyScene = preload("res://scenes/pvp/pvp_lobby.tscn")
const PvpNetworkRoomScene = preload("res://scenes/pvp/pvp_network_room.tscn")

@onready var screen_layer: CanvasLayer = $ScreenLayer

var current_screen: Node
var current_scene_path: String = ""
var route_feedback_layer: CanvasLayer
var route_feedback_panel: PanelContainer
var route_feedback_label: Label
var transition_layer: CanvasLayer
var transition_overlay: ColorRect
var transition_card: PanelContainer
var transition_title_label: Label
var transition_hint_label: Label
var transition_dots_label: Label
var transition_art: TextureRect
var transition_in_progress := false
var transition_tick := 0.0

const TRANSITION_SHOW_SEC := 0.42
const TRANSITION_HIDE_SEC := 0.18

const PORTRAIT_VIEWPORT_SIZE := Vector2(720, 1280)

var battle_scene_paths: Array[String] = [
	"res://scenes/pve/pve_battle_main.tscn",
	"res://scenes/pvp/pvp_network_room.tscn",
]


func _ready() -> void:
	InputBootstrap.ensure_default_input_map()
	_bind_event_bus()
	_bind_route_guard()
	_bind_global_ui_click_sfx()
	_build_route_feedback_layer()
	_build_transition_layer()
	_bind_display_mode()
	_apply_display_mode_for_scene(MenuScene.resource_path)
	_show_scene(MenuScene)
	# 背景音乐：在根节点启动后播放，避免被场景切换影响。
	if AudioService != null and AudioService.has_method("play_bgm"):
		AudioService.play_bgm("bgm_main")


func _bind_global_ui_click_sfx() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not tree.node_added.is_connected(_on_tree_node_added_for_ui_audio):
		tree.node_added.connect(_on_tree_node_added_for_ui_audio)
	# 场景已存在的节点也扫一遍，避免首次进入时漏绑。
	_scan_and_bind_buttons(tree.root)


func _on_tree_node_added_for_ui_audio(node: Node) -> void:
	if node is BaseButton and AudioService != null and AudioService.has_method("bind_ui_button"):
		AudioService.bind_ui_button(node)


func _scan_and_bind_buttons(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is BaseButton and AudioService != null and AudioService.has_method("bind_ui_button"):
		AudioService.bind_ui_button(root)
	for child in root.get_children():
		_scan_and_bind_buttons(child)


func _bind_display_mode() -> void:
	if not PlatformService.display_mode_changed.is_connected(_on_display_mode_changed):
		PlatformService.display_mode_changed.connect(_on_display_mode_changed)


func _on_display_mode_changed(_mode: String) -> void:
	_apply_display_mode_for_scene(current_scene_path)


func _process(delta: float) -> void:
	if not transition_in_progress:
		return
	transition_tick += delta
	if transition_dots_label != null and is_instance_valid(transition_dots_label):
		var dot_count := int(floor(transition_tick * 3.0)) % 4
		transition_dots_label.text = ".".repeat(dot_count)


func _bind_event_bus() -> void:
	if not CoreEventBus.main_menu_requested.is_connected(_on_main_menu_requested):
		CoreEventBus.main_menu_requested.connect(_on_main_menu_requested)

	if not CoreEventBus.level_requested.is_connected(_on_level_requested):
		CoreEventBus.level_requested.connect(_on_level_requested)

	if not CoreEventBus.pvp_lobby_requested.is_connected(_on_pvp_lobby_requested):
		CoreEventBus.pvp_lobby_requested.connect(_on_pvp_lobby_requested)

	if not CoreEventBus.pvp_network_room_requested.is_connected(_on_pvp_network_room_requested):
		CoreEventBus.pvp_network_room_requested.connect(_on_pvp_network_room_requested)

	if not CoreEventBus.battle_finished.is_connected(_on_battle_finished):
		CoreEventBus.battle_finished.connect(_on_battle_finished)

	if not CoreEventBus.retry_requested.is_connected(_on_retry_requested):
		CoreEventBus.retry_requested.connect(_on_retry_requested)

	if not CoreEventBus.upgrade_requested.is_connected(_on_upgrade_requested):
		CoreEventBus.upgrade_requested.connect(_on_upgrade_requested)

	if not CoreEventBus.next_level_requested.is_connected(_on_next_level_requested):
		CoreEventBus.next_level_requested.connect(_on_next_level_requested)

	if not CoreEventBus.settings_requested.is_connected(_on_settings_requested):
		CoreEventBus.settings_requested.connect(_on_settings_requested)

	if not CoreEventBus.tuning_requested.is_connected(_on_tuning_requested):
		CoreEventBus.tuning_requested.connect(_on_tuning_requested)

	if not CoreEventBus.weapon_library_requested.is_connected(_on_weapon_library_requested):
		CoreEventBus.weapon_library_requested.connect(_on_weapon_library_requested)

	if not CoreEventBus.shop_requested.is_connected(_on_shop_requested):
		CoreEventBus.shop_requested.connect(_on_shop_requested)

	if not CoreEventBus.test_center_requested.is_connected(_on_test_center_requested):
		CoreEventBus.test_center_requested.connect(_on_test_center_requested)


func _show_scene(scene_resource: PackedScene) -> void:
	if transition_in_progress:
		return
	var resolved_scene_path: String = scene_resource.resource_path
	_apply_display_mode_for_scene(resolved_scene_path)
	if is_instance_valid(current_screen):
		await _play_scene_transition(resolved_scene_path)
		if is_instance_valid(current_screen):
			current_screen.queue_free()
		else:
			transition_in_progress = false
	else:
		current_scene_path = resolved_scene_path
		current_screen = scene_resource.instantiate()
		screen_layer.add_child(current_screen)
		RouteGuard.confirm_scene(resolved_scene_path)
		call_deferred("_confirm_scene_deferred", resolved_scene_path)
		return

	current_scene_path = resolved_scene_path
	current_screen = scene_resource.instantiate()
	screen_layer.add_child(current_screen)
	RouteGuard.confirm_scene(resolved_scene_path)
	call_deferred("_confirm_scene_deferred", resolved_scene_path)
	await _finish_scene_transition()


func _confirm_scene_deferred(scene_path: String) -> void:
	RouteGuard.confirm_scene(scene_path)


func _bind_route_guard() -> void:
	if not RouteGuard.feedback_changed.is_connected(_on_route_feedback_changed):
		RouteGuard.feedback_changed.connect(_on_route_feedback_changed)


func _build_route_feedback_layer() -> void:
	route_feedback_layer = CanvasLayer.new()
	route_feedback_layer.layer = 50
	add_child(route_feedback_layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_left = 20.0
	margin.offset_top = 18.0
	margin.offset_right = -20.0
	margin.offset_bottom = 94.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_feedback_layer.add_child(margin)

	route_feedback_panel = PanelContainer.new()
	route_feedback_panel.visible = false
	route_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(route_feedback_panel)

	route_feedback_label = Label.new()
	route_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	route_feedback_label.custom_minimum_size = Vector2(0, 44)
	route_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_feedback_panel.add_child(route_feedback_label)


func _build_transition_layer() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 80
	add_child(transition_layer)

	transition_overlay = ColorRect.new()
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = Color(0.02, 0.04, 0.06, 0.0)
	transition_overlay.visible = false
	transition_layer.add_child(transition_overlay)

	transition_card = PanelContainer.new()
	transition_card.anchor_left = 0.5
	transition_card.anchor_top = 0.5
	transition_card.anchor_right = 0.5
	transition_card.anchor_bottom = 0.5
	transition_card.offset_left = -250.0
	transition_card.offset_top = -180.0
	transition_card.offset_right = 250.0
	transition_card.offset_bottom = 180.0
	transition_card.visible = false
	transition_layer.add_child(transition_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	transition_card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	transition_art = TextureRect.new()
	transition_art.texture = LOADING_SCOPE_ART
	transition_art.custom_minimum_size = Vector2(0, 176)
	transition_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	transition_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vbox.add_child(transition_art)

	transition_title_label = Label.new()
	transition_title_label.text = "正在切换页面"
	transition_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(transition_title_label)

	transition_hint_label = Label.new()
	transition_hint_label.text = "正在校准作战终端，请稍候"
	transition_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transition_hint_label.modulate = Color(0.82, 0.9, 0.98)
	transition_hint_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(transition_hint_label)

	transition_dots_label = Label.new()
	transition_dots_label.text = ""
	transition_dots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_dots_label.modulate = Color(0.97, 0.80, 0.42)
	transition_dots_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(transition_dots_label)


func _play_scene_transition(scene_path: String) -> void:
	transition_in_progress = true
	transition_tick = 0.0
	if transition_overlay != null and is_instance_valid(transition_overlay):
		transition_overlay.visible = true
		transition_overlay.color.a = 0.82
	if transition_card != null and is_instance_valid(transition_card):
		transition_card.visible = true
	if transition_title_label != null and is_instance_valid(transition_title_label):
		transition_title_label.text = _resolve_transition_title(scene_path)
	if transition_hint_label != null and is_instance_valid(transition_hint_label):
		transition_hint_label.text = _resolve_transition_hint(scene_path)
	if transition_dots_label != null and is_instance_valid(transition_dots_label):
		transition_dots_label.text = ""
	await get_tree().create_timer(TRANSITION_SHOW_SEC).timeout


func _finish_scene_transition() -> void:
	await get_tree().create_timer(TRANSITION_HIDE_SEC).timeout
	transition_in_progress = false
	transition_tick = 0.0
	if transition_overlay != null and is_instance_valid(transition_overlay):
		transition_overlay.visible = false
		transition_overlay.color.a = 0.0
	if transition_card != null and is_instance_valid(transition_card):
		transition_card.visible = false
	if transition_dots_label != null and is_instance_valid(transition_dots_label):
		transition_dots_label.text = ""


func _resolve_transition_title(scene_path: String) -> String:
	match scene_path:
		MenuScene.resource_path:
			return "返回主菜单"
		BattleScene.resource_path:
			return "正在进入任务"
		ShopScene.resource_path:
			return "正在打开商店"
		WeaponLibraryScene.resource_path:
			return "正在打开武器库"
		SettingsScene.resource_path:
			return "正在打开操作手感设置"
		TuningScene.resource_path:
			return "正在打开调参面板"
		TestCenterScene.resource_path:
			return "正在打开测试中心"
		ResultScene.resource_path:
			return "正在打开结算页"
		UpgradeScene.resource_path:
			return "正在打开升级页"
		PvpLobbyScene.resource_path:
			return "正在进入局域网对战"
		PvpNetworkRoomScene.resource_path:
			return "正在进入联机房间"
		_:
			return "正在切换页面"


func _resolve_transition_hint(scene_path: String) -> String:
	match scene_path:
		BattleScene.resource_path:
			return "正在装填视野、目标与作战信息，请稍候"
		ShopScene.resource_path, WeaponLibraryScene.resource_path:
			return "正在同步资源与页面内容，请稍候"
		PvpLobbyScene.resource_path, PvpNetworkRoomScene.resource_path:
			return "正在连接联机流程，请稍候"
		_:
			return "正在校准作战终端，请稍候"


func _debug_is_transitioning() -> bool:
	return transition_in_progress


func _apply_display_mode_for_scene(scene_path: String) -> void:
	var window := get_window()
	if window == null:
		return
	if _is_battle_scene(scene_path):
		if PlatformService.is_portrait_display_mode():
			window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		else:
			window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	else:
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _is_battle_scene(scene_path: String) -> bool:
	for path in battle_scene_paths:
		if scene_path == path:
			return true
	return false


func _on_route_feedback_changed(status: String, message: String, visible: bool) -> void:
	if route_feedback_panel == null or route_feedback_label == null:
		return

	route_feedback_panel.visible = visible
	route_feedback_label.text = message

	match status:
		RouteGuard.STATUS_PENDING:
			route_feedback_label.modulate = Color(0.98, 0.93, 0.72)
		RouteGuard.STATUS_FAILED:
			route_feedback_label.modulate = Color(1.0, 0.72, 0.72)
		_:
			route_feedback_label.modulate = Color(1, 1, 1)


func _on_main_menu_requested() -> void:
	_show_scene(MenuScene)


func _on_level_requested(level_id: int) -> void:
	var resolved_level = min(level_id, CoreGameState.unlocked_levels)
	CoreGameState.start_level(resolved_level)
	_show_scene(BattleScene)


func _on_pvp_lobby_requested() -> void:
	CoreEventBus.log_event("pvp_lobby_entered", {})
	_show_scene(PvpLobbyScene)


func _on_pvp_network_room_requested() -> void:
	CoreEventBus.log_event("pvp_network_room_entered", {
		"is_server": NetworkManager.is_server,
		"peer_count": NetworkManager.get_peer_count(),
	})
	_show_scene(PvpNetworkRoomScene)


func _on_battle_finished(result: Dictionary) -> void:
	CoreGameState.finish_battle(result)
	if bool(result.get("success", false)) and AudioService != null and AudioService.has_method("play_ui"):
		AudioService.play_ui("ui_result_win")
	_show_scene(ResultScene)


func _on_retry_requested() -> void:
	CoreGameState.start_level(CoreGameState.current_level_id)
	_show_scene(BattleScene)


func _on_upgrade_requested() -> void:
	_show_scene(UpgradeScene)


func _on_next_level_requested() -> void:
	if CoreGameState.can_go_next_level():
		CoreGameState.advance_to_next_level()
		CoreGameState.start_level(CoreGameState.current_level_id)
		_show_scene(BattleScene)
	else:
		_show_scene(MenuScene)


func _on_settings_requested() -> void:
	_show_scene(SettingsScene)


func _on_tuning_requested() -> void:
	_show_scene(TuningScene)


func _on_weapon_library_requested() -> void:
	_show_scene(WeaponLibraryScene)


func _on_shop_requested() -> void:
	_show_scene(ShopScene)


func _on_test_center_requested() -> void:
	_show_scene(TestCenterScene)
