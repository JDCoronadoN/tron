extends Node2D
@onready var animation: AnimationPlayer=$Introduction

func _ready():
	# Cargar sistema de transiciones
	animation.play("Intro")
	await animation.animation_finished
	animation.play("Cierre")
	await animation.animation_finished
	get_tree().change_scene_to_file("res://Menus/menu.tscn")
