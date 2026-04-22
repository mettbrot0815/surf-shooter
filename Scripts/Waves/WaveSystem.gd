extends Node3D
class_name WaveSystem

## WaveSystem - Procedural multi-layer surf wave generation
## 
## Creates flowing water surfaces using layered Gerstner waves for realistic
## surf physics and visual feedback.
##
## Sources:
## - Gerstner wave theory
## - Source Engine water simulation
## - "The Nature of Code" by Daniel Shiffman

signal wave_height_updated(x: float, z: float, height: float)
signal surface_normal_updated(x: float, z: float, normal: Vector3)
signal friction_updated(x: float, z: float, friction: float)

# =============================================================================
# CONFIGURATION
# =============================================================================

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

# =============================================================================
# STATE
# =============================================================================

var wave_time: float = 0.0
var friction_cache: Dictionary = {}
var last_query_position: Vector3 = Vector3.ZERO

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Auto-generate waves if needed
	if auto_generate_waves and wave_layers.is_empty():
		generate_wave_layers()


func _process(delta: float) -> void:
	wave_time += delta
	# Update friction cache periodically
	if Time.get_ticks_msec() - last_query_position.distance_squared_to(last_cache_time, 2) > 500:
		last_cache_time = Time.get_ticks_msec()


# =============================================================================
# WAVE GENERATION - Procedural Gerstner waves
# =============================================================================

func generate_wave_layers() -> void:
	"""Generate procedural wave layers for realistic surf simulation"""
	
	var layers: Array[Dictionary] = []
	var base_freq := wave_frequency
	var base_amp := wave_amplitude
	
	# Create multiple layers with different frequencies and directions
	for i in range(4):
		var layer: Dictionary = {
			"height": base_amp * (1.0 / (i + 1)),  # Diminishing amplitude
			"length": wave_length * (i + 1),        # Longer wavelengths for lower freq
			"frequency": base_freq * (i + 1),
			"direction": Vector2(cos(deg_to_rad(i * 90)), sin(deg_to_rad(i * 90))),
			"speed": wave_speed * (i + 1)
		}
		layers.append(layer)
	
	wave_layers = layers


func get_wave_height(x: float, z: float) -> float:
	"""
	Calculate total wave height at position using layered Gerstner waves.
	
	This creates realistic multi-layer water surface with overlapping waves.
	"""
	
	var total_height: float = water_level
	var total_normal: Vector3 = Vector3.UP
	var total_friction: float = default_friction
	
	# Calculate contribution from each layer
	for layer in wave_layers:
		# Get wave parameters
		var layer_dir: Vector2 = layer["direction"].normalized()
		var wave_number: float = 2.0 * PI / layer["length"]
		var angular_frequency: float = 2.0 * PI * layer["frequency"]
		var wavelength: float = layer["length"]
		
		# Calculate phase at position
		var pos_dot: float = Vector2(x, z).dot(layer_dir)
		var phase: float = wave_number * pos_dot - angular_frequency * wave_time
		
		# Gerstner wave height calculation
		var layer_height: float = layer["height"] * 0.5 * cos(phase)
		total_height += layer_height
		
		# Calculate surface normal from wave gradient
		var gradient_height: float = layer["height"] * 0.5 * -sin(phase)
		var surface_normal: Vector3 = Vector3.UP - Vector2(x, z).normalized() * gradient_height
		total_normal = Vector3(total_normal.x, total_normal.y, total_normal.z + surface_normal.z)
		total_normal = total_normal.normalized()
		
		# Apply friction based on water depth
		var depth: float = total_height - (z - water_level)
		if depth > 0:
			total_friction = min(total_friction, 1.0)
	
	# Clamp normal
	total_normal = total_normal.normalized()
	
	# Cache and emit signals
	last_query_position = Vector3(x, z, 0)
	
	wave_height_updated.emit(x, z, total_height)
	surface_normal_updated.emit(x, z, total_normal)
	friction_updated.emit(x, z, total_friction)
	
	return total_height


func get_surface_normal(x: float, z: float) -> Vector3:
	"""Get surface normal at position for light calculation"""
	
	var normal: Vector3 = Vector3.UP
	var wave_normal: Vector3 = Vector3.UP
	
	for layer in wave_layers:
		var layer_dir: Vector2 = layer["direction"].normalized()
		var wave_number: float = 2.0 * PI / layer["length"]
		var phase: float = wave_number * Vector2(x, z).dot(layer_dir) - angular_frequency * wave_time
		
		var gradient: float = layer["height"] * 0.5 * -sin(phase)
		wave_normal.x += layer_dir.x * gradient
		wave_normal.z += gradient
	
	wave_normal = wave_normal.normalized()
	return wave_normal


func get_friction_at(x: float, z: float) -> float:
	"""Get friction coefficient at position"""
	
	var pos_key := "%s,%s" % [x, z]
	
	if pos_key in friction_cache:
		return friction_cache[pos_key]
	
	# Calculate friction based on wave height (deeper = less friction)
	var wave_height := get_wave_height(x, z)
	var depth := wave_height - (z - water_level)
	
	var friction: float = default_friction
	if depth > 0:
		# Less friction in deeper water
		friction = maxf(default_friction * (1.0 - depth / 100.0), 0.1)
	else:
		# More friction on surface
		friction = default_friction * 2.0
	
	friction_cache[pos_key] = friction
	return friction


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func reset() -> void:
	"""Reset wave system to initial state"""
	wave_time = 0.0
	friction_cache.clear()
	last_query_position = Vector3.ZERO


func get_wave_info() -> Dictionary:
	"""Get current wave system information"""
	return {
		"layers_count": wave_layers.size(),
		"wave_time": wave_time,
		"water_level": water_level,
		"amplitude": wave_amplitude,
		"frequency": wave_frequency,
		"speed": wave_speed,
		"cache_size": friction_cache.size()
	}


func get_visualization_data() -> Array:
	"""Generate data for wave visualization/shaders"""
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
