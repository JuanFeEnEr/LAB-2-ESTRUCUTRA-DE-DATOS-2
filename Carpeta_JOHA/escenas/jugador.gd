extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0 # Velocidad de salto normal
const WALL_SLIDE_FALL_SPEED = 50.0 # Velocidad máxima de caída al deslizarse por la pared
const WALL_JUMP_HORIZONTAL_FORCE = 250.0 # Fuerza horizontal del salto de pared
const WALL_JUMP_VERTICAL_FORCE = -300.0 # Fuerza vertical del salto de pared

# Gravedad es un valor global en Godot para CharacterBody2D.
# Puedes obtenerlo del Project Settings o definirlo aquí si no lo has hecho globalmente.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animationPlayer = $AnimationPlayer 
@onready var sprite_node = $Sprite2D
@onready var wall_detector_right = $pared_derecha 
@onready var wall_detector_left = $pared_izquierda   

var is_wall_sliding = false # Nuevo estado para el deslizamiento automático por la pared

func _ready():
	# Depuración inicial para asegurar que los nodos existen
	if sprite_node:
		print("Nodo sprite_node encontrado: ", sprite_node.name, " de tipo: ", sprite_node.get_class())
	else:
		print("¡ERROR! Nodo 'jugador' NO encontrado o la ruta es incorrecta.")
	if animationPlayer:
		print("Nodo animationPlayer encontrado: ", animationPlayer.name, " de tipo: ", animationPlayer.get_class())
	else:
		print("¡ERROR! Nodo 'AnimationPlayer' NO encontrado o la ruta es incorrecta.")
	if wall_detector_right:
		print("Nodo WallDetectorRight encontrado.")
	else:
		print("¡ERROR! Nodo 'WallDetectorRight' NO encontrado o la ruta es incorrecta.")
	if wall_detector_left:
		print("Nodo WallDetectorLeft encontrado.")
	else:
		print("¡ERROR! Nodo 'WallDetectorLeft' NO encontrado o la ruta es incorrecta.")


func _physics_process(_delta):
	var direction_x_input = 0 # Usaremos esto para saber la dirección del input horizontal
	
	# --- Capturar Input Horizontal ---
	if Input.is_action_pressed("ui_right"):
		direction_x_input += 1
	if Input.is_action_pressed("ui_left"): 
		direction_x_input -= 1 

	# --- Aplicar Gravedad (Modificada para Wall Slide) ---
	if not is_on_floor():
		# Detección de paredes (se hace aquí para decidir la gravedad)
		var touching_wall_right = wall_detector_right.is_colliding()
		var touching_wall_left = wall_detector_left.is_colliding()
		
		# Solo se considera "en pared" si no te alejas activamente de ella
		var on_wall = (touching_wall_right and direction_x_input >= 0) or \
					  (touching_wall_left and direction_x_input <= 0)

		is_wall_sliding = false
		if on_wall and not is_on_floor() and velocity.y >= 0: # Si está en pared, no en suelo, y cayendo o quieto verticalmente
			is_wall_sliding = true
			velocity.y = min(velocity.y + (gravity * _delta), WALL_SLIDE_FALL_SPEED) # Gravedad reducida y limitada
		else:
			velocity.y += gravity * _delta # Gravedad normal
	
	# --- Lógica de "Wall Jump" y Salto Normal ---
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_wall_sliding = false # Salta del suelo, no desliza
		elif is_wall_sliding: # Si está deslizando por una pared, puede hacer wall jump
			# Determinar la dirección del salto de pared (opuesta a la pared que se toca)
			var wall_jump_dir = 0
			if wall_detector_right.is_colliding(): wall_jump_dir = -1
			elif wall_detector_left.is_colliding(): wall_jump_dir = 1
			
			if wall_jump_dir != 0: # Si hay una pared válida para saltar
				velocity.y = WALL_JUMP_VERTICAL_FORCE
				velocity.x = wall_jump_dir * WALL_JUMP_HORIZONTAL_FORCE
				if sprite_node: sprite_node.flip_h = (wall_jump_dir == -1) # Voltear si salta a la izquierda
				is_wall_sliding = false # Ya no desliza, está saltando

	# --- Movimiento Horizontal (después del Wall Jump) ---
	if direction_x_input != 0:
		velocity.x = direction_x_input * SPEED
		if sprite_node:
			sprite_node.flip_h = direction_x_input < 0 # Voltear sprite según la dirección horizontal
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * _delta * 5) # Deceleración suave

	# --- Lógica de Animaciones (Prioridad) ---
	var anim_to_play = "quieta" # Animación por defecto si no se cumplen otras condiciones

	if is_on_floor():
		if direction_x_input != 0:
			anim_to_play = "correr"
		else:
			anim_to_play = "quieta"
	else: # En el aire
		if is_wall_sliding:
			anim_to_play = "deslizar"
		elif velocity.y < 0: # Subiendo
			anim_to_play = "saltar" 
		else: # velocity.y >= 0 (cayendo, incluyendo el deslizamiento de pared que tiene un límite)
			anim_to_play = "caer" # Animación de caer (si no tienes una, usa "saltar")

	if animationPlayer and animationPlayer.current_animation != anim_to_play:
		animationPlayer.play(anim_to_play)
		
	# --- Mover y Colisionar ---
	move_and_slide()
