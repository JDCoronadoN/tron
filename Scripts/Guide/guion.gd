extends Node2D

@onready var texture_rect1 = $Parte1
@onready var texture_rect2 = $Parte2
@onready var texture_rect3 = $Parte3
@onready var continue_button = $Continue
@onready var Courtain = $Courtain
@onready var GameScene: PackedScene=null

var images = []
var current_image_index = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not texture_rect1 or not texture_rect2 or not texture_rect3 or not continue_button:
		print("❌ ERROR: Faltan nodos en la escena")
		return
	images = [texture_rect1, texture_rect2, texture_rect3]
	
	for image in images:
		image.visible = false
		image.modulate.a = 0
	
	continue_button.visible = false
	# Configurar cortina para inicio (fade out)
	Courtain.visible = true
	Courtain.color.a = 1.0  # Empieza completamente opaca
	
	var tween = create_tween()
	tween.tween_property(Courtain, "color:a", 0.0, 3)  # Se desvanece en 3 seg
	tween.tween_callback(func():
		Courtain.visible = false    # 👈 se desactiva al terminar el fade
		show_next_image()           # y recién se muestra la primera imagen
	)

func show_next_image():
	
	var current_image = images[current_image_index]
	current_image.visible = true
	current_image.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(current_image, "modulate:a", 1.0, 1.0)
	tween.tween_callback(show_continue_button)

func show_continue_button():
	continue_button.visible = true

func _on_continue_button_pressed():
	continue_button.visible = false
	
	var current_image = images[current_image_index]
	var tween = create_tween()
	tween.tween_property(current_image, "modulate:a", 0.0, 0.5)
	tween.tween_callback(hide_current_image)

func hide_current_image():
	var current_image = images[current_image_index]
	current_image.visible = false
	
	# Verificar si era la última imagen
	if current_image_index >= images.size() - 1:
		fade_out_to_scene()  # Ir a la siguiente escena
	else:
		current_image_index += 1
		show_next_image()

func fade_out_to_scene():
	# Mostrar la cortina y hacer fade in
	Courtain.visible = true
	Courtain.color.a = 0.0  # Empezar transparente
	
	var tween = create_tween()
	tween.tween_property(Courtain, "color:a", 1.0, 3.0)
	tween.tween_callback(go_to_next_scene)

func go_to_next_scene():
	print("⏳ Cargando y cambiando a escena 3D...")
	
	# PASO CRÍTICO 1: Carga la escena justo antes de cambiar.
	# Usamos 'load()' ya que es una carga final que no queremos mantener precargada.
	var dynamic_scene = load("res://Scenes/main.tscn")
	
	if dynamic_scene:
		# PASO CRÍTICO 2: Activar la lógica del juego global (Si usas el Singleton)
		# Si utilizas el sistema LogicManager (recomendado), actívalo aquí:
		# LogicManager.is_game_active = true 
		
		print("🎉 Última imagen completada - Cambiando de escena")
		
		# Limpiar la referencia (aunque ya es local)
		current_image_index=0 
		
		# Cambiar la escena
		get_tree().change_scene_to_packed(dynamic_scene)
	else:
		print("❌ ERROR: La escena de juego no se pudo cargar.")
