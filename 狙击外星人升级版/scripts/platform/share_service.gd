extends Node


func share(payload: Dictionary = {}) -> Dictionary:
    return {
        "ok": true,
        "payload": payload,
    }
