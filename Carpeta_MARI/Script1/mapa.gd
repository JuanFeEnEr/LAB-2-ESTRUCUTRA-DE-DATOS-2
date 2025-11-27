extends Node2D

# Referencias a los nodos
@onready var timer_juego: Timer = $TimerJuego
@onready var label_tiempo: Label = $CanvasLayer2/LabelTiempo

# Variable para controlar si el juego terminó
var juego_terminado: bool = false

# Definimos las rutas a las escenas
const ESCENA_GANAR = "res://Carpeta_MARI/Escenas/Ganar.tscn"
const ESCENA_PERDER = "res://Carpeta_MARI/Escenas/Perder.tscn"
# Nota: La escena del Mapa es donde se adjunta este script

func _ready():
	# 💥 IMPORTANTE: Esto asegura que el timer siga contando 
	# aunque get_tree().paused = true (cuando cargas las pantallas de Ganar/Perder)
	timer_juego.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectamos la señal de "se acabó el tiempo"
	timer_juego.timeout.connect(_on_timer_timeout)

func _process(delta):
	# Si el juego sigue activo, actualizamos el texto del reloj
	if not juego_terminado:
		actualizar_reloj_ui()

# Esta función convierte los segundos en formato Minutos:Segundos
func actualizar_reloj_ui():
	var tiempo_restante = int(timer_juego.time_left)
	
	var minutos = tiempo_restante / 60
	var segundos = tiempo_restante % 60
	
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]
	
	# (Opcional) Poner el texto rojo si queda menos de 1 minuto
	if tiempo_restante < 60:
		label_tiempo.modulate = Color.RED
	else:
		label_tiempo.modulate = Color.WHITE

# Función cuando el tiempo llega a 0 (PERDER)
func _on_timer_timeout():
	juego_terminado = true
	print("¡Se acabó el tiempo! Has perdido.")
	label_tiempo.text = "00:00"
	cargar_escena(ESCENA_PERDER)

# Función auxiliar para detener el timer cuando GANAS
# Esta función debe ser llamada desde otra parte del juego (ej: al completar un objetivo)
func detener_timer_ganador():
	juego_terminado = true
	timer_juego.stop()
	print("¡Has ganado!")
	cargar_escena(ESCENA_GANAR)

# Función para manejar el cambio de escena
func cargar_escena(ruta_escena: String):
	# Pausa el juego para congelar la acción de fondo
	get_tree().paused = true 
	
	# Cambia a la escena de Ganar o Perder
	var error = get_tree().change_scene_to_file(ruta_escena)
	
	if error != OK:
		printerr("ERROR al cargar escena: ", ruta_escena, " - Código:", error)
