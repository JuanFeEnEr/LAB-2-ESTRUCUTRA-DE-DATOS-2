extends Area2D # Es crucial que tu puerta sea un Area2D o contenga uno.

# Ruta de la escena a la que queremos cambiar al interactuar con la puerta.
# Puedes cambiarla fácilmente desde el Inspector de Godot.
@export var next_scene_path: String = "res://Escenas/pantalla2.tscn" # ¡IMPORTANTE: Cambia esto a la ruta de tu siguiente escena!
@export var requires_key: bool = false # ¿Requiere una llave para abrirse?
@export var key_item_name: String = "llave_dorada" # Nombre de la llave requerida

func _ready() -> void:
	# Conecta la señal body_entered del Area2D a esta función
	# Esto es para la detección cuando el jugador simplemente pasa por ella (no "interactúa" con 'E')
	# Si solo quieres interacción con 'E', puedes omitir esta conexión directa o usar 'area_entered' si tu jugador tiene un Area2D
	pass # Si ya lo conectaste desde el editor, no necesitas esto.


# Este método se llamará desde el jugador cuando el jugador pulse "interactar" ('E')
func interact(player_node: Node) -> void:
	print("El jugador intenta interactuar con la puerta.")

	if requires_key:
		if player_node.has_method("get_held_item") and player_node.get_held_item() == key_item_name:
			print("¡Puerta abierta con la llave!")
			change_to_next_scene()
		else:
			print("La puerta requiere la llave: ", key_item_name)
			# Opcional: Mostrar un mensaje en pantalla al jugador
	else:
		print("¡Puerta abierta!")
		change_to_next_scene()

func change_to_next_scene() -> void:
	if next_scene_path != "":
		print("Cambiando a la escena: ", next_scene_path)
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("ERROR: No se ha especificado una ruta de escena para la puerta.")

# Si quieres que la puerta se abra solo con tocarla, sin necesidad de pulsar "interactar",
# conecta la señal 'body_entered' de esta Area2D a esta función.
func _on_puerta_body_entered(body: Node2D) -> void:
	# Asegúrate de que solo el jugador active esto
	if body.name == "Player": # O 'if body.is_in_group("player"):'
		print("El jugador ha entrado en el área de la puerta (sin interacción 'E').")
		# Si la puerta no requiere llave y quieres que se abra solo con tocarla:
		if not requires_key:
			change_to_next_scene()
		# Si requiere llave, aquí no haríamos nada o mostraríamos un mensaje.
