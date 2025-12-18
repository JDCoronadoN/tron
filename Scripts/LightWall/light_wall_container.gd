extends Node3D

# ===== SISTEMA LIGHTWALL PARA ENEMY =====
var weapon_enable: bool = false
var custom_material: StandardMaterial3D
var spawn_time: float = 0.0
var mono_spawn_delay: float = 0.05

# Variables para la malla continua
var current_trail: Node3D = null
var trails_array: Array = []
var vertices_array: PackedVector3Array
var triangles_array: PackedInt32Array
var first_time: bool = true
var is_even: bool = false
var x: int = 0
var width: float = 0.3
var collision_boxes: Array = []

# Referencia al enemigo (padre)
var enemy: CharacterBody3D
@onready var Main: Node3D = $"../.."

# DEBUG
var debug_frame_count: int = 0
var ultimo_mono_line: float = 0.0

func _ready():
	# Obtener referencia al enemigo (nodo padre)
	enemy = get_parent()
	
	print("\n=== 🔴 LIGHTWALL CONTAINER INITIALIZATION ===")
	print("LightWallContainer path: ", get_path())
	print("Parent (Enemy): ", enemy != null)
	
	if enemy:
		print("  - Enemy path: ", enemy.get_path())
		print("  - Enemy class: ", enemy.get_class())
		print("  - Enemy position: ", enemy.global_position)
	else:
		print("  - ❌ NO SE ENCONTRÓ ENEMY PARENT")
	
	print("Main node: ", Main != null)
	if Main:
		print("  - Main path: ", Main.get_path())
	
	# Crear material
	_crear_material()
	
	print("✅ LightWallContainer inicializado correctamente")
	print("   - Material creado: ", custom_material != null)

func _crear_material():
	custom_material = StandardMaterial3D.new()
	custom_material.albedo_color = Color(1.0, 0.2, 0.2)  # Rojo
	custom_material.emission_enabled = true
	custom_material.emission = Color(1.0, 0.0, 0.0)
	custom_material.emission_energy = 3.0
	custom_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	custom_material.albedo_color.a = 0.8
	print("🎨 Material creado: Rojo brillante")

# Función para verificar si el arma está habilitada
func is_weapon_enabled() -> bool:
	return weapon_enable

# Función para activar/desactivar
func toggle_lightwall():
	weapon_enable = !weapon_enable
	
	print("\n=== TOGGLE LIGHTWALL ===")
	print("Estado NUEVO: ", "ACTIVADO" if weapon_enable else "DESACTIVADO")
	
	if weapon_enable:
		start_new_trail()
	else:
		if current_trail:
			finalize_trail_collision()
		print("⏸️ LIGHTWALL DESACTIVADA")

func start_new_trail():
	print("\n🎨 INICIANDO NUEVO TRAIL")
	
	first_time = true
	vertices_array = PackedVector3Array()
	triangles_array = PackedInt32Array()
	x = 0
	spawn_time = Time.get_ticks_msec() / 1000.0
	ultimo_mono_line = 0.0
	
	current_trail = create_trail_object()
	trails_array.append(current_trail)
	
	print("✅ Trail creado:")
	print("   - Trail path: ", current_trail.get_path())
	print("   - Trails totales: ", trails_array.size())
	
	# Timer de eliminación
	var timer = get_tree().create_timer(30.0)
	timer.timeout.connect(remove_trail.bind(current_trail))

func remove_trail(trail_to_remove: Node3D):
	if trail_to_remove and trail_to_remove in trails_array:
		trail_to_remove.queue_free()
		trails_array.erase(trail_to_remove)
		print("🧹 Trail eliminado (30s expirados)")

func finalize_trail_collision():
	if current_trail and vertices_array.size() > 0:
		var mesh_collider = current_trail.get_meta("mesh_collider")
		update_trail_collision(mesh_collider)
		print("🛡️ Colisión finalizada - Segmentos: ", collision_boxes.size())

func mono_line():
	if not enemy:
		print("❌ MONO_LINE: Enemy es null!")
		return
	
	if not current_trail:
		print("❌ MONO_LINE: current_trail es null!")
		return
	
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	ultimo_mono_line = tiempo_actual
	
	# Debug cada 30 frames
	debug_frame_count += 1
	if debug_frame_count % 30 == 0:
		print("🎨 MONO_LINE llamado (frame ", debug_frame_count, ")")
		print("   - Enemy pos: ", enemy.global_position)
		print("   - Vertices: ", vertices_array.size())
		print("   - Triangles: ", triangles_array.size())
	
	var backward_visual = enemy.global_position - (enemy.global_transform.basis.z * 1.4)
	var backward_collision = enemy.global_position - (enemy.global_transform.basis.z * 3.0)
	
	create_collision_segment(backward_collision)
	
	if first_time:
		print("🎨 PRIMER SEGMENTO DEL TRAIL")
		
		vertices_array = PackedVector3Array([
			backward_visual,
			backward_visual - (enemy.global_transform.basis.x * -width * 0.1),
			backward_visual - (enemy.global_transform.basis.x * -width * 0.1) + Vector3.UP,
			backward_visual + Vector3.UP
		])
		
		triangles_array = PackedInt32Array([
			0, 2, 1,
			0, 3, 2
		])
		
		first_time = false
		is_even = false
		x = 4
		
		print("   - Vertices iniciales: ", vertices_array.size())
		print("   - Triángulos iniciales: ", triangles_array.size())
		
		update_trail_mesh()
		return
	
	# Continuar construyendo la malla
	if is_even:
		vertices_array.append(backward_visual)
		vertices_array.append(backward_visual - (enemy.global_transform.basis.x * -width * 0.1))
		vertices_array.append(backward_visual - (enemy.global_transform.basis.x * -width * 0.1) + Vector3.UP)
		vertices_array.append(backward_visual + Vector3.UP)
		
		triangles_array.append_array(PackedInt32Array([
			x - 4, x - 1, x,
			x - 4, x, x + 3,
			x - 4, x + 3, x + 2,
			x - 4, x + 2, x - 3,
			x - 3, x + 2, x + 1,
			x - 3, x + 1, x - 2
		]))
		is_even = false
	else:
		vertices_array.append(backward_visual + Vector3.UP)
		vertices_array.append(backward_visual - (enemy.global_transform.basis.x * -width * 0.1) + Vector3.UP)
		vertices_array.append(backward_visual - (enemy.global_transform.basis.x * -width * 0.1))
		vertices_array.append(backward_visual)
		
		triangles_array.append_array(PackedInt32Array([
			x - 4, x + 3, x,
			x - 4, x, x - 1,
			x - 2, x - 1, x,
			x - 2, x, x + 1,
			x - 3, x - 2, x + 1,
			x - 3, x + 1, x + 2
		]))
		is_even = true
	
	x += 4
	update_trail_mesh()

func create_trail_object() -> Node3D:
	var trail_container = Node3D.new()
	trail_container.name = "EnemyLightWallTrail_%s" % Time.get_ticks_msec()
	add_child(trail_container)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TrailMesh"
	trail_container.add_child(mesh_instance)
	
	var line_mesh = ArrayMesh.new()
	mesh_instance.mesh = line_mesh
	mesh_instance.material_override = custom_material
	
	var area = Area3D.new()
	area.name = "EnemyLightWallArea"
	trail_container.add_child(area)
	
	var mesh_collider = CollisionShape3D.new()
	area.add_child(mesh_collider)
	
	area.body_entered.connect(_on_lightwall_body_entered)
	area.collision_layer = 4  # Layer diferente
	area.collision_mask = 2
	
	trail_container.set_meta("mesh_instance", mesh_instance)
	trail_container.set_meta("line_mesh", line_mesh)
	trail_container.set_meta("mesh_collider", mesh_collider)
	trail_container.set_meta("area", area)
	
	print("🏗️ Trail object creado:")
	print("   - Mesh instance: ", mesh_instance != null)
	print("   - Material: ", custom_material != null)
	print("   - Area3D: ", area != null)
	
	return trail_container

func update_trail_mesh():
	if not current_trail:
		print("❌ UPDATE_TRAIL_MESH: current_trail es null")
		return
	
	var mesh_instance = current_trail.get_meta("mesh_instance")
	var line_mesh = current_trail.get_meta("line_mesh")
	var mesh_collider = current_trail.get_meta("mesh_collider")
	
	if not mesh_instance or not line_mesh:
		print("❌ UPDATE_TRAIL_MESH: mesh_instance o line_mesh es null")
		return
	
	line_mesh.clear_surfaces()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = triangles_array
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	update_trail_collision(mesh_collider)
	
	# Debug cada 30 llamadas
	if debug_frame_count % 30 == 0:
		print("🔄 Mesh actualizado - Vertices: ", vertices_array.size())

func update_trail_collision(mesh_collider: CollisionShape3D):
	if mesh_collider and vertices_array.size() > 0:
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(vertices_array)
		mesh_collider.shape = shape

func create_collision_segment(position: Vector3):
	var collision_node = Area3D.new()
	collision_node.name = "EnemyCollisionBox_%s" % Time.get_ticks_msec()
	current_trail.add_child(collision_node)
	
	collision_node.global_position = position
	
	var collision_shape = CollisionShape3D.new()
	collision_node.add_child(collision_shape)
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.05, 2.0, 0.3)
	collision_shape.shape = box_shape
	
	collision_node.rotation = enemy.global_rotation
	
	collision_node.collision_layer = 4
	collision_node.collision_mask = 2
	collision_node.body_entered.connect(_on_lightwall_body_entered)
	
	collision_boxes.append(collision_node)
func get_trails_array() -> Array:
	return trails_array

func get_vertices_array() -> PackedVector3Array:
	return vertices_array

func get_current_trail():
	return current_trail
func _on_lightwall_body_entered(body: Node3D):
	print("\n💥 COLISIÓN LIGHTWALL ENEMY")
	print("   - Body: ", body.name)
	print("   - Body class: ", body.get_class())
	
	if body.name == "CharacterBody3D":
		print("🎮 JUGADOR ELIMINADO por lightwall del enemy!")
		if Main:
			if Main.has_method("mostrar_game_over"):
				Main.mostrar_game_over()
			else:
				print("⚠️ Main no tiene método mostrar_game_over()")
				get_tree().reload_current_scene()
		else:
			print("⚠️ Main es null")
			get_tree().reload_current_scene()
	
	if body.name == "Enemy":
		print("💀 Enemy tocó su propia lightwall")
		body.queue_free()

# Función principal - llamar desde _physics_process del Enemy
func process_lightwall_physics():
	if not weapon_enable:
		return
	
	if not enemy:
		if debug_frame_count % 60 == 0:  # Solo mostrar cada segundo
			print("❌ PROCESS_LIGHTWALL_PHYSICS: enemy es null!")
		return
	
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	
	if tiempo_actual >= spawn_time:
		spawn_time = tiempo_actual + mono_spawn_delay
		mono_line()

func _process(delta):
	debug_frame_count += 1
	
	# Debug continuo cada 2 segundos
	var tiempo_actual_int = int(Time.get_ticks_msec() / 1000.0)
	if tiempo_actual_int % 2 == 0 and (debug_frame_count % 120) == 0:
		if weapon_enable:
			print("\n📊 LIGHTWALL STATUS:")
			print("   - Weapon enabled: ", weapon_enable)
			print("   - Current trail: ", current_trail != null)
			print("   - Trails array: ", trails_array.size())
			print("   - Vertices: ", vertices_array.size())
			print("   - Último mono_line: hace %.2fs" % (Time.get_ticks_msec() / 1000.0 - ultimo_mono_line))
			if enemy:
				print("   - Enemy position: ", enemy.global_position)
				print("   - Enemy velocity: ", enemy.velocity.length())
			else:
				print("   - Enemy: NULL")
