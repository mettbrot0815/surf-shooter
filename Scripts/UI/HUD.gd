extends CanvasLayer
class_name HUD

@onready var timer_label: Label = $TimerLabel
@onready var speed_label: Label = $SpeedLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel

var _timer: SpeedrunTimer = null
var _weapon_system: WeaponSystem = null
var _player: SurfPhysicsController = null

func _ready() -> void:
	_timer = SpeedrunTimer
	_weapon_system = get_tree().get_first_node_in_group("weapon_system")
	_player = get_tree().get_first_node_in_group("players")

	if _weapon_system:
		_weapon_system.weapon_changed.connect(_on_weapon_changed)
		_weapon_system.ammo_updated.connect(_on_ammo_updated)

func _process(_delta: float) -> void:
	if _timer:
		var time = _timer.get_elapsed_time_seconds()
		timer_label.text = "Time: %.2f" % time

	if _player:
		var speed = _player.get_current_speed()
		speed_label.text = "Speed: %.0f u/s" % speed

func _on_weapon_changed(weapon_type: String) -> void:
	weapon_label.text = "Weapon: " + weapon_type.capitalize()

func _on_ammo_updated(weapon_type: String, ammo: int) -> void:
	ammo_label.text = "Ammo: " + str(ammo)