extends Node3D

class_name CheckpointSystem

## Manages checkpoints with preview mode, instant teleport, and ghost integration.

@export var checkpoint_scene: PackedScene
@export var preview_material: Material  ## Transparent for preview

var checkpoints: Array[Node3D] = []
var preview_mode: bool = false
var preview_checkpoint: Node3D = null

@onready var player: SurfPhysicsController = get_parent()

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("checkpoint_preview"):
        toggle_preview_mode()
    
    if preview_mode:
        update_preview()
        if Input.is_action_just_pressed("place_checkpoint"):
            place_checkpoint()
        if Input.is_action_just_pressed("remove_checkpoint"):
            remove_last_checkpoint()

func toggle_preview_mode() -> void:
    preview_mode = !preview_mode
    if preview_mode:
        create_preview()
    else:
        destroy_preview()

func create_preview() -> void:
    preview_checkpoint = checkpoint_scene.instantiate()
    preview_checkpoint.material_override = preview_material
    add_child(preview_checkpoint)

func destroy_preview() -> void:
    if preview_checkpoint:
        preview_checkpoint.queue_free()
        preview_checkpoint = null

func update_preview() -> void:
    if preview_checkpoint:
        preview_checkpoint.global_position = player.global_position + player.velocity.normalized() * 2  ## Ahead

func place_checkpoint() -> void:
    var cp = checkpoint_scene.instantiate()
    cp.global_position = player.global_position
    add_child(cp)
    checkpoints.append(cp)
    ## Record ghost segment
    SpeedrunTimer.add_split()
    ## Start new ghost recording from here

func remove_last_checkpoint() -> void:
    if checkpoints.size() > 0:
        checkpoints.back().queue_free()
        checkpoints.pop_back()

func teleport_to_checkpoint(index: int) -> void:
    if index < checkpoints.size():
        player.global_position = checkpoints[index].global_position
        player.velocity = Vector3.ZERO
        SpeedrunTimer.instant_restart()  ## If practice