extends Node

const DEFAULT_PORT := 57890
const MAX_PEERS := 2

signal server_started(port: int)
signal server_start_failed(reason: String)
signal connected_to_server()
signal connection_failed(reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal server_disconnected()
signal network_disconnected()

var is_server := false
var is_network_connected := false
var local_peer_id := 0
var peer_ids: Array[int] = []
var last_error := ""


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func create_server(port: int = DEFAULT_PORT) -> bool:
	_close_existing_peer()

	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(port, MAX_PEERS)
	if result != OK:
		last_error = "创建服务端失败，错误码：%d" % result
		server_start_failed.emit(last_error)
		return false

	multiplayer.multiplayer_peer = peer
	is_server = true
	is_network_connected = true
	local_peer_id = 1
	peer_ids = [1]
	last_error = ""
	server_started.emit(port)
	return true


func connect_to_server(address: String, port: int = DEFAULT_PORT) -> bool:
	_close_existing_peer()

	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address, port)
	if result != OK:
		last_error = "创建客户端失败，错误码：%d" % result
		connection_failed.emit(last_error)
		return false

	multiplayer.multiplayer_peer = peer
	is_server = false
	is_network_connected = false
	local_peer_id = 0
	peer_ids = []
	last_error = ""
	return true


func disconnect_network() -> void:
	if multiplayer.multiplayer_peer == null:
		return

	multiplayer.multiplayer_peer.close()
	_close_existing_peer()
	network_disconnected.emit()


func get_peer_count() -> int:
	return peer_ids.size()


func get_other_peer_id() -> int:
	for pid in peer_ids:
		if pid != local_peer_id:
			return pid
	return 0


func _close_existing_peer() -> void:
	if multiplayer.multiplayer_peer != null:
		var old_peer := multiplayer.multiplayer_peer
		multiplayer.multiplayer_peer = null
		if old_peer.is_open():
			old_peer.close()

	is_server = false
	is_network_connected = false
	local_peer_id = 0
	peer_ids.clear()


func _on_peer_connected(peer_id: int) -> void:
	if not peer_ids.has(peer_id):
		peer_ids.append(peer_id)
	peer_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_ids.erase(peer_id)
	peer_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	is_network_connected = true
	local_peer_id = multiplayer.get_unique_id()
	if not peer_ids.has(local_peer_id):
		peer_ids.append(local_peer_id)
	peer_ids.sort()
	connected_to_server.emit()


func _on_connection_failed() -> void:
	last_error = "连接服务端失败，请检查 IP 和端口"
	_close_existing_peer()
	connection_failed.emit(last_error)


func _on_server_disconnected() -> void:
	is_network_connected = false
	_close_existing_peer()
	server_disconnected.emit()
	network_disconnected.emit()
