extends Control

const MAX_ROUNDS := 3
const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const POSTURES := [&"stand", &"crouch", &"peek"]
const POSTURE_TEXT := {
	&"stand": "站姿",
	&"crouch": "蹲姿",
	&"peek": "探头",
}

var current_round := 1
var current_turn_peer_id := 1
var player_posture: StringName = &"stand"
var opponent_posture: StringName = &"crouch"
var player_hp := 2
var opponent_hp := 2
var match_finished := false
var selected_shot_position := Vector2.ZERO
var has_selected_shot := false
var decal_records := []
var round_logs := []
var server_message := "等待对局开始..."
var summary_text := ""
var my_peer_id := 1
var opponent_peer_id := 2

@onready var round_label: Label = $SafeArea/MainLayout/HeaderPanel/HeaderMargin/HeaderVBox/RoundLabel
@onready var turn_label: Label = $SafeArea/MainLayout/HeaderPanel/HeaderMargin/HeaderVBox/TurnLabel
@onready var server_label: Label = $SafeArea/MainLayout/HeaderPanel/HeaderMargin/HeaderVBox/ServerLabel
@onready var player_state_label: Label = $SafeArea/MainLayout/ContentHBox/LeftPanel/LeftMargin/LeftVBox/PlayerStateLabel
@onready var opponent_state_label: Label = $SafeArea/MainLayout/ContentHBox/LeftPanel/LeftMargin/LeftVBox/OpponentStateLabel
@onready var log_label: Label = $SafeArea/MainLayout/ContentHBox/LeftPanel/LeftMargin/LeftVBox/LogLabel
@onready var battlefield_rect: ColorRect = $SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/BattlefieldRect
@onready var aim_marker: ColorRect = $SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/BattlefieldRect/AimMarker
@onready var decal_root: Control = $SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/BattlefieldRect/DecalRoot
@onready var selection_label: Label = $SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/SelectionLabel
@onready var switch_posture_button: Button = $SafeArea/MainLayout/ContentHBox/RightPanel/RightMargin/RightVBox/SwitchPostureButton
@onready var submit_shot_button: Button = $SafeArea/MainLayout/ContentHBox/RightPanel/RightMargin/RightVBox/SubmitShotButton
@onready var disconnect_button: Button = $SafeArea/MainLayout/ContentHBox/RightPanel/RightMargin/RightVBox/DisconnectButton
@onready var return_menu_button: Button = $SafeArea/MainLayout/ContentHBox/RightPanel/RightMargin/RightVBox/ReturnMenuButton
@onready var summary_label: Label = $SafeArea/MainLayout/ContentHBox/RightPanel/RightMargin/RightVBox/SummaryLabel
@onready var floating_subtitle_layer: Control = $FloatingSubtitleLayer


func _ready() -> void:
	_apply_terminal_style()
	switch_posture_button.pressed.connect(_on_switch_posture_pressed)
	submit_shot_button.pressed.connect(_on_submit_shot_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	return_menu_button.pressed.connect(_on_return_menu_pressed)
	battlefield_rect.gui_input.connect(_on_battlefield_gui_input)

	my_peer_id = NetworkManager.local_peer_id
	opponent_peer_id = NetworkManager.get_other_peer_id()

	if NetworkManager.is_server:
		server_message = "服务端已就绪，等待客户端加入..."
		if NetworkManager.get_peer_count() >= 2:
			_start_match()
		else:
			NetworkManager.peer_connected.connect(_on_peer_connected_server)
	else:
		server_message = "已连接服务端，等待对局开始..."

	_redraw_decals()
	_refresh_view()


func _on_peer_connected_server(peer_id: int) -> void:
	if NetworkManager.get_peer_count() >= 2:
		opponent_peer_id = peer_id
		_start_match()


func _start_match() -> void:
	current_round = 1
	current_turn_peer_id = 1
	player_posture = &"stand"
	opponent_posture = &"crouch"
	player_hp = 2
	opponent_hp = 2
	match_finished = false
	decal_records.clear()
	round_logs.clear()
	server_message = "对局开始！第 1 回合由主机先手"
	_append_log("系统：对局开始，第 1 回合由主机先手")
	_broadcast_state()
	_refresh_view()


func _on_battlefield_gui_input(event: InputEvent) -> void:
	if not _can_local_operate():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected_shot_position = Vector2(
				clampf(mouse_event.position.x, 12.0, battlefield_rect.size.x - 12.0),
				clampf(mouse_event.position.y, 12.0, battlefield_rect.size.y - 12.0)
			)
			has_selected_shot = true
			aim_marker.visible = true
			aim_marker.position = selected_shot_position - aim_marker.size * 0.5
			selection_label.text = "已选落点：(%.0f, %.0f)，可提交射击" % [
				selected_shot_position.x,
				selected_shot_position.y,
			]
			_refresh_view()


func _on_switch_posture_pressed() -> void:
	if not _can_local_operate():
		return
	rpc("_server_request_switch_posture", my_peer_id)


func _on_submit_shot_pressed() -> void:
	if not _can_local_operate() or not has_selected_shot:
		return
	rpc("_server_request_shot", my_peer_id, selected_shot_position)
	has_selected_shot = false
	aim_marker.visible = false
	selection_label.text = "射击已提交，等待服务端裁定..."
	_refresh_view()


func _on_disconnect_pressed() -> void:
	NetworkManager.disconnect_network()
	RouteGuard.request_route("main_menu", "联机房间-主动断开")


func _on_return_menu_pressed() -> void:
	if NetworkManager.is_network_connected:
		NetworkManager.disconnect_network()
	RouteGuard.request_route("main_menu", "联机房间-返回主页")


func _can_local_operate() -> bool:
	if match_finished:
		return false
	if not NetworkManager.is_network_connected:
		return false
	return current_turn_peer_id == my_peer_id


@rpc("any_peer")
func _server_request_switch_posture(requester_peer_id: int) -> void:
	if not NetworkManager.is_server:
		return
	if match_finished:
		return
	if current_turn_peer_id != requester_peer_id:
		return

	var posture: StringName
	var is_player: bool = requester_peer_id == 1
	if is_player:
		var idx := POSTURES.find(player_posture)
		player_posture = POSTURES[(idx + 1) % POSTURES.size()]
		posture = player_posture
	else:
		var idx := POSTURES.find(opponent_posture)
		opponent_posture = POSTURES[(idx + 1) % POSTURES.size()]
		posture = opponent_posture

	var who_text := "主机" if is_player else "客机"
	server_message = "%s切换为%s" % [who_text, _posture_text(posture)]
	_append_log("第 %d 回合：%s切换为%s" % [current_round, who_text, _posture_text(posture)])
	_broadcast_state()


@rpc("any_peer")
func _server_request_shot(requester_peer_id: int, aim_position: Vector2) -> void:
	if not NetworkManager.is_server:
		return
	if match_finished:
		return
	if current_turn_peer_id != requester_peer_id:
		return

	var is_player: bool = requester_peer_id == 1
	var shooter_posture: StringName = player_posture if is_player else opponent_posture
	var target_posture: StringName = opponent_posture if is_player else player_posture

	var result := _build_shot_result(
		requester_peer_id,
		aim_position,
		shooter_posture,
		target_posture,
		current_round
	)
	_apply_shot_result(result, is_player)


func _build_shot_result(
	shooter_peer_id: int,
	aim_position: Vector2,
	shooter_posture: StringName,
	target_posture: StringName,
	round_index: int
) -> Dictionary:
	var seed_value := int(
		roundi(aim_position.x) * 3
		+ roundi(aim_position.y) * 5
		+ round_index * 17
		+ _posture_seed(shooter_posture) * 11
		+ _posture_seed(target_posture) * 7
		+ shooter_peer_id * 23
	)
	var center_distance := absf(aim_position.x - battlefield_rect.size.x * 0.5) \
		+ absf(aim_position.y - battlefield_rect.size.y * 0.45)
	var target_threshold := 34
	match target_posture:
		&"stand":
			target_threshold = 68
		&"crouch":
			target_threshold = 46
		&"peek":
			target_threshold = 58

	if center_distance < 120.0:
		target_threshold += 10
	elif center_distance > 220.0:
		target_threshold -= 6

	var roll: int = abs(seed_value) % 100
	var hit: bool = roll < clampi(target_threshold, 25, 82)
	var impact_position := Vector2(
		clampf(aim_position.x + float((seed_value % 31) - 15), 12.0, battlefield_rect.size.x - 12.0),
		clampf(aim_position.y + float((int(floor(float(seed_value) / 3.0)) % 31) - 15), 12.0, battlefield_rect.size.y - 12.0)
	)
	var shooter_text := "主机" if shooter_peer_id == 1 else "客机"
	var target_text := "客机" if shooter_peer_id == 1 else "主机"
	var server_text := "裁定：%s%s了%s，命中点 (%.0f, %.0f)" % [
		shooter_text,
		"命中" if hit else "未命中",
		target_text,
		impact_position.x,
		impact_position.y,
	]

	return {
		"shooter_peer_id": shooter_peer_id,
		"hit": hit,
		"impact_position": impact_position,
		"server_text": server_text,
		"log_text": "第 %d 回合：%s%s%s" % [
			round_index,
			shooter_text,
			"命中" if hit else "未命中",
			target_text,
		],
	}


func _apply_shot_result(result: Dictionary, is_shooter_player: bool) -> void:
	var hit := bool(result.get("hit", false))
	var shooter_peer_id := int(result.get("shooter_peer_id", 1))
	server_message = str(result.get("server_text", ""))
	_append_log(str(result.get("log_text", "")))
	_add_decal(result)

	if hit:
		if is_shooter_player:
			opponent_hp = max(opponent_hp - 1, 0)
		else:
			player_hp = max(player_hp - 1, 0)

	var target_hp := opponent_hp if is_shooter_player else player_hp
	if target_hp <= 0:
		var winner_text := "主机胜" if is_shooter_player else "客机胜"
		_finish_match(winner_text, "第 %d 回合击杀" % current_round)
		return

	if shooter_peer_id == 1:
		current_turn_peer_id = opponent_peer_id
	else:
		current_round += 1
		if current_round > MAX_ROUNDS:
			_finish_match(_resolve_round_limit_result(), "已打满 %d 回合" % MAX_ROUNDS)
			return
		current_turn_peer_id = 1
		_append_log("系统：第 %d 回合开始，由主机先手" % current_round)

	_broadcast_state()


func _resolve_round_limit_result() -> String:
	if player_hp > opponent_hp:
		return "主机胜"
	if player_hp < opponent_hp:
		return "客机胜"
	return "平局"


func _finish_match(result_text: String, detail_text: String) -> void:
	match_finished = true
	summary_text = "对局结束\n结果：%s\n说明：%s\n最终血量：主机 %d / 客机 %d" % [
		result_text,
		detail_text,
		player_hp,
		opponent_hp,
	]
	_append_log("系统：对局结束，%s" % result_text)
	_broadcast_state()


func _broadcast_state() -> void:
	var state := {
		"current_round": current_round,
		"current_turn_peer_id": current_turn_peer_id,
		"player_posture": String(player_posture),
		"opponent_posture": String(opponent_posture),
		"player_hp": player_hp,
		"opponent_hp": opponent_hp,
		"match_finished": match_finished,
		"decal_records": decal_records.duplicate(true),
		"round_logs": round_logs.slice(max(0, round_logs.size() - 8), round_logs.size()),
		"server_message": server_message,
		"summary_text": summary_text,
	}
	rpc("_client_receive_state", state)


@rpc("any_peer")
func _client_receive_state(state: Dictionary) -> void:
	current_round = int(state.get("current_round", 1))
	current_turn_peer_id = int(state.get("current_turn_peer_id", 1))
	player_posture = StringName(str(state.get("player_posture", "stand")))
	opponent_posture = StringName(str(state.get("opponent_posture", "crouch")))
	player_hp = int(state.get("player_hp", 2))
	opponent_hp = int(state.get("opponent_hp", 2))
	match_finished = bool(state.get("match_finished", false))
	decal_records = state.get("decal_records", []).duplicate(true)
	round_logs = state.get("round_logs", []).duplicate(true)
	server_message = str(state.get("server_message", ""))
	summary_text = str(state.get("summary_text", ""))

	_redraw_decals()
	_refresh_view()
	if not server_message.is_empty():
		_show_floating_subtitle(server_message)


func _refresh_view() -> void:
	$SafeArea/MainLayout/HeaderPanel/HeaderMargin/HeaderVBox/TitleLabel.text = "联机对战房间"
	round_label.text = "当前回合：%d / %d" % [current_round, MAX_ROUNDS]
	turn_label.text = "当前操作方：%s" % _turn_text()
	var my_posture: StringName = player_posture if my_peer_id == 1 else opponent_posture
	var my_hp: int = player_hp if my_peer_id == 1 else opponent_hp
	var opp_posture: StringName = opponent_posture if my_peer_id == 1 else player_posture
	var opp_hp: int = opponent_hp if my_peer_id == 1 else player_hp
	var role_text := "（主机）" if my_peer_id == 1 else "（客机）"

	player_state_label.text = "我方状态%s\n血量：%d\n姿势：%s" % [
		role_text,
		my_hp,
		_posture_text(my_posture),
	]
	opponent_state_label.text = "对手状态\n血量：%d\n姿势：%s" % [
		opp_hp,
		_posture_text(opp_posture),
	]
	log_label.text = "最近事件\n%s" % "\n".join(_last_logs())
	server_label.text = server_message
	switch_posture_button.disabled = not _can_local_operate()
	submit_shot_button.disabled = not _can_local_operate() or not has_selected_shot
	summary_label.visible = match_finished
	summary_label.text = summary_text


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
	tint.color = Color(0.02, 0.04, 0.06, 0.80)
	add_child(tint)
	move_child(tint, 1)

	var top_glow := ColorRect.new()
	top_glow.name = "RuntimeTopGlow"
	top_glow.anchor_left = 0.0
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 1.0
	top_glow.anchor_bottom = 0.18
	top_glow.color = Color(0.08, 0.15, 0.24, 0.24)
	add_child(top_glow)
	move_child(top_glow, 2)

	var safe_area: MarginContainer = $SafeArea
	safe_area.add_theme_constant_override("margin_left", 20)
	safe_area.add_theme_constant_override("margin_top", 20)
	safe_area.add_theme_constant_override("margin_right", 20)
	safe_area.add_theme_constant_override("margin_bottom", 20)

	var main_layout: VBoxContainer = $SafeArea/MainLayout
	main_layout.add_theme_constant_override("separation", 14)

	var header_panel: PanelContainer = $SafeArea/MainLayout/HeaderPanel
	_apply_surface_panel_style(header_panel, true)
	$SafeArea/MainLayout/HeaderPanel/HeaderMargin.add_theme_constant_override("margin_left", 18)
	$SafeArea/MainLayout/HeaderPanel/HeaderMargin.add_theme_constant_override("margin_top", 14)
	$SafeArea/MainLayout/HeaderPanel/HeaderMargin.add_theme_constant_override("margin_right", 18)
	$SafeArea/MainLayout/HeaderPanel/HeaderMargin.add_theme_constant_override("margin_bottom", 14)
	$SafeArea/MainLayout/HeaderPanel/HeaderMargin/HeaderVBox.add_theme_constant_override("separation", 6)
	server_label.modulate = Color(0.96, 0.80, 0.42)
	selection_label.modulate = Color(0.84, 0.90, 0.98)
	summary_label.modulate = Color(0.84, 0.90, 0.98)

	var content_hbox: HBoxContainer = $SafeArea/MainLayout/ContentHBox
	var battle_panel: PanelContainer = $SafeArea/MainLayout/ContentHBox/BattlePanel
	var left_panel: PanelContainer = $SafeArea/MainLayout/ContentHBox/LeftPanel
	var right_panel: PanelContainer = $SafeArea/MainLayout/ContentHBox/RightPanel
	var battle_tip_label: Label = $SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/BattleTipLabel

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_layout.add_child(scroll)
	main_layout.move_child(scroll, 1)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(content_vbox)

	battle_panel.custom_minimum_size = Vector2(0, 360)
	battle_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_apply_surface_panel_style(battle_panel, false)
	battle_panel.reparent(content_vbox)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	content_vbox.add_child(bottom_row)

	left_panel.custom_minimum_size = Vector2(0, 210)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_apply_surface_panel_style(left_panel, false)
	left_panel.reparent(bottom_row)

	right_panel.custom_minimum_size = Vector2(0, 210)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_apply_surface_panel_style(right_panel, false)
	right_panel.reparent(bottom_row)

	content_hbox.queue_free()

	battlefield_rect.custom_minimum_size = Vector2(0, 248)
	battle_tip_label.text = "先点击战场选点，再提交射击；下方会实时显示当前落点和服务端裁定。"
	battle_tip_label.modulate = Color(0.84, 0.90, 0.98)
	player_state_label.modulate = Color(0.90, 0.95, 1.0)
	opponent_state_label.modulate = Color(0.90, 0.95, 1.0)
	log_label.modulate = Color(0.78, 0.86, 0.95)

	switch_posture_button.custom_minimum_size = Vector2(0, 48)
	submit_shot_button.custom_minimum_size = Vector2(0, 48)
	disconnect_button.custom_minimum_size = Vector2(0, 46)
	return_menu_button.custom_minimum_size = Vector2(0, 46)
	_apply_action_button_style(switch_posture_button, "secondary")
	_apply_action_button_style(submit_shot_button, "primary")
	_apply_action_button_style(disconnect_button, "danger")
	_apply_action_button_style(return_menu_button, "secondary")


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
	match tone:
		"primary":
			bg = Color(0.18, 0.35, 0.70, 0.98)
			hover_bg = Color(0.24, 0.42, 0.82, 1.0)
			pressed_bg = Color(0.14, 0.29, 0.58, 1.0)
			border = Color(0.70, 0.82, 1.0, 0.40)
		"danger":
			bg = Color(0.28, 0.10, 0.12, 0.92)
			hover_bg = Color(0.36, 0.12, 0.15, 0.98)
			pressed_bg = Color(0.24, 0.08, 0.10, 0.98)
			border = Color(1.0, 0.56, 0.58, 0.46)
		_:
			pass

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


func _add_decal(result: Dictionary) -> void:
	var shooter_peer_id := int(result.get("shooter_peer_id", 1))
	var impact_position: Vector2 = result.get("impact_position", Vector2.ZERO)
	var record := {
		"shooter_peer_id": shooter_peer_id,
		"x": impact_position.x,
		"y": impact_position.y,
		"hit": bool(result.get("hit", false)),
	}
	decal_records.append(record)


func _redraw_decals() -> void:
	for child in decal_root.get_children():
		child.queue_free()

	for index in range(decal_records.size()):
		var record: Dictionary = decal_records[index]
		var decal := ColorRect.new()
		decal.name = "Decal%02d" % (index + 1)
		var sid := int(record.get("shooter_peer_id", 1))
		decal.color = Color("5ec8ff") if sid == 1 else Color("ff8a5b")
		decal.custom_minimum_size = Vector2(14, 14)
		decal.size = Vector2(14, 14)
		decal.position = Vector2(
			float(record.get("x", 0.0)),
			float(record.get("y", 0.0))
		) - decal.size * 0.5
		decal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decal_root.add_child(decal)


func _append_log(text: String) -> void:
	if text.is_empty():
		return
	round_logs.append(text)
	if round_logs.size() > 8:
		round_logs = round_logs.slice(round_logs.size() - 8, round_logs.size())


func _last_logs() -> Array:
	if round_logs.is_empty():
		return ["系统：等待第一条操作"]
	return round_logs


func _show_floating_subtitle(text: String) -> void:
	var subtitle := Label.new()
	subtitle.text = text
	subtitle.position = Vector2(40.0, 20.0)
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.modulate = Color(1, 1, 1, 0.0)
	floating_subtitle_layer.add_child(subtitle)

	var tween := create_tween()
	tween.tween_property(subtitle, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(subtitle, "position:y", 6.0, 0.4)
	tween.tween_interval(0.45)
	tween.tween_property(subtitle, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func() -> void: subtitle.queue_free())


func _turn_text() -> String:
	if match_finished:
		return "已结束"
	return "我方回合" if current_turn_peer_id == my_peer_id else "对方回合"


func _posture_text(posture: StringName) -> String:
	return str(POSTURE_TEXT.get(posture, "未知姿势"))


func _posture_seed(posture: StringName) -> int:
	match posture:
		&"stand":
			return 1
		&"crouch":
			return 2
		&"peek":
			return 3
	return 0
