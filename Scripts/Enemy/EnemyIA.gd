extends CharacterBody3D

# ==============================================================================
#           CONFIGURACIÓN ENEMIGO (IA Estratégica)
# ==============================================================================
var max_speed: float = 70.0
var min_speed: float = 10.0
var acceleration_time: float = 1.5
var deceleration_time: float = 1.0
var velocidad_actual: float = 0.0
var velocidad_rotacion: float = 5.0
var mostrar_debug: bool = true

# --- Parámetros de Estrategia ---
var hunt_speed: float = 80.0
var attack_speed: float = 50.0
var attack_orbit_distance: float = 20.0
var attack_distance: float = 25.0
var attack_dot_threshold: float = -0.3
var attack_duration: float = 8.0
var attack_cooldown: float = 3.0

# --- [MODIFICADO] Parámetros de IA de Enjambre y Atasco ---
var separation_distance: float = 25.0 # [AUMENTADO] Más espacio personal
var separation_weight: float = 3.5 # [AUMENTADO] Más fuerza de empuje
const STUCK_THRESHOLD: float = 2.0 # Segundos en pánico antes de apagar la estela

# --- [NUEVO] Parámetros de Emboscada ---
var ambush_prediction_time: float = 1.2 # Segundos hacia el futuro que predecirá
var ambush_duration: float = 4.0 # Segundos que durará la emboscada
const AMBUSH_REQUEST_CHANCE: float = 0.005 # Probabilidad por frame de emboscar (baja)

# --- Variables de Estado (IA) ---
var state: String = "HUNT"
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var panic_timer: float = 0.0
var ambush_timer: float = 0.0 # [NUEVO]
var ambush_target_pos: Vector3 # [NUEVO]

var support_orbit_distance: float = 40.0

# --- Referencias ---
var player: CharacterBody3D
var main_game_node: Node3D
var debug_label: Label3D

@onready var evasion_raycasts = $EvasionRaycasts

# ==============================================================================
#           INICIALIZACIÓN
# ==============================================================================

func setup(player_node: CharacterBody3D, game_node: Node3D, base_orbit: float):
	# ... (Sin cambios) ...
	self.player = player_node
	self.main_game_node = game_node
	_setup_raycasts()
	if mostrar_debug:
		_crear_debug_label_enemigo()
	# --- Personalidad Aleatoria ---
	# Asigna la órbita LEJANA (Soporte)
	self.support_orbit_distance = base_orbit 
	# Asigna una órbita CERCANA (Ataque) única
	self.attack_orbit_distance = randf_range(15.0, 25.0) 
	# Asigna velocidad de giro única
	self.velocidad_rotacion = randf_range(4.5, 6.0)
	# Asigna un cooldown de "solicitud" inicial
	self.cooldown_timer = randf_range(1.0, 3.0) 
	
	print(" -> Personalidad de %s: Órbita Ataque: %.1f, Órbita Soporte: %.1f" % [self.name, self.attack_orbit_distance, self.support_orbit_distance])

	await get_tree().physics_frame
	velocidad_actual = min_speed
	state = "HUNT"

# ... (Sin cambios: _setup_raycasts, _crear_debug_label_enemigo) ...
func _setup_raycasts():
	if not is_instance_valid(evasion_raycasts): return
	for raycast_node in evasion_raycasts.get_children():
		if raycast_node is RayCast3D:
			var raycast: RayCast3D = raycast_node
			raycast.collision_mask = 0
			raycast.set_collision_mask_value(1, true)
			raycast.set_collision_mask_value(3, true)
			raycast.enabled = true
			raycast.collide_with_areas = true
			raycast.collide_with_bodies = true
			raycast.clear_exceptions()
			raycast.add_exception(self)
func _crear_debug_label_enemigo():
	debug_label = Label3D.new()
	debug_label.text = self.name
	debug_label.pixel_size = 0.005
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.position.y = 2.0
	debug_label.modulate = Color.WHITE
	debug_label.outline_modulate = Color.BLACK
	debug_label.outline_size = 8
	self.add_child(debug_label)

# ==============================================================================
#           PROCESO PRINCIPAL (IA Autónoma)
# ==============================================================================

func _physics_process(delta):
	if not is_instance_valid(player) or not is_instance_valid(main_game_node):
		# ... (Código de frenado sin cambios) ...
		return

	# 1. Gravedad
	if not self.is_on_floor():
		self.velocity.y += _get_project_gravity().y * delta
	else:
		self.velocity.y = -0.1
	
	# 2. IA de Evasión (Siempre activa)
	var avoidance_result = avoid_obstacles_steering()
	var is_evading = avoidance_result.direction.length_squared() > 0.1
	var avoidance_direction = avoidance_result.direction
	
	# 3. IA Estratégica (Máquina de Estados)
	var desired_direction: Vector3
	var target_speed: float
	var estado_debug: String
	
	var distancia_al_jugador = self.global_position.distance_to(player.global_position)
	
	# --- Actualizar temporizadores ---
	if attack_timer > 0:
		attack_timer -= delta
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if ambush_timer > 0:
		ambush_timer -= delta

	# --- [MODIFICADO] Lógica de Estados (con Emboscada) ---
	match state:
		"HUNT":
			estado_debug = "SOPORTE" # Ahora es un rol de soporte
			# Usa la órbita LEJANA
			desired_direction = orbit_steering(support_orbit_distance) 
			target_speed = hunt_speed

			# [MODIFICADO] Lógica para PEDIR un rol
			if cooldown_timer <= 0:
				cooldown_timer = attack_cooldown # Reinicia el timer de petición
				
				# ¿Puedo ATACAR?
				if distancia_al_jugador < attack_distance:
					# Pregunta al Director si el puesto de "Atacante" está libre
					if main_game_node.request_attack_role(self):
						_change_state("ATTACK")
				
				# ¿Puedo EMBOSCAR?
				elif player.velocity.length() > (hunt_speed * 0.5) and randf() < AMBUSH_REQUEST_CHANCE:
					# Pregunta al Director si el puesto de "Emboscador" está libre
					if main_game_node.request_ambush_role(self):
						_change_state("AMBUSH")

		"ATTACK":
			estado_debug = "ATACANDO"
			# Usa la órbita CERCANA
			desired_direction = orbit_steering(attack_orbit_distance) 
			target_speed = attack_speed

			if attack_timer < 1.0: # Estrategia Anti-Cierre
				desired_direction = self.global_transform.basis.x.normalized()
				estado_debug = "ABRIENDO CIRCULO"
			
			if attack_timer <= 0: # Volver a Soporte
				_change_state("HUNT")
		
		"AMBUSH":
			estado_debug = "¡EMBOSCADA!"
			target_speed = hunt_speed * 1.2 # ¡Ir más rápido!
			desired_direction = (ambush_target_pos - self.global_position).normalized()
			
			if ambush_timer <= 0 or self.global_position.distance_to(ambush_target_pos) < 10.0:
				print("🎯 ENEMIGO: ", self.name, " ¡Emboscada completada!")
				_change_state("HUNT")


	# 4. Lógica de Separación (Espacio Personal)
	var separation_vector = _separation_steering()
	desired_direction = (desired_direction + separation_vector * separation_weight).normalized()


	# 5. Manejo de Evasión Diferencial (IA Defensiva + Detector de Atasco)
	var is_panicking = false
	if is_evading:
		desired_direction = avoidance_direction
		
		if is_instance_valid(player) and avoidance_result.owner == player.name:
			target_speed = max_speed 
			estado_debug = "EVADIENDO (Jugador)"
			panic_timer = 0.0
		else:
			target_speed = min_speed
			estado_debug = "EVADIENDO (Enemigo)"
			is_panicking = true
			panic_timer += delta
			
			if panic_timer > STUCK_THRESHOLD:
				print("🚫 ENEMIGO: ", self.name, " ¡ATASCADO! Apagando estela para escapar.")
				_toggle_lightwall_if_on(false) # Apagar estela
				panic_timer = 0.0
	else:
		panic_timer = 0.0


	# 6. Aceleración / Deceleración Progresiva
	# ... (Sin cambios) ...
	if target_speed > velocidad_actual:
		var acceleration_amount = (hunt_speed / acceleration_time) * delta
		velocidad_actual = move_toward(velocidad_actual, target_speed, acceleration_amount)
	elif is_panicking:
		var panic_brake_rate = (attack_speed / (PI * 0.5)) * delta
		velocidad_actual = move_toward(velocidad_actual, target_speed, panic_brake_rate)
	else:
		var deceleration_amount = (hunt_speed / deceleration_time) * delta
		velocidad_actual = move_toward(velocidad_actual, target_speed, deceleration_amount)

	# 7. Rotación
	_rotar_hacia_direccion_enemigo(desired_direction, delta)

	# 8. Aplicar Velocidad
	var forward_velocity = self.global_transform.basis.z * velocidad_actual
	self.velocity.x = forward_velocity.x
	self.velocity.z = forward_velocity.z
	
	# 9. Moverse
	self.move_and_slide()
	
	# 10. Actualizar Debug
	var color = Color.GREEN
	if state == "ATTACK": color = Color.YELLOW
	if state == "AMBUSH": color = Color.PURPLE # [NUEVO]
	if is_evading:
		if estado_debug == "EVADIENDO (Enemigo)":
			color = Color.RED
		else:
			color = Color.MAGENTA
	if estado_debug == "ABRIENDO CIRCULO": color = Color.CYAN
	if panic_timer > 0.1:
		color = Color.ORANGE
	_actualizar_debug_enemigo(estado_debug, color)


# ==============================================================================
#           [NUEVO] MANEJADOR DE ESTADOS
# ==============================================================================

# Una función central para cambiar de estado limpiamente
func _change_state(new_state: String):
	if new_state == state:
		return # Ya estamos en este estado

	print("IA: ", self.name, " cambiando de ", state, " -> ", new_state)
	
	# --- Lógica de SALIDA del estado antiguo ---
	if state == "ATTACK" or state == "AMBUSH":
		_toggle_lightwall_if_on(false) # Apagar estela al salir de estados ofensivos
		if is_instance_valid(main_game_node):
			main_game_node.release_role(self)

	# --- Lógica de ENTRADA al nuevo estado ---
	state = new_state
	
	match state:
		"HUNT":
			cooldown_timer = attack_cooldown # Iniciar enfriamiento para la PRÓXIMA petición
		
		"ATTACK":
			attack_timer = attack_duration
			_toggle_lightwall_if_on(true)
		
		"AMBUSH":
			ambush_target_pos = player.global_position + (player.velocity * ambush_prediction_time)
			ambush_timer = ambush_duration
			_toggle_lightwall_if_on(true)


# Función auxiliar para no llamar a toggle_lightwall innecesariamente
func _toggle_lightwall_if_on(turn_on: bool):
	if not is_instance_valid(main_game_node): return
	
	var lightwall_state = main_game_node.lightwall_states.get(self)
	if not lightwall_state: return

	if turn_on and not lightwall_state.enabled:
		main_game_node.toggle_lightwall(self) # Encenderla
	elif not turn_on and lightwall_state.enabled:
		main_game_node.toggle_lightwall(self) # Apagarla


# ==============================================================================
#           FUNCIONES DE IA
# ==============================================================================

func _separation_steering() -> Vector3:
	# ... (Sin cambios) ...
	var push_vector = Vector3.ZERO
	var neighbors = get_tree().get_nodes_in_group("Enemies") 
	var neighbor_count = 0
	for neighbor in neighbors:
		if neighbor == self:
			continue
		var pos_self = self.global_position * Vector3(1, 0, 1)
		var pos_neighbor = neighbor.global_position * Vector3(1, 0, 1)
		var dist = pos_self.distance_to(pos_neighbor)
		if dist < separation_distance:
			var away_vec = pos_self - pos_neighbor
			if dist > 0.01:
				push_vector += away_vec.normalized() / dist 
			neighbor_count += 1
	if neighbor_count > 0:
		push_vector = (push_vector / neighbor_count).normalized()
	return push_vector


func orbit_steering(distance:float) -> Vector3:
	# ... (Sin cambios) ...
	if not is_instance_valid(player): return Vector3.ZERO
	var to_player_xz = (player.global_position - self.global_position) * Vector3(1, 0, 1)
	var orbit_direction_xz = to_player_xz.cross(Vector3.UP).normalized()
	# Usa la distancia pasada como parámetro
	var target_orbit_point = player.global_position + orbit_direction_xz * distance
	var direction_to_target = (target_orbit_point - self.global_position) * Vector3(1, 0, 1)
	return direction_to_target.normalized()


func avoid_obstacles_steering() -> Dictionary:
	# ... (Sin cambios) ...
	var current_velocity_xz = self.velocity * Vector3(1, 0, 1)
	if current_velocity_xz.length() > 0.1:
		evasion_raycasts.global_rotation.y = atan2(current_velocity_xz.x, current_velocity_xz.z)
	for raycast_node in evasion_raycasts.get_children():
		if raycast_node is RayCast3D:
			var raycast: RayCast3D = raycast_node
			var ray_length = (velocidad_actual * 0.4) + 30.0
			raycast.target_position = Vector3(0, -ray_length,0)
			raycast.force_raycast_update()
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				if not collider:
					continue
				var owner_name = "Unknown"
				var node_to_check: Node = collider
				while node_to_check and node_to_check != get_tree().root:
					if node_to_check.has_meta("owner_name"):
						owner_name = node_to_check.get_meta("owner_name")
						break
					node_to_check = node_to_check.get_parent()
				if owner_name == "Unknown":
					if collider.get_parent() and collider.get_parent().has_meta("owner_name"):
						owner_name = collider.get_parent().get_meta("owner_name")
				var normal = raycast.get_collision_normal()
				var avoidance_vector = normal * Vector3(1, 0, 1)
				return {"direction": avoidance_vector.normalized(), "owner": owner_name}
	return {"direction": Vector3.ZERO, "owner": ""}


func _rotar_hacia_direccion_enemigo(direction: Vector3, delta: float):
	# ... (Sin cambios) ...
	if direction.length_squared() < 0.01: return
	var target_rotation = atan2(direction.x, direction.z)
	var current_rotation = self.rotation.y
	var rotation_diff = target_rotation - current_rotation
	while rotation_diff > PI: rotation_diff -= TAU
	while rotation_diff < -PI: rotation_diff += TAU
	var rotation_step = sign(rotation_diff) * min(abs(rotation_diff), velocidad_rotacion * delta)
	self.rotation.y += rotation_step

func _actualizar_debug_enemigo(estado: String, color: Color):
	# ... (Sin cambios) ...
	if not debug_label or not is_instance_valid(player): return
	var distancia = self.global_position.distance_to(player.global_position)
	var porcentaje_vel = (velocidad_actual / hunt_speed) * 100.0
	debug_label.text = "%s\nDist: %.1fm\nVel: %.0f%%\nSpeed: %.1f" % [
		estado, distancia, porcentaje_vel, velocidad_actual
	]
	debug_label.modulate = color

func _get_project_gravity() -> Vector3:
	# ... (Sin cambios) ...
	return ProjectSettings.get_setting("physics/3d/default_gravity_vector") * ProjectSettings.get_setting("physics/3d/default_gravity")
