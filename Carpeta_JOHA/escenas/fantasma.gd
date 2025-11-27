extends CharacterBody2D

@export var velocidad = 60.0
@export var punto_a: Node2D 
@export var punto_b: Node2D 
@export var es_el_elegido: bool = false 

var objetivo_actual = null
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

var en_pausa = false 
var esta_muerto = false # NUEVA VARIABLE: Para saber si ya murió

func _ready():
	if $AnimatedSprite2D: $AnimatedSprite2D.play("caminar")
	
	# Preparamos el área de daño para detectar al jugador
	if $AreaDano:
		# Conectar señal si no lo has hecho en el editor
		if not $AreaDano.body_entered.is_connected(_on_body_entered):
			$AreaDano.body_entered.connect(_on_body_entered)

	if punto_a and punto_b:
		objetivo_actual = punto_b 
		print("Fantasma iniciado en: ", name)
	else:
		print("ERROR: FALTAN PUNTOS EN ", name)

func _physics_process(delta):
	# 1. GRAVEDAD SIEMPRE (Vital para que caiga al morir)
	# Quitamos el 'if not is_on_floor()' para que caiga incluso si atravesamos suelo
	velocity.y += gravedad * delta

	# --- SI ESTÁ MUERTO: SOLO CAE ---
	if esta_muerto:
		move_and_slide()
		return # <--- AQUÍ TERMINA EL CÓDIGO SI ESTÁ MUERTO
	
	# --- SI ESTÁ VIVO: PATRULLA ---
	if en_pausa:
		move_and_slide()
		return

	if punto_a and punto_b and objetivo_actual:
		var diferencia_x = objetivo_actual.global_position.x - global_position.x
		
		if abs(diferencia_x) > 10:
			var direccion = sign(diferencia_x)
			velocity.x = direccion * velocidad
			if $AnimatedSprite2D: $AnimatedSprite2D.flip_h = (direccion < 0)
		else:
			llegar_y_cambiar()
	
	move_and_slide()

func llegar_y_cambiar():
	en_pausa = true 
	velocity.x = 0 
	await get_tree().create_timer(0.5).timeout
	
	if objetivo_actual == punto_a: objetivo_actual = punto_b
	else: objetivo_actual = punto_a
	
	en_pausa = false 

# --- ESTA FUNCIÓN MATA AL JUGADOR SI LO TOCA ---
func _on_body_entered(body):
	if body.name == "Jugador" or body.is_in_group("jugador"):
		if not esta_muerto:
			print("Maté al jugador")
			# Aquí reinicias la escena si quieres:
			# get_tree().reload_current_scene()

# --- ESTA FUNCIÓN ES LA QUE LLAMA LA ESPADA ---
func morir():
	if esta_muerto: return # Si ya está muerto, ignorar
	
	print("¡AGHHH! Me muero (Caída dramática)")
	esta_muerto = true # Activamos estado de muerte
	
	# 1. EFECTO DE SALTO (La agonía)
	velocity.y = -300 # Saltito hacia arriba
	velocity.x = 0    # Deja de avanzar
	
	# 2. DESACTIVAR COLISIONES FÍSICAS (Para que atraviese el suelo)
	# IMPORTANTE: Busca tu CollisionShape2D y asegúrate que se llame así
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	# 3. DESACTIVAR ÁREA DE DAÑO (Para que no mate al jugador mientras cae)
	if has_node("AreaDano"):
		$AreaDano.set_deferred("monitoring", false)
	
	# 4. EFECTO VISUAL (Opcional: Voltear patas arriba o poner rojo)
	modulate = Color(1, 0, 0) # Se pone rojo
	if $AnimatedSprite2D: $AnimatedSprite2D.stop() # Pausar animación
	
	# 5. LÓGICA DEL JUEGO (UI)
	if es_el_elegido:
		print("¡Liberando mapa!")
		get_tree().call_group("ui_monitor", "mostrar_mapa_completo")
	
	# 6. ESPERAR A QUE CAIGA Y LUEGO BORRAR
	await get_tree().create_timer(3.0).timeout # Esperamos 3 segundos cayendo
	queue_free()
