extends Node3D

enum GameState { PLAYING, WON, GAME_OVER }

@onready var hud: PlatformerHUD = $HUD
@onready var player: PlayerController = $Player
@onready var coins_container: Node3D = $Coins
@onready var enemies_container: Node3D = $Enemies
@onready var goal_flag: GoalFlag = $GoalFlag

var _game_state: GameState = GameState.PLAYING
var _elapsed_time: float = 0.0
var _defeated_enemy_ids: Dictionary = {}
var _total_coins_in_level: int = 0
var _collected_coins_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_game_state = GameState.PLAYING
	_elapsed_time = 0.0
	
	await get_tree().process_frame
	_setup_level_entities()

func _process(delta: float) -> void:
	# Only accumulate and update time while actively playing and unpaused
	if _game_state == GameState.PLAYING and not get_tree().paused:
		_elapsed_time += delta
		if hud:
			hud.update_timer(get_formatted_time(_elapsed_time))

func _input(event: InputEvent) -> void:
	# Pressing R anywhere restarts the run cleanly
	if event.is_action_pressed("reset") or (event is InputEventKey and event.keycode == KEY_R and event.pressed):
		restart_game()

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _setup_level_entities() -> void:
	if not hud:
		hud = find_child("HUD", true, false) as PlatformerHUD
	if not player:
		player = find_child("Player", true, false) as PlayerController
	if not goal_flag:
		goal_flag = find_child("GoalFlag", true, false) as GoalFlag

	if hud:
		if not hud.restart_requested.is_connected(restart_game):
			hud.restart_requested.connect(restart_game)

	# Connect Player Death
	if player:
		if not player.died.is_connected(_trigger_game_over):
			player.died.connect(_trigger_game_over)

	# Connect Goal Flag
	if goal_flag:
		if not goal_flag.reached.is_connected(_trigger_victory):
			goal_flag.reached.connect(_trigger_victory)

	# Gather and count Coins
	var coins: Array[Node] = []
	if coins_container:
		coins = coins_container.get_children()
	else:
		coins = get_tree().get_nodes_in_group("coin")

	_total_coins_in_level = coins.size()
	if hud:
		hud.set_total_coins(_total_coins_in_level)
		
	for coin: Node in coins:
		if coin is Coin:
			var c: Coin = coin as Coin
			if not c.collected.is_connected(_on_coin_collected):
				c.collected.connect(_on_coin_collected)

	# Gather and count Enemies
	var enemies: Array[Node] = []
	if enemies_container:
		enemies = enemies_container.get_children()
	else:
		enemies = get_tree().get_nodes_in_group("enemy")

	if hud:
		hud.set_total_enemies(enemies.size())
		
	for enemy: Node in enemies:
		if enemy is Enemy:
			var e: Enemy = enemy as Enemy
			var enemy_id: int = e.get_instance_id()
			e.defeated.connect(func() -> void: _on_enemy_eliminated(enemy_id))
			e.tree_exited.connect(func() -> void: _on_enemy_eliminated(enemy_id))

func _on_coin_collected() -> void:
	_collected_coins_count += 1
	if hud:
		hud.add_coin()
	# Win condition: collecting all coins
	if _collected_coins_count >= _total_coins_in_level and _total_coins_in_level > 0:
		_trigger_victory()

func _on_enemy_eliminated(enemy_id: int) -> void:
	if _defeated_enemy_ids.has(enemy_id):
		return
	_defeated_enemy_ids[enemy_id] = true
	if hud:
		hud.add_defeated_enemy()

func _trigger_victory() -> void:
	if _game_state != GameState.PLAYING:
		return
		
	_game_state = GameState.WON
	var final_time_str: String = get_formatted_time(_elapsed_time)
	
	if hud:
		hud.update_timer(final_time_str)
		hud.show_victory(final_time_str)
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _trigger_game_over() -> void:
	if _game_state != GameState.PLAYING:
		return
		
	_game_state = GameState.GAME_OVER
	var final_time_str: String = get_formatted_time(_elapsed_time)
	
	if hud:
		hud.update_timer(final_time_str)
		hud.show_game_over(final_time_str)
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func get_formatted_time(seconds_total: float) -> String:
	var minutes: int = int(seconds_total / 60.0)
	var seconds: int = int(fmod(seconds_total, 60.0))
	var centiseconds: int = int(fmod(seconds_total * 100.0, 100.0))
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
