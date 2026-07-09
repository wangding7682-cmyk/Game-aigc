extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const FLOW_SMOKE_SCENE_PATH := "res://scenes/tests/flow_smoke_runner.tscn"
const NEXT_LEVEL_SMOKE_SCENE_PATH := "res://scenes/tests/next_level_smoke_runner.tscn"
const INTEGRATION_SMOKE_SCENE_PATH := "res://scenes/tests/integration_smoke_runner.tscn"
const ROUTE_GUARD_SMOKE_SCENE_PATH := "res://scenes/tests/route_guard_smoke_runner.tscn"
const PLACEHOLDER_3D_SMOKE_SCENE_PATH := "res://scenes/tests/placeholder_3d_smoke_runner.tscn"
const BATCH_SMOKE_SCENE_PATH := "res://scenes/tests/batch_smoke_runner.tscn"

const RESULT_FILE_MAP := {
	"主流程烟雾": "user://flow_smoke_result.txt",
	"下一关烟雾": "user://next_level_smoke_result.txt",
	"完整集成烟雾": "user://integration_smoke_result.txt",
	"路由守卫烟雾": "user://route_guard_smoke_result.txt",
	"3D 占位烟雾": "user://placeholder_3d_smoke_result.txt",
}

var summary_label: Label
var platform_summary_label: Label
var status_label: Label
var log_view: RichTextLabel
var run_flow_button: Button
var run_next_level_button: Button
var run_integration_button: Button
var run_route_guard_button: Button
var run_placeholder_3d_button: Button
var run_all_button: Button
var reset_progress_button: Button
var platform_login_button: Button
var platform_share_button: Button
var platform_save_button: Button
var platform_ad_button: Button
var back_button: Button
var title_label: Label
var hint_label: Label

var _is_running := false


func _ready() -> void:
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_refresh_cached_results()


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = MENU_KEY_ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var tint := ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.02, 0.04, 0.06, 0.74)
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
	eyebrow.text = "验证与维护终端"
	eyebrow.modulate = Color(0.90, 0.95, 1.0, 0.94)
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_constant_override("outline_size", 5)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	title_box.add_child(eyebrow)

	title_label = Label.new()
	title_label.text = "测试中心"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_constant_override("outline_size", 7)
	title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	title_box.add_child(title_label)

	back_button = Button.new()
	back_button.text = "返回主页"
	back_button.custom_minimum_size = Vector2(124, 46)
	back_button.pressed.connect(func() -> void:
		if _is_running:
			status_label.text = "状态：测试运行中，请等待当前用例结束。"
			return
		RouteGuard.request_route("main_menu", "测试中心-返回主页")
	)
	_apply_action_button_style(back_button, "secondary")
	top_row.add_child(back_button)

	var intro := Label.new()
	intro.text = "统一触发主流程、下一关、完整集成、路由守卫与 3D 占位验证，同时保留平台 mock 自检。"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.84, 0.90, 0.98)
	intro.add_theme_font_size_override("font_size", 15)
	intro.add_theme_constant_override("line_separation", 4)
	header_vbox.add_child(intro)

	hint_label = Label.new()
	hint_label.text = "首屏先给出运行入口与状态摘要，结果详情和日志放到下方内容区。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color(0.96, 0.80, 0.42)
	hint_label.add_theme_font_size_override("font_size", 14)
	header_vbox.add_child(hint_label)

	var primary_panel := PanelContainer.new()
	_apply_surface_panel_style(primary_panel, false)
	shell.add_child(primary_panel)

	var primary_margin := MarginContainer.new()
	primary_margin.add_theme_constant_override("margin_left", 16)
	primary_margin.add_theme_constant_override("margin_top", 16)
	primary_margin.add_theme_constant_override("margin_right", 16)
	primary_margin.add_theme_constant_override("margin_bottom", 16)
	primary_panel.add_child(primary_margin)

	var primary_vbox := VBoxContainer.new()
	primary_vbox.add_theme_constant_override("separation", 12)
	primary_margin.add_child(primary_vbox)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.modulate = Color(0.74, 0.94, 0.80)
	status_label.text = "状态：待机。可单跑，也可一键全跑。"
	primary_vbox.add_child(status_label)

	var button_grid := GridContainer.new()
	button_grid.columns = 2
	button_grid.add_theme_constant_override("h_separation", 12)
	button_grid.add_theme_constant_override("v_separation", 12)
	primary_vbox.add_child(button_grid)

	run_flow_button = _make_action_button("运行主流程烟雾", _on_run_flow_pressed)
	button_grid.add_child(run_flow_button)

	run_next_level_button = _make_action_button("运行下一关烟雾", _on_run_next_level_pressed)
	button_grid.add_child(run_next_level_button)

	run_integration_button = _make_action_button("运行完整集成烟雾", _on_run_integration_pressed)
	button_grid.add_child(run_integration_button)

	run_route_guard_button = _make_action_button("运行路由守卫烟雾", _on_run_route_guard_pressed)
	button_grid.add_child(run_route_guard_button)

	run_placeholder_3d_button = _make_action_button("运行 3D 占位烟雾", _on_run_placeholder_3d_pressed)
	button_grid.add_child(run_placeholder_3d_button)

	run_all_button = _make_action_button("一键全跑", _on_run_all_pressed)
	button_grid.add_child(run_all_button)

	reset_progress_button = _make_action_button("重置本地测试进度", _on_reset_progress_pressed)
	_apply_action_button_style(reset_progress_button, "danger")
	button_grid.add_child(reset_progress_button)

	platform_login_button = _make_action_button("平台登录自检", _on_platform_login_pressed)
	button_grid.add_child(platform_login_button)

	platform_share_button = _make_action_button("平台分享自检", _on_platform_share_pressed)
	button_grid.add_child(platform_share_button)

	platform_save_button = _make_action_button("平台存档自检", _on_platform_save_pressed)
	button_grid.add_child(platform_save_button)

	platform_ad_button = _make_action_button("平台广告自检", _on_platform_ad_pressed)
	button_grid.add_child(platform_ad_button)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_surface_panel_style(detail_panel, false)
	shell.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 16)
	detail_margin.add_theme_constant_override("margin_top", 16)
	detail_margin.add_theme_constant_override("margin_right", 16)
	detail_margin.add_theme_constant_override("margin_bottom", 16)
	detail_panel.add_child(detail_margin)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_theme_constant_override("separation", 12)
	detail_margin.add_child(detail_vbox)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary_label.modulate = Color(0.80, 0.88, 0.97)
	detail_vbox.add_child(summary_label)

	platform_summary_label = Label.new()
	platform_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	platform_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	platform_summary_label.modulate = Color(0.96, 0.86, 0.65)
	detail_vbox.add_child(platform_summary_label)

	log_view = RichTextLabel.new()
	log_view.fit_content = false
	log_view.scroll_following = true
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.custom_minimum_size = Vector2(0, 240)
	log_view.bbcode_enabled = false
	detail_vbox.add_child(log_view)


func _make_action_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.pressed.connect(action)
	_apply_action_button_style(button, "secondary")
	return button


func _set_running_state(running: bool) -> void:
	_is_running = running
	run_flow_button.disabled = running
	run_next_level_button.disabled = running
	run_integration_button.disabled = running
	run_route_guard_button.disabled = running
	run_placeholder_3d_button.disabled = running
	run_all_button.disabled = running
	reset_progress_button.disabled = running
	platform_login_button.disabled = running
	platform_share_button.disabled = running
	platform_save_button.disabled = running
	platform_ad_button.disabled = running


func _format_test_result(test_name: String, content: String) -> String:
	var lines := content.split("\n", false)
	var status := "未知"
	var timestamp := ""
	var failures: Array[String] = []
	
	for line in lines:
		line = line.strip_edges()
		if line.begins_with("TIMESTAMP="):
			timestamp = line.substr("TIMESTAMP=".length())
		elif line.find("=") != -1 and not line.begins_with("TIMESTAMP="):
			status = line.split("=", false, 1)[1]
		elif not line.is_empty() and not line.begins_with("FLOW_SMOKE=") and not line.begins_with("NEXT_LEVEL_SMOKE=") and not line.begins_with("INTEGRATION_SMOKE=") and not line.begins_with("ROUTE_GUARD_SMOKE="):
			failures.append(line)
	
	var time_display := ""
	if not timestamp.is_empty():
		var date_time := timestamp.split(" ", false, 2)
		if date_time.size() >= 2:
			var date_parts := date_time[0].split("-", false)
			var time_parts := date_time[1].split(":", false)
			if date_parts.size() >= 3 and time_parts.size() >= 2:
				var year := int(date_parts[0])
				var month := int(date_parts[1])
				var day := int(date_parts[2])
				var hour := int(time_parts[0])
				var minute := int(time_parts[1])
				if year > 2000 and month >= 1 and month <= 12 and day >= 1 and day <= 31:
					hour += 8
					if hour >= 24:
						hour -= 24
						day += 1
					time_display = " [%02d-%02d %02d:%02d]" % [month, day, hour, minute]
	
	var result_text := status
	if not failures.is_empty():
		result_text += " (%d项失败)" % failures.size()
	
	return "%s：%s%s" % [test_name, result_text, time_display]


func _refresh_cached_results() -> void:
	var lines: Array[String] = []
	for test_name in RESULT_FILE_MAP.keys():
		var result_path: String = str(RESULT_FILE_MAP[test_name])
		var summary := "%s：未运行" % test_name
		if FileAccess.file_exists(result_path):
			var content := FileAccess.get_file_as_string(result_path).strip_edges()
			if content.is_empty():
				summary = "%s：结果文件为空" % test_name
			else:
				summary = _format_test_result(test_name, content)
		lines.append(summary)

	summary_label.text = "统一验收入口：主流程烟雾、下一关烟雾、完整集成烟雾、路由守卫烟雾。\n最近结果：\n%s" % "\n".join(lines)
	platform_summary_label.text = "平台状态：%s\n运行目标：%s\n提示：桌面环境默认走 mock；在微信/抖音开发者工具里打开后，会自动切到真实平台适配器。" % [
		PlatformService.build_mock_status(),
		PlatformService.get_runtime_target(),
	]


func _append_log(text: String) -> void:
	log_view.text += "%s\n" % text


func _on_run_flow_pressed() -> void:
	_launch_smoke_test("主流程烟雾", load(FLOW_SMOKE_SCENE_PATH))


func _on_run_next_level_pressed() -> void:
	_launch_smoke_test("下一关烟雾", load(NEXT_LEVEL_SMOKE_SCENE_PATH))


func _on_run_integration_pressed() -> void:
	_launch_smoke_test("完整集成烟雾", load(INTEGRATION_SMOKE_SCENE_PATH))


func _on_run_route_guard_pressed() -> void:
	_launch_smoke_test("路由守卫烟雾", load(ROUTE_GUARD_SMOKE_SCENE_PATH))


func _on_run_placeholder_3d_pressed() -> void:
	_launch_smoke_test("3D 占位烟雾", load(PLACEHOLDER_3D_SMOKE_SCENE_PATH))


func _on_run_all_pressed() -> void:
	_launch_batch_tests()


func _on_reset_progress_pressed() -> void:
	if _is_running:
		return

	CoreGameState.reset_progress()
	
	# 同时清除旧的测试结果文件
	for result_path in RESULT_FILE_MAP.values():
		if FileAccess.file_exists(result_path):
			DirAccess.remove_absolute(result_path)
	
	_refresh_cached_results()
	status_label.text = "状态：已清空本地测试进度与历史结果，可重新验证教程、首关与升级流程。"
	_append_log(">>> 已执行：重置本地测试进度与历史结果")


func _on_platform_login_pressed() -> void:
	if _is_running:
		return

	status_label.text = "状态：执行平台登录自检..."
	var result: Dictionary = await PlatformService.request_login()
	_append_log(">>> 平台登录自检：%s" % JSON.stringify(result))
	status_label.text = "状态：平台登录自检完成。"
	_refresh_cached_results()


func _on_platform_share_pressed() -> void:
	if _is_running:
		return

	status_label.text = "状态：执行平台分享自检..."
	var result: Dictionary = await PlatformService.open_share({
		"title": "狙击外星人升级版-平台自检",
		"query": "from=test_center_share",
		"from": "test_center",
	})
	_append_log(">>> 平台分享自检：%s" % JSON.stringify(result))
	status_label.text = "状态：平台分享自检完成。"
	_refresh_cached_results()


func _on_platform_save_pressed() -> void:
	if _is_running:
		return

	status_label.text = "状态：执行平台存档自检..."
	var save_ok := PlatformService.save_game(CoreGameState.build_save_payload())
	var loaded_payload := PlatformService.load_game()
	_append_log(">>> 平台存档自检：save_ok=%s load_keys=%s" % [
		str(save_ok),
		JSON.stringify(loaded_payload.keys() if loaded_payload is Dictionary else []),
	])
	status_label.text = "状态：平台存档自检完成。"
	_refresh_cached_results()


func _on_platform_ad_pressed() -> void:
	if _is_running:
		return

	status_label.text = "状态：执行平台广告自检..."
	var result: Dictionary = await PlatformService.show_rewarded_ad("test_center_self_check")
	_append_log(">>> 平台广告自检：%s" % JSON.stringify(result))
	status_label.text = "状态：平台广告自检完成。"
	_refresh_cached_results()


func _find_core_game_root() -> Node:
	var current: Node = self
	while current != null:
		if current.get_script() and str(current.get_script().resource_path).find("core_game_root.gd") != -1:
			return current
		current = current.get_parent()
	return null


func _disable_smoke_test_buttons() -> void:
	"""禁用所有会触发场景切换的烟雾测试按钮，防止重复点击"""
	run_flow_button.disabled = true
	run_next_level_button.disabled = true
	run_integration_button.disabled = true
	run_route_guard_button.disabled = true
	run_placeholder_3d_button.disabled = true
	run_all_button.disabled = true


func _launch_smoke_test(test_name: String, scene_resource: PackedScene) -> void:
	"""启动单个烟雾测试（发射后不管：测试会自动切换场景，当前测试中心面板会被销毁，测试完成后会自动返回新的测试中心）"""
	_disable_smoke_test_buttons()
	status_label.text = "状态：正在启动 %s，场景即将切换..." % test_name
	_append_log(">>> 启动 %s，测试运行中请稍候..." % test_name)

	var runner: Node = scene_resource.instantiate()
	runner.set("auto_quit", false)
	runner.set("_is_embedded", true)
	
	var host_node: Node = _find_core_game_root()
	if host_node == null:
		host_node = get_tree().root
	host_node.add_child(runner)


func _launch_batch_tests() -> void:
	"""启动一键全跑（批量顺序执行所有烟雾测试，完成后自动返回测试中心）"""
	_disable_smoke_test_buttons()
	status_label.text = "状态：正在启动一键全跑，场景即将切换..."
	_append_log(">>> 启动一键全跑，按顺序执行所有烟雾测试...")

	var batch_runner: Node = load(BATCH_SMOKE_SCENE_PATH).instantiate()
	var host_node: Node = _find_core_game_root()
	if host_node == null:
		host_node = get_tree().root
	host_node.add_child(batch_runner)


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
	elif tone == "danger":
		color = Color(0.28, 0.10, 0.12, 0.92)
		hover_color = Color(0.36, 0.12, 0.15, 0.98)
		pressed_color = Color(0.24, 0.08, 0.10, 0.98)
		focus_color = Color(0.42, 0.14, 0.18, 1.0)
		disabled_color = Color(0.16, 0.08, 0.09, 0.52)
		border_color = Color(1.0, 0.56, 0.58, 0.46)

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
