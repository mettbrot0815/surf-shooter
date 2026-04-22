extends Node
class_name PerformanceTest

## PerformanceTest - Tests high-speed surfing capabilities

@export var ramp_boost_test: bool = true
@export var speed_target: float = 800.0  # units/second

var _max_speed_achieved: float = 0.0
var _speed_samples: Array = []
var _test_active: bool = false

func _ready() -> void:
	print("=== Performance Test Starting ===")
	print("Testing for speeds of %.0f+ units/second" % speed_target)
	
	# Connect to speed updates
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("connect"):
		player.speed_updated.connect(_on_speed_updated)
	
	# Start test after short delay
	await get_tree().create_timer(1.0).timeout
	start_performance_test()

func start_performance_test() -> void:
	print("Beginning performance test...")
	_test_active = true
	
	var player = get_tree().get_first_node_in_group("players")
	if player:
		# Position near ramps for testing
		player.global_position = Vector3(0, 5, 15)
		player.velocity = Vector3(0, 0, 100)  # Initial forward velocity
	
	# Run test for 10 seconds
	await get_tree().create_timer(10.0).timeout
	end_performance_test()

func _on_speed_updated(speed: float) -> void:
	if not _test_active:
		return
	
	_speed_samples.append(speed)
	_max_speed_achieved = max(_max_speed_achieved, speed)

func end_performance_test() -> void:
	_test_active = false
	
	print("\n=== Performance Test Results ===")
	print("Max speed achieved: %.2f units/second" % _max_speed_achieved)
	print("Speed target: %.0f units/second" % speed_target)
	
	if _max_speed_achieved >= speed_target:
		print("✅ TARGET ACHIEVED - Surfing at competitive speeds!")
	else:
		print("⚠️ TARGET NOT MET - May need physics tuning")
		print("Difference: %.2f units/second" % (_speed_target - _max_speed_achieved))
	
	# Analyze speed distribution
	if _speed_samples.size() > 0:
		var avg_speed = _speed_samples.reduce(func(a, b): return a + b) / _speed_samples.size()
		var min_speed = _speed_samples.min()
		var max_speed = _speed_samples.max()
		
		print("\nSpeed Statistics:")
		print("Average: %.2f u/s" % avg_speed)
		print("Minimum: %.2f u/s" % min_speed)
		print("Maximum: %.2f u/s" % max_speed)
		
		var high_speed_time = _speed_samples.filter(func(s): return s >= 400).size()
		var high_speed_percentage = (high_speed_time as float / _speed_samples.size()) * 100
		print("Time at 400+ u/s: %.1f%%" % high_speed_percentage)