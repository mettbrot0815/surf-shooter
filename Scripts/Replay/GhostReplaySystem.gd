extends Node
class_name GhostReplaySystem

## GhostReplaySystem - Deterministic ghost replay for speedrunning
##
## Features:
## - Frame-accurate replay recording
## - Input buffering for smooth playback
## - Variable speed playback
## - Replay trimming and optimization
## - Replay preview system
##
## Sources:
## - Source engine demo replay format
## - Speedrunning ghost replay standards

signal replay_recorded(filename: String, duration: float)
signal replay_playback_started()
signal replay_playback_finished()
signal replay_preview_available(filename: String, preview_data: Dictionary)
signal replay_saved(filename: String)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Recording")
@export var max_replay_duration: float = 120.0    ## Max recording time (seconds)
@export var max_input_buffer_size: int = 120     ## Max buffered inputs (ticks)
@export var physics_tick_rate: float = 300.0     ## Physics tick rate
@export var input_buffer_delta: float = 1.0 / 300.0  ## Buffer delta time

@export_group("Playback")
@export var playback_speed_multiplier: float = 1.0  ## Current playback speed
@export var max_playback_speed: float = 3.0   ## Max allowed speed (1x normal, 3x fast)
@export var preview_duration: float = 5.0   ## Preview duration before full playback

@export_group("Compression")
@export var compress_inputs: bool = true  ## Compress input data
@export var compression_quality: int = 2  ## Compression level (1-5)

@export_group("Debug")
@export var show_debug_overlay: bool = false
@export var log_replay_events: bool = false

# =============================================================================
# STATE
# =============================================================================

var _is_recording: bool = false
var _is_playing: bool = false
var _is_previewing: bool = false
var _input_buffer: Array = []
var _replay_data: Dictionary = {}
var _last_input_tick: int = 0
var _preview_data: Dictionary = {}
var _preview_position: Vector3 = Vector3.ZERO
var _preview_rotation: Quaternion = Quaternion.IDENTITY
var _preview_velocity: Vector3 = Vector3.ZERO
var _preview_tick: int = 0

var _buffer_time: float = 0.0
var _recording_start_time: float = 0.0
var _playback_position: float = 0.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Subscribe to physics events for recording
	_replay_system = DeterministicPhysicsServer.get_instance()
	if _replay_system:
		_replay_system.physics_tick_completed.connect(_on_physics_tick)


func _process(_delta: float) -> void:
	# Handle preview timer
	if _is_previewing:
		_preview_timer -= _delta
		if _preview_timer <= 0:
			_start_full_playback()

	# Handle playback
	if _is_playing and _replay_data.has("ticks"):
		var ticks: Array = _replay_data["ticks"]
		if _preview_tick < ticks.size():
			var tick_data: Dictionary = ticks[_preview_tick]
			# Restore state for this tick
			if _replay_system and tick_data.has("state"):
				_replay_system.restore_state(tick_data["state"])

			_preview_tick += 1
		else:
			stop_playback()


# =============================================================================
# REPLAY SYSTEM REFERENCE
# =============================================================================

var _replay_system: Node = null


# =============================================================================
# RECORDING
# =============================================================================

func start_recording() -> void:
	"""Start recording ghost replay"""
	if _is_recording:
		return

	_is_recording = true
	_is_playing = false
	_is_previewing = false
	_input_buffer.clear()
	_replay_data.clear()
	_last_input_tick = 0
	_buffer_time = 0.0
	_recording_start_time = Time.get_ticks_msec() / 1000.0

	# Connect to physics server for state snapshots
	if _replay_system:
		_replay_system.physics_tick_completed.connect(_on_physics_tick)

	if log_replay_events:
		print("[Ghost] Recording started at " + str(_recording_start_time))


func stop_recording() -> void:
	"""Stop recording ghost replay"""
	if not _is_recording:
		return
	
	_is_recording = false
	var duration: float = Time.get_ticks_msec() / 1000.0 - _recording_start_time
	
	# Validate recording
	if duration > max_replay_duration:
		var trimmed_data: Dictionary = _compress_inputs()
		_save_replay(trimmed_data, true)
	else:
		_save_replay(_replay_data, false)
	
	replay_recorded.emit(_last_filename, duration)


func _compress_inputs() -> Dictionary:
	"""Compress input data for smaller replay files"""
	var compressed: Dictionary = {}
	
	if not compress_inputs:
		return _replay_data
	
	# Group inputs by tick
	var input_by_tick: Dictionary = {}
	for input in _input_buffer:
		var tick: int = input.get("tick", 0)
		if not input_by_tick.has(tick):
			input_by_tick[tick] = []
		input_by_tick[tick].append(input)
	
	# Compress by removing redundant inputs
	for tick in input_by_tick:
		var inputs := input_by_tick[tick]
		var compressed_inputs := []
		
		for i in range(inputs.size()):
			if i == 0:
				compressed_inputs.append(inputs[i])
			elif inputs[i] != inputs[i-1]:
				compressed_inputs.append(inputs[i])
		
		input_by_tick[tick] = compressed_inputs
	
	# Convert back to array
	var compressed_data: Array = []
	for tick in input_by_tick:
		compressed_data.append({
			"tick": tick,
			"inputs": input_by_tick[tick]
		})
	
	return {"ticks": compressed_data}


func _save_replay(data: Dictionary, is_compressed: bool) -> void:
	"""Save replay data to file"""
	var filename: String = "replays/ghost_" + str(Time.get_ticks_msec()) + "_" + str(int(_recording_start_time)) + ".json"
	if is_compressed:
		filename = "replays/ghost_" + str(Time.get_ticks_msec()) + "_compressed.json"
	
	var save_data: Dictionary = {
		"start_time": _recording_start_time,
		"duration": Time.get_ticks_msec() / 1000.0 - _recording_start_time,
		"compression": is_compressed,
		"data": data
	}
	
	var file: File = File.new()
	if file.open(filename, File.WRITE) != File.ERROR_OK:
		print("[Ghost] Failed to save replay:", file.get_error())
		return
	
	var json_string: String = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	_last_filename = filename
	replay_saved.emit(filename)
	print("[Ghost] Saved replay to:", filename)


func get_last_filename() -> String:
	return _last_filename


var _last_filename: String = ""


# =============================================================================
# PLAYBACK
# =============================================================================

func start_playback(filename: String, speed: float = 1.0) -> void:
	"""Start playback of saved replay"""
	var file: FileAccess = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		print("[Ghost] Failed to open replay:", filename)
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json = JSON.parse_string(json_string)
	if json == null:
		print("[Ghost] Failed to parse replay JSON")
		return

	_replay_data = json["data"]
	var ticks: Array = _replay_data.get("ticks", [])
	var start_time: float = _replay_data.get("start_time", 0.0)
	var duration: float = _replay_data.get("duration", 0.0)

	_playback_speed_multiplier = clampf(speed, 0.5, max_playback_speed)
	_playback_position = 0.0
	_is_playing = true
	_is_previewing = false
	_preview_tick = 0

	replay_playback_started.emit()
	print("[Ghost] Started playback of", ticks.size(), "ticks")


func pause_playback() -> void:
	"""Pause current playback"""
	if _is_playing:
		_is_playing = false
		get_tree().paused = true


func resume_playback() -> void:
	"""Resume paused playback"""
	if _is_playing:
		get_tree().paused = false


func stop_playback() -> void:
	"""Stop current playback"""
	if _is_playing:
		_is_playing = false
		get_tree().paused = false
		_playback_position = 0.0


func seek_to_time(time: float) -> void:
	"""Seek to specific time in replay"""
	_playback_position = clampf(time, 0.0, _replay_data.get("duration", 0.0))


func set_playback_speed(speed: float) -> void:
	"""Set playback speed"""
	_playback_speed_multiplier = clampf(speed, 0.5, max_playback_speed)


# =============================================================================
# PREVIEW
# =============================================================================

func preview_replay(filename: String) -> void:
	"""Preview replay before playing"""
	var file: File = File.new()
	if file.open(filename, File.READ) != File.ERROR_OK:
		return
	
	var json_string: String = file.get_string()
	file.close()
	
	var json: Dictionary = JSON.parse_string(json_string)
	var replay_data: Dictionary = json["data"]
	var ticks: Array = replay_data.get("ticks", [])
	
	# Get preview data from first few ticks
	var preview_data: Dictionary = {
		"ticks": [],
		"positions": [],
		"rotations": [],
		"velocities": []
	}
	
	var preview_ticks := min(60, ticks.size())
	for i in range(preview_ticks):
		var tick_data: Dictionary = ticks[i]
		preview_data["ticks"].append(tick_data)
		
		# Get player position from tick data
		for player_state in tick_data.get("states", []):
			if player_state.has("position"):
				preview_data["positions"].append(player_state["position"])
				preview_data["rotations"].append(player_state.get("rotation", Quaternion.IDENTITY))
				preview_data["velocities"].append(player_state.get("velocity", Vector3.ZERO))
				preview_data["tick"] = tick_data.get("tick", i)
				break
	
	_preview_data = preview_data
	replay_preview_available.emit(filename, preview_data)


func start_preview() -> void:
	"""Start preview of last saved replay"""
	var filename: String = get_last_filename()
	if filename == "":
		return
	
	preview_replay(filename)
	_is_previewing = true
	_preview_timer = preview_duration
	
	# Load and display preview
	if _preview_data.has("positions") and _preview_data["positions"].size() > 0:
		_preview_position = _preview_data["positions"][0]
		_preview_rotation = _preview_data["rotations"][0]
		_preview_velocity = _preview_data["velocities"][0]
		_preview_tick = _preview_data.get("tick", 0)
		
		# Apply preview transform to player
		var player: CharacterBody3D = get_tree().get_first_node_in_group("players")
		if player:
			player.global_position = _preview_position
			player.rotation = _preview_rotation
			player.velocity = _preview_velocity


# =============================================================================
# INPUT BUFFERING
# =============================================================================

func add_input_to_buffer(input_data: Dictionary) -> void:
	"""Add input data to buffer for playback"""
	var now: int = Time.get_ticks_msec()
	var tick: int = int(now / input_buffer_delta)
	
	input_data["tick"] = tick
	input_data["timestamp"] = now
	
	# Add to buffer
	if _is_recording:
		_input_buffer.append(input_data)
		_last_input_tick = tick
	
	# Limit buffer size
	while _input_buffer.size() > max_input_buffer_size:
		_input_buffer.pop_front()


func get_buffered_inputs() -> Array:
	"""Get all buffered inputs"""
	return _input_buffer


func get_last_input() -> Dictionary:
	"""Get most recent input"""
	if _input_buffer.is_empty():
		return {}
	return _input_buffer[-1]


# =============================================================================
# REPLAY SYSTEM EVENTS
# =============================================================================

func _on_physics_tick(tick: int, delta: float) -> void:
	"""Handle physics tick for recording inputs and states"""
	if _is_recording:
		# Record state snapshot every tick
		var state_snapshot = _replay_system.get_all_states()
		var tick_data = {
			"tick": tick,
			"timestamp": Time.get_ticks_msec(),
			"state": state_snapshot
		}
		if not _replay_data.has("ticks"):
			_replay_data["ticks"] = []
		_replay_data["ticks"].append(tick_data)


# =============================================================================
# DEBUG
# =============================================================================

func _draw() -> void:
	if not show_debug_overlay:
		return
	
	# Draw recording status
	var color := Color.GREEN
	if _is_playing:
		color = Color.BLUE
	if _is_previewing:
		color = Color.CYAN
	
	draw_string(
		_get_local_transform(),
		"Ghost: " + str(color) + str(color) + "Recording" if _is_recording else str(color) + str(color) + "Playing" if _is_playing else str(color) + str(color) + "Preview" if _is_previewing else str(color) + str(color) + "Ready",
		Vector2(10, 10),
		Vector2.ONE,
		0,
		color,
		Size2.ONE
	)
	
	# Draw buffer info
	var buffer_count := _input_buffer.size()
	draw_string(
		_get_local_transform(),
		"Buffer: " + str(buffer_count) + " inputs",
		Vector2(10, 30),
		Vector2.ONE,
		0,
		Color.WHITE,
		Size2.ONE
	)
	
	# Draw playback position
	if _is_playing:
		var pos := str(_playback_position) + "s / " + str(_replay_data.get("duration", 0)) + "s"
		draw_string(
			_get_local_transform(),
			pos,
			Vector2(10, 50),
			Vector2.ONE,
			0,
			Color.YELLOW,
			Size2.ONE
		)