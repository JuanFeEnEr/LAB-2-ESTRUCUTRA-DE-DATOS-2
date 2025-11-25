# Node.gd
extends Node2D

@export var node_id : String = ""
signal node_clicked(id)

@onready var icon = $Icon
@onready var label = $IdLabel

func _ready():
	label.text = node_id
	$Area2D.connect("input_event", Callable(self, "_on_area_input_event"))
	# asegurar que el nodo esté por encima de las aristas
	z_index = 10

func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("node_clicked", node_id)

# opcional: efectos visuales
func highlight(enable: bool):
	# por ejemplo cambiar modulate o escala
	if enable:
		icon.scale = Vector2(1.12, 1.12)
	else:
		icon.scale = Vector2(1, 1)
