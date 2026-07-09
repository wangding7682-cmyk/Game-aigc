extends Control


func _ready() -> void:
	if has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel"):
		var subtitle_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
		subtitle_label.text = "旧菜单占位页，当前主入口已切换到新的主流程菜单。"

	if has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartBattleButton"):
		var start_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartBattleButton
		start_button.pressed.connect(func() -> void:
			RouteGuard.request_route("level", "旧主菜单-开始战斗", CoreGameState.current_level_id)
		)
