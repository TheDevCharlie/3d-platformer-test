extends CharacterBody3D
class_name PlayerController

# --- Health Parameters ---
@export_group("Health")
@export var max_health: float = 100.0

# --- Movement Parameters ---
@export_group("Movement")
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 11.5
@export var acceleration: float = 45.0
@export var friction: float = 35.0
@export var air_acceleration: float = 25.0
@export var air_friction: float = 8.0
@export var rotation_speed: float = 14.0

# --- Jump Parameters ---
@export_group("Jumping & Game Feel")
@export var jump_velocity: float = 11.5
@export var double_jump_velocity: float = 11.5
@export var max_air_jumps: int = 1
@export var gravity_up: float = 28.0
@export var gravity_down: float = 38.0
@export var variable_jump_gravity_mult: float = 2.0
@export var coyote_duration: float = 0.15
@export var jump_buffer_duration: float = 0.15
@export var terminal_velocity: float = 45.0

# --- Camera Parameters ---
@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -75.0
@export var max_pitch: float = 35.0

# --- State Variables ---
var current_health: float = 100.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _air_jumps_left: int = 1
var _was_on_floor: bool = false
var _camera_rotation: Vector2 = Vector2.ZERO
var _initial_mesh_scale: Vector3 = Vector3.ONE
var _squash_tween: Tween
var _is_invulnerable: bool = false
var _knockback_timer: float = 0.0
var _is_dead: bool = false

# --- Signals ---
signal health_changed(current: float, maximum: float)
signal died

# --- Node References ---
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals
@onready var character_mesh: Node3D = $Visuals/CharacterMesh
@onready var ground_raycast: RayCast3D = $GroundRayCast
@onready var shadow_mesh: MeshInstance3D = $ShadowProjector
@onready var jump_particles: CPUParticles3D = $JumpParticles
@onready var land_particles: CPUParticles3D = $LandParticles

var hud: PlatformerHUD = null

func _ready() -> void:
	add_to_group("player")
	_ensure_input_mappings()
	current_health = max_health
	_air_jumps_left = max_air_jumps
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if character_mesh:
		_initial_mesh_scale = character_mesh.scale
	
	if shadow_mesh:
		shadow_mesh.top_level = true
		shadow_mesh.global_rotation = Vector3.ZERO

	call_deferred("_find_hud")

func _find_hud() -> void:
	hud = get_tree().root.find_child("HUD", true, false) as PlatformerHUD
	if hud:
		hud.update_player_health(current_health, max_health)

func _input(event: InputEvent) -> void:
	if _is_dead:
		return
		
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_rotation.x -= event.relative.x * mouse_sensitivity
		_camera_rotation.y -= event.relative.y * mouse_sensitivity
		_camera_rotation.y = clampf(_camera_rotation.y, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		
		if camera_pivot and spring_arm:
			camera_pivot.rotation.y = _camera_rotation.x
			spring_arm.rotation.x = _camera_rotation.y

	# Mouse click window capture
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Toggle mouse cursor capture
	if event.is_action_pressed("pause") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Jump / Double Jump
	if event.is_action_pressed("jump"):
		if is_on_floor() or _coyote_timer > 0.0:
			_jump_buffer_timer = jump_buffer_duration
		elif _air_jumps_left > 0:
			_execute_double_jump()

	# Respawn / Quick Reset
	if event.is_action_pressed("reset"):
		respawn(Vector3(0, 2, 0))

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
		
	var on_floor: bool = is_on_floor()
	
	# --- Timers & State Updates ---
	if _knockback_timer > 0.0:
		_knockback_timer -= delta

	if on_floor:
		_coyote_timer = coyote_duration
		_air_jumps_left = max_air_jumps
		if not _was_on_floor:
			_on_landed()
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	
	# --- Ground Jump Trigger ---
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_execute_jump()

	# --- Gravity & Vertical Movement ---
	_apply_gravity(delta, on_floor)

	# --- Horizontal Movement ---
	_apply_movement(delta, on_floor)

	# --- Character Mesh Orientation ---
	_rotate_visuals_to_motion(delta)

	# --- Execute Physics ---
	move_and_slide()

	# --- Landing Blob Shadow Projection ---
	_update_blob_shadow()

	# --- State Bookkeeping ---
	_was_on_floor = on_floor

	# --- Update Debug HUD ---
	if hud:
		hud.update_debug(on_floor, _air_jumps_left, _coyote_timer > 0.0 and not on_floor, _jump_buffer_timer > 0.0, velocity)

func _execute_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_apply_squash_and_stretch(Vector3(0.75, 1.35, 0.75), 0.18)
	
	if jump_particles:
		jump_particles.restart()
		jump_particles.emitting = true

func _execute_double_jump() -> void:
	_air_jumps_left -= 1
	velocity.y = double_jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_apply_squash_and_stretch(Vector3(0.7, 1.45, 0.7), 0.2)
	
	if jump_particles:
		jump_particles.restart()
		jump_particles.emitting = true

func _on_landed() -> void:
	_apply_squash_and_stretch(Vector3(1.3, 0.7, 1.3), 0.15)
	
	if land_particles:
		land_particles.restart()
		land_particles.emitting = true

func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor:
		if velocity.y < 0.0:
			velocity.y = 0.0
		return

	var current_gravity: float = gravity_down
	
	if velocity.y > 0.0:
		if Input.is_action_pressed("jump"):
			current_gravity = gravity_up
		else:
			current_gravity = gravity_up * variable_jump_gravity_mult
			
	velocity.y -= current_gravity * delta
	velocity.y = maxf(velocity.y, -terminal_velocity)

func _apply_movement(delta: float, on_floor: bool) -> void:
	# Preserve knockback impulse without immediately overriding with input
	if _knockback_timer > 0.0:
		var decay_speed: float = friction * 0.5 if on_floor else air_friction * 0.5
		velocity.x = move_toward(velocity.x, 0.0, decay_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, decay_speed * delta)
		return

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var target_speed: float = sprint_speed if is_sprinting else walk_speed

	var camera_yaw: float = camera_pivot.global_transform.basis.get_euler().y
	var cam_forward: Vector3 = -Vector3(sin(camera_yaw), 0, cos(camera_yaw)).normalized()
	var cam_right: Vector3 = Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()
	
	var move_direction: Vector3 = (cam_right * input_vector.x + cam_forward * (-input_vector.y)).normalized()

	var accel: float = acceleration if on_floor else air_acceleration
	var frict: float = friction if on_floor else air_friction

	var horizontal_vel: Vector3 = Vector3(velocity.x, 0, velocity.z)
	
	if move_direction.length_squared() > 0.001:
		var target_vel: Vector3 = move_direction * target_speed
		horizontal_vel = horizontal_vel.move_toward(target_vel, accel * delta)
	else:
		horizontal_vel = horizontal_vel.move_toward(Vector3.ZERO, frict * delta)

	velocity.x = horizontal_vel.x
	velocity.z = horizontal_vel.z

func _rotate_visuals_to_motion(delta: float) -> void:
	var horizontal_dir: Vector3 = Vector3(velocity.x, 0, velocity.z)
	if horizontal_dir.length_squared() > 0.2:
		var target_angle: float = atan2(-horizontal_dir.x, -horizontal_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)

func _update_blob_shadow() -> void:
	if not ground_raycast or not shadow_mesh:
		return
		
	if ground_raycast.is_colliding():
		shadow_mesh.visible = true
		var hit_point: Vector3 = ground_raycast.get_collision_point()
		shadow_mesh.global_position = hit_point + Vector3(0, 0.03, 0)
		shadow_mesh.global_rotation = Vector3.ZERO
		
		var distance: float = global_position.y - hit_point.y
		var shadow_scale: float = clampf(1.0 - (distance / 15.0), 0.3, 1.0)
		shadow_mesh.scale = Vector3(shadow_scale, 1.0, shadow_scale)
	else:
		shadow_mesh.visible = false

func _apply_squash_and_stretch(target_scale_mult: Vector3, duration: float) -> void:
	if not character_mesh:
		return
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
		
	_squash_tween = create_tween()
	var squashed_scale: Vector3 = _initial_mesh_scale * target_scale_mult
	_squash_tween.tween_property(character_mesh, "scale", squashed_scale, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(character_mesh, "scale", _initial_mesh_scale, duration * 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func stomp_bounce(base_force: float, bonus_force: float) -> void:
	var force: float = bonus_force if Input.is_action_pressed("jump") else base_force
	velocity.y = force
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_air_jumps_left = max_air_jumps
	_apply_squash_and_stretch(Vector3(0.68, 1.45, 0.68), 0.2)
	
	if jump_particles:
		jump_particles.restart()
		jump_particles.emitting = true

func launch(launch_force: float) -> void:
	velocity.y = launch_force
	_air_jumps_left = max_air_jumps
	_apply_squash_and_stretch(Vector3(0.65, 1.5, 0.65), 0.25)
	if jump_particles:
		jump_particles.restart()
		jump_particles.emitting = true

func take_damage(amount: float, hazard_source_pos: Vector3) -> void:
	if _is_invulnerable or _is_dead:
		return
		
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if hud:
		hud.update_player_health(current_health, max_health)
		
	if current_health <= 0.0:
		_die()
		return
		
	_is_invulnerable = true
	_knockback_timer = 0.22
	
	var knockback_dir: Vector3 = (global_position - hazard_source_pos).normalized()
	knockback_dir.y = 0.0
	if knockback_dir.length_squared() < 0.01:
		knockback_dir = Vector3(0, 0, 1)
	
	velocity = knockback_dir * 9.5 + Vector3(0, 5.5, 0)
	_apply_squash_and_stretch(Vector3(1.3, 0.7, 1.3), 0.2)
	
	# Flicker visibility for invulnerability period
	var flash_tween: Tween = create_tween()
	for i: int in range(4):
		flash_tween.tween_callback(func() -> void: if visuals: visuals.visible = false)
		flash_tween.tween_interval(0.06)
		flash_tween.tween_callback(func() -> void: if visuals: visuals.visible = true)
		flash_tween.tween_interval(0.06)
	await flash_tween.finished
	_is_invulnerable = false

func _die() -> void:
	_is_dead = true
	died.emit()
	velocity = Vector3.ZERO
	if shadow_mesh:
		shadow_mesh.visible = false
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector3(1.4, 0.1, 1.4), 0.15)

func respawn(spawn_pos: Vector3) -> void:
	_is_dead = false
	_is_invulnerable = false
	_knockback_timer = 0.0
	current_health = max_health
	health_changed.emit(current_health, max_health)
	if hud:
		hud.update_player_health(current_health, max_health)
	global_position = spawn_pos
	velocity = Vector3.ZERO
	_air_jumps_left = max_air_jumps
	if character_mesh:
		character_mesh.scale = _initial_mesh_scale
	if visuals:
		visuals.scale = Vector3.ONE
		visuals.visible = true

func _ensure_input_mappings() -> void:
	var actions: Dictionary = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"reset": [KEY_R],
		"pause": [KEY_ESCAPE]
	}
	
	for action_name: String in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var keys: Array = actions[action_name] as Array
			for key_variant: Variant in keys:
				var key: int = int(key_variant)
				var ev: InputEventKey = InputEventKey.new()
				ev.physical_keycode = key
				InputMap.action_add_event(action_name, ev)
