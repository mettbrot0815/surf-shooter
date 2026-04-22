extends Node
class_name SpeedrunTimer

## SpeedrunTimer - High-precision timer for surf shooter speedruns

signal timer_started()
signal timer_stopped(time_ms: int)
signal split_completed(split_name: String, time_ms: int)
signal practice_mode_toggled(enabled: bool)

@export var start_zone_position: Vector3 = Vector3.ZERO
@export var start_zone_radius: float = 5.0
@export var end_zone_position: Vector3 = Vector3(100, 0, 0)
@export var end_zone_radius: float = 5.0

var _is_running: bool = false
var _is_practice_mode: bool = false
var _start_time: int = 0
var _current_time: int = 0
var _splits: Dictionary = {}
var _split_times: Array[int] = []
var _best_time: int = -1

func _ready() -> void:
	add_to_group("speedrun_timer")

func _process(_delta: float) -> void:
	if _is_running:
		_current_time = Time.get_ticks_msec() - _start_time

func start_timer() -> void:
	if _is_running:
		return
	_is_running = true
	_start_time = Time.get_ticks_msec()
	_current_time = 0
	_splits.clear()
	_split_times.clear()
	timer_started.emit()
	print("Timer started")

func stop_timer() -> void:
	if not _is_running:
		return
	_is_running = false
	var final_time = _current_time
	timer_stopped.emit(final_time)
	if _best_time == -1 or final_time < _best_time:
		_best_time = final_time
	print("Timer stopped: %d ms" % final_time)

func add_split(split_name: String, position: Vector3) -> void:
	if not _is_running:
		return
	var split_time = _current_time
	_splits[split_name] = {
		"time": split_time,
		"position": position
	}
	_split_times.append(split_time)
	split_completed.emit(split_name, split_time)
	print("Split '%s' at %d ms" % [split_name, split_time])

func enable_practice_mode() -> void:
	_is_practice_mode = true
	practice_mode_toggled.emit(true)
	print("Practice mode enabled")

func disable_practice_mode() -> void:
	_is_practice_mode = false
	practice_mode_toggled.emit(false)
	print("Practice mode disabled")

func instant_restart() -> void:
	if not _is_practice_mode:
		return
	stop_timer()
	reset_timer()
	print("Instant restart")

func reset_timer() -> void:
	_is_running = false
	_current_time = 0
	_splits.clear()
	_split_times.clear()

func is_running() -> bool:
	return _is_running

func is_practice_mode() -> bool:
	return _is_practice_mode

func get_current_time() -> int:
	return _current_time

func get_best_time() -> int:
	return _best_time

func get_splits() -> Dictionary:
	return _splits

func get_formatted_time(time_ms: int) -> String:
	var minutes = time_ms / 60000
	var seconds = (time_ms % 60000) / 1000
	var ms = time_ms % 1000
	return "%02d:%02d.%03d" % [minutes, seconds, ms]

func get_current_formatted_time() -> String:
	return get_formatted_time(_current_time)

func get_elapsed_time_seconds() -> float:
	return _current_time / 1000.0