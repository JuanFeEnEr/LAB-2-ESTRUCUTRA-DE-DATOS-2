extends Panel

# --- SCRIPT DEL QUIZ (PREGUNTAS) ---

@onready var question_label = $LabelPregunta
@onready var btn_option_0 = $BotonOpcion1
@onready var btn_option_1 = $BotonOpcion2
@onready var btn_option_2 = $BotonOpcion3

var current_virus_node = null
var current_correct_index = -1

func _ready():
	# Aseguramos que esté en el grupo correcto
	if not is_in_group("quiz_ui"): add_to_group("quiz_ui")
	visible = false
	
	# Verificamos nodos
	if not (question_label and btn_option_0 and btn_option_1 and btn_option_2):
		print("ERROR: Faltan nodos en el Panel de Quiz.")
		return

	btn_option_0.pressed.connect(func(): _check_answer(0))
	btn_option_1.pressed.connect(func(): _check_answer(1))
	btn_option_2.pressed.connect(func(): _check_answer(2))
	
	_aplicar_diseno()

func start_quiz(virus):
	print("INICIANDO QUIZ...")
	current_virus_node = virus
	
	var gm = get_tree().get_first_node_in_group("graph_manager")
	if not gm:
		print("ERROR: No encuentro al 'graph_manager'.")
		return
	
	var data = gm.get_random_question()
	question_label.text = data["q"]
	btn_option_0.text = data["options"][0]
	btn_option_1.text = data["options"][1]
	btn_option_2.text = data["options"][2]
	current_correct_index = data["correct"]
	
	visible = true
	move_to_front()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _check_answer(idx):
	if idx == current_correct_index:
		if is_instance_valid(current_virus_node):
			current_virus_node.die()
	_close_quiz()

func _close_quiz():
	visible = false
	current_virus_node = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _aplicar_diseno():
	set_anchors_preset(Control.PRESET_CENTER)
	size = Vector2(400, 350)
	question_label.position = Vector2(20, 20)
	question_label.size = Vector2(360, 90)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var btn_x = 50; var btn_w = 300; var btn_h = 50; var espacio = 10
	btn_option_0.position = Vector2(btn_x, 130)
	btn_option_0.size = Vector2(btn_w, btn_h)
	btn_option_1.position = Vector2(btn_x, 130 + btn_h + espacio)
	btn_option_1.size = Vector2(btn_w, btn_h)
	btn_option_2.position = Vector2(btn_x, 130 + (btn_h + espacio) * 2)
	btn_option_2.size = Vector2(btn_w, btn_h)
