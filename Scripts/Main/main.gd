extends Node3D

# ==============================================================================
#           CONFIGURACIÓN GLOBAL
# ==============================================================================
var velocidad: float = 15.0
var velocidad_rotacion: float = 2.0
var tiempo_vel: float = 1.0
var velocidad_maxima: float = 75.0
var velocidad_actual: float = 0.0
var decremento_velocidad: float
var sensibilidad_camara: float = 0.005
var distancia_camara: float = 5.0
var altura_camara: float = 2.0
var angulo_camara: Vector2 = Vector2.ZERO
@onready var ui: CanvasLayer = $UI
@onready var sfx_lightcyclesound: AudioStreamPlayer3D = $CharacterBody3D/sfx_lightcyclesound
@onready var sfx_engine: AudioStreamPlayer3D = $CharacterBody3D/sfx_engine
@onready var bgmusic: AudioStreamPlayer = $bgmusic
@onready var crowdsfx: AudioStreamPlayer = $crowdsfx
@onready var computerannouncersfx: AudioStreamPlayer = $computerannouncersfx

# [MODIFICADO] El nodo de sonido ahora debe ser hijo directo de este Node3D
@onready var sfx_enemydeath: AudioStreamPlayer3D = $sfx_enemydeath

# ==============================================================================
#           [ELIMINADO] CONFIGURACIÓN ENEMIGO
# ==============================================================================
# ... Toda la configuración de la IA se movió a EnemyAI.gd ...

# ==============================================================================
#           CONFIGURACIÓN LIGHTWALL
# ==============================================================================
var lightwall_states: Dictionary = {}
var custom_material_player: StandardMaterial3D
var custom_material_enemy: StandardMaterial3D
var mono_spawn_delay: float = 0.01

# ===== REFERENCIAS =====
@onready var personaje: CharacterBody3D = $CharacterBody3D
@onready var camara: Camera3D = $Camera3D
# [ELIMINADO] @onready var enemy: CharacterBody3D = $Enemy
@onready var fade_courtain: ColorRect=$FadeCourtain
# [ELIMINADO] @onready var evasion_raycasts= $Enemy/EvasionRaycasts
# [ELIMINADO] var enemy_debug_label: Label3D
@onready var label_velocidad: Label=$UI/MarginContainer/VBoxContainer/label_velocidad
@onready var label_tiempo: Label=$UI/MarginContainer/VBoxContainer/label_tiempo
@onready var label_logro: Label=$UI/MarginContainer/VBoxContainer/label_logro
@onready var timer_supervivencia: Timer=$Timer_Supervivencia

# ==============================================================================
#           [NUEVO] CONFIGURACIÓN DIRECTOR DE IA
# ==============================================================================
# Estas variables gestionan los "tickets" de ataque para la manada
var atacante_actual: CharacterBody3D = null
var emboscador_actual: CharacterBody3D = null

# Parámetros para los enemigos en modo "Soporte" (orbitando lejos)
var support_orbit_distance_base: float = 40.0
var support_orbit_distance_variance: float = 10.0

var segundos_supervivencia: int=0
var logros_desbloqueados: Dictionary={}
var tiempo_sin_girar_acumulado: float=0.0

# ==============================================================================
#           INICIALIZACIÓN Y PAUSA
# ==============================================================================
func _ready():
    randomize()
    computerannouncersfx.play()
    bgmusic.play()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print("🎮 CONTROLADOR MOTOCICLETA INICIADO")
    configurar_camara_tercera_persona()
    _inicializar_material_lightwall()
    _inicializar_entidades()
    if label_tiempo:
        label_tiempo.text="00:00"
    if label_velocidad:
        label_velocidad.text="0 KM/H"
    if label_logro:
        label_logro.visible=false
    if timer_supervivencia:
        timer_supervivencia.timeout.connect(_on_timer_supervivencia_timeout)
        timer_supervivencia.start()
    if fade_courtain:
        fade_courtain.visible = true
        fade_courtain.color.a = 1.0
        var tween = create_tween()
        tween.tween_property(fade_courtain, "color:a", 0.0, 1.5)
        tween.tween_callback(func(): fade_courtain.visible = false )
    $bgmusic.play_random_track()
        
func _inicializar_material_lightwall():
    custom_material_player = StandardMaterial3D.new()
    custom_material_player.albedo_color = Color(0, 0.8, 1.0)
    custom_material_player.emission_enabled = true
    custom_material_player.emission = Color(0, 0.4, 0.8)
    custom_material_player.emission_energy = 5.0
    custom_material_enemy = StandardMaterial3D.new()
    custom_material_enemy.albedo_color = Color(1.0, 0.1, 0.0)
    custom_material_enemy.emission_enabled = true
    custom_material_enemy.emission = Color(1.0, 0.0, 0.0)
    custom_material_enemy.emission_energy = 8.0

# En Node3D.gd

# [MODIFICADO] Esta es la función que debes actualizar
func _inicializar_entidades():
    # Configurar al jugador
    _setup_lightwall_state(personaje)
    
    # [AÑADIDO] Bucle para configurar a todos los enemigos
    var enemies = get_tree().get_nodes_in_group("Enemies") # Asegúrate que el nombre del grupo sea "Enemies"
    print("DIRECTOR: Encontrados ", enemies.size(), " enemigos para la manada.")
    
    for current_enemy in enemies:
        if current_enemy is CharacterBody3D:
            _setup_lightwall_state(current_enemy)
            
            if current_enemy.has_method("setup"):
                # Asigna una distancia de soporte única a cada enemigo
                var support_dist = support_orbit_distance_base + randf_range(-support_orbit_distance_variance, support_orbit_distance_variance)
                
                # --- ¡AQUÍ ESTÁ LA LLAMADA CORRECTA CON 3 ARGUMENTOS! ---
                current_enemy.setup(personaje, self, support_dist) 
                
                print("DIRECTOR: Enemigo ", current_enemy.name, " inicializado (Soporte a %.1fm)" % support_dist)
            else:
                print("❌ ERROR: Enemigo ", current_enemy.name, " no tiene script EnemyAI.gd con funcion setup()")


func toggle_pausa():
    # ... (Sin cambios) ...
    if get_tree().paused:
        get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        print("▶ JUEGO REANUDADO")
    else:
        get_tree().paused = true
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        print("⏸ JUEGO EN PAUSA - Cambiando a escena de menú...")
        await get_tree().create_timer(0.1).timeout
        cambiar_a_menu_pausa()
func cambiar_a_menu_pausa():
    # ... (Sin cambios) ...
    var escena_pausa = load("res://Menus/pause.tscn")
    if escena_pausa:
        var instancia_pausa = escena_pausa.instantiate()
        get_tree().current_scene.add_child(instancia_pausa)
        print("🔄 Menú de pausa cargado como overlay")
    else:
        print("❌ No se encontró la escena de pausa")
        get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ==============================================================================
#           PROCESO PRINCIPAL
# ==============================================================================
func _physics_process(delta):
    # Procesar jugador
    if personaje and camara:
        procesar_movimiento_jugador(delta)
        actualizar_camara()
        _procesar_lightwall(personaje)
        personaje.move_and_slide()
        if label_velocidad:
            var velocidad_kmh = velocidad_actual * 3.6
            label_velocidad.text= "%d KM/H" % int(velocidad_kmh)
            
    # [MODIFICADO] Procesar lightwall de todos los enemigos
    # La IA y move_and_slide ahora se manejan en EnemyAI.gd
    for current_enemy in get_tree().get_nodes_in_group("Enemies"):
        if is_instance_valid(current_enemy):
            _procesar_lightwall(current_enemy)
            # [ELIMINADO] procesar_movimiento_enemigo(delta)
            # [ELIMINADO] enemy.move_and_slide()


func _input(event):
    # ... (Sin cambios) ...
    if Input.is_key_pressed(KEY_C):
        angulo_camara = Vector2.ZERO
        return
    if Input.is_action_just_pressed("ui_text_cancel"):
        toggle_pausa()
        return
    if not personaje or get_tree().paused:
        return
    if event is InputEventMouseMotion:
        angulo_camara.x -= event.relative.x * sensibilidad_camara
        angulo_camara.y -= event.relative.y * sensibilidad_camara
        angulo_camara.y = clamp(angulo_camara.y, -0.8, 0.8)
    if Input.is_action_just_pressed("ui_text_tab"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            toggle_lightwall(personaje)

# ==============================================================================
#           SISTEMA LIGHTWALL
# ==============================================================================

func _configurar_lightwall_enemigo():
    # [MODIFICADO] Itera y enciende la estela de TODOS los enemigos
    for current_enemy in get_tree().get_nodes_in_group("Enemies"):
        var state = lightwall_states.get(current_enemy)
        if not state:
            print("No encontrado estado para ", current_enemy.name)
            continue
        state.width = 0.1
        call_deferred("toggle_lightwall", current_enemy)


# [MODIFICADO] Ahora usa grupos para determinar el target_tag
func _setup_lightwall_state(entity: CharacterBody3D):
    # Si la entidad está en el grupo "enemies", su objetivo es "player"
    # Si no (es el jugador), su objetivo es "enemy"
    var entity_target_tag = "player" if entity.is_in_group("Enemies") else "enemy"
    
    lightwall_states[entity] = {
        "enabled": false,
        "spawn_time": 0.0,
        "current_trail": null,
        "trails_array": [],
        "vertices_array": PackedVector3Array(),
        "triangles_array": PackedInt32Array(),
        "first_time": true,
        "is_even": false,
        "x": 0,
        "width": 0.3,
        "collision_boxes": [],
        "target_tag": entity_target_tag, # Asignación dinámica
        "segment_count": 0
    }

func _procesar_lightwall(entity: CharacterBody3D):
    # ... (Sin cambios) ...
    var state = lightwall_states.get(entity)
    if not state or not state.enabled:
        return
    if Time.get_ticks_msec() / 1000.0 > state.spawn_time:
        state.spawn_time = Time.get_ticks_msec() / 1000.0 + mono_spawn_delay
        mono_line(entity, state)

func toggle_lightwall(entity: CharacterBody3D):
    # ... (Sin cambios) ...
    var state = lightwall_states.get(entity)
    if not state:
        print("❌ Error: Estado de Lightwall no encontrado para la entidad.")
        return
    state.enabled = !state.enabled
    if state.enabled:
        start_new_trail(entity, state)
        print("🎨 INICIANDO NUEVO TRAIL de estela para: ", entity.name)
    else:
        if state.current_trail:
            finalize_trail_collision(state)
            var trail_to_remove = state.current_trail
            var timer = get_tree().create_timer(30.0)
            timer.timeout.connect(remove_trail.bind(state, trail_to_remove))
        if entity==personaje:
            if state.segment_count>200:
                _desbloquear_logro("Arquitecto")
        print("⏸ DETENIENDO CREACIÓN - Colisión finalizada para: ", entity.name)

func start_new_trail(entity: CharacterBody3D, state: Dictionary):
    # ... (Sin cambios) ...
    state.first_time = true
    state.vertices_array = PackedVector3Array()
    state.triangles_array = PackedInt32Array()
    state.x = 0
    state.spawn_time = Time.get_ticks_msec() / 1000.0
    state.segment_count = 0
    
    # [MODIFICADO] Pasa el target_tag correcto
    state.current_trail = create_trail_object(entity.name, state.target_tag)
    add_child(state.current_trail)
    state.trails_array.append(state.current_trail)

func remove_trail(state: Dictionary, trail_to_remove: Node3D):
    # ... (Sin cambios) ...
    if trail_to_remove and trail_to_remove in state.trails_array:
        trail_to_remove.queue_free()
        state.trails_array.erase(trail_to_remove)
        print("🧹 Trail de ", trail_to_remove.name, " eliminado después de 30 segundos")

func finalize_trail_collision(state: Dictionary):
    # ... (Sin cambios) ...
    if state.current_trail and state.vertices_array.size() > 0:
        var mesh_collider = state.current_trail.get_meta("mesh_collider")
        update_trail_collision(mesh_collider, state.vertices_array)
        print("🛡 Colisión finalizada para trail desactivado: ", state.current_trail.name)
        print("🛡 Colisión finalizada con ", state.collision_boxes.size(), " segmentos")
        state.collision_boxes.clear()

func mono_line(entity: CharacterBody3D, state: Dictionary):
    # ... (Sin cambios) ...
    state.segment_count += 1
    var backward_visual = entity.global_position - (entity.global_transform.basis.z * 1.4)
    var backward_collision = entity.global_position - (entity.global_transform.basis.z * 3.0)
    var current_width = state.width
    if not is_instance_valid(state.current_trail):
        print("⚠ Error: Trail actual no válido. Deteniendo la generación de segmentos.")
        state.enabled = false
        return
    create_collision_segment(state.current_trail, backward_collision, entity.global_rotation, state)
    if state.first_time:
        state.vertices_array = PackedVector3Array([
            backward_visual,
            backward_visual - (entity.global_transform.basis.x * -current_width * 0.1),
            backward_visual - (entity.global_transform.basis.x * -current_width * 0.1) + Vector3.UP,
            backward_visual + Vector3.UP
        ])
        state.triangles_array = PackedInt32Array([ 0, 2, 1, 0, 3, 2 ])
        state.first_time = false
        state.is_even = false
        state.x = 4
        return
    if state.is_even:
        state.vertices_array.append_array([
            backward_visual,
            backward_visual - (entity.global_transform.basis.x * -current_width * 0.1),
            backward_visual - (entity.global_transform.basis.x * -current_width * 0.1) + Vector3.UP,
            backward_visual + Vector3.UP
        ])
        state.triangles_array.append_array(PackedInt32Array([
            state.x - 4, state.x - 1, state.x, state.x - 4, state.x, state.x + 3, state.x - 4, state.x + 3, state.x + 2,
            state.x - 4, state.x + 2, state.x - 3, state.x - 3, state.x + 2, state.x + 1, state.x - 3, state.x + 1, state.x - 2
        ]))
        state.is_even = false
    else:
        state.vertices_array.append_array([
            backward_visual + Vector3.UP,
            backward_visual - (entity.global_transform.basis.x * -current_width * 0.1) + Vector3.UP,
            backward_visual - (entity.global_transform.basis.x * -current_width * 0.1),
            backward_visual
        ])
        state.triangles_array.append_array(PackedInt32Array([
            state.x - 4, state.x + 3, state.x, state.x - 4, state.x, state.x - 1, state.x - 2, state.x - 1, state.x,
            state.x - 2, state.x, state.x + 1, state.x - 3, state.x - 2, state.x + 1, state.x - 3, state.x + 1, state.x + 2
        ]))
        state.is_even = true
    state.x += 4
    update_trail_mesh(state)

# [MODIFICADO] Asigna material basado en target_tag, no en nombre
func create_trail_object(owner_name: String, target_tag: String) -> Node3D:
    var trail_container = Node3D.new()
    trail_container.name = "LightWallTrail_%s_%s" % [owner_name, Time.get_ticks_msec()]
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.name = "TrailMesh"
    trail_container.add_child(mesh_instance)
    var line_mesh = ArrayMesh.new()
    mesh_instance.mesh = line_mesh
    
    # [MODIFICADO] Lógica de material robusta
    if target_tag == "player": # Es un trail de enemigo
        mesh_instance.material_override = custom_material_enemy
    elif target_tag == "enemy": # Es un trail de jugador
        mesh_instance.material_override = custom_material_player
        
    var area = Area3D.new()
    area.name = "LightWallArea"
    trail_container.add_child(area)
    var mesh_collider = CollisionShape3D.new()
    area.add_child(mesh_collider)
    area.body_entered.connect(_on_lightwall_body_entered.bind(area))
    area.collision_layer = 1
    area.collision_mask = 2
    trail_container.set_meta("mesh_instance", mesh_instance)
    trail_container.set_meta("line_mesh", line_mesh)
    trail_container.set_meta("mesh_collider", mesh_collider)
    trail_container.set_meta("area", area)
    trail_container.set_meta("owner_name", owner_name)
    return trail_container

func update_trail_mesh(state: Dictionary):
    # ... (Sin cambios) ...
    if not state.current_trail: return
    var mesh_instance = state.current_trail.get_meta("mesh_instance")
    var line_mesh = state.current_trail.get_meta("line_mesh")
    if not mesh_instance or not line_mesh: return
    line_mesh.clear_surfaces()
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = state.vertices_array
    arrays[Mesh.ARRAY_INDEX] = state.triangles_array
    line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func update_trail_collision(mesh_collider: CollisionShape3D, vertices: PackedVector3Array):
    # ... (Sin cambios) ...
    if mesh_collider and vertices.size() > 0:
        var shape = ConcavePolygonShape3D.new()
        shape.set_faces(vertices)
        mesh_collider.shape = shape

func create_collision_segment(current_trail: Node3D, position: Vector3, rotation: Vector3, state: Dictionary):
    # ... (Sin cambios) ...
    var collision_node = Area3D.new()
    collision_node.name = "CollisionBox_%s" % Time.get_ticks_msec()
    current_trail.add_child(collision_node)
    collision_node.global_position = position
    var collision_shape = CollisionShape3D.new()
    collision_node.add_child(collision_shape)
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(0.05, 2.0, 0.8)
    collision_shape.shape = box_shape
    collision_node.rotation = rotation
    var trail_area = current_trail.get_meta("area")
    collision_node.collision_layer = trail_area.collision_layer
    collision_node.collision_mask = trail_area.collision_mask
    collision_node.body_entered.connect(_on_lightwall_body_entered.bind(collision_node))
    state.collision_boxes.append(collision_node)

# ==============================================================================
#           [MODIFICADO] LÓGICA DE COLISIÓN
# ==============================================================================
func _on_lightwall_body_entered(body: Node3D, lightwall_area: Area3D):
    sfx_lightcyclesound.play()
    # 1. Identificar dueño (sin cambios)
    var lightwall_root: Node3D = null
    var node_to_check: Node = lightwall_area
    while node_to_check and node_to_check != self:
        if node_to_check.has_meta("owner_name"):
            lightwall_root = node_to_check
            break
        node_to_check = node_to_check.get_parent()
    if not lightwall_root:
        print("⚠ Colisión de estela fallida: No se pudo identificar el trail root.")
        return
    var owner_name = lightwall_root.get_meta("owner_name")
    
    # 2. Filtrar colisiones no deseadas (sin cambios)
    if body is StaticBody3D or body is Area3D:
        return

    print("💥 COLISIÓN DETECTADA con estela de ", owner_name, " contra ", body.name)

    # --- 3. LÓGICA DE MUERTE UNIVERSAL (SIN GRACIA) ---
    
    if body == personaje:
        print("🎮 JUGADOR ELIMINADO por estela de ", owner_name)
        ui.visible = false
        sfx_lightcyclesound.play()
        mostrar_game_over()
        return

    # [MODIFICADO] Comprueba si el cuerpo es CUALQUIER enemigo
    var all_enemies = get_tree().get_nodes_in_group("Enemies")
    if body in all_enemies:
        print("🤖 ENEMIGO ELIMINADO: ", body.name, " (por estela de ", owner_name, ")")
        _desbloquear_logro("Ultimo en pie")
        _desbloquear_logro("The Grid Clear")
        
        # --- Sonido de Muerte (Sin cambios) ---
        if not is_instance_valid(sfx_enemydeath):
             print("❌ ERROR: sfx_enemydeath no es válido.")
        else:
            sfx_enemydeath.global_position = body.global_position
            sfx_enemydeath.play()
            print("✅ Sonido de muerte .play() llamado en: ", sfx_enemydeath.global_position)

        # [NUEVO] ¡El enemigo muerto debe liberar su rol de ataque!
        release_role(body)
        
        # Libera al enemigo
        body.queue_free()

        # Comprobar si era el ÚLTIMO enemigo
        if all_enemies.size() == 1:
            print("🏆 ¡TODOS LOS ENEMIGOS ELIMINADOS! Esperando sonido...")
            if not sfx_enemydeath.finished.is_connected(_on_enemy_death_sound_finished):
                sfx_enemydeath.finished.connect(_on_enemy_death_sound_finished)
        
        return

# ==============================================================================
#           [NUEVA FUNCIÓN] MANEJADOR DE FIN DE SONIDO
# ==============================================================================
# Esta función se ejecutará SÓLO cuando el sfx_enemydeath termine de sonar.
func _on_enemy_death_sound_finished():
    # Desconecta la señal para que no se llame múltiples veces
    sfx_enemydeath.finished.disconnect(_on_enemy_death_sound_finished)
    
    print("✅ Sonido finalizado. Cargando escena de victoria.")
    get_tree().change_scene_to_file("res://Scenes/victory.tscn")
            
func request_attack_role(requester: CharacterBody3D) -> bool:
    # Si el puesto de atacante está vacío, o si el atacante murió y olvidó reportarse
    if atacante_actual == null or not is_instance_valid(atacante_actual):
        atacante_actual = requester
        print("DIRECTOR: Asignando rol de ATAQUE a ", requester.name)
        return true
    
    # El puesto ya está ocupado
    return false

# Esta función es llamada por un enemigo cuando quiere EMBOSCAR
func request_ambush_role(requester: CharacterBody3D) -> bool:
    if emboscador_actual == null or not is_instance_valid(emboscador_actual):
        emboscador_actual = requester
        print("DIRECTOR: Asignando rol de EMBOSCADA a ", requester.name)
        return true
    
    return false

# Esta función es llamada por un enemigo cuando TERMINA su rol
func release_role(reporter: CharacterBody3D):
    if reporter == atacante_actual:
        print("DIRECTOR: ", reporter.name, " ha liberado el rol de ATAQUE.")
        atacante_actual = null
    elif reporter == emboscador_actual:
        print("DIRECTOR: ", reporter.name, " ha liberado el rol de EMBOSCADA.")
        emboscador_actual = null
# ==============================================================================
#           [NUEVO] LÓGICA DE UI Y LOGROS
# ==============================================================================
func _on_timer_supervivencia_timeout():
    # ... (Sin cambios) ...
    segundos_supervivencia += 1
    var minutos = segundos_supervivencia / 60
    var segundos = segundos_supervivencia % 60
    if label_tiempo:
        label_tiempo.text = "%02d:%02d" % [minutos, segundos]
    if segundos_supervivencia >= 120:
        _desbloquear_logro("Maratón")

func _desbloquear_logro(nombre_logro: String):
    # ... (Sin cambios) ...
    if logros_desbloqueados.has(nombre_logro):
        return
    print("🏆 LOGRO DESBLOQUEADO: ", nombre_logro)
    logros_desbloqueados[nombre_logro] = true
    if label_logro:
        label_logro.text = "¡Logro: %s!" % nombre_logro
        label_logro.visible = true
        var timer_logro = get_tree().create_timer(5.0)
        timer_logro.timeout.connect(func(): label_logro.visible = false)

# ==============================================================================
#           LÓGICA DEL JUGADOR
# ==============================================================================
func configurar_camara_tercera_persona():
    # ... (Sin cambios) ...
    var centro = personaje.global_position
    camara.global_position = centro + Vector3(0, altura_camara, distancia_camara)
    camara.look_at(centro, Vector3.UP)
    
func actualizar_camara():
    # ... (Sin cambios) ...
    if not personaje or not camara: return
    var centro = personaje.global_position
    var offset = Vector3(0, altura_camara, -distancia_camara)
    var rotacion_horizontal = clamp(angulo_camara.x, -3, 3)
    offset = offset.rotated(Vector3.UP, rotacion_horizontal)
    offset = offset.rotated(Vector3.UP, personaje.global_rotation.y)
    var pos_camara = centro + offset
    var altura_minima = centro.y + 0.5
    var altura_maxima = centro.y + 4.0
    pos_camara.y = clamp(pos_camara.y, altura_minima, altura_maxima)
    camara.global_position = pos_camara
    camara.look_at(centro, Vector3.UP)
    var rotacion_vertical = clamp(angulo_camara.y, -0.5, 0.5)
    camara.rotate_object_local(Vector3.RIGHT, rotacion_vertical)

func procesar_movimiento_jugador(delta):
    # ... (Sin cambios) ...
    var input_dir = Vector3.ZERO
    var esta_acelerando = false
    if Input.is_key_pressed(KEY_W):
        input_dir += personaje.transform.basis.z
        esta_acelerando = true
    if Input.is_key_pressed(KEY_S):
        esta_acelerando = false
    if esta_acelerando:
        var incremento_velocidad = (velocidad_maxima-velocidad) / tiempo_vel * delta
        velocidad_actual=min(velocidad_actual+incremento_velocidad, velocidad_maxima)
        input_dir = input_dir.normalized()
        personaje.velocity.x = input_dir.x * velocidad_actual
        personaje.velocity.z =input_dir.z * velocidad_actual
    else:
        decremento_velocidad = (velocidad_maxima / PI) * delta
        velocidad_actual = max(velocidad_actual - decremento_velocidad, 0.0)
        personaje.velocity.x = move_toward(personaje.velocity.x, 0, velocidad_actual * delta)
        personaje.velocity.z = move_toward(personaje.velocity.z, 0, velocidad_actual * delta)
    var input_girar = 0.0
    if Input.is_key_pressed(KEY_A): input_girar += 1.0
    if Input.is_key_pressed(KEY_D): input_girar -= 1.0
    if abs(input_girar)>0.01:
        tiempo_sin_girar_acumulado=0.0
    else:
        tiempo_sin_girar_acumulado+=delta
        if tiempo_sin_girar_acumulado >=10.0:
            _desbloquear_logro("Cero Giros")
    if esta_acelerando and abs(input_girar) > 0.1:
        var rotacion = input_girar * velocidad_rotacion * delta
        personaje.rotate_y(rotacion)
    if sfx_engine:
        if velocidad_actual > 0.1 and not sfx_engine.is_playing():
            sfx_engine.play()
        elif velocidad_actual <= 0.1 and sfx_engine.is_playing():
            sfx_engine.stop()

# ==============================================================================
#           [ELIMINADO] LÓGICA DEL ENEMIGO
# ==============================================================================
# ... Todas las funciones (enemy_setup, procesar_movimiento_enemigo, 
#             orbit_steering, avoid_obstacles_steering, etc.) 
#             se movieron a EnemyAI.gd ...
# ==============================================================================

# ==============================================================================
#           FIN DEL JUEGO
# ==============================================================================
func mostrar_game_over():
    # ... (Sin cambios) ...
    print("💀 GAME OVER")
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var escena_game_over = load("res://Scenes/game_over.tscn")
    if escena_game_over:
        var instancia_game_over = escena_game_over.instantiate()
        get_tree().current_scene.add_child(instancia_game_over)
        get_tree().paused = true

func _on_static_body_3d_body_entered(body: Node3D) -> void:
    # ... (Sin cambios) ...
    if body == personaje:
        print("🎮 JUGADOR ELIMINADO por oponente!")
        mostrar_game_over()
    
# ==============================================================================
#           GRAVEDAD (Función auxiliar)
# ==============================================================================
func get_gravity() -> Vector3:
    # ... (Sin cambios) ...
    return ProjectSettings.get_setting("physics/3d/default_gravity_vector") * ProjectSettings.get_setting("physics/3d/default_gravity")
