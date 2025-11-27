extends Control

# Arrastra tus nodos de botón aquí con Ctrl para corregir las rutas si fallan
@onready var boton_dfs = $HBoxContainer/DFS
@onready var boton_bfs = $HBoxContainer/BFS

func _ready():
	# Conectamos las señales (si no lo hiciste desde el editor)
	boton_dfs.pressed.connect(_on_dfs_pressed)
	boton_bfs.pressed.connect(_on_bfs_pressed)

func _on_dfs_pressed():
	seleccionar_ruta("DFS")

func _on_bfs_pressed():
	seleccionar_ruta("BFS")

func seleccionar_ruta(tipo: String):
	# --- AQUÍ OCURRE LA MAGIA ---
	
	# 1. GUARDAR EN EL GLOBAL
	Global.algoritmo_seleccionado = tipo
	print("Guardado en Global: ", Global.algoritmo_seleccionado)
	
	# 2. LLAMAR AL DIÁLOGO PARA QUE REACCIONE
	# Asegúrate de que la ruta "res://..." apunta a tu archivo de diálogo real
	get_tree().change_scene_to_file("res://Carpeta_MARI/Escenas/Mapa.tscn") 
	
