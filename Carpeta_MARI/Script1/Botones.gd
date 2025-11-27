extends Node2D

# 1. Definir las rutas de las escenas
# Asegúrate de que estos nombres de archivo coincidan exactamente con tus archivos .tscn
const ESCENA_MAPA = "res://Carpeta_MARI/Escenas/Mapa.tscn"
const ESCENA_INICIO = "res://Carpeta_MARI/Script1/Inicio del Juego.tscn"

# 2. Referencias a los botones
@onready var boton_reiniciar = $GridContainer/Button # Botón "Reiniciar"
@onready var boton_salir = $GridContainer/Button2   # Botón "Salir"


func _ready():
	# 3. Conectar las señales 'pressed' de los botones a las funciones
	boton_reiniciar.pressed.connect(_on_reiniciar_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)
	
	# Despausar el juego si la escena Mapa lo pausó antes de cargar esta escena
	# Esto es importante para que la UI responda
	get_tree().paused = false 


# --- Funciones de los botones ---

# Función para el botón "Reiniciar"
func _on_reiniciar_pressed():
	print("Botón Reiniciar presionado. Cargando Mapa...")
	
	# Cambia la escena a "Mapa.tscn"
	var error = get_tree().change_scene_to_file(ESCENA_MAPA)
	
	if error != OK:
		printerr("ERROR al cargar la escena Mapa.tscn: ", error)


# Función para el botón "Salir"
func _on_salir_pressed():
	print("Botón Salir presionado. Cargando Inicio del Juego...")
	
	# Cambia la escena a "Inicio del Juego.tscn"
	var error = get_tree().change_scene_to_file(ESCENA_INICIO)
	
	if error != OK:
		printerr("ERROR al cargar la escena Inicio del Juego.tscn: ", error)
