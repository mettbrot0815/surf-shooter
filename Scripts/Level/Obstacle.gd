extends StaticBody3D
class_name Obstacle

## Obstacle - Environmental obstacles that test player skill

signal obstacle_hit(position: Vector3)
signal obstacle_avoided(position: Vector3)

@export var obstacle_type: String = "rock"  # "rock", "crate", "barrier", etc.
@export var difficulty: int = 5
@export var warning_time: float = 1.0  # Seconds to warn player
@export var hit_effect: NodePath = NodePath("")
@export var destroy_effect: NodePath = NodePath("")

var warning_timer: float = warning_time

func _ready() -> void:
	# Make obstacle detectable by player
	add_to_group("obstacles")
	add_to_group("hazards")
	
	# Add visual indicators
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	
	if get_node_or_null("CollisionShape3D"):
		get_node("CollisionShape3D").collision_layer |= 2  # Add obstacle layer
		get_node("CollisionShape3D").collision_mask |= 4  # Detect player layer
	
	if get_node_or_null("MeshInstance3D"):
		get_node("MeshInstance3D").material_override = material


func detect_player_approach(player_controller: SurfPhysicsController, delta: float) -> void:
	# Calculate distance to player
	var distance := global_position.distance_to(player_controller.global_position)
	
	# Give warning when player approaches
	if distance < 15.0 and distance > 5.0:
		warning_timer -= delta
		if warning_timer <= 0:
			warning_timer = 0.0
			# Emit warning signal
			_obstacle_warning.emit()


func _on_obstacle_warning() -> void:
	# Visual warning - flash the obstacle
	if get_node_or_null("MeshInstance3D"):
		var mesh_instance = get_node("MeshInstance3D")
		var original_color = mesh_instance.material_override.get("albedo_color", Color.GRAY)
		
		# Flash white to indicate danger
		var flash_material = StandardMaterial3D.new()
		flash_material.albedo_color = Color.WHITE
		flash_material.emission_enabled = true
		flash_material.emission_strength = 2.0
		
		mesh_instance.material_override = flash_material
		await get_tree().create_timer(0.1).timeout
		mesh_instance.material_override.albedo_color = original_color


func hit_by_player(player_velocity: Vector3, hit_position: Vector3) -> bool:
	# Check if obstacle can be destroyed/damaged
	if difficulty == 0:
		return false  # Invincible obstacle
	
	# Apply impact effect
	_apply_impact(player_velocity)
	
	# Check if obstacle should be destroyed
	if difficulty <= 1:
		destroy_obstacle()
		return true
	else:
		return false


func _apply_impact(velocity: Vector3) -> void:
	# Visual feedback
	if hit_effect:
		var effect_node = get_node(hit_effect)
		if effect_node:
			effect_node.add_to_group("impact_effects")
			effect_node.global_position = global_position


func destroy_obstacle() -> void:
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.queue_free()
	
	# Destroy collision shape if exists
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		collision_shape.queue_free()
	
	# Destroy effect if specified
	if destroy_effect:
		var effect_node = get_node(destroy_effect)
		if effect_node:
			effect_node.queue_free()


func get_obstacle_info() -> Dictionary:
	return {
		"type": obstacle_type,
		"difficulty": difficulty,
		"position": global_position,
		"is_active": true
	}