extends Marker3D
class_name Checkpoint

## Checkpoint - A restart point for the level

signal checkpoint_reached(player: Player)

@export var checkpoint_id: int = 0
@export var checkpoint_name: String = "Checkpoint"
@export var respawn_time: float = 0.5

var is_active: bool = true
var last_activated: float = 0.0

func _ready() -> void:
	# Add to checkpoint group
	add_to_group("checkpoints")
	
	# Make checkpoint visible
	var marker_material = MarkerTexture.new()
	marker_material.color = Color.RED
	marker_material.size = Vector2(1, 1)
	marker_material.texture_type = MarkerTexture.TEXTURE_TYPE_CIRCLE
	marker = marker_material
	
	add_to_group("active_checkpoints")

func activate() -> void:
	if not is_active:
		return
	
	last_activated = Time.get_ticks_msec()
	is_active = true
	
	# Visual feedback
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE
	flash_material.emission_enabled = true
	flash_material.emission_strength = 3.0
	
	add_child(flash_material)
	await get_tree().create_timer(0.3).timeout

func deactivate() -> void:
	is_active = false

func _on_player_nearby(player: Player) -> void:
	# Check if player is close enough
	var distance := global_position.distance_to(player.global_position)
	if distance < 5.0:
		checkpoint_reached.emit(player)