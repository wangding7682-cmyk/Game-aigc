extends RefCounted

const InputBootstrap = preload("res://scripts/core/core_input_bootstrap.gd")


static func ensure_project_input_map() -> void:
    InputBootstrap.ensure_default_input_map()
