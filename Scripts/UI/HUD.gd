extends CanvasLayer
class_name HUD

## HUD - Heads-up display for the game

signal timer_updated(time: float)
signal speed_updated(speed: float)
signal ammo_updated(ammo: int)
signal weapon_changed(weapon: String)
signal checkpoint_updated(count: int)
signal targets_updated(count: int)

var timer_label: Label = null
var speed_label: Label = null
var ammo_label: Label = null
var weapon_label: Label = null
var checkpoint_label: Label = null
var target_label: Label = null

var _speed: float = 0.0
var _current_ammo: int = 12
var _current_weapon: String = "Pistol"
var _checkpoint_count: int = 0
var _active_targets: int = 3

func _ready() -> void:
	# Find HUD elements
	timer_label = $TimerLabel
	speed_label = $SpeedLabel
	ammo_label = $AmmoLabel
	weapon_label = $WeaponLabel
	checkpoint_label = $CheckpointLabel
	target_label = $TargetLabel
	
	# Connect to game signals
	var timer = SpeedrunTimer
	if timer:
		timer.timer_updated.connect(_on_timer_updated)
		timer.speed_updated.connect(_on_speed_updated)
		timer.ammo_updated.connect(_on_ammo_updated)
		timer.weapon_changed.connect(_on_weapon_changed)
		timer.checkpoint_updated.connect(_on_checkpoint_updated)
		timer.targets_updated.connect(_on_targets_updated)

func _on_timer_updated(time: float) -> void:
	if timer_label:
		timer_label.text = "Time: %.2f" % time

func _on_speed_updated(speed: float) -> void:
	_speed = speed
	if speed_label:
		speed_label.text = "Speed: %.0f u/s" % speed

func _on_ammo_updated(ammo: int) -> void:
	_current_ammo = ammo
	if ammo_label:
		ammo_label.text = "Ammo: %d" % ammo

func _on_weapon_changed(weapon: String) -> void:
	_current_weapon = weapon
	if weapon_label:
		weapon_label.text = "Weapon: %s" % weapon

func _on_checkpoint_updated(count: int) -> void:
	_checkpoint_count = count
	if checkpoint_label:
		checkpoint_label.text = "Checkpoint: %d/3" % count

func _on_targets_updated(count: int) -> void:
	_active_targets = count
	if target_label:
		target_label.text = "Targets: %d" % count