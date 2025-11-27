extends Node
# Aquí guardaremos "DFS" o "BFS"
var algoritmo_seleccionado: String = ""
var key_founded: Array[String] = [] # Stores names of collected keys

# NUEVAS VARIABLES
var key_to_collect: Node = null  # Referencia a la llave que espera ser recogida
var player_reference: Node = null # Referencia al jugador que inició el hack
var return_scene_path: String = "" # Ruta de la escena para volver
# Nivel actual del jugador
var nivel_actual: int = 1

func add_key(key_name: String):
	if not key_name in key_founded:
		key_founded.append(key_name)
		print("Key '" + key_name + "' collected!")

var salas_visitadas: Array = []      # Lista de salas por las que ya pasamos (ej: ["SalaA", "SalaB"])
var conexiones_pintadas: Array = []  # Lista de cables encendidos (ej: ["A-B", "B-C"])
var ultima_sala: String = ""         # La última sala donde estuvo el jugador
