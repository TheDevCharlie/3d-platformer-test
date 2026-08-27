extends Node3D

@onready var play_btn: Button = $UI/Margin/VBox/MenuButtons/PlayBtn
@onready var controls_btn: Button = $UI/Margin/VBox/MenuButtons/ControlsBtn
@onready var quit_btn: Button = $UI/Margin/VBox/MenuButtons/QuitBtn
@onready var controls_modal: Control = $UI/ControlsModal
@onready var close_controls_btn: Button = $UI/ControlsModal/Center/Panel/Margin/VBox/CloseControlsBtn
@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	
	if controls_modal:
		controls_modal.visible = false
		
	if play_btn:
		play_btn.pressed.connect(_on_play_pressed)
	if controls_btn:
		controls_btn.pressed.connect(_on_controls_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if close_controls_btn:
		close_controls_btn.pressed.connect(_on_close_controls_pressed)

func _process(delta: float) -> void:
	if camera_pivot:
		camera_pivot.rotate_y(0.25 * delta)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_controls_pressed() -> void:
	if controls_modal:
		controls_modal.visible = true

func _on_close_controls_pressed() -> void:
	if controls_modal:
		controls_modal.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
