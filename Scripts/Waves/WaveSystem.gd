extends Node3D
class_name WaveSystem

## WaveSystem - Procedural multi-layer surf wave generation

signal wave_height_updated(x: float, z: float, height: float)
signal surface_normal_updated(x: float, z: float, normal: Vector3)
signal friction_updated(x: float, z: float, friction: float)

@export_group("Wave Layers")
@export var wave_layers: Array[Dictionary] = []
@export var auto_generate_waves: bool = true

@export_group("Base Settings")
@export var water_level: float = -5.0
@export var wave_amplitude: float = 2.0
@export var wave_frequency: float = 0.5
@export var wave_speed: float = 8.0
@export var wave_direction: Vector2 = Vector2.RIGHT
@export var wave_length: float = 100.0

@export_group("Friction Map")
@export var friction_map: Array[Dictionary] = []
@export var default_friction: float = 1.0

var wave_time: float = 0.0
var friction_cache: Dictionary = {}
var last_query_position: Vector3 = Vector3.ZERO
var last_cache_time: int = 0

func _ready() -> void:
	add_to_group("wave_system")
	if auto_generate_waves and wave_layers.is_empty():
		generate_wave_layers()

func _process(delta: float) -> void:
	wave_time += delta
	if Time.get_ticks_msec() - last_cache_time > 500:
		last_cache_time = Time.get_ticks_msec()

func generate_wave_layers() -> void:
	var layers: Array[Dictionary] = []
	var base_freq := wave_frequency
	var base_amp := wave_amplitude
	
	for i in range(4):
		var layer: Dictionary = {
			"height": base_amp * (1.0 / (i + 1)),
			"length": wave_length * (i + 1),
			"frequency": base_freq * (i + 1),
			"direction": Vector2(cos(deg_to_rad(i * 90)), sin(deg_to_rad(i * 90))),
			"speed": wave_speed * (i + 1)
		}
		layers.append(layer)
	
	wave_layers = layers

func get_wave_height(x: float, z: float) -> float:
	var total_height: float = water_level
	var total_normal: Vector3 = Vector3.UP
	var total_friction: float = default_friction
	
	for layer in wave_layers:
		var layer_dir: Vector2 = layer["direction"].normalized()
		var wave_number: float = 2.0 * PI / layer["length"]
		var angular_frequency: float = 2.0 * PI * layer["frequency"]
		var pos_dot: float = Vector2(x, z).dot(layer_dir)
		var phase: float = wave_number * pos_dot - angular_frequency * wave_time
		var layer_height: float = layer["height"] * 0.5 * cos(phase)
		total_height += layer_height
		
		var gradient_height: float = layer["height"] * 0.5 * -sin(phase)
		var surface_normal: Vector3 = Vector3.UP - layer_dir * gradient_height
		total_normal = Vector3(total_normal.x, total_normal.y, total_normal.z + surface_normal.z)
		total_normal = total_normal.normalized()
		
		var depth: float = total_height - (z - water_level)
		if depth > 0:
			total_friction = min(total_friction, 1.0)
	
	total_normal = total_normal.normalized()
	last_query_position = Vector3(x, z, 0)
	
	wave_height_updated.emit(x, z, total_height)
	surface_normal_updated.emit(x, z, total_normal)
	friction_updated.emit(x, z, total_friction)
	
	return total_height

func get_surface_normal(x: float, z: float) -> Vector3:
	var wave_normal: Vector3 = Vector3.UP
	
	for layer in wave_layers:
		var layer_dir: Vector2 = layer["direction"].normalized()
		var wave_number: float = 2.0 * PI / layer["length"]
		var angular_frequency: float = 2.0 * PI * layer["frequency"]
		var phase: float = wave_number * Vector2(x, z).dot(layer_dir) - angular_frequency * wave_time
		var gradient: float = layer["height"] * 0.5 * -sin(phase)
		wave_normal.x += layer_dir.x * gradient
		wave_normal.z += gradient
	
	return wave_normal.normalized()

func get_friction_at(x: float, z: float) -> float:
	var pos_key := "%.1f,%.1f" % [x, z]  # Round to reduce cache misses

	if pos_key in friction_cache:
		return friction_cache[pos_key]

	var wave_height: float = get_wave_height(x, z)
	var depth: float = global_position.y - wave_height  # Depth = player_y - wave_height

	var friction: float = default_friction
	if depth > 0:  # Underwater
		# Higher friction when deeper underwater
		friction = clamp(default_friction + depth * 0.01, 0.5, 2.0)
	else:  # Above water
		# Less friction when above water (air resistance)
		friction = default_friction * 0.8

	friction_cache[pos_key] = friction
	return friction

func reset() -> void:
	wave_time = 0.0
	friction_cache.clear()
	last_query_position = Vector3.ZERO

func get_wave_info() -> Dictionary:
	return {
		"layers_count": wave_layers.size(),
		"wave_time": wave_time,
		"water_level": water_level,
		"amplitude": wave_amplitude,
		"frequency": wave_frequency,
		"speed": wave_speed,
		"cache_size": friction_cache.size()
	}


func set_wave_info(info: Dictionary) -> void:
	wave_time = info.get("wave_time", 0.0)
	wave_layers = []  # Reset and regenerate if needed
	if info.has("layers_count") and info["layers_count"] > 0:
		generate_wave_layers()
	friction_cache.clear()

func get_visualization_data() -> Array:
	var data: Array = []
	for i in range(100):
		var x := float(i) * 10.0
		var z := float(i) * 10.0
		data.append({
			"pos": Vector3(x, z, 0),
			"height": get_wave_height(x, z) - water_level,
			"normal": get_surface_normal(x, z),
			"friction": get_friction_at(x, z)
		})
	return data
