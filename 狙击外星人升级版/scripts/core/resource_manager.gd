extends Node

class_name ResourceManager

var _loaded_resources: Dictionary = {}
var _loading_tasks: Dictionary = {}
var _cache_size_limit: int = 64
var _cache: Dictionary = {}


func _ready() -> void:
	_loaded_resources.clear()
	_loading_tasks.clear()
	_cache.clear()


func load_resource(path: String, on_loaded: Callable = Callable(), priority: int = 1) -> Resource:
	if _loaded_resources.has(path):
		if on_loaded.is_valid():
			call_deferred("._call_callback", on_loaded, _loaded_resources[path], "")
		return _loaded_resources[path]

	if _loading_tasks.has(path):
		if on_loaded.is_valid():
			_loading_tasks[path].append(on_loaded)
		return null

	_loading_tasks[path] = []
	if on_loaded.is_valid():
		_loading_tasks[path].append(on_loaded)

	var loader := ResourceLoader.load_threaded_request(path, "", false, priority)
	if loader == OK:
		var resource: Resource = ResourceLoader.load_threaded_get(path)
		if resource != null:
			_loaded_resources[path] = resource
			_cache_resource(path, resource)

			for callback in _loading_tasks.get(path, []):
				call_deferred("._call_callback", callback, resource, "")
			_loading_tasks.erase(path)

			return resource
		else:
			var err_msg: String = "Failed to load resource: %s" % path
			push_error(err_msg)

			for callback in _loading_tasks.get(path, []):
				call_deferred("._call_callback", callback, null, err_msg)
			_loading_tasks.erase(path)

			return null
	else:
		var err_msg: String = "Failed to load resource: %s" % path
		push_error(err_msg)

		for callback in _loading_tasks.get(path, []):
			call_deferred("._call_callback", callback, null, err_msg)
		_loading_tasks.erase(path)

		return null


func load_resource_async(path: String, on_loaded: Callable) -> void:
	if _loaded_resources.has(path):
		call_deferred("._call_callback", on_loaded, _loaded_resources[path], "")
		return

	if _loading_tasks.has(path):
		_loading_tasks[path].append(on_loaded)
		return

	_loading_tasks[path] = [on_loaded]

	var loader_err := ResourceLoader.load_threaded_request(path, "", false)
	if loader_err != OK:
		var err_msg: String = "Failed to start async load: %s" % path
		push_error(err_msg)
		call_deferred("._call_callback", on_loaded, null, err_msg)
		_loading_tasks.erase(path)
		return


func unload_resource(path: String) -> void:
	if _loaded_resources.has(path):
		_resource_unref(_loaded_resources[path])
		_loaded_resources.erase(path)
		_cache.erase(path)


func clear_cache() -> void:
	for path in _cache.keys():
		if _loaded_resources.has(path):
			_resource_unref(_loaded_resources[path])
			_loaded_resources.erase(path)
	_cache.clear()


func get_loaded_count() -> int:
	return _loaded_resources.size()


func is_loading(path: String) -> bool:
	return _loading_tasks.has(path)


func _process(_delta: float) -> void:
	var completed_paths: Array[String] = []
	for path in _loading_tasks.keys():
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			completed_paths.append(path)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			completed_paths.append(path)

	for path in completed_paths:
		var resource: Resource = ResourceLoader.load_threaded_get(path)
		var callbacks: Array = _loading_tasks.get(path, [])
		if resource != null:
			_loaded_resources[path] = resource
			_cache_resource(path, resource)
			for callback in callbacks:
				_call_callback(callback, resource, "")
		else:
			var err_msg: String = "Async load failed: %s" % path
			push_error(err_msg)
			for callback in callbacks:
				_call_callback(callback, null, err_msg)
		_loading_tasks.erase(path)


func _cache_resource(path: String, resource: Resource) -> void:
	if _cache.size() >= _cache_size_limit and _cache.size() > 0:
		var oldest_path: String = String(_cache.keys()[0])
		_cache.erase(oldest_path)

	_cache[path] = {
		"resource": resource,
		"accessed_at": Time.get_ticks_msec(),
		"access_count": 1,
	}


func _call_callback(callback: Callable, resource: Resource, error: String) -> void:
	if not callback.is_valid():
		return

	if error != "":
		callback.call(resource, error)
	else:
		callback.call(resource, "")


func _resource_unref(resource: Resource) -> void:
	if resource == null:
		return

	if resource is PackedScene:
		for child in resource.get_children():
			_resource_unref(child)

	if resource.has_method("free"):
		resource.free()
