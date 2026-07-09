extends Node

const LLM_CONFIG_PATH := "res://configs/llm/cfg_llm_service.json"

var _llm_config: Dictionary = {}
var _platform_service = null
var _last_analysis_result: Dictionary = {}
var _is_requesting: bool = false
var _cached_analysis: Dictionary = {}
var _cache_level_id: int = -1
var _cache_valid: bool = false

signal analysis_completed(result: Dictionary)
signal analysis_failed(error: String)
signal history_analysis_completed(result: Dictionary)
signal history_analysis_failed(error: String)


func _ready() -> void:
	_llm_config = _load_llm_config()
	_platform_service = get_node_or_null("/root/PlatformService")


func get_config() -> Dictionary:
	return _llm_config.duplicate(true)


func is_llm_enabled() -> bool:
	return bool(_llm_config.get("enabled", false))


func has_cached_analysis(level_id: int = -1) -> bool:
	if not _cache_valid:
		return false
	if level_id > 0 and _cache_level_id != level_id:
		return false
	return true


func get_cached_analysis() -> Dictionary:
	return _cached_analysis.duplicate(true)


func pre_analyze_battle(result: Dictionary) -> void:
	if not is_llm_enabled():
		return
	if _is_requesting:
		return
	if _cache_valid:
		return
	var level_id: int = int(result.get("level_id", -1))
	if level_id > 0:
		_cache_level_id = level_id
	_is_requesting = true
	var prompt := _build_battle_analysis_prompt(result)
	var analysis_result: Dictionary = await _request_llm_analysis(prompt)
	_is_requesting = false
	if bool(analysis_result.get("ok", false)):
		_cached_analysis = analysis_result
		_cache_valid = true
	elif bool(_llm_config.get("fallback_on_error", true)):
		var fallback_result := _generate_fallback_analysis(result)
		fallback_result["llm_error"] = analysis_result.get("error", "未知错误")
		_cached_analysis = fallback_result
		_cache_valid = true


func analyze_battle_result(result: Dictionary) -> Dictionary:
	var level_id: int = int(result.get("level_id", -1))
	if _cache_valid and (level_id < 0 or _cache_level_id == level_id):
		_cache_valid = false
		_last_analysis_result = _cached_analysis
		analysis_completed.emit(_cached_analysis)
		return _cached_analysis

	if not is_llm_enabled():
		var fallback := _generate_fallback_analysis(result)
		_last_analysis_result = fallback
		analysis_completed.emit(fallback)
		return fallback

	if _is_requesting:
		while _is_requesting:
			await get_tree().process_frame
		if _cache_valid and (level_id < 0 or _cache_level_id == level_id):
			_cache_valid = false
			_last_analysis_result = _cached_analysis
			analysis_completed.emit(_cached_analysis)
			return _cached_analysis
		return _last_analysis_result

	_is_requesting = true

	var prompt := _build_battle_analysis_prompt(result)
	var analysis_result: Dictionary = await _request_llm_analysis(prompt)

	_is_requesting = false

	if not bool(analysis_result.get("ok", false)) and bool(_llm_config.get("fallback_on_error", true)):
		if bool(_llm_config.get("debug_log", false)):
			print_debug("LLM请求失败，回退到fallback分析：", analysis_result.get("error", "未知错误"))
		var fallback_result := _generate_fallback_analysis(result)
		fallback_result["llm_error"] = analysis_result.get("error", "未知错误")
		_last_analysis_result = fallback_result
		analysis_completed.emit(fallback_result)
		return fallback_result

	_last_analysis_result = analysis_result

	if bool(analysis_result.get("ok", false)):
		analysis_completed.emit(analysis_result)
	else:
		analysis_failed.emit(str(analysis_result.get("error", "LLM请求失败")))

	return analysis_result


func analyze_in_progress(result: Dictionary) -> void:
	if not is_llm_enabled():
		return

	if _is_requesting:
		return

	_is_requesting = true

	var prompt := _build_in_progress_prompt(result)
	var analysis_result: Dictionary = await _request_llm_analysis(prompt)

	_is_requesting = false

	if bool(analysis_result.get("ok", false)):
		_last_analysis_result = analysis_result
		analysis_completed.emit(analysis_result)
	else:
		analysis_failed.emit(str(analysis_result.get("error", "LLM请求失败")))


func get_last_analysis() -> Dictionary:
	return _last_analysis_result.duplicate(true)


func analyze_recent_battles(records: Array) -> Dictionary:
	if records.is_empty():
		return {"ok": false, "error": "没有战斗记录"}

	if not is_llm_enabled():
		var fallback := _generate_fallback_history_analysis(records)
		history_analysis_completed.emit(fallback)
		return fallback

	if _is_requesting:
		return _last_analysis_result

	_is_requesting = true

	var prompt := _build_history_analysis_prompt(records)
	var analysis_result: Dictionary = await _request_llm_analysis(prompt)

	_is_requesting = false

	if not bool(analysis_result.get("ok", false)) and bool(_llm_config.get("fallback_on_error", true)):
		if bool(_llm_config.get("debug_log", false)):
			print_debug("LLM历史分析请求失败，回退到fallback：", analysis_result.get("error", "未知错误"))
		var fallback_result := _generate_fallback_history_analysis(records)
		fallback_result["llm_error"] = analysis_result.get("error", "未知错误")
		history_analysis_completed.emit(fallback_result)
		return fallback_result

	if bool(analysis_result.get("ok", false)):
		history_analysis_completed.emit(analysis_result)
	else:
		history_analysis_failed.emit(str(analysis_result.get("error", "LLM请求失败")))

	return analysis_result


func reset_analysis() -> void:
	_last_analysis_result = {}
	_is_requesting = false


func _load_llm_config() -> Dictionary:
	if not FileAccess.file_exists(LLM_CONFIG_PATH):
		return _get_default_config()

	var raw_text := FileAccess.get_file_as_string(LLM_CONFIG_PATH)
	var parsed = JSON.parse_string(raw_text)
	if parsed is Dictionary:
		return parsed
	return _get_default_config()


func _get_default_config() -> Dictionary:
	return {
		"enabled": true,
		"api_base": "https://api.openai.com/v1",
		"model": "gpt-4o-mini",
		"timeout_ms": 8000,
		"max_tokens": 500,
		"temperature": 0.7,
		"fallback_on_error": true,
		"debug_log": true,
	}


func _build_battle_analysis_prompt(result: Dictionary) -> String:
	var success := bool(result.get("success", false))
	var accuracy := float(result.get("accuracy", 0.0)) * 100.0
	var effective_accuracy := float(result.get("effective_accuracy", result.get("accuracy", 0.0))) * 100.0
	var hit_count := int(result.get("hit_count", 0))
	var shot_count := int(result.get("shot_count", 0))
	var tactical_shot_count := int(result.get("tactical_shot_count", 0))
	var attack_shot_count := int(result.get("attack_shot_count", shot_count))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var scan_used := int(result.get("scan_used", 0))
	var time_extend_used := int(result.get("time_extend_used", 0))
	var elapsed_time := float(result.get("elapsed_time", 0.0))
	var level_name := str(result.get("level_name", "未知关卡"))
	var level_id := int(result.get("level_id", 1))
	var rating := str(result.get("rating", {}).get("grade", "-"))
	var reward_gold := int(result.get("reward_gold", 0))

	var weapon_profile = CoreGameState.get_weapon_profile()
	var stability_level := CoreGameState.get_upgrade_level("stability")
	var zoom_level := CoreGameState.get_upgrade_level("zoom")
	var spread_idle := float(weapon_profile.get("spread_idle", 34.0))
	var spread_hold := float(weapon_profile.get("spread_hold", 10.0))
	var zoom_max := float(weapon_profile.get("zoom_max", 2.2))

	var lines: PackedStringArray
	lines.append("你是一个专业的射击游戏战术分析师，同时也是一名资深枪械教练。请根据以下玩家战斗数据，生成一份个性化的评价和成长建议。")
	lines.append("")
	lines.append("【重要说明】")
	lines.append("- 游戏中玩家可以射击障碍物来获取视野，这属于战术射击，是正常的策略行为")
	lines.append("- 有效命中率 = 命中数 / (总射击数 - 战术射击数)，更能反映玩家的真实枪法水平")
	lines.append("- 评价玩家枪法时请主要参考有效命中率，而不是原始命中率")
	lines.append("- 战术射击多说明玩家有战术意识，是优点，不要当成缺点")
	lines.append("")
	lines.append("【战斗结果】")
	lines.append("- 通关状态：%s" % ["成功" if success else "失败"])
	lines.append("- 关卡：%s（第%d关）" % [level_name, level_id])
	lines.append("- 评级：%s" % rating)
	lines.append("- 本局金币：+%d" % reward_gold)
	lines.append("")
	lines.append("【核心数据】")
	lines.append("- 有效命中率：%.1f%%（更能反映真实枪法）" % effective_accuracy)
	lines.append("- 原始命中率：%.1f%%" % accuracy)
	lines.append("- 命中/攻击射击：%d/%d" % [hit_count, attack_shot_count])
	lines.append("- 战术射击（清障等）：%d次" % tactical_shot_count)
	lines.append("- 总射击数：%d" % shot_count)
	lines.append("- 误伤次数：%d" % wrong_hit_count)
	lines.append("- 扫描使用：%d次" % scan_used)
	lines.append("- 时间延长：%d次" % time_extend_used)
	lines.append("- 存活时长：%.1fs" % elapsed_time)
	lines.append("")
	lines.append("【武器配置】")
	lines.append("- 稳定性等级：%d（待机散布%.1f，屏息散布%.1f）" % [stability_level, spread_idle, spread_hold])
	lines.append("- 缩放倍率等级：%d（最大缩放%.1fx）" % [zoom_level, zoom_max])
	lines.append("")
	lines.append("【升级说明】")
	lines.append("- stability：稳定性升级，降低准星晃动，提高命中率")
	lines.append("- zoom：缩放倍率升级，看得更远，更容易识别目标")
	lines.append("")
	lines.append("请按照以下JSON格式返回结果，不要包含任何额外文字：")
	lines.append("{")
	lines.append('  "title": "简短的评价标题（不超过10个字，要有个性）",')
	lines.append('  "comment": "详细的评价（80-100字，口语化、有针对性、结合具体数据）",')
	lines.append('  "strengths": ["优点1", "优点2"],')
	lines.append('  "weaknesses": ["缺点1", "缺点2"],')
	lines.append('  "suggestion": "一条具体的改进建议（要具体、可操作）",')
	lines.append('  "recommended_upgrade": "stability或zoom或空字符串，根据玩家数据推荐最应该升级的属性"')
	lines.append("}")
	lines.append("")
	lines.append("要求：")
	lines.append("1. 评价要真实，失败时不要给虚假的正面评价，但语气不要太打击人")
	lines.append('2. 建议要具体，结合玩家的实际数据，比如"你的有效命中率只有35%，建议先升级稳定性"')
	lines.append("3. 语气要像资深教练，专业但亲切，不要太生硬")
	lines.append("4. 如果数据不足，不要编造信息")
	lines.append("5. strengths和weaknesses最多各2-3条，要精不要多")
	lines.append("6. 如果战术射击较多且表现好，可以作为优点提及，说明玩家有战术意识")
	lines.append("7. recommended_upgrade：如果误伤多或有效命中率低推荐stability；如果用了很多扫描道具推荐zoom；如果表现很好可以空字符串")

	return "\n".join(lines)


func _build_in_progress_prompt(result: Dictionary) -> String:
	var hit_count := int(result.get("hit_count", 0))
	var shot_count := int(result.get("shot_count", 0))
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var elapsed_time := float(result.get("elapsed_time", 0.0))
	var remaining_time := float(result.get("remaining_time", 0.0))
	var remaining_targets := int(result.get("remaining_targets", 0))

	var lines: PackedStringArray
	lines.append("你是一个射击游戏实时战术顾问。请根据以下玩家当前战斗数据，给出简短的实时建议。")
	lines.append("")
	lines.append("【当前状态】")
	lines.append("- 已命中：%d" % hit_count)
	lines.append("- 已射击：%d" % shot_count)
	lines.append("- 误伤次数：%d" % wrong_hit_count)
	lines.append("- 已用时：%.1fs" % elapsed_time)
	lines.append("- 剩余时间：%.1fs" % remaining_time)
	lines.append("- 剩余目标：%d" % remaining_targets)
	lines.append("")
	lines.append("请按照以下JSON格式返回结果：")
	lines.append("{")
	lines.append('  "advice": "简短的实时建议（30字以内）",')
	lines.append('  "warning": "需要注意的问题（如果没有则为空字符串）"')
	lines.append("}")

	return "\n".join(lines)


func _build_history_analysis_prompt(records: Array) -> String:
	var lines: PackedStringArray
	lines.append("你是一个专业的射击游戏战术分析师，同时也是一名资深枪械教练。请根据以下玩家最近的战斗记录，生成一份综合评价和成长建议。")
	lines.append("")
	lines.append("【重要说明】")
	lines.append("- 游戏中玩家可以射击障碍物来获取视野，这属于战术射击，是正常的策略行为")
	lines.append("- 有效命中率 = 命中数 / (总射击数 - 战术射击数)，更能反映玩家的真实枪法水平")
	lines.append("- 评价玩家枪法时请主要参考有效命中率，而不是原始命中率")
	lines.append("- 战术射击多说明玩家有战术意识，是优点，不要当成缺点")
	lines.append("")
	lines.append("【最近%d场战斗记录】" % records.size())
	for i in range(records.size()):
		var rec: Dictionary = records[i]
		var idx := i + 1
		var success := bool(rec.get("success", false))
		var level_name := str(rec.get("level_name", "未知关卡"))
		var level_id := int(rec.get("level_id", 1))
		var accuracy := float(rec.get("accuracy", 0.0)) * 100.0
		var effective_accuracy := float(rec.get("effective_accuracy", rec.get("accuracy", 0.0))) * 100.0
		var hit_count := int(rec.get("hit_count", 0))
		var shot_count := int(rec.get("shot_count", 0))
		var tactical_shot_count := int(rec.get("tactical_shot_count", 0))
		var attack_shot_count := int(rec.get("attack_shot_count", shot_count))
		var wrong_hit_count := int(rec.get("wrong_hit_count", 0))
		var scan_used := int(rec.get("scan_used", 0))
		var time_extend_used := int(rec.get("time_extend_used", 0))
		var elapsed_time := float(rec.get("elapsed_time", 0.0))
		var rating_grade := str(rec.get("rating_grade", "-"))
		var reward_gold := int(rec.get("reward_gold", 0))

		lines.append("--- 第%d场 ---" % idx)
		lines.append("- 关卡：%s（第%d关）" % [level_name, level_id])
		lines.append("- 结果：%s，评级：%s" % ["胜利" if success else "失败", rating_grade])
		lines.append("- 有效命中率：%.1f%%（%d/%d攻击射击）" % [effective_accuracy, hit_count, attack_shot_count])
		lines.append("- 原始命中率：%.1f%%，战术射击：%d次" % [accuracy, tactical_shot_count])
		lines.append("- 误伤：%d次，扫描：%d次，时间延长：%d次" % [wrong_hit_count, scan_used, time_extend_used])
		lines.append("- 用时：%.1fs，获得金币：+%d" % [elapsed_time, reward_gold])
		lines.append("")

	var weapon_profile = CoreGameState.get_weapon_profile()
	var stability_level := CoreGameState.get_upgrade_level("stability")
	var zoom_level := CoreGameState.get_upgrade_level("zoom")
	var spread_idle := float(weapon_profile.get("spread_idle", 34.0))
	var spread_hold := float(weapon_profile.get("spread_hold", 10.0))
	var zoom_max := float(weapon_profile.get("zoom_max", 2.2))

	lines.append("【当前武器配置】")
	lines.append("- 稳定性等级：%d（待机散布%.1f，屏息散布%.1f）" % [stability_level, spread_idle, spread_hold])
	lines.append("- 缩放倍率等级：%d（最大缩放%.1fx）" % [zoom_level, zoom_max])
	lines.append("")
	lines.append("【升级说明】")
	lines.append("- stability：稳定性升级，降低准星晃动，提高命中率")
	lines.append("- zoom：缩放倍率升级，看得更远，更容易识别目标")
	lines.append("")
	lines.append("请按照以下JSON格式返回结果，不要包含任何额外文字：")
	lines.append("{")
	lines.append('  "title": "综合评价标题（不超过12个字，要有个性）",')
	lines.append('  "overall_comment": "综合评价（80-120字，结合多场数据，分析趋势）",')
	lines.append('  "trend": "上升/下降/波动/稳定，描述玩家近期状态趋势",')
	lines.append('  "strengths": ["优点1", "优点2"],')
	lines.append('  "weaknesses": ["缺点1", "缺点2"],')
	lines.append('  "suggestion": "一条核心改进建议（要具体、可操作）",')
	lines.append('  "recommended_upgrade": "stability或zoom或空字符串",')
	lines.append('  "battle_tags": ["标签1", "标签2", "标签3"]')
	lines.append("}")
	lines.append("")
	lines.append("要求：")
	lines.append("1. 综合评价要结合多场战斗，分析趋势和模式，不要只看单场")
	lines.append("2. 如果胜率高，要肯定进步；如果连败，要给鼓励和具体改进方向")
	lines.append("3. 语气要像资深教练，专业但亲切，不要太生硬")
	lines.append("4. strengths和weaknesses最多各2-3条，要精不要多")
	lines.append('5. battle_tags：3个左右能概括玩家特点的标签，比如"精准射手"、"战术意识强"、"误伤警告"等')
	lines.append("6. recommended_upgrade：根据多场数据综合推荐")
	lines.append("7. 如果玩家战术射击多且表现好，可以作为优点，说明有战术头脑")

	return "\n".join(lines)


func _request_llm_analysis(prompt: String) -> Dictionary:
	if bool(_llm_config.get("use_platform_adapter", true)):
		if bool(_llm_config.get("debug_log", false)):
			print_debug("LLM: 使用平台适配器调用")
		var success: bool = false
		var result: Dictionary = {}
		var platform_response: Array = await _call_platform_llm(prompt)
		success = bool(platform_response[0]) if platform_response.size() > 0 else false
		result = platform_response[1] if platform_response.size() > 1 and platform_response[1] is Dictionary else {}
		if success:
			return _parse_llm_result(result)
		if bool(_llm_config.get("debug_log", false)):
			print_debug("LLM: 平台适配器调用失败，尝试直接HTTP调用")

	if bool(_llm_config.get("debug_log", false)):
		print_debug("LLM: 使用直接HTTP调用")
	return await _request_direct_llm(prompt)


func _call_platform_llm(prompt: String):
	if PlatformService == null:
		return [false, {}]
	var result: Dictionary = await PlatformService.request_llm_analysis(prompt)
	return [bool(result.get("ok", false)), result]


func _request_direct_llm(prompt: String) -> Dictionary:
	if not is_llm_enabled():
		return {"ok": false, "error": "LLM未启用"}

	var provider := str(_llm_config.get("provider", "openai"))
	var timeout_ms := int(_llm_config.get("timeout_ms", 8000))
	var max_tokens := int(_llm_config.get("max_tokens", 500))
	var temperature := float(_llm_config.get("temperature", 0.7))

	var url: String
	var headers: PackedStringArray
	var body_str: String
	var body_dict: Dictionary

	if provider == "local_proxy":
		var proxy_base := str(_llm_config.get("proxy_base", "http://127.0.0.1:5000/api/llm"))
		var chat_path := str(_llm_config.get("chat_path", "/chat"))
		if proxy_base.ends_with("/") and chat_path.begins_with("/"):
			url = proxy_base + chat_path.substr(1)
		elif not proxy_base.ends_with("/") and not chat_path.begins_with("/"):
			url = proxy_base + "/" + chat_path
		else:
			url = proxy_base + chat_path

		headers = PackedStringArray([
			"Content-Type: application/json",
		])
		body_dict = {
			"messages": [
				{"role": "system", "content": "你是一个专业的射击游戏战术分析师，擅长根据数据给出精准的评价和建议。"},
				{"role": "user", "content": prompt},
			],
			"max_tokens": max_tokens,
			"temperature": temperature,
			"response_format": {"type": "json_object"},
		}
		body_str = JSON.stringify(body_dict)
	else:
		var api_base := str(_llm_config.get("api_base", "https://api.openai.com/v1"))
		var model := str(_llm_config.get("model", "gpt-4o-mini"))
		var api_key := str(_llm_config.get("api_key", ""))
		var chat_path := str(_llm_config.get("chat_path", "/chat/completions"))

		headers = PackedStringArray([
			"Content-Type: application/json",
		])
		if not api_key.is_empty():
			headers.append("Authorization: Bearer %s" % api_key)

		body_dict = {
			"model": model,
			"messages": [
				{"role": "system", "content": "你是一个专业的射击游戏战术分析师，擅长根据数据给出精准的评价和建议。"},
				{"role": "user", "content": prompt},
			],
			"max_tokens": max_tokens,
			"temperature": temperature,
			"response_format": {"type": "json_object"},
		}
		body_str = JSON.stringify(body_dict)

		if chat_path.begins_with("http"):
			url = chat_path
		else:
			if api_base.ends_with("/") and chat_path.begins_with("/"):
				url = api_base + chat_path.substr(1)
			elif not api_base.ends_with("/") and not chat_path.begins_with("/"):
				url = api_base + "/" + chat_path
			else:
				url = api_base + chat_path

	if bool(_llm_config.get("debug_log", false)):
		print_debug("LLM URL: ", url)
		print_debug("LLM Provider: ", provider)

	var http_request := HTTPRequest.new()
	http_request.timeout = timeout_ms / 1000.0
	http_request.accept_gzip = true
	add_child(http_request)

	var err := http_request.request(url, headers, HTTPClient.METHOD_POST, body_str)
	if err != OK:
		http_request.queue_free()
		return {"ok": false, "error": "请求发起失败：%d" % err}

	var result: Array = await http_request.request_completed
	var result_status: int = result[0]
	var response_code: int = result[1]
	var _response_headers: PackedStringArray = result[2]
	var response_body_packed: PackedByteArray = result[3]

	http_request.queue_free()

	var response_body := response_body_packed.get_string_from_utf8()

	if bool(_llm_config.get("debug_log", false)):
		print_debug("LLM Result Status: ", result_status)
		print_debug("LLM Response Code: ", response_code)
		print_debug("LLM Response: ", response_body.left(300))

	if result_status != HTTPRequest.RESULT_SUCCESS:
		var result_names: Array[String] = ["成功", "Chunked body size mismatch", "无法连接", "连接被拒绝", "GET请求错误", "SSL握手失败", "重定向不被允许", "超时", "请求已被重置", "TLS证书验证失败", "响应体解压失败", "响应体超限"]
		var err_name := String("未知错误")
		if result_status >= 0 and result_status < result_names.size():
			err_name = result_names[result_status]
		return {"ok": false, "error": "请求失败：%s（状态码：%d）" % [err_name, result_status]}

	if response_code != 200:
		var error_msg := "HTTP错误：%d" % response_code
		if not response_body.is_empty():
			error_msg += " - %s" % response_body.left(200)
		return {"ok": false, "error": error_msg}

	if provider == "local_proxy":
		return _parse_proxy_response(response_body)

	return _parse_llm_raw_response(response_body)


func _parse_proxy_response(response_body: String) -> Dictionary:
	var parsed = JSON.parse_string(response_body)
	if parsed == null:
		return {"ok": false, "error": "代理响应JSON解析异常"}
	if not (parsed is Dictionary):
		return {"ok": false, "error": "代理响应格式错误"}

	if not bool(parsed.get("ok", false)):
		return {"ok": false, "error": str(parsed.get("error", "代理请求失败"))}

	var content := str(parsed.get("content", ""))
	if content.is_empty():
		return {"ok": false, "error": "代理返回内容为空"}

	return _parse_llm_content(content)


func _parse_llm_raw_response(response_body: String) -> Dictionary:
	var parsed = JSON.parse_string(response_body)
	if parsed == null:
		return {"ok": false, "error": "JSON解析异常"}
	if parsed is Dictionary:
		var choices: Array = parsed.get("choices", [])
		if choices.size() > 0 and choices[0] is Dictionary:
			var content := str(choices[0].get("message", {}).get("content", ""))
			return _parse_llm_content(content)
	return {"ok": false, "error": "解析响应失败"}


func _parse_llm_result(result: Dictionary) -> Dictionary:
	if not bool(result.get("ok", false)):
		return result

	var content := str(result.get("content", ""))
	return _parse_llm_content(content)


func _parse_llm_content(content: String) -> Dictionary:
	var parsed = JSON.parse_string(content)
	if parsed == null:
		return {"ok": false, "error": "JSON解析异常", "raw_content": content}
	if parsed is Dictionary:
		return {
			"ok": true,
			"title": str(parsed.get("title", "")),
			"comment": str(parsed.get("comment", "")),
			"overall_comment": str(parsed.get("overall_comment", "")),
			"trend": str(parsed.get("trend", "")),
			"strengths": _parse_string_array(parsed.get("strengths", [])),
			"weaknesses": _parse_string_array(parsed.get("weaknesses", [])),
			"suggestion": str(parsed.get("suggestion", "")),
			"recommended_upgrade": str(parsed.get("recommended_upgrade", "")),
			"advice": str(parsed.get("advice", "")),
			"warning": str(parsed.get("warning", "")),
			"battle_tags": _parse_string_array(parsed.get("battle_tags", [])),
			"raw_content": content,
		}
	return {"ok": false, "error": "内容格式错误"}


func _parse_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _generate_fallback_analysis(result: Dictionary) -> Dictionary:
	var success := bool(result.get("success", false))
	var effective_accuracy := float(result.get("effective_accuracy", result.get("accuracy", 0.0))) * 100.0
	var wrong_hit_count := int(result.get("wrong_hit_count", 0))
	var hit_count := int(result.get("hit_count", 0))
	var shot_count := int(result.get("shot_count", 0))
	var tactical_shot_count := int(result.get("tactical_shot_count", 0))
	var scan_used := int(result.get("scan_used", 0))
	var _time_extend_used := int(result.get("time_extend_used", 0))

	var title := ""
	var comment := ""
	var strengths: Array[String] = []
	var weaknesses: Array[String] = []
	var suggestion := ""
	var recommended_upgrade := ""

	if tactical_shot_count > 0:
		strengths.append("有战术意识")

	if success:
		if effective_accuracy >= 90:
			title = "精准射手"
			comment = "你的有效命中率达到了%.0f%%，枪法相当精准！继续保持这种状态。" % effective_accuracy
			strengths.append("有效命中率高")
			strengths.append("精准度好")
			suggestion = "尝试挑战更高难度关卡"
			recommended_upgrade = ""
		elif effective_accuracy >= 70:
			title = "稳定发挥"
			comment = "表现不错，有效命中率%.0f%%处于良好水平。" % effective_accuracy
			strengths.append("发挥稳定")
			suggestion = "可以尝试减少道具依赖"
			if scan_used >= 2:
				recommended_upgrade = "zoom"
			else:
				recommended_upgrade = "stability"
		else:
			title = "勉强过关"
			comment = "虽然通关了，但有效命中率只有%.0f%%，还有提升空间。" % effective_accuracy
			strengths.append("成功通关")
			weaknesses.append("有效命中率偏低")
			suggestion = "提升稳定性来减少散布"
			recommended_upgrade = "stability"
	else:
		if wrong_hit_count >= 2:
			title = "误伤太多"
			comment = "任务失败了，误伤了%d次，准星晃动太大导致打偏。" % wrong_hit_count
			weaknesses.append("误伤太多")
			weaknesses.append("准星不稳")
			suggestion = "先提升稳定性，减少准星晃动"
			recommended_upgrade = "stability"
		elif effective_accuracy < 40 and shot_count >= 3:
			title = "命中困难"
			comment = "有效命中率只有%.0f%%，准星不稳导致打空太多。" % effective_accuracy
			weaknesses.append("有效命中率低")
			weaknesses.append("准星不稳")
			suggestion = "升级稳定性，先把枪稳住"
			recommended_upgrade = "stability"
		elif scan_used >= 2 and hit_count < 2:
			title = "观察不足"
			comment = "用了%d次扫描还是没找到足够目标，看得不够远。" % scan_used
			weaknesses.append("观察距离不足")
			suggestion = "提升缩放倍率，更早发现目标"
			recommended_upgrade = "zoom"
		else:
			title = "再接再厉"
			comment = "任务失败了，调整心态再来一次。注意观察目标特征，把握射击时机。"
			suggestion = "多练习基础瞄准，熟悉目标特征"
			recommended_upgrade = "stability"

	return {
		"ok": true,
		"title": title,
		"comment": comment,
		"strengths": strengths,
		"weaknesses": weaknesses,
		"suggestion": suggestion,
		"recommended_upgrade": recommended_upgrade,
		"fallback": true,
	}


func get_fallback_history_analysis(records: Array) -> Dictionary:
	return _generate_fallback_history_analysis(records)


func _generate_fallback_history_analysis(records: Array) -> Dictionary:
	var total_games := records.size()
	var wins := 0
	var total_effective_accuracy := 0.0
	var total_wrong_hits := 0
	var total_scan_used := 0
	var total_tactical_shots := 0
	var total_reward := 0
	var valid_accuracy_count := 0
	var recent_trend := "稳定"

	for i in range(total_games):
		var rec: Dictionary = records[i]
		if bool(rec.get("success", false)):
			wins += 1
		var shot_count_val := int(rec.get("shot_count", 0))
		if shot_count_val > 0:
			total_effective_accuracy += float(rec.get("effective_accuracy", rec.get("accuracy", 0.0)))
			valid_accuracy_count += 1
		total_wrong_hits += int(rec.get("wrong_hit_count", 0))
		total_scan_used += int(rec.get("scan_used", 0))
		total_tactical_shots += int(rec.get("tactical_shot_count", 0))
		total_reward += int(rec.get("reward_gold", 0))

	var win_rate := float(wins) / float(total_games) * 100.0 if total_games > 0 else 0.0
	var avg_effective_accuracy := (total_effective_accuracy / float(valid_accuracy_count) * 100.0) if valid_accuracy_count > 0 else 0.0
	var avg_wrong_hits := float(total_wrong_hits) / float(total_games) if total_games > 0 else 0.0
	var avg_scan_used := float(total_scan_used) / float(total_games) if total_games > 0 else 0.0
	var avg_tactical_shots := float(total_tactical_shots) / float(total_games) if total_games > 0 else 0.0

	if total_games >= 3:
		var first_half_wins := 0
		var second_half_wins := 0
		var half := total_games / 2
		for i in range(half):
			if bool(records[i].get("success", false)):
				first_half_wins += 1
		for i in range(half, total_games):
			if bool(records[i].get("success", false)):
				second_half_wins += 1
		if second_half_wins > first_half_wins:
			recent_trend = "上升"
		elif second_half_wins < first_half_wins:
			recent_trend = "下降"
		else:
			recent_trend = "稳定"

	var title := ""
	var overall_comment := ""
	var strengths: Array[String] = []
	var weaknesses: Array[String] = []
	var suggestion := ""
	var recommended_upgrade := ""
	var battle_tags: Array[String] = []

	if avg_tactical_shots >= 2.0:
		strengths.append("有战术意识")
		battle_tags.append("战术派")

	if win_rate >= 80:
		title = "常胜将军"
		overall_comment = "最近%d场胜率%.0f%%，有效命中率%.1f%%，表现非常出色！继续保持这种状态，挑战更高难度。" % [total_games, win_rate, avg_effective_accuracy]
		strengths.append("胜率高")
		strengths.append("发挥稳定")
		battle_tags.append("精英射手")
		battle_tags.append("稳扎稳打")
		suggestion = "尝试挑战更高难度关卡，突破自我"
		recommended_upgrade = ""
	elif win_rate >= 50:
		title = "稳步前进"
		overall_comment = "最近%d场胜率%.0f%%，平均有效命中率%.1f%%，整体表现不错，还有提升空间。" % [total_games, win_rate, avg_effective_accuracy]
		strengths.append("有一定胜率")
		battle_tags.append("进步中")
		if avg_wrong_hits >= 1.0:
			weaknesses.append("误伤偏多")
			suggestion = "提升稳定性，减少误伤次数"
			recommended_upgrade = "stability"
			battle_tags.append("需稳准星")
		elif avg_scan_used >= 2.0:
			weaknesses.append("观察不足")
			suggestion = "提升缩放倍率，更早发现目标"
			recommended_upgrade = "zoom"
			battle_tags.append("需看得远")
		else:
			suggestion = "继续练习，提升综合能力"
			recommended_upgrade = "stability"
			battle_tags.append("潜力选手")
	else:
		title = "需要加油"
		overall_comment = "最近%d场胜率%.0f%%，还需要多加练习。不要灰心，找到问题针对性改进。" % [total_games, win_rate]
		battle_tags.append("新手期")
		if avg_wrong_hits >= 1.5:
			weaknesses.append("误伤太多")
			weaknesses.append("准星不稳")
			suggestion = "先升级稳定性，把准星稳住再谈其他"
			recommended_upgrade = "stability"
			battle_tags.append("误伤警告")
		elif avg_effective_accuracy < 50:
			weaknesses.append("有效命中率低")
			suggestion = "多练习瞄准，升级稳定性减少散布"
			recommended_upgrade = "stability"
			battle_tags.append("需要瞄准")
		elif avg_scan_used >= 2:
			weaknesses.append("观察距离不足")
			suggestion = "升级缩放倍率，更容易发现目标"
			recommended_upgrade = "zoom"
			battle_tags.append("视野有限")
		else:
			weaknesses.append("综合能力待提升")
			suggestion = "多玩多练，熟悉游戏节奏"
			recommended_upgrade = "stability"
			battle_tags.append("加油练习")

	return {
		"ok": true,
		"title": title,
		"overall_comment": overall_comment,
		"trend": recent_trend,
		"strengths": strengths,
		"weaknesses": weaknesses,
		"suggestion": suggestion,
		"recommended_upgrade": recommended_upgrade,
		"battle_tags": battle_tags,
		"fallback": true,
	}


func get_analysis_template() -> Dictionary:
	return {
		"title": "",
		"comment": "",
		"overall_comment": "",
		"trend": "",
		"strengths": [],
		"weaknesses": [],
		"suggestion": "",
		"advice": "",
		"warning": "",
		"recommended_upgrade": "",
		"battle_tags": [],
	}
