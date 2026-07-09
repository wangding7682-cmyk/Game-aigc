extends RefCounted
class_name WeaponPreviewCatalog

const PREVIEW_DEFAULT_PATH := "res://assets_mvp_placeholder/weapons/preview/weapon-preview-default.svg"
const PREVIEW_PRECISION_PATH := "res://assets_mvp_placeholder/weapons/preview/weapon-preview-precision.svg"
const PREVIEW_AUTO_PATH := "res://assets_mvp_placeholder/weapons/preview/weapon-preview-auto.svg"
const PREVIEW_PLASMA_PATH := "res://assets_mvp_placeholder/weapons/preview/weapon-preview-plasma.svg"

static var _texture_cache: Dictionary = {}


static func get_weapon_preview(weapon_id: String) -> Texture2D:
	match weapon_id:
		"precision_sniper":
			return _load_texture(PREVIEW_PRECISION_PATH)
		"auto_sniper":
			return _load_texture(PREVIEW_AUTO_PATH)
		"plasma_sniper":
			return _load_texture(PREVIEW_PLASMA_PATH)
		_:
			return _load_texture(PREVIEW_DEFAULT_PATH)


static func get_weapon_preview_by_geometry(geometry_type: String) -> Texture2D:
	match geometry_type:
		"precision":
			return _load_texture(PREVIEW_PRECISION_PATH)
		"auto":
			return _load_texture(PREVIEW_AUTO_PATH)
		"plasma":
			return _load_texture(PREVIEW_PLASMA_PATH)
		_:
			return _load_texture(PREVIEW_DEFAULT_PATH)


static func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]

	var texture: Texture2D = null
	if path.get_extension().to_lower() == "svg":
		texture = _load_svg_texture(path)
	else:
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)

	if texture == null and path.get_extension().to_lower() == "svg":
		var fallback_png := "%s.png" % path.trim_suffix(".svg")
		var fallback_image := Image.load_from_file(fallback_png)
		if fallback_image != null and not fallback_image.is_empty():
			texture = ImageTexture.create_from_image(fallback_image)

	if texture == null:
		return null

	_texture_cache[path] = texture
	return texture


static func _load_svg_texture(path: String) -> Texture2D:
	var svg_text := FileAccess.get_file_as_string(path)
	if svg_text.is_empty():
		return null
	var image := Image.new()
	var err := image.load_svg_from_string(svg_text)
	if err != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
