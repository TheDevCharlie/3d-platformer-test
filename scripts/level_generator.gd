extends Node3D
class_name LevelGenerator

# --- Packed Scene Prefabs ---
const COIN_SCENE: PackedScene = preload("res://scenes/coin.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const JUMP_PAD_SCENE: PackedScene = preload("res://scenes/jump_pad.tscn")
const MOVING_PLATFORM_SCENE: PackedScene = preload("res://scenes/moving_platform.tscn")
const GOAL_FLAG_SCENE: PackedScene = preload("res://scenes/goal_flag.tscn")

func generate_level(level_index: int, world_root: Node3D) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = level_index * 1337 + 42

	var theme_id: int = (level_index - 1) % 4
	var theme_data: Dictionary = _get_theme_data(theme_id)
	_apply_environment_theme(world_root, theme_data)

	var geom_root: Node3D = world_root.find_child("LevelGeometry", true, false) as Node3D
	var enemies_root: Node3D = world_root.find_child("Enemies", true, false) as Node3D
	var coins_root: Node3D = world_root.find_child("Coins", true, false) as Node3D
	var goal_node: GoalFlag = world_root.find_child("GoalFlag", true, false) as GoalFlag
	var moving_plats: Array[Node] = world_root.get_tree().get_nodes_in_group("moving_platform")

	# Clear previous dynamically generated children
	if geom_root:
		for child: Node in geom_root.get_children():
			child.queue_free()
	if enemies_root:
		for child: Node in enemies_root.get_children():
			child.queue_free()
	if coins_root:
		for child: Node in coins_root.get_children():
			child.queue_free()
	if goal_node:
		goal_node.queue_free()
	for plat: Node in moving_plats:
		plat.queue_free()

	# 1. Start Hub
	var start_box: CSGBox3D = CSGBox3D.new()
	start_box.name = "StartHub"
	start_box.size = Vector3(16, 1, 16)
	start_box.position = Vector3(0, -0.5, 0)
	start_box.use_collision = true
	start_box.material = theme_data["mat_ground"] as Material
	if geom_root:
		geom_root.add_child(start_box)

	# 2. Procedural Path Generation
	var current_pos: Vector3 = Vector3(0, 0, 0)
	var platform_count: int = 6 + (level_index % 3) * 2
	var last_pos: Vector3 = current_pos

	var directions: Array[Vector3] = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1),
		Vector3(1, 0, 1).normalized(), Vector3(-1, 0, 1).normalized(),
		Vector3(1, 0, -1).normalized(), Vector3(-1, 0, -1).normalized()
	]

	for i: int in range(platform_count):
		var step_dir: Vector3 = directions[rng.randi() % directions.size()]
		var step_dist: float = rng.randf_range(9.0, 14.0)
		var height_delta: float = rng.randf_range(1.2, 3.0)
		
		current_pos += step_dir * step_dist
		current_pos.y += height_delta
		
		var plat_type: int = rng.randi() % 4 # 0=Static, 1=Moving, 2=JumpPad, 3=EnemyPlatform
		
		if plat_type == 1 and MOVING_PLATFORM_SCENE:
			# Moving Platform
			var moving_plat: Node3D = MOVING_PLATFORM_SCENE.instantiate() as Node3D
			moving_plat.position = current_pos
			var move_offset: Vector3 = Vector3(rng.randf_range(-6.0, 6.0), 0, rng.randf_range(-6.0, 6.0))
			moving_plat.set("move_offset", move_offset)
			moving_plat.set("move_duration", rng.randf_range(2.8, 4.0))
			world_root.add_child(moving_plat)
			
			# Coin on moving platform
			_spawn_coin(coins_root, current_pos + Vector3(0, 1.2, 0))
		else:
			# Static CSG Box Platform
			var plat: CSGBox3D = CSGBox3D.new()
			var p_size: Vector3 = Vector3(rng.randf_range(5.0, 8.0), 1.0, rng.randf_range(5.0, 8.0))
			plat.size = p_size
			plat.position = current_pos - Vector3(0, 0.5, 0)
			plat.use_collision = true
			plat.material = theme_data["mat_platform"] as Material
			if geom_root:
				geom_root.add_child(plat)

			# Spawn items on platform
			if plat_type == 2 and JUMP_PAD_SCENE:
				var pad: Node3D = JUMP_PAD_SCENE.instantiate() as Node3D
				pad.position = current_pos + Vector3(0, 0.1, 0)
				world_root.add_child(pad)
				_spawn_coin(coins_root, current_pos + Vector3(0, 4.5, 0))
			elif plat_type == 3 and ENEMY_SCENE:
				var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
				enemy.position = current_pos + Vector3(0, 0.1, 0)
				enemy.patrol_direction = step_dir
				enemy.patrol_distance = p_size.x * 0.4
				if enemies_root:
					enemies_root.add_child(enemy)
				_spawn_coin(coins_root, current_pos + Vector3(0, 1.5, 0))
			else:
				_spawn_coin(coins_root, current_pos + Vector3(0, 1.2, 0))

		last_pos = current_pos

	# 3. Final Sky Island with Goal Beacon
	var goal_pos: Vector3 = last_pos + Vector3(0, 3.5, 0) + directions[rng.randi() % directions.size()] * 10.0
	var sky_island: CSGBox3D = CSGBox3D.new()
	sky_island.name = "SkyIslandGoal"
	sky_island.size = Vector3(8, 1, 8)
	sky_island.position = goal_pos - Vector3(0, 0.5, 0)
	sky_island.use_collision = true
	sky_island.material = theme_data["mat_accent"] as Material
	if geom_root:
		geom_root.add_child(sky_island)

	if GOAL_FLAG_SCENE:
		var new_goal: GoalFlag = GOAL_FLAG_SCENE.instantiate() as GoalFlag
		new_goal.position = goal_pos
		world_root.add_child(new_goal)

	return {
		"theme_name": theme_data["name"],
		"level_index": level_index
	}

func _spawn_coin(coins_root: Node3D, pos: Vector3) -> void:
	if not coins_root or not COIN_SCENE:
		return
	var coin: Node3D = COIN_SCENE.instantiate() as Node3D
	coin.position = pos
	coins_root.add_child(coin)

func _get_theme_data(theme_id: int) -> Dictionary:
	var themes: Array[Dictionary] = [
		{
			"name": "Emerald Haven",
			"sky_top": Color(0.28, 0.58, 0.98),
			"sky_horizon": Color(0.72, 0.84, 0.95),
			"ground_color": Color(0.35, 0.7, 0.4),
			"plat_color": Color(0.22, 0.26, 0.34),
			"accent_color": Color(1.0, 0.8, 0.2)
		},
		{
			"name": "Sunset Canyon",
			"sky_top": Color(0.85, 0.35, 0.2),
			"sky_horizon": Color(0.98, 0.75, 0.5),
			"ground_color": Color(0.82, 0.48, 0.3),
			"plat_color": Color(0.38, 0.2, 0.15),
			"accent_color": Color(1.0, 0.6, 0.1)
		},
		{
			"name": "Cyber Metropolis",
			"sky_top": Color(0.2, 0.08, 0.38),
			"sky_horizon": Color(0.55, 0.2, 0.65),
			"ground_color": Color(0.12, 0.15, 0.22),
			"plat_color": Color(0.1, 0.65, 0.85),
			"accent_color": Color(0.95, 0.15, 0.65)
		},
		{
			"name": "Glacial Peaks",
			"sky_top": Color(0.45, 0.7, 0.95),
			"sky_horizon": Color(0.85, 0.92, 0.98),
			"ground_color": Color(0.88, 0.94, 0.98),
			"plat_color": Color(0.28, 0.48, 0.68),
			"accent_color": Color(0.2, 0.85, 0.95)
		}
	]

	var cur: Dictionary = themes[theme_id % themes.size()]
	
	var mat_ground: StandardMaterial3D = StandardMaterial3D.new()
	mat_ground.albedo_color = cur["ground_color"] as Color
	mat_ground.roughness = 0.6

	var mat_platform: StandardMaterial3D = StandardMaterial3D.new()
	mat_platform.albedo_color = cur["plat_color"] as Color
	mat_platform.roughness = 0.45

	var mat_accent: StandardMaterial3D = StandardMaterial3D.new()
	mat_accent.albedo_color = cur["accent_color"] as Color
	mat_accent.roughness = 0.3
	mat_accent.emission_enabled = true
	mat_accent.emission = cur["accent_color"] as Color
	mat_accent.emission_energy_multiplier = 0.5

	return {
		"name": cur["name"],
		"sky_top": cur["sky_top"],
		"sky_horizon": cur["sky_horizon"],
		"mat_ground": mat_ground,
		"mat_platform": mat_platform,
		"mat_accent": mat_accent
	}

func _apply_environment_theme(world_root: Node3D, theme_data: Dictionary) -> void:
	var world_env: WorldEnvironment = world_root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if not world_env or not world_env.environment:
		return
	var env: Environment = world_env.environment
	if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
		var sky_mat: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
		sky_mat.sky_top_color = theme_data["sky_top"] as Color
		sky_mat.sky_horizon_color = theme_data["sky_horizon"] as Color
