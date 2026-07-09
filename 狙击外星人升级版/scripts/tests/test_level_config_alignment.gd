extends Node

# 3关配置和三星/奖励公式对齐验证脚本
# 运行方式：在Godot中直接运行此场景

const PVE_LEVEL_CONFIG_SCRIPT = preload("res://scripts/pve/pve_level_config.gd")
const LEVEL_PATHS := {
	1: "res://configs/pve/cfg_pve_level_001.tres",
	2: "res://configs/pve/cfg_pve_level_002.tres",
	3: "res://configs/pve/cfg_pve_level_003.tres",
}

const EXPECTED_CONFIGS := {
	1: {
		"required_targets": 2,
		"civilian_count": 4,
		"time_limit_sec": 120.0,
		"reward_gold": 80,
		"moving_targets": 0,
		"weakpoint_targets": 0,
		"scan_count": 1,
		"time_extend_count": 0,
	},
	2: {
		"required_targets": 5,
		"civilian_count": 5,
		"time_limit_sec": 120.0,
		"reward_gold": 110,
		"moving_targets": 3,
		"weakpoint_targets": 0,
		"scan_count": 1,
		"time_extend_count": 0,
	},
	3: {
		"required_targets": 8,
		"civilian_count": 6,
		"time_limit_sec": 150.0,
		"reward_gold": 150,
		"moving_targets": 3,
		"weakpoint_targets": 2,
		"scan_count": 1,
		"time_extend_count": 1,
	}
}

var failures: Array[String] = []
var passes: int = 0


func _repeat_char(c: String, count: int) -> String:
	var result := ""
	for i in count:
		result += c
	return result


func _ready() -> void:
	var sep := _repeat_char("=", 60)
	print(sep)
	print("【3关配置和三星/奖励公式对齐验证】")
	print(sep)
	
	# 1. 验证3关配置
	_verify_level_configs()
	
	# 2. 验证三星评价规则
	_verify_star_rating()
	
	# 3. 验证时间奖励公式
	_verify_time_bonus_formula()
	
	# 输出结果
	print("\n" + sep)
	if failures.is_empty():
		print("✅ 所有验证通过！共通过 %d 项检查" % passes)
	else:
		print("❌ 发现 %d 项问题：" % failures.size())
		for f in failures:
			print("   - " + f)
	print(sep)
	
	# 自动退出
	get_tree().create_timer(0.5).timeout.connect(func(): get_tree().quit(0 if failures.is_empty() else 1))


func _load_config(level_id: int):
	var path = LEVEL_PATHS[level_id]
	var config = load(path)
	return config


# 三星评价逻辑（从core_game_state.gd复制过来用于独立测试）
func _build_result_rating(success: bool, wrong_hit_count: int, elapsed_time: float, level_id: int) -> Dictionary:
	var config = _load_config(level_id)
	var time_limit = float(config.time_limit_sec)
	var remaining_time = maxf(time_limit - elapsed_time, 0.0)
	
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


# 时间奖励计算逻辑（从battle_core.gd复制过来用于独立测试）
func _calc_time_bonus(base_reward_gold: int, elapsed_time: float, wrong_hit_count: int, success: bool) -> int:
	if not success:
		return 0
	var miss_penalty_ratio := 1.0 + float(wrong_hit_count) * -0.15
	var formula_result := int(elapsed_time * miss_penalty_ratio)
	var floor_result := int(float(base_reward_gold) * 0.3)
	return maxi(formula_result, floor_result)


func _verify_level_configs():
	print("\n📋 验证3关配置...")
	
	for level_id in EXPECTED_CONFIGS.keys():
		var expected = EXPECTED_CONFIGS[level_id]
		var config = _load_config(level_id)
		
		if config == null:
			_fail("第 %d 关配置加载失败" % level_id)
			continue
		
		# 检查各个字段
		for field in expected.keys():
			var expected_val = expected[field]
			var actual_val = config.get(field)
			
			if actual_val == null:
				_fail("第 %d 关缺少字段: %s" % [level_id, field])
				continue
			
			if typeof(actual_val) == TYPE_FLOAT:
				if absf(float(actual_val) - float(expected_val)) > 0.01:
					_fail("第 %d 关 %s 不匹配: 期望 %.1f, 实际 %.1f" % [level_id, field, expected_val, actual_val])
				else:
					_pass("第 %d 关 %s = %s" % [level_id, field, str(actual_val)])
			else:
				if int(actual_val) != int(expected_val):
					_fail("第 %d 关 %s 不匹配: 期望 %s, 实际 %s" % [level_id, field, str(expected_val), str(actual_val)])
				else:
					_pass("第 %d 关 %s = %s" % [level_id, field, str(actual_val)])


func _verify_star_rating():
	print("\n⭐ 验证三星评价规则...")
	
	# 测试场景定义
	var test_cases = [
		# 失败场景
		{"success": false, "wrong_hit": 3, "elapsed": 60.0, "level": 1, "expected_stars": 0, "desc": "误伤3次失败"},
		{"success": false, "wrong_hit": 0, "elapsed": 130.0, "level": 1, "expected_stars": 0, "desc": "超时失败"},
		# 3星场景
		{"success": true, "wrong_hit": 0, "elapsed": 80.0, "level": 1, "expected_stars": 3, "desc": "0误伤+剩余40秒(>30)"},
		{"success": true, "wrong_hit": 0, "elapsed": 89.9, "level": 1, "expected_stars": 3, "desc": "0误伤+剩余30.1秒(>30)"},
		# 2星场景
		{"success": true, "wrong_hit": 0, "elapsed": 90.0, "level": 1, "expected_stars": 2, "desc": "0误伤+剩余30秒(刚好不满足3星)"},
		{"success": true, "wrong_hit": 1, "elapsed": 100.0, "level": 1, "expected_stars": 2, "desc": "1误伤+剩余20秒(>10)"},
		{"success": true, "wrong_hit": 1, "elapsed": 109.9, "level": 1, "expected_stars": 2, "desc": "1误伤+剩余10.1秒(>10)"},
		# 1星场景
		{"success": true, "wrong_hit": 2, "elapsed": 60.0, "level": 1, "expected_stars": 1, "desc": "2误伤(>1)即使剩余时间多"},
		{"success": true, "wrong_hit": 1, "elapsed": 110.0, "level": 1, "expected_stars": 1, "desc": "1误伤+剩余10秒(刚好不满足2星)"},
		{"success": true, "wrong_hit": 0, "elapsed": 115.0, "level": 1, "expected_stars": 1, "desc": "0误伤但剩余5秒(<10)"},
		{"success": true, "wrong_hit": 2, "elapsed": 119.0, "level": 1, "expected_stars": 1, "desc": "惊险过关"},
		# 第3关（150秒时限）的3星测试
		{"success": true, "wrong_hit": 0, "elapsed": 110.0, "level": 3, "expected_stars": 3, "desc": "第3关0误伤+剩余40秒"},
		{"success": true, "wrong_hit": 1, "elapsed": 135.0, "level": 3, "expected_stars": 2, "desc": "第3关1误伤+剩余15秒"},
		{"success": true, "wrong_hit": 2, "elapsed": 145.0, "level": 3, "expected_stars": 1, "desc": "第3关2误伤惊险过关"},
	]
	
	for tc in test_cases:
		var rating = _build_result_rating(tc["success"], tc["wrong_hit"], tc["elapsed"], tc["level"])
		var actual_stars = int(rating.get("stars", -1))
		
		if actual_stars == tc["expected_stars"]:
			_pass("三星评价[%s]: %d星 ✓" % [tc["desc"], actual_stars])
		else:
			_fail("三星评价[%s]: 期望%d星, 实际%d星 (grade=%s)" % [
				tc["desc"], tc["expected_stars"], actual_stars, str(rating.get("grade", ""))
			])


func _verify_time_bonus_formula():
	print("\n💰 验证时间奖励公式...")
	
	# 公式：time_bonus = floor(survive_time_sec * (1.0 + wrong_hit_count * -0.15))
	# 保底：不低于基础奖励的30%
	
	var test_cases = [
		# 第1关（基础奖励80，保底24）
		{"base": 80, "elapsed": 90.0, "wrong_hit": 0, "success": true, "expected_bonus": 90, "desc": "第1关0误伤存活90秒"},
		{"base": 80, "elapsed": 60.0, "wrong_hit": 1, "success": true, "expected_bonus": 51, "desc": "第1关1误伤存活60秒(60*0.85=51)"},
		{"base": 80, "elapsed": 10.0, "wrong_hit": 2, "success": true, "expected_bonus": 24, "desc": "第1关2误伤存活10秒触发保底(10*0.7=7<24)"},
		{"base": 80, "elapsed": 5.0, "wrong_hit": 0, "success": true, "expected_bonus": 24, "desc": "第1关0误伤但太快触发保底(5<24)"},
		{"base": 80, "elapsed": 90.0, "wrong_hit": 0, "success": false, "expected_bonus": 0, "desc": "第1关失败无时间奖励"},
		# 第2关（基础奖励110，保底33）
		{"base": 110, "elapsed": 80.0, "wrong_hit": 0, "success": true, "expected_bonus": 80, "desc": "第2关0误伤存活80秒"},
		{"base": 110, "elapsed": 40.0, "wrong_hit": 1, "success": true, "expected_bonus": 34, "desc": "第2关1误伤存活40秒(40*0.85=34)"},
		{"base": 110, "elapsed": 20.0, "wrong_hit": 2, "success": true, "expected_bonus": 33, "desc": "第2关2误伤存活20秒触发保底(20*0.7=14<33)"},
		# 第3关（基础奖励150，保底45）
		{"base": 150, "elapsed": 120.0, "wrong_hit": 0, "success": true, "expected_bonus": 120, "desc": "第3关0误伤存活120秒"},
		{"base": 150, "elapsed": 100.0, "wrong_hit": 1, "success": true, "expected_bonus": 85, "desc": "第3关1误伤存活100秒(100*0.85=85)"},
		{"base": 150, "elapsed": 30.0, "wrong_hit": 2, "success": true, "expected_bonus": 45, "desc": "第3关2误伤存活30秒触发保底(30*0.7=21<45)"},
		{"base": 150, "elapsed": 53.0, "wrong_hit": 1, "success": true, "expected_bonus": 45, "desc": "第3关1误伤存活53秒触发保底(53*0.85=45.05→45)"},
	]
	
	for tc in test_cases:
		var actual_bonus := _calc_time_bonus(tc["base"], tc["elapsed"], tc["wrong_hit"], tc["success"])
		
		if actual_bonus == tc["expected_bonus"]:
			_pass("时间奖励[%s]: %d金币 ✓" % [tc["desc"], actual_bonus])
		else:
			var miss_penalty_ratio := 1.0 + float(tc["wrong_hit"]) * -0.15
			var formula_result := int(float(tc["elapsed"]) * miss_penalty_ratio)
			var floor_result := int(float(tc["base"]) * 0.3)
			_fail("时间奖励[%s]: 期望%d金币, 实际%d金币 (公式计算%d, 保底%d)" % [
				tc["desc"], tc["expected_bonus"], actual_bonus, formula_result, floor_result
			])


func _pass(msg: String):
	passes += 1
	print("  ✓ " + msg)


func _fail(msg: String):
	failures.append(msg)
	print("  ✗ " + msg)
