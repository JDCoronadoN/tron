extends TextureButton

func _ready():
	self.pressed.connect(_on_boton_opciones_presionado)

func _on_boton_opciones_presionado():
	print("Botón Options presionado en pausa")
	
	# Ocultar solo el VBoxContainer (los botones del menú pausa)
	get_node("..").visible = false
	get_node("../../OPCIONES/HSlider").visible=false
	
	# Mostrar opciones
	get_node("../../OPCIONES").visible = true
