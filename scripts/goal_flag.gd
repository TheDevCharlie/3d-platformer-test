extends Area3D
class_name GoalFlag

@export var rotation_speed: float = 2.0
@onready var beacon_mesh: Node3D = $Visuals/Beacon
@onready var particles: CPUParticles3D = $CPUParticles3D

signal reached

var _is_reached: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if beacon_mesh:
		beacon_mesh.rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if _is_reached:
		return
		
	if body.is_in_group("player") or body is PlayerController or body.name == "Player":
		_trigger_reach()

func _on_area_entered(area: Area3D) -> void:
	if _is_reached:
		return
	if area.get_parent() and (area.get_parent().is_in_group("player") or area.get_parent() is PlayerController):
		_trigger_reach()

func _trigger_reach() -> void:
	_is_reached = true
	if particles:
		particles.emitting = true
	reached.emit()
