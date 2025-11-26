extends Panel

# Referencias a los nodos (usando los nombres de tu imagen)
@onready var question_label = $LabelPregunta
@onready var btn_option_0 = $BotonOpcion1
@onready var btn_option_1 = $BotonOpcion2
@onready var btn_option_2 = $BotonOpcion3

var current_virus_node = null
var current_correct_index = -1

func _ready():
	add_to_group("quiz_ui")
	visible = false
	
	# Verificar que existen los nodos
	if not (question_label and btn_option_0 and btn_option_1 and btn_option_2):
		print("ERROR: Faltan nodos en el Panel. Revisa los nombres.")
		return

	# Conectar botones
	btn_option_0.pressed.connect(func(): _check_answer(0))
	btn_option_1.pressed.connect(func(): _check_answer(1))
	btn_option_2.pressed.connect(func(): _check_answer(2))
	
	# --- APLICAR DISEÑO AUTOMÁTICO ---
	_aplicar_diseno()

func _aplicar_diseno():
	# 1. Configurar el PANEL principal
	# Lo centramos en la pantalla y le damos tamaño fijo
	set_anchors_preset(Control.PRESET_CENTER)
	size = Vector2(400, 350)
	
	# Opcional: Si quieres moverlo un poco para ajustar el centro exacto (offset)
	# position -= size / 2 

	# 2. Configurar el TEXTO DE LA PREGUNTA
	# Posición (x=20, y=20) | Ancho=360 (400-40 margen) | Alto=80
	question_label.position = Vector2(20, 20)
	question_label.size = Vector2(360, 90)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # Para que el texto baje si es largo

	# 3. Configurar los BOTONES (Lista vertical)
	# Margen izquierdo = 50, Ancho = 300, Alto = 50
	var btn_x = 50
	var btn_w = 300
	var btn_h = 50
	var espacio = 10 # Espacio entre botones
	
	# Botón 1 (Y = 130)
	btn_option_0.position = Vector2(btn_x, 130)
	btn_option_0.size = Vector2(btn_w, btn_h)
	
	# Botón 2 (Y = 130 + 50 + 10 = 190)
	btn_option_1.position = Vector2(btn_x, 130 + btn_h + espacio)
	btn_option_1.size = Vector2(btn_w, btn_h)
	
	# Botón 3 (Y = 190 + 50 + 10 = 250)
	btn_option_2.position = Vector2(btn_x, 130 + (btn_h + espacio) * 2)
	btn_option_2.size = Vector2(btn_w, btn_h)

func start_quiz(virus):
	print("ABRIENDO QUIZ...")
	current_virus_node = virus
	
	var gm = get_tree().get_first_node_in_group("graph_manager")
	if not gm: return
	
	var data = gm.get_random_question()
	
	question_label.text = data["q"]
	btn_option_0.text = data["options"][0]
	btn_option_1.text = data["options"][1]
	btn_option_2.text = data["options"][2]
	
	current_correct_index = data["correct"]
	
	visible = true
	# Aseguramos que el panel quede al frente de todo
	move_to_front()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _check_answer(idx):
	if idx == current_correct_index:
		print("¡CORRECTO!")
		if is_instance_valid(current_virus_node):
			current_virus_node.die()
	else:
		print("INCORRECTO")
	
	_close_quiz()

func _close_quiz():
	visible = false
	current_virus_node = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
