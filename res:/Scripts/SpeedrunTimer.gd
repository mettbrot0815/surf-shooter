extends Node

class_name SpeedrunTimer

## Manages speedrun timing, splits, practice mode, and ghost replay at 300 Hz.

@export var checkpoint_scenes: Array[PackedScene]  ## For splits

var start_time: float = 0.0
var current_time: float = 0.0
var is_running: bool = false
var is_practice_mode: bool = false
var splits: Array[float] = []
var best_times: Dictionary = {}  ## Save/load from file

var ghost_data: Array[Dictionary] = []
var is_recording: bool = false
var is_playing_ghost: bool = false
var ghost_playback_speed: float = 1.0
var ghost_index: int = 0

@onready var player: SurfPhysicsController = get_parent()

func _ready() -> void:
    _load_best_times()

func _process(delta: float) -> void:
    if is_running:
        current_time = Time.get_time() - start_time
    
    if is_playing_ghost:
        _update_ghost_playback(delta)

func start_run() -> void:
    start_time = Time.get_time()
    is_running = true
    splits.clear()
    ghost_data.clear()
    is_recording = true

func stop_run() -> void:
    is_running = false
    is_recording = false
    var total_time = current_time
    if total_time < best_times.get("total", INF):
        best_times["total"] = total_time
        _save_best_times()

func add_split() -> void:
    if is_running:
        splits.append(current_time)

func instant_restart() -> void:
    if is_practice_mode:
        player.global_position = Vector3(0, 10, 0)  ## Reset position
        player.velocity = Vector3.ZERO
        start_time = Time.get_time()
        current_time = 0.0
        ghost_index = 0

func record_state(state: Dictionary) -> void:
    if is_recording:
        ghost_data.append(state)

func start_ghost_playback(speed: float = 1.0) -> void:
    if ghost_data.size() > 0:
        is_playing_ghost = true
        ghost_playback_speed = speed
        ghost_index = 0

func stop_ghost_playback() -> void:
    is_playing_ghost = false

func _update_ghost_playback(delta: float) -> void:
    if ghost_index < ghost_data.size():
        var state = ghost_data[ghost_index]
        player.global_position = state["position"]
        player.velocity = state["velocity"]
        player.global_rotation = state["rotation"]
        ghost_index += int(delta * 300 * ghost_playback_speed)
    else:
        stop_ghost_playback()

func _load_best_times() -> void:
    var file = FileAccess.open("user://best_times.json", FileAccess.READ)
    if file:
        best_times = JSON.parse_string(file.get_as_text())

func _save_best_times() -> void:
    var file = FileAccess.open("user://best_times.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(best_times))

func get_formatted_time(time: float) -> String:
    var ms = int((time - floor(time)) * 1000)
    var s = int(time) % 60
    var m = int(time) / 60
    return "%02d:%02d.%03d" % [m, s, ms]