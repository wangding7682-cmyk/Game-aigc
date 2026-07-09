extends Node3D
class_name PveTargetController3D

const TEX_ALIEN_DISGUISED_IDLE := preload("res://assets_mvp_placeholder/characters/alien-disguised-idle.svg")
const TEX_ALIEN_MOVING_PROFILE := preload("res://assets_mvp_placeholder/characters/alien-moving-profile.svg")
const TEX_ALIEN_SCAN_HIGHLIGHT := preload("res://assets_mvp_placeholder/characters/alien-scan-highlight.svg")
const TEX_ALIEN_WEAKPOINT_OPEN := preload("res://assets_mvp_placeholder/characters/alien-weakpoint-open.svg")
const TEX_CIVILIAN_CALM_IDLE := preload("res://assets_mvp_placeholder/characters/civilian-calm-idle.svg")
const TEX_CIVILIAN_FALSE_CLUE := preload("res://assets_mvp_placeholder/characters/civilian-false-clue-glint.svg")
const TEX_ACTOR_FABRIC_BREAKUP_PATH := "res://assets_mvp_placeholder/materials/material-actor-fabric-breakup.svg"
const SCENE_ALIEN_WOMEN_01 := preload("res://assets_mvp_3d/characters/allien-product-women1.glb")
const SCENE_ALIEN_WOMEN_02 := preload("res://assets_mvp_3d/characters/allien-product-women2.glb")
const SCENE_WOMEN_ACTION_01 := preload("res://assets_mvp_3d/women_action1.fbx")
const SCENE_WOMEN_ACTION_02 := preload("res://assets_mvp_3d/women_action2.fbx")
const SCENE_ALIEN_BASE := preload("res://assets_mvp_3d/characters/alien_base_placeholder.glb")
const SCENE_ALIEN_COSTUME := preload("res://assets_mvp_3d/characters/alien_costume_placeholder.glb")

var actor_kind: String = "target" # "target" or "civilian"
var behavior_type: String = "static"
var alive := true
var body_radius: float = 0.6
var disguise_strength: float = 1.0
var tutorial_primary := false

var suspicion_tier := 0
var clue_profile: Array[String] = []

var highlighted_until := 0.0

var false_clue_profile: Array[String] = []
var false_clue_active := false
var false_clue_until := 0.0
var false_clue_cycle_sec := 0.0
var false_clue_window_sec := 0.0

var search_signal_strength := 0.0
var scan_burst_until := 0.0
var scan_burst_strength := 0.0

var move_range := 2.0
var move_speed := 0.9
var reveal_cycle_sec := 6.8
var reveal_window_sec := 1.65
var origin_position: Vector3 = Vector3.ZERO
var phase_offset := 0.0

var mesh: MeshInstance3D
var body: StaticBody3D
var collider: CollisionShape3D
var material := StandardMaterial3D.new()
var mesh_root: Node3D
var costume_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var shoulder_left_mesh: MeshInstance3D
var shoulder_right_mesh: MeshInstance3D
var eye_left_mesh: MeshInstance3D
var eye_right_mesh: MeshInstance3D
var upper_arm_left_mesh: MeshInstance3D
var upper_arm_right_mesh: MeshInstance3D
var forearm_left_mesh: MeshInstance3D
var forearm_right_mesh: MeshInstance3D
var leg_left_mesh: MeshInstance3D
var leg_right_mesh: MeshInstance3D
var foot_left_mesh: MeshInstance3D
var foot_right_mesh: MeshInstance3D
var weakpoint_mesh: MeshInstance3D
var core_mesh: MeshInstance3D
var halo_mesh: MeshInstance3D
var accent_mesh: MeshInstance3D
var costume_overlay_mesh: MeshInstance3D
var accent_overlay_mesh: MeshInstance3D
var billboard_root: Node3D
var main_billboard: MeshInstance3D
var overlay_billboard: MeshInstance3D
var imported_visual_root: Node3D
var main_billboard_material := StandardMaterial3D.new()
var overlay_billboard_material := StandardMaterial3D.new()
var costume_material := StandardMaterial3D.new()
var head_material := StandardMaterial3D.new()
var limb_material := StandardMaterial3D.new()
var accent_material := StandardMaterial3D.new()
var weakpoint_material := StandardMaterial3D.new()
var core_material := StandardMaterial3D.new()
var halo_material := StandardMaterial3D.new()
var eye_left_material := StandardMaterial3D.new()
var eye_right_material := StandardMaterial3D.new()
var costume_overlay_material := StandardMaterial3D.new()
var accent_overlay_material := StandardMaterial3D.new()
var health_bar_root: Node3D
var health_bar_segments: Array[MeshInstance3D] = []
var imported_pose_cache: Dictionary = {}
var actor_fabric_texture: Texture2D
var imported_primary_mesh: MeshInstance3D
var imported_generic_actor := false
var imported_visual_bounds := AABB(Vector3(-0.3, 0.0, -0.2), Vector3(0.6, 1.8, 0.4))
var women_action_enabled := false
var women_action_scene_key := 0
var women_action_range := 0.0
var women_action_speed := 0.0
var women_action_orbit_radius := 0.0
var women_action_orbit_direction := 1.0
var women_action_avoid_direction := 0.0
var women_action_avoid_until := 0.0
var women_action_facing_y := 0.0
var max_hit_points := 1
var current_hit_points := 1
var imported_animation_player: AnimationPlayer
var imported_animation_name := ""
var occlusion_hint_root: Node3D
var occlusion_hint_mesh: MeshInstance3D
var occlusion_hint_glow_mesh: MeshInstance3D
var occlusion_hint_head_mesh: MeshInstance3D
var occlusion_hint_shoulder_mesh: MeshInstance3D
var occlusion_hint_hip_mesh: MeshInstance3D
var occlusion_hint_leg_left_mesh: MeshInstance3D
var occlusion_hint_leg_right_mesh: MeshInstance3D
var occlusion_hint_arm_left_mesh: MeshInstance3D
var occlusion_hint_arm_right_mesh: MeshInstance3D
var occlusion_hint_material := StandardMaterial3D.new()
var occlusion_hint_glow_material := StandardMaterial3D.new()
var occlusion_hint_active := false
var occlusion_hint_strength := 0.0


func setup(kind: String, behavior: String, spawn_position: Vector3, random_seed: float, extra: Dictionary = {}) -> void:
	actor_kind = kind
	behavior_type = behavior
	origin_position = spawn_position
	position = spawn_position
	phase_offset = random_seed

	body_radius = float(extra.get("body_radius", body_radius))
	disguise_strength = float(extra.get("disguise_strength", disguise_strength))
	tutorial_primary = bool(extra.get("tutorial_primary", false))
	suspicion_tier = int(extra.get("suspicion_tier", 0))
	search_signal_strength = float(extra.get("search_signal_strength", 0.0))

	clue_profile.clear()
	for clue in extra.get("clue_profile", []):
		clue_profile.append(str(clue))

	false_clue_profile.clear()
	for clue in extra.get("false_clue_profile", []):
		false_clue_profile.append(str(clue))
	false_clue_cycle_sec = float(extra.get("false_clue_cycle_sec", 0.0))
	false_clue_window_sec = float(extra.get("false_clue_window_sec", 0.0))

	move_range = float(extra.get("move_range", move_range))
	move_speed = float(extra.get("move_speed", move_speed))
	reveal_cycle_sec = float(extra.get("reveal_cycle_sec", reveal_cycle_sec))
	reveal_window_sec = float(extra.get("reveal_window_sec", reveal_window_sec))
	women_action_enabled = bool(extra.get("women_action_enabled", false))
	women_action_scene_key = int(extra.get("women_action_scene_key", 0))
	women_action_range = float(extra.get("women_action_range", 0.0))
	women_action_speed = float(extra.get("women_action_speed", 0.0))
	women_action_orbit_radius = clampf(Vector2(spawn_position.x, spawn_position.z).length(), 3.8, 8.6)
	women_action_orbit_direction = -1.0 if fmod(absf(random_seed) * 1.73, 2.0) > 1.0 else 1.0
	women_action_avoid_direction = 0.0
	women_action_avoid_until = 0.0
	women_action_facing_y = 0.0
	max_hit_points = int(extra.get("max_hit_points", 3 if actor_kind == "target" and women_action_enabled else 1))
	current_hit_points = max_hit_points

	_highlight_build()
	_update_visual()


func _highlight_build() -> void:
	if mesh != null:
		return

	body = StaticBody3D.new()
	body.name = "Body"
	body.position = Vector3(0.0, body_radius * 0.92, 0.0)
	add_child(body)

	mesh_root = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)

	if _try_build_imported_actor():
		if not imported_generic_actor:
			_ensure_surface_overlays()
			_build_billboards()
		_build_health_bar()
		body.set_meta("actor_node", self)
		body.set_meta("actor_kind", actor_kind)
		return

	var capsule := CapsuleMesh.new()
	capsule.radius = body_radius * 0.34
	capsule.height = body_radius * 1.25
	mesh = MeshInstance3D.new()
	mesh.name = "BodyMesh"
	mesh.mesh = capsule
	mesh.position = Vector3(0.0, body_radius * 0.92, 0.0)
	mesh_root.add_child(mesh)

	collider = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = capsule.radius
	shape.height = capsule.height
	collider.shape = shape
	body.add_child(collider)

	# collision layers: 1 obstacle, 2 target, 4 civilian
	body.collision_layer = 2 if actor_kind == "target" else 4
	body.collision_mask = 0

	material.albedo_color = Color(0.42, 0.95, 0.58) if actor_kind == "target" else Color(0.28, 0.58, 0.92)
	material.roughness = 0.65
	material.metallic = 0.0
	mesh.material_override = material

	var head_sphere := SphereMesh.new()
	head_sphere.radius = body_radius * 0.30
	head_sphere.height = body_radius * 0.60
	head_mesh = MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	head_mesh.mesh = head_sphere
	head_mesh.position = Vector3(0.0, body_radius * 1.72, 0.0)
	head_mesh.material_override = head_material
	mesh_root.add_child(head_mesh)

	var shoulder_box := BoxMesh.new()
	shoulder_box.size = Vector3(body_radius * 0.30, body_radius * 0.16, body_radius * 0.28)
	shoulder_left_mesh = MeshInstance3D.new()
	shoulder_left_mesh.name = "ShoulderLeft"
	shoulder_left_mesh.mesh = shoulder_box
	shoulder_left_mesh.position = Vector3(-body_radius * 0.42, body_radius * 1.20, 0.0)
	shoulder_left_mesh.material_override = accent_material
	mesh_root.add_child(shoulder_left_mesh)

	shoulder_right_mesh = MeshInstance3D.new()
	shoulder_right_mesh.name = "ShoulderRight"
	shoulder_right_mesh.mesh = shoulder_box
	shoulder_right_mesh.position = Vector3(body_radius * 0.42, body_radius * 1.20, 0.0)
	shoulder_right_mesh.material_override = accent_material
	mesh_root.add_child(shoulder_right_mesh)

	var eye_sphere := SphereMesh.new()
	eye_sphere.radius = body_radius * 0.055
	eye_sphere.height = body_radius * 0.11
	eye_left_mesh = MeshInstance3D.new()
	eye_left_mesh.name = "EyeLeft"
	eye_left_mesh.mesh = eye_sphere
	eye_left_mesh.position = Vector3(-body_radius * 0.10, body_radius * 1.75, body_radius * 0.24)
	eye_left_mesh.material_override = weakpoint_material
	mesh_root.add_child(eye_left_mesh)

	eye_right_mesh = MeshInstance3D.new()
	eye_right_mesh.name = "EyeRight"
	eye_right_mesh.mesh = eye_sphere
	eye_right_mesh.position = Vector3(body_radius * 0.10, body_radius * 1.75, body_radius * 0.24)
	eye_right_mesh.material_override = weakpoint_material
	mesh_root.add_child(eye_right_mesh)

	var costume_box := BoxMesh.new()
	costume_box.size = Vector3(body_radius * 0.82, body_radius * 1.05, body_radius * 0.46)
	costume_mesh = MeshInstance3D.new()
	costume_mesh.name = "CostumeMesh"
	costume_mesh.mesh = costume_box
	costume_mesh.position = Vector3(0.0, body_radius * 0.98, body_radius * -0.03)
	costume_mesh.material_override = costume_material
	mesh_root.add_child(costume_mesh)

	var accent_box := BoxMesh.new()
	accent_box.size = Vector3(body_radius * 0.20, body_radius * 0.54, body_radius * 0.20)
	accent_mesh = MeshInstance3D.new()
	accent_mesh.name = "AccentMesh"
	accent_mesh.mesh = accent_box
	accent_mesh.position = Vector3(body_radius * 0.30, body_radius * 1.02, body_radius * 0.18)
	accent_mesh.material_override = accent_material
	mesh_root.add_child(accent_mesh)

	var weak_sphere := SphereMesh.new()
	weak_sphere.radius = body_radius * 0.12
	weak_sphere.height = body_radius * 0.24
	weakpoint_mesh = MeshInstance3D.new()
	weakpoint_mesh.name = "WeakpointMesh"
	weakpoint_mesh.mesh = weak_sphere
	weakpoint_mesh.position = Vector3(0.0, body_radius * 1.16, body_radius * 0.30)
	weakpoint_mesh.material_override = weakpoint_material
	mesh_root.add_child(weakpoint_mesh)

	core_mesh = MeshInstance3D.new()
	core_mesh.name = "CoreMesh"
	core_mesh.mesh = weak_sphere
	core_mesh.position = Vector3(0.0, body_radius * 1.16, body_radius * 0.34)
	core_mesh.scale = Vector3.ONE * 0.42
	core_mesh.material_override = core_material
	mesh_root.add_child(core_mesh)

	var halo_capsule := CapsuleMesh.new()
	halo_capsule.radius = body_radius * 0.46
	halo_capsule.height = body_radius * 1.85
	halo_mesh = MeshInstance3D.new()
	halo_mesh.name = "HaloMesh"
	halo_mesh.mesh = halo_capsule
	halo_mesh.position = Vector3(0.0, body_radius * 1.04, 0.0)
	halo_mesh.material_override = halo_material
	mesh_root.add_child(halo_mesh)

	head_material.roughness = 0.72
	head_material.metallic = 0.0
	costume_material.roughness = 0.88
	costume_material.metallic = 0.0
	accent_material.roughness = 0.74
	accent_material.metallic = 0.0
	weakpoint_material.roughness = 0.25
	weakpoint_material.emission_enabled = true
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_material.emission_enabled = true
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_build_occlusion_hint()
	_ensure_surface_overlays()
	_build_billboards()
	_build_health_bar()

	# 标记给射线识别
	body.set_meta("actor_node", self)
	body.set_meta("actor_kind", actor_kind)


func _process(delta: float) -> void:
	if not alive:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var local_time := now + phase_offset
	_ensure_imported_animation_running()

	if actor_kind == "civilian" and false_clue_cycle_sec > 0.0 and false_clue_window_sec > 0.0:
		false_clue_active = fmod(local_time, false_clue_cycle_sec) <= false_clue_window_sec
	else:
		false_clue_active = false_clue_active and now <= false_clue_until

	if women_action_enabled:
		_update_women_action_motion(delta, now, local_time)
	elif behavior_type == "moving":
		global_position = origin_position
		mesh_root.rotation_degrees.z = 0.0
		mesh_root.rotation_degrees.y = sin(local_time * 0.8 + phase_offset) * 2.0
	else:
		mesh_root.rotation_degrees.z = 0.0
		mesh_root.rotation_degrees.y = 0.0

	_update_visual()


func _update_visual() -> void:
	if mesh == null:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var highlighted := now <= highlighted_until
	var scan_burst_active := now <= scan_burst_until
	var scan_burst_ratio := 0.0
	if scan_burst_active:
		scan_burst_ratio = clampf(scan_burst_strength * (0.55 + absf(sin(now * 18.0)) * 0.45), 0.0, 1.0)
	var weakpoint_open := _is_weakpoint_open(now)
	var target_pulse := (sin(now * 3.0) + 1.0) * 0.5
	var scan_pulse := (sin(now * 5.4) + 1.0) * 0.5
	var locomotion_pulse := sin(now * maxf(move_speed, 0.65) * 3.2 + phase_offset)
	var breathe_pulse := sin(now * 1.7 + phase_offset)

	if actor_kind == "target":
		if imported_generic_actor:
			_apply_target_generic_visual(highlighted, weakpoint_open, scan_burst_active, scan_burst_ratio, scan_pulse)
		else:
			_apply_target_women_visual(highlighted, weakpoint_open, scan_burst_active, scan_burst_ratio, scan_pulse, target_pulse)
	else:
		_apply_civilian_visual(highlighted, scan_burst_active, scan_burst_ratio, scan_pulse)

	var sway := sin(now * 1.8 + phase_offset) * 0.02
	if head_mesh != null:
		head_mesh.rotation_degrees.y = sway * 18.0
	if costume_mesh != null:
		costume_mesh.rotation_degrees.y = sway * 8.0
	if halo_mesh != null:
		halo_mesh.visible = highlighted or scan_burst_active
	_update_occlusion_hint(now, target_pulse, scan_pulse, highlighted, scan_burst_active)
	_apply_imported_action_pose(now, locomotion_pulse, breathe_pulse, highlighted, weakpoint_open)
	if not imported_generic_actor:
		_update_billboards(highlighted, weakpoint_open, target_pulse, scan_pulse, scan_burst_active, scan_burst_ratio)
	_update_health_bar(highlighted, scan_burst_active, target_pulse)


func is_weakpoint_active() -> bool:
	if actor_kind != "target":
		return false
	if tutorial_primary:
		return true
	if behavior_type != "weakpoint":
		return true
	if reveal_cycle_sec <= 0.0 or reveal_window_sec <= 0.0:
		return true
	var local_time: float = Time.get_ticks_msec() / 1000.0 + phase_offset
	return fmod(local_time, reveal_cycle_sec) <= reveal_window_sec


func _is_weakpoint_open(now: float) -> bool:
	if actor_kind != "target":
		return false
	if tutorial_primary:
		return true
	if behavior_type != "weakpoint":
		return false
	if reveal_cycle_sec <= 0.0 or reveal_window_sec <= 0.0:
		return false

	var local_time: float = now + phase_offset
	return fmod(local_time, reveal_cycle_sec) <= reveal_window_sec


func _get_rift_flicker_ratio() -> float:
	var t := Time.get_ticks_msec() / 1000.0
	var flicker_ratio := 0.18
	flicker_ratio += absf(sin(t * 7.5)) * 0.26
	flicker_ratio += absf(sin(t * 15.0 + 0.7)) * 0.24
	flicker_ratio += absf(sin(t * 29.0 + 1.3)) * 0.18
	if sin(t * 11.0 + 0.4) > 0.78:
		flicker_ratio += 0.34
	if sin(t * 23.0 + 1.1) > 0.88:
		flicker_ratio += 0.28
	return clampf(flicker_ratio, 0.0, 1.0)


func _apply_target_generic_visual(highlighted: bool, weakpoint_open: bool, scan_burst_active: bool, scan_burst_ratio: float, scan_pulse: float) -> void:
	var flicker_ratio := _get_rift_flicker_ratio()
	if weakpoint_mesh != null:
		weakpoint_mesh.visible = weakpoint_open
	if core_mesh != null:
		core_mesh.visible = false
	if halo_mesh != null:
		halo_mesh.visible = weakpoint_open or highlighted or scan_burst_active
	if costume_mesh != null:
		costume_mesh.visible = false
	if accent_mesh != null:
		accent_mesh.visible = true
	if shoulder_left_mesh != null:
		shoulder_left_mesh.visible = true
		shoulder_left_mesh.scale = Vector3(1.18, 1.0, 1.0)
	if shoulder_right_mesh != null:
		shoulder_right_mesh.visible = true
		shoulder_right_mesh.scale = Vector3(1.02, 1.0, 1.0)
	if head_mesh != null:
		head_mesh.visible = true
	if eye_left_mesh != null:
		eye_left_mesh.visible = true
	if eye_right_mesh != null:
		eye_right_mesh.visible = true
	if foot_left_mesh != null:
		foot_left_mesh.visible = true
	if foot_right_mesh != null:
		foot_right_mesh.visible = true

	head_material.albedo_color = Color(0.36, 0.10, 0.16).lerp(Color(0.60, 0.18, 0.24), scan_burst_ratio * 0.18)
	head_material.roughness = 0.54
	limb_material.albedo_color = Color(0.28, 0.08, 0.10).lerp(Color(0.64, 0.16, 0.18), 0.16 if weakpoint_open else 0.0)
	accent_material.albedo_color = Color(0.28, 0.76, 0.94).lerp(Color(0.70, 0.92, 1.0), scan_burst_ratio * 0.24)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.16, 0.72, 1.0) * (0.12 + 0.10 * scan_pulse + scan_burst_ratio * 0.16)
	weakpoint_material.albedo_color = Color(0.95, 0.95, 0.98)
	weakpoint_material.emission_enabled = true
	weakpoint_material.emission = Color(0.95, 0.95, 1.0) * 0.10 if weakpoint_open else Color.BLACK
	halo_material.emission_enabled = weakpoint_open or highlighted or scan_burst_active
	halo_material.emission = Color(0.18, 0.72, 1.0) * (0.10 + scan_burst_ratio * 0.12) if halo_material.emission_enabled else Color.BLACK
	eye_left_material.albedo_color = Color(0.46, 0.10, 0.10)
	eye_left_material.emission_enabled = true
	eye_left_material.emission = Color(0.78, 0.12, 0.12) * (0.18 + 0.10 * scan_pulse + (0.12 if weakpoint_open else 0.0))
	eye_right_material.albedo_color = Color(0.52, 0.12, 0.12)
	eye_right_material.emission_enabled = true
	eye_right_material.emission = Color(0.92, 0.16, 0.16) * (0.22 + 0.12 * scan_pulse + (0.14 if weakpoint_open else 0.0))
	if weakpoint_open:
		var rift_flash := 0.18 + flicker_ratio * 1.10
		head_material.emission_enabled = true
		head_material.albedo_color = Color(0.16, 0.05, 0.06)
		head_material.emission = Color(0.95, 0.08, 0.10) * (0.08 + rift_flash * 0.22)
		limb_material.emission_enabled = true
		limb_material.albedo_color = Color(0.10, 0.03, 0.04)
		limb_material.emission = Color(0.90, 0.06, 0.08) * (0.05 + rift_flash * 0.16)
		accent_material.albedo_color = Color(0.08, 0.02, 0.03)
		accent_material.emission = Color(1.0, 0.08, 0.10) * (0.20 + rift_flash * 0.30)
		weakpoint_material.albedo_color = Color(0.06, 0.01, 0.02)
		weakpoint_material.emission = Color(1.0, 0.12, 0.14) * (0.18 + rift_flash * 0.36)
		halo_material.albedo_color = Color(1.0, 0.05, 0.08, 0.10 + flicker_ratio * 0.18)
		halo_material.emission = Color(1.0, 0.08, 0.10) * (0.22 + rift_flash * 0.42)
		eye_left_material.emission = Color(1.0, 0.10, 0.12) * (0.24 + rift_flash * 0.28)
		eye_right_material.emission = Color(1.0, 0.10, 0.12) * (0.28 + rift_flash * 0.30)
		if weakpoint_mesh != null:
			weakpoint_mesh.scale = Vector3.ONE * (0.88 + flicker_ratio * 0.18)
		if accent_mesh != null:
			accent_mesh.scale = Vector3.ONE * (0.92 + flicker_ratio * 0.10)
		if halo_mesh != null:
			halo_mesh.scale = Vector3.ONE * (0.96 + flicker_ratio * 0.22)
	else:
		head_material.emission_enabled = false
		head_material.emission = Color.BLACK
		limb_material.emission_enabled = false
		limb_material.emission = Color.BLACK
		if weakpoint_mesh != null:
			weakpoint_mesh.scale = Vector3.ONE
		if accent_mesh != null:
			accent_mesh.scale = Vector3.ONE
		if halo_mesh != null:
			halo_mesh.scale = Vector3.ONE
	if core_mesh != null:
		core_mesh.material_override = core_material
		core_material.albedo_color = Color(0.78, 0.06, 0.10, 0.0)
		core_material.emission = Color.BLACK


func _apply_target_women_visual(highlighted: bool, weakpoint_open: bool, scan_burst_active: bool, scan_burst_ratio: float, scan_pulse: float, target_pulse: float) -> void:
	var flicker_ratio := _get_rift_flicker_ratio()
	material.emission_enabled = true
	material.emission = Color(0.18, 0.26, 0.32) * (0.03 + 0.05 * scan_pulse + scan_burst_ratio * 0.16)
	material.albedo_color = Color(0.14, 0.17, 0.20).lerp(Color(0.26, 0.34, 0.38), scan_burst_ratio * 0.30)
	material.roughness = 0.56
	material.metallic = 0.06

	head_material.albedo_color = Color(0.44, 0.48, 0.54)
	head_material.roughness = 0.66
	limb_material.albedo_color = Color(0.18, 0.22, 0.25)
	limb_material.roughness = 0.72
	costume_material.albedo_color = Color(0.25, 0.30, 0.38).lerp(Color(0.16, 0.20, 0.24), 1.0 - disguise_strength).lerp(Color(0.34, 0.44, 0.52), scan_burst_ratio * 0.32)
	costume_material.roughness = 0.86

	accent_material.albedo_color = Color(0.26, 0.58, 0.72).lerp(Color(0.58, 0.84, 0.96), scan_burst_ratio * 0.24)
	accent_material.emission_enabled = true
	accent_material.emission = Color(0.10, 0.38, 0.52) * (0.08 + scan_burst_ratio * 0.08)
	if weakpoint_open:
		accent_material.emission = Color(0.22, 0.82, 1.0) * (0.22 + 0.08 * target_pulse + scan_burst_ratio * 0.08)

	weakpoint_material.albedo_color = Color(0.96, 0.96, 0.99)
	weakpoint_material.emission_enabled = true
	weakpoint_material.emission = Color(0.96, 0.96, 1.0) * (0.10 + 0.04 * scan_burst_ratio) if weakpoint_open else Color.BLACK

	halo_material.albedo_color = Color(0.18, 0.72, 1.0, 0.08 + scan_burst_ratio * 0.08) if weakpoint_open or highlighted or scan_burst_active else Color(0.0, 0.0, 0.0, 0.0)
	halo_material.emission_enabled = weakpoint_open or highlighted or scan_burst_active
	halo_material.emission = Color(0.18, 0.72, 1.0) * (0.10 + scan_burst_ratio * 0.08) if weakpoint_open or highlighted or scan_burst_active else Color.BLACK

	eye_left_material.albedo_color = Color(0.22, 0.30, 0.34)
	eye_left_material.emission_enabled = false
	eye_left_material.emission = Color.BLACK
	eye_right_material.albedo_color = Color(0.22, 0.30, 0.34)
	eye_right_material.emission_enabled = false
	eye_right_material.emission = Color.BLACK

	if costume_overlay_material != null:
		costume_overlay_material.albedo_color = Color(0.62, 0.76, 0.84, 0.14 + scan_burst_ratio * 0.14)
	if accent_overlay_material != null:
		accent_overlay_material.albedo_color = Color(0.72, 0.90, 0.98, 0.14 + scan_burst_ratio * 0.12)

	if costume_mesh != null:
		costume_mesh.visible = true
	if accent_mesh != null:
		accent_mesh.visible = true
	if weakpoint_mesh != null:
		weakpoint_mesh.visible = weakpoint_open
	if core_mesh != null:
		core_mesh.visible = false
	if halo_mesh != null:
		halo_mesh.visible = weakpoint_open or highlighted or scan_burst_active
	if shoulder_left_mesh != null:
		shoulder_left_mesh.scale = Vector3(1.18, 1.0, 1.0)
		shoulder_left_mesh.visible = true
	if shoulder_right_mesh != null:
		shoulder_right_mesh.scale = Vector3(1.02, 1.0, 1.0)
		shoulder_right_mesh.visible = true
	if eye_left_mesh != null:
		eye_left_mesh.visible = true
	if eye_right_mesh != null:
		eye_right_mesh.visible = true
	eye_left_material.albedo_color = Color(0.46, 0.10, 0.10)
	eye_left_material.emission_enabled = true
	eye_left_material.emission = Color(0.78, 0.12, 0.12) * (0.10 + 0.08 * scan_pulse + (0.10 if weakpoint_open else 0.0))
	eye_right_material.albedo_color = Color(0.52, 0.12, 0.12)
	eye_right_material.emission_enabled = true
	eye_right_material.emission = Color(0.92, 0.16, 0.16) * (0.12 + 0.10 * scan_pulse + (0.12 if weakpoint_open else 0.0))
	if weakpoint_open:
		var rift_flash := 0.20 + flicker_ratio * 1.12
		head_material.emission_enabled = true
		head_material.albedo_color = Color(0.16, 0.05, 0.06)
		head_material.emission = Color(0.95, 0.08, 0.10) * (0.08 + rift_flash * 0.20)
		limb_material.emission_enabled = true
		limb_material.albedo_color = Color(0.10, 0.03, 0.04)
		limb_material.emission = Color(0.90, 0.06, 0.08) * (0.05 + rift_flash * 0.14)
		accent_material.albedo_color = Color(0.08, 0.02, 0.03)
		accent_material.emission = Color(1.0, 0.08, 0.10) * (0.22 + rift_flash * 0.28)
		weakpoint_material.albedo_color = Color(0.06, 0.01, 0.02)
		weakpoint_material.emission = Color(1.0, 0.12, 0.14) * (0.20 + rift_flash * 0.34)
		halo_material.albedo_color = Color(1.0, 0.05, 0.08, 0.12 + flicker_ratio * 0.20)
		halo_material.emission = Color(1.0, 0.08, 0.10) * (0.24 + rift_flash * 0.40)
		eye_left_material.emission = Color(1.0, 0.10, 0.12) * (0.24 + rift_flash * 0.26)
		eye_right_material.emission = Color(1.0, 0.10, 0.12) * (0.28 + rift_flash * 0.28)
		if weakpoint_mesh != null:
			weakpoint_mesh.scale = Vector3.ONE * (0.88 + flicker_ratio * 0.18)
		if accent_mesh != null:
			accent_mesh.scale = Vector3.ONE * (0.92 + flicker_ratio * 0.10)
		if halo_mesh != null:
			halo_mesh.scale = Vector3.ONE * (0.96 + flicker_ratio * 0.22)
	else:
		head_material.emission_enabled = false
		head_material.emission = Color.BLACK
		limb_material.emission_enabled = false
		limb_material.emission = Color.BLACK
		if weakpoint_mesh != null:
			weakpoint_mesh.scale = Vector3.ONE
		if accent_mesh != null:
			accent_mesh.scale = Vector3.ONE
		if halo_mesh != null:
			halo_mesh.scale = Vector3.ONE
	if core_mesh != null:
		core_mesh.material_override = core_material
		core_material.albedo_color = Color(0.78, 0.06, 0.10, 0.0)
		core_material.emission = Color.BLACK


func _apply_civilian_visual(highlighted: bool, scan_burst_active: bool, scan_burst_ratio: float, scan_pulse: float) -> void:
	var false_active := has_false_clue_active()
	var false_ratio := (sin(Time.get_ticks_msec() / 1000.0 * 4.5) + 1.0) * 0.5 if false_active else 0.0
	material.emission_enabled = false_active
	material.emission = Color(1.0, 0.78, 0.42) * (0.12 + 0.26 * false_ratio) if false_active else Color(0.34, 0.76, 1.0) * (scan_burst_ratio * 0.10)
	material.albedo_color = Color(0.24, 0.28, 0.32).lerp(Color(0.42, 0.32, 0.30), 0.22 if false_active else 0.0).lerp(Color(0.34, 0.54, 0.68), scan_burst_ratio * 0.18)
	material.roughness = 0.68
	head_material.albedo_color = Color(0.56, 0.50, 0.46).lerp(Color(0.68, 0.58, 0.50), 0.24 if false_active else 0.0)
	head_material.roughness = 0.70
	limb_material.albedo_color = Color(0.18, 0.20, 0.24).lerp(Color(0.44, 0.20, 0.18), 0.28 if false_active else 0.0)
	limb_material.roughness = 0.78
	var civilian_costume_base := Color(0.20, 0.24, 0.30)
	var civilian_false_costume := Color(0.46, 0.18, 0.22)
	costume_material.albedo_color = civilian_costume_base.lerp(civilian_false_costume, 0.78 if false_active else 0.0).lerp(Color(0.38, 0.46, 0.58), scan_burst_ratio * 0.18)
	costume_material.roughness = 0.88
	accent_material.albedo_color = Color(0.28, 0.32, 0.38).lerp(Color(0.92, 0.74, 0.34), 0.88 if false_active else 0.0).lerp(Color(0.64, 0.84, 0.94), scan_burst_ratio * 0.12)
	accent_material.emission_enabled = false_active
	accent_material.emission = Color(1.0, 0.78, 0.34) * (0.14 + 0.30 * false_ratio) if false_active else Color.BLACK
	weakpoint_material.albedo_color = Color(0.24, 0.26, 0.30).lerp(Color(0.98, 0.84, 0.42), 0.82 if false_active else 0.0)
	weakpoint_material.emission_enabled = false
	weakpoint_material.emission = Color.BLACK
	halo_material.albedo_color = Color(0.90, 0.72, 0.28, 0.14 + 0.10 * false_ratio) if false_active else (Color(0.28, 0.72, 1.0, 0.12 + 0.08 * scan_pulse + scan_burst_ratio * 0.12) if highlighted or scan_burst_active else Color(0.18, 0.28, 0.36, 0.0))
	halo_material.emission_enabled = false_active or highlighted or scan_burst_active
	halo_material.emission = Color(0.98, 0.80, 0.34) * (0.10 + 0.16 * false_ratio) if false_active else (Color(0.22, 0.72, 1.0) * (0.24 + scan_burst_ratio * 0.18) if highlighted or scan_burst_active else Color.BLACK)
	if costume_overlay_material != null:
		costume_overlay_material.albedo_color = Color(0.52, 0.38, 0.42, 0.20 + 0.08 * false_ratio) if false_active else Color(0.44, 0.54, 0.62, 0.12 + scan_burst_ratio * 0.10)
	if accent_overlay_material != null:
		accent_overlay_material.albedo_color = Color(1.0, 0.88, 0.46, 0.16 + 0.12 * false_ratio) if false_active else Color(0.72, 0.84, 0.94, 0.10 + scan_burst_ratio * 0.08)
	if costume_mesh != null:
		costume_mesh.visible = true
	if head_mesh != null:
		head_mesh.visible = true
	if accent_mesh != null:
		accent_mesh.visible = false_active
	if weakpoint_mesh != null:
		weakpoint_mesh.visible = false_active
	if core_mesh != null:
		core_mesh.visible = false
	if halo_mesh != null:
		halo_mesh.visible = false_active or highlighted or scan_burst_active
	if shoulder_left_mesh != null:
		shoulder_left_mesh.scale = Vector3.ONE
		shoulder_left_mesh.visible = false_active
		if false_active:
			shoulder_left_mesh.material_override = accent_material
	if shoulder_right_mesh != null:
		shoulder_right_mesh.scale = Vector3.ONE
		shoulder_right_mesh.visible = false_active
		if false_active:
			shoulder_right_mesh.material_override = accent_material
	if foot_left_mesh != null:
		foot_left_mesh.visible = true
	if foot_right_mesh != null:
		foot_right_mesh.visible = true
	if eye_left_mesh != null:
		eye_left_mesh.visible = false
	if eye_right_mesh != null:
		eye_right_mesh.visible = false


func is_hittable() -> bool:
	return alive and current_hit_points > 0


func apply_shot_damage(_kind: String = "hit", hide_immediately: bool = true) -> Dictionary:
	if not alive or current_hit_points <= 0:
		return {
			"defeated": true,
			"remaining_hp": 0,
			"max_hp": max_hit_points,
		}
	if behavior_type == "weakpoint" and not is_weakpoint_active():
		highlight_for(0.12)
		trigger_scan_burst(0.10, 0.25)
		return {
			"defeated": false,
			"remaining_hp": current_hit_points,
			"max_hp": max_hit_points,
			"ineffective": true,
		}
	current_hit_points = maxi(current_hit_points - 1, 0)
	if current_hit_points <= 0:
		mark_hit(_kind, hide_immediately)
		return {
			"defeated": true,
			"remaining_hp": 0,
			"max_hp": max_hit_points,
		}
	highlight_for(0.18)
	trigger_scan_burst(0.16, 0.4)
	return {
		"defeated": false,
		"remaining_hp": current_hit_points,
		"max_hp": max_hit_points,
	}


func mark_hit(_kind: String = "hit", hide_immediately: bool = true) -> void:
	alive = false
	occlusion_hint_active = false
	if body != null:
		body.collision_layer = 0
		body.collision_mask = 0
		if hide_immediately:
			body.visible = false
	if mesh_root != null and hide_immediately:
		mesh_root.visible = false
	if health_bar_root != null and is_instance_valid(health_bar_root):
		health_bar_root.visible = false
	_set_occlusion_hint_visible(false)


func hide_dead_body() -> void:
	if not alive:
		if body != null:
			body.visible = false
		if mesh_root != null:
			mesh_root.visible = false
		if health_bar_root != null and is_instance_valid(health_bar_root):
			health_bar_root.visible = false
		_set_occlusion_hint_visible(false)


func _build_occlusion_hint() -> void:
	if mesh_root == null:
		return
	if occlusion_hint_root == null or not is_instance_valid(occlusion_hint_root):
		occlusion_hint_root = Node3D.new()
		occlusion_hint_root.name = "OcclusionHintRoot"
		mesh_root.add_child(occlusion_hint_root)
	if occlusion_hint_mesh == null or not is_instance_valid(occlusion_hint_mesh):
		occlusion_hint_mesh = MeshInstance3D.new()
		occlusion_hint_mesh.name = "OcclusionHintTorso"
		var torso_quad := QuadMesh.new()
		torso_quad.size = Vector2(body_radius * 0.86, body_radius * 1.28)
		occlusion_hint_mesh.mesh = torso_quad
		occlusion_hint_mesh.position = Vector3(0.0, body_radius * 1.08, body_radius * 0.10)
		occlusion_hint_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_mesh)
	if occlusion_hint_head_mesh == null or not is_instance_valid(occlusion_hint_head_mesh):
		occlusion_hint_head_mesh = MeshInstance3D.new()
		occlusion_hint_head_mesh.name = "OcclusionHintHead"
		var head_quad := QuadMesh.new()
		head_quad.size = Vector2(body_radius * 0.56, body_radius * 0.58)
		occlusion_hint_head_mesh.mesh = head_quad
		occlusion_hint_head_mesh.position = Vector3(0.0, body_radius * 1.78, body_radius * 0.12)
		occlusion_hint_head_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_head_mesh)
	if occlusion_hint_shoulder_mesh == null or not is_instance_valid(occlusion_hint_shoulder_mesh):
		occlusion_hint_shoulder_mesh = MeshInstance3D.new()
		occlusion_hint_shoulder_mesh.name = "OcclusionHintShoulders"
		var shoulder_quad := QuadMesh.new()
		shoulder_quad.size = Vector2(body_radius * 1.08, body_radius * 0.24)
		occlusion_hint_shoulder_mesh.mesh = shoulder_quad
		occlusion_hint_shoulder_mesh.position = Vector3(0.0, body_radius * 1.42, body_radius * 0.10)
		occlusion_hint_shoulder_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_shoulder_mesh)
	if occlusion_hint_hip_mesh == null or not is_instance_valid(occlusion_hint_hip_mesh):
		occlusion_hint_hip_mesh = MeshInstance3D.new()
		occlusion_hint_hip_mesh.name = "OcclusionHintHips"
		var hip_quad := QuadMesh.new()
		hip_quad.size = Vector2(body_radius * 0.76, body_radius * 0.20)
		occlusion_hint_hip_mesh.mesh = hip_quad
		occlusion_hint_hip_mesh.position = Vector3(0.0, body_radius * 0.74, body_radius * 0.10)
		occlusion_hint_hip_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_hip_mesh)
	if occlusion_hint_leg_left_mesh == null or not is_instance_valid(occlusion_hint_leg_left_mesh):
		occlusion_hint_leg_left_mesh = MeshInstance3D.new()
		occlusion_hint_leg_left_mesh.name = "OcclusionHintLegLeft"
		var leg_quad_left := QuadMesh.new()
		leg_quad_left.size = Vector2(body_radius * 0.18, body_radius * 0.92)
		occlusion_hint_leg_left_mesh.mesh = leg_quad_left
		occlusion_hint_leg_left_mesh.position = Vector3(-body_radius * 0.15, body_radius * 0.24, body_radius * 0.10)
		occlusion_hint_leg_left_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_leg_left_mesh)
	if occlusion_hint_leg_right_mesh == null or not is_instance_valid(occlusion_hint_leg_right_mesh):
		occlusion_hint_leg_right_mesh = MeshInstance3D.new()
		occlusion_hint_leg_right_mesh.name = "OcclusionHintLegRight"
		var leg_quad_right := QuadMesh.new()
		leg_quad_right.size = Vector2(body_radius * 0.18, body_radius * 0.92)
		occlusion_hint_leg_right_mesh.mesh = leg_quad_right
		occlusion_hint_leg_right_mesh.position = Vector3(body_radius * 0.15, body_radius * 0.24, body_radius * 0.10)
		occlusion_hint_leg_right_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_leg_right_mesh)
	if occlusion_hint_arm_left_mesh == null or not is_instance_valid(occlusion_hint_arm_left_mesh):
		occlusion_hint_arm_left_mesh = MeshInstance3D.new()
		occlusion_hint_arm_left_mesh.name = "OcclusionHintArmLeft"
		var arm_quad_left := QuadMesh.new()
		arm_quad_left.size = Vector2(body_radius * 0.16, body_radius * 0.82)
		occlusion_hint_arm_left_mesh.mesh = arm_quad_left
		occlusion_hint_arm_left_mesh.position = Vector3(-body_radius * 0.34, body_radius * 1.02, body_radius * 0.10)
		occlusion_hint_arm_left_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_arm_left_mesh)
	if occlusion_hint_arm_right_mesh == null or not is_instance_valid(occlusion_hint_arm_right_mesh):
		occlusion_hint_arm_right_mesh = MeshInstance3D.new()
		occlusion_hint_arm_right_mesh.name = "OcclusionHintArmRight"
		var arm_quad_right := QuadMesh.new()
		arm_quad_right.size = Vector2(body_radius * 0.16, body_radius * 0.82)
		occlusion_hint_arm_right_mesh.mesh = arm_quad_right
		occlusion_hint_arm_right_mesh.position = Vector3(body_radius * 0.34, body_radius * 1.02, body_radius * 0.10)
		occlusion_hint_arm_right_mesh.material_override = occlusion_hint_material
		occlusion_hint_root.add_child(occlusion_hint_arm_right_mesh)
	if occlusion_hint_glow_mesh == null or not is_instance_valid(occlusion_hint_glow_mesh):
		occlusion_hint_glow_mesh = MeshInstance3D.new()
		occlusion_hint_glow_mesh.name = "OcclusionHintGlow"
		var glow_mesh := SphereMesh.new()
		glow_mesh.radius = body_radius * 0.12
		glow_mesh.height = body_radius * 0.24
		occlusion_hint_glow_mesh.mesh = glow_mesh
		occlusion_hint_glow_mesh.position = Vector3(0.0, body_radius * 1.18, 0.0)
		occlusion_hint_glow_mesh.material_override = occlusion_hint_glow_material
		occlusion_hint_root.add_child(occlusion_hint_glow_mesh)
	occlusion_hint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	occlusion_hint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	occlusion_hint_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	occlusion_hint_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	occlusion_hint_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	occlusion_hint_material.no_depth_test = true
	occlusion_hint_material.emission_enabled = true
	occlusion_hint_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	occlusion_hint_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	occlusion_hint_glow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	occlusion_hint_glow_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	occlusion_hint_glow_material.no_depth_test = true
	occlusion_hint_glow_material.emission_enabled = true
	_set_occlusion_hint_visible(false)


func _update_occlusion_hint(now: float, target_pulse: float, scan_pulse: float, highlighted: bool, scan_burst_active: bool) -> void:
	if occlusion_hint_root == null or occlusion_hint_mesh == null or occlusion_hint_glow_mesh == null:
		return
	var should_show: bool = _should_show_occlusion_hint()
	occlusion_hint_active = should_show
	if not should_show:
		occlusion_hint_strength = 0.0
		_set_occlusion_hint_visible(false)
		return
	var blink_wave: float = (sin(now * 8.8 + phase_offset * 0.4) + 1.0) * 0.5
	occlusion_hint_strength = 0.54 + blink_wave * 0.46
	var base_color: Color = Color(0.18, 0.90, 1.0) if actor_kind == "target" else Color(1.0, 0.84, 0.34)
	var boosted_strength: float = occlusion_hint_strength + (0.12 if highlighted or scan_burst_active else 0.0) + scan_pulse * 0.06 + target_pulse * 0.04
	_set_occlusion_hint_visible(true)
	occlusion_hint_root.scale = Vector3.ONE * (0.94 + occlusion_hint_strength * 0.08)
	occlusion_hint_mesh.scale = Vector3(0.96 + occlusion_hint_strength * 0.18, 0.98 + occlusion_hint_strength * 0.20, 1.0)
	if occlusion_hint_head_mesh != null:
		occlusion_hint_head_mesh.scale = Vector3.ONE * (0.94 + occlusion_hint_strength * 0.16)
	if occlusion_hint_shoulder_mesh != null:
		occlusion_hint_shoulder_mesh.scale = Vector3(0.98 + occlusion_hint_strength * 0.12, 1.0, 1.0)
	if occlusion_hint_hip_mesh != null:
		occlusion_hint_hip_mesh.scale = Vector3(0.98 + occlusion_hint_strength * 0.08, 1.0, 1.0)
	if occlusion_hint_leg_left_mesh != null:
		occlusion_hint_leg_left_mesh.scale = Vector3.ONE * (0.96 + occlusion_hint_strength * 0.10)
	if occlusion_hint_leg_right_mesh != null:
		occlusion_hint_leg_right_mesh.scale = Vector3.ONE * (0.96 + occlusion_hint_strength * 0.10)
	if occlusion_hint_arm_left_mesh != null:
		occlusion_hint_arm_left_mesh.scale = Vector3.ONE * (0.95 + occlusion_hint_strength * 0.12)
	if occlusion_hint_arm_right_mesh != null:
		occlusion_hint_arm_right_mesh.scale = Vector3.ONE * (0.95 + occlusion_hint_strength * 0.12)
	occlusion_hint_material.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.16 + occlusion_hint_strength * 0.18)
	occlusion_hint_material.emission = base_color * (0.88 + boosted_strength * 1.32)
	occlusion_hint_glow_material.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.16 + occlusion_hint_strength * 0.18)
	occlusion_hint_glow_material.emission = base_color * (1.04 + boosted_strength * 1.46)
	occlusion_hint_glow_mesh.scale = Vector3.ONE * (0.92 + occlusion_hint_strength * 0.42)


func _set_occlusion_hint_visible(show_hint: bool) -> void:
	if occlusion_hint_root != null and is_instance_valid(occlusion_hint_root):
		occlusion_hint_root.visible = show_hint
	if occlusion_hint_mesh != null and is_instance_valid(occlusion_hint_mesh):
		occlusion_hint_mesh.visible = show_hint
	if occlusion_hint_glow_mesh != null and is_instance_valid(occlusion_hint_glow_mesh):
		occlusion_hint_glow_mesh.visible = show_hint
	if occlusion_hint_head_mesh != null and is_instance_valid(occlusion_hint_head_mesh):
		occlusion_hint_head_mesh.visible = show_hint
	if occlusion_hint_shoulder_mesh != null and is_instance_valid(occlusion_hint_shoulder_mesh):
		occlusion_hint_shoulder_mesh.visible = show_hint
	if occlusion_hint_hip_mesh != null and is_instance_valid(occlusion_hint_hip_mesh):
		occlusion_hint_hip_mesh.visible = show_hint
	if occlusion_hint_leg_left_mesh != null and is_instance_valid(occlusion_hint_leg_left_mesh):
		occlusion_hint_leg_left_mesh.visible = show_hint
	if occlusion_hint_leg_right_mesh != null and is_instance_valid(occlusion_hint_leg_right_mesh):
		occlusion_hint_leg_right_mesh.visible = show_hint
	if occlusion_hint_arm_left_mesh != null and is_instance_valid(occlusion_hint_arm_left_mesh):
		occlusion_hint_arm_left_mesh.visible = show_hint
	if occlusion_hint_arm_right_mesh != null and is_instance_valid(occlusion_hint_arm_right_mesh):
		occlusion_hint_arm_right_mesh.visible = show_hint


func _should_show_occlusion_hint() -> bool:
	if not alive:
		return false
	if not _uses_women_occlusion_hint():
		return false
	var camera: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if camera == null or not is_instance_valid(camera):
		return false
	var focus_point: Vector3 = get_impact_focus_point()
	if camera.is_position_behind(focus_point):
		return false
	var viewport := camera.get_viewport()
	if viewport != null:
		var viewport_size: Vector2 = viewport.get_visible_rect().size
		var screen_pos: Vector2 = camera.unproject_position(focus_point)
		if screen_pos.x < -220.0 or screen_pos.y < -220.0 or screen_pos.x > viewport_size.x + 220.0 or screen_pos.y > viewport_size.y + 220.0:
			return false
	return _is_probe_occluded(camera, focus_point) and _is_probe_occluded(camera, global_position + Vector3(0.0, maxf(body_radius * 1.86, 1.52), 0.0))


func _uses_women_occlusion_hint() -> bool:
	return imported_visual_root != null and not imported_generic_actor


func _is_probe_occluded(camera: Camera3D, probe_world_pos: Vector3) -> bool:
	var world3d := get_world_3d()
	if world3d == null:
		return false
	var space_state := world3d.direct_space_state
	if space_state == null:
		return false
	var origin: Vector3 = camera.global_position
	if origin.distance_squared_to(probe_world_pos) < 0.0001:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, probe_world_pos)
	query.collision_mask = 1
	if body != null and is_instance_valid(body):
		query.exclude = [body.get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var hit_point: Vector3 = hit.get("position", probe_world_pos)
	return origin.distance_to(hit_point) < origin.distance_to(probe_world_pos) - 0.12


func debug_get_occlusion_hint_state() -> Dictionary:
	return {
		"active": occlusion_hint_active,
		"strength": occlusion_hint_strength,
		"uses_women_hint": _uses_women_occlusion_hint(),
	}


func get_remaining_hit_points() -> int:
	return current_hit_points


func get_max_hit_points() -> int:
	return max_hit_points


func _build_health_bar() -> void:
	if max_hit_points <= 1 or actor_kind != "target":
		return
	if health_bar_root != null and is_instance_valid(health_bar_root):
		return
	health_bar_root = Node3D.new()
	health_bar_root.name = "HealthBarRoot"
	health_bar_root.position = Vector3(0.0, _get_health_bar_height(), 0.0)
	add_child(health_bar_root)
	health_bar_segments.clear()
	var spacing := 0.22
	for index in range(max_hit_points):
		var segment := MeshInstance3D.new()
		segment.name = "HealthSegment%d" % index
		var quad := QuadMesh.new()
		quad.size = Vector2(0.16, 0.07)
		segment.mesh = quad
		segment.position = Vector3((float(index) - float(max_hit_points - 1) * 0.5) * spacing, 0.0, 0.0)
		var segment_material := StandardMaterial3D.new()
		segment_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		segment_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		segment_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		segment_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		segment.material_override = segment_material
		health_bar_root.add_child(segment)
		health_bar_segments.append(segment)
	_update_health_bar(false, false, 0.0)


func _get_health_bar_height() -> float:
	if imported_visual_root != null:
		return imported_visual_bounds.position.y + imported_visual_bounds.size.y + 0.55
	return body_radius * 2.7


func _update_health_bar(highlighted: bool, scan_burst_active: bool, target_pulse: float) -> void:
	if health_bar_root == null or not is_instance_valid(health_bar_root):
		return
	health_bar_root.visible = alive and max_hit_points > 1 and actor_kind == "target"
	if not health_bar_root.visible:
		return
	health_bar_root.position.y = _get_health_bar_height()
	for index in range(health_bar_segments.size()):
		var segment := health_bar_segments[index]
		if segment == null or not is_instance_valid(segment):
			continue
		var mat := segment.material_override as StandardMaterial3D
		if mat == null:
			continue
		var active := index < current_hit_points
		if active:
			var glow_strength := 0.82 + (0.18 if highlighted or scan_burst_active else 0.0) + target_pulse * 0.06
			mat.albedo_color = Color(0.24, 0.95, 0.78, 0.96)
			mat.emission_enabled = true
			mat.emission = Color(0.18, 0.92, 0.76) * glow_strength
		else:
			mat.albedo_color = Color(0.16, 0.20, 0.24, 0.42)
			mat.emission_enabled = false
			mat.emission = Color.BLACK


func highlight_for(seconds: float) -> void:
	highlighted_until = maxf(highlighted_until, Time.get_ticks_msec() / 1000.0 + seconds)
	_update_visual()


func trigger_scan_burst(seconds: float, strength: float = 1.0) -> void:
	scan_burst_until = maxf(scan_burst_until, Time.get_ticks_msec() / 1000.0 + seconds)
	scan_burst_strength = maxf(scan_burst_strength, strength)
	highlight_for(minf(seconds, 1.2))
	_update_visual()


func get_locator_weight() -> float:
	if actor_kind != "target" or not alive:
		return -1.0
	return float(suspicion_tier) + search_signal_strength


func has_false_clue_active() -> bool:
	return actor_kind == "civilian" and false_clue_active and not false_clue_profile.is_empty()


func set_tutorial_primary(is_primary: bool) -> void:
	tutorial_primary = is_primary


func trigger_false_clue(seconds: float) -> void:
	if false_clue_profile.is_empty():
		false_clue_profile.append("胸针或拉链头反光")
	false_clue_active = true
	false_clue_until = maxf(false_clue_until, Time.get_ticks_msec() / 1000.0 + seconds)
	_update_visual()


func get_suspicion_summary() -> String:
	if actor_kind == "civilian":
		if has_false_clue_active():
			return "假线索：%s，但肩线、腰侧和服装结构都更像普通市民。" % "、".join(false_clue_profile)
		return "肩线自然，腰侧没有异常亮线，服装结构更像普通市民。"

	if clue_profile.is_empty():
		return "这个目标有轻微伪装破绽。"
	return "可疑点：%s" % "、".join(clue_profile)


func get_identification_review() -> String:
	if actor_kind == "civilian":
		if has_false_clue_active():
			return "被假线索误导：%s，但这个人肩线自然、腰侧没有异常亮线。" % "、".join(false_clue_profile)
		return "你忽略了这个人肩线自然、腰侧没有异常亮线的普通人特征。"
	if disguise_strength > 0.4:
		return "这次识别准确，虽然服装伪装削弱了异常感，但头部外壳、肩袖结构和腰侧亮线仍然暴露了它。"
	return "这次识别准确，头部外壳和肩袖结构的判断都正确。"


func get_impact_focus_point() -> Vector3:
	return global_position + Vector3(0.0, body_radius * 1.35, body_radius * 0.08)


func _try_build_imported_actor() -> bool:
	imported_generic_actor = false
	var actor_scene: PackedScene = _resolve_actor_scene()
	if actor_scene == null:
		return false
	imported_visual_root = actor_scene.instantiate() as Node3D
	if imported_visual_root == null:
		return false
	imported_visual_root.name = "ImportedActor"
	mesh_root.add_child(imported_visual_root)

	imported_primary_mesh = _find_first_mesh_instance(imported_visual_root)
	imported_animation_player = _find_first_animation_player(imported_visual_root)
	imported_animation_name = ""
	if imported_primary_mesh == null:
		imported_visual_root.queue_free()
		imported_visual_root = null
		return false
	imported_visual_bounds = _compute_imported_bounds(imported_visual_root)
	body_radius = clampf(maxf(imported_visual_bounds.size.x, imported_visual_bounds.size.z) * 0.55, 0.52, 1.35)

	mesh = _find_mesh_instance(imported_visual_root, "BodyMesh")
	head_mesh = _find_mesh_instance(imported_visual_root, "HeadMesh")
	shoulder_left_mesh = _find_mesh_instance(imported_visual_root, "ShoulderLeft")
	shoulder_right_mesh = _find_mesh_instance(imported_visual_root, "ShoulderRight")
	eye_left_mesh = _find_mesh_instance(imported_visual_root, "EyeLeft")
	eye_right_mesh = _find_mesh_instance(imported_visual_root, "EyeRight")
	upper_arm_left_mesh = _find_mesh_instance(imported_visual_root, "UpperArmLeft")
	upper_arm_right_mesh = _find_mesh_instance(imported_visual_root, "UpperArmRight")
	forearm_left_mesh = _find_mesh_instance(imported_visual_root, "ForearmLeft")
	forearm_right_mesh = _find_mesh_instance(imported_visual_root, "ForearmRight")
	leg_left_mesh = _find_mesh_instance(imported_visual_root, "LegLeft")
	leg_right_mesh = _find_mesh_instance(imported_visual_root, "LegRight")
	foot_left_mesh = _find_mesh_instance(imported_visual_root, "FootLeft")
	foot_right_mesh = _find_mesh_instance(imported_visual_root, "FootRight")
	costume_mesh = _find_mesh_instance(imported_visual_root, "CostumeMesh")
	accent_mesh = _find_mesh_instance(imported_visual_root, "AccentMesh")
	weakpoint_mesh = _find_mesh_instance(imported_visual_root, "WeakpointMesh")
	core_mesh = _find_mesh_instance(imported_visual_root, "CoreMesh")
	halo_mesh = _find_mesh_instance(imported_visual_root, "HaloMesh")

	if mesh == null:
		mesh = imported_primary_mesh

	if head_mesh == null or costume_mesh == null or weakpoint_mesh == null or halo_mesh == null:
		imported_generic_actor = true
		_build_imported_feature_helpers(imported_visual_root)

	if mesh == null:
		imported_visual_root.queue_free()
		imported_visual_root = null
		return false

	if not imported_generic_actor:
		mesh.material_override = material
		head_mesh.material_override = head_material
		costume_mesh.material_override = costume_material
		weakpoint_mesh.material_override = weakpoint_material
		halo_mesh.material_override = halo_material
		if accent_mesh != null:
			accent_mesh.material_override = accent_material
		if shoulder_left_mesh != null:
			shoulder_left_mesh.material_override = accent_material
		if shoulder_right_mesh != null:
			shoulder_right_mesh.material_override = accent_material
		if eye_left_mesh != null:
			eye_left_mesh.material_override = eye_left_material
		if eye_right_mesh != null:
			eye_right_mesh.material_override = eye_right_material
		if core_mesh != null:
			core_mesh.material_override = core_material
		for limb_mesh in [upper_arm_left_mesh, upper_arm_right_mesh, forearm_left_mesh, forearm_right_mesh, leg_left_mesh, leg_right_mesh, foot_left_mesh, foot_right_mesh]:
			if limb_mesh != null:
				limb_mesh.material_override = limb_material
	else:
		_apply_imported_generic_materials()
	_ensure_imported_collider()
	_cache_imported_pose()
	_play_imported_animation_if_available()
	return true


func _ensure_surface_overlays() -> void:
	if mesh_root == null:
		return
	if actor_fabric_texture == null:
		actor_fabric_texture = _load_svg_texture_runtime(TEX_ACTOR_FABRIC_BREAKUP_PATH)
	if costume_overlay_mesh == null or not is_instance_valid(costume_overlay_mesh):
		costume_overlay_mesh = _make_surface_overlay("CostumeOverlay", Vector2(body_radius * 1.12, body_radius * 1.22), costume_overlay_material)
		costume_overlay_mesh.position = Vector3(0.0, body_radius * 1.00, body_radius * 0.28)
		mesh_root.add_child(costume_overlay_mesh)
	if accent_overlay_mesh == null or not is_instance_valid(accent_overlay_mesh):
		accent_overlay_mesh = _make_surface_overlay("AccentOverlay", Vector2(body_radius * 0.46, body_radius * 0.62), accent_overlay_material)
		accent_overlay_mesh.position = Vector3(body_radius * 0.28, body_radius * 1.04, body_radius * 0.30)
		mesh_root.add_child(accent_overlay_mesh)


func _make_surface_overlay(node_name: String, overlay_size: Vector2, overlay_material: StandardMaterial3D) -> MeshInstance3D:
	var overlay := MeshInstance3D.new()
	overlay.name = node_name
	var quad := QuadMesh.new()
	quad.size = overlay_size
	overlay.mesh = quad
	overlay.material_override = overlay_material
	overlay.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	overlay_material.albedo_texture = actor_fabric_texture
	overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	overlay_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return overlay


func _load_svg_texture_runtime(svg_path: String) -> Texture2D:
	var svg_text := FileAccess.get_file_as_string(svg_path)
	if svg_text.is_empty():
		return null
	var image := Image.new()
	var err := image.load_svg_from_string(svg_text)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _resolve_actor_scene() -> PackedScene:
	if actor_kind == "civilian":
		return _resolve_civilian_scene()
	if women_action_scene_key == 1:
		return SCENE_WOMEN_ACTION_01
	if women_action_scene_key == 2:
		return SCENE_WOMEN_ACTION_02
	if behavior_type == "weakpoint":
		return SCENE_ALIEN_WOMEN_02
	if behavior_type == "moving":
		return SCENE_ALIEN_WOMEN_01
	if disguise_strength <= 0.35:
		return SCENE_ALIEN_WOMEN_02
	return SCENE_ALIEN_WOMEN_01


func _resolve_civilian_scene() -> PackedScene:
	if int(absf(phase_offset) * 10.0) % 2 == 0:
		return SCENE_ALIEN_WOMEN_01
	return SCENE_ALIEN_WOMEN_02


func _find_first_mesh_instance(root: Node) -> MeshInstance3D:
	if root == null:
		return null
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_first_mesh_instance(child)
		if found != null:
			return found
	return null


func _find_first_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_first_animation_player(child)
		if found != null:
			return found
	return null


func _play_imported_animation_if_available() -> void:
	if imported_animation_player == null:
		return
	var candidates: Array[String] = []
	for animation_name in imported_animation_player.get_animation_list():
		var key := str(animation_name)
		var lowered := key.to_lower()
		if lowered == "reset" or lowered == "_reset":
			continue
		candidates.append(key)
	if candidates.is_empty():
		return
	imported_animation_name = candidates[int(absf(phase_offset)) % candidates.size()]
	imported_animation_player.play(imported_animation_name)
	imported_animation_player.speed_scale = randf_range(0.92, 1.08)


func _ensure_imported_animation_running() -> void:
	if not women_action_enabled:
		return
	if imported_animation_player == null:
		return
	if imported_animation_name.is_empty():
		_play_imported_animation_if_available()
		return
	if not imported_animation_player.is_playing() or str(imported_animation_player.current_animation) != imported_animation_name:
		imported_animation_player.play(imported_animation_name)


func _update_women_action_motion(delta: float, now: float, local_time: float) -> void:
	var action_speed := maxf(women_action_speed * 2.0, 0.48)
	var stride_weight := _get_women_action_stride_weight(local_time)
	var map_center := Vector3.ZERO
	var current_pos := global_position
	var center_offset := map_center - current_pos
	center_offset.y = 0.0
	if center_offset.length_squared() < 0.0001:
		center_offset = Vector3(0.0, 0.0, 1.0)
	var to_center := center_offset.normalized()
	var tangent_dir := Vector3(-to_center.z, 0.0, to_center.x) * women_action_orbit_direction
	var radius := maxf(Vector2(current_pos.x - map_center.x, current_pos.z - map_center.z).length(), 0.001)
	var orbit_band := clampf(women_action_range, 0.28, 0.95)
	var radial_error := radius - women_action_orbit_radius
	var radial_correction := to_center * clampf(radial_error / maxf(orbit_band, 0.28), -1.0, 1.0)
	var edge_correction := _get_women_action_edge_correction(current_pos)
	var desired_dir := (tangent_dir + radial_correction * 0.95 + edge_correction * 1.2).normalized()
	desired_dir = _resolve_women_action_avoidance(desired_dir, now)

	var travel_speed := lerpf(0.44, 2.36, stride_weight) * (0.88 + action_speed * 0.55)
	var previous_position := global_position
	global_position += desired_dir * travel_speed * maxf(delta, 0.0)
	mesh_root.rotation_degrees.z = 0.0

	var planar_delta := Vector2(global_position.x - previous_position.x, global_position.z - previous_position.z)
	var facing_target_rad := deg_to_rad(women_action_facing_y)
	if planar_delta.length() > 0.0005:
		facing_target_rad = atan2(planar_delta.x, planar_delta.y)
	women_action_facing_y = rad_to_deg(lerp_angle(deg_to_rad(women_action_facing_y), facing_target_rad, clampf(delta * 4.5, 0.0, 1.0)))
	mesh_root.rotation_degrees.y = women_action_facing_y + sin(local_time * action_speed * 0.8) * (1.5 + stride_weight * 3.0)


func _get_women_action_stride_weight(local_time: float) -> float:
	if imported_animation_player != null and not imported_animation_name.is_empty():
		var animation := imported_animation_player.get_animation(imported_animation_name)
		if animation != null and animation.length > 0.01:
			var normalized := fposmod(imported_animation_player.current_animation_position / animation.length, 1.0)
			var stride_wave := maxf(sin(normalized * PI * 2.0), 0.0)
			return clampf(stride_wave * stride_wave, 0.0, 1.0)
	var fallback_wave := maxf(sin(local_time * maxf(women_action_speed, 0.24) * 1.6), 0.0)
	return clampf(fallback_wave * fallback_wave, 0.0, 1.0)


func _get_women_action_edge_correction(world_pos: Vector3) -> Vector3:
	var correction := Vector3.ZERO
	if world_pos.x > 10.8:
		correction.x -= clampf((world_pos.x - 10.8) / 1.8, 0.0, 1.0)
	elif world_pos.x < -10.8:
		correction.x += clampf((-10.8 - world_pos.x) / 1.8, 0.0, 1.0)
	if world_pos.z > 8.2:
		correction.z -= clampf((world_pos.z - 8.2) / 1.6, 0.0, 1.0)
	elif world_pos.z < -8.2:
		correction.z += clampf((-8.2 - world_pos.z) / 1.6, 0.0, 1.0)
	return correction.normalized() if correction.length_squared() > 0.0001 else Vector3.ZERO


func _resolve_women_action_avoidance(base_dir: Vector3, now: float) -> Vector3:
	var desired_dir := base_dir.normalized()
	if desired_dir.length_squared() < 0.0001:
		return Vector3.FORWARD
	if now < women_action_avoid_until and absf(women_action_avoid_direction) > 0.01:
		desired_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(62.0 * women_action_avoid_direction)).normalized()
	var probe_origin := global_position + Vector3(0.0, maxf(body_radius * 1.1, 0.95), 0.0)
	var forward_clear := _measure_women_action_clearance(probe_origin, desired_dir, 2.2)
	if forward_clear >= 1.25:
		return desired_dir
	var left_dir := desired_dir.rotated(Vector3.UP, deg_to_rad(48.0)).normalized()
	var right_dir := desired_dir.rotated(Vector3.UP, deg_to_rad(-48.0)).normalized()
	var left_clear := _measure_women_action_clearance(probe_origin, left_dir, 2.1)
	var right_clear := _measure_women_action_clearance(probe_origin, right_dir, 2.1)
	women_action_avoid_direction = 1.0 if left_clear >= right_clear else -1.0
	women_action_avoid_until = now + 0.75
	return desired_dir.rotated(Vector3.UP, deg_to_rad(68.0 * women_action_avoid_direction)).normalized()


func _measure_women_action_clearance(origin: Vector3, direction: Vector3, distance: float) -> float:
	var space_state := get_world_3d().direct_space_state if get_world_3d() != null else null
	if space_state == null:
		return distance
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * distance)
	query.collision_mask = 1
	if body != null and is_instance_valid(body):
		query.exclude = [body.get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return distance
	return origin.distance_to(hit.get("position", origin))


func _compute_imported_bounds(root: Node) -> AABB:
	var merged := AABB()
	var has_bounds := false
	var result := _collect_imported_bounds_recursive(root, Transform3D.IDENTITY, merged, has_bounds)
	merged = result.get("merged", merged)
	has_bounds = bool(result.get("has_bounds", has_bounds))
	if not has_bounds:
		return AABB(Vector3(-0.3, 0.0, -0.2), Vector3(0.6, 1.8, 0.4))
	return merged


func _collect_imported_bounds_recursive(node: Node, accumulated: Transform3D, merged: AABB, has_bounds: bool) -> Dictionary:
	var current_transform := accumulated
	if node is Node3D and node != imported_visual_root:
		current_transform = accumulated * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_aabb: AABB = mesh_instance.mesh.get_aabb()
			for corner in _aabb_corners(mesh_aabb):
				var local_corner := current_transform * corner
				if not has_bounds:
					merged = AABB(local_corner, Vector3.ZERO)
					has_bounds = true
				else:
					merged = merged.expand(local_corner)
	for child in node.get_children():
		var child_result := _collect_imported_bounds_recursive(child, current_transform, merged, has_bounds)
		merged = child_result.get("merged", merged)
		has_bounds = bool(child_result.get("has_bounds", has_bounds))
	return {
		"merged": merged,
		"has_bounds": has_bounds,
	}


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p := aabb.position
	var s := aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]


func _collect_mesh_instances(root: Node, out: Array[MeshInstance3D]) -> void:
	if root == null:
		return
	if root is MeshInstance3D:
		out.append(root as MeshInstance3D)
	for child in root.get_children():
		_collect_mesh_instances(child, out)


func _build_imported_feature_helpers(root: Node3D) -> bool:
	if root == null:
		return false
	if accent_mesh != null and weakpoint_mesh != null and core_mesh != null:
		return true
	var feature_root := Node3D.new()
	feature_root.name = "ImportedFeatureLayer"
	root.add_child(feature_root)

	var center := imported_visual_bounds.position + imported_visual_bounds.size * 0.5
	var size := imported_visual_bounds.size
	var width := maxf(size.x, 0.65)
	var height := maxf(size.y, 1.45)
	var depth := maxf(size.z, 0.42)
	var top_anchor := center + Vector3(0.0, height * 0.60, 0.0)
	var top_stack_gap := height * 0.075

	head_mesh = _make_helper_sphere("HeadMesh", width * 0.10, top_anchor + Vector3(0.0, top_stack_gap * 2.6, 0.0))
	head_mesh.visible = false
	feature_root.add_child(head_mesh)

	shoulder_left_mesh = _make_helper_box("ShoulderLeft", Vector3(width * 0.12, height * 0.05, depth * 0.10), top_anchor + Vector3(-width * 0.12, top_stack_gap * 1.8, 0.0))
	shoulder_left_mesh.visible = false
	feature_root.add_child(shoulder_left_mesh)

	shoulder_right_mesh = _make_helper_box("ShoulderRight", Vector3(width * 0.12, height * 0.05, depth * 0.10), top_anchor + Vector3(width * 0.12, top_stack_gap * 1.8, 0.0))
	shoulder_right_mesh.visible = false
	feature_root.add_child(shoulder_right_mesh)

	costume_mesh = _make_helper_box("CostumeMesh", Vector3(width * 0.26, height * 0.10, depth * 0.04), top_anchor + Vector3(0.0, top_stack_gap * 1.1, 0.0))
	costume_mesh.visible = false
	feature_root.add_child(costume_mesh)

	accent_mesh = _make_helper_box("AccentMesh", Vector3(width * 0.045, height * 0.16, depth * 0.02), top_anchor + Vector3(-width * 0.04, top_stack_gap * 0.25, 0.0))
	feature_root.add_child(accent_mesh)

	weakpoint_mesh = _make_helper_box("WeakpointMesh", Vector3(width * 0.04, height * 0.12, depth * 0.018), top_anchor + Vector3(width * 0.05, top_stack_gap * 0.25, 0.0))
	feature_root.add_child(weakpoint_mesh)

	core_mesh = _make_helper_sphere("CoreMesh", width * 0.018, top_anchor + Vector3(width * 0.11, top_stack_gap * 0.30, 0.0))
	feature_root.add_child(core_mesh)

	halo_mesh = _make_helper_capsule("HaloMesh", width * 0.07, height * 0.14, top_anchor + Vector3(width * 0.05, top_stack_gap * 0.20, 0.0))
	feature_root.add_child(halo_mesh)

	eye_left_mesh = _make_helper_sphere("EyeLeft", width * 0.016, top_anchor + Vector3(-width * 0.05, top_stack_gap * 3.1, 0.0))
	feature_root.add_child(eye_left_mesh)

	eye_right_mesh = _make_helper_sphere("EyeRight", width * 0.016, top_anchor + Vector3(width * 0.05, top_stack_gap * 3.1, 0.0))
	feature_root.add_child(eye_right_mesh)

	foot_left_mesh = _make_helper_box("FootLeft", Vector3(width * 0.08, height * 0.04, depth * 0.08), top_anchor + Vector3(-width * 0.08, -top_stack_gap * 0.35, 0.0))
	foot_left_mesh.visible = false
	feature_root.add_child(foot_left_mesh)

	foot_right_mesh = _make_helper_box("FootRight", Vector3(width * 0.08, height * 0.04, depth * 0.08), top_anchor + Vector3(width * 0.08, -top_stack_gap * 0.35, 0.0))
	foot_right_mesh.visible = false
	feature_root.add_child(foot_right_mesh)

	return true


func _apply_imported_generic_materials() -> void:
	if mesh != null:
		mesh.material_override = null
	if accent_mesh != null:
		accent_mesh.material_override = accent_material
	if head_mesh != null:
		head_mesh.material_override = head_material
	if shoulder_left_mesh != null:
		shoulder_left_mesh.material_override = accent_material
	if shoulder_right_mesh != null:
		shoulder_right_mesh.material_override = accent_material
	if weakpoint_mesh != null:
		weakpoint_mesh.material_override = weakpoint_material
	if core_mesh != null:
		core_mesh.material_override = core_material
	if halo_mesh != null:
		halo_mesh.material_override = halo_material
	if eye_left_mesh != null:
		eye_left_mesh.material_override = eye_left_material
	if eye_right_mesh != null:
		eye_right_mesh.material_override = eye_right_material
	if foot_left_mesh != null:
		foot_left_mesh.material_override = limb_material
	if foot_right_mesh != null:
		foot_right_mesh.material_override = limb_material


func _make_helper_sphere(node_name: String, radius: float, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	node.mesh = sphere
	node.position = at
	return node


func _make_helper_box(node_name: String, box_size: Vector3, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var box := BoxMesh.new()
	box.size = box_size
	node.mesh = box
	node.position = at
	return node


func _make_helper_capsule(node_name: String, radius: float, height: float, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = maxf(height, radius * 2.2)
	node.mesh = capsule
	node.position = at
	return node


func _ensure_imported_collider() -> void:
	if body == null:
		return
	if collider == null:
		collider = CollisionShape3D.new()
		body.add_child(collider)
	var center := imported_visual_bounds.position + imported_visual_bounds.size * 0.5
	var radius := maxf(maxf(imported_visual_bounds.size.x, imported_visual_bounds.size.z) * 0.28, 0.22)
	var height := maxf(imported_visual_bounds.size.y - radius * 2.0, 0.65)
	if women_action_enabled:
		radius = maxf(radius, 0.68)
		height = maxf(height, imported_visual_bounds.size.y * 0.92)
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collider.shape = shape
	collider.position = Vector3.ZERO
	body.position = Vector3(center.x, imported_visual_bounds.position.y + radius + height * 0.5, center.z)
	body.collision_layer = 2 if actor_kind == "target" else 4
	body.collision_mask = 0
	if women_action_enabled:
		body_radius = maxf(body_radius, radius * 1.9)


func _find_mesh_instance(root: Node, target_name: String) -> MeshInstance3D:
	if root == null:
		return null
	if root is MeshInstance3D and root.name == target_name:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_mesh_instance(child, target_name)
		if found != null:
			return found
	return null


func _cache_imported_pose() -> void:
	imported_pose_cache.clear()
	for node in [imported_visual_root, head_mesh, costume_mesh, shoulder_left_mesh, shoulder_right_mesh, upper_arm_left_mesh, upper_arm_right_mesh, forearm_left_mesh, forearm_right_mesh, leg_left_mesh, leg_right_mesh, foot_left_mesh, foot_right_mesh, accent_mesh, weakpoint_mesh, core_mesh, halo_mesh]:
		if node == null:
			continue
		imported_pose_cache[node.name] = {
			"position": node.position,
			"rotation": node.rotation_degrees,
			"scale": node.scale,
		}


func _restore_imported_pose(node: Node3D) -> void:
	if node == null:
		return
	var cached: Dictionary = imported_pose_cache.get(node.name, {})
	if cached.is_empty():
		return
	node.position = cached.get("position", node.position)
	node.rotation_degrees = cached.get("rotation", node.rotation_degrees)
	node.scale = cached.get("scale", node.scale)


func _apply_pose_delta(node: Node3D, pos_delta: Vector3 = Vector3.ZERO, rot_delta: Vector3 = Vector3.ZERO, scale_mul: Vector3 = Vector3.ONE) -> void:
	if node == null:
		return
	_restore_imported_pose(node)
	node.position += pos_delta
	node.rotation_degrees += rot_delta
	node.scale *= scale_mul


func _apply_imported_action_pose(now: float, locomotion_pulse: float, breathe_pulse: float, highlighted: bool, _weakpoint_open: bool) -> void:
	if imported_visual_root == null:
		return

	if imported_generic_actor:
		_apply_pose_delta(imported_visual_root, Vector3(0.0, breathe_pulse * 0.01, 0.0), Vector3(breathe_pulse * 1.6, sin(now * 0.9 + phase_offset) * 2.0, 0.0))
		if behavior_type == "moving":
			_apply_pose_delta(imported_visual_root, Vector3.ZERO, Vector3(-4.0, 16.0 + locomotion_pulse * 6.0, 0.0))
		elif highlighted:
			_apply_pose_delta(imported_visual_root, Vector3.ZERO, Vector3(-2.5, 8.0, 0.0))
		else:
			_apply_pose_delta(imported_visual_root, Vector3.ZERO, Vector3(0.0, -4.0, 0.0))
		_apply_pose_delta(head_mesh, Vector3(0.0, 0.0, breathe_pulse * 0.012), Vector3(breathe_pulse * 2.0, sin(now * 0.9 + phase_offset) * 4.0, 0.0))
		_apply_pose_delta(costume_mesh, Vector3(0.0, 0.0, breathe_pulse * 0.008), Vector3(0.0, breathe_pulse * 1.6, 0.0))
		_apply_pose_delta(accent_mesh, Vector3(0.0, 0.0, breathe_pulse * 0.006))
		return

	_apply_pose_delta(head_mesh, Vector3(0.0, 0.0, breathe_pulse * 0.015), Vector3(breathe_pulse * 2.5, sin(now * 0.9 + phase_offset) * 5.0, 0.0))
	_apply_pose_delta(costume_mesh, Vector3(0.0, 0.0, breathe_pulse * 0.010), Vector3(0.0, breathe_pulse * 2.0, 0.0))
	_apply_pose_delta(accent_mesh, Vector3(0.0, 0.0, breathe_pulse * 0.008))

	if behavior_type == "moving":
		_apply_pose_delta(head_mesh, Vector3.ZERO, Vector3(-4.0, 22.0, 0.0))
		_apply_pose_delta(costume_mesh, Vector3(0.0, 0.0, -0.02), Vector3(0.0, 14.0 + locomotion_pulse * 8.0, 0.0))
		_apply_pose_delta(upper_arm_left_mesh, Vector3.ZERO, Vector3(18.0 + locomotion_pulse * 28.0, 0.0, 18.0))
		_apply_pose_delta(upper_arm_right_mesh, Vector3.ZERO, Vector3(-10.0 - locomotion_pulse * 28.0, 0.0, -14.0))
		_apply_pose_delta(forearm_left_mesh, Vector3.ZERO, Vector3(24.0 + locomotion_pulse * 18.0, 0.0, 8.0))
		_apply_pose_delta(forearm_right_mesh, Vector3.ZERO, Vector3(-18.0 - locomotion_pulse * 18.0, 0.0, -8.0))
		_apply_pose_delta(leg_left_mesh, Vector3.ZERO, Vector3(-18.0 - locomotion_pulse * 18.0, 0.0, 0.0))
		_apply_pose_delta(leg_right_mesh, Vector3.ZERO, Vector3(12.0 + locomotion_pulse * 18.0, 0.0, 0.0))
		_apply_pose_delta(foot_left_mesh, Vector3.ZERO, Vector3(8.0 + locomotion_pulse * 8.0, 0.0, 0.0))
		_apply_pose_delta(foot_right_mesh, Vector3.ZERO, Vector3(-5.0 - locomotion_pulse * 8.0, 0.0, 0.0))
		_apply_pose_delta(accent_mesh, Vector3(0.0, 0.0, 0.02), Vector3(0.0, 0.0, 12.0))
	elif highlighted:
		_apply_pose_delta(head_mesh, Vector3(0.0, 0.01, 0.02), Vector3(-6.0, 14.0, 0.0), Vector3(1.02, 1.02, 1.02))
		_apply_pose_delta(costume_mesh, Vector3.ZERO, Vector3(0.0, 8.0, 0.0))
		_apply_pose_delta(upper_arm_left_mesh, Vector3.ZERO, Vector3(10.0, 0.0, 14.0))
		_apply_pose_delta(upper_arm_right_mesh, Vector3.ZERO, Vector3(-14.0, 0.0, -16.0))
		_apply_pose_delta(forearm_left_mesh, Vector3.ZERO, Vector3(-8.0, 0.0, 10.0))
		_apply_pose_delta(forearm_right_mesh, Vector3.ZERO, Vector3(-22.0, 0.0, -14.0))
		_apply_pose_delta(leg_left_mesh, Vector3.ZERO, Vector3(-4.0, 0.0, 0.0))
		_apply_pose_delta(leg_right_mesh, Vector3.ZERO, Vector3(6.0, 0.0, 0.0))
	else:
		_apply_pose_delta(head_mesh, Vector3.ZERO, Vector3(0.0, -8.0, 0.0))
		_apply_pose_delta(costume_mesh, Vector3(0.0, 0.0, 0.01), Vector3(0.0, -4.0, 0.0))
		_apply_pose_delta(upper_arm_left_mesh, Vector3.ZERO, Vector3(12.0 + breathe_pulse * 4.0, 0.0, 10.0))
		_apply_pose_delta(upper_arm_right_mesh, Vector3.ZERO, Vector3(-8.0 + breathe_pulse * 3.0, 0.0, -10.0))
		_apply_pose_delta(forearm_left_mesh, Vector3.ZERO, Vector3(-10.0, 0.0, 4.0))
		_apply_pose_delta(forearm_right_mesh, Vector3.ZERO, Vector3(-12.0, 0.0, -4.0))
		_apply_pose_delta(leg_left_mesh, Vector3.ZERO, Vector3(-2.0, 0.0, 0.0))
		_apply_pose_delta(leg_right_mesh, Vector3.ZERO, Vector3(2.0, 0.0, 0.0))


func _build_billboards() -> void:
	billboard_root = Node3D.new()
	billboard_root.name = "BillboardRoot"
	mesh_root.add_child(billboard_root)

	main_billboard = MeshInstance3D.new()
	main_billboard.name = "MainBillboard"
	var main_quad := QuadMesh.new()
	main_quad.size = Vector2(body_radius * 1.75, body_radius * 2.45)
	main_billboard.mesh = main_quad
	main_billboard.position = Vector3(0.0, body_radius * 1.18, body_radius * 0.42)
	main_billboard.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_configure_billboard_material(main_billboard_material)
	main_billboard.material_override = main_billboard_material
	billboard_root.add_child(main_billboard)

	overlay_billboard = MeshInstance3D.new()
	overlay_billboard.name = "OverlayBillboard"
	var overlay_quad := QuadMesh.new()
	overlay_quad.size = Vector2(body_radius * 1.92, body_radius * 2.62)
	overlay_billboard.mesh = overlay_quad
	overlay_billboard.position = Vector3(0.0, body_radius * 1.20, body_radius * 0.47)
	overlay_billboard.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	_configure_billboard_material(overlay_billboard_material)
	overlay_billboard.material_override = overlay_billboard_material
	billboard_root.add_child(overlay_billboard)


func _configure_billboard_material(target_material: StandardMaterial3D) -> void:
	target_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	target_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	target_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	target_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	target_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	target_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)


func _update_billboards(highlighted: bool, weakpoint_open: bool, target_pulse: float, scan_pulse: float, scan_burst_active: bool, scan_burst_ratio: float) -> void:
	if main_billboard == null or overlay_billboard == null:
		return

	var main_texture: Texture2D = null
	var overlay_texture: Texture2D = null
	var main_alpha: float = 0.84
	var overlay_alpha: float = 0.0
	var main_modulate := Color(1.0, 1.0, 1.0, main_alpha)
	var overlay_modulate := Color(1.0, 1.0, 1.0, overlay_alpha)

	if actor_kind == "target":
		if weakpoint_open:
			main_texture = TEX_ALIEN_WEAKPOINT_OPEN
			main_modulate = Color(1.0, 1.0, 1.0, 0.90)
		elif behavior_type == "moving":
			main_texture = TEX_ALIEN_MOVING_PROFILE
			main_modulate = Color(1.0, 1.0, 1.0, 0.84)
		else:
			main_texture = TEX_ALIEN_DISGUISED_IDLE
			main_modulate = Color(1.0, 1.0, 1.0, 0.82)

		if highlighted or scan_burst_active:
			overlay_texture = TEX_ALIEN_SCAN_HIGHLIGHT
			overlay_modulate = Color(0.96, 1.0, 1.0, 0.42 + 0.20 * scan_pulse + scan_burst_ratio * 0.26)
		elif weakpoint_open:
			overlay_texture = TEX_ALIEN_SCAN_HIGHLIGHT
			overlay_modulate = Color(0.70, 0.94, 1.0, 0.16 + 0.10 * target_pulse)
	else:
		main_texture = TEX_CIVILIAN_CALM_IDLE
		main_modulate = Color(1.0, 1.0, 1.0, 0.86)
		if has_false_clue_active():
			overlay_texture = TEX_CIVILIAN_FALSE_CLUE
			overlay_modulate = Color(1.0, 0.88, 0.58, 0.28 + 0.18 * scan_pulse)
		elif highlighted or scan_burst_active:
			overlay_texture = TEX_ALIEN_SCAN_HIGHLIGHT
			overlay_modulate = Color(0.76, 0.92, 1.0, 0.18 + 0.08 * scan_pulse + scan_burst_ratio * 0.18)

	main_billboard_material.albedo_texture = main_texture
	main_billboard_material.albedo_color = main_modulate
	main_billboard.visible = main_texture != null and alive

	overlay_billboard_material.albedo_texture = overlay_texture
	overlay_billboard_material.albedo_color = overlay_modulate
	overlay_billboard.visible = overlay_texture != null and alive and overlay_modulate.a > 0.01


func get_visual_asset_state() -> Dictionary:
	return {
		"actor_kind": actor_kind,
		"main_texture": main_billboard_material.albedo_texture.resource_path if main_billboard_material.albedo_texture != null else "",
		"overlay_texture": overlay_billboard_material.albedo_texture.resource_path if overlay_billboard_material.albedo_texture != null else "",
		"main_visible": main_billboard.visible if main_billboard != null else false,
		"overlay_visible": overlay_billboard.visible if overlay_billboard != null else false,
	}
