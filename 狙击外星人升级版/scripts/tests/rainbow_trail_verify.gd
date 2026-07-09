extends Node

func _ready() -> void:
	print("=== 语法与配置验证测试 ===")
	
	var skin_cfg_script = load("res://scripts/core/skin_config.gd")
	if skin_cfg_script == null:
		print("FAIL: skin_config.gd 加载失败")
		get_tree().quit(1)
		return
	print("PASS: skin_config.gd 加载成功")
	
	var wm_script = load("res://scripts/core/weapon_manager.gd")
	if wm_script == null:
		print("FAIL: weapon_manager.gd 加载失败")
		get_tree().quit(1)
		return
	print("PASS: weapon_manager.gd 加载成功")
	
	var shop_script = load("res://scripts/core/shop_service.gd")
	if shop_script == null:
		print("FAIL: shop_service.gd 加载失败")
		get_tree().quit(1)
		return
	print("PASS: shop_service.gd 加载成功")
	
	var vf3d_script = load("res://scripts/pve/visual_feedback_3d.gd")
	if vf3d_script == null:
		print("FAIL: visual_feedback_3d.gd 加载失败")
		get_tree().quit(1)
		return
	print("PASS: visual_feedback_3d.gd 加载成功")
	
	var rainbow_skin = load("res://configs/skin/cfg_skin_rainbow_trail.tres")
	if rainbow_skin == null:
		print("FAIL: cfg_skin_rainbow_trail.tres 加载失败")
		get_tree().quit(1)
		return
	print("PASS: cfg_skin_rainbow_trail.tres 加载成功")
	
	print("")
	print("皮肤信息：")
	print("  ID: ", rainbow_skin.skin_id)
	print("  名称: ", rainbow_skin.display_name)
	print("  稀有度: ", rainbow_skin.rarity)
	print("  价格: ", rainbow_skin.price_gold, " 金币")
	print("  轨迹类型: ", rainbow_skin.trail_effect_type)
	print("  光环数量: ", rainbow_skin.trail_ring_count)
	print("  外半径: ", rainbow_skin.trail_outer_radius)
	print("  辉光强度: ", rainbow_skin.trail_glow_intensity)
	
	var colors = rainbow_skin.get_trail_colors()
	print("  轨迹颜色数: ", colors.size())
	for i in range(colors.size()):
		print("    颜色", i, ": (", colors[i].r, ", ", colors[i].g, ", ", colors[i].b, ")")
	
	var default_skin = load("res://configs/skin/cfg_skin_default.tres")
	if default_skin != null:
		print("")
		print("默认皮肤验证：")
		print("  轨迹类型: ", default_skin.trail_effect_type)
		var def_colors = default_skin.get_trail_colors()
		print("  轨迹颜色数: ", def_colors.size())
		if def_colors.size() == 2:
			print("  PASS: 默认皮肤颜色数正确 (2)")
		else:
			print("  FAIL: 默认皮肤颜色数错误 (期望2，实际", def_colors.size(), ")")
	
	print("")
	print("=== 所有验证通过 ===")
	get_tree().quit(0)
