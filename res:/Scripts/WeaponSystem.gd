extends Node3D

class_name WeaponSystem

## Manages weapons, shooting, reloading, switching with visuals and recoil.

@export var muzzle_flash_scene: PackedScene
@export var bullet_scene: PackedScene
@export var weapon_models: Array[PackedScene]  ## Array of weapon model scenes
@export var crosshair_scene: PackedScene

@export_group("Weapon Stats")
@export var pistol_stats: Dictionary = {
    "name": "Pistol",
    "damage": 25,
    "fire_rate": 0.5,  ## seconds
    "spread": 0.05,  ## radians
    "recoil": 20.0,  ## velocity push
    "magazine_size": 12,
    "reload_time": 1.5
}
@export var rifle_stats: Dictionary = {
    "name": "Rifle",
    "damage": 30,
    "fire_rate": 0.1,
    "spread": 0.02,
    "recoil": 15.0,
    "magazine_size": 30,
    "reload_time": 2.0
}

@onready var camera: Camera3D = get_parent().get_node("Camera3D")
@onready var muzzle: Marker3D = $Muzzle  ## Marker for muzzle position
@onready var weapon_holder: Node3D = $WeaponHolder  ## Node for weapon models

var current_weapon_index: int = 0
var weapons = []
var last_shot_time: float = 0.0
var is_reloading: bool = false
var reload_timer: float = 0.0
var current_ammo: int = 0
var reserve_ammo: Dictionary = {"Pistol": 120, "Rifle": 300}

func _ready() -> void:
    weapons = [pistol_stats, rifle_stats]
    current_ammo = weapons[current_weapon_index]["magazine_size"]
    _switch_weapon(0)  ## Load first weapon

func _process(delta: float) -> void:
    if is_reloading:
        reload_timer -= delta
        if reload_timer <= 0:
            _finish_reload()
    
    ## Weapon sway and bob
    _update_weapon_visuals(delta)
    
    ## Shooting
    if Input.is_action_pressed("shoot") and _can_shoot():
        _shoot()
    
    ## Reload
    if Input.is_action_just_pressed("reload") and not is_reloading and current_ammo < weapons[current_weapon_index]["magazine_size"]:
        _start_reload()
    
    ## Weapon switch
    for i in range(weapons.size()):
        if Input.is_action_just_pressed("weapon_" + str(i + 1)):
            _switch_weapon(i)

func _can_shoot() -> bool:
    var weapon = weapons[current_weapon_index]
    return not is_reloading and current_ammo > 0 and Time.get_time() - last_shot_time >= weapon["fire_rate"]

func _shoot() -> void:
    var weapon = weapons[current_weapon_index]
    last_shot_time = Time.get_time()
    
    ## Create bullet
    var bullet = bullet_scene.instantiate()
    bullet.position = muzzle.global_position
    bullet.damage = weapon["damage"]
    ## Add spread
    var spread_angle = randf_range(-weapon["spread"], weapon["spread"])
    bullet.direction = (camera.global_basis * Vector3.FORWARD).rotated(Vector3.UP, spread_angle)
    get_tree().root.add_child(bullet)
    
    ## Muzzle flash
    var flash = muzzle_flash_scene.instantiate()
    muzzle.add_child(flash)
    
    ## Recoil: push player velocity
    var recoil_dir = -camera.global_basis.z.normalized()
    get_parent().velocity += recoil_dir * weapon["recoil"]
    
    current_ammo -= 1

func _start_reload() -> void:
    is_reloading = true
    reload_timer = weapons[current_weapon_index]["reload_time"]
    ## Play reload animation if weapon model has it

func _finish_reload() -> void:
    var weapon_name = weapons[current_weapon_index]["name"]
    var needed = weapons[current_weapon_index]["magazine_size"] - current_ammo
    var available = min(needed, reserve_ammo[weapon_name])
    current_ammo += available
    reserve_ammo[weapon_name] -= available
    is_reloading = false

func _switch_weapon(index: int) -> void:
    if index >= weapons.size() or index == current_weapon_index:
        return
    current_weapon_index = index
    ## Remove old model
    for child in weapon_holder.get_children():
        child.queue_free()
    ## Add new model
    var model = weapon_models[index].instantiate()
    weapon_holder.add_child(model)
    current_ammo = weapons[index]["magazine_size"]  ## Assume full on switch, or keep

func _update_weapon_visuals(delta: float) -> void:
    if weapon_holder.get_child_count() == 0:
        return
    var weapon_model = weapon_holder.get_child(0)
    
    ## Sway: based on mouse movement
    var mouse_delta = Input.get_last_mouse_velocity() * delta * 0.001
    weapon_model.rotation.x = lerp(weapon_model.rotation.x, mouse_delta.y * 0.1, delta * 10)
    weapon_model.rotation.y = lerp(weapon_model.rotation.y, mouse_delta.x * 0.1, delta * 10)
    
    ## Bob: based on speed
    var speed = get_parent().velocity.length()
    var bob_amount = sin(Time.get_time() * 10) * speed * 0.001
    weapon_model.position.y = lerp(weapon_model.position.y, bob_amount, delta * 5)