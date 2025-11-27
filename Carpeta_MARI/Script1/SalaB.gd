extends Area2D

# En el inspector de Godot, escribes manualmente el nombre: "SalaA", "SalaB", etc.
@export var nombre_en_minimapa: String = "SalaB" 

func _on_body_entered(body):
	# Verificamos que sea el jugador
	if body.name == "Player" or body.is_in_group("jugador"):
		
		# Buscamos el mapa dentro del jugador
		# (Asegúrate de que pusiste el MiniMapa dentro de un CanvasLayer en el Player)
		var mapa = body.get_node_or_null("CanvasLayer/MiniMapa")
		
		if mapa:
			# ¡Le avisamos al mapa!
			mapa.registrar_paso(nombre_en_minimapa)
			print("Entrando en: ", nombre_en_minimapa)
