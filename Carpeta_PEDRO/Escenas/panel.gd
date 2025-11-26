extends Panel

# Usamos @onready para que busque los nodos automáticamente
# ASEGÚRATE DE QUE TUS NODOS SE LLAMEN ASÍ EN LA ESCENA:
@onready var question_label = $LabelPregunta
@onready var btn_option_0 = $BotonOpcion1
@onready var btn_option_1 = $BotonOpcion2
@onready var btn_option_2 = $BotonOpcion3

var current_virus_node = null
var current_correct_index = -1

func _ready():
	add_to_group("quiz_ui")
	visible = false
	
	# Verificación de seguridad para evitar el crash si falta un botón
	if not btn_option_0 or not btn_option_1 or not btn_option_2:
		push_error("¡ERROR! Faltan botones en la escena o tienen nombres incorrectos.")
		return

	# Conectar señales usando Callable
	btn_option_0.pressed.connect(_on_btn_0_pressed)
	btn_option_1.pressed.connect(_on_btn_1_pressed)
	btn_option_2.pressed.connect(_on_btn_2_pressed)

# Funciones puente para conectar las señales limpiamente
func _on_btn_0_pressed(): _check_answer(0)
func _on_btn_1_pressed(): _check_answer(1)
func _on_btn_2_pressed(): _check_answer(2)

func start_quiz(virus):
	current_virus_node = virus
	var gm = get_tree().get_first_node_in_group("graph_manager")
	
	if not gm:
		print("Error: No se encontró el GraphManager")
		return
	
	# Obtenemos la pregunta
	var data = gm.get_random_question()
	
	# Asignamos textos
	question_label.text = data["q"]
	btn_option_0.text = data["options"][0]
	btn_option_1.text = data["options"][1]
	btn_option_2.text = data["options"][2]
	
	current_correct_index = data["correct"]
	
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Liberar mouse para clicar

func _check_answer(idx):
	if idx == current_correct_index:
		print("¡Correcto! Virus eliminado.")
		if is_instance_valid(current_virus_node):
			current_virus_node.die()
	else:
		print("Incorrecto. Intenta de nuevo o huye.")
	
	_close_quiz()

func _close_quiz():
	visible = false
	current_virus_node = null
	# Devolver el control al juego (capturar mouse)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
