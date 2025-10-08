extends Control

@export var main_scene_path: String = "res://scenes/main.tscn"
@onready var music = $AudioBackground
@onready var click = $AudioButton

func _ready():
	# Set background
	music.volume_db = 2  # lower volume slightly
	music.play()
	# Connect buttons
	$Buttons/BattleButton.pressed.connect(_on_battle_pressed)

func _on_battle_pressed():
	click.volume_db = 10  # lower volume slightly
	click.play()
	get_tree().change_scene_to_file(main_scene_path)

func _on_button_mouse_entered(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1, 1), 0.2)
