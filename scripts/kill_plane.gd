extends Area3D
class_name KillPlane

@export var respawn_point: Node3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not respawn_point:
		respawn_point = get_tree().root.find_child("SpawnPoint", true, false)

func _on_body_entered(body: Node3D) -> void:
	if not respawn_point:
		respawn_point = get_tree().root.find_child("SpawnPoint", true, false)
		
	var spawn_pos: Vector3 = respawn_point.global_position if respawn_point else Vector3(0, 2, 0)
	
	if body is PlayerController or body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(100.0, spawn_pos)
		elif body.has_signal("died"):
			body.emit_signal("died")
	elif body is CharacterBody3D:
		body.global_position = spawn_pos
		body.velocity = Vector3.ZERO
