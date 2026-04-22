extends Node
class_name SpeedrunTimer

## SpeedrunTimer - Precise timing system for speedrunning
##
## Implements professional segmented timing with:
## - Millisecond precision
## - Split checkpoints
## - Ghost replay data capture
## - Practice mode with instant restart
## - Best times tracking
##
## Sources:
## - World of Speedrun Records (timing standards)
## - Speedrun.com API reference
## - CS:GO surf meta (timing conventions)

signal split_reached(checkpoint: int, time: float)
signal segment_complete(segment_name: String, time: float)
signal run_completed(time: float, checkpoints_reached: int)
signal best_time_updated(checkpoint: int, time: float)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Timing Settings")
@export var use_high_precision: bool = true
@export var tick_rate: float = 300.0
@export var delta_per_tick: float = 1.0 / 300.0

@export_group("Checkpoints")
@export var checkpoints: Array[Dictionary] = []
@export var default_checkpoint_name: String = "checkpoint"
@export var checkpoint_radius: float = 0.5

@export_group("Best Times")
@export var save_best_times: bool = true
@export var max_best_times: int = 5

# =============================================================================
# STATE
# =============================================================================

var _start_time: int = 0
var _split_times: Dictionary = {}
var _segment_times: Dictionary = {}
var _checkpoint_count: int = 0
var _is_practice_mode: bool = false
var _last_segment_time: float = 0.0
var _delta_time: float = 0.0

# Ghost replay data
var _ghost_data: Array = []
var _ghost_start_time: int = 0
var _ghost_state: Dictionary = {}

# Best times (persisted)
static var _best_times: Dictionary = {}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Load saved best times
	_load_best_times()


func _physics_process(delta: float) -> void:
	# Update delta time
	_delta_time = delta


# =============================================================================
# START/STOP
# =============================================================================

func start_timer() -> void:
	"""
	Start the speedrun timer with high-precision timing.
	"""
	if _is_practice_mode:
		return
	
	_start_time = Time.get_ticks_msec()
	_checkpoint_count = 0
	_split_times.clear()
	_segment_times.clear()
	
	ghost_start_time = _start_time
	ghost_state = {
		"start_time": _start_time,
		"checkpoint_count": 0,
		"current_checkpoint": "",
		"segments": []
	}
	
	print("[Timer] Started at tick " + str(_start_time / 1000.0))


func stop_timer() -> void:
	"""
	Stop the timer and finalize results.
	"""
	if _is_practice_mode:
		return
	
	var end_time: int = Time.get_ticks_msec()
	var total_time: float = end_time - _start_time
	
	run_completed.emit(total_time, _checkpoint_count)
	
	# Save best times
	if save_best_times:
		_save_best_times()
	
	print("[Timer] Finished: " + str(total_time) + "ms, Checkpoints: " + str(_checkpoint_count))


func reset_timer() -> void:
	"""
	Reset timer without stopping (for instant restart).
	"""
	_start_time = 0
	_checkpoint_count = 0
	_split_times.clear()
	_segment_times.clear()
	_ghost_data.clear()
	_ghost_start_time = 0


# =============================================================================
# SPLIT CHECKPOINTS
# =============================================================================

func check_split_checkpoint(position: Vector3, name: String = "") -> void:
	"""
	Check if player is at a split checkpoint.
	Captures split time and advances checkpoint count.
	"""
	var player_name: String = "Player"
	if get_tree().get_first_node_in_group("players"):
		var player := get_tree().get_first_node_in_group("players")
		if player:
			player_name = player.name
	
	# Find matching checkpoint
	for checkpoint in checkpoints:
		if name != "" and checkpoint.get("name", "") != name:
			continue
		
		var cp_position: Vector3 = checkpoint["position"]
		var distance := position.distance_to(cp_position)
		
		if distance < checkpoint_radius:
			# Record split time
			var end_time: int = Time.get_ticks_msec()
			var split_time: float = end_time - _start_time
			_checkpoint_count += 1
			
			split_reached.emit(_checkpoint_count, split_time)
			
			# Record segment time
			if _checkpoint_count > 1:
				var previous_checkpoint := checkpoints[_checkpoint_count - 2]
				var segment_time := split_time - _split_times.get(previous_checkpoint.get("name", ""), 0.0)
				_segment_times[_checkpoint_count - 1] = segment_time
				segment_complete.emit(previous_checkpoint.get("name", "Segment " + str(_checkpoint_count - 1)), segment_time)
			
			# Record ghost data
			_ghost_data.append({
				"tick": _checkpoint_count,
				"position": position,
				"time": split_time,
				"segment": _checkpoint_count
			})
			
			# Update ghost state
			_ghost_state["checkpoint_count"] = _checkpoint_count
			_ghost_state["current_checkpoint"] = name
			_ghost_state["segments"].append({
				"name": previous_checkpoint.get("name", "Segment " + str(_checkpoint_count - 1)),
				"time": segment_time
			})
			
			# Emit best time signal
			if save_best_times:
				var checkpoint_name: String = name if name != "" else "checkpoint_" + str(_checkpoint_count)
				var current_best: float = _best_times.get(checkpoint_name, float(INF))
				if split_time < current_best:
					_best_times[checkpoint_name] = split_time
					best_time_updated.emit(_checkpoint_count, split_time)
			
			return
	
	# Check if reached all checkpoints (last one)
	if _checkpoint_count >= checkpoints.size() and checkpoints.size() > 0:
		stop_timer()


# =============================================================================
# PRACTICE MODE
# =============================================================================

func enable_practice_mode() -> void:
	"""Enable instant restart mode for practice."""
	_is_practice_mode = true
	print("[Timer] Practice mode enabled - instant restart active")


func disable_practice_mode() -> void:
	"""Disable practice mode."""
	_is_practice_mode = false
	print("[Timer] Practice mode disabled")


func instant_restart() -> void:
	"""
	Instant restart for practice mode.
	Zeroes out all timing without showing UI.
	"""
	if _is_practice_mode:
		reset_timer()
		_start_time = Time.get_ticks_msec()
		_checkpoint_count = 0
		_ghost_data.clear()
		_ghost_start_time = _start_time
		print("[Timer] Instant restart")


func is_practice_mode() -> bool:
	return _is_practice_mode


# =============================================================================
# GHOST REPLAY
# =============================================================================

func get_ghost_data() -> Array:
	"""Get complete ghost replay data"""
	return _ghost_data


func save_ghost() -> void:
	"""Save current ghost data to file"""
	var save_data: Dictionary = {
		"start_time": _ghost_start_time,
		"end_time": Time.get_ticks_msec(),
		"total_ticks": _ghost_data.size(),
		"checkpoints": checkpoints.size(),
		"data": _ghost_data
	}
	
	var save_path := "user://ghosts/ghost_" + str(_ghost_data.size()) + ".json"
	var file := File.new()
	if file.open(save_path, File.WRITE) != ERROR_OK:
		print("[Timer] Failed to save ghost:", file.get_error())
	else:
		var json_string := JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("[Timer] Ghost saved to:", save_path)


func load_ghost(path: String) -> bool:
	"""Load ghost data from file"""
	var file := File.new()
	if file.open(path, File.READ) != ERROR_OK:
		print("[Timer] Failed to load ghost:", file.get_error())
		return false
	
	var json_string := file.get_string()
	file.close()
	
	var json := JSON.parse_string(json_string)
	if json == null:
		return false
	
	_ghost_data = json.get("data", [])
	_ghost_start_time = json.get("start_time", Time.get_ticks_msec())
	_ghost_state["segments"] = json.get("data", [])
	
	print("[Timer] Ghost loaded:", json.get("total_ticks", 0), "ticks")
	return true


func clear_ghost() -> void:
	"""Clear ghost replay data"""
	_ghost_data.clear()
	_ghost_start_time = 0
	_ghost_state.clear()


# =============================================================================
# BEST TIMES
# =============================================================================

func _save_best_times() -> void:
	if not save_best_times:
		return
	
	var save_data: Array = []
	for key in _best_times:
		var time: float = _best_times[key]
		var split_name: String = key
		if split_name.begins_with("checkpoint_"):
			var cp_number := int(split_name.replace("checkpoint_", ""))
			if cp_number <= _checkpoint_count:
				save_data.append({
					"name": split_name,
					"time": time,
					"count": _checkpoint_count
				})
		elif key.begins_with("segment_"):
			var segment_num := int(key.replace("segment_", ""))
			if _checkpoint_count > segment_num:
				save_data.append({
					"name": key,
					"time": time,
					"count": _checkpoint_count
				})
	
	# Sort by time
	save_data.sort_custom(func(a, b): return a["time"] < b["time"])
	
	# Keep only top N
	save_data = save_data.slice(0, max_best_times)
	
	# Save to file
	var save_path := "user://speedrun/best_times.json"
	var file := File.new()
	if file.open(save_path, File.WRITE) != ERROR_OK:
		return
	
	var json_string := JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	# Also update static array
	_best_times.clear()
	for item in save_data:
		_best_times[item["name"]] = item["time"]
	
	print("[Timer] Best times saved to:", save_path)


func _load_best_times() -> void:
	var save_path := "user://speedrun/best_times.json"
	var file := File.new()
	if file.open(save_path, File.READ) != ERROR_OK:
		return
	
	var json_string := file.get_string()
	file.close()
	
	var json := JSON.parse_string(json_string)
	if json == null:
		return
	
	for item in json:
		_best_times[item["name"]] = item["time"]


func get_best_times() -> Array:
	"""Get best times for all checkpoints"""
	var times: Array = []
	for checkpoint in checkpoints:
		var name: String = checkpoint.get("name", "checkpoint")
		if name.begins_with("checkpoint_"):
			var cp_number := int(name.replace("checkpoint_", ""))
			var time: float = _best_times.get(name, 0.0)
			times.append({
				"name": name,
				"time": time,
				"target": checkpoint.get("position", Vector3.ZERO),
				"radius": checkpoint_radius
			})
	return times


# =============================================================================
# UTILITY
# =============================================================================

func get_elapsed_time() -> float:
	"""Get current elapsed time in milliseconds"""
	if _start_time == 0:
		return 0.0
	var current_time: int = Time.get_ticks_msec()
	return current_time - _start_time


func get_elapsed_time_seconds() -> float:
	"""Get current elapsed time in seconds"""
	return get_elapsed_time() / 1000.0


func get_checkpoint_time(checkpoint_index: int) -> float:
	"""Get time for specific checkpoint"""
	var name: String = "checkpoint_" + str(checkpoint_index)
	return _best_times.get(name, float(INF))


func format_time(time_ms: float) -> String:
	"""Format milliseconds as MM:SS.ms"""
	var seconds: int = int(time_ms / 1000)
	var millis: int = int(time_ms) % 1000
	var minutes: int = seconds / 60
	var secs: int = seconds % 60
	return "%02d:%02d.%03d" % [minutes, secs, millis]


func get_full_timing_data() -> Dictionary:
	"""Get complete timing information"""
	return {
		"start_time": _start_time,
		"elapsed_time": get_elapsed_time(),
		"elapsed_seconds": get_elapsed_time_seconds(),
		"checkpoint_count": _checkpoint_count,
		"total_checkpoints": checkpoints.size(),
		"split_times": _split_times,
		"segment_times": _segment_times,
		"best_times": _best_times,
		"ghost_data_count": _ghost_data.size()
	}