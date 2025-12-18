extends CanvasLayer

@onready var transition_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _ready():
	transition_rect.visible = false

# TRANSICIÓN SAO EPICA - Intro → Menú
func sao_intro_to_menu():
	transition_rect.visible = true
	transition_rect.color = Color.BLACK
	transition_rect.color.a = 1.0
	transition_rect.scale = Vector2(1, 1)
	
	# Efecto de "escaneo" SAO - líneas verdes
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 1. Líneas de escaneo verde (efecto SAO)
	var scan_color = Color(0, 1, 0, 0.3)  # Verde SAO
	tween.tween_property(transition_rect, "color", scan_color, 1.0)
	
	# 2. Efecto de expansión desde el centro
	transition_rect.scale = Vector2(0.1, 0.1)
	tween.tween_property(transition_rect, "scale", Vector2(1.5, 1.5), 2.0).set_trans(Tween.TRANS_EXPO)
	
	# 3. Sonido mental (simulado con texto)
	print("🔊 SOUND: BEEP BEEP... LINK START!")
	
	# 4. Transición final al menú
	tween.tween_callback(change_to_menu_after_effect).set_delay(2.5)

func change_to_menu_after_effect():
	get_tree().change_scene_to_file("res://Menus/menu.tscn")

# TRANSICIÓN SAO para menús (más suave) - CORREGIDO
func sao_menu_transition(menu_node: Control, should_show: bool):  # ❌ CAMBIADO "show" por "should_show"
	if should_show:  # ❌ CAMBIADO aquí también
		# Efecto de "materialización" SAO
		menu_node.scale = Vector2(0.1, 0.1)
		menu_node.modulate = Color(0, 1, 0, 0)  # Verde transparente
		menu_node.visible = true
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Expansión desde centro con efecto "holo"
		tween.tween_property(menu_node, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK)
		tween.tween_property(menu_node, "modulate", Color(1, 1, 1, 1.0), 0.6)  # A blanco sólido
		
		# Efecto de brillo verde al aparecer
		var glow_tween = create_tween()
		glow_tween.tween_property(menu_node, "modulate", Color(0.5, 1, 0.5, 1.0), 0.2)
		glow_tween.tween_property(menu_node, "modulate", Color(1, 1, 1, 1.0), 0.3)
		
	else:
		# Efecto de "desmaterialización" SAO
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Contracción al centro
		tween.tween_property(menu_node, "scale", Vector2(0.1, 0.1), 0.6).set_trans(Tween.TRANS_BACK)
		
		# Efecto de desvanecimiento verde
		tween.tween_property(menu_node, "modulate", Color(0, 1, 0, 0.0), 0.6)
		
		# Brill final antes de desaparecer
		var glow_tween = create_tween()
		glow_tween.tween_property(menu_node, "modulate", Color(0.8, 1, 0.8, 0.8), 0.1)
		glow_tween.tween_property(menu_node, "modulate", Color(0, 1, 0, 0.0), 0.3)
		
		tween.tween_callback(menu_node.set.bind("visible", false))
