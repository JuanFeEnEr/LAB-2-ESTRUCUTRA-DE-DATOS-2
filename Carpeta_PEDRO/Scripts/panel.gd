extends Panel

# --- SCRIPT DEL MAPA (TECLA M) ---

func _ready():
	visible = false

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		visible = not visible
		
		# Manejo del mouse
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			move_to_front() # Que se vea encima de todo
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
