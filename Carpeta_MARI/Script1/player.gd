extends CharacterBody2D

# --- MOVIMIENTO ---
var speed := 200.0
var input_vector := Vector2.ZERO

# --- ANIMACIÓN ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- VARIABLES ---
var move_dir := Vector2.RIGHT
var held_item := ""
@onready var interaction_area: Area2D = get_node_or_null("InteractionArea")

# Para gestionar si el jugador puede interactuar con algo
var can_interact: bool = false
var current_interactable_object: Node = null # Guardará la referencia al objeto con el que puede interactuar


# -------------------------------------------------------------------------
# PROCESO LÓGICO GENERAL (Entrada, animación y interacción)
# -------------------------------------------------------------------------
func _process(delta: float) -> void:
	# Lógica de input para el movimiento
	input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
		# Lógica para la interacción
	if Input.is_action_just_pressed("interact"):
		print("¡Tecla de interacción presionada!")
		print("can_interact: ", can_interact)
		if current_interactable_object != null:
			print("Nombre del objeto interactuable actual: ", current_interactable_object.name)
		else:
			print("current_interactable_object es nulo.")
		
		if can_interact and current_interactable_object != null:
			if current_interactable_object.has_method("interact"):
				current_interactable_object.interact(self)
	update_animation() # Llama a la actualización de animación

	# Lógica para la interacción
	if Input.is_action_just_pressed("interact") and can_interact and current_interactable_object != null:
		if current_interactable_object.has_method("interact"):
			current_interactable_object.interact(self) # Pasa una referencia del jugador si es necesario


# -------------------------------------------------------------------------
# MOVIMIENTO Y FÍSICA
# -------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if input_vector.length() > 0:
		velocity = input_vector.normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


# -------------------------------------------------------------------------
# SISTEMA DE ANIMACIÓN — AnimatedSprite2D
# -------------------------------------------------------------------------
func update_animation():
	if animated_sprite == null:
		return

	# Si no hay movimiento → idle (elige la animación según la última dirección)
	if input_vector == Vector2.ZERO:
		_play_idle()
		return

	var current_animation := ""

	# Movimiento horizontal dominante
	if abs(input_vector.x) > abs(input_vector.y):
		if input_vector.x > 0:
			current_animation = "Caminar_der"
			move_dir = Vector2.RIGHT
		else:
			current_animation = "Caminar_izq"
			move_dir = Vector2.LEFT

	# Movimiento vertical dominante
	else:
		if input_vector.y > 0:
			current_animation = "Caminar_abajo"
			move_dir = Vector2.DOWN
		else:
			current_animation = "Caminar_arriba"
			move_dir = Vector2.UP

	# Reproducir si cambió
	if animated_sprite.animation != current_animation:
		animated_sprite.play(current_animation)


# -------------------------------------------------------------------------
# ANIMACIONES EN QUIETO
# -------------------------------------------------------------------------
func _play_idle():
	var idle_name := ""

	match move_dir:
		Vector2.UP:
			idle_name = "Idle_arriba"
		Vector2.DOWN:
			idle_name = "Idle_abajo"
		Vector2.LEFT:
			idle_name = "Idle_izq"
		Vector2.RIGHT:
			idle_name = "Idle_der"

	if animated_sprite.animation != idle_name:
		animated_sprite.play(idle_name)


# -------------------------------------------------------------------------
# MANEJO DE SEÑALES DEL AREA DE INTERACCIÓN DEL JUGADOR
# -------------------------------------------------------------------------
func _on_interaction_area_body_entered(body: Node2D) -> void:
	# Asegúrate de que solo se pueda interactuar con objetos que tengan el método "interact"
	if body.has_method("interact"):
		can_interact = true
		current_interactable_object = body
		print("Puedes interactuar con: ", body.name)
		# Opcional: Mostrar un indicador de interacción en la UI

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if current_interactable_object == body: # Asegúrate de que es el mismo objeto que se había detectado
		can_interact = false
		current_interactable_object = null
		print("Saliste del área de interacción con: ", body.name)
		# Opcional: Ocultar el indicador de interacción

# -------------------------------------------------------------------------
# MÉTODOS PARA MANEJAR ITEMS (Añadido para la llave)
# -------------------------------------------------------------------------
func set_held_item(item_name: String) -> void:
	held_item = item_name
	print("El jugador ahora tiene: ", held_item)
	# Aquí podrías añadir lógica para cambiar el sprite del jugador,
	# mostrar el item en la UI, etc.

func get_held_item() -> String:
	return held_item
