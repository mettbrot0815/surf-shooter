extends Node
class_name CheckpointSystem

## CheckpointSystem - Practice mode checkpoints and instant restart

signal checkpoint_added(checkpoint: int, position: Vector3)
signal checkpoint_removed(checkpoint: int)
signal checkpoint_reached(checkpoint: int)
signal checkpoint_preview_enabled(checkpoint: int)
signal checkpoint_preview_disabled()
signal checkpoint_moved(checkpoint: int, old_position: Vector3, new_position: Vector3)

@export_group("Checkpoint Settings")
@export var checkpoint_radius: float = 2.0
@export var checkpoint_visible: bool = true
@export var checkpoint_color: Color = Color.RED
@export var preview_radius: float = 5.0

@export_group("UI Settings")
@export var show_checkpoint_count: bool = true
@export var show_checkpoint_names: bool = false

var _checkpoints: Array = []
var _current_checkpoint: int = 0
var _checkpoint_counter: int = 0
var _preview_mode: bool = false
var _preview_tick: int = 0

func _ready() -> void:
	_create_checkpoint(Vector3(0, 0, 0), "spawn")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("place_checkpoint") and _is_in_preview_mode():
		var pos := get_input_position()
		_add_checkpoint(pos, "checkpoint_" + str(_checkpoint_counter))
	if event.is_action_pressed("restart_checkpoint"):
		restart_from_checkpoint()
	if event.is_action_pressed("toggle_preview"):
		_toggle_preview_mode()

func _is_in_preview_mode() -> bool:
	return _preview_mode

func _create_checkpoint(position: Vector3, name: String) -> int:
	_checkpoint_counter += 1
	var checkpoint: Dictionary = {
		"index": _checkpoint_counter,
		"name": name,
		"position": position,
		"added": Time.get_ticks_msec()
	}
	_checkpoints.append(checkpoint)
	checkpoint_added.emit(_checkpoint_counter, position)
	print("[Checkpoint] Created checkpoint " + str(_checkpoint_counter) + " at " + str(position))
	return _checkpoint_counter

func _add_checkpoint(position: Vector3, name: String) -> int:
	_checkpoint_counter += 1
	var checkpoint: Dictionary = {
		"index": _checkpoint_counter,
		"name": name,
		"position": position,
		"added": Time.get_ticks_msec()
	}
	_checkpoints.append(checkpoint)
	checkpoint_added.emit(_checkpoint_counter, position)
	print("[Checkpoint] Added checkpoint " + str(_checkpoint_counter) + " at " + str(position))
	return _checkpoint_counter

func _remove_checkpoint(index: int) -> void:
	if index >= 0 and index < _checkpoints.size():
		_checkpoints.remove_at(index)
		checkpoint_removed.emit(index)
		print("[Checkpoint] Removed checkpoint at index " + str(index))

func get_checkpoint_at_index(index: int) -> Dictionary:
	if index >= 0 and index < _checkpoints.size():
		return _checkpoints[index]
	return {}

func get_all_checkpoints() -> Array:
	return _checkpoints

func get_checkpoint_count() -> int:
	return _checkpoints.size()

func get_current_checkpoint() -> int:
	return _current_checkpoint

func set_current_checkpoint(index: int) -> void:
	if index >= 0 and index < _checkpoints.size():
		_current_checkpoint = index

func is_at_checkpoint(position: Vector3) -> bool:
	var checkpoint := get_current_checkpoint()
	if checkpoint == -1:
		return false
	var cp_data := get_checkpoint_at_index(checkpoint)
	var cp_position: Vector3 = cp_data.get("position", Vector3.ZERO)
	return position.distance_to(cp_position) < checkpoint_radius

func get_nearest_checkpoint(position: Vector3) -> int:
	var nearest: int = -1
	var nearest_distance: float = float(INF)
	for i in range(_checkpoints.size()):
		var cp_data := _checkpoints[i]
		var cp_position: Vector3 = cp_data.get("position", Vector3.ZERO)
		var distance: float = position.distance_to(cp_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = i
	return nearest

func get_distance_to_current_checkpoint(position: Vector3) -> float:
	var checkpoint := get_current_checkpoint()
	if checkpoint == -1:
		return 0.0
	var cp_data := get_checkpoint_at_index(checkpoint)
	var cp_position: Vector3 = cp_data.get("position", Vector3.ZERO)
	return position.distance_to(cp_position)

func restart_from_checkpoint() -> void:
	var checkpoint := get_current_checkpoint()
	var cp_data := get_checkpoint_at_index(checkpoint)
	var restart_position: Vector3 = cp_data.get("position", Vector3.ZERO)
	if get_tree().get_first_node_in_group("players"):
		var player := get_tree().get_first_node_in_group("players")
		if player:
			player.global_position = restart_position
			player.velocity = Vector3.ZERO
			player.rotation = Vector3.ZERO
	print("[Checkpoint] Restarting from checkpoint " + str(checkpoint))

func enable_preview_mode() -> void:
	_preview_mode = true
	checkpoint_preview_enabled.emit(_checkpoint_counter)
	print("[Checkpoint] Preview mode enabled")

func disable_preview_mode() -> void:
	_preview_mode = false
	checkpoint_preview_disabled.emit()
	print("[Checkpoint] Preview mode disabled")

func _toggle_preview_mode() -> void:
	_preview_mode = not _preview_mode
	if _preview_mode:
		checkpoint_preview_enabled.emit(0)
	else:
		checkpoint_preview_disabled.emit()

func get_preview_position() -> Vector3:
	return global_position

func get_input_position() -> Vector3:
	return global_position
