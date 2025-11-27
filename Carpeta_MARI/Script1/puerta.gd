extends Area2D

# --- CAMBIO IMPORTANTE ---
# Ahora es una LISTA. En el Inspector verás que puedes agregar
# "Element 0", "Element 1", etc. Escribe ahí todas las llaves válidas.
@export var llaves_posibles: Array[String] = []

@export var requires_key: bool = true

# Arrastra aquí el CollisionShape2D (hijo del StaticBody)
@export var pared_colision: CollisionShape2D 

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger_colision: CollisionShape2D = $CollisionShape2D

var esta_abierta: bool = false

func _ready() -> void:
	self.body_entered.connect(_on_area_2d_body_entered)
	
	if anim_sprite:
		anim_sprite.play("Cerrada")
		
	# Advertencia si se te olvidó configurar la puerta
	if requires_key and llaves_posibles.is_empty():
		print("ADVERTENCIA: La puerta en ", self.global_position, " requiere llave pero la lista está vacía.")

func interact(player_node: Node) -> void:
	if esta_abierta: return

	# 1. Obtener qué tiene el jugador
	var item_jugador = ""
	if player_node.has_method("get_held_item"):
		item_jugador = player_node.get_held_item()

	if requires_key:
		print("--- VALIDANDO ACCESO ---")
		print("La puerta acepta cualquiera de estas: ", llaves_posibles)
		print("El jugador tiene: '", item_jugador, "'")

		# 2. VALIDACIÓN: Comprobamos si el item del jugador está DENTRO de la lista
		if item_jugador in llaves_posibles:
			print("¡Coincidencia encontrada! Abriendo...")
			abrir_puerta(player_node)
		else:
			print("Acceso denegado. Ninguna llave coincide.")
	else:
		abrir_puerta(player_node)

func abrir_puerta(player_node) -> void:
	esta_abierta = true
	
	# Opcional: Consumir la llave
	if player_node.has_method("set_held_item"):
		player_node.set_held_item("")
		print("Llave consumida del inventario.")
	
	# Desactivar colisiones
	trigger_colision.set_deferred("disabled", true)
	if pared_colision:
		pared_colision.set_deferred("disabled", true)
	
	# Animación
	if anim_sprite:
		anim_sprite.play("Abrir")
		await get_tree().create_timer(1.0).timeout 
		anim_sprite.play("Abierta")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		interact(body)
