extends Node

const ROOT_SCENE = preload("res://scenes/core/core_game_root.tscn")
const LOBBY_SCENE_PATH := "res://scenes/pvp/pvp_lobby.tscn"
const NETWORK_ROOM_SCENE_PATH := "res://scenes/pvp/pvp_network_room.tscn"

var _failures: Array[String] = []
var _log_lines: PackedStringArray = []


func _ready() -> void:
	await _run()


func _log(msg: String) -> void:
	_log_lines.append(msg)
	print(msg)


func _run() -> void:
	CoreGameState.reset_progress()

	var root: Node = ROOT_SCENE.instantiate()
	add_child(root)
	await get_tree().process_frame
	await get_tree().process_frame

	_log("=== PVP 局域网联机烟雾测试开始 ===")

	_test_network_manager_api()
	_test_lobby_entry(root)
	_test_lobby_scene_structure(root)
	_test_network_room_scene_structure()
	_test_event_signals()
	_test_server_authority_logic()

	_finish()


func _test_network_manager_api() -> void:
	_log("[1/6] 测试 NetworkManager API...")

	_assert_true(NetworkManager.has_method("create_server"), "缺少 create_server")
	_assert_true(NetworkManager.has_method("connect_to_server"), "缺少 connect_to_server")
	_assert_true(NetworkManager.has_method("disconnect_network"), "缺少 disconnect_network")
	_assert_true(NetworkManager.has_method("get_peer_count"), "缺少 get_peer_count")
	_assert_true(NetworkManager.has_method("get_other_peer_id"), "缺少 get_other_peer_id")

	_assert_false(NetworkManager.is_server, "初始不应为服务端")
	_assert_false(NetworkManager.is_network_connected, "初始不应已连接")
	_assert_eq(NetworkManager.get_peer_count(), 0, "初始 peer 数应为 0")

	var signals := [
		"server_started",
		"server_start_failed",
		"connected_to_server",
		"connection_failed",
		"peer_connected",
		"peer_disconnected",
		"network_disconnected",
	]
	for sig in signals:
		_assert_true(NetworkManager.has_signal(sig), "缺少信号：%s" % sig)

	_log("  通过")


func _test_lobby_entry(root: Node) -> void:
	_log("[2/6] 测试大厅入口...")

	_assert_true(CoreEventBus.has_signal("pvp_lobby_requested"), "缺少 pvp_lobby_requested 信号")
	_assert_true(CoreEventBus.has_signal("pvp_network_room_requested"), "缺少 pvp_network_room_requested 信号")

	CoreEventBus.pvp_lobby_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	_assert_scene(root, LOBBY_SCENE_PATH, "触发后应进入大厅场景")
	_log("  通过")


func _test_lobby_scene_structure(root: Node) -> void:
	_log("[3/6] 测试大厅场景结构...")

	var lobby: Node = root.get("current_screen")
	if lobby == null:
		_fail("大厅未实例化")
		return

	_assert_method(lobby, "_on_create_server_pressed", "缺少创建房间处理")
	_assert_method(lobby, "_on_join_server_pressed", "缺少加入房间处理")
	_assert_method(lobby, "_on_back_pressed", "缺少返回处理")

	var ip_edit := lobby.get_node_or_null("SafeArea/MainLayout/IpRow/IpLineEdit")
	_assert_true(ip_edit != null, "缺少 IP 输入框")

	var port_edit := lobby.get_node_or_null("SafeArea/MainLayout/PortRow/PortLineEdit")
	_assert_true(port_edit != null, "缺少端口输入框")

	var create_btn := lobby.get_node_or_null("SafeArea/MainLayout/ButtonVBox/CreateServerButton")
	_assert_true(create_btn != null, "缺少创建房间按钮")

	var join_btn := lobby.get_node_or_null("SafeArea/MainLayout/ButtonVBox/JoinServerButton")
	_assert_true(join_btn != null, "缺少加入房间按钮")

	var status_label := lobby.get_node_or_null("SafeArea/MainLayout/StatusLabel")
	_assert_true(status_label != null, "缺少状态标签")

	_log("  通过")


func _test_network_room_scene_structure() -> void:
	_log("[4/6] 测试网络房间场景结构...")

	var room_scene: PackedScene = load(NETWORK_ROOM_SCENE_PATH)
	if room_scene == null:
		_fail("网络房间场景加载失败")
		return

	var room: Node = room_scene.instantiate()
	add_child(room)
	await get_tree().process_frame

	_assert_method(room, "_on_switch_posture_pressed", "缺少切姿势处理")
	_assert_method(room, "_on_submit_shot_pressed", "缺少提交射击处理")
	_assert_method(room, "_on_disconnect_pressed", "缺少断开处理")
	_assert_method(room, "_server_request_switch_posture", "缺少服务端 RPC：切姿势")
	_assert_method(room, "_server_request_shot", "缺少服务端 RPC：射击")
	_assert_method(room, "_client_receive_state", "缺少客户端 RPC：收状态")
	_assert_method(room, "_broadcast_state", "缺少广播状态方法")
	_assert_method(room, "_build_shot_result", "缺少命中裁定方法")
	_assert_method(room, "_apply_shot_result", "缺少结果应用方法")

	var battlefield := room.get_node_or_null("SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/BattlefieldRect")
	_assert_true(battlefield != null, "缺少靶板")

	var decal_root := room.get_node_or_null("SafeArea/MainLayout/ContentHBox/BattlePanel/BattleMargin/BattleVBox/BattlefieldRect/DecalRoot")
	_assert_true(decal_root != null, "缺少弹贴根节点")

	room.queue_free()
	_log("  通过")


func _test_event_signals() -> void:
	_log("[5/6] 测试事件信号...")

	var lobby_received := false
	var room_received := false

	var lobby_handler := func():
		lobby_received = true
	var room_handler := func():
		room_received = true

	CoreEventBus.pvp_lobby_requested.connect(lobby_handler)
	CoreEventBus.pvp_network_room_requested.connect(room_handler)

	CoreEventBus.pvp_lobby_requested.emit()
	CoreEventBus.pvp_network_room_requested.emit()

	_assert_true(lobby_received, "pvp_lobby_requested 未触发")
	_assert_true(room_received, "pvp_network_room_requested 未触发")

	CoreEventBus.pvp_lobby_requested.disconnect(lobby_handler)
	CoreEventBus.pvp_network_room_requested.disconnect(room_handler)
	_log("  通过")


func _test_server_authority_logic() -> void:
	_log("[6/6] 测试服务端权威逻辑（单进程模拟）...")

	var room_scene: PackedScene = load(NETWORK_ROOM_SCENE_PATH)
	var room: Node = room_scene.instantiate()
	add_child(room)
	await get_tree().process_frame

	room.my_peer_id = 1
	room.opponent_peer_id = 2
	room.current_round = 1
	room.current_turn_peer_id = 1
	room.player_hp = 2
	room.opponent_hp = 2
	room.player_posture = &"stand"
	room.opponent_posture = &"crouch"
	room.match_finished = false
	room.decal_records.clear()
	room.round_logs.clear()
	room._refresh_view()

	var initial_hp: int = room.opponent_hp
	var result: Dictionary = room._build_shot_result(
		1,
		Vector2(200, 120),
		&"stand",
		&"crouch",
		1
	)
	_assert_true(result.has("hit"), "裁定结果缺少 hit 字段")
	_assert_true(result.has("impact_position"), "裁定结果缺少 impact_position")
	_assert_true(result.has("server_text"), "裁定结果缺少 server_text")
	_assert_true(result.has("shooter_peer_id"), "裁定结果缺少 shooter_peer_id")

	var hit := bool(result.get("hit", false))
	room._apply_shot_result(result, true)

	if hit:
		_assert_eq(room.opponent_hp, initial_hp - 1, "命中后对手血量应 -1")
	else:
		_assert_eq(room.opponent_hp, initial_hp, "未命中时对手血量不变")

	_assert_eq(room.current_turn_peer_id, 2, "主机射击后应轮到客机")

	var state_dict := {
		"current_round": 2,
		"current_turn_peer_id": 1,
		"player_posture": "crouch",
		"opponent_posture": "peek",
		"player_hp": 1,
		"opponent_hp": 1,
		"match_finished": false,
		"decal_records": [{"shooter_peer_id": 1, "x": 100, "y": 80, "hit": true}],
		"round_logs": ["测试日志"],
		"server_message": "测试同步",
		"summary_text": "",
	}
	room._client_receive_state(state_dict)
	_assert_eq(room.current_round, 2, "状态同步后回合数应更新")
	_assert_eq(room.player_hp, 1, "状态同步后血量应更新")
	_assert_eq(room.decal_records.size(), 1, "状态同步后弹贴数应更新")

	room.queue_free()
	_log("  通过")


func _assert_scene(root: Node, expected_path: String, message: String) -> void:
	var current_screen: Node = root.get("current_screen")
	if current_screen == null:
		_fail("%s：当前场景为空" % message)
		return
	var current_path: String = str(root.get("current_scene_path"))
	if current_path != expected_path:
		_fail("%s：实际是 %s" % [message, current_path])


func _assert_method(obj: Node, method_name: String, message: String) -> void:
	if not obj.has_method(method_name):
		_fail(message + "（%s）" % method_name)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _assert_false(condition: bool, message: String) -> void:
	if condition:
		_fail(message)


func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail(message + "（实际：%s，期望：%s）" % [str(actual), str(expected)])


func _fail(message: String) -> void:
	_failures.append(message)
	_log("  [FAIL] " + message)


func _finish() -> void:
	var result_lines := _log_lines.duplicate()
	result_lines.append("")
	if _failures.is_empty():
		result_lines.append("=== 全部通过（6/6）===")
	else:
		result_lines.append("=== 失败 %d 项 ===" % _failures.size())
		for f in _failures:
			result_lines.append("  - " + f)

	var output := String("\n").join(result_lines)
	print(output)

	var file := FileAccess.open("user://pvp_network_smoke_result.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(output)
		file.close()

	get_tree().quit(0 if _failures.is_empty() else 1)
