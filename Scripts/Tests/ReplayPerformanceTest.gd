extends Node
class_name ReplayPerformanceTest

## ReplayPerformanceTest - Tests replay system performance under load

## Tests that 300Hz recording doesn't impact game performance by monitoring:
## - FPS (frames per second)
## - Memory usage
## - Recording overhead

signal test_completed(success: bool, results: Dictionary)
signal fps_warning(fps: int)
signal memory_warning(mb_used: float)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export_group("Test Parameters")
@export var test_duration: float = 30.0  ## Test duration in seconds
@export var warmup_duration: float = 5.0  ## Warmup time before recording starts
@export var sample_interval: float = 0.25  ## FPS sampling interval (seconds)
@export var memory_check_interval: float = 1.0  ## Memory check interval

@export_group("Performance Thresholds")
@export var min_fps: int = 30  ## Minimum acceptable FPS
@export var max_memory_mb: float = 1024.0  ## Maximum allowed memory usage (MB)
@export var max_fps_drop: float = 15.0  ## Maximum allowed FPS drop during recording

@export_group("Recording Setup")
@export var test_fps: int = 60  ## Target game FPS
@export var record_fps: int = 300  ## Recording tick rate

# =============================================================================
# STATE
# =============================================================================

var _is_running: bool = false
var _fps_samples: Array = []
var _fps_drops: Array = []
var _memory_samples: Array = []
var _start_time: float = 0.0
var _warmup_end_time: float = 0.0
var _recording_start_time: float = 0.0
var _frames_recorded: int = 0
var _frames_dropped: int = 0
var _peak_memory_mb: float = 0.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Start monitoring game FPS
	_game_fps_monitor = _monitor_fps()
	
	# Start memory monitoring
	_start_memory_monitoring()


func start_test() -> void:
	"""Start the performance test"""
	if _is_running:
		return

	_is_running = true
	_fps_samples.clear()
	_fps_drops.clear()
	_memory_samples.clear()
	
	_start_time = Time.get_ticks_msec() / 1000.0
	_warmup_end_time = _start_time + warmup_duration
	_recording_start_time = _warmup_end_time
	
	print("[Performance Test] Starting test...")
	print("[Performance Test] Warmup phase: %f seconds" % warmup_duration)
	print("[Performance Test] Recording phase: %f seconds" % test_duration)


func stop_test() -> void:
	"""Stop the performance test"""
	if not _is_running:
		return
	
	_is_running = false
	print("[Performance Test] Test completed")
	_generate_report()


func _process(delta: float) -> void:
	# Handle warmup phase
	if _is_running and Time.get_ticks_msec() / 1000.0 < _warmup_end_time:
		return

	# Start recording phase
	if _is_running and Time.get_ticks_msec() / 1000.0 >= _warmup_end_time:
		start_recording()

	# Sample FPS during recording
	if _is_running and Time.get_ticks_msec() / 1000.0 >= _warmup_end_time:
		var current_time := Time.get_ticks_msec() / 1000.0
		var elapsed := current_time - _start_time
		
		# Sample FPS
		if elapsed % sample_interval < 0.01:
			_fps_samples.append(get_fps())
			_memory_samples.append(get_memory_usage())

		# Stop if test duration exceeded
		if elapsed >= test_duration:
			stop_test()


# =============================================================================
# FPS MONITORING
# =============================================================================

func _monitor_fps() -> Node:
	"""Create a hidden node for FPS monitoring"""
	var monitor = Node.new()
	monitor.name = "FPSMonitor"
	monitor.visible = false
	add_child(monitor)
	return monitor


func get_fps() -> int:
	"""Get current FPS"""
	return int(get_tree().get_process_delta_time() * 1000.0)


func _monitor_fps_loop() -> void:
	"""Monitor FPS and detect drops"""
	if not _is_running:
		return
	
	var current_fps := get_fps()
	var fps_drop := get_fps_drop()
	
	_fps_drops.append(fps_drop)
	
	# Check for FPS warnings
	if fps_drop > max_fps_drop:
		fps_warning.emit(current_fps)
		print("[Warning] FPS dropped by %d (current: %d)" % [fps_drop, current_fps])
	
	# Check memory usage
	if _memory_samples.size() > 0 and _memory_samples.back() > max_memory_mb:
		memory_warning.emit(_memory_samples.back())
		print("[Warning] Memory usage exceeded %f MB" % max_memory_mb)


func _monitor_fps_loop_process(_delta: float) -> void:
	_monitor_fps_loop()


# =============================================================================
# MEMORY MONITORING
# =============================================================================

func _start_memory_monitoring() -> void:
	"""Start background memory monitoring"""
	var memory_monitor = Node.new()
	memory_monitor.name = "MemoryMonitor"
	memory_monitor.visible = false
	memory_monitor.process_mode = Node.PROCESS_ALWAYS
	add_child(memory_monitor)
	memory_monitor.add_child(self)


func get_memory_usage() -> float:
	"""Get current memory usage in MB"""
	var memory_info: Dictionary = OS.get_memory_info()
	var used_mb: float = (memory_info["used"] / 1024.0 / 1024.0)
	return used_mb


func _monitor_memory_loop() -> void:
	"""Background memory monitoring"""
	if not _is_running:
		return
	
	_current_time := Time.get_ticks_msec() / 1000.0
	var elapsed := _current_time - _start_time
	
	# Check memory at regular intervals
	if elapsed % memory_check_interval < 0.01:
		var current_memory := get_memory_usage()
		_memory_samples.append(current_memory)
		_peak_memory_mb = max(_peak_memory_mb, current_memory)


# =============================================================================
# RECORDING
# =============================================================================

func start_recording() -> void:
	"""Start recording at 300Hz"""
	var ghost_replay = get_node_or_null("/root/GhostReplaySystem") as GhostReplaySystem
	if ghost_replay:
		ghost_replay.start_recording()
	
	_recording_start_time = Time.get_ticks_msec() / 1000.0
	_frames_recorded = 0
	_frames_dropped = 0

	print("[Performance Test] Recording started at %f seconds" % (Time.get_ticks_msec() / 1000.0))


func stop_recording() -> void:
	"""Stop recording"""
	var ghost_replay = get_node_or_null("/root/GhostReplaySystem") as GhostReplaySystem
	if ghost_replay:
		ghost_replay.stop_recording()
	
	var recording_duration := Time.get_ticks_msec() / 1000.0 - _recording_start_time
	_frames_recorded = int(recording_duration * record_fps)
	
	print("[Performance Test] Recording stopped after %f seconds, recorded %d frames" % [recording_duration, _frames_recorded])


# =============================================================================
# REPORT GENERATION
# =============================================================================

func _generate_report() -> void:
	"""Generate performance test report"""
	var avg_fps: float = 0.0
	var min_fps: float = 0.0
	var max_fps: float = 0.0
	var fps_drop_avg: float = 0.0
	var peak_memory_mb: float = 0.0
	
	if _fps_samples.size() > 0:
		var sum := 0.0
		var fps_values: Array = []
		
		for sample in _fps_samples:
			sum += sample
			fps_values.append(sample)
		
		avg_fps = sum / _fps_samples.size()
		min_fps = fps_values.min()
		max_fps = fps_values.max()
		
		_fps_drop_avg = fps_drops.reduce(
			func(acc: float, drop: float) -> float: return acc + drop,
			0.0
		) / _fps_drops.size()

	if _memory_samples.size() > 0:
		_peak_memory_mb = _memory_samples.max()

	var success: bool = (
		avg_fps >= min_fps and
		_fps_drop_avg <= max_fps_drop and
		_peak_memory_mb <= max_memory_mb
	)

	var results: Dictionary = {
		"duration": test_duration,
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"fps_drop_average": _fps_drop_avg,
		"peak_memory_mb": _peak_memory_mb,
		"frames_recorded": _frames_recorded,
		"fps_samples_count": _fps_samples.size(),
		"test_passed": success
	}

	test_completed.emit(success, results)

	var report = """
[Performance Test Report]
-------------------------
Test Duration: %f seconds
Target FPS: %d
Recorded FPS: %d

FPS Metrics:
- Average FPS: %.2f
- Minimum FPS: %.2f
- Maximum FPS: %.2f
- Average FPS Drop: %.2f

Memory Usage:
- Peak Memory: %.2f MB

Results:
- Test Passed: %s
""" % [
		test_duration,
		test_fps,
		record_fps,
		avg_fps,
		min_fps,
		max_fps,
		_fps_drop_avg,
		_peak_memory_mb,
		"✓" if success else "✗"
	]

	print(report)


# =============================================================================
# UTILITY
# =============================================================================

func reset_test() -> void:
	"""Reset test state"""
	_is_running = false
	_fps_samples.clear()
	_fps_drops.clear()
	_memory_samples.clear()
	_start_time = 0.0
	_warmup_end_time = 0.0
	_recording_start_time = 0.0
	_frames_recorded = 0
	_frames_dropped = 0
	_peak_memory_mb = 0.0
