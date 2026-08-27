extends AnimatableBody3D
class_name MovingPlatform

@export var move_offset: Vector3 = Vector3(8, 0, 0)
@export var move_duration: float = 3.0
@export var pause_duration: float = 0.5

var _start_position: Vector3
var _target_position: Vector3
var _tween: Tween

func _ready() -> void:
	# Ensure physics sync is enabled so characters ride smoothly
	sync_to_physics = true
	_start_position = global_position
	_target_position = _start_position + move_offset
	_start_moving()

func _start_moving() -> void:
	_tween = create_tween().set_loops()
	
	# Move to target
	_tween.tween_property(self, "global_position", _target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(pause_duration)
	
	# Move back to start
	_tween.tween_property(self, "global_position", _start_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(pause_duration)

