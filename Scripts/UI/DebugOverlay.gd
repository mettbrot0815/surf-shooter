extends CanvasLayer
class_name DebugOverlay

## DebugOverlay - Visual debug information display

signal debug_message(message: String, type: String)

@onready var velocity_label: Label = $VBoxContainer/Velocity
@onready var speed_label: Label = $VBoxContainer/Speed
@onready var position_label: Label = $VBoxContainer/Position
@onready var timer_label: Label = $VBoxContainer/Timer
@onready var checkpoint_label: Label = $VBoxContainer/Checkpoint
@onready var wave_label: Label = $VBoxContainer/Wave
@onready var physics_label: Label = $VBoxContainer/Physics
@onready var ghost_label: Label = $VBoxContainer/Ghost

var _wave_system: WaveSystem = null
var _timer: SpeedrunTimer = null
var _physics_server: DeterministicPhysicsServer = null
var _checkpoint_system: CheckpointSystem = null

# =============================================================================
# CONNECTION
# =============================================================================

func _ready() -> void:
	# Connect to physics server
	_physics_server = DeterministicPhysicsServer
	if _physics_server:
		_physics_server.physics_tick_completed.connect(_on_physics_tick)

	# Connect to timer
	_timer = SpeedrunTimer
	if _timer:
		_timer.speed_updated.connect(_on_speed_updated)

	# Connect to checkpoints
	_checkpoint_system = get_tree().get_first_node_in_group("checkpoint_system")
	if _checkpoint_system:
		_checkpoint_system.checkpoint_added.connect(_on_checkpoint_added)

	# Connect to wave system
	_wave_system = get_tree().get_first_node_in_group("wave_system")


func _process(_delta: float) -> void:
	# Update debug information
	var player = get_tree().get_first_node_in_group("players")
	if player:
		_update_player_info(player)
	_update_wave_info()
	_update_timer_info()
	_update_physics_info()
	_update_ghost_info()


func _update_player_info(player: Node3D) -> void:
	if not player.has_method("get_physics_state"):
		return
	
	var state := player.get_physics_state()
	velocity_label.text = "Velocity: " + str(state.get("velocity", Vector3.ZERO))
	speed_label.text = "Speed: " + str(state.get("current_speed", 0)) + " m/s"
	position_label.text = "Pos: " + str(state.get("position", Vector3.ZERO))


func _update_wave_info() -> void:
	if _wave_system:
		var info := _wave_system.get_wave_info()
		wave_label.text = "Waves: " + str(info.get("layers_count", 0)) + " | Amplitude: " + str(info.get("amplitude", 0))


func _update_timer_info() -> void:
	if _timer:
		var data := _timer.get_full_timing_data()
		timer_label.text = "Time: " + str(data.get("elapsed_time", 0)) + " ms"
		checkpoint_label.text = "Checkpoints: " + str(data.get("checkpoint_count", 0)) + "/" + str(data.get("total_checkpoints", 0))


func _update_physics_info() -> void:
	if _physics_server:
		var state := _physics_server.get_physics_state()
		physics_label.text = "Tick: " + str(state.get("tick", 0)) + " | Delta: " + str(state.get("accumulated_delta", 0))


func _update_ghost_info() -> void:
	var ghost = GhostReplaySystem.get_instance()
	if ghost:
		ghost_label.text = "Ghost: " + str(ghost.get_last_filename())


func _on_physics_tick(tick: int, delta: float) -> void:
	physics_label.text = "Tick: " + str(tick) + " | Delta: " + str(delta) + "s"


func _on_speed_updated(speed: float) -> void:
	speed_label.text = "Speed: " + str(speed) + " m/s"


func _on_checkpoint_added(checkpoint: int, position: Vector3) -> void:
	checkpoint_label.text = "Checkpoints: " + str(checkpoint) + " | Pos: " + str(position)


# =============================================================================
# CONTROLS
# =============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_show_velocity_debug()
		if event.keycode == KEY_F2:
			_show_all_debug()
		if event.keycode == KEY_ESCAPE:
			_hide_all_debug()


func _show_velocity_debug() -> void:
	velocity_label.visible = true
	speed_label.visible = true


func _show_all_debug() -> void:
	velocity_label.visible = true
	speed_label.visible = true
	position_label.visible = true
	timer_label.visible = true
	checkpoint_label.visible = true
	wave_label.visible = true
	physics_label.visible = true
	ghost_label.visible = true


func _hide_all_debug() -> void:
	velocity_label.visible = false
	speed_label.visible = false
	position_label.visible = false
	timer_label.visible = false
	checkpoint_label.visible = false
	wave_label.visible = false
	physics_label.visible = false
	ghost_label.visible = false
