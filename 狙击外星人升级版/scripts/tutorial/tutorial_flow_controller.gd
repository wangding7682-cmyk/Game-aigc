extends Control

var _collapsed := false
var _cached_title := "教程"
var _cached_progress := ""
var _cached_body := ""
var _cached_tint := Color(0.85, 0.9, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var toggle_button: Button = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/HeaderRow/ToggleButton")
	if toggle_button != null and not toggle_button.pressed.is_connected(_on_toggle_pressed):
		toggle_button.pressed.connect(_on_toggle_pressed)
	var guide_panel: PanelContainer = get_node_or_null("GuidePanel")
	if guide_panel != null:
		guide_panel.modulate = Color(0.90, 0.95, 1.0, 0.96)
	_refresh_block("等待教程数据...", "", "", Color(0.85, 0.9, 1.0))


func show_step(step_data: Dictionary) -> void:
	# step_data 形如：
	# {
	#   "title": "...",
	#   "description": "...",
	#   "expected_text": "...",
	#   "index": 1,
	#   "total": 5
	# }
	if step_data.is_empty():
		_refresh_block("教程", "教程未启用", "", Color(0.8, 0.86, 0.95))
		return

	var title := str(step_data.get("title", "教程"))
	var index := int(step_data.get("index", 0))
	var total := int(step_data.get("total", 0))
	var progress := "步骤 %d/%d" % [index, total] if index > 0 and total > 0 else "教程进行中"
	var description := str(step_data.get("description", ""))
	var expected := "当前要求：%s" % str(step_data.get("expected_text", ""))
	_refresh_block(title, progress, "%s\n\n%s" % [description, expected], Color(0.92, 0.95, 1.0))


func show_blocked_action(step_data: Dictionary) -> void:
	# 当玩家在锁步阶段提前执行后续操作时调用
	var title := str(step_data.get("title", "教程锁步"))
	var index := int(step_data.get("index", 0))
	var total := int(step_data.get("total", 0))
	var progress := "步骤 %d/%d" % [index, total] if index > 0 and total > 0 else "教程进行中"
	var description := str(step_data.get("description", ""))
	var expected := "先完成：%s" % str(step_data.get("expected_text", ""))
	_refresh_block(title, progress, "%s\n\n%s" % [description, expected], Color(1.0, 0.62, 0.62))


func show_completed() -> void:
	_refresh_block("教程完成", "步骤完成", "所有基础操作已解锁。\n现在可以自由使用道具并完成本关。", Color(0.62, 1.0, 0.78))


func _refresh_block(title_text: String, progress_text: String, body_text: String, tint: Color) -> void:
	_cached_title = title_text
	_cached_progress = progress_text
	_cached_body = body_text
	_cached_tint = tint

	var title_label: Label = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/HeaderRow/HeaderText/TitleLabel")
	if title_label != null:
		title_label.text = title_text
		title_label.modulate = tint
		title_label.add_theme_constant_override("outline_size", 5)
		title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.88))

	var progress_label: Label = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/HeaderRow/HeaderText/ProgressLabel")
	if progress_label != null:
		progress_label.text = "战术引导 · %s" % progress_text if not progress_text.is_empty() else "战术引导"
		progress_label.modulate = Color(0.96, 0.80, 0.42)

	var description_label: Label = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/BodyColumn/DescriptionLabel")
	if description_label != null:
		description_label.text = body_text
		description_label.modulate = Color(0.88, 0.92, 0.98)

	var status_label: Label = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/BodyColumn/StatusLabel")
	if status_label != null:
		status_label.text = "终端提示：未完成当前步骤前，后续关键操作将被锁定。"
		status_label.modulate = Color(0.80, 0.88, 0.96)

	_apply_collapsed_state()


func _on_toggle_pressed() -> void:
	_collapsed = not _collapsed
	_apply_collapsed_state()


func _apply_collapsed_state() -> void:
	var guide_panel: Control = get_node_or_null("GuidePanel")
	var body_column: Control = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/BodyColumn")
	var toggle_button: Button = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/HeaderRow/ToggleButton")
	var title_label: Label = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/HeaderRow/HeaderText/TitleLabel")
	var progress_label: Label = get_node_or_null("GuidePanel/MarginRoot/ContentColumn/HeaderRow/HeaderText/ProgressLabel")

	if body_column != null:
		body_column.visible = not _collapsed

	if toggle_button != null:
		toggle_button.text = "展开" if _collapsed else "收起"

	if title_label != null:
		title_label.text = "教程" if _collapsed else _cached_title
		title_label.modulate = _cached_tint

	if progress_label != null:
		progress_label.text = _cached_progress if _collapsed else _cached_progress

	if guide_panel != null:
		guide_panel.offset_bottom = 176.0 if _collapsed else 312.0
