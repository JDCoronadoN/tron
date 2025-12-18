extends CanvasLayer

@onready var main_buttons: VBoxContainer = $VBoxContainer
@onready var options: Panel = $OPCIONES
@onready var volume: HSlider = $OPCIONES/HSlider
@onready var control: ScrollContainer = $OPCIONES/CONTROL/ScrollContainer
@onready var Sure: Panel = $Confirmation

func _ready():
	# IMPORTANTE: Esto permite que el menú funcione cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Asegurar que solo el menú principal sea visible al inicio
	main_buttons.visible = true
	options.visible = false
	Sure.visible = false
	volume.visible = false
	control.visible = false
	
	print("⏸️ Menú de pausa cargado correctamente")

func _on_Options_pressed():
	print("options pressed")
	main_buttons.visible = false
	options.visible = true

func _on_back_options_pressed() -> void:
	main_buttons.visible = true
	options.visible = false
	volume.visible = false
	control.visible = false

func _on_title_screen_pressed() -> void:
	Sure.visible = true
	main_buttons.visible = false

func _on_yes_pressed() -> void:
	# IMPORTANTE: Quitar la pausa antes de cambiar de escena
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/menu.tscn")

func _on_no_pressed() -> void:
	Sure.visible = false
	main_buttons.visible = true

# AÑADE ESTA FUNCIÓN PARA EL BOTÓN "CONTINUAR"
func _on_continuar_pressed() -> void:
	print("▶️ Continuar juego - Manteniendo progreso")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free() 

# OPCIÓN PARA VOLVER AL JUEGO CON ESC TAMBIÉN
func _input(event):
	if event.is_action_pressed("ui_text_cancel"):  # Tecla ESC
		_on_continuar_pressed()
