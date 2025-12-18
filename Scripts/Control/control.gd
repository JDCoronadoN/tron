extends TextureButton

func _ready():
	self.pressed.connect(_on_control_pressed)
	$ScrollContainer.visible = false
	generar_controles()

func _on_control_pressed():
	print("Botón Control presionado")
	var volume_bar = get_node("../HSlider")
	if volume_bar:
		volume_bar.visible = false
	$ScrollContainer.visible = true

func generar_controles():
	var vbox = $ScrollContainer/VBoxContainer
	
	# Limpiar contenido existente
	for child in vbox.get_children():
		child.queue_free()
	
	# Configuración de fuente para TODOS los labels
	var font_settings = LabelSettings.new()
	font_settings.font_size = 75
	
	# ===== CONTROLES DE TECLADO Y MOUSE =====
	var titulo_teclado = Label.new()
	titulo_teclado.text = "🎮 TECLADO Y MOUSE"
	titulo_teclado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_teclado.label_settings = font_settings
	vbox.add_child(titulo_teclado)
	
	var espaciador_titulo = Control.new()
	espaciador_titulo.custom_minimum_size.y = 40
	vbox.add_child(espaciador_titulo)
	
	# Lista de controles de teclado/mouse
	var controles_teclado = [
		["🖱️ Mouse Click Izquierdo", "Activar/Desactivar Estela de Luz"],
		["🎯 Mover Mouse", "Controlar Cámara"],
		["⬆️ Tecla W", "Acelerar"],
		["⬅️ Tecla A", "Mover Izquierda"],
		["⬇️ Tecla S", "Frenar"],
		["➡️ Tecla D", "Mover Derecha"]
	]
	
	for control in controles_teclado:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Tecla/Control
		var tecla_label = Label.new()
		tecla_label.text = control[0]
		tecla_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tecla_label.label_settings = font_settings
		
		# Descripción
		var desc_label = Label.new()
		desc_label.text = control[1]
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		desc_label.label_settings = font_settings
		
		hbox.add_child(tecla_label)
		hbox.add_child(desc_label)
		vbox.add_child(hbox)
		
		# Espaciador entre items
		var item_espaciador = Control.new()
		item_espaciador.custom_minimum_size.y = 20
		vbox.add_child(item_espaciador)
	
	# ===== SEPARADOR ENTRE SECCIONES =====
	var separador_seccion = HSeparator.new()
	vbox.add_child(separador_seccion)
	
	var espaciador_seccion = Control.new()
	espaciador_seccion.custom_minimum_size.y = 40
	vbox.add_child(espaciador_seccion)
	
