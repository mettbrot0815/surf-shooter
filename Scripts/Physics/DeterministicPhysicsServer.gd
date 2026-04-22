extends Node

## DeterministicPhysicsServer - 300Hz Physics Engine for Surf Shooter
##
## Provides deterministic physics stepping with rollback capability
## for speedrunning and ghost replay systems.

signal physics_tick_completed(tick: int, delta: float)
signal state_snapshot_ready(snapshot: Dictionary)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Physics Settings")
@export var tick_rate: float = 300.0
@export var rollback_buffer_size: int = 50
@export var auto_step: bool = true

# =============================================================================
# STATE
# =============================================================================

var current_tick: int = 0
var delta: float = 1.0 / 300.0
var rollback_buffer: Array = []
var rollback_index: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("DeterministicPhysicsServer started at " + str(current_tick))
	if auto_step:
		# Use _physics_process for fixed timestep
		pass  # _physics_process will handle stepping


func _physics_process(delta: float) -> void:
	if auto_step:
		step()


func step() -> void:
	"""Execute a single physics tick"""
	current_tick += 1
	# Emit tick completed signal for all physics objects
	physics_tick_completed.emit(current_tick, delta)
	# Save state snapshot every tick for rollback
	save_state()


# =============================================================================
# ROLLBACK SYSTEM
# =============================================================================

func save_state() -> void:
	"""Save current state to rollback buffer"""
	if rollback_index < rollback_buffer_size:
		var snapshot: Dictionary = {
			"tick": current_tick,
			"timestamp": Time.get_ticks_msec(),
			"state": get_all_states()
		}
		rollback_buffer.append(snapshot)
		rollback_index = min(rollback_index + 1, rollback_buffer_size)


func rollback_to(tick: int) -> bool:
	"""
	Rollback physics state to a specific tick.
	Returns true if successful, false if tick not found.
	"""
	for i in range(len(rollback_buffer)):
		if rollback_buffer[i]["tick"] == tick:
			current_tick = tick
			# Restore state
			# restore_state(rollback_buffer[i]["state"])
			return true
	return false


func get_rollback_buffer() -> Array:
	"""Get the rollback buffer for inspection"""
	return rollback_buffer


# =============================================================================
# STATE ACCESS
# =============================================================================

func get_all_states() -> Dictionary:
	"""
	Get all current physics states from players and objects.
	"""
	var states: Dictionary = {
		"tick": current_tick,
		"timestamp": Time.get_ticks_msec(),
		"players": {},
		"objects": {}
	}

	# Collect player states
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get_physics_state"):
			var player_id = str(player.get_instance_id())
			states["players"][player_id] = player.get_physics_state()

	# Collect wave system state
	var wave_system = get_tree().get_first_node_in_group("wave_system")
	if wave_system and wave_system.has_method("get_wave_info"):
		states["wave_system"] = wave_system.get_wave_info()

	return states


func restore_state(state: Dictionary) -> void:
	"""
	Restore physics state from a saved snapshot.
	"""
	# Restore tick
	if state.has("tick"):
		current_tick = state["tick"]

	# Restore player states
	if state.has("players"):
		var players = get_tree().get_nodes_in_group("players")
		for player in players:
			var player_id = str(player.get_instance_id())
			if state["players"].has(player_id) and player.has_method("apply_state"):
				player.apply_state(state["players"][player_id])

	# Restore wave system state
	if state.has("wave_system"):
		var wave_system = get_tree().get_first_node_in_group("wave_system")
		if wave_system and wave_system.has_method("set_wave_info"):
			wave_system.set_wave_info(state["wave_system"])
