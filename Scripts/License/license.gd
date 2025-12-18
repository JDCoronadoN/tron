extends Panel

# ===== CONFIGURACIÓN COMPLETA =====
var config = {
	# TEXTO
	"tamaño_fuente_titulo": 35,
	"tamaño_fuente_subtitulo": 30,
	"tamaño_fuente_texto": 25,
	"color_texto": Color.WHITE,
	
	# ICONO
	"escala_icono": 0.2,
	"tamaño_contenedor_icono": 120,
	
	# ESPACIADO
	"espacio_entre_secciones": 40,
	"espacio_icono_texto": 25,
	"margen_interior": 20,
}

func _ready():
	print("📄 LICENSE: Script iniciado")
	visible = false
	generar_info_licencia()

func generar_info_licencia():
	print("📄 LICENSE: Generando información de licencia...")
	
	# DEBUG: Ver estructura completa
	print("=== ESTRUCTURA LICENSE ===")
	print_estructura_completa(self, 0)
	
	# Buscar ScrollContainer de diferentes formas
	var scroll_container = find_child("LOGROS", true, false)
	if not scroll_container:
		scroll_container = $LOGROS
	
	print("📄 ScrollContainer encontrado: ", scroll_container != null)
	
	if scroll_container:
		# Buscar VBoxContainer
		var vbox = scroll_container.find_child("VBoxContainer", true, false)
		print("📄 VBoxContainer encontrado: ", vbox != null)
		
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
		
		# Generar información de licencia...
		generar_licencia_en_vbox(vbox)
	else:
		print("❌ ERROR: No se encontró ScrollContainer 'LOGROS'")

func print_estructura_completa(nodo: Node, nivel: int):
	var sangria = "  ".repeat(nivel)
	print(sangria + "├─ " + nodo.name + " : " + nodo.get_class())
	
	for hijo in nodo.get_children():
		print_estructura_completa(hijo, nivel + 1)

func generar_licencia_en_vbox(vbox: VBoxContainer):
	print("📄 Generando información de licencia en VBoxContainer...")
	
	# Configuraciones de fuente
	var font_titulo = LabelSettings.new()
	font_titulo.font_size = config.tamaño_fuente_titulo
	font_titulo.font_color = config.color_texto
	
	var font_subtitulo = LabelSettings.new()
	font_subtitulo.font_size = config.tamaño_fuente_subtitulo
	font_subtitulo.font_color = config.color_texto
	
	var font_texto = LabelSettings.new()
	font_texto.font_size = config.tamaño_fuente_texto
	font_texto.font_color = config.color_texto
	
	# Información de la licencia
	var secciones_licencia = [
		{
			"titulo": "TRON based on Godot", 
			"subtitulo": "Versión 1.0.0",
			"texto": "Desarrollado por AeroTeam"
		},
		{
			"titulo": "Licencia MIT", 
			"subtitulo": "Copyright (c) 2024 AeroTeam",
			"texto": "Este software se distribuye bajo la licencia MIT. Ver archivo LICENSE para más detalles."
		},
		{
			"titulo": "Descripción", 
			"subtitulo": "Juego snake-like con gráficos 3D",
			"texto": "Juego rápido y sencillo inspirado en TRON con sistema de estelas lightwall."
		},
		{
			"titulo": "Términos de la Licencia MIT", 
			"subtitulo": "Permisos",
			"texto": "• Uso comercial permitido\n• Modificación permitida\n• Distribución permitida\n• Sub-licencia permitida\n• Solo requiere atribución"
		}
	]
	
	for i in range(secciones_licencia.size()):
		var seccion = secciones_licencia[i]
		print("📄 Creando sección ", i + 1, ": ", seccion["titulo"])
		
		# Contenedor principal de la sección
		var seccion_container = VBoxContainer.new()
		seccion_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Título
		var titulo_label = Label.new()
		titulo_label.text = seccion["titulo"]
		titulo_label.label_settings = font_titulo
		seccion_container.add_child(titulo_label)
		
		# Subtítulo
		var subtitulo_label = Label.new()
		subtitulo_label.text = seccion["subtitulo"]
		subtitulo_label.label_settings = font_subtitulo
		seccion_container.add_child(subtitulo_label)
		
		# Texto
		var texto_label = Label.new()
		texto_label.text = seccion["texto"]
		texto_label.label_settings = font_texto
		texto_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		seccion_container.add_child(texto_label)
		
		vbox.add_child(seccion_container)
		
		# Espaciador vertical entre secciones
		if i < secciones_licencia.size() - 1:
			var espaciador_vertical = Control.new()
			espaciador_vertical.custom_minimum_size.y = config.espacio_entre_secciones
			vbox.add_child(espaciador_vertical)
	
	print("✅ Información de licencia generada correctamente")

# Opcional: Función para mostrar/ocultar el panel
func toggle_visibilidad():
	visible = !visible
	if visible:
		print("📄 Panel de licencia mostrado")
	else:
		print("📄 Panel de licencia ocultado")
