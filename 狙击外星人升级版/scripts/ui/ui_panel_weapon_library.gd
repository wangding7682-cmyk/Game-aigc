extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const _WeaponPreviewCatalog = preload("res://scripts/ui/weapon_preview_catalog.gd")
const ARMORY_DETAIL_PANEL := preload("res://assets_mvp_placeholder/ui_kit/armory/armory-detail-panel.svg")
const ARMORY_EQUIP_BUTTON := preload("res://assets_mvp_placeholder/ui_kit/armory/armory-equip-button.svg")
const ARMORY_SKIN_EQUIPPED := preload("res://assets_mvp_placeholder/ui_kit/armory/armory-skin-list-card-equipped.svg")
const ARMORY_SKIN_LOCKED := preload("res://assets_mvp_placeholder/ui_kit/armory/armory-skin-list-card-locked.svg")

var weapon_list: VBoxContainer
var skin_list: VBoxContainer
var detail_panel: PanelContainer
var equip_button: Button
var back_button: Button
var hero_title_label: Label
var summary_label: Label
var hint_label: Label
var gold_label: Label
var detail_preview: TextureRect
var detail_name_label: Label
var detail_desc_label: Label
var detail_stats_label: Label
var detail_readiness_label: Label
var detail_skin_label: Label
var _header_fade_tween: Tween
var _detail_fade_tween: Tween

var selected_weapon: Resource = null
var selected_skin: Resource = null


func _ready() -> void:
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_refresh_weapon_list()


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = MENU_KEY_ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var tint := ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.02, 0.04, 0.06, 0.72)
	add_child(tint)

	var top_glow := ColorRect.new()
	top_glow.anchor_left = 0.0
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 1.0
	top_glow.anchor_bottom = 0.22
	top_glow.color = Color(0.08, 0.15, 0.24, 0.26)
	add_child(top_glow)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 28)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 14)
	root_margin.add_child(shell)

	var header_panel := PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 154)
	_apply_surface_panel_style(header_panel, true)
	shell.add_child(header_panel)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_top", 16)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_bottom", 16)
	header_panel.add_child(header_margin)

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 10)
	header_margin.add_child(header_vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	header_vbox.add_child(top_row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	top_row.add_child(title_box)

	var eyebrow := Label.new()
	eyebrow.text = "装备管理终端"
	eyebrow.modulate = Color(0.90, 0.95, 1.0, 0.94)
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_constant_override("outline_size", 5)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	title_box.add_child(eyebrow)

	hero_title_label = Label.new()
	hero_title_label.text = "武器库"
	hero_title_label.add_theme_font_size_override("font_size", 34)
	hero_title_label.add_theme_constant_override("outline_size", 7)
	hero_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	title_box.add_child(hero_title_label)

	gold_label = Label.new()
	gold_label.text = "金币：%d" % CoreGameState.player_gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.custom_minimum_size = Vector2(128, 36)
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.add_theme_constant_override("outline_size", 4)
	gold_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.09))
	_apply_label_badge_style(gold_label)
	top_row.add_child(gold_label)

	equip_button = Button.new()
	equip_button.text = "装备"
	equip_button.icon = ARMORY_EQUIP_BUTTON
	equip_button.expand_icon = true
	equip_button.custom_minimum_size = Vector2(112, 46)
	equip_button.disabled = true
	equip_button.pressed.connect(func() -> void:
		_try_equip()
	)
	_apply_action_button_style(equip_button, "primary")
	top_row.add_child(equip_button)

	back_button = Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(92, 46)
	back_button.pressed.connect(func() -> void:
		RouteGuard.request_route("main_menu", "武器库-返回主页")
	)
	_apply_action_button_style(back_button, "secondary")
	top_row.add_child(back_button)

	summary_label = Label.new()
	summary_label.text = "在正式出击前确认主武器、皮肤和装备状态。首屏优先保留选择、详情和装备动作。"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.custom_minimum_size = Vector2(0, 42)
	summary_label.modulate = Color(0.84, 0.90, 0.98)
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_constant_override("line_separation", 4)
	header_vbox.add_child(summary_label)

	hint_label = Label.new()
	hint_label.text = "上方先选武器和皮肤，下方确认详情后即可装备。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(0, 22)
	hint_label.modulate = Color(0.96, 0.80, 0.42)
	hint_label.add_theme_font_size_override("font_size", 14)
	header_vbox.add_child(hint_label)

	var list_row := HBoxContainer.new()
	list_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_row.add_theme_constant_override("separation", 10)
	shell.add_child(list_row)

	var weapon_panel := PanelContainer.new()
	weapon_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_panel.size_flags_stretch_ratio = 0.95
	_apply_surface_panel_style(weapon_panel, false)
	list_row.add_child(weapon_panel)

	var weapon_margin := MarginContainer.new()
	weapon_margin.add_theme_constant_override("margin_left", 14)
	weapon_margin.add_theme_constant_override("margin_top", 14)
	weapon_margin.add_theme_constant_override("margin_right", 14)
	weapon_margin.add_theme_constant_override("margin_bottom", 14)
	weapon_panel.add_child(weapon_margin)

	var weapon_vbox := VBoxContainer.new()
	weapon_vbox.add_theme_constant_override("separation", 8)
	weapon_margin.add_child(weapon_vbox)

	var weapon_title := Label.new()
	weapon_title.text = "武器列表"
	weapon_title.add_theme_font_size_override("font_size", 20)
	weapon_vbox.add_child(weapon_title)

	var weapon_scroll := ScrollContainer.new()
	weapon_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	weapon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	weapon_vbox.add_child(weapon_scroll)

	weapon_list = VBoxContainer.new()
	weapon_list.add_theme_constant_override("separation", 6)
	weapon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_scroll.add_child(weapon_list)

	var skin_panel := PanelContainer.new()
	skin_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skin_panel.size_flags_stretch_ratio = 1.05
	_apply_surface_panel_style(skin_panel, false)
	list_row.add_child(skin_panel)

	var skin_margin := MarginContainer.new()
	skin_margin.add_theme_constant_override("margin_left", 14)
	skin_margin.add_theme_constant_override("margin_top", 14)
	skin_margin.add_theme_constant_override("margin_right", 14)
	skin_margin.add_theme_constant_override("margin_bottom", 14)
	skin_panel.add_child(skin_margin)

	var skin_vbox := VBoxContainer.new()
	skin_vbox.add_theme_constant_override("separation", 8)
	skin_margin.add_child(skin_vbox)

	var skin_title := Label.new()
	skin_title.text = "皮肤列表"
	skin_title.add_theme_font_size_override("font_size", 20)
	skin_vbox.add_child(skin_title)

	var skin_scroll := ScrollContainer.new()
	skin_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skin_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	skin_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	skin_vbox.add_child(skin_scroll)

	skin_list = VBoxContainer.new()
	skin_list.add_theme_constant_override("separation", 6)
	skin_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_scroll.add_child(skin_list)

	detail_panel = PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.custom_minimum_size = Vector2(0, 336)
	_apply_surface_panel_style(detail_panel, false)
	shell.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 16)
	detail_margin.add_theme_constant_override("margin_top", 14)
	detail_margin.add_theme_constant_override("margin_right", 16)
	detail_margin.add_theme_constant_override("margin_bottom", 14)
	detail_panel.add_child(detail_margin)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_vbox)
	detail_panel.set_meta("detail_vbox", detail_vbox)

	var detail_title := Label.new()
	detail_title.text = "装备详情"
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_vbox.add_child(detail_title)

	detail_preview = TextureRect.new()
	detail_preview.texture = ARMORY_DETAIL_PANEL
	detail_preview.custom_minimum_size = Vector2(0, 196)
	detail_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_vbox.add_child(detail_preview)

	var detail_content := VBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 8)
	detail_vbox.add_child(detail_content)
	detail_panel.set_meta("detail_content", detail_content)

	detail_name_label = Label.new()
	detail_name_label.text = "选择一把武器查看详情"
	detail_name_label.add_theme_font_size_override("font_size", 24)
	detail_content.add_child(detail_name_label)

	detail_desc_label = Label.new()
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.custom_minimum_size = Vector2(0, 46)
	detail_content.add_child(detail_desc_label)

	detail_stats_label = Label.new()
	detail_stats_label.custom_minimum_size = Vector2(0, 106)
	detail_content.add_child(detail_stats_label)

	detail_readiness_label = Label.new()
	detail_readiness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_readiness_label.custom_minimum_size = Vector2(0, 32)
	detail_readiness_label.modulate = Color(0.84, 0.90, 0.98)
	detail_content.add_child(detail_readiness_label)

	detail_skin_label = Label.new()
	detail_skin_label.custom_minimum_size = Vector2(0, 26)
	detail_skin_label.add_theme_font_size_override("font_size", 18)
	detail_content.add_child(detail_skin_label)


func _refresh_weapon_list() -> void:
	for child in weapon_list.get_children():
		child.queue_free()

	for weapon_config in WeaponManager.get_all_weapon_configs():
		var weapon_id: String = weapon_config.weapon_id
		var is_unlocked: bool = WeaponManager.is_weapon_unlocked(weapon_id)
		var is_equipped: bool = WeaponManager.equipped_weapon_id == weapon_id

		var button := Button.new()
		button.name = "WeaponEntry_%s" % weapon_id
		button.text = "%s%s" % [
			"已装备 | " if is_equipped else "",
			weapon_config.display_name
		]
		button.custom_minimum_size = Vector2(0, 96)
		button.modulate = Color(1.0, 1.0, 1.0) if is_unlocked else Color(0.5, 0.5, 0.5)
		button.icon = WeaponPreviewCatalog.get_weapon_preview(weapon_id)
		button.expand_icon = true

		var rarity_color: Color = weapon_config.get_rarity_color()
		button.add_theme_color_override("font_color", rarity_color)

		button.pressed.connect(func(config: Resource = weapon_config) -> void:
			_selected_weapon(config)
		)

		weapon_list.add_child(button)


func _refresh_skin_list() -> void:
	for child in skin_list.get_children():
		child.queue_free()

	if not selected_weapon:
		return

	var skins: Array = WeaponManager.get_all_skin_configs()
	for skin_config in skins:
		var skin_weapon_id: String = skin_config.weapon_id
		if skin_weapon_id != selected_weapon.weapon_id:
			continue

		var skin_id: String = skin_config.skin_id
		var is_unlocked: bool = WeaponManager.is_skin_unlocked(skin_id)
		var is_equipped: bool = WeaponManager.equipped_skin_ids.get(selected_weapon.weapon_id, "") == skin_id

		var button := Button.new()
		button.text = "%s%s" % [
			"已装备 | " if is_equipped else "",
			skin_config.display_name
		]
		button.custom_minimum_size = Vector2(0, 60)
		button.modulate = Color(1.0, 1.0, 1.0) if is_unlocked else Color(0.5, 0.5, 0.5)
		button.icon = ARMORY_SKIN_EQUIPPED if is_equipped else ARMORY_SKIN_LOCKED
		button.expand_icon = true

		var rarity_color: Color = skin_config.get_rarity_color()
		button.add_theme_color_override("font_color", rarity_color)

		button.pressed.connect(func(config: Resource = skin_config) -> void:
			_selected_skin(config)
		)

		skin_list.add_child(button)


func _selected_weapon(weapon_config: Resource) -> void:
	selected_weapon = weapon_config
	selected_skin = null

	_refresh_skin_list()
	_update_detail_panel()
	_update_equip_button()
	_refresh_header_copy()


func _selected_skin(skin_config: Resource) -> void:
	selected_skin = skin_config
	_update_detail_panel()
	_update_equip_button()
	_refresh_header_copy()


func _update_detail_panel() -> void:
	if detail_preview != null and is_instance_valid(detail_preview):
		detail_preview.texture = WeaponPreviewCatalog.get_weapon_preview(selected_weapon.weapon_id) if selected_weapon else ARMORY_DETAIL_PANEL

	if detail_name_label == null or not is_instance_valid(detail_name_label):
		return

	if not selected_weapon:
		detail_name_label.text = "选择一把武器查看详情"
		detail_name_label.remove_theme_color_override("font_color")
		detail_desc_label.text = "选中武器后，这里会显示武器简介、核心参数和当前工程接入状态。"
		detail_stats_label.text = ""
		detail_readiness_label.text = ""
		detail_skin_label.text = ""
		_play_detail_copy_fade()
		return

	if selected_weapon:
		detail_name_label.text = selected_weapon.display_name
		detail_name_label.add_theme_color_override("font_color", selected_weapon.get_rarity_color())
		detail_desc_label.text = selected_weapon.description
		detail_stats_label.text = "缩放倍率: %.1f-%.2fx\n待机散布: %.1f\n屏息散布: %.1f\n屏息时间: %.2fs\n默认皮肤: %s" % [
			selected_weapon.zoom_min,
			selected_weapon.zoom_max,
			selected_weapon.spread_idle,
			selected_weapon.spread_hold,
			selected_weapon.hold_stabilize_sec,
			selected_weapon.default_skin_id,
		]
		detail_readiness_label.text = _build_weapon_readiness_text(selected_weapon)

	if selected_skin:
		detail_skin_label.text = "皮肤: %s" % selected_skin.display_name
		detail_skin_label.add_theme_color_override("font_color", selected_skin.get_rarity_color())
	else:
		detail_skin_label.text = ""
		detail_skin_label.remove_theme_color_override("font_color")
	_play_detail_copy_fade()


func _build_weapon_readiness_text(weapon_config: Resource) -> String:
	var geometry_type: String = str(weapon_config.geometry_type)
	var geometry_label := geometry_type
	match geometry_type:
		"precision":
			geometry_label = "精准型几何"
		"auto":
			geometry_label = "连发型几何"
		"plasma":
			geometry_label = "电磁型几何"
		_:
			geometry_label = "标准型几何"
	return "当前工程已为 `%s` 绑定独立预览卡与 `%s`，后续可直接对接更高完成度模型替换。" % [
		weapon_config.weapon_id,
		geometry_label,
	]


func _update_equip_button() -> void:
	if selected_weapon and WeaponManager.is_weapon_unlocked(selected_weapon.weapon_id):
		equip_button.disabled = false
		if selected_skin:
			equip_button.text = "装备皮肤"
		else:
			equip_button.text = "装备武器"
	else:
		equip_button.disabled = true
	equip_button.modulate = Color(1.0, 1.0, 1.0) if not equip_button.disabled else Color(0.56, 0.56, 0.56)


func _try_equip() -> void:
	if not selected_weapon:
		return

	if selected_skin:
		if WeaponManager.equip_skin(selected_weapon.weapon_id, selected_skin.skin_id):
			_refresh_skin_list()
	else:
		if WeaponManager.equip_weapon(selected_weapon.weapon_id):
			_refresh_weapon_list()

	_update_detail_panel()
	_refresh_header_copy()


func _refresh_header_copy() -> void:
	if gold_label != null and is_instance_valid(gold_label):
		gold_label.text = "金币：%d" % CoreGameState.player_gold
	if hero_title_label == null or not is_instance_valid(hero_title_label):
		return
	if selected_weapon == null:
		hero_title_label.text = "武器库"
		summary_label.text = "在正式出击前确认主武器、皮肤和装备状态。当前页保留全部选择与装备逻辑，但会更强调准备与比对，而不是配置表操作。"
		hint_label.text = "先选武器，再看皮肤，最后确认详情与装备动作。"
		_play_header_copy_fade()
		return
	hero_title_label.text = "武器库 · %s" % selected_weapon.display_name
	if selected_skin != null:
		summary_label.text = "当前正在检查 `%s` 与皮肤 `%s` 的组合状态。右侧会保留原有装备逻辑，但展示方式更偏装备确认页。" % [selected_weapon.display_name, selected_skin.display_name]
		hint_label.text = "确认皮肤稀有度与装备按钮状态后即可切换。"
	else:
		summary_label.text = "当前聚焦武器 `%s`。可以继续查看对应皮肤，或直接在右下完成装备。" % selected_weapon.display_name
		hint_label.text = "先看武器详情，再决定是否切到对应皮肤。"
	_play_header_copy_fade()


func _play_header_copy_fade() -> void:
	if summary_label == null or hint_label == null:
		return
	if _header_fade_tween != null and _header_fade_tween.is_valid():
		_header_fade_tween.kill()
	summary_label.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	_header_fade_tween = create_tween()
	_header_fade_tween.set_parallel(true)
	_header_fade_tween.tween_property(summary_label, "modulate:a", 0.98, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_header_fade_tween.tween_property(hint_label, "modulate:a", 1.0, 0.20).set_delay(0.03).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _play_detail_copy_fade() -> void:
	var labels: Array[Label] = [
		detail_name_label,
		detail_desc_label,
		detail_stats_label,
		detail_readiness_label,
		detail_skin_label,
	]
	if _detail_fade_tween != null and _detail_fade_tween.is_valid():
		_detail_fade_tween.kill()
	for label in labels:
		if label == null or not is_instance_valid(label):
			continue
		label.modulate.a = 0.0
	_detail_fade_tween = create_tween()
	_detail_fade_tween.set_parallel(true)
	var delay := 0.0
	for label in labels:
		if label == null or not is_instance_valid(label):
			continue
		_detail_fade_tween.tween_property(label, "modulate:a", 1.0, 0.18).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		delay += 0.025


func _apply_surface_panel_style(panel: PanelContainer, is_emphasis: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.shadow_size = 6
	style.shadow_color = Color(0.01, 0.02, 0.04, 0.22)
	if is_emphasis:
		style.bg_color = Color(0.10, 0.18, 0.28, 0.94)
		style.border_color = Color(0.60, 0.78, 1.0, 0.34)
	else:
		style.bg_color = Color(0.08, 0.13, 0.19, 0.88)
		style.border_color = Color(0.44, 0.58, 0.74, 0.22)
	panel.add_theme_stylebox_override("panel", style)


func _apply_label_badge_style(label: Label) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.18, 0.26, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.63, 0.78, 1.0, 0.32)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.01, 0.03, 0.05, 0.22)
	style.shadow_size = 4
	label.add_theme_stylebox_override("normal", style)


func _apply_action_button_style(button: Button, tone: String) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var focus := StyleBoxFlat.new()
	var disabled := StyleBoxFlat.new()
	var border_color := Color(0.42, 0.56, 0.72, 0.55)
	var color := Color(0.10, 0.16, 0.23, 0.94)
	var hover_color := Color(0.15, 0.22, 0.31, 0.98)
	var pressed_color := Color(0.08, 0.13, 0.19, 0.98)
	var focus_color := Color(0.18, 0.28, 0.40, 1.0)
	var disabled_color := Color(0.09, 0.12, 0.16, 0.62)

	if tone == "primary":
		color = Color(0.18, 0.35, 0.70, 0.98)
		hover_color = Color(0.24, 0.42, 0.82, 1.0)
		pressed_color = Color(0.14, 0.29, 0.58, 1.0)
		focus_color = Color(0.28, 0.47, 0.88, 1.0)
		disabled_color = Color(0.14, 0.22, 0.34, 0.68)
		border_color = Color(0.66, 0.82, 1.0, 0.72)

	for stylebox in [normal, hover, pressed, focus, disabled]:
		stylebox.corner_radius_top_left = 16
		stylebox.corner_radius_top_right = 16
		stylebox.corner_radius_bottom_left = 16
		stylebox.corner_radius_bottom_right = 16
		stylebox.content_margin_left = 14
		stylebox.content_margin_right = 14
		stylebox.content_margin_top = 10
		stylebox.content_margin_bottom = 10
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = border_color
		stylebox.shadow_color = Color(0.01, 0.02, 0.04, 0.20)
		stylebox.shadow_size = 4

	normal.bg_color = color
	hover.bg_color = hover_color
	pressed.bg_color = pressed_color
	focus.bg_color = focus_color
	disabled.bg_color = disabled_color

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.78, 0.86, 0.72))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07, 0.96))
	button.add_theme_constant_override("outline_size", 3)
