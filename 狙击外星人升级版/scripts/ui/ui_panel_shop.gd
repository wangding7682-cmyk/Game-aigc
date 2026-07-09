extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const _WeaponPreviewCatalog = preload("res://scripts/ui/weapon_preview_catalog.gd")
const SHOP_TAB_WEAPON_ACTIVE := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-tab-weapon-active.svg")
const SHOP_TAB_SKIN_ACTIVE := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-tab-skin-active.svg")
const SHOP_TAB_ITEM_ACTIVE := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-tab-item-active.svg")
const SHOP_CURRENCY_BAR := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-header-currency-bar.svg")
const SHOP_WEAPON_CARD_OWNED := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-weapon-card-owned.svg")
const SHOP_ITEM_CARD_BUYABLE := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-item-card-buyable.svg")
const SHOP_SKIN_CARD_LOCKED := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-skin-card-locked.svg")
const SHOP_BUY_ENABLED := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-buy-button-enabled.svg")
const SHOP_BUY_DISABLED := preload("res://assets_mvp_placeholder/ui_kit/shop/shop-buy-button-disabled.svg")

var weapon_tab: Button
var skin_tab: Button
var item_tab: Button
var content_panel: ScrollContainer
var back_button: Button
var feedback_label: Label
var gold_label: Label
var title_label: Label
var summary_label: Label
var hint_label: Label
var active_tab_preview: TextureRect

var current_tab: String = "weapon"


func _ready() -> void:
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_switch_tab("weapon")

	ShopService.purchase_succeeded.connect(_on_purchase_succeeded)
	ShopService.purchase_failed.connect(_on_purchase_failed)


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
	root_margin.add_theme_constant_override("margin_right", 28)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 14)
	root_margin.add_child(shell)

	var header_panel := PanelContainer.new()
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
	eyebrow.text = "作战补给站"
	eyebrow.modulate = Color(0.90, 0.95, 1.0, 0.94)
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_constant_override("outline_size", 5)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	title_box.add_child(eyebrow)

	title_label = Label.new()
	title_label.text = "商店"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_constant_override("outline_size", 7)
	title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	title_box.add_child(title_label)

	gold_label = Label.new()
	gold_label.text = "金币：%d" % CoreGameState.player_gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.custom_minimum_size = Vector2(156, 36)
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.add_theme_constant_override("outline_size", 4)
	gold_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.09))
	_apply_label_badge_style(gold_label)
	top_row.add_child(gold_label)

	back_button = Button.new()
	back_button.text = "返回主页"
	back_button.custom_minimum_size = Vector2(124, 46)
	back_button.pressed.connect(func() -> void:
		RouteGuard.request_route("main_menu", "商店-返回主页")
	)
	_apply_action_button_style(back_button, "secondary")
	top_row.add_child(back_button)

	summary_label = Label.new()
	summary_label.text = "为下一次任务补齐武器、皮肤与道具。首屏先提供页签和购买入口，低频说明下沉到滚动内容里。"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.modulate = Color(0.84, 0.90, 0.98)
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_constant_override("line_separation", 4)
	header_vbox.add_child(summary_label)

	hint_label = Label.new()
	hint_label.text = "优先补给：武器 > 皮肤 > 道具。页签切换后，下方主列表会直接更新。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color(0.96, 0.80, 0.42)
	hint_label.add_theme_font_size_override("font_size", 14)
	header_vbox.add_child(hint_label)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 8)
	header_vbox.add_child(tab_hbox)

	weapon_tab = Button.new()
	weapon_tab.text = "武器"
	weapon_tab.custom_minimum_size = Vector2(0, 64)
	weapon_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_tab.pressed.connect(func() -> void:
		_switch_tab("weapon")
	)
	_apply_action_button_style(weapon_tab, "tab")
	tab_hbox.add_child(weapon_tab)

	skin_tab = Button.new()
	skin_tab.text = "皮肤"
	skin_tab.custom_minimum_size = Vector2(0, 64)
	skin_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_tab.pressed.connect(func() -> void:
		_switch_tab("skin")
	)
	_apply_action_button_style(skin_tab, "tab")
	tab_hbox.add_child(skin_tab)

	item_tab = Button.new()
	item_tab.text = "道具"
	item_tab.custom_minimum_size = Vector2(0, 64)
	item_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_tab.pressed.connect(func() -> void:
		_switch_tab("item")
	)
	_apply_action_button_style(item_tab, "tab")
	tab_hbox.add_child(item_tab)

	active_tab_preview = TextureRect.new()
	active_tab_preview.custom_minimum_size = Vector2(0, 84)
	active_tab_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	active_tab_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	active_tab_preview.modulate = Color(1.0, 1.0, 1.0, 0.96)
	header_vbox.add_child(active_tab_preview)

	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.add_theme_font_size_override("font_size", 15)
	header_vbox.add_child(feedback_label)

	var content_wrap := PanelContainer.new()
	content_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_surface_panel_style(content_wrap, false)
	shell.add_child(content_wrap)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 16)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 16)
	content_margin.add_theme_constant_override("margin_bottom", 16)
	content_wrap.add_child(content_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	content_margin.add_child(content_vbox)

	var section_title := Label.new()
	section_title.text = "补给清单"
	section_title.add_theme_font_size_override("font_size", 22)
	content_vbox.add_child(section_title)

	var section_note := Label.new()
	section_note.text = "首屏优先展示可购买内容，详细说明和较长列表自动进入滚动。"
	section_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_note.modulate = Color(0.78, 0.86, 0.96)
	section_note.add_theme_font_size_override("font_size", 14)
	content_vbox.add_child(section_note)

	content_panel = ScrollContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_panel.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_vbox.add_child(content_panel)


func _switch_tab(tab: String, preserve_feedback: bool = false) -> void:
	current_tab = tab

	weapon_tab.modulate = Color(1.0, 1.0, 1.0) if tab == "weapon" else Color(0.5, 0.5, 0.5)
	skin_tab.modulate = Color(1.0, 1.0, 1.0) if tab == "skin" else Color(0.5, 0.5, 0.5)
	item_tab.modulate = Color(1.0, 1.0, 1.0) if tab == "item" else Color(0.5, 0.5, 0.5)
	weapon_tab.icon = null
	skin_tab.icon = null
	item_tab.icon = null
	if active_tab_preview != null and is_instance_valid(active_tab_preview):
		active_tab_preview.texture = _resolve_tab_preview_texture(tab)

	if not preserve_feedback:
		feedback_label.text = ""
	if gold_label != null and is_instance_valid(gold_label):
		gold_label.text = "金币：%d" % CoreGameState.player_gold
	if title_label != null and is_instance_valid(title_label):
		title_label.text = "商店 · %s" % _resolve_tab_title(tab)
	if summary_label != null and is_instance_valid(summary_label):
		summary_label.text = _resolve_tab_summary(tab)
	if hint_label != null and is_instance_valid(hint_label):
		hint_label.text = _resolve_tab_hint(tab)

	match tab:
		"weapon":
			_show_weapon_shop()
		"skin":
			_show_skin_shop()
		"item":
			_show_item_shop()


func _show_weapon_shop() -> void:
	for child in content_panel.get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	content_panel.add_child(vbox)

	for weapon_config in WeaponManager.get_all_weapon_configs():
		var is_unlocked := WeaponManager.is_weapon_unlocked(weapon_config.weapon_id)

		var entry := _make_shop_entry_panel()
		vbox.add_child(entry)
		var item_hbox: HBoxContainer = entry.get_meta("row")

		var weapon_preview := _make_card_preview(WeaponPreviewCatalog.get_weapon_preview(weapon_config.weapon_id))
		weapon_preview.name = "WeaponShopPreview_%s" % weapon_config.weapon_id
		weapon_preview.modulate = Color(1.0, 1.0, 1.0, 0.98) if is_unlocked else Color(0.72, 0.72, 0.72, 0.86)
		item_hbox.add_child(weapon_preview)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 6)
		item_hbox.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = weapon_config.display_name
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", weapon_config.get_rarity_color())
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = weapon_config.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(desc_label)

		var stat_label := Label.new()
		stat_label.text = "缩放 %.1f-%.1fx · 待机散布 %.1f · 屏息散布 %.1f" % [
			weapon_config.zoom_min,
			weapon_config.zoom_max,
			weapon_config.spread_idle,
			weapon_config.spread_hold,
		]
		stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stat_label.modulate = Color(0.74, 0.84, 0.94)
		stat_label.add_theme_font_size_override("font_size", 13)
		info_vbox.add_child(stat_label)

		var action_vbox := _make_entry_action_box()
		item_hbox.add_child(action_vbox)

		var status_chip := _make_entry_chip("状态")
		action_vbox.add_child(status_chip)

		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(136, 46)

		if is_unlocked:
			buy_button.text = "已拥有"
			buy_button.disabled = true
			buy_button.modulate = Color(0.5, 0.8, 0.5)
			status_chip.text = "已拥有"
		elif weapon_config.price_gold == 0:
			buy_button.text = "免费"
			buy_button.modulate = Color(0.5, 0.8, 0.5)
			status_chip.text = "免费领取"
			buy_button.pressed.connect(func(config: Resource = weapon_config) -> void:
				ShopService.buy_weapon(config.weapon_id)
			)
		else:
			buy_button.text = "%d 金币" % weapon_config.price_gold
			buy_button.disabled = not ShopService.can_buy_weapon(weapon_config.weapon_id)
			buy_button.modulate = Color(1.0, 1.0, 1.0) if ShopService.can_buy_weapon(weapon_config.weapon_id) else Color(0.5, 0.5, 0.5)
			status_chip.text = "售价 %d" % weapon_config.price_gold
			buy_button.pressed.connect(func(config: Resource = weapon_config) -> void:
				ShopService.buy_weapon(config.weapon_id)
			)

		action_vbox.add_child(buy_button)
		_apply_buy_button_visual(buy_button, not buy_button.disabled)


func _show_skin_shop() -> void:
	for child in content_panel.get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	content_panel.add_child(vbox)

	for skin_config in WeaponManager.get_all_skin_configs():
		var is_unlocked := WeaponManager.is_skin_unlocked(skin_config.skin_id)
		var weapon_unlocked := WeaponManager.is_weapon_unlocked(skin_config.weapon_id)

		var entry := _make_shop_entry_panel()
		vbox.add_child(entry)
		var item_hbox: HBoxContainer = entry.get_meta("row")

		var preview_texture: Texture2D = WeaponPreviewCatalog.get_weapon_preview(skin_config.weapon_id)
		var skin_preview := _make_card_preview(preview_texture)
		skin_preview.name = "SkinShopPreview_%s" % skin_config.skin_id
		skin_preview.modulate = Color(1.0, 1.0, 1.0, 0.98) if is_unlocked else Color(0.72, 0.72, 0.72, 0.82)
		item_hbox.add_child(skin_preview)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 6)
		item_hbox.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = skin_config.display_name
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", skin_config.get_rarity_color())
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		var weapon_name: String = ""
		var weapon_config: Resource = WeaponManager.get_weapon_config(skin_config.weapon_id)
		if weapon_config:
			weapon_name = weapon_config.display_name
		else:
			weapon_name = "未知武器"
		desc_label.text = "%s - %s" % [weapon_name, skin_config.description]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(desc_label)

		var rarity_label := Label.new()
		rarity_label.text = "所属武器：%s · 稀有度颜色已同步" % weapon_name
		rarity_label.modulate = Color(0.74, 0.84, 0.94)
		rarity_label.add_theme_font_size_override("font_size", 13)
		info_vbox.add_child(rarity_label)

		var action_vbox := _make_entry_action_box()
		item_hbox.add_child(action_vbox)

		var status_chip := _make_entry_chip("状态")
		action_vbox.add_child(status_chip)

		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(136, 46)

		if is_unlocked:
			buy_button.text = "已拥有"
			buy_button.disabled = true
			buy_button.modulate = Color(0.5, 0.8, 0.5)
			status_chip.text = "已解锁"
		elif not weapon_unlocked:
			buy_button.text = "需解锁武器"
			buy_button.disabled = true
			buy_button.modulate = Color(0.5, 0.5, 0.5)
			status_chip.text = "前置未满足"
		else:
			buy_button.text = "%d 金币" % skin_config.price_gold
			buy_button.disabled = not ShopService.can_buy_skin(skin_config.skin_id)
			buy_button.modulate = Color(1.0, 1.0, 1.0) if ShopService.can_buy_skin(skin_config.skin_id) else Color(0.5, 0.5, 0.5)
			status_chip.text = "售价 %d" % skin_config.price_gold
			buy_button.pressed.connect(func(config: Resource = skin_config) -> void:
				ShopService.buy_skin(config.skin_id)
			)

		action_vbox.add_child(buy_button)
		_apply_buy_button_visual(buy_button, not buy_button.disabled)


func _show_item_shop() -> void:
	for child in content_panel.get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	content_panel.add_child(vbox)

	var items := {
		"scan_radar": {"name": "扫描雷达", "desc": "扫描全屏，所有外星人高亮3秒", "price": 200},
		"freeze_bomb": {"name": "冰冻弹", "desc": "冻结所有移动外星人5秒", "price": 300},
		"precision_locator": {"name": "精准定位", "desc": "直接标记1个最难找的外星人", "price": 150},
		"time_extend": {"name": "时间延长", "desc": "增加30秒限时", "price": 250},
		"range_scan": {"name": "范围扫描", "desc": "扫描指定区域，高亮该区域外星人", "price": 100},
	}

	for item_id in items:
		var item_info: Dictionary = items[item_id]
		var current_count: int = InventoryService.get_item_count(item_id)

		var entry := _make_shop_entry_panel()
		vbox.add_child(entry)
		var item_hbox: HBoxContainer = entry.get_meta("row")

		item_hbox.add_child(_make_card_preview(SHOP_ITEM_CARD_BUYABLE))

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 6)
		item_hbox.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = "%s (库存: %d)" % [item_info["name"], current_count]
		name_label.add_theme_font_size_override("font_size", 20)
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = item_info["desc"]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(desc_label)

		var stock_label := Label.new()
		stock_label.text = "当前库存：%d" % current_count
		stock_label.modulate = Color(0.74, 0.84, 0.94)
		stock_label.add_theme_font_size_override("font_size", 13)
		info_vbox.add_child(stock_label)

		var action_vbox := _make_entry_action_box()
		item_hbox.add_child(action_vbox)

		var status_chip := _make_entry_chip("状态")
		status_chip.text = "售价 %d" % item_info["price"]
		action_vbox.add_child(status_chip)

		var buy_button := Button.new()
		buy_button.custom_minimum_size = Vector2(136, 46)
		buy_button.text = "%d 金币" % item_info["price"]

		var can_buy: bool = CoreGameState.player_gold >= item_info["price"]
		buy_button.disabled = not can_buy
		buy_button.modulate = Color(1.0, 1.0, 1.0) if can_buy else Color(0.5, 0.5, 0.5)
		if not can_buy:
			status_chip.text = "金币不足"

		buy_button.pressed.connect(func(id: String = str(item_id), price: int = int(item_info["price"])) -> void:
			if InventoryService.buy_item(id, price):
				_switch_tab("item")
				feedback_label.text = "购买成功！"
				feedback_label.modulate = Color(0.5, 1.0, 0.5)
			else:
				feedback_label.text = "金币不足"
				feedback_label.modulate = Color(1.0, 0.5, 0.5)
		)

		action_vbox.add_child(buy_button)
		_apply_buy_button_visual(buy_button, can_buy)


func _on_purchase_succeeded(_item_type: String, _item_id: String, _price_gold: int, _price_diamond: int) -> void:
	feedback_label.text = "购买成功！"
	feedback_label.modulate = Color(0.5, 1.0, 0.5)
	call_deferred("_switch_tab", current_tab, true)


func _on_purchase_failed(_item_type: String, _item_id: String, reason: String) -> void:
	feedback_label.text = "购买失败：%s" % reason
	feedback_label.modulate = Color(1.0, 0.5, 0.5)


func _make_card_preview(texture: Texture2D) -> Control:
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(164, 88)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate = Color(1.0, 1.0, 1.0, 0.96)
	return preview


func _make_shop_entry_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_surface_panel_style(panel, false)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	panel.set_meta("row", row)
	return panel


func _make_entry_action_box() -> VBoxContainer:
	var action_vbox := VBoxContainer.new()
	action_vbox.custom_minimum_size = Vector2(144, 0)
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.add_theme_constant_override("separation", 8)
	return action_vbox


func _make_entry_chip(text_value: String) -> Label:
	var chip := Label.new()
	chip.text = text_value
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.custom_minimum_size = Vector2(0, 32)
	chip.add_theme_font_size_override("font_size", 13)
	chip.add_theme_constant_override("outline_size", 3)
	chip.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07, 0.92))
	_apply_label_badge_style(chip)
	return chip


func _apply_buy_button_visual(button: Button, enabled: bool) -> void:
	button.icon = SHOP_BUY_ENABLED if enabled else SHOP_BUY_DISABLED
	button.expand_icon = true


func _resolve_tab_title(tab: String) -> String:
	match tab:
		"weapon":
			return "武器补给"
		"skin":
			return "皮肤补给"
		"item":
			return "道具补给"
		_:
			return "补给"


func _resolve_tab_summary(tab: String) -> String:
	match tab:
		"weapon":
			return "优先保证主战武器的稳定性与稀有度提升。这里展示武器购买状态、稀有度与是否已拥有。"
		"skin":
			return "皮肤页保留原有解锁和购买逻辑，但会明确告诉你对应武器与当前解锁前提，避免像后台配置页。"
		"item":
			return "道具页更强调战前补给和库存状态，让购买行为更像战术准备，而不是机械点表。"
		_:
			return "为下一次任务补齐武器、皮肤与道具。"


func _resolve_tab_hint(tab: String) -> String:
	match tab:
		"weapon":
			return "建议先补武器，再根据预算决定皮肤与道具。"
		"skin":
			return "皮肤购买前会检查所属武器是否已解锁。"
		"item":
			return "道具页会同时显示库存，便于快速补充。"
		_:
			return "当前页签决定右侧清单内容。"


func _resolve_tab_preview_texture(tab: String) -> Texture2D:
	match tab:
		"weapon":
			return SHOP_TAB_WEAPON_ACTIVE
		"skin":
			return SHOP_TAB_SKIN_ACTIVE
		"item":
			return SHOP_TAB_ITEM_ACTIVE
		_:
			return null


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

	if tone == "tab":
		color = Color(0.12, 0.18, 0.27, 0.90)
		hover_color = Color(0.17, 0.25, 0.36, 0.98)
		pressed_color = Color(0.11, 0.17, 0.26, 0.98)
		focus_color = Color(0.20, 0.30, 0.42, 1.0)
		border_color = Color(0.58, 0.74, 0.94, 0.40)

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
	if tone == "tab":
		button.add_theme_font_size_override("font_size", 18)
