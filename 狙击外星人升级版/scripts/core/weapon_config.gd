extends Resource
class_name WeaponConfig

@export var weapon_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var rarity: String = "common"
@export var price_gold: int = 0
@export var price_diamond: int = 0
@export var is_default: bool = false

@export var zoom_default: float = 1.0
@export var zoom_min: float = 0.9
@export var zoom_max: float = 2.2
@export var zoom_quick_aim: float = 1.6
@export var zoom_step: float = 0.15

@export var camera_pan_speed: float = 300.0
@export var edge_pan_speed_scale: float = 1.0

@export var hold_stabilize_sec: float = 1.0
@export var aim_recover_sec: float = 0.35

@export var spread_idle: float = 34.0
@export var spread_hold: float = 10.0
@export var hit_tolerance_radius: float = 26.0

@export var time_extend_sec: float = 15.0
@export var scan_highlight_sec: float = 3.0

@export var recoil_duration: float = 0.18
@export var post_shot_recover_duration: float = 0.24
@export var cover_blast_tier: String = "medium"

@export var default_skin_id: String = ""

@export var geometry_type: String = "rifle"
@export var primary_color: Color = Color(0.7, 0.7, 0.7)
@export var secondary_color: Color = Color(0.3, 0.3, 0.3)


func get_rarity_color() -> Color:
	match rarity:
		"legendary":
			return Color(1.0, 0.84, 0.0)
		"epic":
			return Color(0.64, 0.16, 1.0)
		"rare":
			return Color(0.0, 0.64, 1.0)
		"uncommon":
			return Color(0.16, 0.8, 0.16)
		_:
			return Color(0.7, 0.7, 0.7)


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
