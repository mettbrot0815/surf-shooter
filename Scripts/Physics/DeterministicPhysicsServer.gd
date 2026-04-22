extends Node
class_name DeterministicPhysicsServer

## DeterministicPhysicsServer - 300Hz Physics Engine for Surf Shooter
##
## Implements deterministic physics simulation at 300Hz (3.33ms per tick)
## for consistent multi-client gameplay and ghost replay functionality.

signal physics_tick_completed(tick: int, delta: float)
signal state_snapshot_ready(snapshot: Dictionary)
signal state_rolled_back(tick: int, target_tick: int)
signal network_synchronized(tick: int)
signal simulation_paused()
signal simulation_resumed()

# =============================================================================
# CONFIGURATION
# =============================================================================

@export var physics_tick_rate: float = 300.0
@export var physics_time_step: float = 0.00333333
@export var max_network_lag: float = 0.250000
@export var prediction_horizon: float = 0.100000
@export var rollback_buffer_size: int = 150
@export var network_sync_rate: float = 60.0
@export var compression_quality: int = 2

# =============================================================================
# STATE - Physics simulation state
# =============================================================================

var current_tick: int = 0
var tick_counter: int = 0
var accumulated_delta: float = 0.0
var last_physics_time: float = 0.0
var target_tick: int = 0

# Network state
var network_tick: int = 0
var predicted_tick: int = 0
var sync_buffer: Array = []
var latest_client_state: Dictionary = {}

# Rollback buffer for deterministic replay
var rollback_buffer: Array = []
var rollback_index: int = 0

# Simulation state
var is_paused: bool = false
var is_running: bool = false
var last_network_sync_time: float = 0.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Initialize the physics server
	# In Godot 4.x, physics runs automatically, so we just manage state
	last_physics_time = Time.get_ticks_msec()
	
	# Set up network sync timer
	if not has_node("NetworkSyncTimer"):
		var timer := Timer.new()
		timer.one_shot = false
		timer.wait_time = 1.0 / network_sync_rate
		timer.timeout.connect(_on_network_sync_timer_timeout)
		add_child(timer)
		timer.start()


func _process(delta: float) -> void:
	# Handle network synchronization
	if Time.get_ticks_msec() - last_network_sync_time >= 1000.0:
		_network_sync()
		last_network_sync_time = Time.get_ticks_msec()
	
	# Update tick counter
	tick_counter += 1
	
	# Run physics steps
	while accumulated_delta >= physics_time_step:
		if not is_paused and is_running:
			run_physics_step(physics_time_step)
			accumulated_delta -= physics_time_step
			target_tick += 1
		else:
			break


func _network_sync() -> void:
	# Sync with network tick
	network_tick = current_tick
	sync_buffer.clear()
	sync_buffer.append({"tick": network_tick, "timestamp": Time.get_ticks_msec()})


# =============================================================================
# PHYSICS STEP - Main physics loop
# =============================================================================

func run_physics_step(delta: float) -> void:
	"""
	Runs a single physics step at fixed timestep.
	This method captures the current state and emits signals for:
	- Physics tick completion (for deterministic replay)
	- State snapshots (for networking and rollback)
	"""
	
	# Create state snapshot
	var snapshot: Dictionary = {}
	snapshot["tick"] = current_tick
	snapshot["timestamp"] = Time.get_ticks_msec()
	snapshot["delta"] = delta
	
	# Capture all player states
	var player_states: Array = []
	var players := get_tree().get_nodes_in_group("players")
	
	for player in players:
		if player.has_method("get_physics_state"):
			var player_state: Dictionary = player.get_physics_state()
			player_state["player_id"] = player.name
			player_states.append(player_state)
	
	snapshot["players"] = player_states
	
	# Store in rollback buffer
	if rollback_index < rollback_buffer_size:
		rollback_buffer.append(snapshot)
		rollback_index = min(rollback_index + 1, rollback_buffer_size)
	
	# Emit signals
	physics_tick_completed.emit(current_tick, delta)
	state_snapshot_ready.emit(snapshot)
	
	# Increment tick
	current_tick += 1


# =============================================================================
# DETERMINISTIC REPLAY - Rollback functionality
# =============================================================================

func rollback_to_tick(target_tick: int) -> void:
	"""
	Rollback simulation to a previous tick for deterministic replay.
	This enables:
	- Anti-cheat (reversing suspicious actions)
	- Ghost replay systems
	- Deterministic debugging
	"""
	
	if target_tick >= current_tick:
		return  # Already at or past target
	
	if target_tick < 0:
		target_tick = 0
	
	# Find the closest available state
	var closest_tick: int = current_tick
	for i in range(current_tick - 1, max(0, target_tick - 10), -1):
		if rollback_buffer.size() > i:
			closest_tick = i
			break
	
	# Emit rollback event
	state_rolled_back.emit(current_tick, closest_tick)
	
	# Apply rollback state
	if closest_tick >= 0 and rollback_buffer.size() > closest_tick:
		var rollback_state: Dictionary = rollback_buffer[closest_tick]
		_apply_state(rollback_state)
		
		# Jump back to target tick
		current_tick = closest_tick
	
	# Clamp target
	if target_tick > current_tick:
		target_tick = current_tick
		# Fast forward if needed
		while current_tick < target_tick:
			run_physics_step(physics_time_step)


func fast_forward_to_tick(target_tick: int) -> void:
	"""
	Fast forward simulation to a future tick.
	Useful for skipping ahead in replays.
	"""
	
	while current_tick < target_tick:
		run_physics_step(physics_time_step)


func _apply_state(state: Dictionary) -> void:
	"""
	Applies a physics state snapshot to all players.
	This is used for rollback and replay.
	"""
	
	var players := get_tree().get_nodes_in_group("players")
	
	for player in players:
		if player.has_method("apply_state"):
			player.apply_state(state.get("player_states", {}))
	
	network_synchronized.emit(current_tick)


# =============================================================================
# PAUSE/RESUME CONTROL
# =============================================================================

func pause() -> void:
	is_paused = true
	simulation_paused.emit()


func resume() -> void:
	is_paused = false
	simulation_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume()
	else:
		pause()


# =============================================================================
# TIME MANAGEMENT - Deterministic time control
# =============================================================================

func get_current_time() -> float:
	"""Returns current simulated time in seconds"""
	return float(current_tick) * physics_time_step


func get_current_tick() -> int:
	"""Returns current physics tick count"""
	return current_tick


func get_tick_rate() -> float:
	"""Returns physics tick rate in Hz"""
	return physics_tick_rate


# =============================================================================
# STATE QUERY - External access to physics state
# =============================================================================

func get_physics_state() -> Dictionary:
	"""Returns current physics state for external inspection"""
	return {
		"tick": current_tick,
		"timestamp": Time.get_ticks_msec(),
		"accumulated_delta": accumulated_delta,
		"target_tick": target_tick,
		"network_tick": network_tick,
		"is_paused": is_paused,
		"is_running": is_running,
		"players_count": get_tree().get_nodes_in_group("players").size()
	}


func get_rollback_buffer() -> Array:
	"""Returns the rollback buffer for inspection"""
	return rollback_buffer


func get_last_state() -> Dictionary:
	"""Returns the last captured state snapshot"""
	if sync_buffer.size() > 0:
		return sync_buffer[sync_buffer.size() - 1]
	return {}


# =============================================================================
# NETWORKING - Client prediction and synchronization
# =============================================================================

func predict_current_state() -> Dictionary:
	"""
	Returns predicted current state based on network lag compensation.
	This allows for smooth client prediction.
	"""
	var prediction_time: float = Time.get_ticks_msec() - max_network_lag * 1000.0
	
	# Find closest state to prediction time
	var closest_state: Dictionary = {}
	var time_diff: float = float(INF)
	
	for i in range(sync_buffer.size()):
		var state := sync_buffer[i]
		var state_time: float = state.get("timestamp", Time.get_ticks_msec())
		var diff: float = abs(float(state_time) - prediction_time)
		
		if diff < time_diff:
			time_diff = diff
			closest_state = state
	
	return closest_state


func synchronize_with_network(lag: float = 0.0) -> void:
	"""
	Synchronizes local state with network data.
	lag: Network lag in seconds
	"""
	var predicted_state := predict_current_state()
	network_tick = predicted_state.get("tick", current_tick)


# =============================================================================
# DEBUG - Utility functions
# =============================================================================

func _on_network_sync_timer_timeout() -> void:
	# Periodic network sync
	_network_sync()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if physics_tick_rate < 60.0:
		warnings.append("Physics tick rate too low for smooth movement")
	
	if physics_time_step > 1.0 / physics_tick_rate:
		warnings.append("Physics time step doesn't match tick rate")
	
	return warnings


func _draw() -> void:
	# Draw debug overlay
	var debug_color := Color.RED
	if is_paused:
		debug_color = Color.YELLOW
	
	# Draw current tick
	draw_string(
		global_transform,
		"Tick: " + str(current_tick) + " | " + str(tick_counter),
		Vector2(10, 10),
		Vector2.ONE,
		0,
		debug_color
	)
	
	# Draw delta time
	var delta_ms := str(accumulated_delta * 1000.0)
	draw_string(
		global_transform,
		"Delta: " + delta_ms + "ms",
		Vector2(10, 30),
		Vector2.ONE,
		0,
		debug_color
	)
	
	# Draw network sync status
	if sync_buffer.size() > 0:
		var last_sync := sync_buffer[sync_buffer.size() - 1].get("tick", 0)
		draw_string(
			global_transform,
			"Net: " + str(last_sync) + " | Pred: " + str(predicted_tick),
			Vector2(10, 50),
			Vector2.ONE,
			0,
			Color.CYAN
		)