extends StaticBody3D
class_name PveCoverObstacle3D

const TEX_ENV_WALL_CORNER := preload("res://assets_mvp_placeholder/environment/env-wall-corner.svg")
const TEX_ENV_STREET_LAMP := preload("res://assets_mvp_placeholder/environment/env-street-lamp.svg")
const TEX_ENV_PARKED_VAN := preload("res://assets_mvp_placeholder/environment/env-parked-van.svg")
const TEX_ENV_BILLBOARD := preload("res://assets_mvp_placeholder/environment/env-billboard.svg")
const TEX_ENV_GRIME_PATH := "res://assets_mvp_placeholder/materials/material-environment-grime-overlay.svg"
const TEX_ENV_EDGE_WEAR_PATH := "res://assets_mvp_placeholder/materials/material-environment-edge-wear-overlay.svg"
const SCENE_WALL_CORNER := preload("res://assets_mvp_3d/environment/wall_corner_cover.glb")
const SCENE_STREET_LAMP := preload("res://assets_mvp_3d/environment/street_lamp_cover.glb")
const SCENE_PARKED_VAN := preload("res://assets_mvp_3d/environment/parked_van_cover.glb")
const SCENE_BILLBOARD := preload("res://assets_mvp_3d/environment/billboard_cover.glb")

var size: Vector3 = Vector3(3.0, 2.8, 0.8)
var scan_fade_ratio := 0.0
var style_id := "wall_corner"

var collider: CollisionShape3D
var mesh_root: Node3D
var damage_root: Node3D
var art_root: Node3D
var materials: Array[StandardMaterial3D] = []
var art_materials: Array[StandardMaterial3D] = []
var imported_asset_root: Node3D
var imported_asset_path := ""
var style_variant_seed := 0.0
var decal_bullet_hole_texture: Texture2D
var decal_cover_impact_texture: Texture2D
var environment_grime_texture: Texture2D
var environment_edge_texture: Texture2D

var damage_hp: int = 3
var damage_state: int = 0
var destroyed: bool = false
var collapse_tween: Tween = null
var blast_reaction_tween: Tween = null
var blast_feedback_cooldown := 0.0
var blast_reaction_count := 0
var max_active_blast_parts := 12
var collapse_progress := 0.0
var post_destroy_hit_count := 0
var removal_started := false
var auto_cleanup_delay := -1.0
var last_blast_tier := "none"
var last_blast_effective_force := 0.0
var last_blast_effect_kind := ""
var last_blast_detached_spawn_count := 0


func setup(box_size: Vector3, style: String = "wall_corner") -> void:
	size = box_size
	style_id = style
	style_variant_seed = randf()
	if style_id == "hedge_cover":
		size.y *= lerpf(0.92, 1.22, style_variant_seed)
		if style_variant_seed > 0.72:
			size.y *= lerpf(1.10, 1.24, inverse_lerp(0.72, 1.0, style_variant_seed))
	damage_state = 0
	destroyed = false
	collapse_progress = 0.0
	post_destroy_hit_count = 0
	removal_started = false
	auto_cleanup_delay = -1.0
	blast_feedback_cooldown = 0.0
	blast_reaction_count = 0
	last_blast_tier = "none"
	last_blast_effective_force = 0.0
	last_blast_effect_kind = ""
	last_blast_detached_spawn_count = 0
	_build()
	_update_visual()


func set_scan_fade_ratio(ratio: float) -> void:
	scan_fade_ratio = clampf(ratio, 0.0, 1.0)
	_update_visual()


func apply_bullet_hit(hit_point: Vector3, hit_normal: Vector3) -> void:
	if removal_started:
		return
	if destroyed:
		_spawn_bullet_hole(hit_point, hit_normal)
		_apply_post_collapse_damage(0.24)
		return

	if damage_root != null and is_instance_valid(damage_root):
		_spawn_bullet_hole(hit_point, hit_normal)

	damage_hp -= 1
	if damage_hp <= 0:
		_collapse()
	else:
		damage_state = max(damage_state, 4 - damage_hp)
		_update_damage_visuals()


func apply_impact_feedback(hit_point: Vector3, hit_normal: Vector3, effect_type: String = "blocked", blast_tier: String = "medium") -> void:
	if not destroyed:
		apply_bullet_hit(hit_point, hit_normal)
	var blast_profile: Dictionary = _get_blast_profile(effect_type, blast_tier)
	if blast_profile.is_empty():
		return
	apply_explosion_impulse(
		hit_point,
		float(blast_profile.get("radius", 0.0)),
		float(blast_profile.get("force", 0.0)),
		float(blast_profile.get("lift_bias", 0.0)),
		str(blast_profile.get("effect_kind", "explosion")),
		str(blast_profile.get("blast_tier", blast_tier))
	)


func apply_explosion_impulse(
	blast_origin: Vector3,
	blast_radius: float,
	blast_force: float,
	lift_bias: float,
	effect_kind: String = "explosion",
	blast_tier: String = "medium"
) -> void:
	if removal_started:
		return
	if blast_feedback_cooldown > 0.0:
		return
	var safe_radius := maxf(blast_radius, 0.001)
	var center: Vector3 = global_position + Vector3(0.0, size.y * 0.32, 0.0)
	var outward: Vector3 = center - blast_origin
	if outward.length_squared() < 0.0001:
		outward = Vector3(0.0, 0.0, -1.0)
	var distance_ratio := clampf(outward.length() / safe_radius, 0.0, 1.0)
	var effective_ratio := 1.0 - distance_ratio
	if effective_ratio <= 0.04:
		return

	var style_scale: float = _get_style_blast_response_scale()
	var effective_force: float = blast_force * effective_ratio * style_scale
	if effective_force <= 0.08:
		return

	blast_feedback_cooldown = 0.08
	blast_reaction_count += 1
	last_blast_tier = blast_tier
	last_blast_effective_force = effective_force
	last_blast_effect_kind = effect_kind
	var push_dir: Vector3 = outward.normalized()
	_play_blast_reaction(push_dir, effective_force, lift_bias)
	last_blast_detached_spawn_count = _spawn_blast_detached_parts(push_dir, effective_force, lift_bias, effect_kind, blast_tier)
	if destroyed:
		_apply_post_collapse_damage(_get_post_collapse_blast_increment(blast_tier, effective_force))
		return

	if style_id in ["street_lamp", "billboard"] and effective_force >= 0.9 and not destroyed:
		damage_state = max(damage_state, 2)
		_update_damage_visuals()
	if style_id == "wall_corner" and not destroyed:
		if blast_tier == "heavy" and effective_force >= 0.95:
			damage_state = max(damage_state, 3)
		elif blast_tier == "medium" and effective_force >= 0.62:
			damage_state = max(damage_state, 2)
		elif blast_tier == "light" and effective_force >= 0.38:
			damage_state = max(damage_state, 1)
		_update_damage_visuals()
	if style_id == "parked_van" and not destroyed:
		if blast_tier == "heavy" and effective_force >= 0.72:
			damage_state = max(damage_state, 2)
		elif blast_tier == "medium" and effective_force >= 0.48:
			damage_state = max(damage_state, 1)
		elif blast_tier == "light" and effective_force >= 0.30:
			damage_state = max(damage_state, 1)
		_update_damage_visuals()


func _build() -> void:
	if mesh_root != null:
		return
	_ensure_decal_textures()
	_ensure_surface_overlay_textures()

	mesh_root = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)

	damage_root = Node3D.new()
	damage_root.name = "DecalRoot"
	add_child(damage_root)

	art_root = Node3D.new()
	art_root.name = "ArtRoot"
	add_child(art_root)

	collider = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	add_child(collider)

	collision_layer = 1
	collision_mask = 0

	if _try_build_imported_asset():
		return

	match style_id:
		"street_lamp":
			_build_street_lamp()
		"parked_van":
			_build_parked_van()
		"billboard":
			_build_billboard()
		"hedge_cover":
			_build_hedge_cover()
		_:
			_build_wall_corner()


func _collapse() -> void:
	if destroyed:
		return
	destroyed = true
	damage_state = 4
	collapse_progress = max(collapse_progress, 0.38)
	post_destroy_hit_count = 0
	auto_cleanup_delay = 3.0
	if collider != null and is_instance_valid(collider):
		collider.disabled = true

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	collapse_tween = create_tween()
	collapse_tween.set_parallel(true)

	if mesh_root != null and is_instance_valid(mesh_root):
		for mi in _get_mesh_instances(mesh_root):
			var rot_axis: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized()
			var fall_angle: float = rng.randf_range(0.3, 0.9)
			var offset: Vector3 = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.5, -0.1), rng.randf_range(-0.3, 0.3))
			var delay: float = rng.randf_range(0.0, 0.15)
			collapse_tween.tween_interval(delay)
			collapse_tween.parallel().tween_property(mi, "rotation", rot_axis * fall_angle, 0.5).set_ease(Tween.EASE_IN).set_delay(delay)
			collapse_tween.parallel().tween_property(mi, "position", mi.position + offset, 0.5).set_ease(Tween.EASE_IN).set_delay(delay)
		for mat in materials:
			if mat != null:
				collapse_tween.tween_property(mat, "albedo_color:a", 0.2, 0.8).set_delay(0.4).set_ease(Tween.EASE_IN_OUT)

	_spawn_collapse_debris()
	_update_collapse_decay_visuals()


func _spawn_collapse_debris() -> void:
	if damage_root == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var debris_color: Color = _get_debris_color()
	for i in range(14):
		var debris := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var s: float = rng.randf_range(0.08, 0.22)
		mesh.size = Vector3(s, s * rng.randf_range(0.4, 0.9), s)
		debris.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = debris_color
		mat.roughness = 0.9
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debris.material_override = mat
		var spawn_pos: Vector3 = Vector3(
			rng.randf_range(-size.x * 0.3, size.x * 0.3),
			rng.randf_range(0.0, size.y * 0.6),
			rng.randf_range(-size.z * 0.3, size.z * 0.3)
		)
		debris.position = spawn_pos
		debris.set_meta("vel", Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(1.0, 3.5), rng.randf_range(-2.0, 2.0)))
		debris.set_meta("ang_vel", Vector3(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0)))
		debris.set_meta("life", 1.2)
		damage_root.add_child(debris)


func _spawn_bullet_hole(hit_point: Vector3, hit_normal: Vector3) -> void:
	if damage_root == null:
		return
	var local_pos: Vector3 = to_local(hit_point)
	var up: Vector3 = Vector3.UP
	if absf(hit_normal.dot(Vector3.UP)) > 0.95:
		up = Vector3.RIGHT

	var hole := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var hole_size: float = 0.12 + randf() * 0.06
	mesh.size = Vector2(hole_size, hole_size)
	hole.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = decal_bullet_hole_texture
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.88)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	hole.material_override = mat
	hole.position = local_pos + hit_normal * 0.02
	damage_root.add_child(hole)
	hole.look_at(hole.position + hit_normal, up)
	hole.rotate(hit_normal, randf() * TAU)

	var impact_mark := MeshInstance3D.new()
	var impact_mesh := QuadMesh.new()
	var impact_size: float = hole_size * 2.2
	impact_mesh.size = Vector2(impact_size, impact_size)
	impact_mark.mesh = impact_mesh
	var impact_mat := StandardMaterial3D.new()
	impact_mat.albedo_texture = decal_cover_impact_texture
	impact_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.72)
	impact_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	impact_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	impact_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	impact_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	impact_mark.material_override = impact_mat
	impact_mark.position = local_pos + hit_normal * 0.018
	damage_root.add_child(impact_mark)
	impact_mark.look_at(impact_mark.position + hit_normal, up)
	impact_mark.rotate(hit_normal, randf() * TAU)

	var crack_count := clampi(damage_state, 0, 2)
	for ci in range(crack_count):
		var crack := MeshInstance3D.new()
		var cmesh := QuadMesh.new()
		var clen: float = 0.18 + randf() * 0.3
		cmesh.size = Vector2(clen, 0.02 + randf() * 0.015)
		crack.mesh = cmesh
		var cmat := StandardMaterial3D.new()
		cmat.albedo_texture = decal_cover_impact_texture
		cmat.albedo_color = Color(0.86, 0.90, 0.96, 0.42)
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		cmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		crack.material_override = cmat
		var tangent: Vector3 = hit_normal.cross(up).normalized()
		if tangent.length_squared() < 0.01:
			tangent = hit_normal.cross(Vector3.FORWARD).normalized()
		var crack_offset: Vector3 = tangent * randf_range(-0.1, 0.1) * clen
		crack.position = local_pos + hit_normal * 0.025 + crack_offset
		damage_root.add_child(crack)
		crack.look_at(crack.position + hit_normal, up)
		crack.rotate(hit_normal, randf() * TAU)


func _update_damage_visuals() -> void:
	if mesh_root == null or materials.is_empty():
		return
	var dmg_ratio: float = float(damage_state) / 4.0
	for mat in materials:
		if mat == null:
			continue
		mat.albedo_color = mat.albedo_color.darkened(dmg_ratio * 0.15)


func _try_build_imported_asset() -> bool:
	var asset_scene: PackedScene = _resolve_asset_scene()
	if asset_scene == null:
		return false
	imported_asset_path = asset_scene.resource_path
	imported_asset_root = asset_scene.instantiate() as Node3D
	if imported_asset_root == null:
		return false
	imported_asset_root.name = "ImportedAsset"
	mesh_root.add_child(imported_asset_root)
	_collect_imported_materials()
	return not materials.is_empty()


func _resolve_asset_scene() -> PackedScene:
	match style_id:
		"street_lamp":
			return SCENE_STREET_LAMP
		"parked_van":
			return SCENE_PARKED_VAN
		"billboard":
			return SCENE_BILLBOARD
		"hedge_cover":
			return null
		_:
			return SCENE_WALL_CORNER


func _collect_imported_materials() -> void:
	materials.clear()
	for mesh_instance in _get_mesh_instances(mesh_root):
		var material: Material = mesh_instance.material_override
		if material == null:
			material = mesh_instance.get_active_material(0)
		if material == null:
			continue
		if material is StandardMaterial3D:
			var local_material := material.duplicate() as StandardMaterial3D
			mesh_instance.material_override = local_material
			local_material.roughness = clampf(local_material.roughness + 0.08, 0.18, 0.96)
			materials.append(local_material)


func _get_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if root == null:
		return found
	for child in root.get_children():
		if child is MeshInstance3D:
			found.append(child as MeshInstance3D)
		found.append_array(_get_mesh_instances(child))
	return found


func _update_visual() -> void:
	if mesh_root == null:
		return

	var alpha := lerpf(0.92, 0.28, scan_fade_ratio)
	for material in materials:
		if material == null:
			continue
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.9 else BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color.a = alpha
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	for art_material in art_materials:
		if art_material == null:
			continue
		art_material.albedo_color.a = minf(alpha + 0.08, 0.95)


func _process(delta: float) -> void:
	blast_feedback_cooldown = maxf(0.0, blast_feedback_cooldown - delta)
	if destroyed and not removal_started and auto_cleanup_delay >= 0.0:
		auto_cleanup_delay -= delta
		if auto_cleanup_delay <= 0.0:
			_apply_post_collapse_damage(0.32)
	if destroyed and not removal_started:
		_update_collapse_decay_visuals()
	if damage_root == null or not is_instance_valid(damage_root):
		return
	var to_remove: Array[Node] = []
	for child in damage_root.get_children():
		if child is MeshInstance3D and child.has_meta("vel"):
			var mi: MeshInstance3D = child as MeshInstance3D
			var vel: Vector3 = mi.get_meta("vel")
			var ang_vel: Vector3 = mi.get_meta("ang_vel")
			vel.y -= 9.0 * delta
			mi.position += vel * delta
			mi.rotate(Vector3.RIGHT, ang_vel.x * delta)
			mi.rotate(Vector3.UP, ang_vel.y * delta)
			mi.rotate(Vector3.FORWARD, ang_vel.z * delta)
			var life: float = float(mi.get_meta("life")) - delta
			mi.set_meta("life", life)
			if mi.position.y < -0.5 or life <= 0.0:
				if mi.material_override is StandardMaterial3D:
					var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
					mat.albedo_color.a = maxf(life * 0.8, 0.0)
				if life <= -0.3 or mi.position.y < -1.0:
					to_remove.append(mi)
			mi.set_meta("vel", vel)
	for node in to_remove:
		node.queue_free()


func _apply_post_collapse_damage(amount: float) -> void:
	if not destroyed or removal_started:
		return
	post_destroy_hit_count += 1
	collapse_progress = minf(collapse_progress + amount, 1.0)
	_spawn_secondary_collapse_debris(amount)
	_update_collapse_decay_visuals()
	if collapse_progress >= 1.0 or post_destroy_hit_count >= 4:
		_begin_removal()


func _get_post_collapse_blast_increment(blast_tier: String, effective_force: float) -> float:
	var base_increment := clampf(0.12 + effective_force * 0.18, 0.12, 0.42)
	match blast_tier:
		"heavy":
			return minf(base_increment + 0.18, 0.56)
		"medium":
			return minf(base_increment + 0.08, 0.46)
		_:
			return minf(base_increment, 0.34)


func _spawn_secondary_collapse_debris(amount: float) -> void:
	if damage_root == null or not is_instance_valid(damage_root):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var debris_color: Color = _get_debris_color()
	var burst_count: int = clampi(int(round(amount * 8.0)), 2, 6)
	for i in range(burst_count):
		var debris := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var s: float = rng.randf_range(0.05, 0.14)
		mesh.size = Vector3(s, s * rng.randf_range(0.5, 1.0), s)
		debris.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = debris_color
		mat.roughness = 0.92
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debris.material_override = mat
		debris.position = Vector3(
			rng.randf_range(-size.x * 0.22, size.x * 0.22),
			rng.randf_range(0.06, size.y * 0.32),
			rng.randf_range(-size.z * 0.22, size.z * 0.22)
		)
		debris.set_meta("vel", Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(0.8, 2.0), rng.randf_range(-1.6, 1.6)))
		debris.set_meta("ang_vel", Vector3(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0)))
		debris.set_meta("life", 0.6 + rng.randf_range(0.0, 0.3))
		debris.set_meta("blast_detached", true)
		damage_root.add_child(debris)


func _update_collapse_decay_visuals() -> void:
	var visible_alpha := clampf(0.24 * (1.0 - collapse_progress), 0.0, 0.24)
	for mat in materials:
		if mat == null:
			continue
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_color.a = visible_alpha
	for art_mat in art_materials:
		if art_mat == null:
			continue
		art_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		art_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		art_mat.albedo_color.a = minf(visible_alpha + 0.06, 0.28)
	if mesh_root != null and is_instance_valid(mesh_root):
		mesh_root.scale = Vector3(1.0, maxf(0.22, 1.0 - collapse_progress * 0.72), 1.0)
	if art_root != null and is_instance_valid(art_root):
		art_root.scale = Vector3(1.0, maxf(0.16, 1.0 - collapse_progress * 0.80), 1.0)


func _begin_removal() -> void:
	if removal_started:
		return
	removal_started = true
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	if blast_reaction_tween != null and blast_reaction_tween.is_valid():
		blast_reaction_tween.kill()
	var removal_tween := create_tween()
	removal_tween.set_parallel(true)
	if mesh_root != null and is_instance_valid(mesh_root):
		removal_tween.tween_property(mesh_root, "scale", Vector3(1.0, 0.06, 1.0), 0.26).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if art_root != null and is_instance_valid(art_root):
		removal_tween.tween_property(art_root, "scale", Vector3(1.0, 0.04, 1.0), 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	for mat in materials:
		if mat != null:
			removal_tween.tween_property(mat, "albedo_color:a", 0.0, 0.22).set_ease(Tween.EASE_IN)
	for art_mat in art_materials:
		if art_mat != null:
			removal_tween.tween_property(art_mat, "albedo_color:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
	removal_tween.finished.connect(queue_free)


func _make_material(color: Color, roughness: float = 0.92, metallic: float = 0.0, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	materials.append(material)
	return material


func _get_blast_profile(effect_type: String, blast_tier: String = "medium") -> Dictionary:
	var tier_profile: Dictionary = _get_blast_tier_profile(blast_tier)
	var force_scale: float = float(tier_profile.get("force_scale", 1.0))
	var radius_scale: float = float(tier_profile.get("radius_scale", 1.0))
	var lift_scale: float = float(tier_profile.get("lift_scale", 1.0))
	match effect_type:
		"metal":
			return {
				"radius": 3.2 * radius_scale,
				"force": 1.18 * force_scale,
				"lift_bias": 0.62 * lift_scale,
				"effect_kind": "metal_blast",
				"blast_tier": blast_tier,
			}
		"concrete":
			return {
				"radius": 2.8 * radius_scale,
				"force": 0.96 * force_scale,
				"lift_bias": 0.42 * lift_scale,
				"effect_kind": "concrete_blast",
				"blast_tier": blast_tier,
			}
		"blocked":
			return {
				"radius": 2.6 * radius_scale,
				"force": 0.82 * force_scale,
				"lift_bias": 0.38 * lift_scale,
				"effect_kind": "blocked_blast",
				"blast_tier": blast_tier,
			}
		_:
			return {}


func _get_blast_tier_profile(blast_tier: String) -> Dictionary:
	match blast_tier:
		"light":
			return {
				"force_scale": 0.72,
				"radius_scale": 0.88,
				"lift_scale": 0.82,
				"extra_parts": 0,
			}
		"heavy":
			return {
				"force_scale": 1.38,
				"radius_scale": 1.18,
				"lift_scale": 1.26,
				"extra_parts": 2,
			}
		_:
			return {
				"force_scale": 1.0,
				"radius_scale": 1.0,
				"lift_scale": 1.0,
				"extra_parts": 1,
			}


func _get_style_blast_response_scale() -> float:
	match style_id:
		"street_lamp":
			return 1.28
		"billboard":
			return 1.12
		"wall_corner":
			return 1.08
		"parked_van":
			return 0.46
		"hedge_cover":
			return 0.82
		_:
			return 0.55


func _play_blast_reaction(push_dir: Vector3, effective_force: float, lift_bias: float) -> void:
	if mesh_root == null or not is_instance_valid(mesh_root):
		return
	if blast_reaction_tween != null and blast_reaction_tween.is_valid():
		blast_reaction_tween.kill()

	var offset_strength := clampf(0.10 + effective_force * 0.12, 0.08, 0.42)
	var offset := push_dir * offset_strength + Vector3.UP * minf(lift_bias * effective_force * 0.10, 0.16)
	var rotation_offset := Vector3.ZERO
	match style_id:
		"street_lamp":
			rotation_offset = Vector3(push_dir.z * 0.16 * effective_force, 0.0, -push_dir.x * 0.42 * effective_force)
		"billboard":
			rotation_offset = Vector3(-0.22 * effective_force, push_dir.x * 0.10 * effective_force, -push_dir.x * 0.26 * effective_force)
		"wall_corner":
			rotation_offset = Vector3(push_dir.z * 0.05 * effective_force, 0.0, -push_dir.x * 0.08 * effective_force)
		"parked_van":
			rotation_offset = Vector3(0.0, push_dir.x * 0.06 * effective_force, -push_dir.x * 0.04 * effective_force)
		_:
			rotation_offset = Vector3(push_dir.z * 0.08 * effective_force, 0.0, -push_dir.x * 0.12 * effective_force)

	mesh_root.position += offset
	mesh_root.rotation += rotation_offset
	if art_root != null and is_instance_valid(art_root):
		art_root.position += offset * 0.68
		art_root.rotation += rotation_offset * 1.08

	blast_reaction_tween = create_tween()
	blast_reaction_tween.set_parallel(true)
	blast_reaction_tween.tween_property(mesh_root, "position", Vector3.ZERO, 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	blast_reaction_tween.tween_property(mesh_root, "rotation", Vector3.ZERO, 0.48).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if art_root != null and is_instance_valid(art_root):
		blast_reaction_tween.tween_property(art_root, "position", Vector3.ZERO, 0.38).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		blast_reaction_tween.tween_property(art_root, "rotation", Vector3.ZERO, 0.44).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _spawn_blast_detached_parts(push_dir: Vector3, effective_force: float, lift_bias: float, effect_kind: String, blast_tier: String = "medium") -> int:
	if damage_root == null or not is_instance_valid(damage_root):
		return 0
	var remaining_budget: int = max(max_active_blast_parts - _count_active_blast_parts(), 0)
	if remaining_budget <= 0:
		return 0
	var part_specs: Array[Dictionary] = _build_blast_part_specs()
	if part_specs.is_empty():
		return 0
	var tier_profile: Dictionary = _get_blast_tier_profile(blast_tier)
	var extra_parts: int = int(tier_profile.get("extra_parts", 0))
	var spawn_count: int = mini(part_specs.size(), maxi(1, mini(remaining_budget, int(ceil(effective_force * 2.4)) + extra_parts)))
	for index in range(spawn_count):
		_spawn_detached_part(part_specs[index], push_dir, effective_force, lift_bias, effect_kind)
	return spawn_count


func _build_blast_part_specs() -> Array[Dictionary]:
	match style_id:
		"street_lamp":
			return [
				{
					"shape": "box",
					"size": Vector3(size.x * 0.26, size.y * 0.16, size.z * 0.18),
					"pos": Vector3(size.x * 0.22, size.y * 0.24, 0.0),
					"color": Color(0.92, 0.84, 0.48, 0.92),
					"metallic": 0.10,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.40, size.y * 0.05, size.z * 0.14),
					"pos": Vector3(size.x * 0.10, size.y * 0.34, 0.0),
					"color": Color(0.18, 0.20, 0.22, 0.92),
					"metallic": 0.12,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.42, size.y * 0.18, size.z * 0.10),
					"pos": Vector3(0.0, -size.y * 0.10, 0.0),
					"color": Color(0.18, 0.52, 0.88, 0.92),
					"metallic": 0.06,
				},
			]
		"billboard":
			return [
				{
					"shape": "box",
					"size": Vector3(size.x * 0.76, size.y * 0.30, size.z * 0.10),
					"pos": Vector3(0.0, size.y * 0.18, size.z * 0.01),
					"color": Color(0.18, 0.28, 0.42, 0.92),
					"metallic": 0.06,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.56, size.y * 0.07, size.z * 0.11),
					"pos": Vector3(0.0, size.y * 0.23, size.z * 0.02),
					"color": Color(0.96, 0.88, 0.55, 0.92),
					"metallic": 0.04,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.26, size.y * 0.14, size.z * 0.10),
					"pos": Vector3(-size.x * 0.14, size.y * 0.12, 0.0),
					"color": Color(0.92, 0.74, 0.18, 0.92),
					"metallic": 0.05,
				},
			]
		"wall_corner":
			return [
				{
					"shape": "box",
					"size": Vector3(size.x * 0.18, size.y * 0.16, size.z * 0.22),
					"pos": Vector3(size.x * 0.18, size.y * 0.26, -size.z * 0.18),
					"color": Color(0.74, 0.72, 0.68, 0.92),
					"metallic": 0.02,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.15, size.y * 0.12, size.z * 0.16),
					"pos": Vector3(-size.x * 0.06, size.y * 0.12, size.z * 0.08),
					"color": Color(0.62, 0.60, 0.56, 0.92),
					"metallic": 0.0,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.10, size.y * 0.10, size.z * 0.14),
					"pos": Vector3(size.x * 0.06, size.y * 0.04, size.z * 0.16),
					"color": Color(0.56, 0.54, 0.50, 0.92),
					"metallic": 0.0,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.08, size.y * 0.08, size.z * 0.12),
					"pos": Vector3(-size.x * 0.12, size.y * 0.28, -size.z * 0.04),
					"color": Color(0.80, 0.76, 0.66, 0.92),
					"metallic": 0.0,
				},
			]
		"parked_van":
			return [
				{
					"shape": "box",
					"size": Vector3(size.x * 0.34, size.y * 0.28, size.z * 0.08),
					"pos": Vector3(size.x * 0.22, size.y * 0.10, size.z * 0.43),
					"color": Color(0.18, 0.44, 0.72, 0.92),
					"metallic": 0.18,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.30, size.y * 0.16, size.z * 0.10),
					"pos": Vector3(-size.x * 0.18, size.y * 0.32, size.z * 0.05),
					"color": Color(0.22, 0.24, 0.28, 0.92),
					"metallic": 0.12,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.18, size.y * 0.10, size.z * 0.08),
					"pos": Vector3(size.x * 0.02, -size.y * 0.04, size.z * 0.46),
					"color": Color(0.74, 0.82, 0.92, 0.76),
					"metallic": 0.04,
				},
				{
					"shape": "box",
					"size": Vector3(size.x * 0.12, size.y * 0.10, size.z * 0.08),
					"pos": Vector3(-size.x * 0.30, size.y * 0.02, -size.z * 0.38),
					"color": Color(0.16, 0.18, 0.22, 0.92),
					"metallic": 0.10,
				},
			]
		_:
			return []


func _spawn_detached_part(spec: Dictionary, push_dir: Vector3, effective_force: float, lift_bias: float, effect_kind: String) -> void:
	var debris := MeshInstance3D.new()
	var shape_kind := str(spec.get("shape", "box"))
	match shape_kind:
		"cylinder":
			var cylinder := CylinderMesh.new()
			var radius := float(spec.get("radius", 0.12))
			cylinder.top_radius = radius
			cylinder.bottom_radius = radius
			cylinder.height = float(spec.get("height", 0.4))
			debris.mesh = cylinder
		_:
			var box := BoxMesh.new()
			box.size = spec.get("size", Vector3(0.2, 0.2, 0.2))
			debris.mesh = box
	debris.position = spec.get("pos", Vector3.ZERO)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = spec.get("color", _get_debris_color())
	mat.roughness = 0.74
	mat.metallic = float(spec.get("metallic", 0.0))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debris.material_override = mat
	var lateral_scale := clampf(1.1 + effective_force * 0.95, 0.8, 2.2)
	var lift_scale := clampf(0.9 + lift_bias * effective_force * 1.4, 0.6, 2.1)
	var side_jitter := Vector3(randf_range(-0.55, 0.55), randf_range(0.0, 0.28), randf_range(-0.55, 0.55))
	var velocity := (push_dir + side_jitter).normalized() * lateral_scale
	velocity.y += lift_scale
	debris.set_meta("vel", velocity)
	debris.set_meta("ang_vel", Vector3(randf_range(-6.0, 6.0), randf_range(-7.5, 7.5), randf_range(-6.0, 6.0)))
	debris.set_meta("life", 0.9 + randf_range(0.0, 0.45))
	debris.set_meta("blast_detached", true)
	debris.set_meta("blast_kind", effect_kind)
	damage_root.add_child(debris)


func _count_active_blast_parts() -> int:
	if damage_root == null or not is_instance_valid(damage_root):
		return 0
	var count := 0
	for child in damage_root.get_children():
		if child is MeshInstance3D and child.has_meta("blast_detached"):
			count += 1
	return count


func _get_debris_color() -> Color:
	match style_id:
		"street_lamp":
			return Color(0.18, 0.2, 0.22)
		"parked_van":
			return Color(0.75, 0.76, 0.78)
		"billboard":
			return Color(0.85, 0.68, 0.16)
		"hedge_cover":
			return Color(0.26, 0.54, 0.26)
		_:
			return Color(0.2, 0.21, 0.25)


func _add_box(box_size: Vector3, local_pos: Vector3, color: Color, roughness: float = 0.92, metallic: float = 0.0, emission: Color = Color.BLACK) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_pos
	mesh_instance.material_override = _make_material(color, roughness, metallic, emission)
	mesh_root.add_child(mesh_instance)


func _add_cylinder(radius: float, height: float, local_pos: Vector3, color: Color, roughness: float = 0.92, metallic: float = 0.0, emission: Color = Color.BLACK) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = local_pos
	mesh_instance.material_override = _make_material(color, roughness, metallic, emission)
	mesh_root.add_child(mesh_instance)


func _build_wall_corner() -> void:
	var wall_color := Color(0.22, 0.23, 0.27, 0.92)
	_add_box(Vector3(size.x, size.y, size.z * 0.42), Vector3(0.0, 0.0, -size.z * 0.18), wall_color)
	_add_box(Vector3(size.x * 0.42, size.y, size.z), Vector3(-size.x * 0.24, 0.0, 0.0), wall_color.darkened(0.08))
	_add_box(Vector3(size.x * 0.18, size.y * 0.06, size.z * 0.28), Vector3(size.x * 0.12, size.y * 0.18, -size.z * 0.22), Color(0.95, 0.78, 0.20, 0.92), 0.55)
	_add_art_billboard(TEX_ENV_WALL_CORNER, Vector2(size.x * 1.05, size.y * 1.18), Vector3(0.0, size.y * 0.20, size.z * 0.34))
	_add_surface_overlay(environment_grime_texture, Vector2(size.x * 1.00, size.y * 1.05), Vector3(0.0, size.y * 0.16, size.z * 0.23), Color(0.72, 0.70, 0.68, 0.18))
	_add_surface_overlay(environment_edge_texture, Vector2(size.x * 0.98, size.y * 0.94), Vector3(0.0, size.y * 0.22, size.z * 0.24), Color(0.98, 0.92, 0.82, 0.18))


func _build_street_lamp() -> void:
	var dark := Color(0.15, 0.17, 0.19, 0.92)
	_add_cylinder(0.08, size.y * 0.96, Vector3(0.0, 0.0, 0.0), dark, 0.65, 0.12)
	_add_box(Vector3(size.x * 0.36, size.y * 0.05, size.z * 0.16), Vector3(size.x * 0.10, size.y * 0.34, 0.0), dark, 0.65, 0.12)
	_add_box(Vector3(size.x * 0.26, size.y * 0.18, size.z * 0.20), Vector3(size.x * 0.22, size.y * 0.24, 0.0), Color(0.22, 0.24, 0.26, 0.9), 0.4, 0.08, Color(1.0, 0.88, 0.48) * 0.22)
	_add_box(Vector3(size.x * 0.44, size.y * 0.18, size.z * 0.10), Vector3(0.0, -size.y * 0.10, 0.0), Color(0.18, 0.52, 0.88, 0.92), 0.35)
	_add_art_billboard(TEX_ENV_STREET_LAMP, Vector2(size.x * 1.10, size.y * 1.30), Vector3(0.0, size.y * 0.12, size.z * 0.30))
	_add_surface_overlay(environment_grime_texture, Vector2(size.x * 0.54, size.y * 0.44), Vector3(0.02, size.y * 0.06, size.z * 0.12), Color(0.70, 0.68, 0.66, 0.16))


func _build_parked_van() -> void:
	var body := Color(0.82, 0.84, 0.88, 0.92)
	var trim := Color(0.12, 0.13, 0.15, 0.92)
	_add_box(Vector3(size.x * 0.82, size.y * 0.52, size.z * 0.76), Vector3(0.0, -size.y * 0.10, 0.0), body, 0.58, 0.08)
	_add_box(Vector3(size.x * 0.28, size.y * 0.42, size.z * 0.74), Vector3(size.x * 0.22, size.y * 0.02, 0.0), body.lightened(0.05), 0.58, 0.08)
	_add_box(Vector3(size.x * 0.22, size.y * 0.20, size.z * 0.60), Vector3(size.x * 0.24, size.y * 0.06, 0.0), Color(0.18, 0.24, 0.32, 0.72), 0.18, 0.12)
	_add_cylinder(size.y * 0.11, size.z * 0.22, Vector3(-size.x * 0.22, -size.y * 0.28, size.z * 0.28), trim, 0.74, 0.2)
	_add_cylinder(size.y * 0.11, size.z * 0.22, Vector3(size.x * 0.22, -size.y * 0.28, size.z * 0.28), trim, 0.74, 0.2)
	_add_cylinder(size.y * 0.11, size.z * 0.22, Vector3(-size.x * 0.22, -size.y * 0.28, -size.z * 0.28), trim, 0.74, 0.2)
	_add_cylinder(size.y * 0.11, size.z * 0.22, Vector3(size.x * 0.22, -size.y * 0.28, -size.z * 0.28), trim, 0.74, 0.2)
	_add_art_billboard(TEX_ENV_PARKED_VAN, Vector2(size.x * 1.22, size.y * 0.92), Vector3(0.0, -size.y * 0.04, size.z * 0.36))
	_add_surface_overlay(environment_grime_texture, Vector2(size.x * 0.92, size.y * 0.42), Vector3(0.0, -size.y * 0.04, size.z * 0.30), Color(0.56, 0.56, 0.58, 0.18))
	_add_surface_overlay(environment_edge_texture, Vector2(size.x * 0.84, size.y * 0.26), Vector3(0.0, size.y * 0.10, size.z * 0.31), Color(0.94, 0.92, 0.86, 0.14))


func _build_billboard() -> void:
	var pole := Color(0.18, 0.19, 0.22, 0.92)
	_add_cylinder(0.09, size.y * 0.96, Vector3(-size.x * 0.20, 0.0, 0.0), pole, 0.7, 0.10)
	_add_cylinder(0.09, size.y * 0.96, Vector3(size.x * 0.20, 0.0, 0.0), pole, 0.7, 0.10)
	_add_box(Vector3(size.x * 0.84, size.y * 0.42, size.z * 0.12), Vector3(0.0, size.y * 0.18, 0.0), Color(0.92, 0.74, 0.18, 0.92), 0.42)
	_add_box(Vector3(size.x * 0.76, size.y * 0.30, size.z * 0.10), Vector3(0.0, size.y * 0.18, size.z * 0.01), Color(0.18, 0.28, 0.42, 0.92), 0.35)
	_add_box(Vector3(size.x * 0.56, size.y * 0.07, size.z * 0.11), Vector3(0.0, size.y * 0.23, size.z * 0.02), Color(0.96, 0.88, 0.55, 0.92), 0.28)
	_add_art_billboard(TEX_ENV_BILLBOARD, Vector2(size.x * 1.05, size.y * 0.88), Vector3(0.0, size.y * 0.22, size.z * 0.18))
	_add_surface_overlay(environment_grime_texture, Vector2(size.x * 0.78, size.y * 0.28), Vector3(0.0, size.y * 0.17, size.z * 0.08), Color(0.70, 0.66, 0.54, 0.14))
	_add_surface_overlay(environment_edge_texture, Vector2(size.x * 0.86, size.y * 0.34), Vector3(0.0, size.y * 0.18, size.z * 0.09), Color(0.98, 0.92, 0.82, 0.18))


func _build_hedge_cover() -> void:
	var planter_color := Color(0.24, 0.22, 0.18, 0.92)
	var leaf_dark := Color(0.20, 0.50, 0.22, 0.92)
	var leaf_light := Color(0.34, 0.68, 0.30, 0.90)
	var asym := lerpf(-1.0, 1.0, style_variant_seed)
	var top_bias := 0.82 + style_variant_seed * 0.24
	var left_height := 0.42 + maxf(0.0, -asym) * 0.18
	var right_height := 0.36 + maxf(0.0, asym) * 0.22
	_add_box(Vector3(size.x * 0.86, size.y * 0.22, size.z * 0.72), Vector3(0.0, -size.y * 0.32, 0.0), planter_color, 0.94)
	_add_box(Vector3(size.x * (0.38 + maxf(0.0, -asym) * 0.10), size.y * left_height, size.z * 0.72), Vector3(-size.x * 0.22, -size.y * 0.02, -size.z * 0.05), leaf_dark, 0.96)
	_add_box(Vector3(size.x * (0.42 + maxf(0.0, asym) * 0.12), size.y * right_height, size.z * 0.66), Vector3(size.x * 0.18, -size.y * 0.06, size.z * 0.06), leaf_dark.darkened(0.04), 0.96)
	_add_box(Vector3(size.x * top_bias, size.y * 0.26, size.z * 0.52), Vector3(size.x * asym * 0.06, size.y * 0.18, 0.02), leaf_light, 0.94, 0.0, leaf_light * 0.04)
	_add_box(Vector3(size.x * 0.18, size.y * (0.34 + maxf(0.0, -asym) * 0.16), size.z * 0.18), Vector3(-size.x * 0.30, size.y * 0.10, -size.z * 0.08), leaf_light.darkened(0.08), 0.96)
	_add_box(Vector3(size.x * 0.12, size.y * (0.28 + maxf(0.0, asym) * 0.18), size.z * 0.16), Vector3(size.x * 0.28, size.y * 0.04, size.z * 0.12), leaf_light.darkened(0.14), 0.96)
	_add_box(Vector3(size.x * 0.16, size.y * 0.18, size.z * 0.20), Vector3(0.0, size.y * 0.02, -size.z * 0.18), leaf_light.lightened(0.04), 0.96)


func _add_art_billboard(texture: Texture2D, art_size: Vector2, local_pos: Vector3, tint: Color = Color(1.0, 1.0, 1.0, 0.92)) -> void:
	if art_root == null or texture == null:
		return
	var art_mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = art_size
	art_mesh.mesh = quad
	art_mesh.position = local_pos
	art_mesh.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	art_mesh.material_override = material
	art_root.add_child(art_mesh)
	art_materials.append(material)


func _add_surface_overlay(texture: Texture2D, overlay_size: Vector2, local_pos: Vector3, tint: Color) -> void:
	if art_root == null or texture == null:
		return
	var overlay_mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = overlay_size
	overlay_mesh.mesh = quad
	overlay_mesh.position = local_pos
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	overlay_mesh.material_override = material
	art_root.add_child(overlay_mesh)
	art_materials.append(material)


func get_visual_asset_state() -> Dictionary:
	var texture_paths: Array[String] = []
	if art_root != null:
		for art_mesh in art_root.get_children():
			if art_mesh is MeshInstance3D and art_mesh.material_override is StandardMaterial3D:
				var texture: Texture2D = (art_mesh.material_override as StandardMaterial3D).albedo_texture
				if texture != null:
					texture_paths.append(texture.resource_path)
	var decal_textures: Array[String] = []
	if damage_root != null:
		for decal_mesh in damage_root.get_children():
			if decal_mesh is MeshInstance3D and decal_mesh.material_override is StandardMaterial3D:
				var decal_texture: Texture2D = (decal_mesh.material_override as StandardMaterial3D).albedo_texture
				if decal_texture != null:
					decal_textures.append(decal_texture.resource_path)
	return {
		"style_id": style_id,
		"asset_path": imported_asset_path,
		"destroyed": destroyed,
		"collapse_progress": collapse_progress,
		"post_destroy_hit_count": post_destroy_hit_count,
		"removal_started": removal_started,
		"blast_detached_count": _count_active_blast_parts(),
		"last_blast_detached_spawn_count": last_blast_detached_spawn_count,
		"last_blast_tier": last_blast_tier,
		"last_blast_effective_force": last_blast_effective_force,
		"last_blast_effect_kind": last_blast_effect_kind,
		"blast_reaction_count": blast_reaction_count,
		"decal_textures": decal_textures,
		"decal_count": damage_root.get_child_count() if damage_root != null else 0,
		"textures": texture_paths,
	}


func _ensure_decal_textures() -> void:
	if decal_bullet_hole_texture == null:
		decal_bullet_hole_texture = _load_svg_texture_runtime("res://assets_mvp_placeholder/decals/decal-bullet-hole-placeholder.svg")
		if decal_bullet_hole_texture == null:
			decal_bullet_hole_texture = _build_procedural_decal_texture("bullet_hole")
	if decal_cover_impact_texture == null:
		decal_cover_impact_texture = _load_svg_texture_runtime("res://assets_mvp_placeholder/decals/decal-cover-impact-mark-placeholder.svg")
		if decal_cover_impact_texture == null:
			decal_cover_impact_texture = _build_procedural_decal_texture("cover_impact")


func _ensure_surface_overlay_textures() -> void:
	if environment_grime_texture == null:
		environment_grime_texture = _load_svg_texture_runtime(TEX_ENV_GRIME_PATH)
	if environment_edge_texture == null:
		environment_edge_texture = _load_svg_texture_runtime(TEX_ENV_EDGE_WEAR_PATH)


func _load_svg_texture_runtime(svg_path: String) -> Texture2D:
	var svg_text := FileAccess.get_file_as_string(svg_path)
	if svg_text.is_empty():
		return null
	var image := Image.new()
	var err := image.load_svg_from_string(svg_text)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _build_procedural_decal_texture(kind: String) -> Texture2D:
	var size_px := 128
	var image := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(size_px * 0.5, size_px * 0.5)
	for y in range(size_px):
		for x in range(size_px):
			var pos := Vector2(x, y)
			var dist := pos.distance_to(center) / (size_px * 0.5)
			var color := Color(0.0, 0.0, 0.0, 0.0)
			if kind == "bullet_hole":
				if dist < 0.18:
					color = Color(0.0, 0.0, 0.0, 0.96)
				elif dist < 0.42:
					color = Color(0.05, 0.06, 0.08, lerpf(0.82, 0.0, (dist - 0.18) / 0.24))
			else:
				if dist < 0.10:
					color = Color(0.92, 0.96, 1.0, 0.88)
				elif dist < 0.56:
					color = Color(0.78, 0.84, 0.92, lerpf(0.52, 0.0, (dist - 0.10) / 0.46))
			if color.a > 0.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
