extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0 
const WALL_SLIDE_FALL_SPEED = 50.0 
const WALL_JUMP_HORIZONTAL_FORCE = 350.0 
const WALL_JUMP_VERTICAL_FORCE = -380.0 
const WALL_JUMP_COYOTE_TIME = 0.1 
const WALL_JUMP_BUFFER_TIME = 0.1 

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animationPlayer = $AnimationPlayer 
@onready var sprite_node = $Sprite2D 
@onready var wall_detector_right = $pared_derecha
@onready var wall_detector_left = $pared_izquierda   

var is_wall_sliding = false
var last_on_wall_timer = 0.0 
var jump_buffer_timer = 0.0 

func _ready():
	pass

func _physics_process(_delta):
	var direction_x_input = 0 
	
	# --- 0. Actualizar Timers ---
	last_on_wall_timer -= _delta
	jump_buffer_timer -= _delta

	# --- Capturar Input Horizontal ---
	if Input.is_action_pressed("ui_right"):
		direction_x_input += 1
	if Input.is_action_pressed("ui_left"): 
		direction_x_input -= 1 

	# --- Aplicar Gravedad y Wall Slide ---
	if not is_on_floor():
		var touching_wall_right = wall_detector_right.is_colliding()
		var touching_wall_left = wall_detector_left.is_colliding()
		
		# Lógica para determinar si nos pegamos a la pared
		var on_wall = (touching_wall_right and direction_x_input >= 0) or \
					  (touching_wall_left and direction_x_input <= 0) or \
					  (touching_wall_right and direction_x_input == -1) or \
					  (touching_wall_left and direction_x_input == 1)

		is_wall_sliding = false
		if on_wall and not is_on_floor() and velocity.y >= 0: 
			is_wall_sliding = true
			velocity.y = min(velocity.y + (gravity * _delta), WALL_SLIDE_FALL_SPEED)
			last_on_wall_timer = WALL_JUMP_COYOTE_TIME 
		else:
			velocity.y += gravity * _delta 
	else:
		is_wall_sliding = false 
		last_on_wall_timer = 0.0 
	
	# --- Lógica de Salto (BUFFER) ---
	if Input.is_action_just_pressed("ui_up"):
		jump_buffer_timer = WALL_JUMP_BUFFER_TIME 

	# --- EJECUTAR SALTO ---
	if jump_buffer_timer > 0: 
		if is_on_floor(): 
			# Salto normal desde el suelo
			velocity.y = JUMP_VELOCITY
			is_wall_sliding = false 
			jump_buffer_timer = 0 
		
		elif is_wall_sliding or last_on_wall_timer > 0: 
			# --- LÓGICA CORREGIDA PARA SALTO DE PARED ---
			
			# 1. Identificar en qué lado está la pared (-1 izquierda, 1 derecha)
			var wall_side = 0
			if wall_detector_right.is_colliding(): wall_side = 1
			elif wall_detector_left.is_colliding(): wall_side = -1
			elif last_on_wall_timer > 0: 
				# Si estamos en coyote time, adivinamos la pared basada en input previo
				if direction_x_input != 0: wall_side = -direction_x_input

			if wall_side != 0: # Si confirmamos que hay pared
				
				# CASO A: ESCALAR (Input hacia la pared)
				# Si la pared está a la derecha (1) y presionas derecha (1) -> Iguales
				if direction_x_input == wall_side: 
					velocity.y = WALL_JUMP_VERTICAL_FORCE
					# Pequeño empujón hacia la pared para no perder el contacto (el detector)
					velocity.x = wall_side * 10 
				
				# CASO B: REBOTAR (Input contrario o neutro)
				# Si quieres ir al otro lado, te impulsamos fuerte
				else: 
					velocity.y = WALL_JUMP_VERTICAL_FORCE
					# Impulso fuerte hacia el lado contrario (-wall_side)
					velocity.x = -wall_side * WALL_JUMP_HORIZONTAL_FORCE
					if sprite_node: sprite_node.flip_h = (-wall_side == -1) 

				is_wall_sliding = false 
				jump_buffer_timer = 0 
				last_on_wall_timer = 0 
	
	# --- Movimiento Horizontal ---
	# Verificamos si estamos en medio de un "Rebote de pared" fuerte.
	# Si velocity.x es muy alta (mayor al 80% de la fuerza de rebote), bloqueamos el control un momento.
	# Si estamos escalando (velocity.x es 10), esta condición es falsa y tienes control inmediato.
	var is_wall_kicking = not is_on_floor() and abs(velocity.x) > WALL_JUMP_HORIZONTAL_FORCE * 0.8
	
	if not is_wall_kicking:
		if direction_x_input != 0:
			velocity.x = direction_x_input * SPEED
			if sprite_node: sprite_node.flip_h = direction_x_input < 0 
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * _delta * 5)
	
	# --- Animaciones ---
	var anim_to_play = "quieta" 

	if is_on_floor():
		if direction_x_input != 0:
			anim_to_play = "correr"
		else:
			anim_to_play = "quieta"
	else: 
		if is_wall_sliding:
			anim_to_play = "deslizar"
		elif velocity.y < 0: 
			anim_to_play = "saltar" 
		else: 
			anim_to_play = "caer" 

	if animationPlayer and animationPlayer.has_animation(anim_to_play):
		if animationPlayer.current_animation != anim_to_play:
			animationPlayer.play(anim_to_play)
		
	move_and_slide()
