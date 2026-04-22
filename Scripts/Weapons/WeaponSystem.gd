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

var _current_weapon: String = "pistol"
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

func _physics_process(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

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
			"ammo": pistol_ammo
		},
		"rifle": {
			"recoil": rifle_recoil,
			"spread": rifle_spread,
			"fire_rate": rifle_fire_rate,
			"ammo": rifle_ammo
		}
	}
	
	var settings: Dictionary = weapon_settings[_current_weapon]
	
	_current_weapon = _current_weapon
	_last_shot_time = Time.get_ticks_msec()
	_fire_cooldown = settings["fire_rate"]
	
	ammo[_current_weapon] -= 1
	_update_ammo()
	
	var direction := get_shot_direction()
	direction = direction + Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * settings["spread"]
	direction = direction.normalized()
	
	apply_recoil(settings["recoil"])
	
	shot_fired.emit(_current_weapon, direction)
	
	_spawn_bullet(direction)
	
	print("Fired %s: direction=%s, ammo=%d" % [_current_weapon, direction, _ammo[_current_weapon]])

func get_shot_direction() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3.RIGHT
	
	var mouse_position: Vector2 = Input.get_mouse_position()
	var camera_transform := camera.global_transform
	var camera_forward := camera_transform.basis.z
	var camera_right := camera_transform.basis.x
	var camera_up := camera_transform.basis.y
	
	var normalized_pos := mouse_position.normalized()
	
	var direction := camera_forward + camera_right * normalized_pos.x + camera_up * normalized_pos.y
	return direction.normalized()

func apply_recoil(recoil: Vector3) -> void:
	if has_node("CharacterBody3D"):
		var player := get_node("CharacterBody3D")
		if player:
			player.velocity += recoil

func _spawn_bullet(direction: Vector3) -> void:
	var bullet_body := CharacterBody3D.new()
	bullet_body.position = global_position + Vector3.RIGHT * 0.5
	
	var bullet_velocity := direction * bullet_speed
	bullet_body.velocity = bullet_velocity
	
	var bullet_life := 0.0
	
	bullet_body.body_entered = func(body: Node3D) -> void:
		queue_free()
	
	get_tree().add_child(bullet_body)
	
	bullet_body.velocity = bullet_velocity

func _switch_weapon() -> void:
	var idx := available_weapons.find(_current_weapon)
	if idx != -1 and idx + 1 < available_weapons.size():
		_current_weapon = available_weapons[idx + 1]
		ammo[_current_weapon] = _ammo[_current_weapon]
		weapon_changed.emit(_current_weapon)
		_update_ammo()
		print("Switched to " + _current_weapon)

func get_current_weapon() -> String:
	return _current_weapon

func get_current_ammo() -> int:
	return _ammo[_current_weapon]

func set_ammo(weapon: String, amount: int) -> void:
	if weapon in _ammo:
		ammo[weapon] = amount
