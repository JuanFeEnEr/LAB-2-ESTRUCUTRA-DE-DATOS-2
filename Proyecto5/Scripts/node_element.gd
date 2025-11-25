extends Area2D

signal node_clicked(node_ref)

var id: int = 0
var is_infected: bool = false 

@onready var sprite = $Sprite2D
@onready var label = $Label

# --- NUEVO: Esta función se ejecuta sola cuando el nodo ya existe seguro ---
func _ready():
	# Aquí 'label' ya existe, así que no dará error
	label.text = str(id)

func setup(new_id: int, pos: Vector2):
	id = new_id
	position = pos
	# label.text = str(id)  <--- BORRAMOS ESTA LÍNEA DE AQUÍ (causaba el error)
	modulate = Color.WHITE 

# ... El resto del script déjalo igual ...
func set_infected():
	is_infected = true
	modulate = Color(1, 0, 0) 

func set_visited():
	modulate = Color(0, 1, 0)

func set_highlight():
	modulate = Color(0, 0.5, 1)

func reset_visual():
	if is_infected:
		modulate = Color(1, 0, 0)
	else:
		modulate = Color.WHITE

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("node_clicked", self)
