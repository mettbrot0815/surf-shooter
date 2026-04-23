extends StaticBody3D
class_name EnemyTarget

## EnemyTarget - A target for players to shoot at during the level

signal shot_detected(position: Vector3)
signal hit_registered(position: Vector3)

@export var target_type: String = "enemy"  # "enemy", "target", "practice"
@export var health: int = 100
@export var visual_color: Color = Color.RED
@export var hit_effect: NodePath = NodePath("")
@export var death_effect: NodePath = NodePath("")

var current_health: int = 0
var is_active: bool = true
var last_hit_time: float = 0.0

func _ready() -> void:
	current_health = health
	# Add collision layers for detection
	add_to_group("shooting_targets")
	
	# Add visual indicator
	var cube = CubeMesh.new()
	cube.size = Vector3(1, 1, 1)
	var shape = CubeShape3D.new()
	shape.size = Vector3(1, 1, 1)
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	
	var mesh = MeshInstance3D.new()
	mesh.mesh = cube
	mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = visual_color
	
	add_child(collision_shape)
	add_child(mesh)
	
	# Add hit effect if specified
	if hit_effect:
		var effect_node = get_node(hit_effect)
		if effect_node:
			effect_node.add_to_group("hit_effects")
	
	# Add death effect if specified
	if death_effect:
		var death_node = get_node(death_effect)
		if death_node:
			death_node.add_to_group("death_effects")


func take_damage(amount: int, hit_position: Vector3) -> bool:
	if not is_active:
		return false
	
	# Calculate damage reduction based on target type
	var reduction := 0.0
	if target_type == "enemy":
		reduction = 0.1  # Enemies take reduced damage
	
	current_health -= int(amount * (1.0 - reduction))
	last_hit_time = Time.get_ticks_msec()
	
	if current_health <= 0:
		kill_target()
		return true
	else:
		hit_registered.emit(hit_position)
		return false


func kill_target() -> void:
	if not is_active:
		return
	
	is_active = false
	add_to_group("shooting_targets")  # Remove from group
	
	# Visual feedback - flash effect
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE
	flash_material.emission_enabled = true
	flash_material.emission_color = Color.WHITE
	flash_material.emission_strength = 5.0
	
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.material_override = flash_material
		await get_tree().create_timer(0.1).timeout
		mesh_instance.material_override = null
	
	# Spawn death effect
	if death_effect:
		var death_node = get_node(death_effect)
		if death_node:
			death_node.queue_free()
	
	shot_detected.emit(global_position)


func get_target_info() -> Dictionary:
	return {
		"type": target_type,
		"health": current_health,
		"is_active": is_active,
		"position": global_position,
		"last_hit": last_hit_time
	}