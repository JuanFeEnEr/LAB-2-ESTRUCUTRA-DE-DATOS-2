extends CharacterBody2D

@export var velocidad = 60.0
@export var punto_a: Node2D 
@export var punto_b: Node2D 
@export var es_el_elegido: bool = false 

# --- SISTEMA DE VIDA ---
var vida_maxima = 3
var vida_actual = 0

var objetivo_actual = null
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var en_pausa = false 
var esta_muerto = false 

func _ready():
	if $AnimatedSprite2D: $AnimatedSprite2D.play("caminar")
	
	# --- CONFIGURACIÓN DE VIDA ---
	if es_el_elegido:
		vida_maxima = 5 # El jefe aguanta 5 golpes
		# Opcional: Hacerlo un poquito más grande para que imponga respeto
		position.y -= 20 
		
	else:
		vida_maxima = 3 # Los normales aguantan 3
	
	vida_actual = vida_maxima
	
	# Verificar puntos
	if punto_a and punto_b:
		objetivo_actual = punto_b 
	
	# Conectar área de daño al jugador
	if has_node("AreaDano"):
		if not $AreaDano.body_entered.is_connected(_on_body_entered):
			$AreaDano.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Gravedad
	velocity.y += gravedad * delta

	if esta_muerto or en_pausa:
		move_and_slide()
		return

	# Patrulla
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

# --- NUEVA FUNCIÓN: RECIBIR DAÑO ---
func recibir_dano():
	if esta_muerto: return
	
	vida_actual -= 1
	print(name, " recibió un golpe. Vida restante: ", vida_actual)
	
	# EFECTO VISUAL: Parpadeo ROJO al recibir golpe
	modulate = Color(10, 0, 0) # Rojo brillante intenso
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1) # Volver a color normal
	
	if vida_actual <= 0:
		morir()

func morir():
	if esta_muerto: return
	esta_muerto = true
	print("¡Fantasma eliminado!")
	
	# Efecto de muerte (caída)
	velocity.y = -300
	velocity.x = 0
	if has_node("CollisionShape2D"): $CollisionShape2D.set_deferred("disabled", true)
	if has_node("AreaDano"): $AreaDano.set_deferred("monitoring", false)
	modulate = Color(0.5, 0.5, 0.5, 0.5) # Gris transparente
	
	# --- LÓGICA DEL ELEGIDO ---
	if es_el_elegido:
		print("¡Era el portador! Desbloqueando mapa...")
		get_tree().call_group("ui_monitor", "mostrar_mapa_completo")
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _on_body_entered(body):
	if body.name == "Jugador" or body.is_in_group("jugador"):
		if not esta_muerto:
			# Aquí decides si el jugador muere o pierde vida
			print("El fantasma tocó al jugador")
