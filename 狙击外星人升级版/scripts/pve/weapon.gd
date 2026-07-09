extends Node

var weapon_id: String = "default_sniper"
var display_name: String = "狙击步枪"

var zoom_default: float = 1.0
var zoom_min: float = 0.9
var zoom_max: float = 2.2
var zoom_quick_aim: float = 1.6
var zoom_step: float = 0.15

var camera_pan_speed: float = 300.0
var edge_pan_speed_scale: float = 1.0

var hold_stabilize_sec: float = 1.0
var aim_recover_sec: float = 0.35

var spread_idle: float = 34.0
var spread_hold: float = 10.0
var hit_tolerance_radius: float = 26.0

var time_extend_sec: float = 15.0
var scan_highlight_sec: float = 3.0

var recoil_duration: float = 0.18
var post_shot_recover_duration: float = 0.24
var cover_blast_tier: String = "medium"

var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func setup_from_profile(profile: Dictionary) -> void:
	zoom_default = float(profile.get("zoom_default", 1.0))
	zoom_min = float(profile.get("zoom_min", 0.9))
	zoom_max = float(profile.get("zoom_max", 2.2))
	zoom_quick_aim = float(profile.get("zoom_quick_aim", clampf(zoom_max * 0.72, 1.5, zoom_max)))
	zoom_quick_aim = clampf(zoom_quick_aim, 1.2, zoom_max)
	zoom_step = float(profile.get("zoom_step", 0.15))
	camera_pan_speed = float(profile.get("camera_pan_speed", 300.0))
	edge_pan_speed_scale = float(profile.get("edge_pan_speed_scale", 1.0))
	hold_stabilize_sec = float(profile.get("hold_stabilize_sec", 1.0))
	aim_recover_sec = float(profile.get("aim_recover_sec", 0.35))
	spread_idle = float(profile.get("spread_idle", 34.0))
	spread_hold = float(profile.get("spread_hold", 10.0))
	hit_tolerance_radius = float(profile.get("hit_tolerance_radius", 26.0))
	time_extend_sec = float(profile.get("time_extend_sec", 15.0))
	scan_highlight_sec = float(profile.get("scan_highlight_sec", 3.0))
	cover_blast_tier = str(profile.get("cover_blast_tier", "medium"))


func calculate_spread(hold_ratio: float) -> float:
	return lerpf(spread_idle, spread_hold, hold_ratio)


func calculate_shot_offset(hold_ratio: float, current_zoom: float) -> Vector2:
	var current_spread: float = calculate_spread(hold_ratio)
	var offset_magnitude: float = _rng.randf_range(0.0, current_spread / maxf(current_zoom, 1.0))
	return Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * offset_magnitude


func get_zoom_range() -> Vector2:
	return Vector2(zoom_min, zoom_max)


func get_stability_factor(hold_ratio: float) -> float:
	return clampf(hold_ratio, 0.0, 1.0)


func can_fire_at_zoom(current_zoom: float) -> bool:
	return current_zoom >= 1.12


func get_profile() -> Dictionary:
	return {
		"weapon_id": weapon_id,
		"display_name": display_name,
		"zoom_default": zoom_default,
		"zoom_min": zoom_min,
		"zoom_max": zoom_max,
		"zoom_quick_aim": zoom_quick_aim,
		"zoom_step": zoom_step,
		"camera_pan_speed": camera_pan_speed,
		"edge_pan_speed_scale": edge_pan_speed_scale,
		"hold_stabilize_sec": hold_stabilize_sec,
		"aim_recover_sec": aim_recover_sec,
		"spread_idle": spread_idle,
		"spread_hold": spread_hold,
		"hit_tolerance_radius": hit_tolerance_radius,
		"time_extend_sec": time_extend_sec,
		"scan_highlight_sec": scan_highlight_sec,
		"recoil_duration": recoil_duration,
		"post_shot_recover_duration": post_shot_recover_duration,
		"cover_blast_tier": cover_blast_tier,
	}


func randomize() -> void:
	_rng.randomize()
