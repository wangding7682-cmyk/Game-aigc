extends Node

@warning_ignore("unused_signal")
signal main_menu_requested
@warning_ignore("unused_signal")
signal level_requested(level_id: int)
@warning_ignore("unused_signal")
signal pvp_lobby_requested
@warning_ignore("unused_signal")
signal pvp_network_room_requested
@warning_ignore("unused_signal")
signal battle_finished(result: Dictionary)
@warning_ignore("unused_signal")
signal retry_requested
@warning_ignore("unused_signal")
signal upgrade_requested
@warning_ignore("unused_signal")
signal next_level_requested
@warning_ignore("unused_signal")
signal settings_requested
@warning_ignore("unused_signal")
signal tuning_requested
signal analytics_logged(event_name: String, payload: Dictionary)
@warning_ignore("unused_signal")
signal weapon_equipped(weapon_id: String)
@warning_ignore("unused_signal")
signal skin_equipped(weapon_id: String, skin_id: String)
@warning_ignore("unused_signal")
signal weapon_library_requested
@warning_ignore("unused_signal")
signal shop_requested
@warning_ignore("unused_signal")
signal test_center_requested


func log_event(event_name: String, payload: Dictionary = {}) -> void:
	analytics_logged.emit(event_name, payload)
	var analytics_service := get_node_or_null("/root/AnalyticsService")
	if analytics_service != null:
		analytics_service.track_event(event_name, payload)
		return

	print("[Analytics] %s %s" % [event_name, JSON.stringify(payload)])
