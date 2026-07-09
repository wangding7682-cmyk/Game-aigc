extends "res://scripts/platform/platform_adapter_base.gd"

const REWARDED_AD_MODES := ["success", "fail"]

var _rewarded_ad_mode_index := 0


func get_platform_name() -> String:
    return "mock_desktop"


func is_mock_runtime() -> bool:
    return true


func supports_debug_controls() -> bool:
    return true


func build_status_summary() -> String:
    return "平台：%s | 调试广告结果：%s" % [
        get_platform_name(),
        get_rewarded_ad_mode_name(),
    ]


func request_login() -> Dictionary:
    return {
        "ok": true,
        "platform": get_platform_name(),
        "user_id": "mock_user_001",
        "nickname": "MockSniper",
        "needBackendExchange": false,
    }


func init_share_menu() -> Dictionary:
    return {
        "ok": true,
        "platform": get_platform_name(),
        "message": "桌面 mock 无需初始化分享菜单",
    }


func open_share(payload: Dictionary = {}) -> Dictionary:
    return {
        "ok": true,
        "platform": get_platform_name(),
        "accepted": true,
        "payload": payload.duplicate(true),
        "message": "桌面 mock 已模拟分享成功",
    }


func is_rewarded_ad_available() -> bool:
    return true


func show_rewarded_ad(placement: String) -> Dictionary:
    await Engine.get_main_loop().create_timer(1.0).timeout
    var current_mode: String = str(REWARDED_AD_MODES[_rewarded_ad_mode_index])
    if current_mode == "success":
        return {
            "ok": true,
            "platform": get_platform_name(),
            "placement": placement,
            "completed": true,
            "message": "mock rewarded ad success",
        }
    return {
        "ok": false,
        "platform": get_platform_name(),
        "placement": placement,
        "completed": false,
        "reason": "mock_failed",
        "message": "mock rewarded ad failed",
    }


func get_rewarded_ad_mode_name() -> String:
    return "成功" if REWARDED_AD_MODES[_rewarded_ad_mode_index] == "success" else "失败"


func cycle_rewarded_ad_mode() -> String:
    _rewarded_ad_mode_index = (_rewarded_ad_mode_index + 1) % REWARDED_AD_MODES.size()
    return get_rewarded_ad_mode_name()


func request_llm_analysis(_prompt: String) -> Dictionary:
    await Engine.get_main_loop().create_timer(0.8).timeout
    var mock_responses := [
        {
            "title": "精准射手",
            "comment": "你的命中率达到了85%，枪法相当精准！但使用了2次扫描道具，说明你在远距离目标识别上还有提升空间。",
            "strengths": ["命中率高", "射击稳定"],
            "weaknesses": ["道具依赖"],
            "suggestion": "提升缩放倍率，可以更早发现目标，减少扫描使用",
            "recommended_upgrade": "zoom"
        },
        {
            "title": "稳中有升",
            "comment": "表现不错，成功通关！零误伤是你的亮点，但射击次数略多，说明有时会犹豫。",
            "strengths": ["零误伤", "成功通关"],
            "weaknesses": ["射击效率"],
            "suggestion": "提升稳定性，一次瞄准就能命中，减少不必要的射击",
            "recommended_upgrade": "stability"
        },
        {
            "title": "需要练习",
            "comment": "任务失败了，命中率只有35%，准星晃动太大导致打空。先把枪稳住再说。",
            "strengths": [],
            "weaknesses": ["命中率低", "准星不稳"],
            "suggestion": "升级稳定性，减少待机散布，让准星更稳",
            "recommended_upgrade": "stability"
        },
        {
            "title": "完美表现",
            "comment": "完美通关！零误伤、高命中、无道具，你已经掌握了这款游戏的精髓。",
            "strengths": ["零误伤", "高命中", "无道具"],
            "weaknesses": [],
            "suggestion": "挑战更高难度，看看你的极限在哪里",
            "recommended_upgrade": ""
        },
    ]
    var random_index := randi_range(0, mock_responses.size() - 1)
    return {
        "ok": true,
        "platform": get_platform_name(),
        "content": JSON.stringify(mock_responses[random_index]),
        "message": "mock LLM analysis success",
    }
