extends Control

const DEFAULT_PORT := 57890
const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")

@onready var title_label: Label = $SafeArea/MainLayout/TitleLabel
@onready var ip_line_edit: LineEdit = $SafeArea/MainLayout/IpRow/IpLineEdit
@onready var port_line_edit: LineEdit = $SafeArea/MainLayout/PortRow/PortLineEdit
@onready var create_server_button: Button = $SafeArea/MainLayout/ButtonVBox/CreateServerButton
@onready var join_server_button: Button = $SafeArea/MainLayout/ButtonVBox/JoinServerButton
@onready var status_label: Label = $SafeArea/MainLayout/StatusLabel
@onready var back_button: Button = $SafeArea/MainLayout/BackButton


func _ready() -> void:
	_apply_terminal_style()
	create_server_button.pressed.connect(_on_create_server_pressed)
	join_server_button.pressed.connect(_on_join_server_pressed)
	back_button.pressed.connect(_on_back_pressed)

	NetworkManager.server_started.connect(_on_server_started)
	NetworkManager.server_start_failed.connect(_on_server_start_failed)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.peer_connected.connect(_on_peer_connected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	NetworkManager.peer_disconnected.connect(_on_peer_disconnected)

	ip_line_edit.text = "127.0.0.1"
	port_line_edit.text = str(DEFAULT_PORT)
	status_label.text = "选择创建房间，或输入 IP 加入作战房间"


func _on_create_server_pressed() -> void:
	var port := _get_port()
	if port <= 0:
		status_label.text = "端口号无效"
		return

	status_label.text = "正在建立主机房间..."
	create_server_button.disabled = true
	join_server_button.disabled = true
	NetworkManager.create_server(port)


func _on_join_server_pressed() -> void:
	var ip := ip_line_edit.text.strip_edges()
	var port := _get_port()
	if ip.is_empty():
		status_label.text = "请输入服务端 IP"
		return
	if port <= 0:
		status_label.text = "端口号无效"
		return

	status_label.text = "正在连接 %s:%d..." % [ip, port]
	create_server_button.disabled = true
	join_server_button.disabled = true
	NetworkManager.connect_to_server(ip, port)


func _on_back_pressed() -> void:
	if NetworkManager.is_network_connected:
		NetworkManager.disconnect_network()
	RouteGuard.request_route("main_menu", "联机大厅-返回主页")


func _get_port() -> int:
	var text := port_line_edit.text.strip_edges()
	if text.is_empty():
		return DEFAULT_PORT
	var port_val := text.to_int()
	if port_val <= 0 or port_val > 65535:
		return -1
	return port_val


func _on_server_started(port: int) -> void:
	status_label.text = "房间已创建，端口：%d\n正在等待另一位玩家加入..." % port
	back_button.disabled = false


func _on_server_start_failed(reason: String) -> void:
	status_label.text = "创建房间失败：%s" % reason
	create_server_button.disabled = false
	join_server_button.disabled = false


func _on_connected_to_server() -> void:
	status_label.text = "已连接服务端，等待对局开始..."
	RouteGuard.request_route("pvp_network_room", "联机大厅-连接服务端")


func _on_connection_failed(reason: String) -> void:
	status_label.text = "连接失败：%s" % reason
	create_server_button.disabled = false
	join_server_button.disabled = false


func _on_peer_connected(_peer_id: int) -> void:
	if NetworkManager.is_server and NetworkManager.get_peer_count() >= 2:
		status_label.text = "玩家已加入，正在进入对局..."
		RouteGuard.request_route("pvp_network_room", "联机大厅-玩家已加入")


func _on_server_disconnected() -> void:
	status_label.text = "与服务端断开连接"
	create_server_button.disabled = false
	join_server_button.disabled = false


func _on_peer_disconnected(_peer_id: int) -> void:
	if NetworkManager.is_server:
		status_label.text = "对方断开连接，等待重新加入..."


func _apply_terminal_style() -> void:
	var bg := TextureRect.new()
	bg.name = "RuntimeBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = MENU_KEY_ART
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	move_child(bg, 0)

	var tint := ColorRect.new()
	tint.name = "RuntimeTint"
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.02, 0.04, 0.06, 0.78)
	add_child(tint)
	move_child(tint, 1)

	var top_glow := ColorRect.new()
	top_glow.name = "RuntimeTopGlow"
	top_glow.anchor_left = 0.0
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 1.0
	top_glow.anchor_bottom = 0.22
	top_glow.color = Color(0.08, 0.15, 0.24, 0.26)
	add_child(top_glow)
	move_child(top_glow, 2)

	var safe_area: MarginContainer = $SafeArea
	safe_area.add_theme_constant_override("margin_left", 28)
	safe_area.add_theme_constant_override("margin_top", 24)
	safe_area.add_theme_constant_override("margin_right", 28)
	safe_area.add_theme_constant_override("margin_bottom", 24)

	var layout: VBoxContainer = $SafeArea/MainLayout
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.custom_minimum_size = Vector2.ZERO
	layout.add_theme_constant_override("separation", 14)

	var subtitle: Label = $SafeArea/MainLayout/SubtitleLabel
	title_label.text = "局域网联机大厅"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.text = "在同一局域网下创建或加入房间，让主机与客机进入同一场短局对抗。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.modulate = Color(0.84, 0.90, 0.98)
	subtitle.add_theme_font_size_override("font_size", 15)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.96, 0.80, 0.42)
	back_button.custom_minimum_size = Vector2(0, 46)
	create_server_button.custom_minimum_size = Vector2(0, 50)
	join_server_button.custom_minimum_size = Vector2(0, 50)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	layout.add_child(title_row)
	layout.move_child(title_row, 0)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	title_row.add_child(title_box)

	var eyebrow := Label.new()
	eyebrow.text = "联机匹配终端"
	eyebrow.modulate = Color(0.90, 0.95, 1.0, 0.94)
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_constant_override("outline_size", 5)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	title_box.add_child(eyebrow)

	title_label.reparent(title_box)
	subtitle.reparent(title_box)

	back_button.text = "返回主页"
	_apply_action_button_style(back_button, "secondary")
	title_row.add_child(back_button)

	var connect_panel := PanelContainer.new()
	_apply_surface_panel_style(connect_panel, true)
	layout.add_child(connect_panel)
	layout.move_child(connect_panel, 1)

	var connect_margin := MarginContainer.new()
	connect_margin.add_theme_constant_override("margin_left", 16)
	connect_margin.add_theme_constant_override("margin_top", 16)
	connect_margin.add_theme_constant_override("margin_right", 16)
	connect_margin.add_theme_constant_override("margin_bottom", 16)
	connect_panel.add_child(connect_margin)

	var connect_vbox := VBoxContainer.new()
	connect_vbox.add_theme_constant_override("separation", 12)
	connect_margin.add_child(connect_vbox)

	var connect_title := Label.new()
	connect_title.text = "房间连接"
	connect_title.add_theme_font_size_override("font_size", 24)
	connect_vbox.add_child(connect_title)

	ip_line_edit.custom_minimum_size = Vector2(0, 42)
	port_line_edit.custom_minimum_size = Vector2(0, 42)
	_apply_line_edit_style(ip_line_edit)
	_apply_line_edit_style(port_line_edit)
	$SafeArea/MainLayout/IpRow.reparent(connect_vbox)
	$SafeArea/MainLayout/PortRow.reparent(connect_vbox)

	_apply_action_button_style(create_server_button, "primary")
	_apply_action_button_style(join_server_button, "secondary")
	$SafeArea/MainLayout/ButtonVBox.add_theme_constant_override("separation", 10)
	$SafeArea/MainLayout/ButtonVBox.reparent(connect_vbox)

	var status_panel := PanelContainer.new()
	_apply_surface_panel_style(status_panel, false)
	layout.add_child(status_panel)
	layout.move_child(status_panel, 2)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 16)
	status_margin.add_theme_constant_override("margin_top", 14)
	status_margin.add_theme_constant_override("margin_right", 16)
	status_margin.add_theme_constant_override("margin_bottom", 14)
	status_panel.add_child(status_margin)

	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 8)
	status_margin.add_child(status_vbox)

	var status_title := Label.new()
	status_title.text = "当前状态"
	status_title.add_theme_font_size_override("font_size", 20)
	status_vbox.add_child(status_title)

	status_label.reparent(status_vbox)


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

	var bg := Color(0.10, 0.16, 0.23, 0.94)
	var hover_bg := Color(0.14, 0.22, 0.30, 0.98)
	var pressed_bg := Color(0.08, 0.13, 0.20, 1.0)
	var border := Color(0.44, 0.58, 0.74, 0.24)
	var font_color := Color(0.92, 0.96, 1.0)
	if tone == "primary":
		bg = Color(0.18, 0.35, 0.70, 0.98)
		hover_bg = Color(0.24, 0.42, 0.82, 1.0)
		pressed_bg = Color(0.14, 0.29, 0.58, 1.0)
		border = Color(0.70, 0.82, 1.0, 0.40)
	elif tone == "secondary":
		bg = Color(0.10, 0.16, 0.23, 0.94)
		hover_bg = Color(0.14, 0.22, 0.30, 0.98)
		pressed_bg = Color(0.08, 0.13, 0.20, 1.0)
		border = Color(0.44, 0.58, 0.74, 0.24)

	for style in [normal, hover, pressed, focus, disabled]:
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10

	normal.bg_color = bg
	hover.bg_color = hover_bg
	pressed.bg_color = pressed_bg
	focus.bg_color = hover_bg
	disabled.bg_color = Color(bg.r, bg.g, bg.b, 0.42)
	normal.border_color = border
	hover.border_color = border
	pressed.border_color = border
	focus.border_color = Color(border.r, border.g, border.b, 0.56)
	disabled.border_color = Color(border.r, border.g, border.b, 0.18)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.48))


func _apply_line_edit_style(line_edit: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.11, 0.16, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.48, 0.60, 0.76, 0.24)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	line_edit.add_theme_stylebox_override("normal", style)
	line_edit.add_theme_stylebox_override("focus", style.duplicate())
