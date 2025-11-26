extends CharacterBody3D

# --- CONFIGURACIÓN ---
@export_group("Estadísticas")
@export var max_lives: int = 3
@export var move_speed: float = 10.0
@export var vertical_speed: float = 6.0
@export var mouse_sensitivity: float = 0.15

@export_group("Interacción")
@export var interact_distance: float = 40.0       # Distancia edificios
@export var virus_interact_distance: float = 8.0  # Distancia virus

@export_group("Referencias UI")
@export var life_label: Label  # <--- ¡NO OLVIDES ARRASTRAR EL LABEL AQUÍ!

# --- VARIABLES ---
var current_lives: int = 3
var _mouse_captured: bool = true
var _yaw: float = 0.0
var _pitch: float = 0.0

var current_target = null              
var current_virus = null 
var was_interact_pressed: bool = false  

# Variable clave: Guarda el nodo del que traemos el cable
var cable_source_node = null 

@onready var cam: Camera3D = null
@onready var ui_hint: Label = null

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam = get_node_or_null("Camera3D")
	if cam == null: cam = _find_camera_recursive(self)
	ui_hint = get_tree().get_first_node_in_group("hint_label")
	
	_yaw = rotation.y
	if cam: _pitch = cam.rotation.x
	
	current_lives = max_lives
	_update_life_ui()

func _unhandled_input(event):
	if event is InputEventMouseMotion and _mouse_captured:
		_yaw -= event.relative.x * mouse_sensitivity * 0.01
		_pitch -= event.relative.y * mouse_sensitivity * 0.01
		_pitch = clamp(_pitch, deg_to_rad(-60.0), deg_to_rad(60.0))
		rotation.y = _yaw
		if cam: cam.rotation.x = _pitch

	# Clic Derecho para soltar cable
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_cable()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not _mouse_captured:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				_mouse_captured = true

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_mouse_captured = not _mouse_captured
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if _mouse_captured else Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_F:
			if current_virus: _start_hacking(current_virus)

func _physics_process(delta):
	# Movimiento
	var input_dir = Vector3.ZERO
	var forward = 0.0
	var right = 0.0
	if Input.is_key_pressed(KEY_D): forward += 1.0
	if Input.is_key_pressed(KEY_A): forward -= 1.0
	if Input.is_key_pressed(KEY_S): right += 1.0
	if Input.is_key_pressed(KEY_W): right -= 1.0
	var up = 0.0
	if Input.is_key_pressed(KEY_SPACE): up += 1.0
	if Input.is_key_pressed(KEY_CTRL): up -= 1.0

	input_dir += -transform.basis.z * forward
	input_dir += transform.basis.x * right
	var vel = Vector3.ZERO
	if input_dir.length() > 0.001: vel += input_dir.normalized() * move_speed
	vel.y = up * vertical_speed
	velocity = vel
	move_and_slide()

	_update_target_and_ui()
	_update_dynamic_cable()

	# Tecla E para interactuar (Agarrar o Soltar cable)
	if Input.is_key_pressed(KEY_E) and not was_interact_pressed:
		_handle_interaction()
	was_interact_pressed = Input.is_key_pressed(KEY_E)

# --- MECÁNICA PICK UP / DROP ---
func _handle_interaction():
	if current_target == null: return
	
	if cable_source_node == null:
		# 1. No tengo cable -> Lo tomo
		cable_source_node = current_target
		print("Cable tomado del Nodo ", cable_source_node.node_id)
	else:
		# 2. Tengo cable -> Intento conectar
		if cable_source_node == current_target:
			# Si es el mismo nodo, no hacemos nada
			return
			
		var gm = get_tree().get_first_node_in_group("graph_manager")
		if gm:
			var success = gm.try_create_connection(cable_source_node, current_target)
			if success:
				# Conexión exitosa, soltamos el cable
				cable_source_node = null
				_clear_dynamic_cable()

func _cancel_cable():
	if cable_source_node != null:
		print("Cable cancelado/soltado.")
		cable_source_node = null
		_clear_dynamic_cable()

# --- UI Y OBJETIVOS ---
func _update_target_and_ui() -> void:
	current_target = null
	current_virus = null
	
	# Buscar Edificios
	var best_dist = interact_distance
	var buildings = get_tree().get_nodes_in_group("building")
	for b in buildings:
		if not (b is Area3D): continue
		var pos = b.get_connection_point() if b.has_method("get_connection_point") else b.global_position
		var d = global_position.distance_to(pos)
		if d <= interact_distance and d < best_dist:
			best_dist = d
			current_target = b

	# Buscar Virus
	var viruses = get_tree().get_nodes_in_group("virus")
	var best_virus_dist = virus_interact_distance 
	for v in viruses:
		var d = global_position.distance_to(v.global_position)
		if d < best_virus_dist:
			best_virus_dist = d
			current_virus = v
	
	if ui_hint:
		ui_hint.visible = true
		if current_virus:
			ui_hint.text = "¡VIRUS! [F] HACKEAR"
			ui_hint.modulate = Color(1, 0, 0)
		elif current_target:
			ui_hint.modulate = Color(1, 1, 1)
			if cable_source_node == null:
				ui_hint.text = "Nodo %d - [E] TOMAR CABLE" % current_target.node_id
			else:
				if cable_source_node == current_target:
					ui_hint.text = "Nodo %d (Origen)" % current_target.node_id
				else:
					ui_hint.text = "Conectar con Nodo %d - [E] FIJAR" % current_target.node_id
		else:
			# Si llevas un cable pero no miras a un nodo
			if cable_source_node != null:
				ui_hint.text = "Llevando cable... ([Clic Der] Cancelar)"
				ui_hint.modulate = Color(1, 1, 0)
			else:
				ui_hint.visible = false

func _update_dynamic_cable() -> void:
	var drawer = get_tree().get_first_node_in_group("line_drawer")
	if not drawer: return

	if cable_source_node != null:
		# Dibuja línea desde el origen hasta el Dron
		var from = cable_source_node.get_connection_point()
		drawer.update_dynamic_cable(from, global_position)
	else:
		_clear_dynamic_cable()

func _clear_dynamic_cable():
	var drawer = get_tree().get_first_node_in_group("line_drawer")
	if drawer and drawer.has_method("clear_dynamic_cable"):
		drawer.clear_dynamic_cable()

# --- DAÑO ---
func take_damage(amount: int):
	current_lives -= amount
	_update_life_ui()
	if current_lives <= 0:
		print("GAME OVER")
		get_tree().reload_current_scene()

func _update_life_ui():
	if life_label:
		var hearts = "❤️".repeat(current_lives)
		life_label.text = "VIDAS: " + hearts

func _start_hacking(virus_node):
	var quiz_ui = get_tree().get_first_node_in_group("quiz_ui")
	if quiz_ui:
		quiz_ui.start_quiz(virus_node)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_mouse_captured = false

func _find_camera_recursive(node):
	for child in node.get_children():
		if child is Camera3D: return child
		var found = _find_camera_recursive(child)
		if found: return found
	return null
