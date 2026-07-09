extends Resource
class_name SkinConfig

@export var skin_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var weapon_id: String = ""
@export var rarity: String = "common"
@export var price_gold: int = 0
@export var price_diamond: int = 0

@export var primary_color: Color = Color(0.7, 0.7, 0.7)
@export var secondary_color: Color = Color(0.3, 0.3, 0.3)
@export var accent_color: Color = Color(1.0, 1.0, 1.0)
@export var glow_color: Color = Color(0.0, 0.0, 0.0)

@export var barrel_length_scale: float = 1.0
@export var stock_width_scale: float = 1.0
@export var scope_size_scale: float = 1.0

@export var has_glow: bool = false
@export var glow_intensity: float = 0.0

@export var trail_effect_type: String = "default"
@export var trail_ring_count: int = 2
@export var trail_outer_radius: float = 0.12
@export var trail_glow_intensity: float = 1.0
@export var trail_color_0: Color = Color(1.0, 0.85, 0.45)
@export var trail_color_1: Color = Color(1.0, 0.65, 0.25)
@export var trail_color_2: Color = Color(1.0, 0.45, 0.65)
@export var trail_color_3: Color = Color(0.55, 0.75, 1.0)
@export var trail_color_4: Color = Color(0.65, 1.0, 0.75)
@export var trail_color_5: Color = Color(0.95, 0.55, 1.0)


func get_trail_colors() -> Array[Color]:
	var colors: Array[Color] = []
	colors.append(trail_color_0)
	colors.append(trail_color_1)
	if trail_effect_type == "rainbow":
		colors.append(trail_color_2)
		colors.append(trail_color_3)
		colors.append(trail_color_4)
		colors.append(trail_color_5)
	return colors


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
