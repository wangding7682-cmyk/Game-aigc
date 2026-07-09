extends Resource
class_name PveSpawnEntry

@export_enum("target", "civilian") var actor_kind: String = "target"
@export_enum("static", "moving", "weakpoint") var behavior_type: String = "static"
@export var position: Vector2 = Vector2.ZERO
@export var tutorial_primary := false
@export_range(0.0, 1.0, 0.01) var disguise_strength: float = 0.8

# 搜索提示 / 识别强度（默认 -1 / 空数组 表示交给战斗脚本生成默认值）
@export_range(-1, 3, 1) var suspicion_tier: int = -1
@export var clue_profile: PackedStringArray = PackedStringArray()
@export_range(-1.0, 1.0, 0.01) var search_signal_strength: float = -1.0

# 假线索（一般只给 civilian 使用）
@export var false_clue_profile: PackedStringArray = PackedStringArray()
@export var false_clue_cycle_sec: float = -1.0
@export var false_clue_window_sec: float = -1.0

# 下面 4 个参数默认用负数表示“沿用目标脚本默认值”，避免配置条目过多时必须全填。
@export var move_range: float = -1.0
@export var move_speed: float = -1.0
@export var reveal_cycle_sec: float = -1.0
@export var reveal_window_sec: float = -1.0
