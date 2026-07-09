extends Node


func log_event(event_name: String, payload: Dictionary = {}) -> void:
    track_event(event_name, payload)


func track_event(event_name: String, payload: Dictionary = {}) -> void:
    # 目标：在 mock 阶段保证“埋点不会阻塞主流程”，同时可本地回看。
    # 输出策略：
    # 1) 控制台打印（便于联调）
    # 2) 追加写入 user://analytics_events.jsonl（便于批量分析）
    var record := {
        "ts_unix": Time.get_unix_time_from_system(),
        "event": event_name,
        "payload": payload.duplicate(true),
    }

    print("[Analytics] %s %s" % [event_name, JSON.stringify(payload)])

    var log_path := "user://analytics_events.jsonl"
    if has_node("/root/PlatformService"):
        log_path = PlatformService.get_analytics_log_path()

    var file: FileAccess = null
    if FileAccess.file_exists(log_path):
        file = FileAccess.open(log_path, FileAccess.READ_WRITE)
        if file != null:
            file.seek_end()
    else:
        file = FileAccess.open(log_path, FileAccess.WRITE)

    if file == null:
        push_warning("AnalyticsService：无法写入埋点日志 %s" % log_path)
        return

    file.store_line(JSON.stringify(record))
