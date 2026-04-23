extends Node3D
class_name EnemySpawner

## EnemySpawner - Spawns enemy targets at strategic positions around the level

signal enemy_added(enemy: EnemyTarget)
signal enemy_killed(enemy: EnemyTarget)

@export var enemy_count: int = 3
@export var spawn_points: Array[Vector3] = []
@export var spawn_radius: float = 100.0
@export var spawn_delay: float = 0.5
@export var target_types: Array[String] = ["enemy", "target", "practice"]

var spawned_enemies: Array[EnemyTarget] = []
var is_spawning: bool = false

func _ready() -> void:
	if spawn_points.is_empty():
		# Auto-generate spawn points around the level
		for i in range(enemy_count):
			spawn_points.append(_get_random_spawn_position())
	
	# Connect to game over for cleanup
	await get_tree().paused
	
	# Start spawning enemies
	spawn_enemies()


func _get_random_spawn_position() -> Vector3:
	# Random position within level bounds
	var x := randf_range(-150.0, 150.0)
	var y := 2.0
	var z := randf_range(-150.0, 150.0)
	return Vector3(x, y, z)


func spawn_enemies() -> void:
	is_spawning = true
	var spawn_index := 0
	
	while spawn_index < enemy_count:
		var spawn_delay := randf_range(0.5, 2.0)
		await get_tree().create_timer(spawn_delay).timeout
		
		var position := _get_random_spawn_position()
		var target_type := target_types[spawn_index % target_types.size()]
		
		var enemy = _create_enemy(position, target_type)
		if enemy:
			spawned_enemies.append(enemy)
			enemy_added.emit(enemy)
			spawn_index += 1


func _create_enemy(position: Vector3, target_type: String) -> EnemyTarget:
	var enemy = EnemyTarget.new()
	enemy.position = position
	enemy.target_type = target_type
	
	# Set color based on type
	match target_type:
		"enemy":
			enemy.visual_color = Color.RED
		"target":
			enemy.visual_color = Color.GREEN
		"practice":
			enemy.visual_color = Color.BLUE
	
	enemy.add_to_group("shooting_targets")
	add_child(enemy)
	
	return enemy


func _on_enemy_killed(enemy: EnemyTarget) -> void:
	spawned_enemies.erase(enemy)
	enemy.queue_free()
	enemy_killed.emit(enemy)


func _process(_delta: float) -> void:
	# Cleanup dead enemies
	spawned_enemies = spawned_enemies.filter(func(e: EnemyTarget) -> bool:
		return e.is_active
	)

func get_spawned_enemies() -> Array[EnemyTarget]:
	return spawned_enemies.filter(func(e: EnemyTarget) -> bool:
		return e.is_active
	)