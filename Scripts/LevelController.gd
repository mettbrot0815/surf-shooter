extends Node3D
class_name LevelController

## LevelController - Manages the 5-ramp level including ramps, checkpoints, enemies, obstacles, and hazards

signal level_started()
signal level_completed()
signal checkpoint_activated(checkpoint_id: int)
signal obstacle_destroyed(obstacle: Obstacle)
signal hazard_detected(hazard: HazardArea)
signal ramp_entered(ramp: Ramp)
signal ramp_exited(ramp: Ramp)

var enemy_spawner: EnemySpawner = null
var checkpoints: Array[Checkpoint] = []
var obstacles: Array[Obstacle] = []
var hazards: Array[HazardArea] = []
var ramps: Array[Ramp] = []
var is_level_active: bool = false
var current_ramp: Ramp = null
var ramp_sequence_index: int = 0
var total_ramps: int = 5

func _ready() -> void:
	# Find and reference level components
	enemy_spawner = get_node_or_null("EnemySpawner")
	
	# Find all checkpoints
	checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		checkpoint.add_to_group("active_checkpoints")
		checkpoint.referenced_by = self
	
	# Find all obstacles
	obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		obstacle.add_to_group("environmental_hazards")
	
	# Find all hazards
	hazards = get_tree().get_nodes_in_group("hazards")
	for hazard in hazards:
		hazard.add_to_group("environmental_hazards")
	
	# Find all ramps
	ramps = get_tree().get_nodes_in_group("ramps")
	total_ramps = ramps.size()
	if total_ramps > 0:
		ramp_sequence_index = 0
	
	# Start level
	level_started.emit()

func _process(_delta: float) -> void:
	# Handle checkpoint interactions
	for checkpoint in checkpoints:
		if checkpoint.is_active:
			if get_tree().get_first_node_in_group("players"):
				_check_checkpoint_interaction(checkpoint)
	
	# Handle obstacle interactions
	for obstacle in obstacles:
		_check_obstacle_interactions(obstacle)
	
	# Handle hazard interactions
	for hazard in hazards:
		_check_hazard_interactions(hazard)
	
	# Handle ramp interactions
	if current_ramp != null:
		current_ramp.process(0.016)

func _check_checkpoint_interaction(checkpoint: Checkpoint) -> void:
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	var player_controller = player as Player
	if player_controller:
		var distance := checkpoint.global_position.distance_to(player_controller.global_position)
		if distance < 3.0:
			checkpoint_activated.emit(checkpoint.checkpoint_id)
			print("Checkpoint %d activated!" % checkpoint.checkpoint_id)

func _check_obstacle_interactions(obstacle: Obstacle) -> void:
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	var player_controller = player as Player
	if player_controller:
		var distance := obstacle.global_position.distance_to(player_controller.global_position)
		if distance < 15.0 and distance > 5.0:
			obstacle.detect_player_approach(player_controller, 0.016)

func _check_hazard_interactions(hazard: HazardArea) -> void:
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return
	
	var player_controller = player as Player
	if player_controller:
		var distance := hazard.global_position.distance_to(player_controller.global_position)
		if distance < 10.0:
			hazard._on_body_entered(player)
			hazard._process(0.016)

func get_level_state() -> Dictionary:
	return {
		"is_active": is_level_active,
		"active_checkpoints": checkpoints.filter(func(c: Checkpoint) -> bool: return c.is_active).size(),
		"active_obstacles": obstacles.filter(func(o: Obstacle) -> bool: return o.is_active).size(),
		"active_hazards": hazards.filter(func(h: HazardArea) -> bool: return h.affected_players.size() > 0).size(),
		"current_ramp_index": ramp_sequence_index,
		"total_ramps": total_ramps
	}

func reset_level() -> void:
	# Reset all checkpoints
	for checkpoint in checkpoints:
		checkpoint.deactivate()
	
	# Reset all obstacles
	for obstacle in obstacles:
		var mesh_instance = get_node_or_null("%s/MeshInstance3D" % obstacle.name)
		if mesh_instance:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.3, 0.3, 0.3)
			mesh_instance.material_override = material
	
	# Reset all hazards
	for hazard in hazards:
		hazard.affected_players.clear()
		hazard.damage_per_second = 0.0
	
	# Reset ramps
	ramp_sequence_index = 0
	current_ramp = null
	
	# Reset enemies
	if enemy_spawner:
		enemy_spawner.clear_enemies()

func enter_next_ramp() -> void:
	if ramp_sequence_index >= ramps.size():
		return
	
	ramp_sequence_index += 1
	current_ramp = ramps[ramp_sequence_index - 1]
	if current_ramp:
		ramp_entered.emit(current_ramp)

func exit_current_ramp() -> void:
	if current_ramp:
		ramp_exited.emit(current_ramp)
		current_ramp = null

func activate_all_checkpoints() -> void:
	for checkpoint in checkpoints:
		if not checkpoint.is_active:
			checkpoint.activate()

func deactivate_all_checkpoints() -> void:
	for checkpoint in checkpoints:
		checkpoint.deactivate()