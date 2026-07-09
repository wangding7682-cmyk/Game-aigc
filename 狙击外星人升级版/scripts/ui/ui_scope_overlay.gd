extends Control

const HUD_SCOPE_FRAME := preload("res://assets_mvp_placeholder/ui/hud-scope-frame.svg")
const HUD_TARGET_LOCK_FRAME := preload("res://assets_mvp_placeholder/ui/hud-target-lock-frame.svg")
const FX_HIT_CONFIRM := preload("res://assets_mvp_placeholder/feedback/fx-hit-confirm.svg")
const FX_WRONG_HIT := preload("res://assets_mvp_placeholder/feedback/fx-wrong-hit-alert.svg")
const FX_COVER_IMPACT := preload("res://assets_mvp_placeholder/feedback/fx-cover-impact.svg")
const FX_SCAN_PULSE := preload("res://assets_mvp_placeholder/feedback/fx-scan-pulse.svg")
const HIT_CONFIRM_FRAMES := [
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-01.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-02.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-03.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-04.svg"),
	preload("res://assets_mvp_placeholder/feedback/hit-confirm-frame-05.svg"),
]
const WRONG_HIT_FRAMES := [
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-01.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-02.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-03.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-04.svg"),
	preload("res://assets_mvp_placeholder/feedback/wrong-hit-alert-frame-05.svg"),
]
const SCAN_PULSE_FRAMES := [
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-01.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-02.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-03.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-04.svg"),
	preload("res://assets_mvp_placeholder/feedback/scan-pulse-frame-05.svg"),
]

var scope_visible := false
var aim_screen_position := Vector2.ZERO
var hold_ratio := 0.0
var spread_radius_px := 28.0
var shot_flash_ratio := 0.0
var shot_result := "idle"
var slowmo_active := false
var muzzle_flash_ratio := 0.0
var scan_feedback_ratio := 0.0
var crosshair_style := "plus"
var crosshair_color := Color(1.0, 0.95, 0.82)
var hold_vignette_strength := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func update_state(state: Dictionary) -> void:
	scope_visible = bool(state.get("scope_visible", false))
	aim_screen_position = state.get("aim_screen_position", size * 0.5)
	hold_ratio = clampf(float(state.get("hold_ratio", 0.0)), 0.0, 1.0)
	spread_radius_px = maxf(float(state.get("spread_radius_px", 28.0)), 4.0)
	shot_flash_ratio = clampf(float(state.get("shot_flash_ratio", 0.0)), 0.0, 1.0)
	shot_result = str(state.get("shot_result", "idle"))
	slowmo_active = bool(state.get("slowmo_active", false))
	muzzle_flash_ratio = clampf(float(state.get("muzzle_flash_ratio", 0.0)), 0.0, 1.0)
	scan_feedback_ratio = clampf(float(state.get("scan_feedback_ratio", 0.0)), 0.0, 1.0)
	crosshair_style = str(state.get("crosshair_style", "plus"))
	crosshair_color = _resolve_crosshair_color(str(state.get("crosshair_color", "amber")))
	hold_vignette_strength = clampf(float(state.get("hold_vignette_strength", 1.0)), 0.4, 1.6)
	queue_redraw()


func _draw() -> void:
	if not scope_visible:
		return

	var center: Vector2 = aim_screen_position
	var radius: float = minf(size.x, size.y) * 0.28
	var dark_color := Color(0.0, 0.0, 0.0, 0.95)
	var inner_color := Color(0.0, 0.0, 0.0, 0.0)
	var ring_color := Color(0.82, 0.88, 0.96, 0.9)
	var cross_color := crosshair_color * Color(1.0, 1.0, 1.0, 0.82)
	var spread_color := Color(1.0, 0.93, 0.78, 0.86)

	match shot_result:
		"hit":
			ring_color = ring_color.lerp(Color(0.48, 1.0, 0.62), shot_flash_ratio * 0.65)
			cross_color = cross_color.lerp(Color(0.48, 1.0, 0.62), shot_flash_ratio * 0.8)
		"wrong_hit":
			ring_color = ring_color.lerp(Color(1.0, 0.38, 0.38), shot_flash_ratio * 0.75)
			cross_color = cross_color.lerp(Color(1.0, 0.38, 0.38), shot_flash_ratio * 0.85)
		"miss":
			ring_color = ring_color.lerp(Color(1.0, 0.78, 0.38), shot_flash_ratio * 0.55)
		"cover":
			ring_color = ring_color.lerp(Color(0.62, 0.86, 1.0), shot_flash_ratio * 0.65)
			cross_color = cross_color.lerp(Color(0.62, 0.86, 1.0), shot_flash_ratio * 0.7)

	var l: float = center.x - radius
	var r: float = center.x + radius
	var t: float = center.y - radius
	var b: float = center.y + radius
	var sx: float = size.x
	var sy: float = size.y

	draw_rect(Rect2(0, 0, sx, maxf(t, 0)), dark_color, true)
	draw_rect(Rect2(0, b, sx, maxf(sy - b, 0)), dark_color, true)
	draw_rect(Rect2(0, maxf(t, 0), maxf(l, 0), minf(b, sy) - maxf(t, 0)), dark_color, true)
	draw_rect(Rect2(r, maxf(t, 0), maxf(sx - r, 0), minf(b, sy) - maxf(t, 0)), dark_color, true)

	var arc_steps := 16
	var corner_polys := [
		[_corner_arc_points(center, radius, PI, PI * 1.5, arc_steps), Vector2(l, t)],
		[_corner_arc_points(center, radius, PI * 1.5, TAU, arc_steps), Vector2(r, t)],
		[_corner_arc_points(center, radius, 0, PI * 0.5, arc_steps), Vector2(r, b)],
		[_corner_arc_points(center, radius, PI * 0.5, PI, arc_steps), Vector2(l, b)],
	]
	for cp in corner_polys:
		var pts: Array = cp[0]
		var corner: Vector2 = cp[1]
		var poly := PackedVector2Array()
		poly.append(corner)
		for p in pts:
			poly.append(p)
		if poly.size() >= 3:
			draw_colored_polygon(poly, dark_color)

	draw_circle(center, radius * 1.06, Color(0.0, 0.0, 0.0, 0.1))
	draw_circle(center, radius, inner_color)

	var vignette_base_alpha := 0.04 * hold_vignette_strength
	var vignette_rings := 4
	for i in range(vignette_rings):
		var vt: float = float(i) / float(vignette_rings)
		var vr: float = radius * (0.98 - vt * 0.25)
		var valpha: float = vignette_base_alpha * (1.0 - vt * 0.8)
		var thickness: float = radius * 0.08
		draw_arc(center, vr, 0.0, TAU, 48, Color(0.0, 0.0, 0.0, valpha), thickness)

	if HUD_SCOPE_FRAME != null:
		var scope_rect := Rect2(center - Vector2(radius * 1.2, radius * 1.2), Vector2(radius * 2.4, radius * 2.4))
		draw_texture_rect(HUD_SCOPE_FRAME, scope_rect, false, Color(1.0, 1.0, 1.0, 0.48))
	draw_arc(center, radius, 0.0, TAU, 64, ring_color, 3.0)
	draw_arc(center, radius * 0.985, 0.0, TAU, 64, Color(0.02, 0.02, 0.03, 0.65), 1.0)
	draw_arc(center, radius * 0.92, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.06), 1.0)
	if slowmo_active:
		draw_arc(center, radius * 0.78, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.22), 1.2)

	var crosshair_pos: Vector2 = center
	_draw_crosshair(crosshair_pos, radius, cross_color)

	var spread: float = minf(spread_radius_px, radius * 0.68)
	draw_arc(crosshair_pos, spread, 0.0, TAU, 48, spread_color, 1.5)
	draw_arc(crosshair_pos, maxf(spread * 0.66, 4.0), 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.25 + hold_ratio * 0.25), 1.0)
	if HUD_TARGET_LOCK_FRAME != null:
		var lock_size := Vector2(radius * 0.74, radius * 0.74)
		draw_texture_rect(HUD_TARGET_LOCK_FRAME, Rect2(crosshair_pos - lock_size * 0.5, lock_size), false, Color(1.0, 1.0, 1.0, 0.66))
	if muzzle_flash_ratio > 0.0:
		draw_circle(center, radius * 0.96, Color(1.0, 0.95, 0.82, muzzle_flash_ratio * 0.08))
	if scan_feedback_ratio > 0.01:
		var scan_texture := _resolve_sequence_frame(SCAN_PULSE_FRAMES, scan_feedback_ratio)
		var scan_size := Vector2(radius * 1.34, radius * 1.34)
		if scan_texture != null:
			draw_texture_rect(scan_texture, Rect2(center - scan_size * 0.5, scan_size), false, Color(0.86, 0.96, 1.0, clampf(1.0 - scan_feedback_ratio * 0.12, 0.0, 0.92)))

	var center_mark: float = 3.5 if hold_ratio >= 0.55 else 2.5
	draw_circle(crosshair_pos, center_mark, crosshair_color * Color(1.0, 1.0, 1.0, 0.92))

	if shot_flash_ratio > 0.1:
		var hit_flash_color: Color = Color.WHITE
		var feedback_texture: Texture2D = null
		match shot_result:
			"hit":
				hit_flash_color = Color(0.48, 1.0, 0.62, shot_flash_ratio * 0.35)
				feedback_texture = _resolve_sequence_frame(HIT_CONFIRM_FRAMES, shot_flash_ratio)
				if feedback_texture == null:
					feedback_texture = FX_HIT_CONFIRM
			"wrong_hit":
				hit_flash_color = Color(1.0, 0.38, 0.38, shot_flash_ratio * 0.4)
				feedback_texture = _resolve_sequence_frame(WRONG_HIT_FRAMES, shot_flash_ratio)
				if feedback_texture == null:
					feedback_texture = FX_WRONG_HIT
			"cover":
				hit_flash_color = Color(0.62, 0.86, 1.0, shot_flash_ratio * 0.3)
				feedback_texture = FX_COVER_IMPACT
			"miss":
				hit_flash_color = Color(1.0, 0.85, 0.5, shot_flash_ratio * 0.2)
				feedback_texture = FX_SCAN_PULSE
		draw_circle(crosshair_pos, radius * 0.5, hit_flash_color)
		if feedback_texture != null:
			var feedback_size := Vector2(radius * 0.66, radius * 0.66)
			draw_texture_rect(feedback_texture, Rect2(crosshair_pos - feedback_size * 0.5, feedback_size), false, Color(1.0, 1.0, 1.0, clampf(shot_flash_ratio, 0.0, 0.95)))


func _corner_arc_points(c: Vector2, rad: float, angle_from: float, angle_to: float, steps: int) -> Array:
	var pts: Array = []
	for i in range(steps + 1):
		var a: float = lerpf(angle_from, angle_to, float(i) / float(steps))
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	return pts


func _draw_crosshair(center: Vector2, radius: float, color: Color) -> void:
	var cross_extent: float = radius * 0.92
	match crosshair_style:
		"dot":
			return
		"circle":
			draw_arc(center, 14.0, 0.0, TAU, 48, color, 1.6)
		"x":
			draw_line(center + Vector2(-cross_extent, -cross_extent), center + Vector2(-18.0, -18.0), color, 1.6)
			draw_line(center + Vector2(18.0, 18.0), center + Vector2(cross_extent, cross_extent), color, 1.6)
			draw_line(center + Vector2(-cross_extent, cross_extent), center + Vector2(-18.0, 18.0), color, 1.6)
			draw_line(center + Vector2(18.0, -18.0), center + Vector2(cross_extent, -cross_extent), color, 1.6)
		"cross":
			draw_line(center + Vector2(-cross_extent, 0.0), center + Vector2(-16.0, 0.0), color, 1.6)
			draw_line(center + Vector2(16.0, 0.0), center + Vector2(cross_extent, 0.0), color, 1.6)
			draw_line(center + Vector2(0.0, -cross_extent), center + Vector2(0.0, -16.0), color, 1.6)
			draw_line(center + Vector2(0.0, 16.0), center + Vector2(0.0, cross_extent), color, 1.6)
		_:
			draw_line(center + Vector2(-cross_extent, 0.0), center + Vector2(-16.0, 0.0), color, 1.6)
			draw_line(center + Vector2(16.0, 0.0), center + Vector2(cross_extent, 0.0), color, 1.6)
			draw_line(center + Vector2(0.0, -cross_extent), center + Vector2(0.0, -16.0), color, 1.6)
			draw_line(center + Vector2(0.0, 16.0), center + Vector2(0.0, cross_extent), color, 1.6)


func _resolve_crosshair_color(color_id: String) -> Color:
	match color_id:
		"white":
			return Color(1.0, 1.0, 1.0)
		"green":
			return Color(0.52, 1.0, 0.66)
		"red":
			return Color(1.0, 0.38, 0.38)
		"cyan":
			return Color(0.58, 0.92, 1.0)
		_:
			return Color(1.0, 0.95, 0.82)


func _resolve_sequence_frame(frames: Array, ratio: float) -> Texture2D:
	if frames.is_empty():
		return null
	var normalized := clampf(ratio, 0.0, 0.9999)
	var index := clampi(int(floor(normalized * float(frames.size()))), 0, frames.size() - 1)
	var texture: Variant = frames[index]
	return texture if texture is Texture2D else null
