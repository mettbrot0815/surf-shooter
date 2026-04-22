extends CharacterBody3D
class_name WeaponSystem

## WeaponSystem - Weapon mechanics for surf shooter

signal weapon_changed(weapon_type: String)
signal shot_fired(weapon_type: String, direction: Vector3)
signal ammo_updated(weapon_type: String, ammo: int)

@export_group("Weapon Types")
@export var equipped_weapon: String = "pistol"
@export var available_weapons: Array[String] = ["pistol", "rifle"]

@export_group("Pistol Settings")
@export var pistol_ammo: int = 12
@export var pistol_recoil: Vector3 = Vector3.UP * 2.0 + Vector3.RIGHT * 0.5
@export var pistol_spread: float = 0.02
@export var pistol_fire_rate: float = 0.15

@export_group("Rifle Settings")
@export var rifle_ammo: int = 30
@export var rifle_recoil: Vector3 = Vector3.UP * 4.0 + Vector3.RIGHT * 1.0
@export var rifle_spread: float = 0.05
@export var rifle_fire_rate: float = 0.08

@export_group("World Settings")
@export var bullet_speed: float = 300.0
@export var bullet_lifetime: float = 2.0
@export var bullet_radius: float = 0.1
@export var bullet_color: Color = Color.RED

@export_group("Weapon Sway & Bob")
@export var sway_intensity: float = 0.1
@export var sway_speed: float = 2.0
@export var bob_intensity: float = 0.05
@export var bob_speed: float = 10.0
@export var bob_frequency: float = 2.0

@export_group("Debug")
@export var log_movement: bool = false

var _current_weapon: String = "pistol"
var _sway_offset: Vector3 = Vector3.ZERO
var _bob_offset: Vector3 = Vector3.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var _ammo: Dictionary = {
	"pistol": pistol_ammo,
	"rifle": rifle_ammo
}
var _fire_cooldown: float = 0.0
var _last_shot_time: float = 0.0
var _is_shooting: bool = false

func _ready() -> void:
	add_to_group("players")
	_update_ammo()
	_update_weapon_visual()

func _physics_process(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

func _process(delta: float) -> void:
	_update_weapon_sway(delta)
	_update_weapon_bob(delta)
	_apply_weapon_offsets()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") or event.is_action_pressed("fire"):
		fire_weapon()
	elif event.is_action_pressed("reload"):
		reload_weapon()
	elif event.is_action_pressed("weapon_1"):
		switch_to_weapon("pistol")
	elif event.is_action_pressed("weapon_2"):
		switch_to_weapon("rifle")
	elif event is InputEventMouseMotion:
		_mouse_delta = event.relative * 0.001  # Scale mouse delta

func _update_ammo() -> void:
	ammo_updated.emit(_current_weapon, _ammo[_current_weapon])

func fire_weapon() -> void:
	if _fire_cooldown > 0.0:
		return

	if _ammo[_current_weapon] <= 0:
		return

	var weapon_settings: Dictionary = {
		"pistol": {
			"recoil": pistol_recoil,
			"spread": pistol_spread,
			"fire_rate": pistol_fire_rate,
			"damage": 25.0,
			"projectile_speed": bullet_speed
		},
		"rifle": {
			"recoil": rifle_recoil,
			"spread": rifle_spread,
			"fire_rate": rifle_fire_rate,
			"damage": 35.0,
			"projectile_speed": bullet_speed
		}
	}

	var settings: Dictionary = weapon_settings[_current_weapon]

	_last_shot_time = Time.get_ticks_msec()
	_fire_cooldown = settings["fire_rate"]

	_ammo[_current_weapon] -= 1
	_update_ammo()

	var direction := get_shot_direction()
	# Deterministic spread based on shot count (not random)
	var shot_index := _ammo[_current_weapon] % 8  # Cycle through 8 spread patterns
	var spread_offset := _get_deterministic_spread(shot_index, settings["spread"])
	direction = (direction + spread_offset).normalized()

	apply_recoil(settings["recoil"])

	shot_fired.emit(_current_weapon, direction)

	# Audio placeholder - play shoot sound
	_play_shoot_sound()

	_spawn_projectile(direction, settings)

	if log_movement:
		print("Fired %s: direction=%s, ammo=%d" % [_current_weapon, direction, _ammo[_current_weapon]])

func get_shot_direction() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3.FORWARD

	# Use camera forward direction for shooting
	var direction := -camera.global_transform.basis.z
	return direction.normalized()


func _get_deterministic_spread(index: int, max_spread: float) -> Vector3:
	# Predefined spread patterns for deterministic behavior
	var patterns := [
		Vector3(0, 0, 0),
		Vector3(0.5, 0.5, 0),
		Vector3(-0.5, 0.5, 0),
		Vector3(0.5, -0.5, 0),
		Vector3(-0.5, -0.5, 0),
		Vector3(0, 0.7, 0),
		Vector3(0.7, 0, 0),
		Vector3(0, -0.7, 0)
	]

	if index >= 0 and index < patterns.size():
		return patterns[index] * max_spread
	return Vector3.ZERO

func apply_recoil(recoil: Vector3) -> void:
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("add_velocity"):
		player.add_velocity(recoil)

func _spawn_projectile(direction: Vector3, settings: Dictionary) -> void:
	var bullet_scene = load("res://Scenes/Bullet.tscn")
	if not bullet_scene:
		# Fallback: create simple projectile
		var bullet_body := CharacterBody3D.new()
		bullet_body.position = global_position + direction * 0.5

		var bullet_velocity := direction * settings["projectile_speed"]
		bullet_body.velocity = bullet_velocity

		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = SphereShape3D.new()
		collision_shape.shape.radius = bullet_radius
		bullet_body.add_child(collision_shape)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = SphereMesh.new()
		mesh_instance.mesh.radius = bullet_radius
		mesh_instance.mesh.height = bullet_radius * 2
		var material := StandardMaterial3D.new()
		material.albedo_color = bullet_color
		mesh_instance.material_override = material
		bullet_body.add_child(mesh_instance)

		get_tree().root.add_child(bullet_body)

		# Add muzzle flash effect
		_add_muzzle_flash()

		# Remove after lifetime
		await get_tree().create_timer(bullet_lifetime).timeout
		if is_instance_valid(bullet_body):
			bullet_body.queue_free()
	else:
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.position = global_position + direction * 0.5
		bullet_instance.direction = direction
		bullet_instance.speed = settings["projectile_speed"]
		bullet_instance.damage = settings["damage"]
		get_tree().root.add_child(bullet_instance)

		_add_muzzle_flash()


func _add_muzzle_flash() -> void:
	var flash_scene = load("res://Scenes/MuzzleFlash.tscn")
	if flash_scene:
		var flash_instance = flash_scene.instantiate()
		flash_instance.position = global_position + Vector3.FORWARD * 0.5
		get_tree().root.add_child(flash_instance)

func reload_weapon() -> void:
	# Simple reload - refill ammo
	if _current_weapon == "pistol":
		_ammo["pistol"] = pistol_ammo
	elif _current_weapon == "rifle":
		_ammo["rifle"] = rifle_ammo
	_update_ammo()
	print("Reloaded " + _current_weapon)

func switch_to_weapon(weapon: String) -> void:
	if weapon in available_weapons and weapon != _current_weapon:
		_current_weapon = weapon
		weapon_changed.emit(_current_weapon)
		_update_ammo()
		_update_weapon_visual()
		print("Switched to " + _current_weapon)

func _update_weapon_visual() -> void:
	var weapon_mesh = $WeaponMesh
	if weapon_mesh and weapon_mesh.mesh:
		var material = weapon_mesh.material_override
		if not material:
			material = StandardMaterial3D.new()
			weapon_mesh.material_override = material

		# Change color based on weapon
		if _current_weapon == "pistol":
			material.albedo_color = Color(0.8, 0.8, 0.9)  # Light gray
			weapon_mesh.mesh.size = Vector3(0.2, 0.1, 0.5)
		elif _current_weapon == "rifle":
			material.albedo_color = Color(0.6, 0.4, 0.2)  # Brown
			weapon_mesh.mesh.size = Vector3(0.3, 0.15, 0.8)

func get_current_weapon() -> String:
	return _current_weapon

func get_current_ammo() -> int:
	return _ammo[_current_weapon]

func set_ammo(weapon: String, amount: int) -> void:
	if weapon in _ammo:
		_ammo[weapon] = amount
		_update_ammo()

func _update_weapon_sway(delta: float) -> void:
	var mouse_motion = Input.get_last_mouse_velocity() * delta
	_mouse_delta = _mouse_delta.lerp(mouse_motion, sway_speed * delta)
	_sway_offset.x = -_mouse_delta.x * sway_intensity
	_sway_offset.y = _mouse_delta.y * sway_intensity

func _update_weapon_bob(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("get_current_speed"):
		var speed = player.get_current_speed()
		if speed > 10.0:  # Only bob when moving
			_bob_time += delta * bob_speed * (speed / 100.0)
			var bob_amount = sin(_bob_time * bob_frequency) * bob_intensity
			_bob_offset.y = bob_amount
			_bob_offset.x = cos(_bob_time * bob_frequency * 0.5) * bob_intensity * 0.5
		else:
			_bob_offset = _bob_offset.lerp(Vector3.ZERO, delta * 5.0)

func _apply_weapon_offsets() -> void:
	var weapon_mesh = $WeaponMesh
	if weapon_mesh:
		var base_position = Vector3(0.5, -0.2, -0.5)  # Default position
		weapon_mesh.position = base_position + _sway_offset + _bob_offset

func _play_shoot_sound() -> void:
	# Audio placeholder - in real implementation, play audio stream
	print("BANG! Shot fired with " + _current_weapon)
