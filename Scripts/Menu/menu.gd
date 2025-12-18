extends Node2D
@onready var main_buttons: VBoxContainer = $"ColorRect/WALLPAPER/MAIN MENU"
@onready var options: Panel=$OPCIONES
@onready var achievements: Panel=$ACHIEVEMENT
@onready var control: ScrollContainer=$OPCIONES/CONTROL/ScrollContainer
@onready var volume: HSlider=$OPCIONES/HSlider
@onready var Sure: Panel=$Confirmation
@onready var License: Panel=$LICENSE
@onready var Fade: AnimationPlayer=$MenuPlay
@onready var Fondo: TextureRect =$ColorRect/WALLPAPER
@onready var Guide: Node2D=$GUION
@onready var THE_SON_OF_FLYNN = $bgmusic
@onready var clicked_button: AudioStreamPlayer2D = $clickedButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Fondo.visible=true
	Fondo.modulate.a=0.0
	var tween = create_tween()
	tween.tween_property(Fondo, "modulate:a", 1.0, 1.5)  # Se desvanece en 1.5 seg
	THE_SON_OF_FLYNN.play()
	

func _on_Options_pressed():
	print("options pressed")
	main_buttons.visible=false
	options.visible=true
	clicked_button.play()

func _on_back_pressed() -> void:
	main_buttons.visible=true
	options.visible=false
	volume.visible=false
	control.visible=false
	clicked_button.play()


func _on_backachievement_pressed() -> void:
	achievements.visible=false
	main_buttons.visible=true
	clicked_button.play()


func _on_quit_pressed() -> void:
	Sure.visible=true
	main_buttons.visible=false
	clicked_button.play()


func _on_yes_pressed() -> void:
	get_tree().quit()
	clicked_button.play()

func _on_no_pressed() -> void:
	Sure.visible=false
	main_buttons.visible=true
	clicked_button.play()


func _on_play_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(Fondo, "modulate:a", 0.0, 1.5)  # Se desvanece en 1.5 seg
	tween.tween_callback(func():
		Fondo.visible=false
		var new_scene=load("res://Scenes/guion.tscn").instantiate()
		add_child(new_scene)
	)
	clicked_button.play()


func _on_licence_pressed() -> void:
	License.visible=true
	main_buttons.visible=false
	clicked_button.play()


func _on_back_licence_pressed() -> void:
	License.visible=false
	main_buttons.visible=true
	clicked_button.play()
