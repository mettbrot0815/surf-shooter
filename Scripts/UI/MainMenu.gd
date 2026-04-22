extends CanvasLayer
class_name MainMenu

func _ready() -> void:
	visible = true  # Show menu by default

func _on_start_pressed() -> void:
	visible = false
	# Start the timer
	var timer = SpeedrunTimer
	if timer:
		timer.start_timer()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("practice_mode"):
		var timer = SpeedrunTimer
		if timer:
			if timer.is_practice_mode():
				timer.disable_practice_mode()
			else:
				timer.enable_practice_mode()
			print("Practice mode:", timer.is_practice_mode())