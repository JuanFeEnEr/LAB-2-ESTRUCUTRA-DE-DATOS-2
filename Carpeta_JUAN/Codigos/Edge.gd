extends Line2D

@export var from_id: String
@export var to_id: String
@export var capacity: int = 1

var arrow_size := 18.0
var arrow_angle := 25.0 # grados

func _ready():
	width = 4
	default_color = Color.WHITE

func update_points(from_pos: Vector2, to_pos: Vector2):
	points = [from_pos, to_pos]
	queue_redraw()  # <- esto reemplaza "update()"

func highlight(active: bool):
	default_color = Color.YELLOW if active else Color.WHITE
	width = 6 if active else 4
	queue_redraw()

# ------------------------------
# DIBUJAR FLECHA AL FINAL DE LA LÍNEA
# ------------------------------
func _draw():
	if points.size() < 2:
		return

	var p1 = points[points.size() - 2]
	var p2 = points[points.size() - 1]

	# vector de la línea
	var dir = (p2 - p1).normalized()

	# crear los dos lados de la flecha
	var left = dir.rotated(deg_to_rad(180 - arrow_angle)) * arrow_size
	var right = dir.rotated(deg_to_rad(180 + arrow_angle)) * arrow_size

	# dibujar las líneas
	draw_line(p2, p2 + left, default_color, width)
	draw_line(p2, p2 + right, default_color, width)
