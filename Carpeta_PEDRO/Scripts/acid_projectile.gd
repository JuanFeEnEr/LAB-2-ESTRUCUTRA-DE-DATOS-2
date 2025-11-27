extends Area3D

@export var speed: float = 15.0
@export var damage: int = 1

func _ready():
	# 1. Forzar que monitoree choques
	monitoring = true
	monitorable = true
	
	# 2. Forzar que busque en la Capa 1 (donde está el jugador)
	collision_mask = 1 
	collision_layer = 1
	
	# 3. Conectar señal
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	# 4. Autodestrucción
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()

func _process(delta):
	# Mover hacia adelante
	position += -transform.basis.z * speed * delta

func _on_body_entered(body):
	# --- DIAGNÓSTICO: ¿QUÉ TOQUÉ? ---
	print("--- IMPACTO ---")
	print("Toqué un objeto llamado: ", body.name)
	
	# Verificar si es el jugador
	if body.is_in_group("player"):
		print("¡ES EL JUGADOR! Intentando hacer daño...")
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Función take_damage llamada.")
		else:
			print("ERROR: El jugador no tiene la función 'take_damage'. Revisa su script.")
		queue_free()
	
	# Si choca con el escenario (pero no enemigos)
	elif not body.is_in_group("virus"):
		print("Chocó contra pared/suelo. Destruyendo proyectil.")
		queue_free()
