extends Node

var _passed: int = 0
var _failed: int = 0
var _logs: Array[String] = []


func _ready() -> void:
	_log("=== 虹彩流光轨迹特效皮肤测试 ===")
	_log("")
	
	_test_skin_config_load()
	_test_skin_trail_colors()
	_test_shop_can_buy()
	_test_visual_feedback_trail_config()
	
	_log("")
	_log("=== 测试结果：%d 通过，%d 失败 ===" % [_passed, _failed])
	get_tree().quit(_failed)


func _test_skin_config_load() -> void:
	_log("[测试1] 皮肤配置加载")
	var skin = WeaponManager.get_skin_config("skin_rainbow_trail")
	if skin == null:
		_fail("皮肤配置加载失败：skin_rainbow_trail")
		return
	_pass("皮肤配置加载成功：%s" % skin.display_name)
	_assert_equal("skin_id", skin.skin_id, "skin_rainbow_trail")
	_assert_equal("rarity", skin.rarity, "legendary")
	_assert_equal("price_gold", skin.price_gold, 2800)
	_assert_equal("weapon_id", skin.weapon_id, "default_sniper")
	_log("")


func _test_skin_trail_colors() -> void:
	_log("[测试2] 轨迹特效配置")
	var skin = WeaponManager.get_skin_config("skin_rainbow_trail")
	if skin == null:
		_fail("皮肤不存在")
		return
	_assert_equal("trail_effect_type", skin.trail_effect_type, "rainbow")
	_assert_greater_equal("trail_ring_count", skin.trail_ring_count, 3)
	_assert_greater("trail_outer_radius", skin.trail_outer_radius, 0.1)
	_assert_greater("trail_glow_intensity", skin.trail_glow_intensity, 1.5)
	var colors = skin.get_trail_colors()
	_assert_greater_equal("颜色数量", colors.size(), 6)
	_log("六色环绕：红(%.2f,%.2f,%.2f) 橙(%.2f,%.2f,%.2f) 黄(%.2f,%.2f,%.2f) 绿(%.2f,%.2f,%.2f) 蓝(%.2f,%.2f,%.2f) 紫(%.2f,%.2f,%.2f)" % [
		colors[0].r, colors[0].g, colors[0].b,
		colors[1].r, colors[1].g, colors[1].b,
		colors[2].r, colors[2].g, colors[2].b,
		colors[3].r, colors[3].g, colors[3].b,
		colors[4].r, colors[4].g, colors[4].b,
		colors[5].r, colors[5].g, colors[5].b,
	])
	_pass("轨迹特效配置验证通过")
	_log("")


func _test_shop_can_buy() -> void:
	_log("[测试3] 商店购买逻辑")
	var can_buy = ShopService.can_buy_skin("skin_rainbow_trail")
	_log("当前金币：%d，皮肤价格：%d" % [CoreGameState.player_gold, 2800])
	if CoreGameState.player_gold >= 2800:
		_assert_true("金币充足时可购买", can_buy)
	else:
		_assert_false("金币不足时不可购买", can_buy)
	var price = ShopService.get_skin_price("skin_rainbow_trail")
	_assert_equal("售价", price["gold"], 2800)
	_pass("商店购买逻辑验证通过")
	_log("")


func _test_visual_feedback_trail_config() -> void:
	_log("[测试4] 视觉反馈轨迹配置读取")
	var default_skin = WeaponManager.get_skin_config("skin_default")
	if default_skin != null:
		_assert_equal("默认皮肤轨迹类型", default_skin.trail_effect_type, "default")
		var default_colors = default_skin.get_trail_colors()
		_assert_equal("默认皮肤颜色数", default_colors.size(), 2)
		_log("默认皮肤轨迹配置正常：%d 色" % default_colors.size())
	
	var rainbow_skin = WeaponManager.get_skin_config("skin_rainbow_trail")
	if rainbow_skin != null:
		var rainbow_colors = rainbow_skin.get_trail_colors()
		_assert_greater_equal("虹彩皮肤颜色数", rainbow_colors.size(), 6)
		_log("虹彩流光轨迹配置正常：%d 色环绕" % rainbow_colors.size())
	
	_pass("视觉反馈轨迹配置读取验证通过")
	_log("")


func _assert_equal(label: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		_pass("  ✓ %s: %s == %s" % [label, str(actual), str(expected)])
	else:
		_fail("  ✗ %s: 期望 %s，实际 %s" % [label, str(expected), str(actual)])


func _assert_greater(label: String, actual: float, expected: float) -> void:
	if actual > expected:
		_pass("  ✓ %s: %.3f > %.3f" % [label, actual, expected])
	else:
		_fail("  ✗ %s: 期望 > %.3f，实际 %.3f" % [label, expected, actual])


func _assert_greater_equal(label: String, actual: float, expected: float) -> void:
	if actual >= expected:
		_pass("  ✓ %s: %.3f >= %.3f" % [label, actual, expected])
	else:
		_fail("  ✗ %s: 期望 >= %.3f，实际 %.3f" % [label, expected, actual])


func _assert_true(label: String, value: bool) -> void:
	if value:
		_pass("  ✓ %s: true" % label)
	else:
		_fail("  ✗ %s: 期望 true，实际 false" % label)


func _assert_false(label: String, value: bool) -> void:
	if not value:
		_pass("  ✓ %s: false" % label)
	else:
		_fail("  ✗ %s: 期望 false，实际 true" % label)


func _pass(msg: String) -> void:
	_passed += 1
	_logs.append(msg)
	print(msg)


func _fail(msg: String) -> void:
	_failed += 1
	_logs.append(msg)
	print(msg)


func _log(msg: String) -> void:
	_logs.append(msg)
	print(msg)
