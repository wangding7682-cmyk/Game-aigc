extends CanvasLayer

signal fire_pressed
signal scan_pressed
signal time_extend_pressed
signal zoom_in_pressed
signal zoom_out_pressed
signal back_pressed
signal quit_to_menu_pressed

const ScopeOverlayScript = preload("res://scripts/ui/ui_scope_overlay.gd")
const HUD_HEALTH_BAR := preload("res://assets_mvp_placeholder/ui/hud-health-bar.svg")
const HUD_TIME_BAR := preload("res://assets_mvp_placeholder/ui/hud-time-bar.svg")
const HUD_TARGET_LOCK := preload("res://assets_mvp_placeholder/ui/hud-target-lock-frame.svg")
const ICON_SCAN_RADAR := preload("res://assets_mvp_placeholder/ui/icon-scan-radar.svg")
const ICON_TIME_EXTEND := preload("res://assets_mvp_placeholder/ui/icon-time-extend.svg")
const FX_HIT_CONFIRM := preload("res://assets_mvp_placeholder/feedback/fx-hit-confirm.svg")
const FX_WRONG_HIT := preload("res://assets_mvp_placeholder/feedback/fx-wrong-hit-alert.svg")
const FX_SCAN_PULSE := preload("res://assets_mvp_placeholder/feedback/fx-scan-pulse.svg")

var stats_label: Label
var feedback_label: Label
var help_label: Label
var scan_button: Button
var time_button: Button
var crosshair_label: Label
var scope_overlay: ColorRect
var scope_hint_label: Label
var scope_draw_layer: Control
var time_bar_frame: TextureRect
var health_bar_frame: TextureRect
var target_lock_frame: TextureRect
var feedback_icon: TextureRect
var pause_overlay: ColorRect
var pause_panel: PanelContainer
var pause_status_label: Label
var pause_hint_label: Label
var pause_resume_button: Button
var pause_quit_button: Button
var pause_visible := false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	scope_overlay = ColorRect.new()
	scope_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scope_overlay.color = Color(0.01, 0.02, 0.04, 0.0)
	scope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scope_overlay)

	scope_draw_layer = Control.new()
	scope_draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	scope_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scope_draw_layer.set_script(ScopeOverlayScript)
	root.add_child(scope_draw_layer)

	time_bar_frame = TextureRect.new()
	time_bar_frame.texture = HUD_TIME_BAR
	time_bar_frame.anchor_left = 0.02
	time_bar_frame.anchor_top = 0.025
	time_bar_frame.anchor_right = 0.32
	time_bar_frame.anchor_bottom = 0.11
	time_bar_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	time_bar_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	time_bar_frame.modulate = Color(1.0, 1.0, 1.0, 0.92)
	time_bar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(time_bar_frame)

	health_bar_frame = TextureRect.new()
	health_bar_frame.texture = HUD_HEALTH_BAR
	health_bar_frame.anchor_left = 0.68
	health_bar_frame.anchor_top = 0.025
	health_bar_frame.anchor_right = 0.98
	health_bar_frame.anchor_bottom = 0.11
	health_bar_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	health_bar_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	health_bar_frame.modulate = Color(1.0, 1.0, 1.0, 0.92)
	health_bar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(health_bar_frame)

	target_lock_frame = TextureRect.new()
	target_lock_frame.texture = HUD_TARGET_LOCK
	target_lock_frame.anchor_left = 0.5
	target_lock_frame.anchor_top = 0.08
	target_lock_frame.anchor_right = 0.5
	target_lock_frame.anchor_bottom = 0.08
	target_lock_frame.offset_left = -80.0
	target_lock_frame.offset_top = -32.0
	target_lock_frame.offset_right = 80.0
	target_lock_frame.offset_bottom = 48.0
	target_lock_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_lock_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target_lock_frame.modulate = Color(1.0, 1.0, 1.0, 0.46)
	target_lock_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(target_lock_frame)

	var top_bar := PanelContainer.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_left = 18.0
	top_bar.offset_top = 18.0
	top_bar.offset_right = -18.0
	top_bar.offset_bottom = 94.0
	root.add_child(top_bar)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_bar.add_child(stats_label)

	feedback_label = Label.new()
	feedback_label.anchor_left = 0.15
	feedback_label.anchor_top = 0.22
	feedback_label.anchor_right = 0.85
	feedback_label.anchor_bottom = 0.34
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.add_theme_font_size_override("font_size", 22)
	root.add_child(feedback_label)

	feedback_icon = TextureRect.new()
	feedback_icon.anchor_left = 0.5
	feedback_icon.anchor_top = 0.30
	feedback_icon.anchor_right = 0.5
	feedback_icon.anchor_bottom = 0.30
	feedback_icon.offset_left = -36.0
	feedback_icon.offset_top = -36.0
	feedback_icon.offset_right = 36.0
	feedback_icon.offset_bottom = 36.0
	feedback_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feedback_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	feedback_icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	feedback_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(feedback_icon)

	pause_overlay = ColorRect.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.color = Color(0.02, 0.04, 0.06, 0.0)
	pause_overlay.visible = false
	root.add_child(pause_overlay)

	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -240.0
	pause_panel.offset_top = -190.0
	pause_panel.offset_right = 240.0
	pause_panel.offset_bottom = 190.0
	pause_panel.visible = false
	root.add_child(pause_panel)

	var pause_margin := MarginContainer.new()
	pause_margin.add_theme_constant_override("margin_left", 28)
	pause_margin.add_theme_constant_override("margin_top", 28)
	pause_margin.add_theme_constant_override("margin_right", 28)
	pause_margin.add_theme_constant_override("margin_bottom", 28)
	pause_panel.add_child(pause_margin)

	var pause_vbox := VBoxContainer.new()
	pause_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_vbox.add_theme_constant_override("separation", 16)
	pause_margin.add_child(pause_vbox)

	var pause_title := Label.new()
	pause_title.text = "作战暂停"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 24)
	pause_vbox.add_child(pause_title)

	pause_status_label = Label.new()
	pause_status_label.text = "当前任务已暂停"
	pause_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_status_label.modulate = Color(0.96, 0.80, 0.42)
	pause_vbox.add_child(pause_status_label)

	pause_hint_label = Label.new()
	pause_hint_label.text = "你可以继续任务，或直接退出回到主菜单。"
	pause_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hint_label.modulate = Color(0.84, 0.90, 0.98)
	pause_vbox.add_child(pause_hint_label)

	pause_resume_button = Button.new()
	pause_resume_button.text = "继续任务"
	pause_resume_button.custom_minimum_size = Vector2(0, 46)
	pause_resume_button.pressed.connect(func() -> void:
		set_pause_overlay_visible(false)
	)
	pause_vbox.add_child(pause_resume_button)

	pause_quit_button = Button.new()
	pause_quit_button.text = "退出到主菜单"
	pause_quit_button.custom_minimum_size = Vector2(0, 46)
	pause_quit_button.pressed.connect(func() -> void:
		quit_to_menu_pressed.emit()
	)
	pause_vbox.add_child(pause_quit_button)

	crosshair_label = Label.new()
	crosshair_label.anchor_left = 0.0
	crosshair_label.anchor_top = 0.0
	crosshair_label.anchor_right = 0.0
	crosshair_label.anchor_bottom = 0.0
	crosshair_label.size = Vector2(48.0, 44.0)
	crosshair_label.text = "＋"
	crosshair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair_label.add_theme_font_size_override("font_size", 32)
	root.add_child(crosshair_label)

	scope_hint_label = Label.new()
	scope_hint_label.anchor_left = 0.5
	scope_hint_label.anchor_top = 0.5
	scope_hint_label.anchor_right = 0.5
	scope_hint_label.anchor_bottom = 0.5
	scope_hint_label.offset_left = -180.0
	scope_hint_label.offset_top = 58.0
	scope_hint_label.offset_right = 180.0
	scope_hint_label.offset_bottom = 110.0
	scope_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scope_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scope_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scope_hint_label.modulate = Color(0.82, 0.88, 0.96, 0.0)
	scope_hint_label.text = "双击或滚轮放大进入瞄准"
	root.add_child(scope_hint_label)

	var bottom_bar := PanelContainer.new()
	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = 18.0
	bottom_bar.offset_top = -210.0
	bottom_bar.offset_right = -18.0
	bottom_bar.offset_bottom = -18.0
	root.add_child(bottom_bar)

	var bottom_vbox := VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 12)
	bottom_bar.add_child(bottom_vbox)

	help_label = Label.new()
	help_label.text = "WASD 平移，Q/E 缩放；双击左键进入瞄准；瞄准后按住 Shift/右键/Space 屏息减晃动；Enter/左键开火；[] 切换武器。"
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_vbox.add_child(help_label)

	var first_row := HBoxContainer.new()
	first_row.add_theme_constant_override("separation", 10)
	bottom_vbox.add_child(first_row)

	scan_button = Button.new()
	scan_button.text = "扫描"
	scan_button.icon = ICON_SCAN_RADAR
	scan_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scan_button.custom_minimum_size = Vector2(0, 46)
	scan_button.pressed.connect(func() -> void:
		scan_pressed.emit()
	)
	first_row.add_child(scan_button)

	time_button = Button.new()
	time_button.text = "+15秒"
	time_button.icon = ICON_TIME_EXTEND
	time_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_button.custom_minimum_size = Vector2(0, 46)
	time_button.pressed.connect(func() -> void:
		time_extend_pressed.emit()
	)
	first_row.add_child(time_button)

	var fire_button := Button.new()
	fire_button.text = "开火"
	fire_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fire_button.custom_minimum_size = Vector2(0, 46)
	fire_button.pressed.connect(func() -> void:
		fire_pressed.emit()
	)
	first_row.add_child(fire_button)

	var second_row := HBoxContainer.new()
	second_row.add_theme_constant_override("separation", 10)
	bottom_vbox.add_child(second_row)

	var zoom_in_button := Button.new()
	zoom_in_button.text = "放大"
	zoom_in_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_in_button.custom_minimum_size = Vector2(0, 42)
	zoom_in_button.pressed.connect(func() -> void:
		zoom_in_pressed.emit()
	)
	second_row.add_child(zoom_in_button)

	var zoom_out_button := Button.new()
	zoom_out_button.text = "缩小"
	zoom_out_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_out_button.custom_minimum_size = Vector2(0, 42)
	zoom_out_button.pressed.connect(func() -> void:
		zoom_out_pressed.emit()
	)
	second_row.add_child(zoom_out_button)

	var menu_button := Button.new()
	menu_button.text = "返回主页"
	menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_button.custom_minimum_size = Vector2(0, 42)
	menu_button.pressed.connect(func() -> void:
		back_pressed.emit()
	)
	second_row.add_child(menu_button)


func update_state(state: Dictionary) -> void:
	var weapon_name := str(state.get("weapon_name", "标准狙击枪"))
	stats_label.text = "关卡 %d | 时间 %.1fs | 目标 %d/%d | 生命 %d | 武器: %s | 识别奖励 +%d | 连击加成 +%d | 误判罚时 %.0fs | 放大 %.2fx" % [
		int(state.get("level_id", 1)),
		float(state.get("remaining_time", 0.0)),
		int(state.get("killed_targets", 0)),
		int(state.get("total_targets", 0)),
		int(state.get("lives", 0)),
		weapon_name,
		int(state.get("recognition_bonus_gold", 0)),
		int(state.get("recognition_combo_bonus_gold", 0)),
		float(state.get("wrong_identification_time_penalty", 0.0)),
		float(state.get("zoom", 1.0)),
	]

	scan_button.text = "扫描 x%d" % int(state.get("scan_count", 0))
	scan_button.disabled = int(state.get("scan_count", 0)) <= 0

	time_button.text = "+%.0fs x%d" % [
		float(state.get("time_extend_sec", 15.0)),
		int(state.get("time_extend_count", 0)),
	]
	time_button.disabled = int(state.get("time_extend_count", 0)) <= 0

	var scope_visible := bool(state.get("scope_visible", false))
	var hold_ratio := float(state.get("hold_ratio", 0.0))
	var crosshair_style := str(state.get("crosshair_style", "plus"))
	var crosshair_color := str(state.get("crosshair_color", "amber"))
	var _hold_vignette_strength := clampf(float(state.get("hold_vignette_strength", 1.0)), 0.4, 1.6)
	var interaction_hint := str(state.get("interaction_hint", ""))
	var search_hint_text := str(state.get("search_hint_text", ""))
	var identification_replay_text := str(state.get("identification_replay_text", ""))
	var aim_screen_position: Vector2 = state.get("aim_screen_position", Vector2.ZERO)
	var help_lines: Array[String] = [interaction_hint]
	if not identification_replay_text.is_empty():
		help_lines.append(identification_replay_text)
	elif not search_hint_text.is_empty():
		help_lines.append(search_hint_text)
	help_label.text = "\n".join(help_lines)
	var weapon_ready: bool = bool(state.get("weapon_ready", true))
	var killcam_active: bool = bool(state.get("killcam_active", false))
	var misjudgment_active: bool = bool(state.get("misjudgment_active", false))
	var cinematic_active: bool = killcam_active or misjudgment_active

	var show_scope_ui: bool = scope_visible and not cinematic_active
	scope_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	target_lock_frame.modulate.a = 0.72 if show_scope_ui else 0.42
	if scope_draw_layer != null and is_instance_valid(scope_draw_layer):
		scope_draw_layer.visible = show_scope_ui
		scope_draw_layer.modulate.a = 1.0 if show_scope_ui else 0.0

	var show_hint: bool = weapon_ready and not cinematic_active and not pause_visible
	if scope_visible and not cinematic_active:
		scope_hint_label.text = "长按屏息，松手或单击开火"
	else:
		scope_hint_label.text = "双击或滚轮放大进入瞄准"
	if CoreGameState.is_tutorial_active() and not pause_visible:
		scope_hint_label.text = "教程锁步中：按当前提示完成动作"
	scope_hint_label.modulate.a = 0.85 if show_hint else 0.0
	var base_color: Color = _resolve_crosshair_color(crosshair_color)
	crosshair_label.modulate = base_color.lerp(Color(1.0, 1.0, 1.0), 0.12) if hold_ratio >= 0.55 else base_color
	crosshair_label.text = _resolve_crosshair_char(crosshair_style)
	crosshair_label.position = aim_screen_position - crosshair_label.size * 0.5
	crosshair_label.visible = not scope_visible and not cinematic_active and not pause_visible
	target_lock_frame.position = aim_screen_position - target_lock_frame.size * 0.5
	if scope_draw_layer != null and scope_draw_layer.has_method("update_state") and show_scope_ui:
		scope_draw_layer.call("update_state", state)


func show_feedback(content: String, color: Color = Color.WHITE) -> void:
	feedback_label.text = content
	feedback_label.modulate = color
	feedback_icon.texture = _resolve_feedback_texture(content)
	feedback_icon.modulate.a = 0.92 if feedback_icon.texture != null else 0.0


func set_pause_overlay_visible(enabled: bool, status_text: String = "当前任务已暂停", hint_text: String = "你可以继续任务，或直接退出回到主菜单。") -> void:
	pause_visible = enabled
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.visible = enabled
		pause_overlay.color.a = 0.72 if enabled else 0.0
	if pause_panel != null and is_instance_valid(pause_panel):
		pause_panel.visible = enabled
	if pause_status_label != null and is_instance_valid(pause_status_label):
		pause_status_label.text = status_text
	if pause_hint_label != null and is_instance_valid(pause_hint_label):
		pause_hint_label.text = hint_text
	if scope_hint_label != null and is_instance_valid(scope_hint_label):
		if enabled:
			scope_hint_label.modulate.a = 0.0


func is_pause_overlay_visible() -> bool:
	return pause_visible


func show_result(result: Dictionary) -> void:
	var success := bool(result.get("success", false))
	var reward := int(result.get("reward_gold", 0))
	var reason := str(result.get("reason", ""))
	if success:
		show_feedback("任务完成！奖励 %d 金币\n%s" % [reward, reason], Color(0.58, 1.0, 0.72))
	else:
		show_feedback("任务失败：%s" % reason, Color(1.0, 0.72, 0.72))


func _resolve_feedback_texture(content: String) -> Texture2D:
	var lower_content := content.to_lower()
	if content.find("完成") != -1 or content.find("命中") != -1 or lower_content.find("hit") != -1:
		return FX_HIT_CONFIRM
	if content.find("失败") != -1 or content.find("误") != -1 or lower_content.find("wrong") != -1:
		return FX_WRONG_HIT
	if content.find("扫描") != -1 or lower_content.find("scan") != -1:
		return FX_SCAN_PULSE
	return null


func _resolve_crosshair_char(style: String) -> String:
	match style:
		"dot":
			return "•"
		"circle":
			return "○"
		"x":
			return "×"
		"cross":
			return "+"
		_:
			return "＋"


func _resolve_crosshair_color(color_id: String) -> Color:
	match color_id:
		"white":
			return Color(1.0, 1.0, 1.0)
		"green":
			return Color(0.52, 1.0, 0.66)
		"red":
			return Color(1.0, 0.38, 0.38)
		"cyan":
			return Color(0.58, 0.92, 1.0)
		_:
			return Color(1.0, 0.95, 0.82) # amber
