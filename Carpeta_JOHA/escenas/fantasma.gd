extends CharacterBody2D

@export var velocidad = 60.0
@export var punto_a: Node2D 
@export var punto_b: Node2D 
@export var es_el_elegido: bool = false 

var objetivo_actual = null
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- ESTA ES LA CLAVE PARA QUE NO SE VUELVA LOCO ---
var en_pausa = false 

func _ready():
	if $AnimatedSprite2D: $AnimatedSprite2D.play("caminar")
	
	if punto_a and punto_b:
		# Empezamos yendo hacia el B (hacia la derecha)
		objetivo_actual = punto_b 
		print("Fantasma iniciado. Voy hacia: ", objetivo_actual.name)
	else:
		print("ERROR: FALTAN PUNTOS EN ", name)

func _physics_process(delta):
	# 1. Gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta

	# SI ESTAMOS EN PAUSA, NO CALCULAMOS MOVIMIENTO
	if en_pausa:
		move_and_slide()
		return # <--- Salimos de la función aquí mismo

	if punto_a and punto_b and objetivo_actual:
		
		# 2. Calcular distancia
		var diferencia_x = objetivo_actual.global_position.x - global_position.x
		
		# 3. Moverse si estamos lejos (Mayor a 10 pixeles)
		if abs(diferencia_x) > 10:
			var direccion = sign(diferencia_x)
			velocity.x = direccion * velocidad
			
			if $AnimatedSprite2D:
				$AnimatedSprite2D.flip_h = (direccion < 0)
		
		# 4. LLEGADA
		else:
			# Llegamos (estamos a menos de 10 pixeles)
			llegar_y_cambiar()
	
	move_and_slide()

func llegar_y_cambiar():
	# Activamos el semáforo en ROJO
	en_pausa = true 
	velocity.x = 0 # Frenamos en seco
	
	print("Llegué a ", objetivo_actual.name, ". Esperando un momento...")
	
	# Esperamos 0.5 segundos (o lo que quieras)
	await get_tree().create_timer(0.5).timeout
	
	# Cambiamos el objetivo
	if objetivo_actual == punto_a:
		objetivo_actual = punto_b
		print("¡Cambio! Ahora voy a la DERECHA (Punto B)")
	else:
		objetivo_actual = punto_a
		print("¡Cambio! Ahora voy a la IZQUIERDA (Punto A)")
	
	# Activamos el semáforo en VERDE
	en_pausa = false
