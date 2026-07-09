extends RefCounted


static func ensure_default_input_map() -> void:
    _ensure_action("camera_left", [_key(KEY_A), _key(KEY_LEFT)])
    _ensure_action("camera_right", [_key(KEY_D), _key(KEY_RIGHT)])
    _ensure_action("camera_up", [_key(KEY_W), _key(KEY_UP)])
    _ensure_action("camera_down", [_key(KEY_S), _key(KEY_DOWN)])
    _ensure_action("aim_zoom_in", [_key(KEY_Q), _mouse_button(MOUSE_BUTTON_WHEEL_UP)])
    _ensure_action("aim_zoom_out", [_key(KEY_E), _mouse_button(MOUSE_BUTTON_WHEEL_DOWN)])
    _ensure_action("aim_hold", [_key(KEY_SHIFT)])
    # 注意：Space 在“进入瞄准/屏息模式（双击左键）”后用于屏息，故不再映射到 fire。
    # 鼠标左键开火由战斗场景脚本自行处理（按下/拖动/松开），这里仅保留 Enter。
    _ensure_action("fire", [_key(KEY_ENTER)])
    _ensure_action("use_scan", [_key(KEY_1)])
    _ensure_action("use_time_extend", [_key(KEY_2)])
    _ensure_action("weapon_switch_next", [_key(KEY_BRACKETRIGHT)])
    _ensure_action("weapon_switch_prev", [_key(KEY_BRACKETLEFT)])
    _ensure_action("pvp_switch_posture", [_key(KEY_TAB)])
    _ensure_action("pvp_disconnect", [_key(KEY_X)])
    _ensure_action("ui_back", [_key(KEY_ESCAPE)])
    _ensure_action("debug_toggle_weapon_pos", [_key(KEY_F11)])
    _ensure_action("debug_switch_adjust_mode", [_key(KEY_F10)])
    _ensure_action("debug_reset_weapon_pos", [_key(KEY_R)])


static func _ensure_action(action_name: String, events: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    if InputMap.action_get_events(action_name).is_empty():
        for event in events:
            InputMap.action_add_event(action_name, event)


static func _key(code: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    return event


static func _mouse_button(button_index: MouseButton) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = button_index
    return event
