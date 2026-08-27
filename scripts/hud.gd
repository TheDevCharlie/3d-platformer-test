extends CanvasLayer
class_name PlatformerHUD

# --- Top HUD Elements ---
@onready var coin_label: Label = $MarginContainer/VBoxContainer/TopBar/StatsContainer/CoinPanel/CoinMargin/CoinLabel
@onready var enemy_label: Label = $MarginContainer/VBoxContainer/TopBar/StatsContainer/EnemyPanel/EnemyMargin/EnemyLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/TopBar/StatsContainer/HPPanel/HPMargin/HPBox/HPLabel
@onready var hp_progress: ProgressBar = $MarginContainer/VBoxContainer/TopBar/StatsContainer/HPPanel/HPMargin/HPBox/HPProgressBar
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopBar/TimerPanel/TimerMargin/TimerLabel

# --- Debug Panel Elements ---
@onready var state_label: Label = $MarginContainer/VBoxContainer/DebugPanel/DebugMargin/DebugList/StateLabel
@onready var velocity_label: Label = $MarginContainer/VBoxContainer/DebugPanel/DebugMargin/DebugList/VelocityLabel
@onready var double_jump_label: Label = $MarginContainer/VBoxContainer/DebugPanel/DebugMargin/DebugList/DoubleJumpLabel
@onready var coyote_label: Label = $MarginContainer/VBoxContainer/DebugPanel/DebugMargin/DebugList/CoyoteLabel
@onready var buffer_label: Label = $MarginContainer/VBoxContainer/DebugPanel/DebugMargin/DebugList/BufferLabel

# --- Win & Lose Screens ---
@onready var victory_panel: Control = $VictoryScreen
@onready var victory_time_label: Label = $VictoryScreen/Center/Panel/Margin/VBox/TimeResultLabel
@onready var victory_coins_label: Label = $VictoryScreen/Center/Panel/Margin/VBox/CoinsResultLabel
@onready var victory_enemies_label: Label = $VictoryScreen/Center/Panel/Margin/VBox/EnemiesResultLabel
@onready var victory_restart_btn: Button = $VictoryScreen/Center/Panel/Margin/VBox/VictoryRestartBtn
@onready var game_over_panel: Control = $GameOverScreen
@onready var game_over_time_label: Label = $GameOverScreen/Center/Panel/Margin/VBox/TimeSurvivedLabel
@onready var game_over_restart_btn: Button = $GameOverScreen/Center/Panel/Margin/VBox/GameOverRestartBtn

signal restart_requested

var total_coins: int = 0
var collected_coins: int = 0
var total_enemies: int = 0
var defeated_enemies: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_node_references()
	update_stats_display()
	if victory_panel:
		victory_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
		
	if victory_restart_btn:
		victory_restart_btn.pressed.connect(_on_restart_button_pressed)
	if game_over_restart_btn:
		game_over_restart_btn.pressed.connect(_on_restart_button_pressed)

func _on_restart_button_pressed() -> void:
	restart_requested.emit()

func _resolve_node_references() -> void:
	if not coin_label:
		coin_label = find_child("CoinLabel", true, false) as Label
	if not enemy_label:
		enemy_label = find_child("EnemyLabel", true, false) as Label
	if not hp_label:
		hp_label = find_child("HPLabel", true, false) as Label
	if not hp_progress:
		hp_progress = find_child("HPProgressBar", true, false) as ProgressBar
	if not timer_label:
		timer_label = find_child("TimerLabel", true, false) as Label
	if not state_label:
		state_label = find_child("StateLabel", true, false) as Label
	if not velocity_label:
		velocity_label = find_child("VelocityLabel", true, false) as Label
	if not double_jump_label:
		double_jump_label = find_child("DoubleJumpLabel", true, false) as Label
	if not coyote_label:
		coyote_label = find_child("CoyoteLabel", true, false) as Label
	if not buffer_label:
		buffer_label = find_child("BufferLabel", true, false) as Label
	if not victory_panel:
		victory_panel = find_child("VictoryScreen", true, false) as Control
	if not victory_time_label:
		victory_time_label = find_child("TimeResultLabel", true, false) as Label
	if not victory_coins_label:
		victory_coins_label = find_child("CoinsResultLabel", true, false) as Label
	if not victory_enemies_label:
		victory_enemies_label = find_child("EnemiesResultLabel", true, false) as Label
	if not victory_restart_btn:
		victory_restart_btn = find_child("VictoryRestartBtn", true, false) as Button
	if not game_over_panel:
		game_over_panel = find_child("GameOverScreen", true, false) as Control
	if not game_over_time_label:
		game_over_time_label = find_child("TimeSurvivedLabel", true, false) as Label
	if not game_over_restart_btn:
		game_over_restart_btn = find_child("GameOverRestartBtn", true, false) as Button

func set_total_coins(count: int) -> void:
	total_coins = count
	update_stats_display()

func add_coin() -> void:
	collected_coins += 1
	update_stats_display()
	_animate_label(coin_label)

func set_total_enemies(count: int) -> void:
	total_enemies = count
	update_stats_display()

func add_defeated_enemy() -> void:
	defeated_enemies += 1
	update_stats_display()
	_animate_label(enemy_label)

func update_stats_display() -> void:
	if not coin_label:
		coin_label = find_child("CoinLabel", true, false) as Label
	if not enemy_label:
		enemy_label = find_child("EnemyLabel", true, false) as Label
		
	if coin_label:
		coin_label.text = "COINS: %d / %d" % [collected_coins, total_coins]
	if enemy_label:
		enemy_label.text = "ENEMIES: %d / %d" % [defeated_enemies, total_enemies]

func update_player_health(current: float, maximum: float) -> void:
	if not hp_label or not hp_progress:
		_resolve_node_references()
		
	if hp_progress:
		hp_progress.max_value = maximum
		hp_progress.value = current
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]
		if current <= 30.0:
			hp_label.modulate = Color.RED
		elif current <= 60.0:
			hp_label.modulate = Color.GOLD
		else:
			hp_label.modulate = Color.GREEN

func update_timer(formatted_time: String) -> void:
	if timer_label:
		timer_label.text = "⏱ TIME: %s" % formatted_time

func show_victory(final_time: String) -> void:
	if not victory_panel:
		_resolve_node_references()
	update_timer(final_time)
	if victory_time_label:
		victory_time_label.text = "Clear Time: %s" % final_time
	if victory_coins_label:
		victory_coins_label.text = "Coins Collected: %d / %d" % [collected_coins, total_coins]
	if victory_enemies_label:
		victory_enemies_label.text = "Enemies Defeated: %d / %d" % [defeated_enemies, total_enemies]
	if victory_panel:
		victory_panel.visible = true
		_pop_screen(victory_panel)

func show_game_over(final_time: String = "") -> void:
	if not game_over_panel:
		_resolve_node_references()
	if final_time != "":
		update_timer(final_time)
		if game_over_time_label:
			game_over_time_label.text = "Time Survived: %s" % final_time
	if game_over_panel:
		game_over_panel.visible = true
		_pop_screen(game_over_panel)

func hide_overlays() -> void:
	if victory_panel:
		victory_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false

func _pop_screen(screen: Control) -> void:
	screen.scale = Vector2(0.8, 0.8)
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(screen, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_label(lbl: Label) -> void:
	if not lbl:
		return
	var tween: Tween = create_tween()
	tween.tween_property(lbl, "scale", Vector2(1.25, 1.25), 0.1)
	tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15)

func update_debug(is_grounded: bool, air_jumps_left: int, coyote_active: bool, jump_buffered: bool, velocity: Vector3) -> void:
	if not state_label:
		return
		
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	
	if is_grounded:
		state_label.text = "Status: GROUNDED"
		state_label.modulate = Color.GREEN
	elif velocity.y > 0.1:
		state_label.text = "Status: JUMPING (Up)"
		state_label.modulate = Color.DODGER_BLUE
	else:
		state_label.text = "Status: FALLING (Down)"
		state_label.modulate = Color.ORANGE
		
	if velocity_label:
		velocity_label.text = "Speed: %0.1f m/s (Vert: %0.1f)" % [horizontal_speed, velocity.y]
	
	if double_jump_label:
		if air_jumps_left > 0:
			double_jump_label.text = "Double Jump: READY (%d)" % air_jumps_left
			double_jump_label.modulate = Color.CYAN
		else:
			double_jump_label.text = "Double Jump: Used"
			double_jump_label.modulate = Color(0.6, 0.6, 0.6)
			
	if coyote_label:
		if coyote_active:
			coyote_label.text = "Coyote Time: ACTIVE"
			coyote_label.modulate = Color.GOLD
		else:
			coyote_label.text = "Coyote Time: Inactive"
			coyote_label.modulate = Color(0.6, 0.6, 0.6)
		
	if buffer_label:
		if jump_buffered:
			buffer_label.text = "Jump Buffer: READY"
			buffer_label.modulate = Color.SPRING_GREEN
		else:
			buffer_label.text = "Jump Buffer: Empty"
			buffer_label.modulate = Color(0.6, 0.6, 0.6)
