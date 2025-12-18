extends Node

# Variable para guardar el volumen actual (1.0 = 100%, 0.0 = 0%)
var current_volume_linear: float = 1.0

func _ready():
	# Asegurarse de que el volumen se aplique en cuanto el juego inicie
	set_master_volume(current_volume_linear)

# Esta es la función que llamarán tus sliders
func set_master_volume(linear_value: float):
	# Guardar el valor actual
	current_volume_linear = linear_value
	
	# Convertir el valor lineal (0-1) a decibelios (logarítmico)
	# Usamos -80db como silencio total para evitar problemas con -infinito
	var db_value: float
	if linear_value < 0.001:
		db_value = -80.0
	else:
		db_value = linear_to_db(linear_value)
		
	# Aplicar este valor al bus "Master" (el canal de audio principal)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_value)
