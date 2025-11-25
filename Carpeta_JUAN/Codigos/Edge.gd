extends Line2D

@export var from_id: String
@export var to_id: String
@export var capacity: int = 1

func _ready():
	width = 4
	default_color = Color.WHITE


func update_points(from_pos: Vector2, to_pos: Vector2):
	points = [from_pos, to_pos]


func highlight(active: bool):
	default_color = Color.YELLOW if active else Color.WHITE
	width = 6 if active else 4
