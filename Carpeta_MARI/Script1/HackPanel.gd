extends Control

# --- CONFIGURACIÓN EN EL INSPECTOR ---
@export_group("Nodos UI")
@export var display_label: Label
@export var history_container: VBoxContainer
@export var keypad_grid: GridContainer

@export_group("Juego por Defecto")
@export var code_length: int = 4
@export var max_attempts: int = 10

# --- COLORES DE RETROALIMENTACIÓN ---
const COLOR_CORRECT = Color("33ff33") # Verde
const COLOR_PARTIAL = Color("ffff33") # Amarillo
const COLOR_WRONG = Color("cc3333")   # Rojo
const COLOR_DEFAULT = Color("33ff33")

# --- VARIABLES INTERNAS ---
var secret_code: String = ""
var current_input: String = ""
var current_attempts: int = 0
var is_locked: bool = false

const KEYPAD_MAP = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]

func _ready():
	# CRÍTICO: Configurar para que funcione mientras el juego está pausado
	_configure_pause_mode()
	
	# Configurar señales de botones
	_setup_keypad_signals()
	
	# RESPALDO: Si configure_difficulty no se llama en 0.2 segundos, usa valores por defecto
	get_tree().create_timer(0.2).timeout.connect(_check_if_configured)
	
	print("DEBUG: HackPanel listo. Esperando configuración...")

# Función de respaldo por si se prueba la escena sola
func _check_if_configured():
	if secret_code == "":
		print("DEBUG: Iniciando con valores por defecto (No se recibió config externa)")
		start_game()

# --- NUEVA FUNCIÓN: Configurar dificultad desde la llave ---
func configure_difficulty(length: int, max_att: int):
	print("DEBUG: Recibiendo configuración - Longitud: %d, Intentos: %d" % [length, max_att])
	
	# Actualizar parámetros (con validación mínima)
	code_length = length if length > 0 else 4
	max_attempts = max_att if max_att > 0 else 10
	
	# Iniciar el juego inmediatamente con los nuevos datos
	start_game()

func start_game():
	secret_code = _generate_random_code()
	
	# Reiniciar estado
	current_input = ""
	current_attempts = 0
	is_locked = false
	
	if is_instance_valid(display_label):
		display_label.add_theme_color_override("font_color", COLOR_DEFAULT)
	
	# Limpiar historial previo
	if is_instance_valid(history_container):
		for child in history_container.get_children():
			child.queue_free()
		
	_update_display()
	print("DEBUG: Juego iniciado. Código secreto: %s" % secret_code)

func _generate_random_code() -> String:
	var code = ""
	for i in range(code_length):
		code += str(randi_range(0, 9))
	return code

# --- CONFIGURACIÓN DE PAUSA ---
func _configure_pause_mode():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_children_process_mode(self)

func _set_children_process_mode(node: Node):
	for child in node.get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS
		_set_children_process_mode(child)

# --- BOTONES E INTERFAZ ---
func _setup_keypad_signals():
	if not is_instance_valid(keypad_grid): return
	
	var buttons = keypad_grid.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not (btn is Button or btn is TextureButton): continue
			
		var action = ""
		if i < KEYPAD_MAP.size(): action = KEYPAD_MAP[i]
		elif btn is Button: action = btn.text.to_upper()
		
		if action.is_valid_int():
			btn.pressed.connect(_on_number_pressed.bind(action))
		elif "C" in action or "CLEAR" in action:
			btn.pressed.connect(_on_clear_pressed)
		elif "OK" in action or "ENTER" in action:
			btn.pressed.connect(_on_enter_pressed)

func _update_display():
	if not is_instance_valid(display_label): return
	
	var text_show = ""
	for i in range(current_input.length()):
		text_show += current_input[i] + "    "
	
	var remaining = code_length - current_input.length()
	for i in range(remaining):
		text_show += "_    "
	
	display_label.text = text_show.strip_edges()

# --- INPUTS ---
func _on_number_pressed(num_str: String):
	if is_locked: return
	if current_input.length() < code_length:
		current_input += num_str
		_update_display()

func _on_clear_pressed():
	if is_locked: return
	if current_input.length() > 0:
		current_input = current_input.left(current_input.length() - 1)
		_update_display()

func _on_enter_pressed():
	if is_locked: return
	if current_input.length() != code_length:
		_anim_shake_display()
		return
	
	current_attempts += 1
	_process_attempt()

# --- LÓGICA MASTERMIND ---
func _process_attempt():
	var feedback = _calculate_feedback(current_input, secret_code)
	_add_history_entry(current_input, feedback)
	
	if current_input == secret_code:
		_handle_win()
	elif current_attempts >= max_attempts:
		_handle_loss()
	else:
		current_input = ""
		_update_display()

func _calculate_feedback(guess: String, secret: String) -> Array:
	var result = []
	result.resize(code_length)
	result.fill(COLOR_WRONG)
	
	var s_used = []
	s_used.resize(code_length)
	s_used.fill(false)
	var g_used = []
	g_used.resize(code_length)
	g_used.fill(false)
	
	# Fase 1: Verde (Posición exacta)
	for i in range(code_length):
		if guess[i] == secret[i]:
			result[i] = COLOR_CORRECT
			s_used[i] = true
			g_used[i] = true
			
	# Fase 2: Amarillo (Número existe, posición incorrecta)
	for i in range(code_length):
		if not g_used[i]:	
			for j in range(code_length):
				if not s_used[j] and guess[i] == secret[j]:
					result[i] = COLOR_PARTIAL
					s_used[j] = true
					break
	return result

func _add_history_entry(code_str: String, colors: Array):
	if not is_instance_valid(history_container): return

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var attempt_lbl = Label.new()
	attempt_lbl.text = "#%d " % current_attempts
	attempt_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	row.add_child(attempt_lbl)
	
	for i in range(code_length):
		var num_lbl = Label.new()
		num_lbl.text = code_str[i] + " "
		num_lbl.add_theme_color_override("font_color", colors[i])
		row.add_child(num_lbl)
	
	history_container.add_child(row)
	history_container.move_child(row, 0)

# --- FINALIZACIÓN ---
func _handle_win():
	is_locked = true
	display_label.text = "ACCESO OK"
	display_label.add_theme_color_override("font_color", COLOR_CORRECT)
	await get_tree().create_timer(1.5).timeout
	_notify_key_and_return(true)

func _handle_loss():
	is_locked = true
	display_label.text = "BLOQUEADO"
	display_label.add_theme_color_override("font_color", COLOR_WRONG)
	await get_tree().create_timer(1.5).timeout
	_notify_key_and_return(false)

func _notify_key_and_return(success: bool):
	# 1. Notificar a la llave
	if Global.get("key_to_collect") and is_instance_valid(Global.key_to_collect):
		Global.key_to_collect.on_hack_finished(success, Global.player_reference)
	
	# 2. Despausar
	get_tree().paused = false
	
	# 3. Limpiar referencias globales y cerrarse
	Global.key_to_collect = null
	Global.player_reference = null
	
	await get_tree().process_frame
	queue_free()

func _anim_shake_display():
	var tween = create_tween()
	var original_pos = display_label.position
	for i in range(4):
		var offset = Vector2(randf_range(-4, 4), 0)
		tween.tween_property(display_label, "position", original_pos + offset, 0.05)
	tween.tween_property(display_label, "position", original_pos, 0.05)
