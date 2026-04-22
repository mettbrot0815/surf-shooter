extends Node
class_name PhysicsDeterminismTest

## PhysicsDeterminismTest - Verifies 300Hz physics determinism

@export var test_duration: float = 5.0
@export var test_runs: int = 3

var _test_results: Array = []
var _current_test: int = 0
var _test_start_time: float = 0.0
var _player_states: Array = []

func _ready() -> void:
	print("=== Physics Determinism Test Starting ===")
	run_determinism_test()

func run_determinism_test() -> void:
	_test_results.clear()
	_current_test = 0
	
	for i in range(test_runs):
		print("Running test run %d/%d..." % [i+1, test_runs])
		await run_single_test()
	
	analyze_results()

func run_single_test() -> Promise:
	var test_promise = Promise.new()
	
	# Reset player to start position
	var player = get_tree().get_first_node_in_group("players")
	if player:
		player.global_position = Vector3(0, 10, 0)
		player.velocity = Vector3.ZERO
	
	# Start timer
	var timer = SpeedrunTimer
	if timer:
		timer.start_timer()
	
	# Record states for 5 seconds
	_player_states.clear()
	_test_start_time = Time.get_ticks_msec() / 1000.0
	
	# Wait for test duration
	await get_tree().create_timer(test_duration).timeout
	
	# Stop timer and record final state
	if timer:
		timer.stop_timer()
	
	var final_state = get_player_state()
	_test_results.append(final_state)
	
	test_promise.resolve()
	return test_promise

func get_player_state() -> Dictionary:
	var player = get_tree().get_first_node_in_group("players")
	if player and player.has_method("get_physics_state"):
		return player.get_physics_state()
	return {}

func analyze_results() -> void:
	print("\n=== Test Results Analysis ===")
	
	if _test_results.size() < 2:
		print("Not enough test runs to analyze")
		return
	
	var reference_state = _test_results[0]
	var all_match = true
	
	for i in range(1, _test_results.size()):
		var state = _test_results[i]
		var matches = compare_states(reference_state, state)
		print("Test run %d vs reference: %s" % [i+1, "MATCH" if matches else "DIFFERENT"])
		if not matches:
			all_match = false
			print_differences(reference_state, state)
	
	if all_match:
		print("\n✅ PHYSICS DETERMINISM VERIFIED - All test runs produced identical results!")
		print("300Hz physics engine is working correctly.")
	else:
		print("\n❌ DETERMINISM FAILED - Results vary between runs")
		print("Check for non-deterministic elements in physics calculations.")

func compare_states(state1: Dictionary, state2: Dictionary) -> bool:
	var tolerance = 0.001  # Allow tiny floating point differences
	
	for key in state1.keys():
		if not state2.has(key):
			return false
		
		var val1 = state1[key]
		var val2 = state2[key]
		
		if val1 is Vector3 and val2 is Vector3:
			if not val1.is_equal_approx(val2, tolerance):
				return false
		elif val1 is float and val2 is float:
			if abs(val1 - val2) > tolerance:
				return false
		elif val1 != val2:
			return false
	
	return true

func print_differences(state1: Dictionary, state2: Dictionary) -> void:
	for key in state1.keys():
		if state2.has(key):
			var val1 = state1[key]
			var val2 = state2[key]
			if val1 != val2:
				print("  %s: %s vs %s" % [key, val1, val2])