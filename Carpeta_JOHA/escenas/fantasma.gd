extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export var tiene_clave: bool = false
@export var velocidad: float = 50.0

# CAMBIO 1: Usamos Array[Node2D] en lugar de NodePath. 
# Esto hace que la conexión en el editor sea más solida.
# Cuando vayas al Inspector, borra lo que tenías y vuelve a asignar los Marker2D.
@export var puntos_de_patrulla: Array[Node2D] 

signal fantasma_muerto(es_clave)

# --- VARIABLES INTERNAS ---
# Si quieres que camine (no vuele), descomenta la gravedad
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity") 

var indice_objetivo_actual = 0
var esta_muriendo = false

@onready var sprite = $AnimatedSprite2D
@onready var area_dano = $AreaDano 

func _ready():
	# Ya no necesitamos convertir rutas, porque exportamos Node2D directamente
	
	# Verificación de seguridad para ver si encontró los puntos
	if puntos_de_patrulla.size() == 0:
		print("ERROR: El fantasma ", name, " no tiene puntos de patrulla asignados en el Inspector.")
	
	area_dano.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if esta_muriendo: return

	# 1. Aplicar Gravedad (IMPORTANTE: Si es un fantasma que camina)
	# Si tus Markers están a ras de suelo, necesitas gravedad para que el fantasma baje si hay desniveles.
	if not is_on_floor():
		velocity.y += gravedad * delta

	# 2. Movimiento de Patrulla
	if puntos_de_patrulla.size() > 0:
		var objetivo = puntos_de_patrulla[indice_objetivo_actual]
		
		# Verificamos que el punto exista (por si lo borraste sin querer)
		if objetivo != null:
			# Calcular dirección
			var direccion = (objetivo.global_position - global_position).normalized()
			
			# MOVIMIENTO:
			# Opción A: Fantasma Volador (Se mueve en X y Y hacia el punto)
			# velocity = direccion * velocidad 
			
			# Opción B: Fantasma Caminante (Solo se mueve en X, la gravedad maneja la Y)
			velocity.x = direccion.x * velocidad
			
			# Voltear sprite
			if velocity.x > 0:
				sprite.flip_h = false 
			elif velocity.x < 0:
				sprite.flip_h = true 
				
			# Verificar si llegamos (Aumenté un poco el rango a 20.0 para facilitar detección)
			# Usamos distance_to pero solo considerando la posición X si es caminante
			if abs(global_position.x - objetivo.global_position.x) < 20.0:
				pasar_al_siguiente_punto()
		
	move_and_slide()

func pasar_al_siguiente_punto():
	indice_objetivo_actual += 1
	if indice_objetivo_actual >= puntos_de_patrulla.size():
		indice_objetivo_actual = 0

# Detectar contacto con el jugador
func _on_body_entered(body):
	# CAMBIO 2: Debugging
	# Esto imprimirá en la consola qué está tocando el área. 
	# Si toca al TileMap o paredes, lo verás aquí.
	print("Fantasma tocó a: ", body.name) 

	# CAMBIO 3: Usar Grupos en vez de nombre exacto
	# Asegúrate de añadir a tu Jugador al grupo "jugador"
	if body.is_in_group("jugador"): 
		
		# Lógica de salto (Mario Bros)
		# Comparamos la posición Y. Recuerda: en Godot Y crece hacia abajo.
		# Si el jugador está más ARRIBA (menor Y) que el fantasma...
		if body.global_position.y < global_position.y - 10: # El -10 da un margen de error a favor del jugador
			print("El jugador aplastó al fantasma")
			body.velocity.y = -300 
			morir()
		else:
			print("El jugador ha sido infectado!")
			# Aquí matas al jugador o le quitas vida.
			# get_tree().reload_current_scene() # Ejemplo: Reiniciar nivel

func morir():
	if esta_muriendo: return
	esta_muriendo = true
	print("Fantasma eliminado. ¿Tenía clave? ", tiene_clave)
	
	$CollisionShape2D.set_deferred("disabled", true)
	area_dano.set_deferred("monitoring", false)
	
	emit_signal("fantasma_muerto", tiene_clave)
	
	modulate = Color(1, 0, 0, 0) 
	await get_tree().create_timer(0.2).timeout 
	queue_free()
