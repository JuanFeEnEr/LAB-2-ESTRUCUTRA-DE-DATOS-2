extends Area3D

@export var speed: float = 15.0

func _ready():
	# Destruir tras 5 segundos para no llenar memoria
	await get_tree().create_timer(5.0).timeout
	queue_free()
	
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Mover hacia adelante (eje Z local negativo)
	position += -transform.basis.z * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("¡EL JUGADOR RECIBIÓ DAÑO DE ÁCIDO!")
		# Aquí llamarías a una función body.take_damage() si la tienes
		queue_free()
	elif not body.is_in_group("virus"):
		queue_free() # Choca contra pared o suelo
