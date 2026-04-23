extends Area3D
class_name HazardArea

## HazardArea - Defines areas with environmental hazards that affect gameplay

signal hazard_detected(position: Vector3)
signal hazard_entered(player: Player)
signal hazard_exited(player: Player)

@export var hazard_type: String = "water"  # "water", "lava", "ice", "mud", etc.
@export var damage_per_second: float = 0.0
@export var hazard_strength: float = 1.0  # Multiplier for effects
@export var visual_color: Color = Color.RED
@export var warning_light: NodePath = NodePath("")

var hazard_timer: float = 0.0
var affected_players: Array[Player] = []

func _ready() -> void:
	# Add to hazard groups
	add_to_group("hazards")
	add_to_group("environmental_hazards")
	
	# Set collision layers
	collision_layer = 2  # Hazard layer
	collision_mask = 4  # Player detection layer
	
	# Add warning light if specified
	if warning_light:
		var light = get_node(warning_light)
		if light:
			light.add_to_group("warning_lights")

func _process(delta: float) -> void:
	# Apply hazard effects to affected players
	if affected_players.is_empty():
		return
	
	hazard_timer -= delta
	if hazard_timer > 0:
		# Emit hazard warning
		if hazard_timer < 0.1:
			hazard_detected.emit(global_position)
			hazard_timer = 0.0


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		affected_players.append(body)
		hazard_entered.emit(body)
		
		# Apply immediate hazard effect
		_apply_hazard_effect(body)
	
	# Check if this is a water area
	if hazard_type == "water":
		# Apply water interaction
		if body is SurfPhysicsController:
			body._is_in_water = true
			body._ground_normal = Vector3.UP
			body.surf_state_changed.emit(true, false)


func _on_body_exited(body: Node3D) -> void:
	affected_players.erase(body)
	hazard_exited.emit(body)
	
	# Clear water interaction
	if hazard_type == "water" and body is SurfPhysicsController:
		body._is_in_water = false
		body.surf_state_changed.emit(false, false)


func _apply_hazard_effect(player: Player) -> void:
	match hazard_type:
		"lava":
			# Apply fire damage
			player.take_damage(damage_per_second * hazard_strength)
		"ice":
			# Reduce player speed
			player.velocity = player.velocity * 0.5
		"mud":
			# Increase friction
			player._surface_friction *= 2.0
		"water":
			# Apply water interaction (handled in surf controller)
			pass
		_:
			# Unknown hazard type - just visual warning
			pass


func get_hazard_info() -> Dictionary:
	return {
		"type": hazard_type,
		"damage_per_second": damage_per_second,
		"strength": hazard_strength,
		"position": global_position,
		"active": affected_players.size() > 0
	}