extends StaticBody3D
class_name PveFoliageProp3D

var style_id: String = "patch"
var size: Vector3 = Vector3(0.8, 0.4, 0.5)
var destroyed := false

var collider: CollisionShape3D
var mesh_root: Node3D
var debris_root: Node3D
var materials: Array[StandardMaterial3D] = []


func setup(prop_style: String, prop_size: Vector3, palette: Dictionary) -> void:
	style_id = prop_style
	size = prop_size
	_build(palette)


func apply_shot_hit(hit_point: Vector3, hit_normal: Vector3) -> void:
	if destroyed:
		return
	destroyed = true
	if collider != null and is_instance_valid(collider):
		collider.disabled = true
	_build_hit_burst(to_local(hit_point), hit_normal)
	_fade_and_remove()


func _build(palette: Dictionary) -> void:
	mesh_root = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)

	debris_root = Node3D.new()
	debris_root.name = "DebrisRoot"
	add_child(debris_root)

	collider = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(size.x, 0.18), maxf(size.y, 0.18), maxf(size.z, 0.18))
	collider.shape = shape
	add_child(collider)

	collision_layer = 1
	collision_mask = 0

	match style_id:
		"planter":
			_build_planter(palette)
		"shrub":
			_build_shrub(palette)
		_:
			_build_patch(palette)


func _build_patch(palette: Dictionary) -> void:
	_add_box(Vector3(size.x, 0.03, size.z), Vector3(0.0, 0.015, 0.0), palette.get("soil_bed", Color(0.22, 0.18, 0.12)), 0.98)
	for idx in range(5):
		_add_sphere(
			0.06 + float(idx % 2) * 0.02,
			Vector3(-size.x * 0.28 + idx * size.x * 0.14, 0.08 + float(idx % 3) * 0.02, -size.z * 0.18 + float(idx % 2) * 0.10),
			palette.get("grass_light", Color(0.38, 0.82, 0.36)),
			0.92,
			palette.get("grass_light", Color(0.38, 0.82, 0.36)) * 0.04
		)
	for idx in range(5):
		var bloom_color: Color = palette.get("flower_b", Color(1.0, 0.88, 0.30)) if idx % 2 == 0 else palette.get("flower_c", Color(0.20, 0.90, 0.96))
		_add_sphere(
			0.035,
			Vector3(-size.x * 0.30 + idx * size.x * 0.15, 0.15 + float(idx % 2) * 0.03, size.z * 0.10 - float(idx % 3) * 0.08),
			bloom_color,
			0.24,
			bloom_color * 0.18
		)


func _build_shrub(palette: Dictionary) -> void:
	for idx in range(3):
		_add_sphere(
			0.12 + idx * 0.03,
			Vector3(-size.x * 0.18 + idx * size.x * 0.18, 0.12 + idx * 0.02, -0.02 + idx * 0.04),
			palette.get("grass_main", Color(0.24, 0.72, 0.34)),
			0.84,
			palette.get("grass_main", Color(0.24, 0.72, 0.34)) * 0.06
		)
	for idx in range(3):
		var stem_color: Color = palette.get("flower_a", Color(1.0, 0.48, 0.26)) if idx % 2 == 0 else palette.get("flower_b", Color(1.0, 0.88, 0.30))
		_add_cylinder(
			0.025,
			0.18 + float(idx % 2) * 0.04,
			Vector3(-size.x * 0.10 + idx * size.x * 0.10, 0.20, size.z * 0.10 - idx * 0.06),
			stem_color,
			0.24,
			stem_color * 0.18
		)


func _build_planter(palette: Dictionary) -> void:
	_add_box(Vector3(size.x, size.y * 0.42, size.z), Vector3(0.0, size.y * 0.21, 0.0), palette.get("planter_box", Color(0.24, 0.28, 0.30)), 0.90)
	for idx in range(2):
		_add_sphere(
			0.12 + idx * 0.02,
			Vector3(-size.x * 0.12 + idx * size.x * 0.24, size.y * 0.44 + idx * 0.02, 0.0),
			palette.get("grass_main", Color(0.24, 0.72, 0.34)),
			0.84,
			palette.get("grass_main", Color(0.24, 0.72, 0.34)) * 0.05
		)


func _add_box(box_size: Vector3, local_pos: Vector3, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.position = local_pos
	mi.material_override = _make_material(color, roughness, emission)
	mesh_root.add_child(mi)


func _add_sphere(radius: float, local_pos: Vector3, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> void:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	mi.position = local_pos
	mi.material_override = _make_material(color, roughness, emission)
	mesh_root.add_child(mi)


func _add_cylinder(radius: float, height: float, local_pos: Vector3, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = local_pos
	mi.material_override = _make_material(color, roughness, emission)
	mesh_root.add_child(mi)


func _make_material(color: Color, roughness: float = 0.9, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
	materials.append(mat)
	return mat


func _build_hit_burst(local_hit: Vector3, hit_normal: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var burst_count: int = 6 if style_id == "patch" else 8
	for idx in range(burst_count):
		var debris := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		var radius := rng.randf_range(0.03, 0.09)
		mesh.radius = radius
		mesh.height = radius * 2.0
		debris.mesh = mesh
		debris.position = local_hit + Vector3(rng.randf_range(-0.08, 0.08), rng.randf_range(0.02, 0.18), rng.randf_range(-0.08, 0.08))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.36, 0.84, 0.42, 0.88) if idx % 2 == 0 else Color(1.0, 0.82, 0.28, 0.86)
		mat.roughness = 0.82
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debris.material_override = mat
		var scatter_dir := (hit_normal + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.2, 0.8), rng.randf_range(-0.6, 0.6))).normalized()
		debris.set_meta("vel", scatter_dir * rng.randf_range(0.8, 1.8))
		debris.set_meta("ang_vel", Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0), rng.randf_range(-6.0, 6.0)))
		debris.set_meta("life", 0.38 + rng.randf_range(0.0, 0.18))
		debris_root.add_child(debris)


func _fade_and_remove() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	if mesh_root != null and is_instance_valid(mesh_root):
		tween.tween_property(mesh_root, "scale", Vector3(1.0, 0.05, 1.0), 0.24).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	for mat in materials:
		if mat != null:
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.22).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)


func _process(delta: float) -> void:
	if debris_root == null or not is_instance_valid(debris_root):
		return
	var to_remove: Array[Node] = []
	for child in debris_root.get_children():
		if child is MeshInstance3D and child.has_meta("vel"):
			var mi := child as MeshInstance3D
			var vel: Vector3 = mi.get_meta("vel")
			var ang_vel: Vector3 = mi.get_meta("ang_vel")
			vel.y -= 7.6 * delta
			mi.position += vel * delta
			mi.rotate(Vector3.RIGHT, ang_vel.x * delta)
			mi.rotate(Vector3.UP, ang_vel.y * delta)
			mi.rotate(Vector3.FORWARD, ang_vel.z * delta)
			var life: float = float(mi.get_meta("life")) - delta
			mi.set_meta("life", life)
			if mi.material_override is StandardMaterial3D:
				var mat := mi.material_override as StandardMaterial3D
				mat.albedo_color.a = maxf(life * 1.4, 0.0)
			if life <= 0.0 or mi.position.y < -0.2:
				to_remove.append(mi)
			mi.set_meta("vel", vel)
	for node in to_remove:
		node.queue_free()
