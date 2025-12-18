extends CharacterBody3D

# Parámetros de movimiento
var velocidad: float = 12.0
var tiempo_vel: float = 1.5
var velocidad_maxima: float = 35.0
var velocidad_actual: float = 0.0
var decremento_velocidad: float
var velocidad_rotacion: float = 3.0

# Navegación
@onready var nav_agent = $NavigationAgent3D
@onready var target = $"../CharacterBody3D"

# Distancias
var distancia_llegada: float = 2.0

# Debug visual
var debug_label: Label3D
var mostrar_debug: bool = true

func _ready():
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = distancia_llegada
	
	position.y = max(position.y, 1.0)
	
	# Crear label de debug
	if mostrar_debug:
		_crear_debug_label()
	
	call_deferred("actor_setup")

func _crear_debug_label():
	debug_label = Label3D.new()
	debug_label.text = "Enemy"
	debug_label.pixel_size = 0.005
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.position.y = 2.0
	debug_label.modulate = Color.WHITE
	debug_label.outline_modulate = Color.BLACK
	debug_label.outline_size = 8
	add_child(debug_label)

func actor_setup():
	await get_tree().physics_frame
	
	print("=== ENEMY SETUP ===")
	print("Enemy position: ", global_position)
	print("Target exists: ", target != null)
	
	if target:
		nav_agent.target_position = target.global_position
		print("Target position: ", target.global_position)

func _physics_process(delta):
	# Detectar caída
	if global_position.y < -10:
		print("⚠️ Enemy cayó del mundo")
		global_position = Vector3(0, 2, 0)
		velocity = Vector3.ZERO
		velocidad_actual = 0.0
		return
	
	# Gravedad
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = -0.1
	
	# Sin target válido
	if not target:
		_procesar_desaceleracion(delta)
		_actualizar_debug("SIN TARGET", Color.ORANGE)
		move_and_slide()
		return
	
	# Actualizar target
	nav_agent.target_position = target.global_position
	
	# Calcular distancia
	var distancia_al_jugador = global_position.distance_to(target.global_position)
	
	# Perseguir SIEMPRE sin límite de distancia
	_procesar_persecucion(delta, distancia_al_jugador)
	var estado = "PERSIGUIENDO" if velocidad_actual > 5.0 else "FRENANDO"
	var reachable = nav_agent.is_target_reachable()
	if not reachable:
		estado = "NO ALCANZABLE"
	_actualizar_debug(estado, Color.GREEN if velocidad_actual > 5.0 else Color.YELLOW)
	
	move_and_slide()

func _procesar_persecucion(delta: float, distancia_al_jugador: float):
	if nav_agent.is_navigation_finished():
		_procesar_desaceleracion(delta)
		return
	
	# Verificar si el target es alcanzable
	if nav_agent.is_target_reachable() == false:
		_procesar_desaceleracion(delta)
		return
	
	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position)
	direction.y = 0
	
	if direction.length() < 0.1:
		_procesar_desaceleracion(delta)
		return
	
	direction = direction.normalized()
	
	# Factor de distancia para frenar cerca del jugador
	var factor_distancia = 1.0
	if distancia_al_jugador < distancia_llegada * 3:
		factor_distancia = distancia_al_jugador / (distancia_llegada * 3)
		factor_distancia = clamp(factor_distancia, 0.2, 1.0)
	
	# Aceleración progresiva
	var incremento_velocidad = (velocidad_maxima - velocidad) / tiempo_vel * delta
	var velocidad_objetivo = velocidad_maxima * factor_distancia
	velocidad_actual = min(velocidad_actual + incremento_velocidad, velocidad_objetivo)
	
	# Aplicar velocidad
	var target_velocity = direction * velocidad_actual
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	
	# Rotar hacia dirección
	_rotar_hacia_direccion(direction, delta)

func _procesar_desaceleracion(delta: float):
	decremento_velocidad = (velocidad_maxima / PI) * delta
	velocidad_actual = max(velocidad_actual - decremento_velocidad, 0.0)
	
	velocity.x = move_toward(velocity.x, 0, decremento_velocidad)
	velocity.z = move_toward(velocity.z, 0, decremento_velocidad)

func _rotar_hacia_direccion(direction: Vector3, delta: float):
	var target_rotation = atan2(direction.x, direction.z)
	var current_rotation = rotation.y
	
	var rotation_diff = target_rotation - current_rotation
	
	# Normalizar ángulo
	while rotation_diff > PI:
		rotation_diff -= TAU
	while rotation_diff < -PI:
		rotation_diff += TAU
	
	# Aplicar rotación
	var rotation_step = sign(rotation_diff) * min(abs(rotation_diff), velocidad_rotacion * delta)
	rotation.y += rotation_step

func _actualizar_debug(estado: String, color: Color):
	if not debug_label or not target:
		return
	
	var distancia = global_position.distance_to(target.global_position)
	var porcentaje_vel = (velocidad_actual / velocidad_maxima) * 100.0
	var path_distance = nav_agent.distance_to_target()
	
	debug_label.text = "%s\nDist: %.1fm\nPath: %.1fm\nVel: %.0f%%\nSpeed: %.1f" % [
		estado,
		distancia,
		path_distance,
		porcentaje_vel,
		velocidad_actual
	]
	debug_label.modulate = color

# Función para ajustar dificultad
func ajustar_dificultad(nivel: int):
	match nivel:
		1: # Fácil - Lento y torpe
			velocidad_maxima = 30.0
			tiempo_vel = 2.0
			velocidad_rotacion = 2.5
		2: # Normal - Equilibrado
			velocidad_maxima = 35.0
			tiempo_vel = 1.5
			velocidad_rotacion = 3.0
		3: # Difícil - Rápido
			velocidad_maxima = 42.0
			tiempo_vel = 1.0
			velocidad_rotacion = 3.5
		4: # Experto - Casi iguala al jugador
			velocidad_maxima = 48.0
			tiempo_vel = 0.8
			velocidad_rotacion = 4.0
