extends Resource
class_name PveLevelConfig

@export var level_id: int = 1
@export var display_name: String = "城市试炼 01"
@export var flavor_text: String = "先打通一条完整主流程。"
@export var time_limit_sec: float = 75.0
@export var required_targets: int = 3
@export var civilian_count: int = 2
@export var reward_gold: int = 60
@export var scan_count: int = 1
@export var time_extend_count: int = 1
@export var moving_targets: int = 0
@export var weakpoint_targets: int = 0
@export var world_size: Vector2 = Vector2(1600.0, 900.0)
@export var target_radius: float = 22.0
@export var civilian_radius: float = 18.0
@export var spawn_entries: Array[Resource] = []
@export var cover_entries_2d: Array[Resource] = []
@export var cover_entries_3d: Array[Resource] = []
@export var cover_budget_2d: int = -1
@export var cover_budget_3d: int = -1
@export var cover_style_pool_3d: PackedStringArray = PackedStringArray(["wall_corner", "street_lamp", "parked_van", "billboard"])
@export var runtime_greenery_cover_budget: int = -1
