extends CanvasLayer

class_name DebugOverlay

## Debug overlay showing velocity, speed, timer, and togglable debug visuals.

@onready var velocity_label: Label = $VBoxContainer/VelocityLabel
@onready var speed_label: Label = $VBoxContainer/SpeedLabel
@onready var peak_speed_label: Label = $VBoxContainer/PeakSpeedLabel
@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var debug_toggle: Button = $DebugToggle

var show_debug: bool = true

@onready var player: SurfPhysicsController = get_parent().get_node("Player")

func _ready() -> void:
    debug_toggle.connect("pressed", Callable(self, "_toggle_debug"))

func _process(delta: float) -> void:
    if show_debug:
        velocity_label.text = "Velocity: %.2f, %.2f, %.2f" % [player.velocity.x, player.velocity.y, player.velocity.z]
        var horiz_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
        speed_label.text = "Speed: %.2f" % horiz_speed
        peak_speed_label.text = "Peak Speed: %.2f" % player.peak_speed
        timer_label.text = "Timer: " + SpeedrunTimer.get_formatted_time(SpeedrunTimer.current_time)

func _toggle_debug() -> void:
    show_debug = !show_debug
    $VBoxContainer.visible = show_debug