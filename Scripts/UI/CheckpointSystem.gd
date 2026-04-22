extends Node
class_name CheckpointSystem

## CheckpointSystem - Practice mode checkpoints and instant restart
##
## Features:
## - Checkpoint placement at any position
## - Instant restart from checkpoint
## - Checkpoint preview mode
## - Checkpoint visibility toggling
## - Checkpoint editing (move/delete)
##
## Sources:
## - CS:GO surf practice mode
## - Speedrunning checkpoint conventions

signal checkpoint_added(checkpoint: int, position: Vector3)
signal checkpoint_removed(checkpoint: int)
signal checkpoint_reached(checkpoint: int)
signal checkpoint_preview_enabled(checkpoint: int)
signal checkpoint_preview_disabled()
signal checkpoint_moved(checkpoint: int, old_position: Vector3, new_position: Vector3)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Checkpoint Settings")
@export var checkpoint_radius: float = 2.0  ## Checkpoint detection radius
@export var checkpoint_visible: bool = true ## Whether checkpoints are visible
@export var checkpoint_color: Color = Color.RED
@export var preview_radius: float = 5.0  ## Preview zone radius

@export_group("UI Settings")
@export var show_checkpoint_count: bool = true
@export var show_checkpoint_names: bool = false

# =============================================================================
# STATE
# =============================================================================

var _checkpoints: Array = []  ## [position, name]
var _current_checkpoint: int = 0
var _checkpoint_counter: int = 0
var _preview_mode: bool = false
var _preview_tick: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Create initial checkpoint at spawn
	_create_checkpoint(Vector3(0, 0, 0), "spawn")
	
	# Add keyboard shortcuts
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	# Checkpoint placement (LMB)
	if event.is_action_pressed("place_checkpoint") and _is_in_preview_mode():
		var pos := get_input_position()
		_add_checkpoint(pos, "checkpoint_" + str(_checkpoint_counter))
	
	# Checkpoint restart (RMB)
	if event.is_action_pressed("restart_checkpoint"):
		restart_from_checkpoint()
	
	# Toggle preview mode (E key)
	if event.is_action_pressed("toggle_preview"):
		_toggle_preview_mode()


func _is_in_preview_mode() -> bool:
	return _preview_mode


# =============================================================================
# CHECKPOINT MANAGEMENT
# =============================================================================

func _create_checkpoint(position: Vector3, name: String) -> int:
	"""Create a new checkpoint"""
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
	"""Add a checkpoint at specified position"""
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
	"""Remove checkpoint at specified index"""
	if index >= 0 and index < _checkpoints.size():
		_checkpoints.remove_at(index)
		checkpoint_removed.emit(index)
		print("[Checkpoint] Removed checkpoint at index " + str(index))


func get_checkpoint_at_index(index: int) -> Dictionary:
	"""Get checkpoint data at index"""
	if index >= 0 and index < _checkpoints.size():
		return _checkpoints[index]
	return {}


func get_all_checkpoints() -> Array:
	"""Get all checkpoints"""
	return _checkpoints


func get_checkpoint_count() -> int:
	"""Get total number of checkpoints"""
	return _checkpoints.size()


func get_current_checkpoint() -> int:
	"""Get current checkpoint index"""
	return _current_checkpoint


func set_current_checkpoint(index: int) -> void:
	"""Set current checkpoint (for instant restart)"""
	if index >= 0 and index < _checkpoints.size():
		_current_checkpoint = index


# =============================================================================
# CHECKPOINT UTILITIES
# =============================================================================

func is_at_checkpoint(position: Vector3) -> bool:
	"""Check if player is at current checkpoint"""
	var checkpoint := get_current_checkpoint()
	if checkpoint == -1:
		return false
	
	var cp_data := get_checkpoint_at_index(checkpoint)
	var cp_position: Vector3 = cp_data.get("position", Vector3.ZERO)
	return position.distance_to(cp_position) < checkpoint_radius


func get_nearest_checkpoint(position: Vector3) -> int:
	"""Find nearest checkpoint to position"""
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
	"""Get distance from position to current checkpoint"""
	var checkpoint := get_current_checkpoint()
	if checkpoint == -1:
		return 0.0
	
	var cp_data := get_checkpoint_at_index(checkpoint)
	var cp_position: Vector3 = cp_data.get("position", Vector3.ZERO)
	return position.distance_to(cp_position)


# =============================================================================
# PRACTICE MODE
# =============================================================================

func restart_from_checkpoint() -> void:
	"""Instant restart from current checkpoint"""
	var checkpoint := get_current_checkpoint()
	if checkpoint == -1:
		return
	
	var cp_data := get_checkpoint_at_index(checkpoint)
	var cp_position: Vector3 = cp_data.get("position", Vector3.ZERO)
	var cp_rotation: Vector3 = cp_data.get("rotation", Vector3.UP)
	
	# Find and teleport player
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("reset_position"):
			player.reset_position(cp_position)
			# Orient player
			player.rotation = Quaternion.IDENTITY
			player.look_at(cp_position + cp_rotation, Vector3.UP)
	
	print("[Checkpoint] Restarting from checkpoint " + str(checkpoint))


func enable_preview_mode() -> void:
	"""Enable checkpoint preview mode"""
	_preview_mode = true
	_preview_tick = Time.get_ticks_msec() / 1000
	checkpoint_preview_enabled.emit(_current_checkpoint)
	print("[Checkpoint] Preview mode enabled")


func disable_preview_mode() -> void:
	"""Disable checkpoint preview mode"""
	_preview_mode = false
	checkpoint_preview_disabled.emit()
	print("[Checkpoint] Preview mode disabled")


func toggle_preview_mode() -> void:
	"""Toggle preview mode"""
	if _preview_mode:
		disable_preview_mode()
	else:
		enable_preview_mode()


func get_preview_position() -> Vector3:
	"""Get position at preview tick (for replay)"""
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get_position_at_tick"):
			return player.get_position_at_tick(_preview_tick)
	return Vector3.ZERO


# =============================================================================
# CHECKPOINT EDITING (Developer)
# =============================================================================

func move_checkpoint(index: int, new_position: Vector3) -> void:
	"""Move checkpoint to new position"""
	if index >= 0 and index < _checkpoints.size():
		var old_position: Vector3 = _checkpoints[index].get("position", Vector3.ZERO)
		_checkpoints[index]["position"] = new_position
		checkpoint_moved.emit(index, old_position, new_position)
		print("[Checkpoint] Moved checkpoint " + str(index) + " to " + str(new_position))


func delete_checkpoint(index: int) -> void:
	"""Delete checkpoint (must be last or all after it)"""
	if index >= 0 and index < _checkpoints.size():
		# Only allow deleting last checkpoint or all after it
		if index == _checkpoints.size() - 1:
			_remove_checkpoint(index)
		else:
			print("[Checkpoint] Cannot delete non-final checkpoint")


func clear_all_checkpoints() -> void:
	"""Clear all checkpoints"""
	_checkpoints.clear()
	_checkpoint_counter = 0
	_current_checkpoint = -1
	print("[Checkpoint] All checkpoints cleared")


# =============================================================================
# UI UPDATES
# =============================================================================

func _process(_delta: float) -> void:
	# Update UI if needed
	if show_checkpoint_count:
		var ui_node := get_node_or_null("UI/CheckpointCount")
		if ui_node:
			ui_node.set_text(str(get_checkpoint_count()))
	
	if show_checkpoint_names:
		var ui_node := get_node_or_null("UI/CheckpointNames")
		if ui_node:
			var names: String = ""
			for i in range(_checkpoints.size()):
				var name: String = _checkpoints[i].get("name", "CP")
				names += name + ", "
			ui_node.set_text(names)


func _get_local_transform() -> Transform3D:
	# Override to get proper local transform
	return get_global_transform()


# =============================================================================
# DEBUG
# =============================================================================

func _draw() -> void:
	if not checkpoint_visible:
		return
	
	var transform := get_global_transform()
	
	# Draw checkpoints
	for i in range(_checkpoints.size()):
		var cp_data := _checkpoints[i]
		var position: Vector3 = cp_data.get("position", Vector3.ZERO)
		
		# Draw checkpoint sphere
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = checkpoint_radius
		sphere.subdivide_count = 8
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = checkpoint_color
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = sphere
		mesh_instance.material_override = material
		add_child(mesh_instance)
		mesh_instance.global_position = transform * Vector3(position.x, position.y, position.z)
	
	# Draw preview ring
	if _preview_mode:
		var ring := CylinderMesh.new()
		ring.radius_inner = 0.1
		ring.radius_outer = preview_radius
		ring.height = 0.5
		var ring_material: StandardMaterial3D = StandardMaterial3D.new()
		ring_material.albedo_color = Color.CYAN
		var ring_instance := MeshInstance3D.new()
		ring_instance.mesh = ring
		ring_instance.material_override = ring_material
		add_child(ring_instance)
		ring_instance.global_transform = transform * Transform3D(Vector3(position.x, 0.25, position.z))