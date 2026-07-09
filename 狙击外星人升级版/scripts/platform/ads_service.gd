extends Node


func show_rewarded_ad(placement: String) -> Dictionary:
    return {
        "ok": true,
        "placement": placement,
        "message": "ads_service 占位成功",
    }
