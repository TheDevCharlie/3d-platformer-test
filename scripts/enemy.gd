extends CharacterBody3D
class_name Enemy

enum State { PATROL, CHASE, RETURN }

# --- Health Parameters ---
@export_group("Health")
@export var max_health: float = 60.0

# --- Movement & AI Settings ---
@export_group("AI & Patrol")
@export var patrol_direction: Vector3 = Vector3(1, 0, 0)
@export var patrol_distance: float = 6.0
@export var patrol_speed: float = 2.5
@export var chase_speed: float = 3.8
@export var pause_at_endpoints: float = 0.5
@export var detection_radius: float = 9.0
@export var leash_distance: float = 14.0
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 0.75

# --- Combat Settings ---
@export_group("Combat")
@export var stomp_bounce_force: float = 14.0
@export var stomp_bonus_bounce_force: float = 17.5

# --- State Variables ---
var current_health: float = 60.0
var _current_state: State = State.PATROL
var _start_position: Vector3
var _target_position: Vector3
var _moving_to_target: bool = true
var _pause_timer: float = 0.0
var _attack_timer: float = 0.0
var _is_defeated: bool = false
var _walk_time: float = 0.0
var _player_target: PlayerController = null

# --- Node References ---
@onready var visuals: Node3D = $Visuals
@onready var body_mesh: Node3D = $Visuals/Body
@onready var main_collider: CollisionShape3D = $CollisionShape3D
@onready var head_hurtbox: Area3D = $HeadHurtbox
@onready var head_collision: CollisionShape3D = $HeadHurtbox/CollisionShape3D
@onready var body_hazard: Area3D = $BodyHazard
@onready var body_hazard_collision: CollisionShape3D = $BodyHazard/CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var defeat_particles: CPUParticles3D = $DefeatParticles
@onready var hp_bar_fill: MeshInstance3D = $HealthBarPivot/BarBackground/BarFill
@onready var hp_bar_pivot: Node3D = $HealthBarPivot

signal defeated

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	_start_position = global_position
	_target_position = _start_position + patrol_direction.normalized() * patrol_distance
	
	head_hurtbox.body_entered.connect(_on_head_entered)
	body_hazard.body_entered.connect(_on_body_entered)
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)
		
	_update_health_bar()

func _notification(what: int) -> void:
	# Ensure defeat signal is emitted even if deleted or fell into void without player stomp
	if what == NOTIFICATION_PREDELETE:
		if not _is_defeated:
			_is_defeated = true
			defeated.emit()

func _physics_process(delta: float) -> void:
	if _is_defeated:
		return
		
	# Fall check (killplane boundary for enemies)
	if global_position.y < -8.0:
		_die()
		return
		
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# AI State Machine
	match _current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.RETURN:
			_process_return(delta)

	# Continuous hazard attack check against overlapping player
	_process_hazard_attacks(delta)

	move_and_slide()
	_update_health_bar_facing()

func _process_patrol(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		return

	var dest: Vector3 = _target_position if _moving_to_target else _start_position
	var to_dest: Vector3 = (dest - global_position)
	to_dest.y = 0.0
	
	if to_dest.length() < 0.25:
		_moving_to_target = not _moving_to_target
		_pause_timer = pause_at_endpoints
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var move_dir: Vector3 = to_dest.normalized()
		velocity.x = move_dir.x * patrol_speed
		velocity.z = move_dir.z * patrol_speed
		_orient_and_bob(move_dir, patrol_speed, delta)

func _process_chase(delta: float) -> void:
	if not is_instance_valid(_player_target):
		_current_state = State.RETURN
		return
		
	var dist_from_start: float = (global_position - _start_position).length()
	var dist_to_player: float = (global_position - _player_target.global_position).length()
	
	# Leash check
	if dist_from_start > leash_distance or dist_to_player > detection_radius * 1.4:
		_player_target = null
		_current_state = State.RETURN
		return
		
	var to_player: Vector3 = (_player_target.global_position - global_position)
	to_player.y = 0.0
	
	# Approach player but keep a slight separation to avoid physics snagging
	if to_player.length() > 0.6:
		var move_dir: Vector3 = to_player.normalized()
		velocity.x = move_dir.x * chase_speed
		velocity.z = move_dir.z * chase_speed
		_orient_and_bob(move_dir, chase_speed, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

func _process_return(delta: float) -> void:
	var to_start: Vector3 = (_start_position - global_position)
	to_start.y = 0.0
	
	if to_start.length() < 0.3:
		_current_state = State.PATROL
		_moving_to_target = true
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var move_dir: Vector3 = to_start.normalized()
		velocity.x = move_dir.x * patrol_speed
		velocity.z = move_dir.z * patrol_speed
		_orient_and_bob(move_dir, patrol_speed, delta)

func _process_hazard_attacks(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
		return
		
	if not body_hazard:
		return
		
	var overlapping: Array[Node3D] = body_hazard.get_overlapping_bodies()
	for body: Node3D in overlapping:
		if body is PlayerController:
			var player: PlayerController = body as PlayerController
			_execute_attack_on_player(player)
			break

func _execute_attack_on_player(player: PlayerController) -> void:
	_attack_timer = attack_cooldown
	player.take_damage(attack_damage, global_position)
	
	# Recoil enemy slightly backwards so it doesn't get stuck overlapping inside player
	var push_back: Vector3 = (global_position - player.global_position).normalized()
	push_back.y = 0.0
	if push_back.length_squared() < 0.01:
		push_back = -visuals.global_transform.basis.z.normalized()
		
	velocity.x = push_back.x * 4.5
	velocity.z = push_back.z * 4.5

func _orient_and_bob(move_dir: Vector3, speed: float, delta: float) -> void:
	if move_dir.length_squared() > 0.01:
		var target_angle: float = atan2(-move_dir.x, -move_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 10.0 * delta)
		
	_walk_time += delta * speed * 4.0
	if body_mesh:
		body_mesh.position.y = 0.9 + sin(_walk_time) * 0.06
		body_mesh.rotation.z = sin(_walk_time * 0.5) * 0.06

func _on_player_detected(body: Node3D) -> void:
	if _is_defeated:
		return
	if body is PlayerController:
		_player_target = body as PlayerController
		_current_state = State.CHASE

func _on_player_lost(body: Node3D) -> void:
	if body == _player_target:
		var dist: float = (global_position - _player_target.global_position).length()
		if dist > detection_radius:
			_player_target = null
			_current_state = State.RETURN

func _on_head_entered(body: Node3D) -> void:
	if _is_defeated:
		return
		
	if body is PlayerController:
		var player: PlayerController = body as PlayerController
		# Stomp check: player must be above the enemy head and falling downward
		if player.global_position.y >= global_position.y + 1.3 and player.velocity.y <= 0.2:
			player.stomp_bounce(stomp_bounce_force, stomp_bonus_bounce_force)
			take_damage(60.0)

func _on_body_entered(body: Node3D) -> void:
	if _is_defeated:
		return
		
	if body is PlayerController and _attack_timer <= 0.0:
		var player: PlayerController = body as PlayerController
		_execute_attack_on_player(player)

func take_damage(amount: float) -> void:
	if _is_defeated:
		return
		
	current_health = maxf(current_health - amount, 0.0)
	_update_health_bar()
	
	# Damage reaction
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector3(1.2, 0.8, 1.2), 0.08).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(visuals, "scale", Vector3.ONE, 0.1).set_trans(Tween.TRANS_ELASTIC)
	
	if current_health <= 0.0:
		_die()

func _die() -> void:
	if _is_defeated:
		return
		
	_is_defeated = true
	defeated.emit()
	
	main_collider.set_deferred("disabled", true)
	head_collision.set_deferred("disabled", true)
	body_hazard_collision.set_deferred("disabled", true)
	
	if hp_bar_pivot:
		hp_bar_pivot.visible = false
	if defeat_particles:
		defeat_particles.emitting = true
		
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "scale", Vector3(1.5, 0.08, 1.5), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "position:y", 0.05, 0.12)
	
	await tween.finished
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(visuals, "scale", Vector3.ZERO, 0.25).set_delay(0.2)
	await fade_tween.finished
	queue_free()

func _update_health_bar() -> void:
	if not hp_bar_fill:
		return
	var hp_ratio: float = clampf(current_health / max_health, 0.0, 1.0)
	hp_bar_fill.scale.x = hp_ratio
	hp_bar_fill.position.x = -0.38 * (1.0 - hp_ratio)

func _update_health_bar_facing() -> void:
	if not hp_bar_pivot:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam:
		hp_bar_pivot.look_at(cam.global_position, Vector3.UP)
		hp_bar_pivot.rotation.x = 0.0
		hp_bar_pivot.rotation.z = 0.0
