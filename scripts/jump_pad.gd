extends Area3D
class_name JumpPad

@export var launch_force: float = 20.0

@onready var visual_pad: Node3D = $Visuals/Pad
@onready var particles: CPUParticles3D = $CPUParticles3D

var _is_animating: bool = false
var _pad_initial_scale: Vector3

func _ready() -> void:
	if visual_pad:
		_pad_initial_scale = visual_pad.scale
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("launch"):
		body.launch(launch_force)
		_trigger_pad_animation()
	elif body is CharacterBody3D:
		body.velocity.y = launch_force
		_trigger_pad_animation()

func _trigger_pad_animation() -> void:
	if particles:
		particles.emitting = true
		
	if visual_pad and not _is_animating:
		_is_animating = true
		var tween: Tween = create_tween()
		tween.tween_property(visual_pad, "scale", Vector3(_pad_initial_scale.x * 1.3, _pad_initial_scale.y * 0.3, _pad_initial_scale.z * 1.3), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pad, "scale", Vector3(_pad_initial_scale.x * 0.8, _pad_initial_scale.y * 1.5, _pad_initial_scale.z * 0.8), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_pad, "scale", _pad_initial_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		_is_animating = false
