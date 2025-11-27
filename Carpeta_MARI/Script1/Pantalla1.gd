# Archivo: MenuPrincipal.gd

extends Node2D # O el tipo de nodo principal que estés usando

# Ruta a la escena a la que quieres cambiar.
# IMPORTANTE: Godot usa rutas relativas al proyecto, que siempre inician con "res://".
const NEXT_SCENE_PATH = "res://Escenas/Historia.tscn"

# --- Función Conectada al Botón ---
func _on_button_pressed():
	# 1. Cargar y Crear Instancia de la Nueva Escena
	var new_scene_resource = load(NEXT_SCENE_PATH)
	var next_level = new_scene_resource.instantiate()

	# 2. Acceder al Nodo Raíz (Viewport)
	# get_tree().get_root() es necesario para encontrar el contenedor principal
	# donde se añaden las escenas. Es la forma manual de cambiar de pantalla.
	var root = get_tree().get_root()

	# 3. Agregar la Nueva Escena a la Raíz
	# Esto hace que el Nivel 1 se muestre en pantalla.
	root.add_child(next_level)

	# 4. Eliminar la Escena Actual (El Menú)
	# queue_free() elimina este nodo (el menú) y todos sus hijos 
	# de forma segura al final del frame.
	queue_free()


func _on_salir_pressed() -> void:
	get_tree().quit()
