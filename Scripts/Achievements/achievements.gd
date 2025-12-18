extends TextureButton

func _ready():
	self.pressed.connect(_on_achievements_pressed)

func _on_achievements_pressed():
	print("Botón Achievements presionado")
	
	# Ocultar el MAIN MENU
	var main_menu = get_node("..")  # MAIN MENU (abuelo)
	if main_menu:
		main_menu.visible = false
		print("✅ MAIN MENU ocultado")
	
	# Mostrar el panel ACHIEVEMENT
	var achievement_panel = get_node("../../../../ACHIEVEMENT")
	if achievement_panel:
		achievement_panel.visible = true
		print("✅ Panel ACHIEVEMENT mostrado")
	else:
		print("❌ No se encontró el panel ACHIEVEMENT")
