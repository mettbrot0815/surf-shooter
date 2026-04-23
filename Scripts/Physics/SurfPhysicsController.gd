extends CharacterBody3D
class_name SurfPhysicsController

## SurfPhysicsController - CS:GO-style surfing physics for Godot 4.3+

signal velocity_changed(new_velocity: Vector3)
signal surf_state_changed(in_water: bool, on_ramp: bool)
signal speed_updated(speed: float)

@export_group("Movement Settings")
@export var max_speed: float = 320.0
@export var max_air_speed: float = 350.0
@export var sprint_speed: float = 400.0
@export var jump_force: float = 290.0

@export_group("Acceleration (Source Values)")
@export var ground_acceleration: float = 4000.0
@export var air_acceleration: float = 1500.0
@export var air_acceleration_dir_factor: float = 1.0

@export_group("Friction (Source Values)")
@export var ground_friction: float = 6.0
@export var air_resistance: float = 0.0
@export var water_friction: float = 4.0
@export var stop_speed: float = 100.0

@export_group("Surf Physics")
@export var surf_acceleration: float = 2500.0
@export var surf_max_velocity: float = 6000.0
@export var ramp_deflection_strength: float = 1.0
@export var min_ramp_angle: float = 10.0
@export var max_ramp_angle: float = 60.0
@export var ramp_speed_retention: float = 0.1
@export var ramp_boost_factor: float = 0.8
@export var water_surface_threshold: float = 50.0

@export_group("Debug")
@export var show_debug_overlay: bool = false
@export var log_movement: bool = false

var _current_speed: float = 0.0
var _wish_speed: float = 0.0
var _wish_direction: Vector3 = Vector3.ZERO
var _ground_normal: Vector3 = Vector3.UP
var _is_on_ground: bool = false
var _is_on_ramp: bool = false
var _is_in_water: bool = false
var _last_ground_collider: Node3D = null
var _surface_friction: float = 1.0

@export var _wave_system: WaveSystem = null

var _ramp_surface_normal: Vector3 = Vector3.ZERO
var _ramp_detection_ray_length: float = 50.0

var _peak_speed: float = 0.0
var _total_distance_traveled: float = 0.0
var _last_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("players")
	_last_position = global_position

	# Physics handled directly in _physics_process at 300Hz

	# Connect to timer for practice mode
	var timer = SpeedrunTimer
	if timer:
		timer.enable_practice_mode()  # Enable by default for testing


func _physics_process(delta: float) -> void:
	_fixed_physics_update(delta)
	_process(delta)  # Process shake effects


func _fixed_physics_update(_delta: float) -> void:
	_update_wish_direction()
	_check_surface_state()
	
	if _is_in_water or _is_on_ramp:
		_apply_surf_movement(_delta)
	elif _is_on_ground:
		_apply_ground_movement(_delta)
	else:
		_apply_air_movement(_delta)
	
	_apply_friction(_delta)
	_handle_jump()
	
	var collision := move_and_slide()
	_update_state_tracking()
	_emit_signals()


func _update_wish_direction() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var camera := get_viewport().get_camera_3d()
	if camera:
		var forward := camera.global_transform.basis.z
		var right := camera.global_transform.basis.x

		# Camera-relative movement
		_wish_direction = (right * input_dir.x - forward * input_dir.y)
		_wish_direction = Vector3(_wish_direction.x, 0, _wish_direction.z).normalized()

		# In air, allow full 3D wish direction relative to camera
		if not _is_on_ground and not _is_on_ramp:
			var up := camera.global_transform.basis.y
			var vertical_input := Input.get_axis("move_forward", "move_backward") * 0.5  # Reduced vertical influence
			_wish_direction += up * vertical_input
			_wish_direction = _wish_direction.normalized()
	else:
		_wish_direction = Vector3(input_dir.x, 0, -input_dir.y).normalized()

	var current_max := max_speed
	if Input.is_action_pressed("sprint"):
		current_max = sprint_speed

	_wish_speed = _wish_direction.length() * current_max


func _check_surface_state() -> void:
	var was_on_ground := _is_on_ground
	var was_on_ramp := _is_on_ramp
	_is_on_ground = is_on_floor()
	_is_on_ramp = false
	_is_in_water = false
	
	if is_on_floor():
		_ground_normal = get_floor_normal()
		
		var angle := rad_to_deg(acos(_ground_normal.dot(Vector3.UP)))
		if angle > min_ramp_angle:
			_is_on_ramp = true
			_ramp_surface_normal = _ground_normal
			surf_state_changed.emit(_is_in_water, _is_on_ramp)
		elif was_on_ground and not _is_on_ramp:
			surf_state_changed.emit(_is_in_water, _is_on_ramp)
		elif was_on_ramp and not _is_on_ramp:
			surf_state_changed.emit(_is_in_water, _is_on_ramp)
	else:
		_check_water_surface()
	
	# Reset friction based on surface type
	if _is_on_ground:
		_surface_friction = ground_friction * 0.5  # Reduced ground friction for better feel
	elif _is_on_ramp:
		_surface_friction = 0.3  # Very low friction on ramps for speed
	else:
		_surface_friction = 1.0


func _check_water_surface() -> void:
	var wave_system = get_tree().get_first_node_in_group("wave_system")
	var surface_normal = Vector3.UP
	var wave_height = water_level
	
	if wave_system:
		var water_height := wave_system.get_wave_height(global_position.x, global_position.z)
		var depth := global_position.y - water_height
		
		if depth <= water_surface_threshold:  # Player is at or below water surface
			_is_in_water = true
			_ground_normal = wave_system.get_surface_normal(global_position.x, global_position.z)
			# Dynamic friction based on depth
			var friction = wave_system.get_friction_at(global_position.x, global_position.z)
			_surface_friction = friction
			surf_state_changed.emit(_is_in_water, _is_on_ramp)
		else:
			# Get surface normal from nearest wave for smooth transition
			var nearest_normal = wave_system.get_surface_normal(global_position.x, global_position.z)
			# Blend with UP for smoother water surface
			var blend_factor = clamp(1.0 - depth / water_surface_threshold * 2.0, 0.0, 1.0)
			_ground_normal = (nearest_normal * blend_factor + Vector3.UP * (1.0 - blend_factor)).normalized()
			surface_normal = _ground_normal
			_is_in_water = false
			_is_on_ramp = false
			surf_state_changed.emit(_is_in_water, _is_on_ramp)
	else:
		_ground_normal = Vector3.UP
		surface_normal = Vector3.UP


func _apply_ground_movement(delta: float) -> void:
	if _wish_direction == Vector3.ZERO:
		return
	
	var wish_speed := min(_wish_speed, max_speed)
	var add_speed := wish_speed - _current_speed
	
	if add_speed <= 0:
		return
	
	var accel_speed := ground_acceleration * _surface_friction * delta
	accel_speed = min(accel_speed, add_speed)
	
	velocity += _wish_direction * accel_speed
	
	if log_movement:
		print("Ground move: wish=%s speed=%.1f accel=%.1f" % [_wish_direction, wish_speed, accel_speed])


func _apply_air_movement(delta: float) -> void:
	if _wish_direction == Vector3.ZERO:
		return
	
	var current_speed_in_wish := velocity.dot(_wish_direction)
	var add_speed := _wish_speed - current_speed_in_wish
	
	if add_speed <= 0:
		return
	
	var accel_speed := air_acceleration * delta * air_acceleration_dir_factor
	accel_speed = min(accel_speed, add_speed)
	
	velocity += _wish_direction * accel_speed
	
	if velocity.length() > max_air_speed:
		velocity = velocity.normalized() * max_air_speed
	
	if log_movement:
		print("Air move: wish=%s current=%.1f add=%.1f" % [_wish_direction, current_speed_in_wish, add_speed])


func _apply_surf_movement(delta: float) -> void:
	var surface_normal: Vector3
	if _is_on_ramp:
		surface_normal = _ramp_surface_normal
	else:
		surface_normal = _ground_normal
	
	# CS:GO style surf physics
	# Deflect velocity along the surface normal
	var velocity_dot_normal := velocity.dot(surface_normal)
	
	# Only deflect if moving towards the surface
	if velocity_dot_normal < 0:
		# Calculate deflection: reflect velocity off surface
		var deflection := velocity - 2 * velocity_dot_normal * surface_normal
		# Apply some friction/energy loss
		var deflection_strength := 0.98  # Slight energy loss
		velocity = deflection * deflection_strength
	
	# Calculate surf direction (perpendicular component)
	var velocity_parallel := velocity - velocity.dot(surface_normal) * surface_normal
	var surf_direction := velocity_parallel.cross(surface_normal).cross(surface_normal).normalized()
	
	# If no perpendicular component, use wish direction projected onto surface
	if surf_direction == Vector3.ZERO or surf_direction.length() < 0.1:
		surf_direction = (_wish_direction - _wish_direction.dot(surface_normal) * surface_normal).normalized()
		if surf_direction == Vector3.ZERO:
			return
	
	var current_speed := velocity.length()
	var add_speed := surf_acceleration * delta
	
	# Apply acceleration in surf direction
	velocity += surf_direction * add_speed
	
	# Ramp speed gain based on angle
	if _is_on_ramp:
		var ramp_angle := acos(surface_normal.dot(Vector3.UP))
		var angle_factor := clamp(ramp_angle / deg_to_rad(max_ramp_angle), 0.0, 1.0)
		
		# Optimal ramp surfing gives speed boost
		if angle_factor > 0.3:  # Sweet spot angles
			var speed_boost := current_speed * angle_factor * ramp_boost_factor * delta
			velocity += surf_direction * speed_boost
		
		# Speed retention for high speeds
		if current_speed > 200.0:
			var retention := min(current_speed * ramp_speed_retention * delta, current_speed * 0.1)
			velocity += velocity_parallel.normalized() * retention
	
	var new_speed := velocity.length()
	if new_speed > surf_max_velocity:
		velocity = velocity.normalized() * surf_max_velocity
	
_current_speed = velocity.length()

	# Play surf whoosh for high-speed surfing
	if _current_speed > 200:
		_play_surf_whoosh()
		# Add subtle shake for high-speed surfing
		if _current_speed > 300:
			_apply_shake(0.1, _current_speed / 600.0)

	# Log surf physics info for debugging
	if log_movement:
		print("Surf: speed=%.1f normal=%s angle=%.1f deflection=%.3f" % [_current_speed, surface_normal, rad_to_deg(acos(surface_normal.dot(Vector3.UP))), velocity_dot_normal])


func _apply_friction(delta: float) -> void:
	if _wish_direction.length() > 0 and _is_on_ground:
		return
	
	var speed := velocity.length()
	if speed < 0.001:
		velocity = Vector3.ZERO
		return
	
	var friction := 0.0
	if _is_in_water:
		friction = water_friction
	elif _is_on_ground:
		friction = ground_friction
	else:
		friction = air_resistance
	
	var effective_friction := friction
	if speed < stop_speed:
		effective_friction = friction * (speed / stop_speed)
	
	var drop := 0.0
	if _is_on_ground:
		drop = friction * _surface_friction * delta * speed
	else:
		drop = friction * delta * speed
	
	drop = maxf(drop, 0.0)
	var new_speed := maxf(speed - drop, 0.0)
	
	if new_speed != speed:
		velocity = velocity.normalized() * new_speed


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and (_is_on_ground or _is_on_ramp):
		velocity.y = jump_force
		# Audio placeholder - play jump sound
		_play_jump_sound()
		# Visual feedback - screen shake
		_apply_shake(0.5, 0.1)
		# Add jump particle effect
		_spawn_jump_particles()


func _update_state_tracking() -> void:
	_current_speed = velocity.length()
	
	if _current_speed > _peak_speed:
		_peak_speed = _current_speed
	
	var movement := global_position - _last_position
	_total_distance_traveled += movement.length()
	_last_position = global_position


func _emit_signals() -> void:
	velocity_changed.emit(velocity)
	speed_updated.emit(_current_speed)


func get_physics_state() -> Dictionary:
	return {
		"position": global_position,
		"rotation": rotation,
		"velocity": velocity,
		"is_on_ground": _is_on_ground,
		"is_on_ramp": _is_on_ramp,
		"is_in_water": _is_in_water,
		"ground_normal": _ground_normal,
		"current_speed": _current_speed,
		"wish_direction": _wish_direction,
		"wish_speed": _wish_speed,
		# Audio/Visual feedback status
		"shaking": shake_data is not null and shake_data.get("intensity", 0) > 0,
		"shaking_intensity": shake_data.get("intensity", 0) if shake_data else 0,
		"surfx_whooshing": _current_speed > 200
	}


func apply_state(state: Dictionary) -> void:
	global_position = state.get("position", global_position)
	rotation = state.get("rotation", rotation)
	velocity = state.get("velocity", velocity)


func get_peak_speed() -> float:
	return _peak_speed


func get_total_distance() -> float:
	return _total_distance_traveled


func reset_position(new_position: Vector3) -> void:
	global_position = new_position
	velocity = Vector3.ZERO
	_current_speed = 0.0
	_peak_speed = 0.0
	_total_distance_traveled = 0.0


func add_velocity(velocity_addition: Vector3) -> void:
	velocity += velocity_addition


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if not get_viewport().get_camera_3d():
		warnings.append("No Camera3D found in scene - movement won't be camera-relative")
	
	return warnings


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("practice_mode"):
		var timer = SpeedrunTimer
		if timer:
			if timer.is_practice_mode():
				timer.disable_practice_mode()
			else:
				timer.enable_practice_mode()

	if event.is_action_pressed("instant_restart"):
		var timer = SpeedrunTimer
		if timer and timer.is_practice_mode():
			timer.instant_restart()
			reset_position(Vector3(0, 5, 0))  # Reset to spawn


func _draw() -> void:
	if not show_debug_overlay:
		return

	# Draw velocity vector
	var vel_end := global_position + velocity.normalized() * min(velocity.length() * 0.1, 100.0)
	draw_line(global_position, vel_end, Color.RED, 2.0)

	# Draw wish direction vector
	var wish_end := global_position + _wish_direction * 30.0
	draw_line(global_position, wish_end, Color.GREEN, 2.0)

# =============================================================================
# AUDIO & VISUAL FEEDBACK
# =============================================================================

func _play_jump_sound() -> void:
	# TODO: Replace with actual audio file
	# var audio = AudioStreamPlayer.new()
	# audio.stream = load("res://audio/jump.mp3")
	# audio.play()
	print("AUDIO: Play jump sound...")

func _play_shoot_sound() -> void:
	# TODO: Replace with actual audio file
	print("AUDIO: Play shoot sound...")

func _apply_shake(duration: float, intensity: float) -> void:
	# Visual screen shake effect
	var shake_intensity := 20.0 * intensity
	var shake_duration := duration
	
	# Store shake data for processing
	shake_data = {
		"intensity": shake_intensity,
		"duration": shake_duration,
		"time": Time.get_ticks_msec()
	}

func _spawn_jump_particles() -> void:
	# TODO: Add particle system for jump effect
	print("VISUAL: Spawn jump particles...")

func _spawn_shoot_particles() -> void:
	# TODO: Add particle system for muzzle flash and impact
	print("VISUAL: Spawn shoot particles...")

func _play_surf_whoosh() -> void:
	# TODO: Play surf whoosh sound based on speed
	if _current_speed > 100:
		# Higher speed = more intense whoosh
		print("AUDIO: Play surf whoosh (speed: %.1f u/s)" % _current_speed)

func _spawn_impact_sound() -> void:
	# TODO: Play impact sound based on impact surface
	print("AUDIO: Play impact sound...")

# =============================================================================
# SHAKE EFFECT
# =============================================================================

var shake_data: Dictionary = null

func _process(delta: float) -> void:
	# Process shake effect
	if shake_data:
		var elapsed := (Time.get_ticks_msec() - shake_data["time"]) / 1000.0
		if elapsed < shake_data["duration"]:
			var progress := 1.0 - elapsed / shake_data["duration"]
			# Smooth decay
			shake_intensity = shake_data["intensity"] * pow(progress, 3)
			if shake_intensity > 0.1:
				_apply_camera_shake(shake_intensity)
		else:
			shake_data = null

# =============================================================================
# CAMERA SHAKE
# =============================================================================

func _apply_camera_shake(intensity: float) -> void:
	if get_viewport():
		var viewport = get_viewport()
		if viewport.get_camera_3d():
			var shake_x := randf() * intensity - intensity / 2.0
			var shake_y := randf() * intensity - intensity / 2.0
			get_viewport().position = Vector2(shake_x, shake_y)
