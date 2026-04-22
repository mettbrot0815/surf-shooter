extends CanvasLayer
class_name MainMenu

func _ready() -> void:
	visible = true  # Show menu by default

func _on_start_pressed() -> void:
	visible = false
	# Start the game - perhaps load level or just hide menu

func _on_quit_pressed() -> void:
	get_tree().quit()