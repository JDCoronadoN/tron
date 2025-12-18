extends Panel

# ===== CONFIGURACIÓN COMPLETA =====
var config = {
	# TEXTO
	"tamaño_fuente_nombre": 35,
	"tamaño_fuente_desc": 30,
	"color_texto": Color.WHITE,
	
	# ICONO
	"escala_icono": 0.2,
	"tamaño_contenedor_icono": 120,
	
	# ESPACIADO
	"espacio_entre_logros": 50,
	"espacio_icono_texto": 25,
	"margen_interior": 20,
}

func _ready():
	print("🎯 ACHIEVEMENT: Script iniciado")
	visible = false
	generar_logros()

func generar_logros():
	print("🎯 ACHIEVEMENT: Generando logros...")
	
	# DEBUG: Ver estructura completa
	print("=== ESTRUCTURA ACHIEVEMENT ===")
	print_estructura_completa(self, 0)
	
	# Buscar ScrollContainer de diferentes formas
	var scroll_container = find_child("LOGROS", true, false)
	if not scroll_container:
		scroll_container = $LOGROS
	
	print("🎯 ScrollContainer encontrado: ", scroll_container != null)
	
	if scroll_container:
		# Buscar VBoxContainer
		var vbox = scroll_container.find_child("VBoxContainer", true, false)
		print("🎯 VBoxContainer encontrado: ", vbox != null)
		
		if not vbox:
			print("❌ No hay VBoxContainer, creando uno...")
			vbox = VBoxContainer.new()
			vbox.name = "VBoxContainer"
			scroll_container.add_child(vbox)
		
		# AHORA SÍ configurar (vbox ya no es null)
		vbox.add_theme_constant_override("separation", config.margen_interior)
		
		# Limpiar contenido existente
		for child in vbox.get_children():
			child.queue_free()
		
		# Generar logros...
		generar_logros_en_vbox(vbox)
	else:
		print("❌ ERROR: No se encontró ScrollContainer 'LOGROS'")

func print_estructura_completa(nodo: Node, nivel: int):
	var sangria = "  ".repeat(nivel)
	print(sangria + "├─ " + nodo.name + " : " + nodo.get_class())
	
	for hijo in nodo.get_children():
		print_estructura_completa(hijo, nivel + 1)

func generar_logros_en_vbox(vbox: VBoxContainer):
	print("🎯 Generando 6 logros en VBoxContainer...")
	
	# Configuraciones de fuente
	var font_nombre = LabelSettings.new()
	font_nombre.font_size = config.tamaño_fuente_nombre
	font_nombre.font_color = config.color_texto
	
	var font_desc = LabelSettings.new()
	font_desc.font_size = config.tamaño_fuente_desc
	font_desc.font_color = config.color_texto
	
	var logros = [
		{"nombre": "Último en pie", "descripcion": "Gana 1ª ronda"},
		{"nombre": "Cero giros", "descripcion": "Sobrevive X sg sin girar"},
		{"nombre": "Encierro perfecto", "descripcion": "Eliminas 2 en 3 sg"},
		{"nombre": "Maratón", "descripcion": "Sobrevive >2 min"},
		{"nombre": "Arquitecto", "descripcion": "Encierro de área grande"},
		{"nombre": "The Grid Clear", "descripcion": "Ganar por primera vez"}
	]
	
	for i in range(logros.size()):
		var logro = logros[i]
		print("🎯 Creando logro ", i + 1, ": ", logro["nombre"])
		
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Icono
		var icono_container = Control.new()
		icono_container.custom_minimum_size.x = config.tamaño_contenedor_icono
		
		var icono = Sprite2D.new()
		var texture = load("res://Images/Icons/ACHIEVEMENT.png")
		if texture:
			icono.texture = texture
			icono.scale = Vector2(config.escala_icono, config.escala_icono)
			icono.position = Vector2(config.tamaño_contenedor_icono/2, config.tamaño_contenedor_icono/2)
		else:
			print("❌ No se pudo cargar el icono")
		
		icono_container.add_child(icono)
		hbox.add_child(icono_container)
		
		# Espaciador
		var espaciador = Control.new()
		espaciador.custom_minimum_size.x = config.espacio_icono_texto
		hbox.add_child(espaciador)
		
		# Texto
		var text_container = VBoxContainer.new()
		text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var nombre_label = Label.new()
		nombre_label.text = logro["nombre"]
		nombre_label.label_settings = font_nombre
		
		var desc_label = Label.new()
		desc_label.text = logro["descripcion"]
		desc_label.label_settings = font_desc
		
		text_container.add_child(nombre_label)
		text_container.add_child(desc_label)
		hbox.add_child(text_container)
		
		vbox.add_child(hbox)
		
		# Espaciador vertical
		var espaciador_vertical = Control.new()
		espaciador_vertical.custom_minimum_size.y = config.espacio_entre_logros
		vbox.add_child(espaciador_vertical)
	
	print("✅ 6 logros generados correctamente")
