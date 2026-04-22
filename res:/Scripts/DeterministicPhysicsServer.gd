extends Node

class_name DeterministicPhysicsServer

## Handles deterministic physics simulation at 300 Hz for fair replays and rollback.

@export var physics_tick_rate: float = 300.0

var tick_time: float = 1.0 / physics_tick_rate

var rollback_buffer_size: int = 150  ## 500ms buffer for rollback

var state_history: Array[Dictionary] = []  ## Stores state snapshots

var current_tick: int = 0

func _ready() -> void:
    Engine.physics_ticks_per_second = physics_tick_rate
    tick_time = 1.0 / physics_tick_rate

## Saves the current state of the player for replay/rollback.
## Returns a dictionary with position, velocity, rotation, and tick.
func save_state(player: SurfPhysicsController) -> Dictionary:
    return {
        "position": player.global_position,
        "velocity": player.velocity,
        "rotation": player.global_rotation,
        "tick": current_tick
    }

## Loads a state snapshot into the player.
func load_state(state: Dictionary, player: SurfPhysicsController) -> void:
    player.global_position = state["position"]
    player.velocity = state["velocity"]
    player.global_rotation = state["rotation"]
    current_tick = state["tick"]

## Advances the tick counter. Call this at the end of each physics tick.
func advance_tick() -> void:
    current_tick += 1
    ## Maintain rollback buffer
    if state_history.size() > rollback_buffer_size:
        state_history.pop_front()