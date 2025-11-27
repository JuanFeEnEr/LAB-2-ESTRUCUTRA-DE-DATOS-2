extends Area2D

# Nombre para el minimapa
@export var nombre_en_minimapa: String = "SalaF" 

func _on_body_entered(body):
	# 1. Verificamos que sea el jugador (Unificamos los nombres por si acaso)
	if body.name == "Player" or body.name == "Jugador" or body.is_in_group("jugador"):
		
		# --- PARTE A: MINIMAPA ---
		# Buscamos el nodo del mapa dentro del jugador
		var mapa = body.get_node_or_null("CanvasLayer/MiniMapa")
		if mapa:
			mapa.registrar_paso(nombre_en_minimapa)
			print("Registrado en minimapa: ", nombre_en_minimapa)
			
		# --- PARTE B: GANAR EL JUEGO (TIMER) ---
		# Como el Timer y el UI están en el nodo PADRE (la escena del Mapa),
		# no podemos llamarlos directamente aquí. Llamamos a la función del padre.
		
		var nodo_mapa = get_parent() # Obtenemos el nodo raíz de la escena
		
		# Verificamos si el mapa tiene la función de ganar que creamos antes
		if nodo_mapa.has_method("detener_timer_ganador"):
			# Le decimos al mapa que ejecute la victoria
			nodo_mapa.detener_timer_ganador()
			
			# NOTA: No hace falta hacer panel.show() aquí, 
			# porque la función 'detener_timer_ganador' del mapa YA hace eso.
