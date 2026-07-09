extends "res://scripts/pve/pve_battle_controller_base.gd"

const HudScene = preload("res://scenes/ui/ui_hud_pve.tscn")
const TutorialScene = preload("res://scenes/tutorial/tutorial_flow_intro.tscn")
const InputBootstrap = preload("res://scripts/core/core_input_bootstrap.gd")
const CAMERA_CONTROLLER_3D_SCRIPT = preload("res://scripts/pve/camera_controller_3d.gd")
const BATTLE_CORE_3D_SCRIPT = preload("res://scripts/pve/battle_core_3d.gd")
const VISUAL_FEEDBACK_3D_SCRIPT = preload("res://scripts/pve/visual_feedback_3d.gd")
const BATTLE_MODE_PVE_3D_SCRIPT = preload("res://scripts/pve/battle_mode_pve_3d.gd")
const HUD_CONTROLLER_SCRIPT = preload("res://scripts/pve/hud_controller.gd")
const COVER_OBSTACLE_3D_SCRIPT = preload("res://scripts/pve/pve_cover_obstacle_3d.gd")
const FOLIAGE_PROP_3D_SCRIPT = preload("res://scripts/pve/pve_foliage_prop_3d.gd")
const WEAPON_RENDERER_3D_SCRIPT = preload("res://scripts/ui/weapon_renderer_3d.gd")
const LEVEL_STREET_BLOCK_SCENE := preload("res://assets_mvp_3d/level/street_block_mvp.glb")

@onready var aim_camera: Camera3D = $AimCamera
@onready var world_root: Node3D = $WorldRoot
@onready var level_root: Node3D = $WorldRoot/LevelRoot
@onready var actor_root: Node3D = $WorldRoot/ActorRoot
@onready var decal_root: Node3D = $WorldRoot/DecalRoot
@onready var fx_root: Node3D = $WorldRoot/FxRoot

var camera_controller = null
var weapon = null
var battle_core = null
var input_handler = null
var visual_feedback = null
var battle_mode = null
var hud_controller = null
var weapon_renderer = null

var world_bounds_x := Vector2(-12.0, 12.0)
var world_bounds_z := Vector2(-9.0, 9.0)
var cover_obstacles_3d: Array = []
var runtime_target_greenery_nodes: Array = []
var runtime_greenery_cover_nodes: Array = []
var _battle_finish_processing := false


func _get(property: StringName):
	if property == &"battle_finished" or property == &"battle_closed":
		return null
	if battle_core != null and is_instance_valid(battle_core):
		var val = battle_core.get(property)
		if typeof(val) != TYPE_NIL and typeof(val) != TYPE_SIGNAL:
			return val
	if camera_controller != null and is_instance_valid(camera_controller):
		var val2 = camera_controller.get(property)
		if typeof(val2) != TYPE_NIL and typeof(val2) != TYPE_SIGNAL:
			return val2
	return null


func _set(property: StringName, value) -> bool:
	if property == &"battle_finished" or property == &"battle_closed":
		return false
	if battle_core != null and is_instance_valid(battle_core):
		var cur = battle_core.get(property)
		if typeof(cur) != TYPE_NIL and typeof(cur) != TYPE_SIGNAL:
			battle_core.set(property, value)
			return true
	if camera_controller != null and is_instance_valid(camera_controller):
		var cur2 = camera_controller.get(property)
		if typeof(cur2) != TYPE_NIL and typeof(cur2) != TYPE_SIGNAL:
			camera_controller.set(property, value)
			return true
	return false


func _ready() -> void:
	InputBootstrap.ensure_default_input_map()
	level_config = CoreGameState.get_level_config()
	_setup_lighting()
	_build_level_placeholder()
	_init_modules()
	_setup_battle_mode()
	_spawn_cover_obstacles()
	call_deferred("_rebuild_runtime_target_greenery_after_spawn")
	mount_hud(HudScene)
	mount_tutorial(TutorialScene)
	_setup_hud_connections()
	_setup_intro_focus()
	push_feedback("%s\n%s" % [level_config.display_name, level_config.flavor_text], Color(0.92, 0.95, 1.0))
	log_level_entered()


func _setup_lighting() -> void:
	var style_profile: Dictionary = _get_level_style_profile(int(level_config.level_id))
	var sun_light := DirectionalLight3D.new()
	sun_light.position = Vector3(-6.0, 12.0, 8.0)
	sun_light.rotation_degrees = style_profile.get("sun_rotation", Vector3(-55.0, -35.0, 0.0))
	sun_light.light_energy = float(style_profile.get("sun_energy", 1.15))
	sun_light.light_color = style_profile.get("sun_color", Color(1.0, 0.96, 0.88))
	sun_light.shadow_enabled = true
	sun_light.shadow_opacity = float(style_profile.get("sun_shadow_opacity", 0.55))
	world_root.add_child(sun_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.position = Vector3(5.0, 8.0, -6.0)
	fill_light.rotation_degrees = style_profile.get("fill_rotation", Vector3(-45.0, 40.0, 0.0))
	fill_light.light_energy = float(style_profile.get("fill_energy", 0.35))
	fill_light.light_color = style_profile.get("fill_color", Color(0.72, 0.82, 1.0))
	world_root.add_child(fill_light)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = style_profile.get("ambient_color", Color(0.32, 0.36, 0.44))
	env.ambient_light_energy = float(style_profile.get("ambient_energy", 0.55))
	env.fog_enabled = true
	env.fog_light_color = style_profile.get("fog_color", Color(0.55, 0.62, 0.74))
	env.fog_density = float(style_profile.get("fog_density", 0.018))
	env.background_mode = Environment.BG_COLOR
	env.background_color = style_profile.get("background_color", Color(0.12, 0.14, 0.18))
	world_env.environment = env
	world_root.add_child(world_env)


func _build_level_placeholder() -> void:
	for child in level_root.get_children():
		child.queue_free()

	if int(level_config.level_id) == 1:
		_build_level_one_placeholder()
		_add_level_decorations(int(level_config.level_id))
		return

	if LEVEL_STREET_BLOCK_SCENE != null:
		var imported_level := LEVEL_STREET_BLOCK_SCENE.instantiate() as Node3D
		if imported_level != null:
			while imported_level.get_child_count() > 0:
				var child := imported_level.get_child(0)
				imported_level.remove_child(child)
				child.owner = null
				level_root.add_child(child)
			imported_level.queue_free()
			_add_level_decorations(int(level_config.level_id))
			return

	var street := MeshInstance3D.new()
	street.name = "StreetBase"
	var street_mesh := BoxMesh.new()
	street_mesh.size = Vector3(28.0, 0.2, 18.0)
	street.mesh = street_mesh
	street.position = Vector3(0.0, -0.1, 0.0)
	var street_mat := StandardMaterial3D.new()
	street_mat.albedo_color = Color(0.16, 0.17, 0.19)
	street_mat.roughness = 0.92
	street.material_override = street_mat
	level_root.add_child(street)

	var lane := MeshInstance3D.new()
	lane.name = "LaneStrip"
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(0.16, 0.02, 14.0)
	lane.mesh = lane_mesh
	lane.position = Vector3(0.0, 0.02, 0.0)
	var lane_mat := StandardMaterial3D.new()
	lane_mat.albedo_color = Color(0.95, 0.82, 0.38)
	lane_mat.emission_enabled = true
	lane_mat.emission = Color(0.8, 0.62, 0.2) * 0.15
	lane.material_override = lane_mat
	level_root.add_child(lane)

	for side in [-1.0, 1.0]:
		var sidewalk := MeshInstance3D.new()
		sidewalk.name = "Sidewalk%s" % ("Left" if side < 0.0 else "Right")
		var sidewalk_mesh := BoxMesh.new()
		sidewalk_mesh.size = Vector3(5.0, 0.28, 18.0)
		sidewalk.mesh = sidewalk_mesh
		sidewalk.position = Vector3(side * 11.5, 0.02, 0.0)
		var sidewalk_mat := StandardMaterial3D.new()
		sidewalk_mat.albedo_color = Color(0.28, 0.3, 0.34)
		sidewalk_mat.roughness = 0.95
		sidewalk.material_override = sidewalk_mat
		level_root.add_child(sidewalk)

		var backdrop := MeshInstance3D.new()
		backdrop.name = "BackdropBlock%s" % ("Left" if side < 0.0 else "Right")
		var backdrop_mesh := BoxMesh.new()
		backdrop_mesh.size = Vector3(3.4, 6.0, 18.0)
		backdrop.mesh = backdrop_mesh
		backdrop.position = Vector3(side * 14.6, 3.0, 0.0)
		var backdrop_mat := StandardMaterial3D.new()
		backdrop_mat.albedo_color = Color(0.18, 0.2, 0.24)
		backdrop_mat.roughness = 0.98
		backdrop.material_override = backdrop_mat
		level_root.add_child(backdrop)

	var spawn_band := MeshInstance3D.new()
	spawn_band.name = "SpawnReadableBand"
	var spawn_mesh := BoxMesh.new()
	spawn_mesh.size = Vector3(22.0, 0.01, 10.0)
	spawn_band.mesh = spawn_mesh
	spawn_band.position = Vector3(0.0, 0.03, 0.5)
	var spawn_mat := StandardMaterial3D.new()
	spawn_mat.albedo_color = Color(0.18, 0.26, 0.32, 0.35)
	spawn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spawn_band.material_override = spawn_mat
	level_root.add_child(spawn_band)

	for side in [-1.0, 1.0]:
		for index in range(4):
			var window_strip := MeshInstance3D.new()
			window_strip.name = "WindowStrip%s_%d" % ["L" if side < 0.0 else "R", index]
			var window_mesh := BoxMesh.new()
			window_mesh.size = Vector3(0.22, 0.58, 3.2)
			window_strip.mesh = window_mesh
			window_strip.position = Vector3(side * 13.1, 1.2 + index * 1.2, -5.6 + index * 3.6)
			var window_mat := StandardMaterial3D.new()
			window_mat.albedo_color = Color(0.92, 0.22, 0.22)
			window_mat.emission_enabled = true
			window_mat.emission = Color(0.95, 0.22, 0.22) * 0.45
			window_mat.roughness = 0.22
			window_strip.material_override = window_mat
			level_root.add_child(window_strip)

	var center_landmark := MeshInstance3D.new()
	center_landmark.name = "CenterLandmark"
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.68
	center_mesh.bottom_radius = 0.84
	center_mesh.height = 0.22
	center_landmark.mesh = center_mesh
	center_landmark.position = Vector3(0.0, 0.11, 5.4)
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.20, 0.22, 0.28)
	center_mat.roughness = 0.88
	center_landmark.material_override = center_mat
	level_root.add_child(center_landmark)

	var center_ring := MeshInstance3D.new()
	center_ring.name = "CenterLandmarkRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 1.56
	ring_mesh.bottom_radius = 1.64
	ring_mesh.height = 0.06
	center_ring.mesh = ring_mesh
	center_ring.position = Vector3(0.0, 0.19, 5.4)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.96, 0.24, 0.24)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.96, 0.24, 0.24) * 0.65
	ring_mat.roughness = 0.18
	center_ring.material_override = ring_mat
	level_root.add_child(center_ring)
	_add_level_decorations(int(level_config.level_id))


func _build_level_one_placeholder() -> void:
	var street := _add_level_box("StreetBase", Vector3(28.0, 0.2, 18.0), Vector3(0.0, -0.1, 0.0), Color(0.11, 0.12, 0.16), 0.94)

	var lane := _add_level_box("LaneStrip", Vector3(0.24, 0.02, 14.4), Vector3(0.0, 0.02, 0.0), Color(0.98, 0.86, 0.18), 0.32, Color(0.98, 0.82, 0.10) * 0.22)
	lane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for dash_index in range(6):
		var dash := _add_level_box(
			"LaneDash%02d" % dash_index,
			Vector3(0.18, 0.015, 1.15),
			Vector3(0.0, 0.03, -6.2 + dash_index * 2.45),
			Color(1.0, 0.94, 0.42),
			0.24,
			Color(0.98, 0.90, 0.30) * 0.14
		)
		dash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var sidewalk_specs := [
		{
			"name": "Left",
			"side": -1.0,
			"walk_color": Color(0.12, 0.46, 0.96),
			"edge_color": Color(0.08, 0.82, 0.96),
		},
		{
			"name": "Right",
			"side": 1.0,
			"walk_color": Color(0.98, 0.34, 0.14),
			"edge_color": Color(1.0, 0.84, 0.18),
		},
	]
	for spec in sidewalk_specs:
		var side := float(spec.side)
		_add_level_box("Sidewalk%s" % spec.name, Vector3(5.0, 0.28, 18.0), Vector3(side * 11.5, 0.02, 0.0), spec.walk_color, 0.88)
		_add_level_box("CurbEdge%s" % spec.name, Vector3(0.28, 0.12, 18.0), Vector3(side * 9.16, 0.12, 0.0), spec.edge_color, 0.42, spec.edge_color * 0.22)
		_add_level_box("BackdropBlock%s" % spec.name, Vector3(3.4, 6.0, 18.0), Vector3(side * 14.6, 3.0, 0.0), Color(0.12, 0.14, 0.20), 0.98)

		for zone_index in range(3):
			var zone_z := -4.4 + zone_index * 4.4
			var facade_panel := _add_level_box(
				"FacadePanel%s_%02d" % [spec.name, zone_index],
				Vector3(0.28, 2.4, 4.2),
				Vector3(side * 13.0, 2.1, zone_z),
				spec.edge_color if zone_index % 2 == 0 else spec.walk_color.lightened(0.12),
				0.36,
				spec.edge_color * 0.16
			)
			facade_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		for banner_index in range(4):
			var banner_color := Color(0.98, 0.18, 0.18) if banner_index % 2 == 0 else Color(1.0, 0.88, 0.16)
			var banner := _add_level_box(
				"FacadeBanner%s_%02d" % [spec.name, banner_index],
				Vector3(0.24, 0.54, 2.3),
				Vector3(side * 12.95, 1.0 + banner_index * 1.05, -5.6 + banner_index * 3.6),
				banner_color,
				0.24,
				banner_color * 0.25
			)
			banner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var spawn_band := _add_level_box("SpawnReadableBand", Vector3(22.0, 0.01, 10.2), Vector3(0.0, 0.03, 0.5), Color(0.10, 0.90, 0.96, 0.34), 0.18)
	if spawn_band.material_override is StandardMaterial3D:
		var spawn_mat := spawn_band.material_override as StandardMaterial3D
		spawn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spawn_mat.emission_enabled = true
		spawn_mat.emission = Color(0.12, 0.86, 0.96) * 0.10
	spawn_band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var zone_bands := [
		{"name": "Front", "z": -4.6, "color": Color(1.0, 0.30, 0.18)},
		{"name": "Mid", "z": 0.0, "color": Color(1.0, 0.84, 0.16)},
		{"name": "Rear", "z": 4.6, "color": Color(0.12, 0.88, 0.96)},
	]
	for zone_info in zone_bands:
		var band := _add_level_box(
			"ZoneBand%s" % zone_info.name,
			Vector3(21.2, 0.02, 0.24),
			Vector3(0.0, 0.035, zone_info.z),
			Color(zone_info.color.r, zone_info.color.g, zone_info.color.b, 0.58),
			0.18,
			zone_info.color * 0.15
		)
		if band.material_override is StandardMaterial3D:
			var band_mat := band.material_override as StandardMaterial3D
			band_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for stripe_index in range(5):
		var crosswalk := _add_level_box(
			"CrosswalkStripe%02d" % stripe_index,
			Vector3(6.2, 0.02, 0.34),
			Vector3(0.0, 0.03, -5.8 + stripe_index * 0.55),
			Color(1.0, 0.98, 0.90),
			0.26,
			Color(0.9, 0.95, 1.0) * 0.06
		)
		crosswalk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for side in [-1.0, 1.0]:
		for marker_index in range(4):
			var marker_color := Color(1.0, 0.86, 0.12) if marker_index % 2 == 0 else Color(0.08, 0.86, 0.96)
			_add_level_cylinder(
				"GuidePylon%s_%02d" % ["L" if side < 0.0 else "R", marker_index],
				0.18,
				1.05 + marker_index * 0.10,
				Vector3(side * 8.8, 0.52, -5.8 + marker_index * 3.8),
				marker_color,
				0.24,
				marker_color * 0.22
			)

	var center_landmark := _add_level_cylinder("CenterLandmark", 0.78, 0.26, Vector3(0.0, 0.13, 5.1), Color(0.16, 0.18, 0.24), 0.84)
	center_landmark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var center_ring := _add_level_cylinder("CenterLandmarkRing", 1.62, 0.06, Vector3(0.0, 0.19, 5.1), Color(1.0, 0.20, 0.18), 0.20, Color(1.0, 0.20, 0.18) * 0.45)
	center_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var stage_token := _add_level_box("StageToken", Vector3(1.3, 0.08, 1.3), Vector3(0.0, 0.05, 5.1), Color(0.10, 0.86, 0.96), 0.14, Color(0.10, 0.86, 0.96) * 0.22)
	stage_token.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if street.material_override is StandardMaterial3D:
		var street_mat := street.material_override as StandardMaterial3D
		street_mat.emission_enabled = true
		street_mat.emission = Color(0.06, 0.08, 0.12) * 0.12


func _make_level_material(color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	return material


func _add_level_box(node_name: String, box_size: Vector3, pos: Vector3, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _make_level_material(color, roughness, emission)
	level_root.add_child(mesh_instance)
	return mesh_instance


func _add_level_cylinder(node_name: String, radius: float, height: float, pos: Vector3, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _make_level_material(color, roughness, emission)
	level_root.add_child(mesh_instance)
	return mesh_instance


func _add_level_sphere(node_name: String, radius: float, pos: Vector3, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _make_level_material(color, roughness, emission)
	level_root.add_child(mesh_instance)
	return mesh_instance


func _add_level_decorations(level_id: int) -> void:
	var palette := _get_level_greenery_palette(level_id)
	var style_profile: Dictionary = _get_level_style_profile(level_id)
	if bool(style_profile.get("add_clean_markers", false)):
		_add_clean_street_markers(level_id, palette)
	if bool(style_profile.get("add_market_clutter", false)):
		_add_market_clutter(level_id, palette)
	if bool(style_profile.get("add_hazard_zone", false)):
		_add_hazard_zone(level_id, palette)
	if bool(style_profile.get("add_battlefield_greenery", true)):
		_add_battlefield_greenery(level_id, palette)


func _add_planter_cluster(node_prefix: String, center: Vector3, side: float, palette: Dictionary) -> void:
	var planter := _add_level_box(
		"%s_Box" % node_prefix,
		Vector3(1.18, 0.44, 0.82),
		center + Vector3(0.0, 0.22, 0.0),
		palette.get("planter_box", Color(0.24, 0.28, 0.30)),
		0.92
	)
	planter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var soil := _add_level_box(
		"%s_Soil" % node_prefix,
		Vector3(0.98, 0.08, 0.62),
		center + Vector3(0.0, 0.42, 0.0),
		Color(0.18, 0.12, 0.08),
		0.98
	)
	soil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for bush_index in range(3):
		var bush := _add_level_sphere(
			"%s_Bush_%02d" % [node_prefix, bush_index],
			0.22 + bush_index * 0.03,
			center + Vector3(-0.26 + bush_index * 0.26, 0.66 + bush_index * 0.02, -0.04 + bush_index * 0.05),
			palette.get("grass_main", Color(0.24, 0.72, 0.34)),
			0.82,
			palette.get("grass_main", Color(0.24, 0.72, 0.34)) * 0.10
		)
		bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for flower_index in range(4):
		var flower_color: Color = palette.get("flower_a", Color(1.0, 0.54, 0.24)) if flower_index % 2 == 0 else palette.get("flower_b", Color(1.0, 0.88, 0.28))
		var flower := _add_level_cylinder(
			"%s_Flower_%02d" % [node_prefix, flower_index],
			0.045,
			0.18 + float(flower_index % 2) * 0.04,
			center + Vector3(-0.32 + flower_index * 0.22, 0.74, side * 0.04),
			flower_color,
			0.24,
			flower_color * 0.36
		)
		flower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_flower_patch(node_prefix: String, center: Vector3, side: float, palette: Dictionary) -> void:
	var bed := _add_level_box(
		"%s_Bed" % node_prefix,
		Vector3(1.42, 0.06, 0.86),
		center + Vector3(0.0, 0.03, 0.0),
		palette.get("soil_bed", Color(0.22, 0.18, 0.12)),
		0.98
	)
	bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for leaf_index in range(5):
		var leaf := _add_level_sphere(
			"%s_Leaf_%02d" % [node_prefix, leaf_index],
			0.12 + float(leaf_index % 3) * 0.03,
			center + Vector3(-0.42 + leaf_index * 0.20, 0.16 + float(leaf_index % 2) * 0.05, side * 0.05),
			palette.get("grass_light", Color(0.38, 0.82, 0.36)),
			0.88,
			palette.get("grass_light", Color(0.38, 0.82, 0.36)) * 0.08
		)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for bloom_index in range(4):
		var bloom_color: Color = palette.get("flower_b", Color(1.0, 0.88, 0.28)) if bloom_index % 2 == 0 else palette.get("flower_c", Color(0.22, 0.92, 0.96))
		var bloom := _add_level_sphere(
			"%s_Bloom_%02d" % [node_prefix, bloom_index],
			0.07,
			center + Vector3(-0.30 + bloom_index * 0.22, 0.30 + float(bloom_index % 2) * 0.05, -0.08 + float(bloom_index % 3) * 0.08),
			bloom_color,
			0.24,
			bloom_color * 0.24
		)
		bloom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _get_level_greenery_palette(level_id: int) -> Dictionary:
	match level_id:
		2:
			return {
				"grass_main": Color(0.26, 0.72, 0.30),
				"grass_light": Color(0.42, 0.86, 0.38),
				"grass_dark": Color(0.16, 0.52, 0.26),
				"flower_a": Color(1.0, 0.44, 0.30),
				"flower_b": Color(1.0, 0.86, 0.26),
				"flower_c": Color(0.18, 0.88, 0.96),
				"planter_box": Color(0.26, 0.28, 0.30),
				"soil_bed": Color(0.24, 0.18, 0.12),
			}
		3:
			return {
				"grass_main": Color(0.24, 0.68, 0.34),
				"grass_light": Color(0.40, 0.80, 0.40),
				"grass_dark": Color(0.14, 0.48, 0.28),
				"flower_a": Color(0.98, 0.32, 0.42),
				"flower_b": Color(1.0, 0.82, 0.24),
				"flower_c": Color(0.24, 0.86, 1.0),
				"planter_box": Color(0.22, 0.24, 0.28),
				"soil_bed": Color(0.22, 0.16, 0.10),
			}
		_:
			return {
				"grass_main": Color(0.24, 0.74, 0.34),
				"grass_light": Color(0.38, 0.86, 0.36),
				"grass_dark": Color(0.16, 0.54, 0.28),
				"flower_a": Color(1.0, 0.48, 0.26),
				"flower_b": Color(1.0, 0.88, 0.30),
				"flower_c": Color(0.20, 0.90, 0.96),
				"planter_box": Color(0.24, 0.28, 0.30),
				"soil_bed": Color(0.22, 0.18, 0.12),
			}


func _get_level_style_profile(level_id: int) -> Dictionary:
	match level_id:
		1:
			return {
				"sun_rotation": Vector3(-48.0, -28.0, 0.0),
				"sun_energy": 1.34,
				"sun_color": Color(1.0, 0.98, 0.92),
				"sun_shadow_opacity": 0.42,
				"fill_rotation": Vector3(-42.0, 36.0, 0.0),
				"fill_energy": 0.42,
				"fill_color": Color(0.80, 0.88, 1.0),
				"ambient_color": Color(0.42, 0.46, 0.52),
				"ambient_energy": 0.64,
				"fog_color": Color(0.76, 0.84, 0.92),
				"fog_density": 0.010,
				"background_color": Color(0.22, 0.26, 0.32),
				"extra_planters": 1,
				"add_clean_markers": true,
				"add_battlefield_greenery": true,
			}
		2:
			return {
				"sun_rotation": Vector3(-56.0, -36.0, 0.0),
				"sun_energy": 1.12,
				"sun_color": Color(1.0, 0.95, 0.86),
				"sun_shadow_opacity": 0.58,
				"fill_rotation": Vector3(-46.0, 42.0, 0.0),
				"fill_energy": 0.32,
				"fill_color": Color(0.72, 0.80, 0.94),
				"ambient_color": Color(0.32, 0.36, 0.42),
				"ambient_energy": 0.52,
				"fog_color": Color(0.58, 0.64, 0.72),
				"fog_density": 0.019,
				"background_color": Color(0.14, 0.16, 0.20),
				"extra_planters": 2,
				"add_market_clutter": true,
				"add_battlefield_greenery": true,
			}
		3:
			return {
				"sun_rotation": Vector3(-63.0, -42.0, 0.0),
				"sun_energy": 0.92,
				"sun_color": Color(0.96, 0.82, 0.78),
				"sun_shadow_opacity": 0.72,
				"fill_rotation": Vector3(-52.0, 46.0, 0.0),
				"fill_energy": 0.18,
				"fill_color": Color(0.60, 0.68, 0.84),
				"ambient_color": Color(0.22, 0.24, 0.30),
				"ambient_energy": 0.44,
				"fog_color": Color(0.42, 0.34, 0.38),
				"fog_density": 0.030,
				"background_color": Color(0.09, 0.08, 0.10),
				"extra_planters": 1,
				"add_hazard_zone": true,
				"add_market_clutter": true,
				"add_battlefield_greenery": true,
			}
		_:
			return {}


func _add_extra_planter_rows(level_id: int, palette: Dictionary, extra_count: int) -> void:
	for extra_index in range(extra_count):
		var offset_z := -4.8 + extra_index * 4.6
		_add_planter_cluster(
			"ExtraPlanterL_%02d_%d" % [level_id, extra_index],
			Vector3(-10.8, 0.0, offset_z),
			-1.0,
			palette
		)
		_add_planter_cluster(
			"ExtraPlanterR_%02d_%d" % [level_id, extra_index],
			Vector3(10.8, 0.0, offset_z + 1.0),
			1.0,
			palette
		)


func _add_clean_street_markers(level_id: int, palette: Dictionary) -> void:
	for side in [-1.0, 1.0]:
		for idx in range(3):
			var marker := _add_level_box(
				"CleanMarker_%d_%02d_%02d" % [level_id, int(side), idx],
				Vector3(0.48, 0.42, 0.48),
				Vector3(side * 10.6, 0.21, -4.8 + idx * 4.7),
				palette.get("flower_c", Color(0.20, 0.90, 0.96)),
				0.18,
				palette.get("flower_c", Color(0.20, 0.90, 0.96)) * 0.22
			)
			marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_market_clutter(level_id: int, palette: Dictionary) -> void:
	var clutter_specs := [
		{"pos": Vector3(-10.2, 0.0, -2.8), "size": Vector3(1.0, 0.52, 0.72), "color": Color(0.82, 0.36, 0.18)},
		{"pos": Vector3(10.0, 0.0, -0.6), "size": Vector3(1.16, 0.58, 0.74), "color": Color(0.18, 0.58, 0.86)},
		{"pos": Vector3(-10.6, 0.0, 3.3), "size": Vector3(0.92, 0.44, 0.66), "color": Color(0.96, 0.84, 0.22)},
	]
	for idx in range(clutter_specs.size()):
		var spec: Dictionary = clutter_specs[idx]
		var crate := _add_level_box(
			"MarketCrate_%02d_%02d" % [level_id, idx],
			spec.get("size", Vector3.ONE),
			spec.get("pos", Vector3.ZERO) + Vector3(0.0, float(spec.get("size", Vector3.ONE).y) * 0.5, 0.0),
			spec.get("color", Color(0.82, 0.36, 0.18)),
			0.72,
			Color(spec.get("color", Color.WHITE).r, spec.get("color", Color.WHITE).g, spec.get("color", Color.WHITE).b) * 0.08
		)
		crate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var top_bush := _add_level_sphere(
			"MarketCrateBush_%02d_%02d" % [level_id, idx],
			0.18 + idx * 0.02,
			spec.get("pos", Vector3.ZERO) + Vector3(0.0, float(spec.get("size", Vector3.ONE).y) + 0.16, 0.0),
			palette.get("grass_main", Color(0.24, 0.72, 0.34)),
			0.82,
			palette.get("grass_main", Color(0.24, 0.72, 0.34)) * 0.08
		)
		top_bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_hazard_zone(level_id: int, palette: Dictionary) -> void:
	var hazard_rows := [
		{"side": -1.0, "z": -3.2},
		{"side": 1.0, "z": 2.8},
	]
	for row_index in range(hazard_rows.size()):
		var row: Dictionary = hazard_rows[row_index]
		var side: float = float(row.get("side", -1.0))
		var z_val: float = float(row.get("z", 0.0))
		for post_index in range(3):
			var post_color := Color(1.0, 0.32, 0.24) if post_index % 2 == 0 else Color(1.0, 0.82, 0.18)
			var post := _add_level_box(
				"HazardPost_%02d_%02d_%02d" % [level_id, row_index, post_index],
				Vector3(0.22, 0.92, 0.22),
				Vector3(side * 10.6, 0.46, z_val + post_index * 0.64),
				post_color,
				0.22,
				post_color * 0.22
			)
			post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var barrier := _add_level_box(
			"HazardBarrier_%02d_%02d" % [level_id, row_index],
			Vector3(1.86, 0.12, 0.18),
			Vector3(side * 10.6, 0.78, z_val + 0.64),
			Color(0.12, 0.12, 0.16),
			0.34,
			Color(1.0, 0.20, 0.18) * 0.16
		)
		barrier.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var warning_bloom := _add_level_sphere(
			"HazardBloom_%02d_%02d" % [level_id, row_index],
			0.16,
			Vector3(side * 10.6, 1.08, z_val + 0.64),
			palette.get("flower_a", Color(0.98, 0.32, 0.42)),
			0.20,
			palette.get("flower_a", Color(0.98, 0.32, 0.42)) * 0.34
		)
		warning_bloom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_battlefield_greenery(level_id: int, palette: Dictionary) -> void:
	var cluster_specs: Array[Dictionary] = _get_battlefield_greenery_specs(level_id)
	for idx in range(cluster_specs.size()):
		var spec: Dictionary = cluster_specs[idx]
		var cluster_type: String = str(spec.get("type", "patch"))
		var cluster_center: Vector3 = spec.get("pos", Vector3.ZERO)
		match cluster_type:
			"planter":
				_add_mixed_planter("%d_%02d" % [level_id, idx], cluster_center, palette)
			"shrub":
				_add_mixed_shrub_cluster("%d_%02d" % [level_id, idx], cluster_center, palette)
			_:
				_add_mixed_flower_patch("%d_%02d" % [level_id, idx], cluster_center, palette)


func _get_battlefield_greenery_specs(_level_id: int) -> Array[Dictionary]:
	return []


func _build_target_greenery_specs_from_config(level_id: int) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	if level_config == null:
		return specs
	var config_entries: Array = level_config.spawn_entries
	if config_entries.is_empty():
		return specs
	var target_index := 0
	for entry in config_entries:
		if entry == null:
			continue
		if str(entry.actor_kind) != "target":
			continue
		var target_world_pos: Vector3 = _map_config_position_to_world_3d_for_decor(Vector2(entry.position))
		var behavior: String = str(entry.behavior_type)
		var offsets: Array[Dictionary] = _get_target_greenery_offsets(level_id, target_index, behavior)
		for offset_info in offsets:
			var cluster_type: String = str(offset_info.get("type", "patch"))
			var offset: Vector3 = offset_info.get("offset", Vector3.ZERO)
			var cluster_pos := Vector3(
				clampf(target_world_pos.x + offset.x, world_bounds_x.x + 1.0, world_bounds_x.y - 1.0),
				0.0,
				clampf(target_world_pos.z + offset.z, world_bounds_z.x + 0.8, world_bounds_z.y - 0.8)
			)
			specs.append({
				"type": cluster_type,
				"pos": cluster_pos,
			})
		target_index += 1
	return specs


func _get_target_greenery_offsets(level_id: int, target_index: int, behavior: String) -> Array[Dictionary]:
	var base_patterns: Array[Array] = [
		[
			{"type": "shrub", "offset": Vector3(-0.12, 0.0, 0.08)},
			{"type": "patch", "offset": Vector3(0.10, 0.0, -0.06)},
			{"type": "patch", "offset": Vector3(0.02, 0.0, 0.16)},
		],
		[
			{"type": "patch", "offset": Vector3(-0.10, 0.0, -0.10)},
			{"type": "shrub", "offset": Vector3(0.14, 0.0, 0.06)},
			{"type": "patch", "offset": Vector3(-0.02, 0.0, 0.18)},
		],
		[
			{"type": "shrub", "offset": Vector3(0.08, 0.0, 0.12)},
			{"type": "patch", "offset": Vector3(-0.12, 0.0, 0.04)},
			{"type": "patch", "offset": Vector3(0.00, 0.0, -0.16)},
		],
		[
			{"type": "patch", "offset": Vector3(0.06, 0.0, -0.12)},
			{"type": "planter", "offset": Vector3(-0.18, 0.0, 0.08)},
			{"type": "patch", "offset": Vector3(0.00, 0.0, 0.18)},
		],
	]
	var chosen_pattern: Array = base_patterns[target_index % base_patterns.size()]
	var result: Array[Dictionary] = []
	for item in chosen_pattern:
		result.append(item.duplicate(true))
	if behavior == "moving":
		for item in result:
			var moved_offset: Vector3 = item.get("offset", Vector3.ZERO)
			moved_offset *= 0.72
			item["offset"] = moved_offset
			if str(item.get("type", "")) == "planter":
				item["type"] = "patch"
	elif behavior == "weakpoint":
		if not result.is_empty():
			result[0]["type"] = "planter"
			var weak_offset: Vector3 = result[0].get("offset", Vector3.ZERO)
			result[0]["offset"] = weak_offset * 0.96
	if level_id == 1 and result.size() > 1:
		result.resize(2)
	elif level_id == 3:
		result.append({
			"type": "patch" if behavior == "moving" else "shrub",
			"offset": Vector3(0.10 if target_index % 2 == 0 else -0.10, 0.0, 0.20),
		})
	return result


func _map_config_position_to_world_3d_for_decor(config_position: Vector2) -> Vector3:
	var world_width: float = maxf(level_config.world_size.x, 1.0)
	var world_height: float = maxf(level_config.world_size.y, 1.0)
	var x_ratio: float = clampf(config_position.x / (world_width * 0.5), -1.0, 1.0)
	var z_ratio: float = clampf(config_position.y / (world_height * 0.5), -1.0, 1.0)
	return Vector3(
		lerpf(world_bounds_x.x, world_bounds_x.y, (x_ratio + 1.0) * 0.5),
		0.0,
		lerpf(world_bounds_z.x, world_bounds_z.y, (z_ratio + 1.0) * 0.5)
	)


func _add_mixed_flower_patch(node_suffix: String, center: Vector3, palette: Dictionary) -> void:
	var foliage = FOLIAGE_PROP_3D_SCRIPT.new()
	foliage.name = "BattlePatch_%s" % node_suffix
	foliage.position = center
	level_root.add_child(foliage)
	foliage.setup("patch", Vector3(0.96, 0.36, 0.60), palette)
	runtime_target_greenery_nodes.append(foliage)


func _add_mixed_shrub_cluster(node_suffix: String, center: Vector3, palette: Dictionary) -> void:
	var foliage = FOLIAGE_PROP_3D_SCRIPT.new()
	foliage.name = "BattleShrub_%s" % node_suffix
	foliage.position = center
	level_root.add_child(foliage)
	foliage.setup("shrub", Vector3(0.80, 0.48, 0.56), palette)
	runtime_target_greenery_nodes.append(foliage)


func _add_mixed_planter(node_suffix: String, center: Vector3, palette: Dictionary) -> void:
	var foliage = FOLIAGE_PROP_3D_SCRIPT.new()
	foliage.name = "BattlePlanter_%s" % node_suffix
	foliage.position = center
	level_root.add_child(foliage)
	foliage.setup("planter", Vector3(0.68, 0.48, 0.48), palette)

	runtime_target_greenery_nodes.append(foliage)


func _clear_runtime_target_greenery() -> void:
	for node in runtime_target_greenery_nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	runtime_target_greenery_nodes.clear()
	for node in runtime_greenery_cover_nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	runtime_greenery_cover_nodes.clear()
	cover_obstacles_3d = cover_obstacles_3d.filter(func(obstacle): return obstacle != null and is_instance_valid(obstacle))


func _rebuild_runtime_target_greenery_after_spawn() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_rebuild_runtime_target_greenery()


func _rebuild_runtime_target_greenery() -> void:
	_clear_runtime_target_greenery()
	if battle_core == null or not is_instance_valid(battle_core):
		return
	var palette := _get_level_greenery_palette(int(level_config.level_id))
	var actor_positions: Array[Vector3] = []
	var target_index := 0
	for actor in battle_core.active_actors:
		if actor == null or not is_instance_valid(actor):
			continue
		if bool(actor.alive):
			var any_actor_world: Vector3 = actor.global_position
			any_actor_world.y = 0.0
			actor_positions.append(any_actor_world)
		if str(actor.actor_kind) != "target" or not bool(actor.alive):
			continue
		var actor_world: Vector3 = actor.global_position
		actor_world.y = 0.0
		_add_actor_foot_greenery(actor, target_index, palette)
		var offsets: Array[Dictionary] = _get_runtime_target_greenery_offsets(actor, target_index)
		for cluster_index in range(offsets.size()):
			var cluster: Dictionary = offsets[cluster_index]
			var offset: Vector3 = cluster.get("offset", Vector3.ZERO)
			var cluster_center := Vector3(
				clampf(actor_world.x + offset.x, world_bounds_x.x + 0.25, world_bounds_x.y - 0.25),
				0.0,
				clampf(actor_world.z + offset.z, world_bounds_z.x + 0.25, world_bounds_z.y - 0.25)
			)
			match str(cluster.get("type", "patch")):
				"planter":
					_add_mixed_planter("RT_%02d_%02d" % [target_index, cluster_index], cluster_center, palette)
				"shrub":
					_add_mixed_shrub_cluster("RT_%02d_%02d" % [target_index, cluster_index], cluster_center, palette)
				_:
					_add_mixed_flower_patch("RT_%02d_%02d" % [target_index, cluster_index], cluster_center, palette)
		target_index += 1
	_add_runtime_greenery_covers(actor_positions)
	_add_spawn_cluster_greenery(actor_positions, palette)


func _add_actor_foot_greenery(actor, target_index: int, palette: Dictionary) -> void:
	var actor_world: Vector3 = actor.global_position
	actor_world.y = 0.0
	var body_radius: float = 0.24
	var radius_value = actor.get("body_radius")
	if typeof(radius_value) == TYPE_FLOAT:
		body_radius = clampf(float(radius_value), 0.18, 0.36)
	var behavior: String = str(actor.behavior_type)
	var side_sign: float = -1.0 if target_index % 2 == 0 else 1.0

	var foot_patch_center := Vector3(
		clampf(actor_world.x, world_bounds_x.x + 0.20, world_bounds_x.y - 0.20),
		0.0,
		clampf(actor_world.z + body_radius * 0.08, world_bounds_z.x + 0.20, world_bounds_z.y - 0.20)
	)
	var foot_patch = FOLIAGE_PROP_3D_SCRIPT.new()
	foot_patch.name = "ActorFootPatch_%02d" % target_index
	foot_patch.position = foot_patch_center
	level_root.add_child(foot_patch)
	foot_patch.setup("patch", Vector3(1.24, 0.36, 0.76), palette)
	runtime_target_greenery_nodes.append(foot_patch)

	if behavior != "moving":
		var leg_side_center := Vector3(
			clampf(actor_world.x + side_sign * body_radius * 0.30, world_bounds_x.x + 0.20, world_bounds_x.y - 0.20),
			0.0,
			clampf(actor_world.z - body_radius * 0.04, world_bounds_z.x + 0.20, world_bounds_z.y - 0.20)
		)
		var leg_side = FOLIAGE_PROP_3D_SCRIPT.new()
		leg_side.name = "ActorLegShrub_%02d" % target_index
		leg_side.position = leg_side_center
		level_root.add_child(leg_side)
		leg_side.setup("shrub", Vector3(0.60, 0.44, 0.44), palette)
		runtime_target_greenery_nodes.append(leg_side)

	if behavior == "weakpoint":
		var rear_patch_center := Vector3(
			clampf(actor_world.x - side_sign * body_radius * 0.12, world_bounds_x.x + 0.20, world_bounds_x.y - 0.20),
			0.0,
			clampf(actor_world.z + body_radius * 0.26, world_bounds_z.x + 0.20, world_bounds_z.y - 0.20)
		)
		var rear_patch = FOLIAGE_PROP_3D_SCRIPT.new()
		rear_patch.name = "ActorRearPatch_%02d" % target_index
		rear_patch.position = rear_patch_center
		level_root.add_child(rear_patch)
		rear_patch.setup("patch", Vector3(0.72, 0.28, 0.48), palette)
		runtime_target_greenery_nodes.append(rear_patch)


func _get_runtime_target_greenery_offsets(actor, target_index: int) -> Array[Dictionary]:
	var behavior: String = str(actor.behavior_type)
	var body_radius: float = 0.22
	var radius_value = actor.get("body_radius")
	if typeof(radius_value) == TYPE_FLOAT:
		body_radius = clampf(float(radius_value), 0.16, 0.34)
	var side_sign: float = -1.0 if target_index % 2 == 0 else 1.0
	match behavior:
		"moving":
			return [
				{"type": "patch", "offset": Vector3(side_sign * body_radius * 0.46, 0.0, body_radius * 0.18)},
				{"type": "patch", "offset": Vector3(-side_sign * body_radius * 0.22, 0.0, -body_radius * 0.34)},
			]
		"weakpoint":
			return [
				{"type": "planter", "offset": Vector3(side_sign * body_radius * 0.52, 0.0, body_radius * 0.08)},
				{"type": "patch", "offset": Vector3(-side_sign * body_radius * 0.20, 0.0, body_radius * 0.42)},
				{"type": "shrub", "offset": Vector3(side_sign * body_radius * 0.12, 0.0, -body_radius * 0.32)},
			]
		_:
			return [
				{"type": "shrub", "offset": Vector3(side_sign * body_radius * 0.44, 0.0, body_radius * 0.10)},
				{"type": "patch", "offset": Vector3(-side_sign * body_radius * 0.18, 0.0, body_radius * 0.34)},
				{"type": "patch", "offset": Vector3(side_sign * body_radius * 0.08, 0.0, -body_radius * 0.30)},
				{"type": "patch", "offset": Vector3(0.0, 0.0, body_radius * 0.18)},
			]


func _add_spawn_cluster_greenery(actor_positions: Array[Vector3], palette: Dictionary) -> void:
	if actor_positions.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var planted_positions: Array[Vector3] = []
	var greenery_budget: int = clampi(actor_positions.size() * 2, 8, 18)
	for idx in range(greenery_budget):
		var anchor: Vector3 = actor_positions[rng.randi_range(0, actor_positions.size() - 1)]
		var placed := false
		for _attempt in range(14):
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(0.55, 1.75)
			var candidate := Vector3(
				clampf(anchor.x + cos(angle) * radius, world_bounds_x.x + 0.6, world_bounds_x.y - 0.6),
				0.0,
				clampf(anchor.z + sin(angle) * radius, world_bounds_z.x + 0.6, world_bounds_z.y - 0.6)
			)
			if not _is_runtime_greenery_position_valid(candidate, actor_positions, planted_positions):
				continue
			var pick := rng.randf()
			if pick < 0.18:
				_add_mixed_planter("Cluster_%02d" % idx, candidate, palette)
			elif pick < 0.54:
				_add_mixed_shrub_cluster("Cluster_%02d" % idx, candidate, palette)
			else:
				_add_mixed_flower_patch("Cluster_%02d" % idx, candidate, palette)
			planted_positions.append(candidate)
			placed = true
			break
		if not placed:
			continue


func _is_runtime_greenery_position_valid(candidate: Vector3, actor_positions: Array[Vector3], planted_positions: Array[Vector3]) -> bool:
	for actor_pos in actor_positions:
		var dist := actor_pos.distance_to(candidate)
		if dist < 0.42:
			return false
		if dist > 2.35:
			continue
	for planted in planted_positions:
		if planted.distance_to(candidate) < 0.62:
			return false
	for obstacle in cover_obstacles_3d:
		if obstacle == null or not is_instance_valid(obstacle):
			continue
		var obstacle_radius := 1.1
		var obstacle_size = obstacle.get("size")
		if typeof(obstacle_size) == TYPE_VECTOR3:
			obstacle_radius = maxf(float(obstacle_size.x), float(obstacle_size.z)) * 0.45 + 0.35
		if obstacle.global_position.distance_to(candidate) < obstacle_radius:
			return false
	return true


func _add_runtime_greenery_covers(actor_positions: Array[Vector3]) -> void:
	if actor_positions.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var cover_budget: int = int(level_config.runtime_greenery_cover_budget)
	if cover_budget < 0:
		cover_budget = clampi(int(round(float(actor_positions.size()) * 1.0)), 3, 8)
	if cover_budget <= 0:
		return
	for idx in range(cover_budget):
		var anchor: Vector3 = actor_positions[rng.randi_range(0, actor_positions.size() - 1)]
		for _attempt in range(20):
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(0.72, 1.48)
			var candidate := Vector3(
				clampf(anchor.x + cos(angle) * radius, world_bounds_x.x + 0.9, world_bounds_x.y - 0.9),
				0.0,
				clampf(anchor.z + sin(angle) * radius, world_bounds_z.x + 0.9, world_bounds_z.y - 0.9)
			)
			if not _is_runtime_green_cover_position_valid(candidate, actor_positions):
				continue
			var cover = _add_cover(candidate, "hedge_cover")
			if cover != null:
				runtime_greenery_cover_nodes.append(cover)
			break


func _is_runtime_green_cover_position_valid(candidate: Vector3, actor_positions: Array[Vector3]) -> bool:
	for actor_pos in actor_positions:
		var dist := actor_pos.distance_to(candidate)
		if dist < 0.64:
			return false
		if dist > 2.00:
			continue
	var obstacle_radius := 1.15
	for obstacle in cover_obstacles_3d:
		if obstacle == null or not is_instance_valid(obstacle):
			continue
		var cover_size = obstacle.get("size")
		if typeof(cover_size) == TYPE_VECTOR3:
			obstacle_radius = maxf(float(cover_size.x), float(cover_size.z)) * 0.44 + 0.28
		if obstacle.global_position.distance_to(candidate) < obstacle_radius:
			return false
	return true


func _init_modules() -> void:
	camera_controller = CAMERA_CONTROLLER_3D_SCRIPT.new()
	camera_controller.camera = aim_camera
	add_child(camera_controller)

	weapon = preload("res://scripts/pve/weapon.gd").new()
	weapon.setup_from_profile(CoreGameState.get_weapon_profile())
	add_child(weapon)

	battle_core = BATTLE_CORE_3D_SCRIPT.new()
	add_child(battle_core)

	input_handler = preload("res://scripts/pve/input_handler.gd").new()
	add_child(input_handler)

	visual_feedback = VISUAL_FEEDBACK_3D_SCRIPT.new()
	add_child(visual_feedback)

	battle_mode = BATTLE_MODE_PVE_3D_SCRIPT.new()
	add_child(battle_mode)

	hud_controller = HUD_CONTROLLER_SCRIPT.new()
	add_child(hud_controller)

	weapon_renderer = WEAPON_RENDERER_3D_SCRIPT.new()
	weapon_renderer.name = "WeaponRenderer3D"
	aim_camera.add_child(weapon_renderer)
	weapon_renderer.update_from_profile(CoreGameState.get_weapon_profile())

	if battle_core != null and not battle_core.shot_fired.is_connected(_on_shot_fired):
		battle_core.shot_fired.connect(_on_shot_fired)


func _setup_battle_mode() -> void:
	camera_controller.setup(weapon.get_profile(), world_root, aim_camera)
	camera_controller.configure_scene_roots(level_root, actor_root, decal_root, fx_root)
	battle_mode.setup_3d(level_config, weapon, world_root, actor_root)
	battle_mode.initialize_controllers_3d(battle_core, camera_controller, input_handler, visual_feedback)
	battle_mode.start_battle_3d()

	battle_mode.battle_finished.connect(_on_battle_finished)
	if battle_core != null and is_instance_valid(battle_core):
		battle_core.victory_pending.connect(_on_victory_pending)
	tutorial_primary_target = battle_core.tutorial_primary_target


func _setup_hud_connections() -> void:
	if hud == null or not is_instance_valid(hud):
		return

	hud_controller.setup(battle_core, camera_controller, visual_feedback, hud)

	hud_controller.fire_pressed.connect(_on_fire_pressed)
	hud_controller.scan_pressed.connect(_on_scan_pressed)
	hud_controller.time_extend_pressed.connect(_on_time_extend_pressed)
	hud_controller.zoom_in_pressed.connect(_on_zoom_in_pressed)
	hud_controller.zoom_out_pressed.connect(_on_zoom_out_pressed)
	hud_controller.back_pressed.connect(func() -> void:
		_request_pause_overlay("hud_back_button")
	)
	if hud != null and is_instance_valid(hud) and hud.has_signal("quit_to_menu_pressed") and not hud.quit_to_menu_pressed.is_connected(_exit_to_main_menu_from_pause):
		hud.quit_to_menu_pressed.connect(_exit_to_main_menu_from_pause)


func _spawn_cover_obstacles() -> void:
	for obstacle in cover_obstacles_3d:
		if obstacle != null and is_instance_valid(obstacle):
			obstacle.queue_free()
	cover_obstacles_3d.clear()

	if not level_config.cover_entries_3d.is_empty():
		for entry in level_config.cover_entries_3d:
			if entry == null:
				continue
			var obstacle = _add_cover(Vector3(entry.position), str(entry.style_id))
			if obstacle != null:
				obstacle.rotation.y = deg_to_rad(float(entry.rotation_deg_y))
		return

	var fixed_cover_plan: Array[Dictionary] = _get_fixed_cover_plan(int(level_config.level_id))
	if not fixed_cover_plan.is_empty():
		for entry in fixed_cover_plan:
			_add_cover(entry.pos, entry.style)
		return

	var cover_count := int(level_config.cover_budget_3d)
	if cover_count < 0:
		cover_count = clampi(int(level_config.required_targets) + 1, 3, 7)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var styles: Array[String] = []
	for style in level_config.cover_style_pool_3d:
		styles.append(str(style))
	if styles.is_empty():
		styles = ["wall_corner", "street_lamp", "parked_van", "billboard"]
	for i in range(cover_count):
		var pos := Vector3(
			rng.randf_range(world_bounds_x.x + 1.2, world_bounds_x.y - 2.6),
			0.0,
			rng.randf_range(world_bounds_z.x + 0.8, world_bounds_z.y - 2.2)
		)
		var style: String = styles[rng.randi_range(0, styles.size() - 1)]
		_add_cover(pos, style)


func _get_fixed_cover_plan(level_id: int) -> Array[Dictionary]:
	match level_id:
		1:
			return [
				{"pos": Vector3(-4.2, 0.0, -4.0), "style": "wall_corner"},
				{"pos": Vector3(-5.5, 0.0, -2.3), "style": "street_lamp"},
				{"pos": Vector3(-2.6, 0.0, -3.2), "style": "billboard"},
				{"pos": Vector3(2.1, 0.0, -2.7), "style": "wall_corner"},
				{"pos": Vector3(4.4, 0.0, -1.1), "style": "parked_van"},
				{"pos": Vector3(0.3, 0.0, -0.6), "style": "street_lamp"},
				{"pos": Vector3(-4.8, 0.0, 0.9), "style": "parked_van"},
				{"pos": Vector3(-1.8, 0.0, 0.3), "style": "street_lamp"},
				{"pos": Vector3(5.2, 0.0, 0.7), "style": "billboard"},
				{"pos": Vector3(3.7, 0.0, 1.8), "style": "wall_corner"},
				{"pos": Vector3(-5.1, 0.0, 2.8), "style": "billboard"},
				{"pos": Vector3(-3.4, 0.0, 3.9), "style": "wall_corner"},
				{"pos": Vector3(2.6, 0.0, 4.8), "style": "parked_van"},
				{"pos": Vector3(4.7, 0.0, 3.1), "style": "street_lamp"},
			]
		2:
			return [
				{"pos": Vector3(-6.0, 0.0, -4.6), "style": "wall_corner"},
				{"pos": Vector3(-3.6, 0.0, -3.6), "style": "street_lamp"},
				{"pos": Vector3(-0.8, 0.0, -2.9), "style": "billboard"},
				{"pos": Vector3(1.8, 0.0, -3.4), "style": "parked_van"},
				{"pos": Vector3(4.9, 0.0, -2.4), "style": "wall_corner"},
				{"pos": Vector3(-5.4, 0.0, -0.8), "style": "parked_van"},
				{"pos": Vector3(-2.0, 0.0, -0.2), "style": "street_lamp"},
				{"pos": Vector3(2.0, 0.0, 0.9), "style": "billboard"},
				{"pos": Vector3(5.7, 0.0, 0.9), "style": "street_lamp"},
				{"pos": Vector3(-5.0, 0.0, 2.2), "style": "billboard"},
				{"pos": Vector3(-0.8, 0.0, 2.8), "style": "wall_corner"},
				{"pos": Vector3(3.0, 0.0, 4.4), "style": "parked_van"},
			]
		3:
			return [
				{"pos": Vector3(-6.0, 0.0, -5.2), "style": "wall_corner"},
				{"pos": Vector3(-3.2, 0.0, -4.6), "style": "parked_van"},
				{"pos": Vector3(0.0, 0.0, -3.8), "style": "street_lamp"},
				{"pos": Vector3(4.2, 0.0, -4.2), "style": "billboard"},
				{"pos": Vector3(-5.3, 0.0, -1.8), "style": "parked_van"},
				{"pos": Vector3(-2.0, 0.0, -0.9), "style": "street_lamp"},
				{"pos": Vector3(1.8, 0.0, -0.4), "style": "billboard"},
				{"pos": Vector3(6.0, 0.0, 0.3), "style": "wall_corner"},
				{"pos": Vector3(-4.2, 0.0, 1.4), "style": "parked_van"},
				{"pos": Vector3(-1.2, 0.0, 1.0), "style": "wall_corner"},
				{"pos": Vector3(2.6, 0.0, 1.9), "style": "street_lamp"},
				{"pos": Vector3(5.6, 0.0, 1.8), "style": "billboard"},
				{"pos": Vector3(-5.4, 0.0, 3.5), "style": "billboard"},
				{"pos": Vector3(-2.8, 0.0, 4.6), "style": "wall_corner"},
				{"pos": Vector3(2.6, 0.0, 4.5), "style": "parked_van"},
			]
		_:
			return []


func _add_cover(pos: Vector3, style: String):
	var obstacle := COVER_OBSTACLE_3D_SCRIPT.new()
	obstacle.position = pos
	if style == "hedge_cover":
		obstacle.rotation.y = deg_to_rad(randf_range(-18.0, 18.0))
	obstacle.setup(_get_cover_size_for_style(style), style)
	level_root.add_child(obstacle)
	cover_obstacles_3d.append(obstacle)
	return obstacle


func _get_cover_size_for_style(style: String) -> Vector3:
	match style:
		"street_lamp":
			return Vector3(0.72, 2.35, 0.42)
		"parked_van":
			return Vector3(2.28, 1.58, 0.98)
		"billboard":
			return Vector3(2.18, 2.74, 0.56)
		"hedge_cover":
			return Vector3(1.26, 1.52, 0.74)
		_:
			return Vector3(1.68, 2.32, 0.76)


func _setup_intro_focus() -> void:
	if battle_core.tutorial_primary_target != null and is_instance_valid(battle_core.tutorial_primary_target):
		var target_pos: Vector3 = battle_core.tutorial_primary_target.global_position
		camera_controller.focus_on_world_position(target_pos + Vector3(-1.8, 0.0, 0.6))
		tutorial_primary_target = battle_core.tutorial_primary_target


func _process(delta: float) -> void:
	if battle_core == null or not is_instance_valid(battle_core):
		return
	if battle_core.battle_closed:
		return
	if battle_mode == null or not is_instance_valid(battle_mode):
		return

	battle_mode.update_3d(delta)

	cover_scan_fade_timer = maxf(0.0, cover_scan_fade_timer - delta)
	_update_cover_fade()
	_update_hud()


func _input(event: InputEvent) -> void:
	if battle_mode == null or not is_instance_valid(battle_mode):
		return
	if handle_common_input(event):
		return
	battle_mode.handle_input_event_3d(event)


func _update_cover_fade() -> void:
	if cover_obstacles_3d.is_empty():
		return
	var ratio := 0.0
	if cover_scan_fade_total > 0.0:
		ratio = clampf(cover_scan_fade_timer / cover_scan_fade_total, 0.0, 1.0)
	for obstacle in cover_obstacles_3d:
		if obstacle != null and is_instance_valid(obstacle):
			obstacle.set_scan_fade_ratio(ratio)


func _update_hud() -> void:
	if hud_controller != null and is_instance_valid(hud_controller):
		hud_controller.update()
	if weapon_renderer != null and is_instance_valid(weapon_renderer) and camera_controller != null and is_instance_valid(camera_controller):
		var hold_ratio: float = 0.0
		if battle_core != null and is_instance_valid(battle_core):
			hold_ratio = float(battle_core.hold_ratio)
		var stability_factor: float = hold_ratio
		if weapon != null and is_instance_valid(weapon):
			stability_factor = float(weapon.get_stability_factor(hold_ratio))
		if weapon_renderer.has_method("update_presentation"):
			weapon_renderer.update_presentation(camera_controller.scope_visible, camera_controller.current_zoom, hold_ratio, stability_factor)
		else:
			weapon_renderer.set_scope_mode(camera_controller.scope_visible)


func _on_fire_pressed() -> void:
	if input_handler == null or not is_instance_valid(input_handler):
		return
	input_handler.fire_requested.emit()


func _on_scan_pressed() -> void:
	if battle_core == null or not is_instance_valid(battle_core) or weapon == null or visual_feedback == null:
		return
	if not battle_core.use_scan_3d(weapon.scan_highlight_sec):
		visual_feedback.push_feedback("扫描次数已用完。", Color(0.92, 0.74, 0.40))
		return

	cover_scan_fade_total = weapon.scan_highlight_sec
	cover_scan_fade_timer = cover_scan_fade_total
	_update_cover_fade()
	if battle_mode != null and is_instance_valid(battle_mode):
		battle_mode._try_progress_tutorial(&"use_scan")


func _on_time_extend_pressed() -> void:
	if input_handler == null or not is_instance_valid(input_handler):
		return
	input_handler.time_extend_requested.emit()


func _on_zoom_in_pressed() -> void:
	if input_handler == null or not is_instance_valid(input_handler):
		return
	input_handler.zoom_in_requested.emit()


func _on_zoom_out_pressed() -> void:
	if input_handler == null or not is_instance_valid(input_handler):
		return
	input_handler.zoom_out_requested.emit()


func _on_battle_finished(result: Dictionary) -> void:
	if _battle_finish_processing:
		return
	_battle_finish_processing = true
	CoreEventBus.battle_finished.emit(result)
	battle_finished.emit(result)
	if hud_controller != null and is_instance_valid(hud_controller):
		hud_controller.show_result(result)


func _on_victory_pending(snapshot: Dictionary) -> void:
	var llm_service = get_node_or_null("/root/LLMService")
	if llm_service == null:
		return
	llm_service.pre_analyze_battle(snapshot)


func _on_shot_fired(result: String, _actor, _hit_point: Vector2, _reward: int) -> void:
	if weapon_renderer != null and is_instance_valid(weapon_renderer):
		weapon_renderer.trigger_fire_feedback(result)
	if AudioService != null and AudioService.has_method("play_sfx"):
		AudioService.play_sfx("sfx_shot_fire")


func _finish_battle(success: bool, reason: String) -> void:
	if battle_core == null or not is_instance_valid(battle_core):
		return
	battle_core.finish_battle(success, reason)


func _handle_camera_move_tutorial(movement: Vector2) -> void:
	if battle_mode == null or not is_instance_valid(battle_mode):
		return
	battle_mode._handle_camera_move_tutorial_3d(movement)


func _zoom_focus_to_next_step() -> void:
	if battle_core.tutorial_primary_target == null or not is_instance_valid(battle_core.tutorial_primary_target):
		return
	var target_pos: Vector3 = battle_core.tutorial_primary_target.global_position
	camera_controller.focus_on_world_position(target_pos)
	camera_controller.set_zoom(maxf(camera_controller.current_zoom, camera_controller.zoom_quick_aim))
	if battle_mode != null and is_instance_valid(battle_mode):
		battle_mode._try_progress_tutorial(&"aim_zoom_in")


func _try_progress_tutorial(action_name: StringName, extra: Dictionary = {}) -> Dictionary:
	return try_progress_tutorial(action_name, extra)


func _debug_focus_tutorial_target() -> void:
	if battle_core.tutorial_primary_target == null or not is_instance_valid(battle_core.tutorial_primary_target):
		return
	camera_controller.focus_on_world_position(battle_core.tutorial_primary_target.global_position)
	if battle_mode != null and is_instance_valid(battle_mode):
		battle_mode._try_progress_tutorial(&"focus_target")


func _debug_shoot_primary_target() -> void:
	if battle_core.tutorial_primary_target == null or not is_instance_valid(battle_core.tutorial_primary_target):
		return
	var actor = battle_core.tutorial_primary_target
	camera_controller.focus_on_world_position(actor.global_position)
	camera_controller.set_zoom(maxf(camera_controller.current_zoom, 1.35))
	battle_core.hold_ratio = 1.0
	var hit_point: Vector3 = actor.global_position + Vector3.UP * actor.body_radius * 0.92
	battle_core._apply_actor_hit_3d(actor, hit_point)
	if battle_mode != null and is_instance_valid(battle_mode):
		battle_mode._try_progress_tutorial(&"fire")


func _debug_shoot_first_civilian() -> void:
	return


func _debug_get_camera_motion_bounds() -> Dictionary:
	return camera_controller.get_camera_motion_bounds()


func _debug_get_aim_world_coverage() -> Dictionary:
	return camera_controller.get_aim_world_coverage()


func _debug_step_edge_auto_pan(edge: String) -> Dictionary:
	return camera_controller.step_edge_auto_pan(edge)


func _debug_is_weapon_ready() -> bool:
	return battle_core.weapon_ready


func _debug_finish_post_shot_recover() -> void:
	battle_core.weapon_ready = true
	visual_feedback.finish_post_shot_recover()


func _debug_get_slowmo_state() -> Dictionary:
	return visual_feedback.get_slowmo_state()


func _debug_finish_slowmo() -> void:
	visual_feedback.finish_slowmo()


func _debug_get_killcam_state() -> Dictionary:
	return visual_feedback.get_killcam_state()


func _debug_finish_killcam() -> void:
	visual_feedback.finish_killcam()


func _debug_finish_misjudgment_review() -> void:
	visual_feedback.finish_misjudgment_review()


func _debug_get_weapon_mount_state() -> Dictionary:
	if weapon_renderer == null or not is_instance_valid(weapon_renderer):
		return {
			"exists": false,
		}
	var state: Dictionary = weapon_renderer.get_mount_state()
	state["scope_visible"] = camera_controller.scope_visible if camera_controller != null and is_instance_valid(camera_controller) else false
	state["weapon_ready"] = battle_core.weapon_ready if battle_core != null and is_instance_valid(battle_core) else false
	return state


func _request_pause_overlay(_entry: String = "keyboard_back") -> void:
	if hud == null or not is_instance_valid(hud):
		return
	if hud.has_method("is_pause_overlay_visible") and bool(hud.call("is_pause_overlay_visible")):
		hud.call("set_pause_overlay_visible", false)
		return
	var status_text := "当前任务已暂停"
	var hint_text := "你可以继续任务，或直接退出回到主菜单。"
	hud.call("set_pause_overlay_visible", true, status_text, hint_text)


func _exit_to_main_menu_from_pause() -> void:
	CoreGameState.record_first_exit("battle_pause_exit")
	CoreEventBus.log_event("battle_exited", {
		"level_id": level_config.level_id,
		"entry": "pause_overlay",
	})
	CoreEventBus.main_menu_requested.emit()


func _debug_get_search_state() -> Dictionary:
	return {
		"hint": _build_search_hint(),
		"has_locator": visual_feedback.locator_target != null and is_instance_valid(visual_feedback.locator_target) and visual_feedback.locator_target.alive,
	}


func _debug_get_identification_feedback_state() -> Dictionary:
	return {
		"combo_count": battle_core.recognition_combo_count,
		"combo_bonus_gold": battle_core.recognition_combo_bonus_gold,
		"replay_text": visual_feedback.last_identification_replay,
		"replay_active": visual_feedback.identification_replay_timer > 0.0,
		"misjudgment_review_active": visual_feedback.misjudgment_review_active,
	}


func _debug_shoot_next_target() -> void:
	for actor in battle_core.active_actors:
		if is_instance_valid(actor) and actor.actor_kind == "target" and actor.alive:
			camera_controller.focus_on_world_position(actor.global_position)
			camera_controller.set_zoom(maxf(camera_controller.current_zoom, 1.35))
			battle_core.hold_ratio = 1.0
			var hit_point: Vector3 = actor.global_position + Vector3.UP * actor.body_radius * 0.92
			battle_core._apply_actor_hit_3d(actor, hit_point)
			if battle_mode != null and is_instance_valid(battle_mode):
				battle_mode._try_progress_tutorial(&"fire")
			return


func _debug_trigger_civilian_false_clue() -> Dictionary:
	return {
		"summary": "当前 3D 战斗已无平民角色",
		"active": false,
	}


func _build_search_hint() -> String:
	if battle_core.tutorial_primary_target != null and is_instance_valid(battle_core.tutorial_primary_target) and battle_core.tutorial_primary_target.alive and _is_primary_target_in_focus():
		return battle_core.tutorial_primary_target.get_suspicion_summary()
	var observed_actor = _get_observed_actor()
	if observed_actor != null and is_instance_valid(observed_actor):
		return observed_actor.get_suspicion_summary()
	if visual_feedback.locator_hint_timer > 0.0 and visual_feedback.locator_target != null and is_instance_valid(visual_feedback.locator_target) and visual_feedback.locator_target.alive:
		var target_pos_2d: Vector2 = Vector2(visual_feedback.locator_target.global_position.x, visual_feedback.locator_target.global_position.z)
		var camera_pos_2d: Vector2 = Vector2(camera_controller.camera.global_position.x, camera_controller.camera.global_position.z)
		return "定位线索：最可疑目标在%s，留意它的头部外壳、肩袖结构和腰侧亮线。" % describe_direction_from_position(camera_pos_2d, target_pos_2d)
	return "搜索提示：优先找头部外壳过紧、肩袖连接偏硬，以及腰侧会短暂显露亮线的目标。"


func _get_observed_actor():
	var observation_center: Vector3 = camera_controller.get_aim_world_position()
	var observation_center_2d: Vector2 = Vector2(observation_center.x, observation_center.z)
	var max_distance: float = 2.5 if not camera_controller.scope_visible else 1.8
	var nearest_actor = null
	var nearest_distance: float = INF
	for actor in battle_core.active_actors:
		if not is_instance_valid(actor) or not actor.alive:
			continue
		var actor_pos_2d: Vector2 = Vector2(actor.global_position.x, actor.global_position.z)
		var distance: float = actor_pos_2d.distance_to(observation_center_2d)
		if distance <= max_distance and distance < nearest_distance:
			nearest_actor = actor
			nearest_distance = distance
	return nearest_actor


func _is_primary_target_in_focus() -> bool:
	var focus_radius_world := lerpf(3.0, 1.5, clampf((camera_controller.current_zoom - 1.0) / 0.6, 0.0, 1.0))
	var target_pos_2d: Vector2 = Vector2(battle_core.tutorial_primary_target.global_position.x, battle_core.tutorial_primary_target.global_position.z)
	var camera_pos_2d: Vector2 = Vector2(camera_controller.camera.global_position.x, camera_controller.camera.global_position.z)
	return target_pos_2d.distance_to(camera_pos_2d) <= focus_radius_world
