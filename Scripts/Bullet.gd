extends CharacterBody3D

var direction: Vector3 = Vector3.FORWARD
var speed: float = 300.0
var damage: float = 25.0
var lifetime: float = 2.0

func _ready() -> void:
	velocity = direction * speed
	$Timer.wait_time = lifetime
	$Timer.start()

func _physics_process(delta: float) -> void:
	var collision = move_and_slide()
	if collision:
		# Hit something
		_on_hit()

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	# Deal damage if it's a damageable object
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_on_hit()

func _on_hit() -> void:
	# Add impact effect
	var impact_scene = load("res://Scenes/ImpactEffect.tscn")
	if impact_scene:
		var impact = impact_scene.instantiate()
		impact.position = global_position
		get_tree().root.add_child(impact)
	queue_free()