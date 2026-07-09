extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const _WeaponPreviewCatalog = preload("res://scripts/ui/weapon_preview_catalog.gd")

var gold_label: Label
var recommendation_label: Label
var primary_button: Button
var stability_card_box: VBoxContainer
var zoom_card_box: VBoxContainer
var next_button: Button
var title_label: Label
var weapon_preview: TextureRect
var weapon_summary_label: Label


func _ready() -> void:
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_refresh_ui()


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = MENU_KEY_ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var tint := ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.03, 0.04, 0.06, 0.78)
	add_child(tint)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 28)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_right", 28)
	root_margin.add_theme_constant_override("margin_bottom", 22)
	add_child(root_margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_margin.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	var top_panel := _make_section_panel(content)
	var top_box := top_panel.get_child(0) as VBoxContainer

	title_label = Label.new()
	title_label.text = "成长升级"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	top_box.add_child(title_label)

	var intro_label := Label.new()
	intro_label.text = "结算之后直接给出成长建议、升级候选和下一关动作，让主循环自然闭环。"
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.modulate = Color(0.84, 0.90, 0.98)
	top_box.add_child(intro_label)

	var top_art := TextureRect.new()
	top_art.texture = LOADING_SCOPE_ART
	top_art.custom_minimum_size = Vector2(0, 156)
	top_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	top_box.add_child(top_art)

	var hero_panel := _make_section_panel(content)
	var hero_box := hero_panel.get_child(0) as VBoxContainer

	var title := Label.new()
	title.text = "成长推荐"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	hero_box.add_child(title)

	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 34)
	hero_box.add_child(gold_label)

	recommendation_label = Label.new()
	recommendation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recommendation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recommendation_label.modulate = Color(0.82, 0.88, 0.98)
	hero_box.add_child(recommendation_label)

	weapon_preview = TextureRect.new()
	weapon_preview.custom_minimum_size = Vector2(0, 168)
	weapon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_box.add_child(weapon_preview)

	weapon_summary_label = Label.new()
	weapon_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_summary_label.modulate = Color(0.82, 0.90, 0.98)
	hero_box.add_child(weapon_summary_label)

	primary_button = Button.new()
	primary_button.custom_minimum_size = Vector2(0, 58)
	hero_box.add_child(primary_button)

	var cards_panel := _make_section_panel(content)
	var cards_box := cards_panel.get_child(0) as VBoxContainer
	_add_section_title(cards_box, "成长选项")

	stability_card_box = _make_upgrade_card(cards_box)
	zoom_card_box = _make_upgrade_card(cards_box)

	var summary_panel := _make_section_panel(content)
	var summary_box := summary_panel.get_child(0) as VBoxContainer
	_add_section_title(summary_box, "当前能力")

	var growth_detail_label := Label.new()
	growth_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_detail_label.modulate = Color(0.86, 0.90, 0.96)
	growth_detail_label.text = CoreGameState.get_growth_summary()
	summary_box.add_child(growth_detail_label)

	var action_panel := _make_section_panel(content)
	var action_box := action_panel.get_child(0) as VBoxContainer
	_add_section_title(action_box, "继续冒险")

	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(0, 50)
	next_button.pressed.connect(func() -> void:
		RouteGuard.request_route("next_level", "升级页-下一关")
	)
	action_box.add_child(next_button)

	var menu_button := Button.new()
	menu_button.text = "返回主页"
	menu_button.custom_minimum_size = Vector2(0, 46)
	menu_button.pressed.connect(func() -> void:
		RouteGuard.request_route("main_menu", "升级页-返回主页")
	)
	_apply_button_style(menu_button, "secondary")
	action_box.add_child(menu_button)


func _refresh_ui() -> void:
	var recommendation := CoreGameState.get_growth_recommendation()
	var recommended_upgrade := str(recommendation.get("recommended_upgrade", ""))
	var stability_data := CoreGameState.get_upgrade_card_data("stability")
	var zoom_data := CoreGameState.get_upgrade_card_data("zoom")
	var equipped_weapon: Resource = WeaponManager.get_equipped_weapon()

	gold_label.text = "当前金币：%d" % CoreGameState.player_gold
	recommendation_label.text = "%s\n%s" % [
		str(recommendation.get("headline", "继续推进关卡")),
		str(recommendation.get("body", "")),
	]
	if equipped_weapon:
		weapon_preview.texture = WeaponPreviewCatalog.get_weapon_preview(equipped_weapon.weapon_id)
		weapon_summary_label.text = "当前装备：%s\n缩放 %.1f-%.1fx · 待机散布 %.1f · 屏息散布 %.1f" % [
			equipped_weapon.display_name,
			equipped_weapon.zoom_min,
			equipped_weapon.zoom_max,
			equipped_weapon.spread_idle,
			equipped_weapon.spread_hold,
		]
	else:
		weapon_preview.texture = LOADING_SCOPE_ART
		weapon_summary_label.text = "当前尚未读取到武器配置。"

	_refresh_primary_button(recommended_upgrade, recommendation)
	_refresh_upgrade_card(stability_card_box, stability_data)
	_refresh_upgrade_card(zoom_card_box, zoom_data)

	next_button.text = "开始下一关" if CoreGameState.can_go_next_level() else "当前无下一关"
	next_button.disabled = not CoreGameState.can_go_next_level()
	_apply_button_style(next_button, "secondary")


func _refresh_primary_button(recommended_upgrade: String, recommendation: Dictionary) -> void:
	for connection in primary_button.pressed.get_connections():
		primary_button.pressed.disconnect(connection.callable)

	if recommended_upgrade != "" and CoreGameState.can_upgrade(recommended_upgrade):
		var card_data := CoreGameState.get_upgrade_card_data(recommended_upgrade)
		primary_button.text = "按建议升级%s\n%s" % [
			str(card_data.get("label", recommended_upgrade)),
			str(card_data.get("effect_next", "")),
		]
		primary_button.disabled = false
		primary_button.pressed.connect(func() -> void:
			_try_upgrade(recommended_upgrade)
		)
	else:
		primary_button.text = "当前推荐：%s\n金币暂时不够，先去下一关试试当前手感吧。" % str(recommendation.get("headline", "继续推进关卡"))
		primary_button.disabled = true

	_apply_button_style(primary_button, "primary")


func _try_upgrade(stat_name: String) -> void:
	var upgraded := CoreGameState.apply_upgrade(stat_name)
	if upgraded:
		CoreEventBus.log_event("upgrade_applied", {
			"stat_name": stat_name,
			"level": CoreGameState.get_upgrade_level(stat_name),
		})
	_refresh_ui()


func _refresh_upgrade_card(card_box: VBoxContainer, card_data: Dictionary) -> void:
	for child in card_box.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "%s Lv.%d%s" % [
		str(card_data.get("label", "")),
		int(card_data.get("current_level", 0)),
		" · 推荐" if bool(card_data.get("is_recommended", false)) else "",
	]
	title.add_theme_font_size_override("font_size", 22)
	card_box.add_child(title)

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.82, 0.88, 0.95)
	desc.text = str(card_data.get("description", ""))
	card_box.add_child(desc)

	var current_effect := Label.new()
	current_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_effect.text = str(card_data.get("effect_now", ""))
	card_box.add_child(current_effect)

	var next_effect := Label.new()
	next_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_effect.modulate = Color(0.72, 0.92, 0.82)
	next_effect.text = str(card_data.get("effect_next", ""))
	card_box.add_child(next_effect)

	var cost_label := Label.new()
	cost_label.text = "升级花费：%s" % str(card_data.get("cost_text", ""))
	cost_label.modulate = Color(0.98, 0.84, 0.46) if not bool(card_data.get("is_max", false)) else Color(0.75, 0.82, 0.9)
	card_box.add_child(cost_label)

	var action_button := Button.new()
	action_button.custom_minimum_size = Vector2(0, 48)
	action_button.text = "升级%s" % str(card_data.get("label", ""))
	action_button.disabled = not bool(card_data.get("can_upgrade", false))
	if bool(card_data.get("is_max", false)):
		action_button.text = "%s已满级" % str(card_data.get("label", ""))
	action_button.pressed.connect(func() -> void:
		_try_upgrade(str(card_data.get("stat_name", "")))
	)
	_apply_button_style(action_button, "primary" if bool(card_data.get("is_recommended", false)) else "secondary")
	card_box.add_child(action_button)


func _make_upgrade_card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box


func _make_section_panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return panel


func _add_section_title(parent: Node, title_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.82, 0.88, 0.98)
	parent.add_child(title)


func _apply_button_style(button: Button, tone: String) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var color := Color(0.18, 0.24, 0.32)
	var hover_color := Color(0.22, 0.29, 0.38)
	var pressed_color := Color(0.14, 0.20, 0.28)

	match tone:
		"primary":
			color = Color(0.27, 0.46, 0.92)
			hover_color = Color(0.35, 0.53, 0.98)
			pressed_color = Color(0.20, 0.38, 0.82)
		_:
			color = Color(0.18, 0.24, 0.32)
			hover_color = Color(0.22, 0.29, 0.38)
			pressed_color = Color(0.14, 0.20, 0.28)

	for stylebox in [normal, hover, pressed]:
		stylebox.corner_radius_top_left = 12
		stylebox.corner_radius_top_right = 12
		stylebox.corner_radius_bottom_right = 12
		stylebox.corner_radius_bottom_left = 12
		stylebox.content_margin_left = 12
		stylebox.content_margin_right = 12
		stylebox.content_margin_top = 10
		stylebox.content_margin_bottom = 10

	normal.bg_color = color
	hover.bg_color = hover_color
	pressed.bg_color = pressed_color
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
