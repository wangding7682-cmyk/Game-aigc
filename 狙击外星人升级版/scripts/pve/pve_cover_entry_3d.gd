extends Resource
class_name PveCoverEntry3D

@export var position: Vector3 = Vector3.ZERO
@export_enum("wall_corner", "street_lamp", "parked_van", "billboard", "hedge_cover") var style_id: String = "wall_corner"
@export var rotation_deg_y: float = 0.0
