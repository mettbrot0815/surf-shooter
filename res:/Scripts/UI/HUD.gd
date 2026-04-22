extends CanvasLayer

class_name HUD

## Main HUD displaying timer, speedometer, ammo, current weapon.

@onready var timer_label: Label = $TimerLabel
@onready var speed_label: Label = $SpeedLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel

@onready var player: SurfPhysicsController = get_parent().get_node("Player")
@onready var weapon_system: WeaponSystem = player.get_node("WeaponSystem")

func _process(delta: float) -> void:
    timer_label.text = SpeedrunTimer.get_formatted_time(SpeedrunTimer.current_time)
    var horiz_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
    speed_label.text = "%.0f u/s" % horiz_speed
    var weapon = weapon_system.weapons[weapon_system.current_weapon_index]
    ammo_label.text = "%d/%d" % [weapon_system.current_ammo, weapon_system.reserve_ammo[weapon["name"]]]
    weapon_label.text = weapon["name"]