extends Node

signal battle_finished(result: Dictionary)
signal shot_fired(result: String, actor, hit_point: Vector2, reward: int)
signal target_hit(actor, hit_point: Vector2, reward: int)
@warning_ignore("unused_signal")
signal target_damaged(actor, hit_point: Vector2, remaining_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal ineffective_hit(actor, hit_point: Vector2)
signal wrong_hit(actor, hit_point: Vector2)
signal target_missed(hit_point: Vector2)
signal shot_blocked(actor, hit_point: Vector2)
signal scan_used(remaining: int)
signal time_extend_used(remaining: int, added_time: float)
signal state_changed()
signal victory_imminent(partial_result: Dictionary)
signal victory_pending(final_result: Dictionary)

var level_config = null
var weapon = null
var camera_controller = null

var remaining_time: float = 0.0
var elapsed_time: float = 0.0
var lives: int = 3
var killed_targets: int = 0
var total_targets: int = 0
var shot_count: int = 0
var hit_count: int = 0
var wrong_hit_count: int = 0
var tactical_shot_count: int = 0
var no_miss_rounds: int = 0
var scan_count: int = 0
var time_extend_count: int = 0

var hold_ratio: float = 0.0
var weapon_ready: bool = true
var battle_closed: bool = false

var active_actors: Array = []
var tutorial_primary_target = null

var recognition_bonus_gold: int = 0
var pending_victory_reason: String = ""
var recognition_success_count: int = 0
var wrong_identification_time_penalty: float = 0.0
var wrong_identification_count: int = 0
var recognition_combo_count: int = 0
var recognition_combo_bonus_gold: int = 0

var first_hit_elapsed_sec: float = -1.0
var checkpoint_logged: Dictionary = {
	"first_kill": false,
	"midgame": false,
	"endgame": false,
}

var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func setup(level_cfg, weapon_obj, camera_ctrl) -> void:
	level_config = level_cfg
	weapon = weapon_obj
	camera_controller = camera_ctrl
	
	_reset_battle_stats()
	remaining_time = level_config.time_limit_sec
	scan_count = level_config.scan_count
	time_extend_count = level_config.time_extend_count
	total_targets = level_config.required_targets
	
	active_actors.clear()
	tutorial_primary_target = null
	
	battle_closed = false
	weapon_ready = true


func _reset_battle_stats() -> void:
	elapsed_time = 0.0
	lives = 3
	killed_targets = 0
	shot_count = 0
	hit_count = 0
	wrong_hit_count = 0
	tactical_shot_count = 0
	no_miss_rounds = 0
	hold_ratio = 0.0
	recognition_bonus_gold = 0
	recognition_success_count = 0
	wrong_identification_time_penalty = 0.0
	wrong_identification_count = 0
	recognition_combo_count = 0
	recognition_combo_bonus_gold = 0
	first_hit_elapsed_sec = -1.0
	checkpoint_logged = {
		"first_kill": false,
		"midgame": false,
		"endgame": false,
	}


func spawn_actors() -> void:
	var target_behaviors: Array[String] = []
	var tutorial_layout_active: bool = level_config.level_id == 1 and CoreGameState.is_tutorial_active()
	var spawn_plan: Array[Dictionary] = []

	for _i in range(level_config.moving_targets):
		target_behaviors.append("moving")

	for _i in range(level_config.weakpoint_targets):
		target_behaviors.append("weakpoint")

	while target_behaviors.size() < level_config.required_targets:
		target_behaviors.append("static")

	if not tutorial_layout_active:
		target_behaviors.shuffle()
		spawn_plan = _build_level_spawn_plan_from_config()
		if spawn_plan.is_empty():
			spawn_plan = _build_level_spawn_plan()

	var target_positions: Array[Vector2] = _generate_positions(level_config.required_targets + level_config.civilian_count)
	if tutorial_layout_active:
		target_positions = [
			Vector2(240.0, -120.0),
			Vector2(-260.0, 110.0),
			Vector2(420.0, 165.0),
			Vector2(-380.0, -180.0),
			Vector2(80.0, 280.0),
			Vector2(-60.0, -70.0),
			Vector2(120.0, 250.0),
			Vector2(440.0, -50.0),
		]
	elif not spawn_plan.is_empty():
		target_positions.clear()
		for entry in spawn_plan:
			target_positions.append(entry.get("position", Vector2.ZERO))

	for index in range(level_config.required_targets):
		var actor = PveTargetController.new()
		var is_tutorial_primary: bool = tutorial_layout_active and index == 0
		var target_behavior: String = target_behaviors[index]
		var target_extra: Dictionary = {
			"tutorial_primary": is_tutorial_primary,
			"disguise_strength": 0.55 if is_tutorial_primary else 1.0,
		}
		if not tutorial_layout_active and not spawn_plan.is_empty():
			var plan_entry: Dictionary = spawn_plan[index]
			target_behavior = str(plan_entry.get("behavior", target_behavior))
			target_extra = plan_entry.get("extra", {}).duplicate(true)
			target_extra["tutorial_primary"] = false
		target_extra.merge(_build_actor_search_profile("target", target_behavior, is_tutorial_primary, index, float(target_extra.get("disguise_strength", 1.0))), false)
		actor.setup(
			"target",
			target_behavior,
			level_config.target_radius,
			target_positions[index],
			_rng.randf_range(0.0, 100.0),
			target_extra
		)
		active_actors.append(actor)
		if is_tutorial_primary:
			tutorial_primary_target = actor

	for offset in range(level_config.civilian_count):
		var actor = PveTargetController.new()
		var civilian_extra: Dictionary = {
			"disguise_strength": 0.8,
		}
		if not tutorial_layout_active and not spawn_plan.is_empty():
			civilian_extra = spawn_plan[level_config.required_targets + offset].get("extra", {}).duplicate(true)
		civilian_extra.merge(_build_actor_search_profile("civilian", "static", false, offset, float(civilian_extra.get("disguise_strength", 0.8))), false)
		actor.setup(
			"civilian",
			"static",
			level_config.civilian_radius,
			target_positions[level_config.required_targets + offset],
			_rng.randf_range(0.0, 100.0),
			civilian_extra
		)
		active_actors.append(actor)


func record_tactical_shot(shot_point: Vector2) -> void:
	tactical_shot_count += 1
	state_changed.emit()


func shoot(aim_world_point: Vector2) -> Dictionary:
	if not weapon_ready:
		return {"result": "not_ready"}

	if not weapon.can_fire_at_zoom(camera_controller.current_zoom):
		return {"result": "not_zoomed"}

	shot_count += 1
	var shot_offset: Vector2 = weapon.calculate_shot_offset(hold_ratio, camera_controller.current_zoom)
	var hit_point: Vector2 = aim_world_point + shot_offset

	var best_actor = null
	var best_distance: float = INF

	for actor in active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue

		var allowed_distance: float = actor.body_radius + weapon.hit_tolerance_radius
		var distance: float = actor.global_position.distance_to(hit_point)

		if distance <= allowed_distance and distance < best_distance:
			best_actor = actor
			best_distance = distance

	if best_actor == null:
		no_miss_rounds = 0
		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "miss",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
		})
		target_missed.emit(hit_point)
		shot_fired.emit("miss", null, hit_point, 0)
		state_changed.emit()
		return {"result": "miss", "hit_point": hit_point}

	return _apply_actor_hit(best_actor, hit_point)


func use_scan() -> bool:
	if not CoreGameState.is_tutorial_active() and scan_count <= 0:
		return false

	if not CoreGameState.is_tutorial_active():
		scan_count -= 1
	CoreEventBus.log_event("item_used", {
		"level_id": level_config.level_id,
		"item_id": "scan",
		"remaining_count": scan_count,
		"elapsed_time": elapsed_time,
	})

	for actor in active_actors:
		if is_instance_valid(actor) and actor.actor_kind == "target" and actor.alive:
			actor.highlight_for(weapon.scan_highlight_sec)

	scan_used.emit(scan_count)
	state_changed.emit()
	return true


func use_time_extend() -> bool:
	if not CoreGameState.is_tutorial_active() and time_extend_count <= 0:
		return false

	if not CoreGameState.is_tutorial_active():
		time_extend_count -= 1
	remaining_time += weapon.time_extend_sec
	CoreEventBus.log_event("item_used", {
		"level_id": level_config.level_id,
		"item_id": "time_extend",
		"remaining_count": time_extend_count,
		"remaining_time": remaining_time,
		"elapsed_time": elapsed_time,
	})
	time_extend_used.emit(time_extend_count, weapon.time_extend_sec)
	state_changed.emit()
	return true


func update(delta: float) -> void:
	if battle_closed:
		return

	elapsed_time += delta
	remaining_time = max(0.0, remaining_time - delta)

	if remaining_time <= 0.0:
		finish_battle(false, "时间耗尽")


func finish_battle(success: bool, reason: String) -> void:
	if battle_closed:
		return

	battle_closed = true
	var accuracy: float = clampf(float(hit_count) / float(max(1, shot_count)), 0.0, 1.0)
	var attack_shot_count: int = max(1, shot_count - tactical_shot_count)
	var effective_accuracy: float = clampf(float(hit_count) / float(attack_shot_count), 0.0, 1.0)
	var base_reward_gold := int(level_config.reward_gold * 0.25)
	var time_bonus_gold := 0
	var wrong_hit_penalty_gold := wrong_hit_count * 8
	var identification_bonus_gold := recognition_bonus_gold

	if success:
		base_reward_gold = level_config.reward_gold
		# 对齐规范：time_bonus = floor(survive_time_sec * (1.0 + miss_count * -0.15))
		# 保底不低于基础通关奖励的 30%
		var miss_penalty_ratio := 1.0 + float(wrong_hit_count) * -0.15
		time_bonus_gold = maxi(int(elapsed_time * miss_penalty_ratio), int(float(base_reward_gold) * 0.3))

	var reward: int = maxi(base_reward_gold + time_bonus_gold + identification_bonus_gold - wrong_hit_penalty_gold, 0)

	var result: Dictionary = {
		"success": success,
		"reason": reason,
		"reward_gold": reward,
		"base_reward_gold": base_reward_gold,
		"time_bonus_gold": time_bonus_gold,
		"bonus_reward_gold": identification_bonus_gold,
		"wrong_hit_penalty_gold": wrong_hit_penalty_gold,
		"accuracy": accuracy,
		"effective_accuracy": effective_accuracy,
		"shot_count": shot_count,
		"hit_count": hit_count,
		"wrong_hit_count": wrong_hit_count,
		"tactical_shot_count": tactical_shot_count,
		"attack_shot_count": attack_shot_count,
		"recognition_success_count": recognition_success_count,
		"wrong_identification_count": wrong_identification_count,
		"wrong_identification_time_penalty": wrong_identification_time_penalty,
		"scan_used": level_config.scan_count - scan_count,
		"time_extend_used": level_config.time_extend_count - time_extend_count,
		"elapsed_time": elapsed_time,
		"first_hit_elapsed_sec": first_hit_elapsed_sec,
		"no_miss_rounds": no_miss_rounds,
		"level_id": level_config.level_id,
		"level_name": level_config.display_name,
		"can_go_next": success and level_config.level_id < CoreGameState.LEVEL_PATHS.size(),
		"next_level_id": min(level_config.level_id + 1, CoreGameState.LEVEL_PATHS.size()),
	}

	battle_finished.emit(result)

	CoreEventBus.log_event("battle_finished", {
		"success": success,
		"level_id": level_config.level_id,
		"level_name": level_config.display_name,
		"reason": reason,
		"reward_gold": reward,
		"shot_count": shot_count,
		"hit_count": hit_count,
		"wrong_hit_count": wrong_hit_count,
		"tactical_shot_count": tactical_shot_count,
		"accuracy": accuracy,
		"effective_accuracy": effective_accuracy,
		"scan_used": level_config.scan_count - scan_count,
		"time_extend_used": level_config.time_extend_count - time_extend_count,
		"elapsed_time": elapsed_time,
		"first_hit_elapsed_sec": first_hit_elapsed_sec,
		"recognition_success_count": recognition_success_count,
		"wrong_identification_count": wrong_identification_count,
	})

	if level_config.level_id == 1:
		CoreEventBus.log_event("level_1_%s" % ("completed" if success else "failed"), {
			"elapsed_time": elapsed_time,
			"accuracy": accuracy,
			"wrong_hit_count": wrong_hit_count,
		})


func confirm_victory() -> void:
	if pending_victory_reason.is_empty():
		return
	finish_battle(true, pending_victory_reason)
	pending_victory_reason = ""


func _apply_actor_hit(actor, hit_point: Vector2) -> Dictionary:
	if not actor.is_hittable():
		no_miss_rounds = 0
		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "blocked",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
		})
		shot_blocked.emit(actor, hit_point)
		shot_fired.emit("blocked", actor, hit_point, 0)
		state_changed.emit()
		return {"result": "blocked", "actor": actor, "hit_point": hit_point}

	actor.mark_hit("wrong_hit" if actor.actor_kind == "civilian" else "hit")
	if actor == tutorial_primary_target:
		actor.set_tutorial_primary(false)

	if actor.actor_kind == "civilian":
		wrong_hit_count += 1
		wrong_identification_count += 1
		recognition_combo_count = 0
		lives -= 1
		no_miss_rounds = 0
		_apply_wrong_identification_penalty()

		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "wrong_hit",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
			"elapsed_time": elapsed_time,
		})

		wrong_hit.emit(actor, hit_point)
		shot_fired.emit("wrong_hit", actor, hit_point, 0)
		state_changed.emit()

		if lives <= 0:
			finish_battle(false, "误伤次数达到上限")

		return {"result": "wrong_hit", "actor": actor, "hit_point": hit_point}
	else:
		hit_count += 1
		killed_targets += 1
		no_miss_rounds += 1
		recognition_success_count += 1
		recognition_combo_count += 1

		var recognition_reward: int = _apply_recognition_reward(actor)
		_record_first_hit_if_needed()
		_record_level_checkpoints_after_kill()

		CoreEventBus.log_event("shot_fired", {
			"level_id": level_config.level_id,
			"result": "hit",
			"shot_count": shot_count,
			"hit_count": hit_count,
			"wrong_hit_count": wrong_hit_count,
			"elapsed_time": elapsed_time,
		})

		target_hit.emit(actor, hit_point, recognition_reward)
		shot_fired.emit("hit", actor, hit_point, recognition_reward)
		state_changed.emit()

		var remaining_targets: int = maxi(total_targets - killed_targets, 0)
		if remaining_targets == 1 and total_targets >= 2:
			var snapshot: Dictionary = _build_battle_snapshot("imminent")
			victory_imminent.emit(snapshot)

		if killed_targets >= total_targets:
			pending_victory_reason = "全部目标已完成清除"
			var final_snapshot: Dictionary = _build_battle_snapshot("pending")
			victory_pending.emit(final_snapshot)

		return {"result": "hit", "actor": actor, "hit_point": hit_point, "reward": recognition_reward}


func _build_battle_snapshot(phase: String = "pending") -> Dictionary:
	var accuracy: float = clampf(float(hit_count) / float(max(1, shot_count)), 0.0, 1.0)
	var attack_shot_count: int = max(1, shot_count - tactical_shot_count)
	var effective_accuracy: float = clampf(float(hit_count) / float(attack_shot_count), 0.0, 1.0)
	var scan_used_val: int = int(level_config.scan_count) - scan_count
	var time_extend_used_val: int = int(level_config.time_extend_count) - time_extend_count
	var is_success: bool = phase == "pending" or phase == "final"
	return {
		"success": is_success,
		"reason": pending_victory_reason if not pending_victory_reason.is_empty() else "战斗进行中",
		"reward_gold": 0,
		"base_reward_gold": 0,
		"time_bonus_gold": 0,
		"bonus_reward_gold": recognition_bonus_gold,
		"wrong_hit_penalty_gold": wrong_hit_count * 8,
		"accuracy": accuracy,
		"effective_accuracy": effective_accuracy,
		"shot_count": shot_count,
		"hit_count": hit_count,
		"wrong_hit_count": wrong_hit_count,
		"tactical_shot_count": tactical_shot_count,
		"attack_shot_count": attack_shot_count,
		"recognition_success_count": recognition_success_count,
		"wrong_identification_count": wrong_identification_count,
		"wrong_identification_time_penalty": wrong_identification_time_penalty,
		"scan_used": scan_used_val,
		"time_extend_used": time_extend_used_val,
		"elapsed_time": elapsed_time,
		"first_hit_elapsed_sec": first_hit_elapsed_sec,
		"no_miss_rounds": no_miss_rounds,
		"level_id": level_config.level_id,
		"level_name": level_config.display_name,
		"can_go_next": is_success and level_config.level_id < CoreGameState.LEVEL_PATHS.size(),
		"next_level_id": min(level_config.level_id + 1, CoreGameState.LEVEL_PATHS.size()),
		"_preview_phase": phase,
		"_remaining_targets": maxi(total_targets - killed_targets, 0),
		"_total_targets": total_targets,
	}


func _apply_recognition_reward(actor) -> int:
	var suspicion_bonus: int = maxi(int(actor.suspicion_tier), 1)
	var combo_bonus: int = maxi(recognition_combo_count - 1, 0) * 3
	var reward_gold: int = 6 + suspicion_bonus * 4 + combo_bonus
	recognition_bonus_gold += reward_gold
	recognition_combo_bonus_gold += combo_bonus
	remaining_time += 2.0
	return reward_gold


func _apply_wrong_identification_penalty() -> void:
	var penalty_time := 8.0
	remaining_time = maxf(0.0, remaining_time - penalty_time)
	wrong_identification_time_penalty += penalty_time
	recognition_combo_bonus_gold = 0
	scan_count = 0


func _record_first_hit_if_needed() -> void:
	if first_hit_elapsed_sec >= 0.0:
		return

	first_hit_elapsed_sec = elapsed_time
	CoreEventBus.log_event("first_hit_recorded", {
		"level_id": level_config.level_id,
		"first_hit_elapsed_sec": first_hit_elapsed_sec,
		"shot_count": shot_count,
		"wrong_hit_count": wrong_hit_count,
	})


func _record_level_checkpoints_after_kill() -> void:
	if killed_targets >= 1 and not bool(checkpoint_logged.get("first_kill", false)):
		_record_level_checkpoint("first_kill")

	var midgame_threshold := int(ceil(float(total_targets) * 0.5))
	if killed_targets >= midgame_threshold and not bool(checkpoint_logged.get("midgame", false)):
		_record_level_checkpoint("midgame")

	var endgame_remaining_threshold := 2 if total_targets >= 5 else 1
	var remaining_targets := maxi(total_targets - killed_targets, 0)
	if remaining_targets <= endgame_remaining_threshold and not bool(checkpoint_logged.get("endgame", false)):
		_record_level_checkpoint("endgame")


func _record_level_checkpoint(checkpoint_id: String) -> void:
	checkpoint_logged[checkpoint_id] = true
	CoreEventBus.log_event("level_checkpoint", {
		"level_id": level_config.level_id,
		"checkpoint_id": checkpoint_id,
		"killed_targets": killed_targets,
		"total_targets": total_targets,
		"remaining_targets": maxi(total_targets - killed_targets, 0),
		"elapsed_time": elapsed_time,
		"remaining_time": remaining_time,
		"wrong_hit_count": wrong_hit_count,
		"scan_used": level_config.scan_count - scan_count,
		"time_extend_used": level_config.time_extend_count - time_extend_count,
	})


func _build_actor_search_profile(kind: String, behavior: String, is_tutorial_primary: bool, slot_index: int, disguise: float) -> Dictionary:
	if kind == "civilian":
		return {
			"suspicion_tier": 0,
			"clue_profile": ["呼吸平稳", "肩线自然"],
			"search_signal_strength": 0.0,
			"eyes_glow_color": Color(0.18, 0.25, 0.32),
			"false_clue_profile": ["玻璃反光像红眼", "衣领短暂闪动"],
			"false_clue_cycle_sec": 3.6 + float(slot_index) * 0.25,
			"false_clue_window_sec": 0.55,
		}

	if is_tutorial_primary:
		return {
			"suspicion_tier": 3,
			"clue_profile": ["红眼脉冲", "肩线不自然", "胸口微弱闪动"],
			"search_signal_strength": 1.0,
			"eyes_glow_color": Color(1.0, 0.26, 0.26),
			"disguise_strength": minf(disguise, 0.48),
		}

	match behavior:
		"moving":
			return {
				"suspicion_tier": 2,
				"clue_profile": ["移动节奏异常", "眼白偏红"],
				"search_signal_strength": 0.72 + float(slot_index) * 0.04,
				"eyes_glow_color": Color(1.0, 0.52, 0.18),
			}
		"weakpoint":
			return {
				"suspicion_tier": 2,
				"clue_profile": ["胸口周期性鼓动", "目光发亮"],
				"search_signal_strength": 0.86,
				"eyes_glow_color": Color(1.0, 0.34, 0.16),
			}
		_:
			return {
				"suspicion_tier": 1,
				"clue_profile": ["红眼反光", "肩线略歪"],
				"search_signal_strength": 0.52 + float(slot_index) * 0.05,
			}


func _generate_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var tries: int = 0
	var world_limits: Rect2 = camera_controller.world_limits
	var min_distance: float = maxf(level_config.target_radius, level_config.civilian_radius) * 3.2

	while positions.size() < count and tries < 500:
		tries += 1

		var candidate: Vector2 = Vector2(
			_rng.randf_range(world_limits.position.x + 90.0, world_limits.position.x + world_limits.size.x - 90.0),
			_rng.randf_range(world_limits.position.y + 70.0, world_limits.position.y + world_limits.size.y - 70.0)
		)

		var valid = true

		for existing in positions:
			if existing.distance_to(candidate) < min_distance:
				valid = false
				break

		if valid:
			positions.append(candidate)

	return positions


func _build_level_spawn_plan_from_config() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var config_entries: Array = level_config.spawn_entries
	if config_entries.is_empty():
		return entries

	for entry_resource in config_entries:
		if entry_resource == null:
			continue

		var plan_entry: Dictionary = {
			"position": Vector2(entry_resource.position),
			"behavior": str(entry_resource.behavior_type),
			"actor_kind": str(entry_resource.actor_kind),
			"extra": {
				"tutorial_primary": bool(entry_resource.tutorial_primary),
				"disguise_strength": float(entry_resource.disguise_strength),
			},
		}

		if float(entry_resource.move_range) >= 0.0:
			plan_entry["extra"]["move_range"] = float(entry_resource.move_range)
		if float(entry_resource.move_speed) >= 0.0:
			plan_entry["extra"]["move_speed"] = float(entry_resource.move_speed)
		if float(entry_resource.reveal_cycle_sec) >= 0.0:
			plan_entry["extra"]["reveal_cycle_sec"] = float(entry_resource.reveal_cycle_sec)
		if float(entry_resource.reveal_window_sec) >= 0.0:
			plan_entry["extra"]["reveal_window_sec"] = float(entry_resource.reveal_window_sec)

		if int(entry_resource.suspicion_tier) >= 0:
			plan_entry["extra"]["suspicion_tier"] = int(entry_resource.suspicion_tier)
		if not entry_resource.clue_profile.is_empty():
			plan_entry["extra"]["clue_profile"] = entry_resource.clue_profile
		if float(entry_resource.search_signal_strength) >= 0.0:
			plan_entry["extra"]["search_signal_strength"] = float(entry_resource.search_signal_strength)

		if not entry_resource.false_clue_profile.is_empty():
			plan_entry["extra"]["false_clue_profile"] = entry_resource.false_clue_profile
		if float(entry_resource.false_clue_cycle_sec) >= 0.0:
			plan_entry["extra"]["false_clue_cycle_sec"] = float(entry_resource.false_clue_cycle_sec)
		if float(entry_resource.false_clue_window_sec) >= 0.0:
			plan_entry["extra"]["false_clue_window_sec"] = float(entry_resource.false_clue_window_sec)

		entries.append(plan_entry)

	var expected_total: int = level_config.required_targets + level_config.civilian_count
	if entries.size() != expected_total:
		push_warning("关卡 %d 的 spawn_entries 数量不匹配，期望 %d，实际 %d，将回退默认刷点。" % [
			int(level_config.level_id),
			expected_total,
			entries.size(),
		])
		return []

	return entries


func _build_level_spawn_plan() -> Array[Dictionary]:
	match int(level_config.level_id):
		1:
			return [
				{"position": Vector2(210.0, -140.0), "behavior": "static", "extra": {"disguise_strength": 0.45}},
				{"position": Vector2(-270.0, 40.0), "behavior": "static", "extra": {"disguise_strength": 0.62}},
				{"position": Vector2(360.0, 180.0), "behavior": "static", "extra": {"disguise_strength": 0.7}},
				{"position": Vector2(-60.0, -70.0), "extra": {"disguise_strength": 0.85}},
				{"position": Vector2(120.0, 250.0), "extra": {"disguise_strength": 0.82}},
			]
		2:
			return [
				{"position": Vector2(-220.0, -110.0), "behavior": "static", "extra": {"disguise_strength": 0.56}},
				{"position": Vector2(210.0, -10.0), "behavior": "static", "extra": {"disguise_strength": 0.68}},
				{"position": Vector2(-340.0, 170.0), "behavior": "moving", "extra": {"move_range": 54.0, "move_speed": 0.52, "disguise_strength": 0.72}},
				{"position": Vector2(330.0, 190.0), "behavior": "moving", "extra": {"move_range": 72.0, "move_speed": 0.62, "disguise_strength": 0.8}},
				{"position": Vector2(-40.0, 250.0), "extra": {"disguise_strength": 0.84}},
				{"position": Vector2(80.0, -210.0), "extra": {"disguise_strength": 0.82}},
				{"position": Vector2(420.0, 70.0), "extra": {"disguise_strength": 0.86}},
			]
		_:
			return [
				{"position": Vector2(-260.0, -120.0), "behavior": "static", "extra": {"disguise_strength": 0.58}},
				{"position": Vector2(260.0, -40.0), "behavior": "static", "extra": {"disguise_strength": 0.72}},
				{"position": Vector2(-380.0, 170.0), "behavior": "moving", "extra": {"move_range": 76.0, "move_speed": 0.64, "disguise_strength": 0.78}},
				{"position": Vector2(40.0, 210.0), "behavior": "weakpoint", "extra": {"reveal_cycle_sec": 2.2, "reveal_window_sec": 1.05, "disguise_strength": 0.82}},
				{"position": Vector2(410.0, 185.0), "behavior": "weakpoint", "extra": {"reveal_cycle_sec": 2.0, "reveal_window_sec": 0.9, "disguise_strength": 0.85}},
				{"position": Vector2(-110.0, -230.0), "extra": {"disguise_strength": 0.82}},
				{"position": Vector2(150.0, -215.0), "extra": {"disguise_strength": 0.84}},
				{"position": Vector2(-150.0, 290.0), "extra": {"disguise_strength": 0.86}},
				{"position": Vector2(180.0, 315.0), "extra": {"disguise_strength": 0.88}},
			]
