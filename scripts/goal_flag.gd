extends Area3D
class_name GoalFlag

@export var rotation_speed: float = 2.0
@onready var beacon_mesh: Node3D = $Visuals/Beacon
@onready var particles: CPUParticles3D = $CPUParticles3D

signal reached

var _is_reached: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if beacon_mesh:
		beacon_mesh.rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if _is_reached:
		return
		
	if body is PlayerController:
		_is_reached = true
		if particles:
			particles.emitting = true
		reached.emit()

