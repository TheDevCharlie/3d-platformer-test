extends Area3D
class_name Coin

@export var rotation_speed: float = 3.0
@export var float_speed: float = 2.5
@export var float_amplitude: float = 0.25

var _initial_y: float = 0.0
var _time_passed: float = 0.0
var _is_collected: bool = false

@onready var visual_mesh: Node3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var particles: CPUParticles3D = $CPUParticles3D

signal collected

func _ready() -> void:
	add_to_group("coin")
	_initial_y = position.y
	_time_passed = randf() * 10.0
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _is_collected:
		return
		
	_time_passed += delta
	position.y = _initial_y + sin(_time_passed * float_speed) * float_amplitude
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if _is_collected:
		return
		
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	_is_collected = true
	collected.emit()
	collision_shape.set_deferred("disabled", true)
	
	if particles:
		particles.emitting = true
		
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visual_mesh, "position:y", visual_mesh.position.y + 1.2, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_mesh, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await tween.finished
	await get_tree().create_timer(0.3).timeout
	queue_free()

