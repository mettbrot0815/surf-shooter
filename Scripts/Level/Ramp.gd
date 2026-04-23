extends StaticBody3D
class_name Ramp

## Ramp - A sloped surface that players traverse

signal ramp_entered(player: Player)
signal ramp_exited(player: Player)
signal ramp_completed(player: Player)

@export var ramp_name: String = "Ramp"
@export var ramp_angle: float = 0.0  # in degrees
@export var ramp_length: float = 15.0
@export var ramp_width: float = 12.0
@export var ramp_height: float = 2.0
@export var ramp_speed: float = 5.0
@export var checkpoint_id: int = 0

var is_active: bool = true
var player_on_ramp: Player = null
var is_completed: bool = false
var progress: float = 0.0
var ramp_direction: Vector3 = Vector3.RIGHT
var ramp_normal: Vector3 = Vector3.UP

func _ready() -> void:
	# Add to ramp group
	add_to_group("ramps")
	
	# Calculate ramp normal based on angle
	var angle_rad := deg_to_rad(ramp_angle)
	ramp_normal = Vector3(0, sin(angle_rad), cos(angle_rad))
	ramp_direction = ramp_normal.cross(Vector3.FORWARD).normalized()
	
	# Setup materials
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.6)
	material.albedo_texture = RampTexture.new()
	material.albedo_texture.size = Vector2(64, 64)
	material.albedo_texture.wrap_mode_u = Texture.WRAP_CLAMP
	material.albedo_texture.wrap_mode_v = Texture.WRAP_CLAMP
	material.albedo_texture.repeat = Vector2(4, 4)
	material.emission_enabled = true
	material.emission_strength = 0.3
	material.ramp_visual = true
	add_child(material)
	
	# Add visual markers
	create_ramp_markers()

func create_ramp_markers() -> void:
	# Create start marker
	var start_marker = MarkerTexture.new()
	start_marker.color = Color.GREEN
	start_marker.size = Vector2(2, 2)
	start_marker.texture_type = MarkerTexture.TEXTURE_TYPE_SQUARE
	var start_marker_node = Marker3D.new()
	start_marker_node.position = global_position - ramp_direction * (ramp_length / 2)
	start_marker_node.set_surface_material(0, start_marker)
	add_child(start_marker_node)
	
	# Create end marker
	var end_marker = MarkerTexture.new()
	end_marker.color = Color.RED
	end_marker.size = Vector2(2, 2)
	end_marker.texture_type = MarkerTexture.TEXTURE_TYPE_SQUARE
	var end_marker_node = Marker3D.new()
	end_marker_node.position = global_position + ramp_direction * (ramp_length / 2)
	end_marker_node.set_surface_material(0, end_marker)
	add_child(end_marker_node)

func enter_ramp(player: Player) -> void:
	if not is_active:
		return
	
	player_on_ramp = player
	is_active = false
	
	# Visual feedback
	var enter_effect = Line2D.new()
	enter_effect.points = [global_position, global_position + ramp_direction * 10]
	enter_effect.line_color = Color.GREEN
	enter_effect.line_width = 2.0
	enter_effect.closed = false
	add_child(enter_effect)
	
	ramp_entered.emit(player)

func exit_ramp(player: Player) -> void:
	if player_on_ramp == player:
		player_on_ramp = null
	
	is_active = true
	ramp_exited.emit(player)

func process(_delta: float) -> void:
	if player_on_ramp == null:
		return
	
	var player := player_on_ramp
	
	# Calculate progress
	var current_position := player.global_position
	var distance_traveled := current_position.distance_to(global_position)
	
	if distance_traveled >= (ramp_length / 2):
		# Check if player has completed the ramp
		var ramp_center := global_position + ramp_direction * (ramp_length / 2)
		var distance_to_center := current_position.distance_to(ramp_center)
		var tolerance := ramp_length * 0.1
		
		if distance_to_center < tolerance:
			is_completed = true
			ramp_completed.emit(player)
			print("Ramp %s completed!" % ramp_name)

func get_ramp_info() -> Dictionary:
	return {
		"name": ramp_name,
		"angle": ramp_angle,
		"length": ramp_length,
		"width": ramp_width,
		"is_active": is_active,
		"is_completed": is_completed,
		"progress": progress,
		"position": global_position,
		"direction": ramp_direction,
		"normal": ramp_normal
	}

func _on_player_entered(player: Node) -> void:
	if player is Player:
		enter_ramp(player as Player)

func _on_player_exited(player: Node) -> void:
	if player is Player:
		exit_ramp(player as Player)