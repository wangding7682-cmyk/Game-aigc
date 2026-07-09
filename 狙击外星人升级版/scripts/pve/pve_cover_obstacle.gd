extends Node2D
class_name PveCoverObstacle

var size: Vector2 = Vector2(120.0, 180.0)
var base_color: Color = Color(0.20, 0.22, 0.26, 0.92)
var scan_fade_ratio := 0.0


func setup(rect_size: Vector2, color: Color = Color(0.20, 0.22, 0.26, 0.92)) -> void:
	size = rect_size
	base_color = color
	queue_redraw()


func set_scan_fade_ratio(ratio: float) -> void:
	scan_fade_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func get_world_rect() -> Rect2:
	return Rect2(global_position, size)


func _draw() -> void:
	var alpha := base_color.a
	if scan_fade_ratio > 0.0:
		alpha = lerpf(alpha, 0.28, scan_fade_ratio)

	draw_rect(Rect2(Vector2.ZERO, size), Color(base_color.r, base_color.g, base_color.b, alpha), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08, alpha * 0.75), false, 2.0)

