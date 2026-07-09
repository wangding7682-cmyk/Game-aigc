extends Node2D
class_name PveTargetController

var actor_kind: String = "target"
var behavior_type: String = "static"
var body_radius: float = 18.0
var alive := true
var highlighted_until: float = 0.0
var weakpoint_open := true
var origin_position: Vector2 = Vector2.ZERO
var move_range: float = 90.0
var move_speed: float = 1.0
var reveal_cycle_sec: float = 2.2
var reveal_window_sec: float = 0.9
var phase_offset: float = 0.0
var tint: Color = Color(0.40, 0.44, 0.48)
var eyes_glow_color: Color = Color(0.95, 0.24, 0.28)
var tutorial_primary := false
var disguise_strength := 1.0
var hit_fx_timer := 0.0
var hit_fx_total := 0.24
var hit_fx_kind := "idle"
var fall_timer := 0.0
var fall_total := 0.34
var suspicion_tier := 0
var clue_profile: Array[String] = []
var search_signal_strength := 0.0
var pulse_phase_offset := 0.0
var locator_marked := false
var locator_mark_until := 0.0
var false_clue_profile: Array[String] = []
var false_clue_active := false
var false_clue_until := 0.0
var false_clue_cycle_sec := 0.0
var false_clue_window_sec := 0.0


func setup(kind: String, behavior: String, radius: float, spawn_position: Vector2, random_seed: float, extra: Dictionary = {}) -> void:
	actor_kind = kind
	behavior_type = behavior
	body_radius = radius
	origin_position = spawn_position
	global_position = spawn_position
	phase_offset = random_seed
	move_range = body_radius * 3.2
	tutorial_primary = bool(extra.get("tutorial_primary", false))
	disguise_strength = float(extra.get("disguise_strength", 1.0))
	suspicion_tier = int(extra.get("suspicion_tier", 0))
	clue_profile.clear()
	for clue in extra.get("clue_profile", []):
		clue_profile.append(str(clue))
	search_signal_strength = float(extra.get("search_signal_strength", 0.0))
	pulse_phase_offset = float(extra.get("pulse_phase_offset", random_seed))
	false_clue_profile.clear()
	for clue in extra.get("false_clue_profile", []):
		false_clue_profile.append(str(clue))
	false_clue_cycle_sec = float(extra.get("false_clue_cycle_sec", 0.0))
	false_clue_window_sec = float(extra.get("false_clue_window_sec", 0.0))

	if actor_kind == "civilian":
		tint = Color(0.28, 0.55, 0.85)
		move_speed = 0.55
		eyes_glow_color = Color(0.18, 0.25, 0.32)
	elif behavior_type == "moving":
		tint = Color(0.46, 0.50, 0.42)
		move_speed = 0.9
		eyes_glow_color = Color(0.98, 0.62, 0.18)
	elif behavior_type == "weakpoint":
		tint = Color(0.48, 0.43, 0.55)
		move_speed = 0.4
		eyes_glow_color = Color(0.98, 0.35, 0.18)
	else:
		tint = Color(0.42, 0.46, 0.44)
		eyes_glow_color = Color(0.92, 0.22, 0.28)

	tint = tint.lerp(Color(0.16, 0.18, 0.21), clampf(disguise_strength * 0.35, 0.0, 0.45))
	move_range = float(extra.get("move_range", move_range))
	move_speed = float(extra.get("move_speed", move_speed))
	reveal_cycle_sec = float(extra.get("reveal_cycle_sec", reveal_cycle_sec))
	reveal_window_sec = float(extra.get("reveal_window_sec", reveal_window_sec))
	if extra.has("tint"):
		tint = extra["tint"]
	if extra.has("eyes_glow_color"):
		eyes_glow_color = extra["eyes_glow_color"]

	if tutorial_primary:
		highlighted_until = Time.get_ticks_msec() / 1000.0 + 999.0
		locator_marked = true
		locator_mark_until = Time.get_ticks_msec() / 1000.0 + 999.0

	queue_redraw()


func _process(delta: float) -> void:
	hit_fx_timer = maxf(0.0, hit_fx_timer - delta)
	fall_timer = maxf(0.0, fall_timer - delta)

	if not alive:
		queue_redraw()
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var local_time: float = now + phase_offset
	locator_marked = locator_marked and now <= locator_mark_until
	if actor_kind == "civilian" and false_clue_cycle_sec > 0.0 and false_clue_window_sec > 0.0:
		false_clue_active = fmod(local_time, false_clue_cycle_sec) <= false_clue_window_sec
	else:
		false_clue_active = false_clue_active and now <= false_clue_until

	if behavior_type == "moving":
		global_position = origin_position + Vector2(sin(local_time * move_speed), cos(local_time * move_speed * 0.65) * 0.25) * Vector2(move_range, body_radius * 0.9)
	elif actor_kind == "civilian":
		global_position = origin_position + Vector2(sin(local_time * move_speed), 0.0) * Vector2(move_range * 0.55, 0.0)

	if behavior_type == "weakpoint":
		weakpoint_open = fmod(local_time, reveal_cycle_sec) <= reveal_window_sec

	queue_redraw()


func is_hittable() -> bool:
	if not alive:
		return false

	if actor_kind == "civilian":
		return true

	if behavior_type == "weakpoint":
		return weakpoint_open

	return true


func highlight_for(seconds: float) -> void:
	highlighted_until = maxf(highlighted_until, Time.get_ticks_msec() / 1000.0 + seconds)
	queue_redraw()


func is_highlighted() -> bool:
	return Time.get_ticks_msec() / 1000.0 <= highlighted_until


func set_tutorial_primary(enabled: bool) -> void:
	tutorial_primary = enabled
	if enabled:
		highlighted_until = maxf(highlighted_until, Time.get_ticks_msec() / 1000.0 + 999.0)
	queue_redraw()


func mark_locator_for(seconds: float) -> void:
	locator_marked = true
	locator_mark_until = maxf(locator_mark_until, Time.get_ticks_msec() / 1000.0 + seconds)
	queue_redraw()


func trigger_false_clue(seconds: float) -> void:
	false_clue_active = true
	false_clue_until = maxf(false_clue_until, Time.get_ticks_msec() / 1000.0 + seconds)
	queue_redraw()


func is_locator_marked() -> bool:
	return locator_marked or tutorial_primary


func has_false_clue_active() -> bool:
	return actor_kind == "civilian" and false_clue_active


func get_suspicion_summary() -> String:
	if actor_kind == "civilian":
		if has_false_clue_active() and not false_clue_profile.is_empty():
			return "假线索：%s，但呼吸和平肩仍然像普通市民。" % "、".join(false_clue_profile)
		return "呼吸平稳，眼睛与肩线都更像普通市民。"

	if clue_profile.is_empty():
		# 复盘口径：只要是任务目标，就统一使用“可疑点”前缀，便于测试与提示文案稳定匹配。
		return "可疑点：这个目标有轻微伪装破绽。"

	return "可疑点：%s" % "、".join(clue_profile)


func get_locator_weight() -> float:
	if actor_kind != "target" or not alive:
		return -1.0

	return float(suspicion_tier) + search_signal_strength


func get_identification_review() -> String:
	if actor_kind == "civilian":
		if has_false_clue_active() and not false_clue_profile.is_empty():
			return "被假线索误导：%s，但这个人呼吸平稳、肩线自然。" % "、".join(false_clue_profile)
		return "你忽略了这个人呼吸平稳、肩线自然的普通人特征。"

	return "这次识别准确，红眼脉冲和肩线异常都判断正确。"


func mark_hit(kind: String = "hit") -> void:
	alive = false
	hit_fx_kind = kind
	hit_fx_timer = hit_fx_total
	fall_timer = fall_total if kind == "hit" else fall_total * 0.6
	queue_redraw()


func get_impact_focus_point() -> Vector2:
	return global_position + Vector2(0.0, -body_radius * 0.72)


func _draw() -> void:
	if not alive:
		var dead_color := Color(1.0, 0.25, 0.25, 0.4)
		if hit_fx_kind == "wrong_hit":
			dead_color = Color(1.0, 0.38, 0.38, 0.55)
		elif hit_fx_kind == "hit":
			dead_color = Color(0.58, 1.0, 0.72, 0.42)

		var fall_ratio := 1.0 - (fall_timer / maxf(fall_total, 0.001))
		var body_shift := Vector2(lerpf(0.0, body_radius * 0.86, fall_ratio), lerpf(0.0, body_radius * 0.52, fall_ratio))
		draw_ellipse(
			body_shift,
			body_radius * lerpf(0.45, 0.82, fall_ratio),
			body_radius * lerpf(0.45, 0.28, fall_ratio),
			dead_color,
			true
		)
		draw_circle(body_shift + Vector2(body_radius * 0.32, -body_radius * 0.12), body_radius * 0.18, dead_color.lightened(0.12))

		if hit_fx_timer > 0.0:
			var ratio := hit_fx_timer / hit_fx_total
			var fx_color := Color(1.0, 0.84, 0.35, 0.9)
			if hit_fx_kind == "wrong_hit":
				fx_color = Color(1.0, 0.42, 0.42, 0.92)
			elif hit_fx_kind == "hit":
				fx_color = Color(0.56, 1.0, 0.68, 0.9)

			draw_arc(Vector2.ZERO, lerpf(body_radius * 1.45, body_radius * 0.66, 1.0 - ratio), 0.0, TAU, 24, fx_color * Color(1.0, 1.0, 1.0, ratio), 2.4)
			draw_circle(Vector2.ZERO, lerpf(body_radius * 0.9, body_radius * 0.36, 1.0 - ratio), fx_color * Color(1.0, 1.0, 1.0, ratio * 0.22))
		return

	var draw_color: Color = tint

	if actor_kind == "target" and is_highlighted():
		draw_color = Color(0.98, 0.87, 0.25)

	var pulse_time: float = Time.get_ticks_msec() / 1000.0 + pulse_phase_offset
	var pulse_ratio: float = (sin(pulse_time * 2.2) + 1.0) * 0.5
	var shoulder_offset: float = body_radius * (0.08 + float(suspicion_tier) * 0.02) if actor_kind == "target" else 0.0
	var false_clue_ratio: float = (sin(pulse_time * 4.5) + 1.0) * 0.5 if has_false_clue_active() else 0.0

	draw_circle(Vector2.ZERO, body_radius, draw_color)
	draw_circle(Vector2(0.0, -body_radius * 1.05), body_radius * 0.55, draw_color.lightened(0.12))
	if actor_kind == "target":
		draw_circle(Vector2(body_radius * 0.22, -body_radius * 0.18), body_radius * (0.16 + 0.04 * pulse_ratio), Color(1.0, 0.28, 0.28, 0.10 + 0.16 * pulse_ratio))
		draw_line(Vector2(-body_radius * 0.42, body_radius * 0.18), Vector2(body_radius * 0.44, body_radius * (0.18 + shoulder_offset)), Color(0.10, 0.12, 0.14, 0.24 + 0.18 * pulse_ratio), 2.0)
	elif has_false_clue_active():
		draw_circle(Vector2(body_radius * 0.18, -body_radius * 0.24), body_radius * (0.12 + 0.06 * false_clue_ratio), Color(1.0, 0.72, 0.42, 0.10 + 0.14 * false_clue_ratio))
		draw_arc(Vector2.ZERO, body_radius + 9.0 + false_clue_ratio * 3.0, 0.0, TAU, 24, Color(1.0, 0.84, 0.52, 0.14 + false_clue_ratio * 0.10), 1.4)

	var eyes_y := -body_radius * 1.1
	var eye_offset := body_radius * 0.22
	var eye_radius := maxf(body_radius * 0.13, 2.5)
	var eye_color := eyes_glow_color
	if actor_kind == "civilian":
		eye_color = eye_color.darkened(0.25)
		if has_false_clue_active():
			eye_color = eye_color.lerp(Color(1.0, 0.78, 0.42), 0.25 + false_clue_ratio * 0.28)
	elif actor_kind == "target":
		eye_color = eye_color.lightened(0.08 + pulse_ratio * 0.18)
	elif tutorial_primary:
		eye_color = eye_color.lightened(0.35)

	draw_circle(Vector2(-eye_offset, eyes_y), eye_radius, eye_color)
	draw_circle(Vector2(eye_offset, eyes_y), eye_radius, eye_color)

	if actor_kind == "target":
		var inner_color: Color = draw_color.darkened(0.15)
		draw_circle(Vector2.ZERO, body_radius * 0.38, inner_color)

		if behavior_type == "weakpoint":
			var weakpoint_color: Color = Color(0.96, 0.28, 0.28) if weakpoint_open else Color(0.20, 0.12, 0.12)
			draw_circle(Vector2.ZERO, body_radius * 0.22, weakpoint_color)

		if is_highlighted():
			draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 24, Color(1.0, 1.0, 0.4), 2.0)

		if tutorial_primary:
			draw_arc(Vector2.ZERO, body_radius + 14.0, 0.0, TAU, 28, Color(1.0, 0.36, 0.28, 0.85), 3.0)

		if is_locator_marked():
			draw_arc(Vector2.ZERO, body_radius + 18.0 + pulse_ratio * 4.0, 0.0, TAU, 28, Color(0.58, 0.96, 1.0, 0.35 + pulse_ratio * 0.25), 2.0)
