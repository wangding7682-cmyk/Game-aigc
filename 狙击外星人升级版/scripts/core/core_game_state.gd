extends Node

const PVE_LEVEL_CONFIG_SCRIPT = preload("res://scripts/pve/pve_level_config.gd")
const LEVEL_PATHS := {
	1: "res://configs/pve/cfg_pve_level_001.tres",
	2: "res://configs/pve/cfg_pve_level_002.tres",
	3: "res://configs/pve/cfg_pve_level_003.tres",
	4: "res://configs/pve/cfg_pve_level_004.tres",
	5: "res://configs/pve/cfg_pve_level_005.tres",
	6: "res://configs/pve/cfg_pve_level_006.tres",
	7: "res://configs/pve/cfg_pve_level_007.tres",
	8: "res://configs/pve/cfg_pve_level_008.tres",
	9: "res://configs/pve/cfg_pve_level_009.tres",
	10: "res://configs/pve/cfg_pve_level_010.tres",
	11: "res://configs/pve/cfg_pve_level_011.tres",
	12: "res://configs/pve/cfg_pve_level_012.tres",
	13: "res://configs/pve/cfg_pve_level_013.tres",
	14: "res://configs/pve/cfg_pve_level_014.tres",
	15: "res://configs/pve/cfg_pve_level_015.tres",
	16: "res://configs/pve/cfg_pve_level_016.tres",
	17: "res://configs/pve/cfg_pve_level_017.tres",
	18: "res://configs/pve/cfg_pve_level_018.tres",
	19: "res://configs/pve/cfg_pve_level_019.tres",
	20: "res://configs/pve/cfg_pve_level_020.tres",
}
const TUTORIAL_STEPS := [
	{
		"title": "移动镜头",
		"description": "先拖动画面或用 `WASD` / 方向键观察四周，找一找可疑目标。",
		"expected_text": "移动一次镜头",
		"allowed_actions": [&"camera_left", &"camera_right", &"camera_up", &"camera_down", &"camera_move", &"aim_zoom_in", &"aim_zoom_out"],
		"progress_actions": [&"camera_left", &"camera_right", &"camera_up", &"camera_down", &"camera_move"],
	},
	{
		"title": "拖到中央观察",
		"description": "注意那个眼睛发红、肩线不自然，还会轻微脉冲闪烁的目标，把它拖到屏幕中央观察区。",
		"expected_text": "把可疑外星人拖到屏幕中央",
		"allowed_actions": [&"camera_left", &"camera_right", &"camera_up", &"camera_down", &"camera_move", &"aim_zoom_in", &"aim_zoom_out"],
		"progress_actions": [&"focus_target", &"tutorial_target_focused", &"tutorial_target_centered"],
	},
	{
		"title": "扫描确认",
		"description": "点一次 `扫描`，确认哪一个目标是真的外星人。扫描会高亮可疑目标，并给出定位线索。",
		"expected_text": "使用一次扫描确认目标",
		"allowed_actions": [&"use_scan", &"camera_left", &"camera_right", &"camera_up", &"camera_down", &"camera_move", &"aim_zoom_in", &"aim_zoom_out"],
		"progress_actions": [&"use_scan"],
	},
	{
		"title": "放大瞄准",
		"description": "双击鼠标左键、滚轮或按 `Q/E` 调整倍率，把目标拉近。",
		"expected_text": "完成一次放大瞄准",
		"allowed_actions": [&"aim_zoom_in", &"aim_zoom_out", &"camera_move", &"camera_left", &"camera_right", &"camera_up", &"camera_down", &"use_scan"],
		"progress_actions": [&"aim_zoom_in", &"aim_zoom_out", &"aim_zoom_in_steady"],
	},
	{
		"title": "屏息稳枪",
		"description": "按住右键或 `Shift` 屏息，准星会更稳，边缘会变暗。\n双击进入瞄准后，也可以按住 `Space` 触发屏息。",
		"expected_text": "屏息稳定至少半秒",
		"allowed_actions": [&"aim_hold", &"hold_breath", &"aim_zoom_in", &"aim_zoom_out", &"camera_move", &"use_scan"],
		"progress_actions": [&"aim_hold", &"hold_breath"],
	},
	{
		"title": "完成第一枪",
		"description": "保持准星压在目标上，松开右键或按 `Enter/左键` 完成射击。",
		"expected_text": "击中第一个外星人",
		"allowed_actions": [&"aim_hold", &"fire", &"aim_zoom_in", &"aim_zoom_out", &"camera_move", &"use_scan", &"hold_breath"],
		"progress_actions": [&"fire", &"target_killed"],
	},
]
const DEFAULT_PLAYER_FEEL_SETTINGS := {
	"camera_pan_speed_scale": 1.0,
	"search_mouse_look_scale": 1.0,
	"zoom_step_scale": 1.0,
	"edge_pan_speed_scale": 1.0,
	"crosshair_style": "plus",
	"crosshair_color": "amber",
	"hold_vignette_strength": 1.0,
}
const CROSSHAIR_STYLE_OPTIONS := ["plus", "cross", "dot", "circle", "x"]
const CROSSHAIR_COLOR_OPTIONS := ["amber", "white", "green", "cyan", "red"]
const PLAYER_FEEL_SETTING_RULES := {
	"camera_pan_speed_scale": {
		"label": "镜头移动速度",
		"min": 0.8,
		"max": 1.3,
		"step": 0.1,
		"description": "只影响拖镜头和按键平移速度，不改变关卡难度。",
	},
	"search_mouse_look_scale": {
		"label": "搜索态鼠标扫视灵敏度",
		"min": 0.6,
		"max": 1.6,
		"step": 0.05,
		"description": "只影响搜索态下按住并拖动时的视野扫视速度，不改变机位和关卡难度。",
	},
	"zoom_step_scale": {
		"label": "缩放步进速度",
		"min": 0.8,
		"max": 1.25,
		"step": 0.05,
		"description": "只影响放大/缩小镜头的快慢，不改变目标行为。",
	},
	"edge_pan_speed_scale": {
		"label": "边缘跟镜速度",
		"min": 0.75,
		"max": 1.35,
		"step": 0.1,
		"description": "只影响准星贴边时镜头自动跟随的速度。",
	},
	"hold_vignette_strength": {
		"label": "屏息边缘暗角强度",
		"min": 0.6,
		"max": 1.35,
		"step": 0.05,
		"description": "只影响瞄准/屏息时边缘暗角的视觉强度，不改变目标行为。",
	},
}
const UPGRADE_META := {
	"stability": {
		"label": "稳定性",
		"description": "减少待机散布和屏息后的残余抖动，降低误伤和打空概率。",
	},
	"zoom": {
		"label": "缩放倍率",
		"description": "提升最大缩放范围，让远处伪装目标更容易观察和确认。",
	},
}

var current_level_id := 1
var unlocked_levels := LEVEL_PATHS.size()
var tutorial_completed := false
var tutorial_step_index := 0
var tutorial_started_logged := false
var player_gold := 0
var login_profile: Dictionary = {}
var last_result: Dictionary = {}
var first_exit_entry: String = ""
var first_failed_level_id := 0
var first_failed_reason := ""
var upgrade_levels := {
	"stability": 0,
	"zoom": 0,
}
var best_level_records: Dictionary = {}
var battle_history: Array[Dictionary] = []
const MAX_BATTLE_HISTORY := 5
var player_feel_settings: Dictionary = DEFAULT_PLAYER_FEEL_SETTINGS.duplicate(true)


func _ready() -> void:
	var payload := PlatformService.load_game()
	if payload is Dictionary and not payload.is_empty():
		restore_from_payload(payload)


func start_level(level_id: int) -> void:
	current_level_id = clampi(level_id, 1, LEVEL_PATHS.size())
	if is_tutorial_active() and tutorial_step_index >= TUTORIAL_STEPS.size():
		tutorial_step_index = 0


func finish_battle(result: Dictionary) -> void:
	last_result = result.duplicate(true)
	last_result["record_flags"] = _build_record_flags(last_result)
	_update_best_level_record(last_result)
	_add_battle_history(last_result)
	player_gold += int(result.get("reward_gold", 0))
	if bool(result.get("success", false)):
		unlocked_levels = min(max(unlocked_levels, current_level_id + 1), LEVEL_PATHS.size())
	else:
		record_first_failure(current_level_id, str(result.get("reason", "unknown")))
	PlatformService.save_game(build_save_payload())


func can_go_next_level() -> bool:
	return bool(last_result.get("success", false)) and current_level_id < LEVEL_PATHS.size() and unlocked_levels >= current_level_id + 1


func advance_to_next_level() -> void:
	current_level_id = min(current_level_id + 1, LEVEL_PATHS.size())


func get_level_config(level_id: int = current_level_id):
	var resolved_level := clampi(level_id, 1, LEVEL_PATHS.size())
	var level_path: String = str(LEVEL_PATHS.get(resolved_level, LEVEL_PATHS[1]))
	var config: Variant = load(level_path)
	if config != null:
		return config

	push_warning("关卡配置加载失败，回退到内置默认配置：%s" % level_path)
	match resolved_level:
		1:
			return _make_level_config(1, "城市试炼 01", "新手关卡：以静止伪装目标为主，先熟悉瞄准与开枪。", 120.0, 2, 4, 80, 1, 0, 0, 0, Vector2(1800.0, 1000.0))
		2:
			return _make_level_config(2, "城市试炼 02", "加入缓慢移动目标，开始考验你的观察和跟枪能力。", 120.0, 5, 5, 110, 1, 0, 3, 0, Vector2(2000.0, 1100.0))
		3:
			return _make_level_config(3, "城市试炼 03", "三类目标混合出现，逼出道具使用与优先级判断。", 150.0, 8, 6, 150, 1, 1, 3, 2, Vector2(2200.0, 1200.0))
		_:
			return _make_generated_level_config(resolved_level)


func get_level_config_path(level_id: int) -> String:
	var resolved_level := clampi(level_id, 1, LEVEL_PATHS.size())
	return str(LEVEL_PATHS.get(resolved_level, LEVEL_PATHS[1]))


func get_weapon_profile() -> Dictionary:
	return _build_weapon_profile_for_levels(
		get_upgrade_level("stability"),
		get_upgrade_level("zoom")
	)


func _build_weapon_profile_for_levels(stability_level: int, zoom_level: int) -> Dictionary:
	var base_profile := WeaponManager.get_equipped_weapon_profile()
	var camera_pan_speed_scale: float = float(player_feel_settings.get("camera_pan_speed_scale", 1.0))
	var search_mouse_look_scale: float = float(player_feel_settings.get("search_mouse_look_scale", 1.0))
	var zoom_step_scale: float = float(player_feel_settings.get("zoom_step_scale", 1.0))
	var edge_pan_speed_scale: float = float(player_feel_settings.get("edge_pan_speed_scale", 1.0))

	return {
		"weapon_id": base_profile.get("weapon_id", "default_sniper"),
		"display_name": base_profile.get("display_name", "狙击步枪"),
		"zoom_default": float(base_profile.get("zoom_default", 1.0)) + float(zoom_level) * 0.08,
		"zoom_min": float(base_profile.get("zoom_min", 0.9)),
		"zoom_max": float(base_profile.get("zoom_max", 2.2)) + float(zoom_level) * 0.2,
		"zoom_quick_aim": float(base_profile.get("zoom_quick_aim", 1.4)) + float(zoom_level) * 0.10,
		"zoom_step": float(base_profile.get("zoom_step", 0.15)) * zoom_step_scale,
		"camera_pan_speed": float(base_profile.get("camera_pan_speed", 300.0)) * camera_pan_speed_scale,
		"search_mouse_look_scale": search_mouse_look_scale,
		"edge_pan_speed_scale": float(base_profile.get("edge_pan_speed_scale", 1.0)) * edge_pan_speed_scale,
		"hold_stabilize_sec": max(0.55, float(base_profile.get("hold_stabilize_sec", 1.0)) - float(stability_level) * 0.08),
		"aim_recover_sec": float(base_profile.get("aim_recover_sec", 0.35)),
		"spread_idle": max(20.0, float(base_profile.get("spread_idle", 34.0)) - float(stability_level) * 8.0),
		"spread_hold": max(5.0, float(base_profile.get("spread_hold", 10.0)) - float(stability_level) * 1.2),
		"hit_tolerance_radius": float(base_profile.get("hit_tolerance_radius", 26.0)),
		"time_extend_sec": float(base_profile.get("time_extend_sec", 15.0)),
		"scan_highlight_sec": float(base_profile.get("scan_highlight_sec", 3.0)),
		"recoil_duration": float(base_profile.get("recoil_duration", 0.18)),
		"post_shot_recover_duration": float(base_profile.get("post_shot_recover_duration", 0.24)),
		"cover_blast_tier": str(base_profile.get("cover_blast_tier", "medium")),
		"primary_color": base_profile.get("primary_color", Color(0.7, 0.7, 0.7)),
		"secondary_color": base_profile.get("secondary_color", Color(0.3, 0.3, 0.3)),
		"accent_color": base_profile.get("accent_color", Color(0.7, 0.7, 0.7)),
		"glow_color": base_profile.get("glow_color", Color(0.0, 0.0, 0.0)),
		"has_glow": bool(base_profile.get("has_glow", false)),
		"glow_intensity": float(base_profile.get("glow_intensity", 0.0)),
	}


func is_tutorial_active() -> bool:
	return current_level_id == 1 and not tutorial_completed and tutorial_step_index < TUTORIAL_STEPS.size()


func get_tutorial_step_data() -> Dictionary:
	if not is_tutorial_active():
		return {}

	var step_data: Dictionary = TUTORIAL_STEPS[tutorial_step_index].duplicate(true)
	step_data["index"] = tutorial_step_index + 1
	step_data["total"] = TUTORIAL_STEPS.size()
	return step_data


func is_tutorial_action_unlocked(action_name: StringName) -> bool:
	if not is_tutorial_active():
		return true

	var step_data: Dictionary = TUTORIAL_STEPS[tutorial_step_index]
	return step_data.get("allowed_actions", []).has(action_name)


func try_progress_tutorial(action_name: StringName, context: Dictionary = {}) -> Dictionary:
	if not is_tutorial_active():
		return {"progressed": false, "completed": tutorial_completed}

	var step_data: Dictionary = TUTORIAL_STEPS[tutorial_step_index]
	if not step_data.get("progress_actions", []).has(action_name):
		return {"progressed": false, "completed": false, "step": get_tutorial_step_data()}

	tutorial_step_index += 1
	if tutorial_step_index >= TUTORIAL_STEPS.size():
		tutorial_completed = true
		CoreEventBus.log_event("tutorial_completed", {
			"level_id": current_level_id,
			"step_count": TUTORIAL_STEPS.size(),
			"elapsed_time": float(context.get("elapsed_time", -1.0)),
		})
		PlatformService.save_game(build_save_payload())
		return {"progressed": true, "completed": true}

	return {
		"progressed": true,
		"completed": false,
		"step": get_tutorial_step_data(),
	}


func apply_upgrade(stat_name: String) -> bool:
	var cost := get_upgrade_cost(stat_name)
	if cost <= 0 or player_gold < cost:
		return false

	player_gold -= cost
	upgrade_levels[stat_name] = get_upgrade_level(stat_name) + 1
	PlatformService.save_game(build_save_payload())
	return true


func get_upgrade_level(stat_name: String) -> int:
	return int(upgrade_levels.get(stat_name, 0))


func get_upgrade_cost(stat_name: String) -> int:
	match stat_name:
		"stability":
			if get_upgrade_level(stat_name) >= 3:
				return -1
			return 40 + get_upgrade_level(stat_name) * 20
		"zoom":
			if get_upgrade_level(stat_name) >= 3:
				return -1
			return 50 + get_upgrade_level(stat_name) * 25
	return -1


func can_upgrade(stat_name: String) -> bool:
	var cost := get_upgrade_cost(stat_name)
	return cost > 0 and player_gold >= cost


func grant_reward_bonus(bonus_reward: int, source: String) -> void:
	var resolved_bonus: int = maxi(bonus_reward, 0)
	if resolved_bonus <= 0:
		return

	player_gold += resolved_bonus
	last_result["reward_gold"] = int(last_result.get("reward_gold", 0)) + resolved_bonus
	last_result["bonus_reward_gold"] = int(last_result.get("bonus_reward_gold", 0)) + resolved_bonus
	last_result["rewarded_ad_claimed"] = true
	last_result["reward_bonus_source"] = source
	PlatformService.save_game(build_save_payload())


func get_growth_summary() -> String:
	var weapon_profile: Dictionary = get_weapon_profile()
	var recommendation := get_growth_recommendation()
	return "当前金币：%d\n稳定性等级：%d，待机散布 %.1f，屏息后 %.1f\n缩放倍率等级：%d，最大缩放 %.1fx\n下一次升级花费：稳定性 %s，缩放倍率 %s\n当前建议：%s" % [
		player_gold,
		get_upgrade_level("stability"),
		float(weapon_profile.get("spread_idle", 34.0)),
		float(weapon_profile.get("spread_hold", 10.0)),
		get_upgrade_level("zoom"),
		float(weapon_profile.get("zoom_max", 2.2)),
		_format_upgrade_cost(get_upgrade_cost("stability")),
		_format_upgrade_cost(get_upgrade_cost("zoom")),
		str(recommendation.get("headline", "继续推进关卡")),
	]


func get_last_result_presentation() -> Dictionary:
	var result := last_result.duplicate(true)
	var rating := _build_result_rating(result)
	var record_flags: Array[String] = _string_array_from_variant(result.get("record_flags", []))
	var highlight_tags := _build_highlight_tags(result, rating, record_flags)
	var share_title := _build_share_title(result, rating, highlight_tags, record_flags)
	var recommendation := get_growth_recommendation(result)
	var primary_action := get_primary_result_action(result, recommendation)
	var secondary_actions := get_secondary_result_actions(primary_action.get("action_id", ""), result)

	return {
		"rating": rating,
		"highlight_tags": highlight_tags,
		"record_flags": record_flags,
		"share_title": share_title,
		"recommendation": recommendation,
		"primary_action": primary_action,
		"secondary_actions": secondary_actions,
		"reward_rows": [
			{"label": "基础金币", "value": int(result.get("base_reward_gold", 0)), "tone": "neutral"},
			{"label": "时间奖励", "value": int(result.get("time_bonus_gold", 0)), "tone": "positive"},
			{"label": "误伤扣减", "value": -int(result.get("wrong_hit_penalty_gold", 0)), "tone": "negative"},
			{"label": "广告奖励", "value": int(result.get("bonus_reward_gold", 0)), "tone": "bonus"},
			{"label": "本局金币", "value": int(result.get("reward_gold", 0)), "tone": "total"},
		],
		"stats_rows": [
			{"label": "命中率", "value": "%d%%" % int(round(float(result.get("accuracy", 0.0)) * 100.0))},
			{"label": "命中 / 射击", "value": "%d / %d" % [int(result.get("hit_count", 0)), int(result.get("shot_count", 0))]},
			{"label": "误伤次数", "value": str(int(result.get("wrong_hit_count", 0)))},
			{"label": "连续稳定回合", "value": str(int(result.get("no_miss_rounds", 0)))},
			{"label": "扫描使用", "value": str(int(result.get("scan_used", 0)))},
			{"label": "时间延长", "value": str(int(result.get("time_extend_used", 0)))},
			{"label": "存活时长", "value": "%.1fs" % float(result.get("elapsed_time", 0.0))},
		],
	}


func get_growth_recommendation(result: Dictionary = last_result) -> Dictionary:
	var success := bool(result.get("success", false))
	var accuracy := float(result.get("accuracy", 0.0))
	var effective_accuracy := float(result.get("effective_accuracy", accuracy))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var scan_used := int(result.get("scan_used", 0))
	var time_extend_used := int(result.get("time_extend_used", 0))
	var shot_count := int(result.get("shot_count", 0))
	var hit_count := int(result.get("hit_count", 0))
	var tactical_shot_count := int(result.get("tactical_shot_count", 0))
	var recommended_upgrade := ""
	var headline := ""
	var body := ""
	var strengths: Array[String] = []
	var weaknesses: Array[String] = []
	var suggestion := ""

	if hit_count > 0:
		strengths.append("有命中记录")
	if wrong_hit_count == 0 and shot_count > 0:
		strengths.append("零误伤")
	if success:
		strengths.append("成功通关")
	if tactical_shot_count > 0:
		strengths.append("有战术意识")
	if effective_accuracy >= 0.7 and shot_count >= 3:
		strengths.append("枪法稳定")
	if scan_used == 0 and success:
		strengths.append("不依赖扫描")
	if time_extend_used == 0 and success:
		strengths.append("节奏紧凑")

	if not success:
		if wrong_hit_count >= 2:
			weaknesses.append("误伤偏多")
			recommended_upgrade = "stability"
			headline = "先稳住枪"
			body = "误伤过多，稳定性不足导致准星晃动过大。优先升级稳定性可以减少待机散布和屏息后的残余抖动。"
			suggestion = "先升级稳定性，压低准星晃动再挑战。"
		elif accuracy < 0.4 and shot_count >= 3:
			weaknesses.append("命中率偏低")
			recommended_upgrade = "stability"
			headline = "提高稳定性"
			body = "命中率偏低，准星不稳容易打空。升级稳定性能缩小散布范围，提高命中概率。"
			suggestion = "多练习屏息瞄准节奏，或升级稳定性降低散布。"
		elif hit_count == 0 and shot_count >= 3:
			weaknesses.append("未命中目标")
			headline = "调整瞄准习惯"
			body = "未能命中任何目标，建议先熟悉武器手感和目标识别特征，多练习基础瞄准。"
			suggestion = "先用低难度关卡熟悉瞄准和目标特征。"
		else:
			headline = "再接再厉"
			body = "任务失败了，调整心态再来一次。注意观察目标特征，把握屏息时机。"
			suggestion = "稳住节奏，仔细确认目标后再开枪。"
		return {
			"recommended_upgrade": recommended_upgrade,
			"headline": headline,
			"body": body,
			"suggestion": suggestion,
			"strengths": strengths,
			"weaknesses": weaknesses,
			"can_upgrade_now": recommended_upgrade != "" and can_upgrade(recommended_upgrade),
		}

	if wrong_hit_count >= 2:
		weaknesses.append("误伤偏多")
		recommended_upgrade = "stability"
		headline = "优先升级稳定性"
		body = "误伤偏多，准星晃动导致容易打偏。稳定性升级能直接降低待机散布和屏息后的残余抖动。"
		suggestion = "升级稳定性后，误伤率会明显下降。"
	elif effective_accuracy < 0.7 and shot_count >= 3:
		weaknesses.append("枪法有待提升")
		recommended_upgrade = "stability"
		headline = "建议提升稳定性"
		body = "命中率偏低，需要更稳定的准星。升级稳定性可以提高射击精度。"
		suggestion = "多练习屏息时机，或升级稳定性减小散布。"
	elif scan_used >= 2 or time_extend_used >= 2:
		weaknesses.append("道具依赖")
		recommended_upgrade = "zoom"
		headline = "建议补缩放倍率"
		body = "道具使用偏多，说明观察距离不足。提升缩放倍率可以更早识别远处目标，减少道具依赖。"
		suggestion = "升级缩放倍率，远处目标更容易识别。"
	elif can_upgrade("stability") and get_upgrade_level("stability") <= get_upgrade_level("zoom"):
		recommended_upgrade = "stability"
		headline = "继续打磨稳定性"
		body = "你已经能稳定通关，再补一点稳定性，会让下一关命中更从容。"
		suggestion = "稳定性再升一级，下一关会更轻松。"
	elif can_upgrade("zoom"):
		recommended_upgrade = "zoom"
		headline = "可以提升观察距离"
		body = "稳定性已经不错，提升缩放倍率可以更早发现和确认目标，减少犹豫时间。"
		suggestion = "试试升级缩放倍率，提高远距离作战效率。"
	else:
		headline = "继续推进关卡"
		body = "当前成长已经能支撑下一步挑战，直接进入下一关试试更强的自己吧。"
		suggestion = "直接挑战下一关，检验你的真实水平。"

	return {
		"recommended_upgrade": recommended_upgrade,
		"headline": headline,
		"body": body,
		"suggestion": suggestion,
		"strengths": strengths,
		"weaknesses": weaknesses,
		"can_upgrade_now": recommended_upgrade != "" and can_upgrade(recommended_upgrade),
	}


func get_upgrade_card_data(stat_name: String) -> Dictionary:
	var current_level := get_upgrade_level(stat_name)
	var cost := get_upgrade_cost(stat_name)
	var current_profile := get_weapon_profile()
	var next_profile := _build_weapon_profile_for_levels(
		current_level + (1 if stat_name == "stability" and cost > 0 else 0),
		get_upgrade_level("zoom") + (1 if stat_name == "zoom" and cost > 0 else 0)
	)
	var meta: Dictionary = UPGRADE_META.get(stat_name, {
		"label": stat_name,
		"description": "",
	})
	var effect_now := ""
	var effect_next := ""

	if stat_name == "stability":
		effect_now = "当前：待机散布 %.1f，屏息散布 %.1f" % [
			float(current_profile.get("spread_idle", 0.0)),
			float(current_profile.get("spread_hold", 0.0)),
		]
		effect_next = "升级后：待机散布 %.1f，屏息散布 %.1f" % [
			float(next_profile.get("spread_idle", 0.0)),
			float(next_profile.get("spread_hold", 0.0)),
		]
	else:
		effect_now = "当前：默认倍率 %.2fx，最大倍率 %.2fx" % [
			float(current_profile.get("zoom_default", 1.0)),
			float(current_profile.get("zoom_max", 1.0)),
		]
		effect_next = "升级后：默认倍率 %.2fx，最大倍率 %.2fx" % [
			float(next_profile.get("zoom_default", 1.0)),
			float(next_profile.get("zoom_max", 1.0)),
		]

	return {
		"stat_name": stat_name,
		"label": str(meta.get("label", stat_name)),
		"description": str(meta.get("description", "")),
		"current_level": current_level,
		"cost": cost,
		"cost_text": _format_upgrade_cost(cost),
		"can_upgrade": can_upgrade(stat_name),
		"is_max": cost < 0,
		"is_recommended": str(get_growth_recommendation().get("recommended_upgrade", "")) == stat_name,
		"effect_now": effect_now,
		"effect_next": effect_next,
	}


func get_primary_result_action(result: Dictionary = last_result, recommendation: Dictionary = {}) -> Dictionary:
	var success := bool(result.get("success", false))
	if not success:
		return {
			"action_id": "retry",
			"label": "重开当前关",
			"route": "retry_current",
			"description": "先把这关打顺，比直接堆成长更直观。",
		}

	if can_go_next_level():
		return {
			"action_id": "next_level",
			"label": "开始下一关",
			"route": "next_level",
			"description": "把这次成长和节奏反馈带到下一关验证。",
		}

	var recommended_upgrade := str(recommendation.get("recommended_upgrade", ""))
	if recommended_upgrade != "":
		return {
			"action_id": "upgrade",
			"label": "进入升级",
			"route": "upgrade",
			"description": str(recommendation.get("headline", "先做一次成长提升")),
		}

	return {
		"action_id": "main_menu",
		"label": "返回主页",
		"route": "main_menu",
		"description": "已完成当前内容，可以返回主页选择其他挑战。",
	}


func get_secondary_result_actions(primary_action_id: String, result: Dictionary = last_result) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var success := bool(result.get("success", false))

	if primary_action_id != "upgrade":
		actions.append({
			"action_id": "upgrade",
			"label": "进入升级",
			"route": "upgrade",
			"enabled": success,
		})

	if primary_action_id != "next_level":
		actions.append({
			"action_id": "next_level",
			"label": "开始下一关",
			"route": "next_level",
			"enabled": can_go_next_level(),
		})

	if primary_action_id != "retry":
		actions.append({
			"action_id": "retry",
			"label": "重开当前关",
			"route": "retry_current",
			"enabled": true,
		})

	actions.append({
		"action_id": "main_menu",
		"label": "返回主页",
		"route": "main_menu",
		"enabled": true,
	})
	return actions


func _build_result_rating(result: Dictionary) -> Dictionary:
	var success := bool(result.get("success", false))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var elapsed_time := float(result.get("elapsed_time", 0.0))
	var level_id := int(result.get("level_id", current_level_id))
	var level_config: PveLevelConfig = get_level_config(level_id)
	var time_limit := float(level_config.time_limit_sec)
	var remaining_time := maxf(time_limit - elapsed_time, 0.0)

	if not success:
		if wrong_hit_count >= 3:
			return {"grade": "×", "title": "误伤过多", "stars": 0, "tone": "red"}
		return {"grade": "×", "title": "任务超时", "stars": 0, "tone": "red"}

	# 3星：0误伤 + 剩余时间 > 30秒
	if wrong_hit_count == 0 and remaining_time > 30.0:
		return {"grade": "★★★", "title": "完美清场", "stars": 3, "tone": "gold"}

	# 2星：误伤≤1 + 剩余时间 > 10秒
	if wrong_hit_count <= 1 and remaining_time > 10.0:
		return {"grade": "★★", "title": "稳定完成", "stars": 2, "tone": "blue"}

	# 1星：通关即可
	return {"grade": "★", "title": "惊险过关", "stars": 1, "tone": "gray"}


func _build_highlight_tags(result: Dictionary, rating: Dictionary, record_flags: Array[String]) -> Array[String]:
	var tags: Array[String] = []
	var success := bool(result.get("success", false))
	var accuracy := float(result.get("accuracy", 0.0))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var no_miss_rounds := int(result.get("no_miss_rounds", 0))
	var shot_count := int(result.get("shot_count", 0))
	var scan_used := int(result.get("scan_used", 0))
	var time_extend_used := int(result.get("time_extend_used", 0))
	var bonus_reward_gold := int(result.get("bonus_reward_gold", 0))
	var level_config = get_level_config(int(result.get("level_id", current_level_id)))
	var time_limit_sec := float(level_config.time_limit_sec)
	var elapsed_time := float(result.get("elapsed_time", 0.0))
	var hit_count := int(result.get("hit_count", 0))
	var required_targets := int(level_config.required_targets)

	if success:
		if wrong_hit_count == 0:
			tags.append("零误伤")
		if accuracy >= 0.9 and shot_count >= 3:
			tags.append("高命中")
		if no_miss_rounds >= 3:
			tags.append("连续稳定")
		if scan_used == 0 and time_extend_used == 0:
			tags.append("无道具通关")
		if time_limit_sec > 0.0 and elapsed_time <= time_limit_sec * 0.5:
			tags.append("速通")
		if hit_count == required_targets and shot_count == hit_count:
			tags.append("完美命中")
		if bonus_reward_gold > 0:
			tags.append("奖励翻倍")
	else:
		if wrong_hit_count >= 2:
			tags.append("误伤过多")
		if accuracy < 0.4 and shot_count >= 3:
			tags.append("命中率低")
		if hit_count == 0 and shot_count >= 3:
			tags.append("未能命中")

	for flag in record_flags:
		if tags.size() >= 5:
			break
		if not tags.has(flag):
			tags.append(flag)

	if tags.is_empty():
		tags.append(str(rating.get("title", "继续磨枪")))

	return tags


func _build_share_title(result: Dictionary, rating: Dictionary, highlight_tags: Array[String], record_flags: Array[String]) -> String:
	var level_name := str(result.get("level_name", "未知关卡"))
	var accuracy_percent := int(round(float(result.get("accuracy", 0.0)) * 100.0))
	var title := "%s %s" % [str(rating.get("grade", "C")), str(rating.get("title", "任务结算"))]
	if not record_flags.is_empty():
		title += " · %s" % record_flags[0]
	elif not highlight_tags.is_empty():
		title += " · %s" % highlight_tags[0]
	return "%s\n%s\n命中率 %d%% ｜ 本局金币 %d" % [
		title,
		level_name,
		accuracy_percent,
		int(result.get("reward_gold", 0)),
	]


func _build_record_flags(result: Dictionary) -> Array[String]:
	var flags: Array[String] = []
	var level_id := int(result.get("level_id", current_level_id))
	var previous: Dictionary = best_level_records.get(level_id, {})
	var success := bool(result.get("success", false))
	var accuracy := float(result.get("accuracy", 0.0))
	var reward_gold := int(result.get("reward_gold", 0))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var elapsed_time := float(result.get("elapsed_time", 0.0))
	var shot_count := int(result.get("shot_count", 0))

	if not success:
		return flags

	if not bool(previous.get("cleared_once", false)):
		flags.append("首通达成")
	if shot_count >= 3 and accuracy > float(previous.get("best_accuracy", -1.0)) and accuracy >= 0.5:
		flags.append("命中率新高")
	if reward_gold > int(previous.get("best_reward", -1)):
		flags.append("奖励新高")
	if not previous.has("best_time") or elapsed_time < float(previous.get("best_time", INF)):
		flags.append("最快通关")
	if wrong_hit_count == 0 and not bool(previous.get("has_zero_wrong_clear", false)):
		flags.append("首次零误伤")

	return flags


func _update_best_level_record(result: Dictionary) -> void:
	var level_id := int(result.get("level_id", current_level_id))
	var record: Dictionary = best_level_records.get(level_id, {})
	var success := bool(result.get("success", false))
	var accuracy := float(result.get("accuracy", 0.0))
	var reward_gold := int(result.get("reward_gold", 0))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var elapsed_time := float(result.get("elapsed_time", 0.0))
	var shot_count := int(result.get("shot_count", 0))

	if shot_count > 0:
		record["best_accuracy"] = maxf(float(record.get("best_accuracy", 0.0)), accuracy)
	record["best_reward"] = maxi(int(record.get("best_reward", 0)), reward_gold)
	if success:
		record["cleared_once"] = true
		if not record.has("best_time") or elapsed_time < float(record.get("best_time", INF)):
			record["best_time"] = elapsed_time
		if wrong_hit_count == 0:
			record["has_zero_wrong_clear"] = true

	best_level_records[level_id] = record


func _add_battle_history(result: Dictionary) -> void:
	var record: Dictionary = {
		"level_id": int(result.get("level_id", current_level_id)),
		"level_name": str(result.get("level_name", "未知关卡")),
		"success": bool(result.get("success", false)),
		"accuracy": float(result.get("accuracy", 0.0)),
		"effective_accuracy": float(result.get("effective_accuracy", result.get("accuracy", 0.0))),
		"hit_count": int(result.get("hit_count", 0)),
		"shot_count": int(result.get("shot_count", 0)),
		"tactical_shot_count": int(result.get("tactical_shot_count", 0)),
		"attack_shot_count": int(result.get("attack_shot_count", result.get("shot_count", 0))),
		"wrong_hit_count": int(result.get("wrong_hit_count", 0)),
		"scan_used": int(result.get("scan_used", 0)),
		"time_extend_used": int(result.get("time_extend_used", 0)),
		"elapsed_time": float(result.get("elapsed_time", 0.0)),
		"reward_gold": int(result.get("reward_gold", 0)),
		"rating_grade": str(result.get("rating", {}).get("grade", "-")),
		"played_at": Time.get_datetime_string_from_system(),
	}
	battle_history.push_front(record)
	while battle_history.size() > MAX_BATTLE_HISTORY:
		battle_history.pop_back()


func get_battle_history() -> Array[Dictionary]:
	return battle_history.duplicate(true)


func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func build_save_payload() -> Dictionary:
	var payload: Dictionary = {
		"current_level_id": current_level_id,
		"unlocked_levels": unlocked_levels,
		"tutorial_completed": tutorial_completed,
		"tutorial_step_index": tutorial_step_index,
		"tutorial_started_logged": tutorial_started_logged,
		"player_gold": player_gold,
		"login_profile": login_profile.duplicate(true),
		"first_exit_entry": first_exit_entry,
		"first_failed_level_id": first_failed_level_id,
		"first_failed_reason": first_failed_reason,
		"upgrade_levels": upgrade_levels.duplicate(true),
		"best_level_records": best_level_records.duplicate(true),
		"battle_history": battle_history.duplicate(true),
		"player_feel_settings": player_feel_settings.duplicate(true),
		"last_result": last_result.duplicate(true),
	}
	payload.merge(WeaponManager.build_save_payload())
	payload.merge(InventoryService.build_save_payload())
	return payload


func restore_from_payload(payload: Dictionary) -> void:
	current_level_id = clampi(int(payload.get("current_level_id", 1)), 1, LEVEL_PATHS.size())
	unlocked_levels = LEVEL_PATHS.size()
	tutorial_completed = bool(payload.get("tutorial_completed", false))
	tutorial_step_index = clampi(int(payload.get("tutorial_step_index", 0)), 0, TUTORIAL_STEPS.size())
	tutorial_started_logged = bool(payload.get("tutorial_started_logged", false))
	player_gold = maxi(int(payload.get("player_gold", 0)), 0)
	login_profile = payload.get("login_profile", {}).duplicate(true)
	last_result = payload.get("last_result", {}).duplicate(true)
	first_exit_entry = str(payload.get("first_exit_entry", ""))
	first_failed_level_id = maxi(int(payload.get("first_failed_level_id", 0)), 0)
	first_failed_reason = str(payload.get("first_failed_reason", ""))

	var restored_upgrades: Dictionary = payload.get("upgrade_levels", {})
	upgrade_levels = {
		"stability": int(restored_upgrades.get("stability", 0)),
		"zoom": int(restored_upgrades.get("zoom", 0)),
	}
	best_level_records = payload.get("best_level_records", {}).duplicate(true)
	var saved_history: Array = payload.get("battle_history", [])
	battle_history.clear()
	for item in saved_history:
		if item is Dictionary:
			battle_history.append(item)
	_restore_player_feel_settings(payload.get("player_feel_settings", {}))

	WeaponManager.restore_from_payload(payload)
	InventoryService.restore_from_payload(payload)


func reset_progress() -> void:
	current_level_id = 1
	unlocked_levels = LEVEL_PATHS.size()
	tutorial_completed = false
	tutorial_step_index = 0
	tutorial_started_logged = false
	player_gold = 0
	login_profile = {}
	last_result = {}
	first_exit_entry = ""
	first_failed_level_id = 0
	first_failed_reason = ""
	upgrade_levels = {
		"stability": 0,
		"zoom": 0,
	}
	best_level_records = {}
	player_feel_settings = DEFAULT_PLAYER_FEEL_SETTINGS.duplicate(true)
	CoreSaveService.clear_profile()


func record_first_exit(entry: String) -> void:
	# “第一次退出节点”埋点口径：只记录一次，用于观察玩家最常从哪一段退出。
	if not first_exit_entry.is_empty():
		return

	first_exit_entry = entry
	CoreEventBus.log_event("first_exit_recorded", {
		"entry": entry,
		"level_id": current_level_id,
	})
	PlatformService.save_game(build_save_payload())


func record_tutorial_started(level_id: int) -> void:
	if tutorial_started_logged:
		return

	tutorial_started_logged = true
	var step_data := get_tutorial_step_data()
	CoreEventBus.log_event("tutorial_started", {
		"level_id": level_id,
		"step_index": int(step_data.get("index", tutorial_step_index + 1)),
		"step_title": str(step_data.get("title", "教程开始")),
	})
	PlatformService.save_game(build_save_payload())


func record_first_failure(level_id: int, reason: String) -> void:
	if first_failed_level_id > 0:
		return

	first_failed_level_id = level_id
	first_failed_reason = reason
	CoreEventBus.log_event("first_failure_recorded", {
		"level_id": level_id,
		"reason": reason,
	})
	PlatformService.save_game(build_save_payload())


func record_login(profile: Dictionary) -> void:
	login_profile = profile.duplicate(true)


func get_player_feel_settings() -> Dictionary:
	return player_feel_settings.duplicate(true)


func get_player_feel_setting_rules() -> Dictionary:
	return PLAYER_FEEL_SETTING_RULES.duplicate(true)


func set_player_feel_setting(setting_name: String, value: float) -> void:
	if not PLAYER_FEEL_SETTING_RULES.has(setting_name):
		return

	var rule: Dictionary = PLAYER_FEEL_SETTING_RULES[setting_name]
	var min_value: float = float(rule.get("min", 0.0))
	var max_value: float = float(rule.get("max", 1.0))
	var step: float = float(rule.get("step", 0.1))
	var clamped_value: float = clampf(value, min_value, max_value)
	var snapped_value: float = snappedf(clamped_value, step)
	player_feel_settings[setting_name] = clampf(snapped_value, min_value, max_value)
	PlatformService.save_game(build_save_payload())


func cycle_crosshair_style() -> void:
	var current := str(player_feel_settings.get("crosshair_style", "plus"))
	var index := CROSSHAIR_STYLE_OPTIONS.find(current)
	if index < 0:
		index = 0
	player_feel_settings["crosshair_style"] = CROSSHAIR_STYLE_OPTIONS[(index + 1) % CROSSHAIR_STYLE_OPTIONS.size()]
	PlatformService.save_game(build_save_payload())


func cycle_crosshair_color() -> void:
	var current := str(player_feel_settings.get("crosshair_color", "amber"))
	var index := CROSSHAIR_COLOR_OPTIONS.find(current)
	if index < 0:
		index = 0
	player_feel_settings["crosshair_color"] = CROSSHAIR_COLOR_OPTIONS[(index + 1) % CROSSHAIR_COLOR_OPTIONS.size()]
	PlatformService.save_game(build_save_payload())



func reset_player_feel_settings() -> void:
	player_feel_settings = DEFAULT_PLAYER_FEEL_SETTINGS.duplicate(true)


func build_player_feel_summary() -> String:
	return "镜头移动速度：%.2fx\n搜索态鼠标扫视灵敏度：%.2fx\n缩放步进速度：%.2fx\n边缘跟镜速度：%.2fx\n准星样式：%s\n准星颜色：%s\n屏息暗角强度：%.2fx\n\n操作提示：双击左键进入瞄准；瞄准后按住 Shift / 右键 / Space 可屏息减晃动；Enter/左键开火。\n\n这些设置只影响你的操作手感，不改变目标速度、弱点窗口和误伤阈值。" % [
		float(player_feel_settings.get("camera_pan_speed_scale", 1.0)),
		float(player_feel_settings.get("search_mouse_look_scale", 1.0)),
		float(player_feel_settings.get("zoom_step_scale", 1.0)),
		float(player_feel_settings.get("edge_pan_speed_scale", 1.0)),
		str(player_feel_settings.get("crosshair_style", "plus")),
		str(player_feel_settings.get("crosshair_color", "amber")),
		float(player_feel_settings.get("hold_vignette_strength", 1.0)),
	]


func _format_upgrade_cost(cost: int) -> String:
	if cost < 0:
		return "已满级"
	return "%d 金币" % cost


func _restore_player_feel_settings(saved_settings: Dictionary) -> void:
	player_feel_settings = DEFAULT_PLAYER_FEEL_SETTINGS.duplicate(true)
	for setting_name in DEFAULT_PLAYER_FEEL_SETTINGS.keys():
		if not saved_settings.has(setting_name):
			continue

		var rule: Dictionary = PLAYER_FEEL_SETTING_RULES.get(setting_name, {})
		if not rule.is_empty():
			var min_value: float = float(rule.get("min", 0.0))
			var max_value: float = float(rule.get("max", 1.0))
			player_feel_settings[setting_name] = clampf(
				float(saved_settings.get(setting_name, DEFAULT_PLAYER_FEEL_SETTINGS[setting_name])),
				min_value,
				max_value
			)
		else:
			player_feel_settings[setting_name] = saved_settings.get(setting_name, DEFAULT_PLAYER_FEEL_SETTINGS[setting_name])

	var restored_style := str(player_feel_settings.get("crosshair_style", "plus"))
	if CROSSHAIR_STYLE_OPTIONS.find(restored_style) < 0:
		player_feel_settings["crosshair_style"] = "plus"

	var restored_color := str(player_feel_settings.get("crosshair_color", "amber"))
	if CROSSHAIR_COLOR_OPTIONS.find(restored_color) < 0:
		player_feel_settings["crosshair_color"] = "amber"


func _make_level_config(
	level_id: int,
	display_name: String,
	flavor_text: String,
	time_limit_sec: float,
	required_targets: int,
	civilian_count: int,
	reward_gold: int,
	scan_count: int,
	time_extend_count: int,
	moving_targets: int,
	weakpoint_targets: int,
	world_size: Vector2
):
	var config = PVE_LEVEL_CONFIG_SCRIPT.new()
	config.level_id = level_id
	config.display_name = display_name
	config.flavor_text = flavor_text
	config.time_limit_sec = time_limit_sec
	config.required_targets = required_targets
	config.civilian_count = civilian_count
	config.reward_gold = reward_gold
	config.scan_count = scan_count
	config.time_extend_count = time_extend_count
	config.moving_targets = moving_targets
	config.weakpoint_targets = weakpoint_targets
	config.world_size = world_size
	return config


func _make_generated_level_config(level_id: int):
	var tier: int = maxi(level_id - 3, 1)
	var required_targets: int = mini(8 + int(floor(float(tier) * 0.42)), 15)
	var civilian_count: int = mini(6 + int(floor(float(tier) * 0.35)), 12)
	var moving_targets: int = mini(3 + int(floor(float(tier) * 0.25)), maxi(required_targets - 2, 3))
	var weakpoint_targets: int = mini(2 + int(floor(float(tier) * 0.18)), maxi(required_targets - moving_targets - 1, 1))
	var reward_gold: int = 150 + tier * 18
	var scan_count: int = 1 if level_id <= 9 else 2
	var time_extend_count: int = 1 if level_id <= 14 else 2
	var time_limit_sec: float = 150.0 + float(tier) * 4.0
	var world_size := Vector2(2200.0 + float(tier) * 36.0, 1200.0 + float(tier) * 18.0)
	return _make_level_config(
		level_id,
		"城市试炼 %02d" % level_id,
		"扩展关卡：在已有规则下继续提高搜索、判断与资源管理压力。",
		time_limit_sec,
		required_targets,
		civilian_count,
		reward_gold,
		scan_count,
		time_extend_count,
		moving_targets,
		weakpoint_targets,
		world_size
	)
