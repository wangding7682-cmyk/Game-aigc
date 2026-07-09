extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")

var rating_grade_label: Label
var rating_title_label: Label
var share_title_label: Label
var tag_flow: HFlowContainer
var record_label: Label
var total_reward_label: Label
var reward_rows_container: VBoxContainer
var stats_grid: GridContainer
var recommendation_headline_label: Label
var recommendation_body_label: Label
var growth_label: Label
var rec_strengths_container: HFlowContainer
var rec_weaknesses_container: HFlowContainer
var rec_suggestion_label: Label
var llm_title_label: Label
var llm_comment_label: Label
var llm_strengths_container: HFlowContainer
var llm_weaknesses_container: HFlowContainer
var llm_suggestion_label: Label
var llm_loading_label: Label
var primary_action_button: Button
var secondary_actions_container: VBoxContainer
var rewarded_ad_button: Button
var status_label: Label
var page_title_label: Label
var page_intro_label: Label


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
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	var top_panel := _make_section_panel(content)
	var top_box := top_panel.get_child(0) as VBoxContainer

	page_title_label = Label.new()
	page_title_label.text = "任务结算"
	page_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_title_label.add_theme_font_size_override("font_size", 32)
	top_box.add_child(page_title_label)

	page_intro_label = Label.new()
	page_intro_label.text = "查看你的本局战绩、获得奖励及成长建议，准备下一次挑战。"
	page_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_intro_label.modulate = Color(0.84, 0.90, 0.98)
	top_box.add_child(page_intro_label)

	var top_art := TextureRect.new()
	top_art.texture = LOADING_SCOPE_ART
	top_art.custom_minimum_size = Vector2(0, 156)
	top_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	top_box.add_child(top_art)

	var hero_panel := _make_section_panel(content)
	var hero_box := hero_panel.get_child(0) as VBoxContainer

	var page_title := Label.new()
	page_title.text = "单局战报"
	page_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_title.add_theme_font_size_override("font_size", 20)
	page_title.modulate = Color(0.86, 0.90, 0.98)
	hero_box.add_child(page_title)

	rating_grade_label = Label.new()
	rating_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating_grade_label.add_theme_font_size_override("font_size", 56)
	hero_box.add_child(rating_grade_label)

	rating_title_label = Label.new()
	rating_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating_title_label.add_theme_font_size_override("font_size", 28)
	hero_box.add_child(rating_title_label)

	share_title_label = Label.new()
	share_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	share_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	share_title_label.modulate = Color(0.82, 0.88, 0.98)
	hero_box.add_child(share_title_label)

	tag_flow = HFlowContainer.new()
	tag_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	tag_flow.add_theme_constant_override("h_separation", 10)
	tag_flow.add_theme_constant_override("v_separation", 10)
	hero_box.add_child(tag_flow)

	record_label = Label.new()
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	record_label.modulate = Color(0.98, 0.84, 0.42)
	hero_box.add_child(record_label)

	var reward_panel := _make_section_panel(content)
	var reward_box := reward_panel.get_child(0) as VBoxContainer
	_add_section_title(reward_box, "奖励拆分")

	total_reward_label = Label.new()
	total_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_reward_label.add_theme_font_size_override("font_size", 38)
	reward_box.add_child(total_reward_label)

	reward_rows_container = VBoxContainer.new()
	reward_rows_container.add_theme_constant_override("separation", 8)
	reward_box.add_child(reward_rows_container)

	var stats_panel := _make_section_panel(content)
	var stats_box := stats_panel.get_child(0) as VBoxContainer
	_add_section_title(stats_box, "战绩表现")

	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 10)
	stats_box.add_child(stats_grid)

	var growth_panel := _make_section_panel(content)
	var growth_box := growth_panel.get_child(0) as VBoxContainer
	_add_section_title(growth_box, "成长建议")

	recommendation_headline_label = Label.new()
	recommendation_headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	recommendation_headline_label.add_theme_font_size_override("font_size", 22)
	growth_box.add_child(recommendation_headline_label)

	recommendation_body_label = Label.new()
	recommendation_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recommendation_body_label.modulate = Color(0.86, 0.90, 0.96)
	growth_box.add_child(recommendation_body_label)

	rec_strengths_container = HFlowContainer.new()
	rec_strengths_container.alignment = FlowContainer.ALIGNMENT_BEGIN
	rec_strengths_container.add_theme_constant_override("h_separation", 8)
	rec_strengths_container.add_theme_constant_override("v_separation", 6)
	growth_box.add_child(rec_strengths_container)

	rec_weaknesses_container = HFlowContainer.new()
	rec_weaknesses_container.alignment = FlowContainer.ALIGNMENT_BEGIN
	rec_weaknesses_container.add_theme_constant_override("h_separation", 8)
	rec_weaknesses_container.add_theme_constant_override("v_separation", 6)
	growth_box.add_child(rec_weaknesses_container)

	rec_suggestion_label = Label.new()
	rec_suggestion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rec_suggestion_label.modulate = Color(0.70, 0.88, 1.0)
	growth_box.add_child(rec_suggestion_label)

	var growth_sep := HSeparator.new()
	growth_sep.modulate = Color(0.25, 0.30, 0.38)
	growth_box.add_child(growth_sep)

	growth_label = Label.new()
	growth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_label.modulate = Color(0.74, 0.84, 0.95)
	growth_box.add_child(growth_label)

	var llm_panel := _make_section_panel(content)
	var llm_box := llm_panel.get_child(0) as VBoxContainer
	_add_section_title(llm_box, "AI战术分析")

	llm_loading_label = Label.new()
	llm_loading_label.text = "正在分析你的战斗数据..."
	llm_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	llm_loading_label.modulate = Color(0.6, 0.75, 0.95)
	llm_loading_label.add_theme_font_size_override("font_size", 18)
	llm_box.add_child(llm_loading_label)

	llm_title_label = Label.new()
	llm_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	llm_title_label.add_theme_font_size_override("font_size", 28)
	llm_title_label.visible = false
	llm_box.add_child(llm_title_label)

	llm_comment_label = Label.new()
	llm_comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	llm_comment_label.modulate = Color(0.88, 0.92, 0.98)
	llm_comment_label.visible = false
	llm_box.add_child(llm_comment_label)

	llm_strengths_container = HFlowContainer.new()
	llm_strengths_container.alignment = FlowContainer.ALIGNMENT_BEGIN
	llm_strengths_container.add_theme_constant_override("h_separation", 8)
	llm_strengths_container.visible = false
	llm_box.add_child(llm_strengths_container)

	llm_weaknesses_container = HFlowContainer.new()
	llm_weaknesses_container.alignment = FlowContainer.ALIGNMENT_BEGIN
	llm_weaknesses_container.add_theme_constant_override("h_separation", 8)
	llm_weaknesses_container.visible = false
	llm_box.add_child(llm_weaknesses_container)

	llm_suggestion_label = Label.new()
	llm_suggestion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	llm_suggestion_label.modulate = Color(0.70, 0.88, 1.0)
	llm_suggestion_label.visible = false
	llm_box.add_child(llm_suggestion_label)

	var action_panel := _make_section_panel(content)
	var action_box := action_panel.get_child(0) as VBoxContainer
	_add_section_title(action_box, "下一步")

	primary_action_button = Button.new()
	primary_action_button.custom_minimum_size = Vector2(0, 60)
	action_box.add_child(primary_action_button)

	secondary_actions_container = VBoxContainer.new()
	secondary_actions_container.add_theme_constant_override("separation", 8)
	action_box.add_child(secondary_actions_container)

	var ad_panel := _make_section_panel(content)
	var ad_box := ad_panel.get_child(0) as VBoxContainer
	_add_section_title(ad_box, "额外收益")

	rewarded_ad_button = Button.new()
	rewarded_ad_button.text = "看视频，奖励翻倍"
	rewarded_ad_button.custom_minimum_size = Vector2(0, 50)
	rewarded_ad_button.pressed.connect(_on_rewarded_ad_pressed)
	ad_box.add_child(rewarded_ad_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.75, 0.82, 0.9)
	status_label.text = "看视频可以领取额外奖励，不会影响你的正常结算。"
	ad_box.add_child(status_label)


func _refresh_ui() -> void:
	var presentation: Dictionary = CoreGameState.get_last_result_presentation()
	var rating: Dictionary = presentation.get("rating", {})
	var recommendation: Dictionary = presentation.get("recommendation", {})
	var reward_rows: Array = presentation.get("reward_rows", [])
	var stats_rows: Array = presentation.get("stats_rows", [])
	var primary_action: Dictionary = presentation.get("primary_action", {})
	var secondary_actions: Array = presentation.get("secondary_actions", [])
	var result: Dictionary = CoreGameState.last_result

	rating_grade_label.text = str(rating.get("grade", "-"))
	rating_grade_label.modulate = _get_rating_color(str(rating.get("tone", "gray")))
	rating_title_label.text = "%s · %s" % [
		"通关成功" if bool(result.get("success", false)) else "任务失败",
		str(rating.get("title", "任务结算")),
	]
	share_title_label.text = str(presentation.get("share_title", ""))

	_refresh_tag_flow(
		_string_array_from_variant(presentation.get("highlight_tags", [])),
		_string_array_from_variant(presentation.get("record_flags", []))
	)

	var record_flags := _string_array_from_variant(presentation.get("record_flags", []))
	record_label.text = "纪录突破：%s" % " / ".join(record_flags) if not record_flags.is_empty() else ""
	record_label.visible = not record_flags.is_empty()

	total_reward_label.text = "本局金币 +%d" % int(result.get("reward_gold", 0))
	_refresh_reward_rows(reward_rows)
	_refresh_stats_grid(stats_rows)

	recommendation_headline_label.text = str(recommendation.get("headline", "继续推进关卡"))
	recommendation_body_label.text = str(recommendation.get("body", ""))

	var rec_strengths := _string_array_from_variant(recommendation.get("strengths", []))
	var rec_weaknesses := _string_array_from_variant(recommendation.get("weaknesses", []))
	var rec_suggestion := str(recommendation.get("suggestion", ""))

	_refresh_llm_tags(rec_strengths_container, rec_strengths, Color(0.15, 0.35, 0.15), Color(0.6, 1.0, 0.6))
	_refresh_llm_tags(rec_weaknesses_container, rec_weaknesses, Color(0.35, 0.15, 0.15), Color(1.0, 0.6, 0.6))

	if not rec_suggestion.is_empty():
		rec_suggestion_label.text = "💡 %s" % rec_suggestion
		rec_suggestion_label.visible = true
	else:
		rec_suggestion_label.visible = false

	growth_label.text = CoreGameState.get_growth_summary()

	_refresh_primary_action(primary_action)
	_refresh_secondary_actions(secondary_actions)

	rewarded_ad_button.disabled = bool(result.get("rewarded_ad_claimed", false))
	_apply_button_style(rewarded_ad_button, "accent")

	_start_llm_analysis(result)


func _refresh_tag_flow(highlight_tags: Array[String], record_flags: Array[String]) -> void:
	for child in tag_flow.get_children():
		child.queue_free()

	for tag_text in highlight_tags:
		tag_flow.add_child(_make_tag_chip(tag_text, Color(0.20, 0.28, 0.38), Color(0.92, 0.96, 1.0)))

	for tag_text in record_flags:
		tag_flow.add_child(_make_tag_chip(tag_text, Color(0.42, 0.31, 0.08), Color(1.0, 0.93, 0.66)))


func _refresh_reward_rows(reward_rows: Array) -> void:
	for child in reward_rows_container.get_children():
		child.queue_free()

	for row_data in reward_rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		reward_rows_container.add_child(row)

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = str(row_data.get("label", ""))
		row.add_child(name_label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var value := int(row_data.get("value", 0))
		value_label.text = "%+d" % value if value != 0 else "0"
		value_label.modulate = _get_reward_tone_color(str(row_data.get("tone", "neutral")))
		row.add_child(value_label)


func _refresh_stats_grid(stats_rows: Array) -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	for row_data in stats_rows:
		var panel := PanelContainer.new()
		stats_grid.add_child(panel)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)

		var label_node := Label.new()
		label_node.text = str(row_data.get("label", ""))
		label_node.modulate = Color(0.77, 0.83, 0.9)
		box.add_child(label_node)

		var value_node := Label.new()
		value_node.text = str(row_data.get("value", ""))
		value_node.add_theme_font_size_override("font_size", 22)
		box.add_child(value_node)


func _refresh_primary_action(primary_action: Dictionary) -> void:
	primary_action_button.text = "%s\n%s" % [
		str(primary_action.get("label", "继续")),
		str(primary_action.get("description", "")),
	]
	_apply_button_style(primary_action_button, "primary")

	for connection in primary_action_button.pressed.get_connections():
		primary_action_button.pressed.disconnect(connection.callable)

	var route := str(primary_action.get("route", "main_menu"))
	var label := str(primary_action.get("label", "继续"))
	primary_action_button.pressed.connect(func() -> void:
		RouteGuard.request_route(route, "结算页-%s" % label)
	)


func _refresh_secondary_actions(secondary_actions: Array) -> void:
	for child in secondary_actions_container.get_children():
		child.queue_free()

	for action_data in secondary_actions:
		var button := Button.new()
		button.text = str(action_data.get("label", ""))
		button.custom_minimum_size = Vector2(0, 46)
		button.disabled = not bool(action_data.get("enabled", true))
		_apply_button_style(button, "secondary")
		var route := str(action_data.get("route", "main_menu"))
		var label := str(action_data.get("label", "操作"))
		button.pressed.connect(func() -> void:
			RouteGuard.request_route(route, "结算页-%s" % label)
		)
		secondary_actions_container.add_child(button)


func _on_rewarded_ad_pressed() -> void:
	if bool(CoreGameState.last_result.get("rewarded_ad_claimed", false)):
		status_label.text = "本局奖励翻倍已领取。"
		return

	rewarded_ad_button.disabled = true
	status_label.text = "视频播放中，请稍候..."

	var bonus_reward: int = maxi(int(CoreGameState.last_result.get("base_reward_gold", 0)), 1)
	var ad_result: Dictionary = await PlatformService.show_rewarded_ad("result_double_reward")
	if bool(ad_result.get("ok", false)):
		CoreGameState.grant_reward_bonus(bonus_reward, "rewarded_ad")
		CoreEventBus.log_event("ad_reward_granted", {
			"placement": "result_double_reward",
			"bonus_reward_gold": bonus_reward,
		})
		status_label.text = "观看完成，额外奖励 %d 金币已到账！" % bonus_reward
	else:
		rewarded_ad_button.disabled = false
		status_label.text = "视频暂时无法播放，请稍后再试。"

	_refresh_ui()


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


func _make_tag_chip(text_value: String, background_color: Color, font_color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	chip.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text_value
	label.modulate = font_color
	chip.add_child(label)
	return chip


func _apply_button_style(button: Button, tone: String) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var color := Color(0.20, 0.25, 0.32)
	var hover_color := Color(0.24, 0.30, 0.38)
	var pressed_color := Color(0.18, 0.22, 0.28)

	match tone:
		"primary":
			color = Color(0.27, 0.46, 0.92)
			hover_color = Color(0.35, 0.53, 0.98)
			pressed_color = Color(0.20, 0.38, 0.82)
		"accent":
			color = Color(0.22, 0.56, 0.33)
			hover_color = Color(0.28, 0.64, 0.39)
			pressed_color = Color(0.18, 0.48, 0.29)
		"utility":
			color = Color(0.22, 0.24, 0.28)
			hover_color = Color(0.28, 0.30, 0.34)
			pressed_color = Color(0.16, 0.18, 0.22)
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


func _get_rating_color(tone: String) -> Color:
	match tone:
		"gold":
			return Color(1.0, 0.88, 0.38)
		"violet":
			return Color(0.84, 0.72, 1.0)
		"blue":
			return Color(0.70, 0.84, 1.0)
		"orange":
			return Color(1.0, 0.72, 0.36)
		"red":
			return Color(1.0, 0.46, 0.46)
	return Color(0.84, 0.88, 0.94)


func _get_reward_tone_color(tone: String) -> Color:
	match tone:
		"positive":
			return Color(0.55, 0.92, 0.60)
		"negative":
			return Color(1.0, 0.58, 0.58)
		"bonus":
			return Color(0.98, 0.85, 0.46)
		"total":
			return Color(1.0, 1.0, 1.0)
	return Color(0.82, 0.88, 0.95)


func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _start_llm_analysis(result: Dictionary) -> void:
	var llm_service = get_node_or_null("/root/LLMService")
	if llm_service == null:
		llm_loading_label.text = "AI分析服务未启动"
		llm_loading_label.visible = true
		return

	var level_id: int = int(result.get("level_id", -1))
	var has_cache: bool = llm_service.has_cached_analysis(level_id)
	if has_cache:
		llm_loading_label.visible = false
	else:
		llm_loading_label.visible = true

	llm_title_label.visible = false
	llm_comment_label.visible = false
	llm_strengths_container.visible = false
	llm_weaknesses_container.visible = false
	llm_suggestion_label.visible = false

	llm_service.analysis_completed.connect(_on_llm_analysis_completed)
	llm_service.analysis_failed.connect(_on_llm_analysis_failed)
	llm_service.analyze_battle_result(result)


func _on_llm_analysis_completed(analysis: Dictionary) -> void:
	llm_loading_label.visible = false

	var title := str(analysis.get("title", ""))
	var comment := str(analysis.get("comment", ""))
	var strengths := _string_array_from_variant(analysis.get("strengths", []))
	var weaknesses := _string_array_from_variant(analysis.get("weaknesses", []))
	var suggestion := str(analysis.get("suggestion", ""))

	if title.is_empty() and comment.is_empty() and suggestion.is_empty():
		llm_loading_label.text = "暂无分析数据"
		llm_loading_label.visible = true
		return

	if not title.is_empty():
		llm_title_label.text = title
		llm_title_label.visible = true

	if not comment.is_empty():
		llm_comment_label.text = comment
		llm_comment_label.visible = true

	_refresh_llm_tags(llm_strengths_container, strengths, Color(0.15, 0.35, 0.15), Color(0.6, 1.0, 0.6))

	_refresh_llm_tags(llm_weaknesses_container, weaknesses, Color(0.35, 0.15, 0.15), Color(1.0, 0.6, 0.6))

	if not suggestion.is_empty():
		llm_suggestion_label.text = "💡 %s" % suggestion
		llm_suggestion_label.visible = true

	_update_growth_recommendation_with_llm(analysis)


func _update_growth_recommendation_with_llm(analysis: Dictionary) -> void:
	var suggestion := str(analysis.get("suggestion", ""))
	var comment := str(analysis.get("comment", ""))
	var weaknesses := _string_array_from_variant(analysis.get("weaknesses", []))
	var strengths := _string_array_from_variant(analysis.get("strengths", []))
	var recommended_upgrade := str(analysis.get("recommended_upgrade", ""))

	if not suggestion.is_empty():
		recommendation_headline_label.text = suggestion
	elif weaknesses.size() > 0:
		recommendation_headline_label.text = "重点改进：%s" % weaknesses[0]

	if not comment.is_empty():
		recommendation_body_label.text = comment

	if strengths.size() > 0:
		_refresh_llm_tags(rec_strengths_container, strengths, Color(0.15, 0.35, 0.15), Color(0.6, 1.0, 0.6))
	if weaknesses.size() > 0:
		_refresh_llm_tags(rec_weaknesses_container, weaknesses, Color(0.35, 0.15, 0.15), Color(1.0, 0.6, 0.6))

	if not suggestion.is_empty():
		rec_suggestion_label.text = "💡 %s" % suggestion
		rec_suggestion_label.visible = true

	if not recommended_upgrade.is_empty():
		var upgrade_name := "稳定性" if recommended_upgrade == "stability" else "缩放倍率"
		growth_label.text = "推荐优先升级：%s\n%s" % [upgrade_name, CoreGameState.get_growth_summary()]
	else:
		growth_label.text = CoreGameState.get_growth_summary()


func _on_llm_analysis_failed(error: String) -> void:
	llm_loading_label.text = "分析失败：%s" % error
	llm_loading_label.modulate = Color(1.0, 0.5, 0.5)


func _refresh_llm_tags(container: HFlowContainer, tags: Array[String], bg_color: Color, font_color: Color) -> void:
	for child in container.get_children():
		child.queue_free()

	if tags.is_empty():
		container.visible = false
		return

	for tag_text in tags:
		container.add_child(_make_tag_chip(tag_text, bg_color, font_color))

	container.visible = true
