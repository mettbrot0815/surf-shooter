extends CharacterBody3D

class_name SurfPhysicsController

## Core movement controller replicating CS:GO surf physics with deterministic simulation.

@export_group("Movement Tuning")
@export var max_speed: float = 300.0  ## Max horizontal speed (units/sec)
@export var air_accelerate: float = 10.0  ## Air acceleration multiplier (CS:GO style)
@export var ground_accelerate: float = 10.0  ## Ground acceleration
@export var friction: float = 4.0  ## Ground friction
@export var gravity: float = 29.4  ## Gravity force (3x normal for surf)
@export var jump_force: float = 250.0  ## Jump velocity

@export_group("Surf Tuning")
@export var ramp_deflect: float = 1.0  ## Ramp deflection strength
@export var speed_gain_threshold: float = -0.5  ## Dot product threshold for speed gain on ramps
@export var speed_gain_multiplier: float = 1.1  ## Multiplier for speed gain

@export_group("Water Tuning")
@export var water_friction: float = 2.0  ## Friction in water

@onready var camera: Camera3D = $Camera3D

var wish_dir: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var is_surfing: bool = false
var in_water: bool = false
var delta_fixed: float = 1.0 / 300.0
var peak_speed: float = 0.0

func _physics_process(delta: float) -> void:
    delta_fixed = delta  ## Assume fixed at 300 Hz
    
    ## Input handling with camera-relative wish direction
    var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var input_y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    var input_dir = Vector3(input_x, 0, input_y).normalized()
    wish_dir = (camera.global_basis * input_dir).normalized()
    
    if Input.is_action_just_pressed("jump") and is_grounded:
        velocity.y = jump_force
    
    ## Gravity application
    if not is_grounded:
        velocity.y -= gravity * delta_fixed
    
    ## Friction
    var fric = water_friction if in_water else friction
    if is_grounded or in_water:
        var speed = velocity.length()
        if speed > 0:
            var drop = speed * fric * delta_fixed
            velocity *= max(0, speed - drop) / speed
    
    ## Acceleration (CS:GO air acceleration formula)
    var accel = ground_accelerate if is_grounded else air_accelerate
    var wish_speed = max_speed
    var current_speed_in_wish_dir = velocity.dot(wish_dir)
    var add_speed = wish_speed - current_speed_in_wish_dir
    if add_speed > 0:
        var accel_speed = min(add_speed, accel * wish_speed * delta_fixed)
        velocity += wish_dir * accel_speed
    
    ## Movement and collision
    var collision = move_and_slide()
    is_grounded = is_on_floor()
    
    ## Surf ramp behavior
    is_surfing = false
    if collision:
        for i in range(get_slide_collision_count()):
            var col = get_slide_collision(i)
            var normal = col.get_normal()
            if abs(normal.y) < 0.7:  ## Ramp surface (not floor/ceiling)
                is_surfing = true
                ## Deflect velocity along ramp
                velocity = velocity.slide(normal) * ramp_deflect
                ## Speed gain on proper angles
                var dot = velocity.normalized().dot(normal)
                if dot < speed_gain_threshold:
                    velocity *= speed_gain_multiplier
    
    ## Water interaction via WaveSystem
    var wave_height = WaveSystem.get_height(global_position)
    var wave_friction = WaveSystem.get_friction(global_position)
    if global_position.y < wave_height:
        in_water = true
        ## Apply wave normal to velocity for surface riding
        var wave_normal = WaveSystem.get_normal(global_position)
        velocity = velocity.slide(wave_normal)
        ## Dynamic friction
        fric = wave_friction
    else:
        in_water = false
    
    ## Track peak speed
    var horiz_speed = Vector3(velocity.x, 0, velocity.z).length()
    peak_speed = max(peak_speed, horiz_speed)
    
    ## State snapshot for determinism
    var state = DeterministicPhysicsServer.save_state(self)
    ## Send to SpeedrunTimer for recording if active
    if SpeedrunTimer.is_recording:
        SpeedrunTimer.record_state(state)
    DeterministicPhysicsServer.advance_tick()