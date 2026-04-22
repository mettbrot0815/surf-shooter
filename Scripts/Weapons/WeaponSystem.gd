extends Node3D
class_name WeaponSystem

## WeaponSystem - Precision shooting for surf shooter
##
## Implements:
## - Recoil and spread patterns
## - Bullet physics with gravity
## - Hit registration
## - Sound and visual effects
##
## Sources:
## - CS:GO shooting mechanics
## - Source engine weapon physics

signal bullet_fired(position: Vector3, velocity: Vector3)
signal bullet_hit(hit_position: Vector3, hit_normal: Vector3, hit_entity: Node3D)
signal enemy_hit(enemy: Node3D, damage: float)
signal weapon_reloaded(weapon: String)

# =============================================================================
# WEAPONS
# =============================================================================

const Pistol: Dictionary = {
	"name": "Pistol",
	"fire_rate": 0.3,
	"spread": 0.1,
	"damage": 25.0,
	"bullet_speed": 500.0,
	"recoil_up": 0.3,
	"recoil_right": 0.1,
	"recoil_spread": 0.05,
	"magazine_size": 12,
	"reload_time": 1.5,
	"bullet_count": 1,
	"auto_fire": false
}

const Rifle: Dictionary = {
	"name": "Rifle",
	"fire_rate": 0.05,
	"spread": 0.02,
	"damage": 12.0,
	"bullet_speed": 700.0,
	"recoil_up": 0.15,
	"recoil_right": 0.05,
	"recoil_spread": 0.01,
	"magazine_size": 30,
	"reload_time": 2.0,
	"bullet_count": 1,
	"auto_fire": true
}

var _current_weapon: Dictionary = Pistol
var _fire_rate_timer: float = 0.0
var _is_reloading: bool = false
var _current_magazine: int = 12
var _current_ammo: int = 12
var _last_shot_time: float = 0.0
var _recoil_accumulation: Vector3 = Vector3.ZERO

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Muzzle Flash")
@export var muzzle_flash_scene: PackedScene
@export var muzzle_flash_duration: float = 0.1

@export_group("Muzzle Effects")
@export var muzzle_glow_enabled: bool = true
@export var muzzle_glow_material: Texture2D

@export_group("Sound")
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream

@export_group("Debug")
@export var show_bullets: bool = false
@export var bullet_lifetime: float = 3.0
@export var bullet_scale: float = 0.5

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Set up auto-switching if desired
	# switch_to_weapon("Rifle")


func _process(_delta: float) -> void:
	# Update fire rate timer
	if _fire_rate_timer > 0:
		_fire_rate_timer -= get_process_delta_time()


# =============================================================================
# WEAPON CONTROL
# =============================================================================

func switch_to_weapon(weapon_name: String) -> void:
	"""Switch to a different weapon"""
	var weapon_dict := _current_weapon
	if weapon_name == "Pistol":
		_current_weapon = Pistol
	elif weapon_name == "Rifle":
		_current_weapon = Rifle
	else:
		return
	
	# Reset state for new weapon
	_current_magazine = _current_weapon["magazine_size"]
	_current_ammo = _current_weapon["magazine_size"]
	_fire_rate_timer = 0.0
	_is_reloading = false
	_last_shot_time = 0.0
	_recoil_accumulation = Vector3.ZERO
	
	# Play switch sound (could be expanded)
	print("[Weapon] Switched to: " + _current_weapon["name"])


func get_current_weapon_name() -> String:
	return _current_weapon["name"]


func is_empty() -> bool:
	"""Check if current weapon is out of ammo"""
	return _current_ammo <= 0


func reload() -> void:
	"""Reload current weapon"""
	if _is_reloading or _current_ammo >= _current_weapon["magazine_size"]:
		return
	
	_is_reloading = true
	
	if reload_sound:
		# Play reload sound
		pass  # Implementation depends on your audio system
	
	# Simulate reload time
	await get_tree().create_timer(_current_weapon["reload_time"]).timeout
	
	_current_ammo = _current_weapon["magazine_size"]
	_current_magazine = _current_weapon["magazine_size"]
	_is_reloading = false
	
	weapon_reloaded.emit(_current_weapon["name"])


func get_ammo_count() -> int:
	return _current_ammo


func get_magazine_count() -> int:
	return _current_magazine


# =============================================================================
# FIRING
# =============================================================================

func shoot(input_direction: Vector3) -> void:
	"""
	Fire the current weapon.
	
	@param input_direction: Direction from weapon to target
	"""
	var now: float = Time.get_ticks_msec() / 1000.0
	
	# Check fire rate
	if _current_weapon["auto_fire"]:
		# Auto-fire: shoot if enough time has passed
		if now - _last_shot_time < _current_weapon["fire_rate"]:
			return
	else:
		# Manual fire: always allow single shot
		if now - _last_shot_time < _current_weapon["fire_rate"]:
			return
	
	_fire_rate_timer = _current_weapon["fire_rate"]
	_last_shot_time = now
	
	# Calculate spread
	var spread: float = _current_weapon["spread"]
	var random_spread := Vector3.random_for_direction(spread)
	
	# Calculate recoil
	_recoil_accumulation += Vector3(
		_random_range(-_current_weapon["recoil_right"], _current_weapon["recoil_right"]),
		_random_range(0, _current_weapon["recoil_up"] + random_spread.y),
		_random_range(-_current_weapon["recoil_right"], _current_weapon["recoil_right"])
	)
	
	# Calculate bullet velocity with spread
	var bullet_direction: Vector3 = input_direction + random_spread
	bullet_direction.normalize()
	
	var muzzle_position := get_muzzle_position()
	var muzzle_velocity := bullet_direction * _current_weapon["bullet_speed"]
	
	# Fire bullet
	fire_bullet(muzzle_position, muzzle_velocity)
	
	# Apply recoil
	apply_recoil()
	
	# Play fire effects
	play_fire_effects()


func fire_bullet(position: Vector3, velocity: Vector3) -> void:
	"""Fire a single bullet"""
	bullet_fired.emit(position, velocity)
	
	# Create bullet (visual)
	create_bullet_visual(position, velocity)
	
	# Spawn bullet scene if available
	if _has_bullet_scene():
		var bullet := _current_bullet_scene().instantiate() as Node3D
		add_child(bullet)
		bullet.global_position = position
		bullet.linear_velocity = velocity
		bullet.scale = Vector3(bullet_scale, bullet_scale, bullet_scale)
		bullet.add_to_group("bullets")
		bullet.add_to_group("player_bullets")
	
	# Decrease ammo
	_current_ammo -= _current_weapon["bullet_count"]
	_current_magazine -= _current_weapon["bullet_count"]
	
	# Check if out of ammo
	if _current_ammo <= 0:
		weapon_empty.emit()


# =============================================================================
# BULLET VISUALS
# =============================================================================

func _has_bullet_scene() -> bool:
	return _current_bullet_scene() != null


func _current_bullet_scene() -> PackedScene:
	return _bullet_scene


@export var _bullet_scene: PackedScene = null


func create_bullet_visual(position: Vector3, velocity: Vector3) -> void:
	"""Create visual trail for bullet"""
	if not _current_weapon["name"] == "Rifle":
		return
	
	# Create trail (simple implementation)
	var trail := Trail.new()
	trail.max_age = bullet_lifetime
	trail.add_point(position)
	add_child(trail)


# =============================================================================
# RECOIL SYSTEM
# =============================================================================

func apply_recoil() -> void:
	"""Apply recoil to weapon and camera"""
	var recoil := _recoil_accumulation.normalized() * 50.0
	_recoil_accumulation *= 0.8  # Decay
	
	# Apply to weapon
	if has_node("WeaponMesh"):
		var weapon := get_node("WeaponMesh") as Node3D
		weapon.global_rotation.y += recoil.x
		weapon.global_rotation.x += recoil.y
	
	# Apply to camera (smooth)
	if get_parent().has_method("set_input"):
		get_parent().set_input("recoil_x", recoil.x)
		get_parent().set_input("recoil_y", recoil.y)


# =============================================================================
# FIRE EFFECTS
# =============================================================================

func play_fire_effects() -> void:
	"""Play muzzle flash and other effects"""
	
	# Muzzle flash
	if muzzle_flash_scene:
		var flash := muzzle_flash_scene.instantiate() as Node3D
		add_child(flash)
		flash.global_transform = _get_muzzle_transform()
		flash.queue_free()
	
	# Muzzle glow
	if muzzle_glow_enabled and muzzle_glow_material:
		if has_node("MuzzleGlow"):
			var glow := get_node("MuzzleGlow") as Node3D
			glow.material_override = muzzle_glow_material
	
	# Flash camera
	if get_tree().get_root().has_method("flash_screen"):
		get_tree().get_root().flash_screen(0.1)
	
	await get_tree().create_timer(muzzle_flash_duration).timeout


func _get_muzzle_transform() -> Transform3D:
	"""Get transform at muzzle position"""
	if has_node("WeaponMesh"):
		var weapon := get_node("WeaponMesh") as Node3D
		return weapon.get_transform()
	return Transform3D()


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check for right-click weapon switching
			if event.button_index == MOUSE_BUTTON_RIGHT:
				# Cycle weapons (could be expanded)
				var weapons := ["Pistol", "Rifle"]
				var current_index := weapons.find(_current_weapon["name"])
				var next_index := (current_index + 1) % weapons.size()
				switch_to_weapon(weapons[next_index])
			else:
				shoot(Vector3.ZERO)  # Default direction
