extends Control
class_name PauseMenu

@onready var resume_btn: Button = $Center/Panel/Margin/VBox/ResumeBtn
@onready var restart_btn: Button = $Center/Panel/Margin/VBox/RestartBtn
@onready var main_menu_btn: Button = $Center/Panel/Margin/VBox/MainMenuBtn

signal resume_requested
signal restart_requested
signal main_menu_requested

var _is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		# Toggle pause
		if _is_paused:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	# Don't pause if already in victory or game over
	var main_node: Node = get_tree().current_scene
	if main_node and main_node.get("_game_state") != null:
		var state: int = int(main_node.get("_game_state"))
		if state != 0: # Not PLAYING
			return
			
	_is_paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func resume_game() -> void:
	_is_paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	resume_requested.emit()

func _on_resume_pressed() -> void:
	resume_game()

func _on_restart_pressed() -> void:
	_is_paused = false
	visible = false
	get_tree().paused = false
	restart_requested.emit()

func _on_main_menu_pressed() -> void:
	_is_paused = false
	visible = false
	get_tree().paused = false
	main_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
