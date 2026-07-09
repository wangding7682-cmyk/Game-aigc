extends Node3D
class_name WeaponRenderer3D

const SEARCH_MOUNT_POS := Vector3(-0.51, -0.7, -1.38)
const SEARCH_MOUNT_ROT := Vector3(10.0, -16.0, 0.0)
const SCOPE_MOUNT_POS := Vector3(1.2, -0.36, -1.0)
const SCOPE_MOUNT_ROT := Vector3(4.0, -6.0, 0.0)
const FX_MUZZLE_FLASH := preload("res://assets_mvp_placeholder/feedback/fx-muzzle-flash.svg")
const TEX_WEAPON_GRIME_PATH := "res://assets_mvp_placeholder/materials/material-weapon-grime-overlay.svg"
const TEX_WEAPON_EDGE_WEAR_PATH := "res://assets_mvp_placeholder/materials/material-weapon-edge-wear-overlay.svg"
const ENABLE_REFINED_WEAPON_TRACK := true
const PATH_WEAPON_RIFLE := "res://assets_mvp_3d/weapons/weapon_fps_rifle.glb"
const PATH_WEAPON_PRECISION := "res://assets_mvp_3d/weapons/weapon_fps_precision.glb"
const PATH_WEAPON_AUTO := "res://assets_mvp_3d/weapons/weapon_fps_auto.glb"
const PATH_WEAPON_PLASMA := "res://assets_mvp_3d/weapons/weapon_fps_plasma.glb"
const PATH_WEAPON_RIFLE_REFINED := "res://assets_mvp_3d/weapons/weapon_fps_rifle_refined.glb"
const PATH_WEAPON_PRECISION_REFINED := "res://assets_mvp_3d/weapons/weapon_fps_precision_refined.glb"
const PATH_WEAPON_AUTO_REFINED := "res://assets_mvp_3d/weapons/weapon_fps_auto_refined.glb"
const PATH_WEAPON_PLASMA_REFINED := "res://assets_mvp_3d/weapons/weapon_fps_plasma_refined.glb"

var view_model_root: Node3D
var barrel_mesh: MeshInstance3D
var stock_mesh: MeshInstance3D
var scope_mesh: MeshInstance3D
var grip_mesh: MeshInstance3D
var body_mesh: MeshInstance3D
var mag_mesh: MeshInstance3D
var muzzle_mesh: MeshInstance3D
var glow_mesh: MeshInstance3D
var muzzle_flash_quad: MeshInstance3D
var body_overlay_quad: MeshInstance3D
var stock_overlay_quad: MeshInstance3D
var scope_overlay_quad: MeshInstance3D
var muzzle_point: Marker3D
var shell_point: Marker3D
var grip_point: Marker3D
var scope_focus_point: Marker3D

var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var accent_material: StandardMaterial3D
var glow_material: StandardMaterial3D
var muzzle_flash_material: StandardMaterial3D
var body_overlay_material: StandardMaterial3D
var stock_overlay_material: StandardMaterial3D
var scope_overlay_material: StandardMaterial3D
var weapon_grime_texture: Texture2D
var weapon_edge_wear_texture: Texture2D

var current_profile: Dictionary = {}
var scope_mode := false
var fire_flash_timer := 0.0
var recoil_offset := 0.0
var recoil_pitch := 0.0
var recoil_yaw := 0.0
var recoil_roll := 0.0
var sway_time := 0.0
var imported_weapon_root: Node3D
var current_scene_key := ""
var current_scene_signature := ""
var current_scene_track := "none"
var current_scene_source_path := ""
var attempted_scene_signature := ""
var attempted_scene_track := "none"
var attempted_scene_source_path := ""
var scope_alignment_ratio := 0.0
var hold_ratio_visual := 0.0
var current_zoom_visual := 1.0
var stability_visual := 0.0
var _optional_scene_cache: Dictionary = {}
var imported_single_mesh := false

var debug_mode_enabled := false
var debug_adjust_search_pos: Vector3 = Vector3.ZERO
var debug_adjust_scope_pos: Vector3 = Vector3.ZERO
var debug_adjust_mode := 0
var debug_label: Label = null


func _ready() -> void:
	_ensure_view_model_root()
	update_from_profile(CoreGameState.get_weapon_profile())
	if not CoreEventBus.weapon_equipped.is_connected(_on_weapon_equipped):
		CoreEventBus.weapon_equipped.connect(_on_weapon_equipped)


func _process(delta: float) -> void:
	_handle_debug_input(delta)
	sway_time += delta
	fire_flash_timer = maxf(0.0, fire_flash_timer - delta)
	recoil_offset = move_toward(recoil_offset, 0.0, delta * 2.8)
	recoil_pitch = move_toward(recoil_pitch, 0.0, delta * 34.0)
	recoil_yaw = move_toward(recoil_yaw, 0.0, delta * 26.0)
	recoil_roll = move_toward(recoil_roll, 0.0, delta * 22.0)
	scope_alignment_ratio = move_toward(scope_alignment_ratio, 1.0 if scope_mode else 0.0, delta * (7.5 if scope_mode else 5.2))
	var mount_pos: Vector3 = SEARCH_MOUNT_POS.lerp(SCOPE_MOUNT_POS, scope_alignment_ratio)
	var mount_rot: Vector3 = SEARCH_MOUNT_ROT.lerp(SCOPE_MOUNT_ROT, scope_alignment_ratio)
	var search_pose_ratio: float = 1.0 - scope_alignment_ratio
	var geometry_type: String = str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile)))
	var search_pose_adjustment := _get_search_pose_adjustment(geometry_type)
	mount_pos += (search_pose_adjustment.get("pos", Vector3.ZERO) as Vector3) * search_pose_ratio
	mount_rot += (search_pose_adjustment.get("rot", Vector3.ZERO) as Vector3) * search_pose_ratio
	var debug_offset: Vector3 = debug_adjust_search_pos.lerp(debug_adjust_scope_pos, scope_alignment_ratio)
	mount_pos += debug_offset
	var base_sway_strength: float = lerpf(0.012, 0.0034, scope_alignment_ratio)
	var stability_suppress: float = lerpf(1.0, 0.42, clampf(hold_ratio_visual * 0.72 + stability_visual * 0.28, 0.0, 1.0))
	var sway_strength: float = base_sway_strength * stability_suppress
	var sway_rot_strength: float = lerpf(0.35, 0.06, scope_alignment_ratio) * stability_suppress
	var zoom_pull: float = clampf((current_zoom_visual - 1.0) / maxf(float(current_profile.get("zoom_max", 2.0)) - 1.0, 0.25), 0.0, 1.0)
	var zoom_pull_back := Vector3(0.0, 0.0, -1.20) * zoom_pull
	view_model_root.position = mount_pos + zoom_pull_back + Vector3(
		sin(sway_time * 1.4) * sway_strength * (1.0 - zoom_pull * 0.18),
		cos(sway_time * 1.9) * sway_strength * 0.6 * (1.0 - zoom_pull * 0.12),
		recoil_offset
	)
	view_model_root.rotation_degrees = mount_rot + Vector3(
		cos(sway_time * 1.2) * sway_rot_strength + recoil_pitch,
		sin(sway_time * 1.5) * sway_rot_strength * 0.7 + recoil_yaw,
		cos(sway_time * 0.9) * sway_rot_strength * 0.15 + recoil_roll
	)
	_update_flash_visual()
	_update_debug_label()


func _handle_debug_input(delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle_weapon_pos"):
		debug_mode_enabled = not debug_mode_enabled
		_ensure_debug_label()
		if debug_label != null:
			debug_label.visible = debug_mode_enabled
	if not debug_mode_enabled:
		return
	var adjust_speed: float = 0.5 * delta
	if Input.is_key_pressed(KEY_SHIFT):
		adjust_speed *= 4.0
	var target_pos: Vector3 = debug_adjust_search_pos if debug_adjust_mode == 0 else debug_adjust_scope_pos
	if Input.is_key_pressed(KEY_I):
		target_pos.y += adjust_speed
	if Input.is_key_pressed(KEY_K):
		target_pos.y -= adjust_speed
	if Input.is_key_pressed(KEY_J):
		target_pos.x -= adjust_speed
	if Input.is_key_pressed(KEY_L):
		target_pos.x += adjust_speed
	if Input.is_key_pressed(KEY_U):
		target_pos.z += adjust_speed
	if Input.is_key_pressed(KEY_O):
		target_pos.z -= adjust_speed
	if debug_adjust_mode == 0:
		debug_adjust_search_pos = target_pos
	else:
		debug_adjust_scope_pos = target_pos
	if Input.is_action_just_pressed("debug_switch_adjust_mode"):
		debug_adjust_mode = 1 - debug_adjust_mode
	if Input.is_action_just_pressed("debug_reset_weapon_pos"):
		if debug_adjust_mode == 0:
			debug_adjust_search_pos = Vector3.ZERO
		else:
			debug_adjust_scope_pos = Vector3.ZERO


func _ensure_debug_label() -> void:
	if debug_label != null:
		return
	var parent := get_tree().root
	if parent == null:
		return
	debug_label = Label.new()
	debug_label.name = "WeaponDebugLabel"
	debug_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	debug_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	debug_label.add_theme_constant_override("outline_size", 4)
	debug_label.position = Vector2(10, 10)
	debug_label.z_index = 100
	parent.add_child(debug_label)


func _update_debug_label() -> void:
	if not debug_mode_enabled or debug_label == null:
		return
	var mode_name: String = "搜索模式" if debug_adjust_mode == 0 else "瞄准模式"
	var search_pos: Vector3 = SEARCH_MOUNT_POS + debug_adjust_search_pos
	var scope_pos: Vector3 = SCOPE_MOUNT_POS + debug_adjust_scope_pos
	debug_label.text = "[武器位置调试] 模式:%s\n搜索: X=%.2f Y=%.2f Z=%.2f\n瞄准: X=%.2f Y=%.2f Z=%.2f\nI/K=上下 J/L=左右 U/O=前后\nF10=切换模式 R=重置 Shift=加速" % [
		mode_name,
		search_pos.x, search_pos.y, search_pos.z,
		scope_pos.x, scope_pos.y, scope_pos.z
	]
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var label_size: Vector2 = debug_label.get_size()
	debug_label.position = Vector2((viewport_size.x - label_size.x) * 0.5, viewport_size.y * 0.25)


func _ensure_view_model_root() -> void:
	if view_model_root != null:
		return
	view_model_root = Node3D.new()
	view_model_root.name = "ViewModelRoot"
	add_child(view_model_root)


func _clear_view_model_root() -> void:
	if view_model_root == null:
		return
	for child in view_model_root.get_children():
		child.queue_free()
	imported_weapon_root = null
	body_mesh = null
	barrel_mesh = null
	scope_mesh = null
	grip_mesh = null
	stock_mesh = null
	mag_mesh = null
	muzzle_mesh = null
	glow_mesh = null
	muzzle_flash_quad = null
	body_overlay_quad = null
	stock_overlay_quad = null
	scope_overlay_quad = null
	muzzle_point = null
	shell_point = null
	grip_point = null
	scope_focus_point = null
	imported_single_mesh = false


func _ensure_materials() -> void:
	if primary_material != null and secondary_material != null and accent_material != null and glow_material != null:
		return
	primary_material = StandardMaterial3D.new()
	primary_material.roughness = 0.36
	primary_material.metallic = 0.72

	secondary_material = StandardMaterial3D.new()
	secondary_material.roughness = 0.72
	secondary_material.metallic = 0.16

	accent_material = StandardMaterial3D.new()
	accent_material.roughness = 0.24
	accent_material.metallic = 0.55

	glow_material = StandardMaterial3D.new()
	glow_material.roughness = 0.0
	glow_material.metallic = 0.0
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.emission_enabled = true
	glow_material.albedo_color = Color(1.0, 0.7, 0.25, 0.0)
	glow_material.emission = Color(1.0, 0.7, 0.25) * 0.0

	muzzle_flash_material = StandardMaterial3D.new()
	muzzle_flash_material.albedo_texture = FX_MUZZLE_FLASH
	muzzle_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	muzzle_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	muzzle_flash_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	muzzle_flash_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	muzzle_flash_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	muzzle_flash_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	muzzle_flash_material.emission_enabled = true
	muzzle_flash_material.emission = Color(1.0, 0.82, 0.46) * 0.0

	_ensure_runtime_material_textures()
	body_overlay_material = _make_overlay_material(weapon_grime_texture, Color(0.72, 0.76, 0.80, 0.30))
	stock_overlay_material = _make_overlay_material(weapon_grime_texture, Color(0.54, 0.56, 0.58, 0.24))
	scope_overlay_material = _make_overlay_material(weapon_edge_wear_texture, Color(0.96, 0.90, 0.82, 0.34))


func _resolve_weapon_scene_descriptor(scene_key: String) -> Dictionary:
	match scene_key:
		"precision":
			var refined_precision := _load_optional_packed_scene(PATH_WEAPON_PRECISION_REFINED)
			if ENABLE_REFINED_WEAPON_TRACK and refined_precision != null:
				return {
					"scene": refined_precision,
					"signature": "precision:refined",
					"track": "sample_refined",
					"source_path": PATH_WEAPON_PRECISION_REFINED,
				}
			return {
				"scene": _load_required_packed_scene(PATH_WEAPON_PRECISION),
				"signature": "precision:default",
				"track": "legacy_default",
				"source_path": PATH_WEAPON_PRECISION,
			}
		"auto":
			var refined_auto := _load_optional_packed_scene(PATH_WEAPON_AUTO_REFINED)
			if ENABLE_REFINED_WEAPON_TRACK and refined_auto != null:
				return {
					"scene": refined_auto,
					"signature": "auto:refined",
					"track": "sample_refined",
					"source_path": PATH_WEAPON_AUTO_REFINED,
				}
			return {
				"scene": _load_required_packed_scene(PATH_WEAPON_AUTO),
				"signature": "auto:default",
				"track": "legacy_default",
				"source_path": PATH_WEAPON_AUTO,
			}
		"plasma":
			var refined_plasma := _load_optional_packed_scene(PATH_WEAPON_PLASMA_REFINED)
			if ENABLE_REFINED_WEAPON_TRACK and refined_plasma != null:
				return {
					"scene": refined_plasma,
					"signature": "plasma:refined",
					"track": "sample_refined",
					"source_path": PATH_WEAPON_PLASMA_REFINED,
				}
			return {
				"scene": _load_required_packed_scene(PATH_WEAPON_PLASMA),
				"signature": "plasma:default",
				"track": "legacy_default",
				"source_path": PATH_WEAPON_PLASMA,
			}
		_:
			var refined_scene := _load_optional_packed_scene(PATH_WEAPON_RIFLE_REFINED)
			if ENABLE_REFINED_WEAPON_TRACK and refined_scene != null:
				return {
					"scene": refined_scene,
					"signature": "rifle:refined",
					"track": "sample_refined",
					"source_path": PATH_WEAPON_RIFLE_REFINED,
				}
			return {
				"scene": _load_required_packed_scene(PATH_WEAPON_RIFLE),
				"signature": "rifle:legacy",
				"track": "legacy_default",
				"source_path": PATH_WEAPON_RIFLE,
			}


func _load_required_packed_scene(resource_path: String) -> PackedScene:
	return _load_optional_packed_scene(resource_path)


func _load_optional_packed_scene(resource_path: String) -> PackedScene:
	if _optional_scene_cache.has(resource_path):
		return _optional_scene_cache[resource_path]
	if not ResourceLoader.exists(resource_path):
		_optional_scene_cache[resource_path] = null
		return null
	var scene := load(resource_path) as PackedScene
	_optional_scene_cache[resource_path] = scene
	return scene


func _ensure_imported_weapon_scene(scene_key: String) -> bool:
	_ensure_view_model_root()
	var scene_descriptor := _resolve_weapon_scene_descriptor(scene_key)
	var scene_res: PackedScene = scene_descriptor.get("scene", null)
	var scene_signature: String = str(scene_descriptor.get("signature", scene_key))
	attempted_scene_signature = scene_signature
	attempted_scene_track = str(scene_descriptor.get("track", "default"))
	attempted_scene_source_path = str(scene_descriptor.get("source_path", ""))
	if scene_res == null:
		return false
	if imported_weapon_root != null and current_scene_key == scene_key and current_scene_signature == scene_signature and is_instance_valid(imported_weapon_root):
		return true
	_clear_view_model_root()
	imported_weapon_root = scene_res.instantiate() as Node3D
	if imported_weapon_root == null:
		return false
	imported_weapon_root.name = "ImportedWeapon"
	view_model_root.add_child(imported_weapon_root)
	current_scene_key = scene_key
	current_scene_signature = scene_signature
	current_scene_track = str(scene_descriptor.get("track", "default"))
	current_scene_source_path = str(scene_descriptor.get("source_path", ""))
	_bind_imported_weapon_nodes(imported_weapon_root)
	return body_mesh != null and barrel_mesh != null and muzzle_point != null


func _bind_imported_weapon_nodes(root: Node) -> void:
	imported_single_mesh = false
	body_mesh = _find_mesh_instance(root, "BodyMesh")
	barrel_mesh = _find_mesh_instance(root, "BarrelMesh")
	scope_mesh = _find_mesh_instance(root, "ScopeMesh")
	grip_mesh = _find_mesh_instance(root, "GripMesh")
	stock_mesh = _find_mesh_instance(root, "StockMesh")
	mag_mesh = _find_mesh_instance(root, "MagMesh")
	muzzle_mesh = _find_mesh_instance(root, "MuzzleMesh")
	glow_mesh = _find_mesh_instance(root, "GlowMesh")
	muzzle_point = _find_marker(root, "MuzzlePoint")
	if muzzle_point == null:
		muzzle_point = _find_marker(root, "Muzzle")
	shell_point = _find_marker(root, "ShellPoint")
	grip_point = _find_marker(root, "Grip")
	scope_focus_point = _find_marker(root, "ScopeFocus")
	if body_mesh == null or barrel_mesh == null:
		var fallback_mesh := _find_first_mesh_instance(root)
		if fallback_mesh != null:
			_bind_single_mesh_import(root, fallback_mesh, str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile))), str(current_profile.get("weapon_id", "default_sniper")))
	_ensure_muzzle_flash_visual()
	_ensure_material_overlay_visuals()


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


func _find_marker(root: Node, target_name: String) -> Marker3D:
	if root == null:
		return null
	if root is Marker3D and root.name == target_name:
		return root as Marker3D
	for child in root.get_children():
		var found := _find_marker(child, target_name)
		if found != null:
			return found
	return null


func _bind_single_mesh_import(root: Node, mesh: MeshInstance3D, geometry_type: String, weapon_id: String) -> void:
	imported_single_mesh = true
	body_mesh = mesh
	barrel_mesh = mesh
	_fit_single_mesh_weapon(mesh, geometry_type)
	_ensure_single_mesh_support_nodes(root, mesh, geometry_type, weapon_id)


func _fit_single_mesh_weapon(mesh: MeshInstance3D, geometry_type: String) -> void:
	if mesh == null:
		return
	var base_aabb := mesh.get_aabb()
	var base_size := base_aabb.size
	var longest_xz := maxf(base_size.x, base_size.z)
	if base_size.z > base_size.x * 1.08:
		mesh.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	else:
		mesh.rotation_degrees = Vector3.ZERO
	var fit_settings := _get_single_mesh_fit_settings(geometry_type)
	var target_length: float = float(fit_settings.get("length", 1.62))
	var target_min_x: float = float(fit_settings.get("min_x", -0.88))
	var target_center_y: float = float(fit_settings.get("center_y", 0.12))
	var target_center_z: float = float(fit_settings.get("center_z", 0.0))
	var scale_factor := target_length / maxf(longest_xz, 0.001)
	mesh.scale = Vector3.ONE * scale_factor
	var bounds := _compute_mesh_bounds_in_parent(mesh)
	var min_pos: Vector3 = bounds.get("min", Vector3.ZERO)
	var max_pos: Vector3 = bounds.get("max", Vector3.ZERO)
	var center := (min_pos + max_pos) * 0.5
	mesh.position += Vector3(
		target_min_x - min_pos.x,
		target_center_y - center.y,
		target_center_z - center.z
	)


func _ensure_single_mesh_support_nodes(root: Node, mesh: MeshInstance3D, geometry_type: String, _weapon_id: String) -> void:
	var bounds := _compute_mesh_bounds_in_parent(mesh)
	var min_pos: Vector3 = bounds.get("min", Vector3.ZERO)
	var max_pos: Vector3 = bounds.get("max", Vector3.ZERO)
	var center := (min_pos + max_pos) * 0.5
	var span: Vector3 = max_pos - min_pos
	if muzzle_point == null:
		muzzle_point = Marker3D.new()
		muzzle_point.name = "MuzzlePoint"
		root.add_child(muzzle_point)
	if shell_point == null:
		shell_point = Marker3D.new()
		shell_point.name = "ShellPoint"
		root.add_child(shell_point)
	if grip_point == null:
		grip_point = Marker3D.new()
		grip_point.name = "Grip"
		root.add_child(grip_point)
	if scope_focus_point == null:
		scope_focus_point = Marker3D.new()
		scope_focus_point.name = "ScopeFocus"
		root.add_child(scope_focus_point)
	if glow_mesh == null:
		glow_mesh = _make_box_mesh("GlowMesh", Vector3(0.28, 0.08, 0.08), glow_material)
		root.add_child(glow_mesh)
	muzzle_point.position = Vector3(max_pos.x + maxf(0.06, span.x * 0.04), center.y, center.z)
	shell_point.position = Vector3(
		lerpf(min_pos.x, max_pos.x, 0.34),
		lerpf(min_pos.y, max_pos.y, 0.64),
		center.z - maxf(0.06, span.z * 0.35)
	)
	grip_point.position = Vector3(
		lerpf(min_pos.x, max_pos.x, 0.26),
		lerpf(min_pos.y, max_pos.y, 0.26),
		center.z
	)
	scope_focus_point.position = Vector3(
		lerpf(min_pos.x, max_pos.x, 0.42),
		lerpf(min_pos.y, max_pos.y, 0.72),
		center.z
	)
	glow_mesh.position = Vector3(
		lerpf(min_pos.x, max_pos.x, 0.58),
		center.y,
		center.z
	)
	match geometry_type:
		"precision":
			_set_box_size(glow_mesh, Vector3(0.18, 0.06, 0.06))
		"auto":
			_set_box_size(glow_mesh, Vector3(0.24, 0.08, 0.08))
		"plasma":
			_set_box_size(glow_mesh, Vector3(0.52, 0.14, 0.12))
		_:
			_set_box_size(glow_mesh, Vector3(0.22, 0.08, 0.08))


func _compute_mesh_bounds_in_parent(mesh: MeshInstance3D) -> Dictionary:
	if mesh == null:
		return {
			"min": Vector3.ZERO,
			"max": Vector3.ZERO,
		}
	var aabb := mesh.get_aabb()
	var min_pos := Vector3(INF, INF, INF)
	var max_pos := Vector3(-INF, -INF, -INF)
	for x_flag in [0.0, 1.0]:
		for y_flag in [0.0, 1.0]:
			for z_flag in [0.0, 1.0]:
				var point := aabb.position + Vector3(aabb.size.x * x_flag, aabb.size.y * y_flag, aabb.size.z * z_flag)
				var transformed := mesh.transform * point
				min_pos = Vector3(minf(min_pos.x, transformed.x), minf(min_pos.y, transformed.y), minf(min_pos.z, transformed.z))
				max_pos = Vector3(maxf(max_pos.x, transformed.x), maxf(max_pos.y, transformed.y), maxf(max_pos.z, transformed.z))
	return {
		"min": min_pos,
		"max": max_pos,
	}


func _get_search_pose_adjustment(geometry_type: String) -> Dictionary:
	match geometry_type:
		"precision":
			return {
				"pos": Vector3(-0.08, 0.07, -0.10),
				"rot": Vector3(-3.2, -7.0, -4.4),
			}
		"auto":
			return {
				"pos": Vector3(-0.06, 0.08, -0.08),
				"rot": Vector3(-4.0, -8.0, -5.2),
			}
		"plasma":
			return {
				"pos": Vector3(-0.07, 0.06, -0.08),
				"rot": Vector3(-3.0, -6.5, -4.0),
			}
		_:
			return {
				"pos": Vector3(-0.06, 0.05, -0.08),
				"rot": Vector3(-2.6, -5.8, -3.6),
			}


func _get_single_mesh_fit_settings(geometry_type: String) -> Dictionary:
	match geometry_type:
		"precision":
			return {
				"length": 1.58,
				"min_x": -1.02,
				"center_y": 0.18,
				"center_z": 0.0,
			}
		"auto":
			return {
				"length": 1.28,
				"min_x": -1.00,
				"center_y": 0.22,
				"center_z": 0.0,
			}
		"plasma":
			return {
				"length": 1.50,
				"min_x": -0.86,
				"center_y": 0.12,
				"center_z": 0.0,
			}
		_:
			return {
				"length": 1.64,
				"min_x": -0.88,
				"center_y": 0.12,
				"center_z": 0.0,
			}


func _build_weapon_geometry() -> void:
	_ensure_view_model_root()
	_clear_view_model_root()
	current_scene_key = "procedural"
	current_scene_signature = "procedural"
	current_scene_track = "procedural"
	current_scene_source_path = ""
	_ensure_materials()

	body_mesh = _make_box_mesh("BodyMesh", Vector3(1.1, 0.26, 0.26), primary_material)
	body_mesh.position = Vector3(0.04, 0.0, 0.0)
	view_model_root.add_child(body_mesh)

	barrel_mesh = _make_box_mesh("BarrelMesh", Vector3(1.5, 0.14, 0.14), primary_material)
	barrel_mesh.position = Vector3(0.98, 0.02, 0.0)
	view_model_root.add_child(barrel_mesh)

	muzzle_mesh = _make_cylinder_mesh("MuzzleMesh", 0.055, 0.16, accent_material)
	muzzle_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	muzzle_mesh.position = Vector3(1.78, 0.02, 0.0)
	view_model_root.add_child(muzzle_mesh)

	stock_mesh = _make_box_mesh("StockMesh", Vector3(0.68, 0.28, 0.30), secondary_material)
	stock_mesh.position = Vector3(-0.72, -0.01, 0.0)
	view_model_root.add_child(stock_mesh)

	grip_mesh = _make_box_mesh("GripMesh", Vector3(0.18, 0.40, 0.16), secondary_material)
	grip_mesh.position = Vector3(-0.14, -0.24, 0.0)
	view_model_root.add_child(grip_mesh)

	mag_mesh = _make_box_mesh("MagMesh", Vector3(0.20, 0.34, 0.18), secondary_material)
	mag_mesh.position = Vector3(0.26, -0.22, 0.0)
	view_model_root.add_child(mag_mesh)

	scope_mesh = _make_box_mesh("ScopeMesh", Vector3(0.42, 0.18, 0.18), accent_material)
	scope_mesh.position = Vector3(0.22, 0.18, 0.0)
	view_model_root.add_child(scope_mesh)

	glow_mesh = _make_box_mesh("GlowMesh", Vector3(0.40, 0.12, 0.12), glow_material)
	glow_mesh.position = Vector3(0.54, 0.08, 0.0)
	glow_mesh.visible = false
	view_model_root.add_child(glow_mesh)

	muzzle_point = Marker3D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector3(1.90, 0.02, 0.0)
	view_model_root.add_child(muzzle_point)

	shell_point = Marker3D.new()
	shell_point.name = "ShellPoint"
	shell_point.position = Vector3(0.22, 0.14, -0.08)
	view_model_root.add_child(shell_point)

	grip_point = Marker3D.new()
	grip_point.name = "Grip"
	grip_point.position = Vector3(-0.14, -0.10, 0.0)
	view_model_root.add_child(grip_point)

	scope_focus_point = Marker3D.new()
	scope_focus_point.name = "ScopeFocus"
	scope_focus_point.position = Vector3(0.22, 0.18, 0.0)
	view_model_root.add_child(scope_focus_point)
	_ensure_muzzle_flash_visual()
	_ensure_material_overlay_visuals()


func _ensure_muzzle_flash_visual() -> void:
	if muzzle_point == null:
		return
	_ensure_materials()
	if muzzle_flash_quad != null and is_instance_valid(muzzle_flash_quad):
		if muzzle_flash_quad.get_parent() != muzzle_point:
			muzzle_point.add_child(muzzle_flash_quad)
		return
	muzzle_flash_quad = MeshInstance3D.new()
	muzzle_flash_quad.name = "MuzzleFlashQuad"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34, 0.34)
	muzzle_flash_quad.mesh = quad
	muzzle_flash_quad.material_override = muzzle_flash_material
	muzzle_flash_quad.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	muzzle_flash_quad.position = Vector3(0.07, 0.0, 0.0)
	muzzle_flash_quad.visible = false
	muzzle_point.add_child(muzzle_flash_quad)


func _ensure_runtime_material_textures() -> void:
	if weapon_grime_texture == null:
		weapon_grime_texture = _load_svg_texture_runtime(TEX_WEAPON_GRIME_PATH)
	if weapon_edge_wear_texture == null:
		weapon_edge_wear_texture = _load_svg_texture_runtime(TEX_WEAPON_EDGE_WEAR_PATH)


func _make_overlay_material(texture: Texture2D, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return material


func _ensure_material_overlay_visuals() -> void:
	if view_model_root == null:
		return
	_ensure_materials()
	if body_overlay_quad == null or not is_instance_valid(body_overlay_quad):
		body_overlay_quad = _make_overlay_quad("BodyOverlay", Vector2(0.98, 0.30), body_overlay_material)
		view_model_root.add_child(body_overlay_quad)
	if stock_overlay_quad == null or not is_instance_valid(stock_overlay_quad):
		stock_overlay_quad = _make_overlay_quad("StockOverlay", Vector2(0.56, 0.24), stock_overlay_material)
		view_model_root.add_child(stock_overlay_quad)
	if scope_overlay_quad == null or not is_instance_valid(scope_overlay_quad):
		scope_overlay_quad = _make_overlay_quad("ScopeOverlay", Vector2(0.46, 0.16), scope_overlay_material)
		view_model_root.add_child(scope_overlay_quad)
	_update_material_overlay_layout(str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile))))


func _make_overlay_quad(node_name: String, size: Vector2, material: StandardMaterial3D) -> MeshInstance3D:
	var quad_node := MeshInstance3D.new()
	quad_node.name = node_name
	var quad := QuadMesh.new()
	quad.size = size
	quad_node.mesh = quad
	quad_node.material_override = material
	quad_node.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	return quad_node


func _update_material_overlay_layout(geometry_type: String) -> void:
	if body_overlay_quad == null or stock_overlay_quad == null or scope_overlay_quad == null:
		return
	match geometry_type:
		"precision":
			body_overlay_quad.position = Vector3(0.26, 0.13, 0.10)
			stock_overlay_quad.position = Vector3(-0.74, 0.08, 0.12)
			scope_overlay_quad.position = Vector3(0.34, 0.28, 0.11)
		"auto":
			body_overlay_quad.position = Vector3(0.18, 0.12, 0.11)
			stock_overlay_quad.position = Vector3(-0.66, 0.07, 0.11)
			scope_overlay_quad.position = Vector3(0.18, 0.23, 0.12)
		"plasma":
			body_overlay_quad.position = Vector3(0.12, 0.13, 0.11)
			stock_overlay_quad.position = Vector3(-0.56, 0.08, 0.12)
			scope_overlay_quad.position = Vector3(0.10, 0.27, 0.14)
		_:
			body_overlay_quad.position = Vector3(0.18, 0.13, 0.10)
			stock_overlay_quad.position = Vector3(-0.62, 0.08, 0.11)
			scope_overlay_quad.position = Vector3(0.24, 0.26, 0.11)


func _make_box_mesh(node_name: String, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	return node


func _make_cylinder_mesh(node_name: String, radius: float, height: float, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.material_override = material
	return node


func update_from_profile(profile: Dictionary) -> void:
	current_profile = profile.duplicate(true)
	_ensure_materials()
	var primary_color: Color = profile.get("primary_color", Color(0.7, 0.7, 0.7))
	var secondary_color: Color = profile.get("secondary_color", Color(0.3, 0.3, 0.3))
	var accent_color: Color = profile.get("accent_color", primary_color.lightened(0.08))
	var has_glow: bool = bool(profile.get("has_glow", false))
	var glow_color: Color = profile.get("glow_color", Color(0.0, 0.0, 0.0))
	var glow_intensity: float = float(profile.get("glow_intensity", 0.0))
	var geometry_type: String = str(profile.get("geometry_type", _resolve_geometry_type(profile)))
	var weapon_id: String = str(profile.get("weapon_id", "default_sniper"))
	var using_imported := _ensure_imported_weapon_scene(geometry_type)
	if not using_imported and body_mesh == null:
		_build_weapon_geometry()

	primary_material.albedo_color = primary_color
	secondary_material.albedo_color = secondary_color
	accent_material.albedo_color = accent_color
	primary_material.roughness = 0.24
	primary_material.metallic = 0.82
	secondary_material.roughness = 0.86
	secondary_material.metallic = 0.08
	accent_material.roughness = 0.18
	accent_material.metallic = 0.62

	if body_mesh != null:
		body_mesh.material_override = primary_material
	if barrel_mesh != null:
		barrel_mesh.material_override = primary_material
	if stock_mesh != null:
		stock_mesh.material_override = secondary_material
	if grip_mesh != null:
		grip_mesh.material_override = secondary_material
	if mag_mesh != null:
		mag_mesh.material_override = secondary_material
	if scope_mesh != null:
		scope_mesh.material_override = accent_material
	if muzzle_mesh != null:
		muzzle_mesh.material_override = accent_material
	glow_material.albedo_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
	glow_material.emission = glow_color * maxf(glow_intensity, 0.0)
	if glow_mesh != null:
		glow_mesh.visible = has_glow
		glow_mesh.material_override = glow_material

	if not using_imported:
		_apply_geometry_preset(geometry_type, weapon_id)
	_update_material_overlay_layout(geometry_type)
	if body_overlay_material != null:
		body_overlay_material.albedo_color = Color(primary_color.r * 1.06, primary_color.g * 1.04, primary_color.b * 0.98, 0.24)
	if stock_overlay_material != null:
		stock_overlay_material.albedo_color = Color(secondary_color.r * 0.92, secondary_color.g * 0.92, secondary_color.b * 0.90, 0.20)
	if scope_overlay_material != null:
		scope_overlay_material.albedo_color = Color(accent_color.r * 1.15, accent_color.g * 1.08, accent_color.b * 0.94, 0.30)
	if scope_mesh != null:
		scope_mesh.visible = weapon_id.find("sniper") != -1 or geometry_type == "precision"
	_update_flash_visual()


func _resolve_geometry_type(profile: Dictionary) -> String:
	var weapon_id: String = str(profile.get("weapon_id", "default_sniper"))
	if weapon_id.find("plasma") != -1:
		return "plasma"
	if weapon_id.find("auto") != -1:
		return "auto"
	if weapon_id.find("precision") != -1:
		return "precision"
	return "rifle"


func _apply_geometry_preset(geometry_type: String, weapon_id: String = "") -> void:
	match geometry_type:
		"precision":
			_set_box_size(body_mesh, Vector3(1.28, 0.20, 0.18))
			_set_box_size(barrel_mesh, Vector3(1.86, 0.12, 0.12))
			_set_box_size(stock_mesh, Vector3(0.84, 0.24, 0.24))
			_set_box_size(grip_mesh, Vector3(0.16, 0.42, 0.14))
			_set_box_size(mag_mesh, Vector3(0.18, 0.26, 0.14))
			_set_box_size(scope_mesh, Vector3(0.72, 0.16, 0.16))
			_set_box_size(glow_mesh, Vector3(0.34, 0.08, 0.08))
			body_mesh.position = Vector3(0.10, 0.0, 0.0)
			barrel_mesh.position = Vector3(1.18, 0.03, 0.0)
			stock_mesh.position = Vector3(-0.86, -0.01, 0.0)
			grip_mesh.position = Vector3(-0.16, -0.23, 0.0)
			mag_mesh.position = Vector3(0.24, -0.19, 0.0)
			scope_mesh.position = Vector3(0.26, 0.18, 0.0)
			glow_mesh.position = Vector3(0.92, 0.02, 0.0)
			muzzle_mesh.position = Vector3(2.10, 0.03, 0.0)
			muzzle_point.position = Vector3(2.24, 0.03, 0.0)
			shell_point.position = Vector3(0.28, 0.12, -0.08)
			if grip_point != null:
				grip_point.position = Vector3(-0.16, -0.10, 0.0)
			if scope_focus_point != null:
				scope_focus_point.position = Vector3(0.26, 0.18, 0.0)
		"auto":
			_set_box_size(body_mesh, Vector3(1.18, 0.28, 0.28))
			_set_box_size(barrel_mesh, Vector3(1.48, 0.16, 0.16))
			_set_box_size(stock_mesh, Vector3(0.70, 0.30, 0.32))
			_set_box_size(grip_mesh, Vector3(0.20, 0.44, 0.18))
			_set_box_size(mag_mesh, Vector3(0.24, 0.44, 0.18))
			_set_box_size(scope_mesh, Vector3(0.36, 0.12, 0.18))
			_set_box_size(glow_mesh, Vector3(0.48, 0.12, 0.10))
			body_mesh.position = Vector3(0.04, 0.0, 0.0)
			barrel_mesh.position = Vector3(1.00, 0.02, 0.0)
			stock_mesh.position = Vector3(-0.72, 0.0, 0.0)
			grip_mesh.position = Vector3(-0.06, -0.26, 0.0)
			mag_mesh.position = Vector3(0.34, -0.26, 0.0)
			scope_mesh.position = Vector3(0.16, 0.16, 0.0)
			glow_mesh.position = Vector3(0.44, 0.08, 0.0)
			muzzle_mesh.position = Vector3(1.80, 0.02, 0.0)
			muzzle_point.position = Vector3(1.94, 0.02, 0.0)
			shell_point.position = Vector3(0.12, 0.13, -0.08)
			if grip_point != null:
				grip_point.position = Vector3(-0.06, -0.12, 0.0)
			if scope_focus_point != null:
				scope_focus_point.position = Vector3(0.16, 0.16, 0.0)
		"plasma":
			_set_box_size(body_mesh, Vector3(1.04, 0.30, 0.26))
			_set_box_size(barrel_mesh, Vector3(1.30, 0.18, 0.18))
			_set_box_size(stock_mesh, Vector3(0.62, 0.28, 0.30))
			_set_box_size(grip_mesh, Vector3(0.18, 0.42, 0.18))
			_set_box_size(mag_mesh, Vector3(0.28, 0.32, 0.22))
			_set_box_size(scope_mesh, Vector3(0.28, 0.18, 0.24))
			_set_box_size(glow_mesh, Vector3(0.72, 0.18, 0.18))
			body_mesh.position = Vector3(0.00, 0.0, 0.0)
			barrel_mesh.position = Vector3(0.88, 0.03, 0.0)
			stock_mesh.position = Vector3(-0.64, 0.0, 0.0)
			grip_mesh.position = Vector3(-0.04, -0.25, 0.0)
			mag_mesh.position = Vector3(0.36, -0.05, 0.0)
			scope_mesh.position = Vector3(0.08, 0.20, 0.0)
			glow_mesh.position = Vector3(0.56, 0.03, 0.0)
			muzzle_mesh.position = Vector3(1.60, 0.03, 0.0)
			muzzle_point.position = Vector3(1.72, 0.03, 0.0)
			shell_point.position = Vector3(0.08, 0.12, -0.08)
			if grip_point != null:
				grip_point.position = Vector3(-0.04, -0.11, 0.0)
			if scope_focus_point != null:
				scope_focus_point.position = Vector3(0.08, 0.20, 0.0)
		_:
			_set_box_size(body_mesh, Vector3(1.10, 0.26, 0.26))
			_set_box_size(barrel_mesh, Vector3(1.50, 0.14, 0.14))
			_set_box_size(stock_mesh, Vector3(0.68, 0.28, 0.30))
			_set_box_size(grip_mesh, Vector3(0.18, 0.40, 0.16))
			_set_box_size(mag_mesh, Vector3(0.20, 0.34, 0.18))
			_set_box_size(scope_mesh, Vector3(0.42, 0.18, 0.18))
			_set_box_size(glow_mesh, Vector3(0.40, 0.12, 0.12))
			body_mesh.position = Vector3(0.04, 0.0, 0.0)
			barrel_mesh.position = Vector3(0.98, 0.02, 0.0)
			stock_mesh.position = Vector3(-0.72, -0.01, 0.0)
			grip_mesh.position = Vector3(-0.14, -0.24, 0.0)
			mag_mesh.position = Vector3(0.26, -0.22, 0.0)
			scope_mesh.position = Vector3(0.22, 0.18, 0.0)
			glow_mesh.position = Vector3(0.54, 0.08, 0.0)
			muzzle_mesh.position = Vector3(1.78, 0.02, 0.0)
			muzzle_point.position = Vector3(1.90, 0.02, 0.0)
			shell_point.position = Vector3(0.22, 0.14, -0.08)
			if grip_point != null:
				grip_point.position = Vector3(-0.14, -0.10, 0.0)
			if scope_focus_point != null:
				scope_focus_point.position = Vector3(0.22, 0.18, 0.0)
	if weapon_id.find("sniper") != -1:
		scope_mesh.visible = true


func _set_box_size(node: MeshInstance3D, size: Vector3) -> void:
	if node == null or node.mesh == null:
		return
	if node.mesh is BoxMesh:
		(node.mesh as BoxMesh).size = size


func set_scope_mode(active: bool) -> void:
	scope_mode = active


func update_presentation(scope_active: bool, current_zoom: float, hold_ratio: float, stability_factor: float = -1.0) -> void:
	scope_mode = scope_active
	current_zoom_visual = current_zoom
	hold_ratio_visual = clampf(hold_ratio, 0.0, 1.0)
	if stability_factor >= 0.0:
		stability_visual = clampf(stability_factor, 0.0, 1.0)
	else:
		var idle_spread := float(current_profile.get("spread_idle", 34.0))
		var hold_spread := float(current_profile.get("spread_hold", 10.0))
		stability_visual = clampf(1.0 - ((idle_spread * 0.55 + hold_spread * 0.45) / 34.0), 0.0, 1.0)


func trigger_fire_feedback(result: String = "miss") -> void:
	recoil_offset = -0.16
	recoil_pitch = 2.4
	recoil_yaw = randf_range(-0.28, 0.28)
	recoil_roll = randf_range(-0.55, 0.55)
	fire_flash_timer = 0.08
	if result == "blocked":
		recoil_offset = -0.11
		recoil_pitch = 1.6
		recoil_roll *= 0.7
	elif result == "hit":
		recoil_offset = -0.18
		recoil_pitch = 2.9
		recoil_roll *= 0.85
	elif result == "wrong_hit":
		recoil_offset = -0.20
		recoil_pitch = 3.2
		recoil_yaw *= 1.2
		recoil_roll *= 1.15


func _update_flash_visual() -> void:
	if glow_mesh == null:
		return
	if fire_flash_timer > 0.0:
		var flash_alpha: float = clampf(fire_flash_timer / 0.08, 0.0, 1.0)
		glow_mesh.visible = true
		glow_material.albedo_color.a = 0.18 * flash_alpha
		glow_material.emission = glow_material.emission.lerp(Color(1.0, 0.78, 0.32) * 5.5, flash_alpha)
		if muzzle_flash_quad != null and is_instance_valid(muzzle_flash_quad):
			muzzle_flash_quad.visible = true
			muzzle_flash_quad.scale = Vector3.ONE * lerpf(0.72, 1.28, flash_alpha)
			muzzle_flash_material.albedo_color.a = 0.82 * flash_alpha
			muzzle_flash_material.emission = Color(1.0, 0.82, 0.46) * (2.6 * flash_alpha)
		if scope_overlay_material != null:
			scope_overlay_material.albedo_color.a = 0.30 + flash_alpha * 0.10
	else:
		var has_profile_glow: bool = bool(current_profile.get("has_glow", false))
		glow_mesh.visible = has_profile_glow
		glow_material.albedo_color.a = 0.08 if has_profile_glow else 0.0
		var base_glow_color: Color = current_profile.get("glow_color", Color(0.0, 0.0, 0.0))
		var glow_intensity: float = float(current_profile.get("glow_intensity", 0.0))
		glow_material.emission = base_glow_color * glow_intensity
		if muzzle_flash_quad != null and is_instance_valid(muzzle_flash_quad):
			muzzle_flash_quad.visible = false
			muzzle_flash_material.albedo_color.a = 0.0
			muzzle_flash_material.emission = Color(1.0, 0.82, 0.46) * 0.0
		if scope_overlay_material != null:
			scope_overlay_material.albedo_color.a = 0.30


func _load_svg_texture_runtime(svg_path: String) -> Texture2D:
	var svg_text := FileAccess.get_file_as_string(svg_path)
	if svg_text.is_empty():
		return null
	var image := Image.new()
	var err := image.load_svg_from_string(svg_text)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func get_mount_state() -> Dictionary:
	return {
		"exists": true,
		"scope_mode": scope_mode,
		"weapon_id": str(current_profile.get("weapon_id", "")),
		"geometry_type": str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile))),
		"scene_track": current_scene_track,
		"scene_signature": current_scene_signature,
		"scene_source_path": current_scene_source_path,
		"attempted_scene_track": attempted_scene_track,
		"attempted_scene_signature": attempted_scene_signature,
		"attempted_scene_source_path": attempted_scene_source_path,
		"imported_single_mesh": imported_single_mesh,
		"sample_refined_enabled": ENABLE_REFINED_WEAPON_TRACK,
		"sample_refined_available": _load_optional_packed_scene(PATH_WEAPON_RIFLE_REFINED) != null if str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile))) == "rifle" else (
			_load_optional_packed_scene(PATH_WEAPON_PRECISION_REFINED) != null if str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile))) == "precision" else (
				_load_optional_packed_scene(PATH_WEAPON_AUTO_REFINED) != null if str(current_profile.get("geometry_type", _resolve_geometry_type(current_profile))) == "auto" else _load_optional_packed_scene(PATH_WEAPON_PLASMA_REFINED) != null
			)
		),
		"muzzle_local_position": muzzle_point.position if muzzle_point != null else Vector3.ZERO,
		"muzzle_global_position": muzzle_point.global_position if muzzle_point != null else Vector3.ZERO,
		"muzzle_flash_texture": FX_MUZZLE_FLASH.resource_path,
		"shell_local_position": shell_point.position if shell_point != null else Vector3.ZERO,
		"grip_local_position": grip_point.position if grip_point != null else Vector3.ZERO,
		"scope_focus_local_position": scope_focus_point.position if scope_focus_point != null else Vector3.ZERO,
	}


func _on_weapon_equipped(_weapon_id: String) -> void:
	update_from_profile(CoreGameState.get_weapon_profile())
