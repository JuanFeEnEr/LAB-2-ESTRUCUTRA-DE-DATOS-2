extends Area2D

# --- CONFIGURACIÓN DE ESCENAS ---
const HACK_SCENE = preload("res://Carpeta_MARI/Escenas/Contrasena.tscn")

# --- VARIABLES EXPORTADAS ---
@export var nombre_sala_manual: String = ""

@export_group("Dificultad del Hack")
@export var hack_code_length: int = 4 # Longitud del código
@export var hack_max_attempts: int = 10 # Intentos máximos

# --- VARIABLES INTERNAS ---
var key_item_name: String = ""
var is_hack_active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	configurar_llave()

func configurar_llave() -> void:
	var nombre_contenedor = nombre_sala_manual if nombre_sala_manual != "" else get_parent().name
	var algoritmo = Global.get("algoritmo_seleccionado") if Global.get("algoritmo_seleccionado") != null else "BFS"
	
	key_item_name = obtener_nombre_llave(nombre_contenedor, algoritmo)
	
	# Verificar si ya fue recogida
	if Global.get("key_founded") != null and key_item_name in Global.key_founded:
		queue_free()
		return
	
	if key_item_name == "":
		queue_free()
	else:
		print("Llave configurada: %s (Dificultad: %d digitos)" % [key_item_name, hack_code_length])

func obtener_nombre_llave(sala: String, tipo: String) -> String:
	match sala:
		"SalaA": return "Llave B"
		"SalaB": return "Llave C"
		"SalaC": return "Llave D" if tipo == "BFS" else "Llave E"
		"SalaD": return "Llave E" if tipo == "BFS" else "Llave F"
		"SalaE": return "Llave D" if tipo == "DFS" else "Llave F"
		_: return ""

# --- DETECCIÓN DE COLISIÓN ---
func _on_body_entered(body: Node2D) -> void:
	if not (body.name == "Player" or body.is_in_group("Player")):
		return
	
	if is_hack_active:
		return
	
	print("Activando minijuego para: %s" % key_item_name)
	is_hack_active = true
	
	# Desactivar colisión de forma segura (física)
	var collision = get_node_or_null("CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)
	
	visible = false
	
	# Guardar referencias
	Global.key_to_collect = self
	Global.player_reference = body
	
	# Iniciar minijuego
	call_deferred("_open_scene_additive")

# --- ABRIR MINIJUEGO ---
func _open_scene_additive() -> void:
	if not HACK_SCENE.can_instantiate():
		push_error("ERROR: No se encuentra escena Contrasena.tscn")
		_restore_state()
		return
	
	var minigame_instance = HACK_SCENE.instantiate()
	
	# Configurar dificultad
	if minigame_instance.has_method("configure_difficulty"):
		minigame_instance.configure_difficulty(hack_code_length, hack_max_attempts)
	
	# Configurar para que funcione durante la pausa
	minigame_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# --- SOLUCIÓN AL PROBLEMA DE CÁMARA ---
	# Creamos un CanvasLayer temporal. Esto fuerza al UI a estar frente a la cámara
	# sin importar dónde esté el jugador en el mundo.
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 100 # Un número alto para asegurar que esté encima de todo
	ui_layer.name = "HackLayerTemp"
	
	# Añadimos el Layer a la raíz
	get_tree().root.add_child(ui_layer)
	
	# Añadimos el minijuego DENTRO del Layer
	ui_layer.add_child(minigame_instance)
	
	# TRUCO DE LIMPIEZA:
	# Cuando el minijuego se elimine (queue_free), le decimos al Layer que también se elimine.
	minigame_instance.tree_exited.connect(func(): ui_layer.queue_free())
	# ---------------------------------------
	
	# Pausar juego principal
	get_tree().paused = true
# --- RESULTADO DEL HACK ---
func on_hack_finished(success: bool, player_body: Node2D) -> void:
	# Asegurar que el juego está despausado
	get_tree().paused = false
	
	# Limpiar referencias globales
	Global.key_to_collect = null
	Global.player_reference = null
	
	if success:
		_handle_success(player_body)
	else:
		_handle_failure()

func _handle_success(player_body: Node2D) -> void:
	print("¡Hack exitoso! Llave obtenida.")
	
	if is_instance_valid(player_body) and player_body.has_method("set_held_item"):
		player_body.set_held_item(key_item_name)
	
	if Global.has_method("add_key"):
		Global.add_key(key_item_name)
		
	queue_free()

func _handle_failure() -> void:
	print("Hack fallido. Reintentar.")
	_restore_state()

func _restore_state() -> void:
	is_hack_active = false
	visible = true
	
	# Seguridad extra para despausar
	if get_tree().paused:
		get_tree().paused = false
	
	# --- CORRECCIÓN FÍSICA ---
	# NUNCA usar .disabled = false directamente en medio de lógica
	var collision = get_node_or_null("CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", false)
