extends CharacterBody2D

# --- CONFIGURACIÓN MOVIMIENTO ---
const SPEED = 150.0
const JUMP_VELOCITY = -300.0 
const WALL_SLIDE_FALL_SPEED = 50.0 
const WALL_JUMP_HORIZONTAL_FORCE = 350.0 
const WALL_JUMP_VERTICAL_FORCE = -380.0 
const WALL_JUMP_COYOTE_TIME = 0.1 
const WALL_JUMP_BUFFER_TIME = 0.1 

# --- VARIABLES SISTEMA ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- NODOS ORIGINALES ---
@onready var animationPlayer = $AnimationPlayer 
@onready var sprite_node = $Sprite2D 
@onready var wall_detector_right = $pared_derecha
@onready var wall_detector_left = $pared_izquierda   

# --- NUEVOS NODOS (ESPADA) ---
@onready var pivote_espada = $PivoteEspada
@onready var area_espada = $PivoteEspada/AreaEspada
@onready var sprite_espada = $PivoteEspada/AreaEspada/SpriteEspada
@onready var colision_espada = $PivoteEspada/AreaEspada/CollisionShape2D

# --- VARIABLES DE ESTADO ---
var is_wall_sliding = false
var last_on_wall_timer = 0.0 
var jump_buffer_timer = 0.0 
var atacando = false 

func _ready():
	# Configuración inicial de la espada
	if sprite_espada: sprite_espada.visible = false
	if colision_espada: colision_espada.disabled = true
	
	# Conexión automática de señal
	if area_espada:
		if not area_espada.body_entered.is_connected(_on_espada_impacto):
			area_espada.body_entered.connect(_on_espada_impacto)

func _physics_process(delta):
	var direction_x_input = 0 
	
	# --- 0. Actualizar Timers ---
	last_on_wall_timer -= delta
	jump_buffer_timer -= delta

	# --- Capturar Input Horizontal ---
	if Input.is_action_pressed("ui_right"):
		direction_x_input += 1
	if Input.is_action_pressed("ui_left"): 
		direction_x_input -= 1 

	# --- [CORRECCIÓN PRINCIPAL] SINCRONIZACIÓN ESPADA/SPRITE ---
	
	# 1. Primero actualizamos hacia dónde mira el sprite si nos estamos moviendo
	if direction_x_input > 0:
		sprite_node.flip_h = false # Mira derecha
	elif direction_x_input < 0:
		sprite_node.flip_h = true # Mira izquierda
	
	# 2. Ahora obligamos a la espada a mirar a donde mire el sprite (incluso quietos)
	# Usamos un valor fijo de distancia (ej: 20 pixeles) o la actual si ya está configurada
	var distancia_mano = 20 
	if abs(pivote_espada.position.x) > 0: distancia_mano = abs(pivote_espada.position.x)
	
	if sprite_node.flip_h: # Si el Sprite mira a la IZQUIERDA
		pivote_espada.scale.x = -1 # Volteamos espada
		pivote_espada.position.x = -distancia_mano # Movemos pivote a la izq
	else: # Si el Sprite mira a la DERECHA
		pivote_espada.scale.x = 1 # Espada normal
		pivote_espada.position.x = distancia_mano # Movemos pivote a la der

	# --- ATAQUE ---
	if Input.is_action_just_pressed("ui_accept") and not atacando:
		realizar_ataque()

	# --- Aplicar Gravedad y Wall Slide ---
	if not is_on_floor():
		var touching_wall_right = wall_detector_right.is_colliding()
		var touching_wall_left = wall_detector_left.is_colliding()
		
		var on_wall = (touching_wall_right and direction_x_input >= 0) or \
					  (touching_wall_left and direction_x_input <= 0) or \
					  (touching_wall_right and direction_x_input == -1) or \
					  (touching_wall_left and direction_x_input == 1)

		is_wall_sliding = false
		if on_wall and not is_on_floor() and velocity.y >= 0: 
			is_wall_sliding = true
			velocity.y = min(velocity.y + (gravity * delta), WALL_SLIDE_FALL_SPEED)
			last_on_wall_timer = WALL_JUMP_COYOTE_TIME 
		else:
			velocity.y += gravity * delta 
	else:
		is_wall_sliding = false 
		last_on_wall_timer = 0.0 
	
	# --- Lógica de Salto (BUFFER) ---
	if Input.is_action_just_pressed("ui_up"):
		jump_buffer_timer = WALL_JUMP_BUFFER_TIME 

	# --- EJECUTAR SALTO ---
	if jump_buffer_timer > 0: 
		if is_on_floor(): 
			velocity.y = JUMP_VELOCITY
			is_wall_sliding = false 
			jump_buffer_timer = 0 
		elif is_wall_sliding or last_on_wall_timer > 0: 
			var wall_side = 0
			if wall_detector_right.is_colliding(): wall_side = 1
			elif wall_detector_left.is_colliding(): wall_side = -1
			elif last_on_wall_timer > 0: 
				if direction_x_input != 0: wall_side = -direction_x_input

			if wall_side != 0: 
				if direction_x_input == wall_side: 
					velocity.y = WALL_JUMP_VERTICAL_FORCE
					velocity.x = wall_side * 10 
				else: 
					velocity.y = WALL_JUMP_VERTICAL_FORCE
					velocity.x = -wall_side * WALL_JUMP_HORIZONTAL_FORCE
					# Nota: El flip del sprite ya se manejó arriba, no es necesario repetirlo aquí
					# pero lo dejamos por seguridad en el salto de pared
					if sprite_node: sprite_node.flip_h = (-wall_side == -1) 

				is_wall_sliding = false 
				jump_buffer_timer = 0 
				last_on_wall_timer = 0 
	
	# --- Movimiento Horizontal ---
	var is_wall_kicking = not is_on_floor() and abs(velocity.x) > WALL_JUMP_HORIZONTAL_FORCE * 0.8
	
	if not is_wall_kicking:
		if direction_x_input != 0:
			velocity.x = direction_x_input * SPEED
			# El flip del sprite ya se manejó arriba
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta * 5)
	
	# --- Animaciones ---
	var anim_to_play = "quieta" 
	if is_on_floor():
		if direction_x_input != 0: anim_to_play = "correr"
		else: anim_to_play = "quieta"
	else: 
		if is_wall_sliding: anim_to_play = "deslizar"
		elif velocity.y < 0: anim_to_play = "saltar" 
		else: anim_to_play = "caer" 

	if animationPlayer and animationPlayer.has_animation(anim_to_play):
		if animationPlayer.current_animation != anim_to_play:
			animationPlayer.play(anim_to_play)
		
	move_and_slide()

# --- FUNCIONES DE ATAQUE ---

func realizar_ataque():
	atacando = true
	sprite_espada.visible = true
	colision_espada.disabled = false
	
	await get_tree().create_timer(0.3).timeout
	
	sprite_espada.visible = false
	colision_espada.disabled = true
	atacando = false

func _on_espada_impacto(body):
	# 1. EVITAR GOLPEARNOS A NOSOTROS MISMOS
	if body == self:
		return 

	print("Golpeé a: ", body.name)

	# 2. INTENTAR MATAR AL ENEMIGO
	if body.has_method("morir"):
		print("¡Matando a ", body.name, "!")
		body.morir()
	else:
		print("ERROR: ", body.name, " no tiene la función 'morir'.")
