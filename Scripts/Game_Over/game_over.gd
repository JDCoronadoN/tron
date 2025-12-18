extends Control
@onready var Confirmation: Panel=$Confirmation
@onready var Retry: TextureButton=$RETRY
@onready var Title: TextureButton=$TITLESCREEN
@onready var bgmusic: AudioStreamPlayer2D = $bgmusic
@onready var label: Label = $Label


func _ready():
	# IMPORTANTE: Permitir que funcione aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Asegurar visibilidad inicial correcta
	Confirmation.visible = false
	Retry.visible = true
	Title.visible = true
	
	print("💀 Game Over screen loaded")
	bgmusic.play()


func _on_titlescreen_pressed() -> void:
	Confirmation.visible=true
	Retry.visible=false
	Title.visible=false
	label.visible=false


func _on_yes_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/menu.tscn")


func _on_no_pressed() -> void:
	Confirmation.visible=false
	Retry.visible=true
	Title.visible=true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
