extends TextureButton

@onready var main_menu = get_node("..")  # MAIN MENU
@onready var opciones_panel = get_node("/root/Menu/OPCIONES")

func _ready():
	self.pressed.connect(_on_boton_opciones_presionado)

func _on_boton_opciones_presionado():
	print("Botón Options presionado")
	main_menu.visible = false
	opciones_panel.visible = true
