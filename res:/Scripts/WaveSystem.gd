extends Node3D

class_name WaveSystem

## Gerstner wave system with height, normal, friction queries for water interaction.

@export var amplitude: float = 1.0
@export var wavelength: float = 10.0
@export var speed: float = 1.0
@export var steepness: float = 0.5

var time: float = 0.0

func _process(delta: float) -> void:
    time += delta

## Get wave height at position
func get_height(pos: Vector3) -> float:
    var x = pos.x / wavelength
    var z = pos.z / wavelength
    return amplitude * sin(x + time * speed) * cos(z + time * speed)

## Get wave normal at position
func get_normal(pos: Vector3) -> Vector3:
    var x = pos.x / wavelength
    var z = pos.z / wavelength
    var dx = cos(x + time * speed) * cos(z + time * speed)
    var dz = -sin(x + time * speed) * sin(z + time * speed)
    return Vector3(-dx, 1.0, -dz).normalized()

## Get dynamic friction at position (higher in rough waves)
func get_friction(pos: Vector3) -> float:
    var height = get_height(pos)
    return 1.0 + abs(height) * 0.5  ## Base friction + wave intensity