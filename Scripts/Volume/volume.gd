extends TextureButton

func _ready():
	self.pressed.connect(_on_volume_pressed)

func _on_volume_pressed():
	print("Botón Volume presionado")
	
	# Ocultar controles
	var controles = get_node("../CONTROL/ScrollContainer")
	if controles:
		controles.visible = false
	
	# Mostrar barra de volumen
	var volume_bar = get_node("../HSlider")
	if volume_bar:
		volume_bar.visible = true
	
	
	# 1. Sincronizar el slider con el valor global actual
	#    (para que si lo cambiaste en pausa, se muestre bien en el menú principal)
	volume_bar.value = Globalaudio.current_volume_linear
	
	# 2. Conectar la señal 'value_changed' del slider a la función del script global
	volume_bar.value_changed.connect(Globalaudio.set_master_volume)
