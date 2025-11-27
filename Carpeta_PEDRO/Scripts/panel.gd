extends Panel

# Si tienes un Label de aviso ("Presiona M"), arrástralo aquí. 
# Si no, déjalo vacío, no dará error.
@export var aviso_label: Label 

func _ready():
	# Empezar oculto
	visible = false
	
	if aviso_label:
		aviso_label.visible = true
		aviso_label.text = "Presiona 'M' para ver el Mapa"

func _input(event):
	# Detectar la tecla M
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		_toggle_map()

func _toggle_map():
	# Invertir visibilidad
	visible = not visible
	
	# GESTIÓN DEL MOUSE (Vital para que puedas mover el cursor en el mapa)
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if aviso_label: aviso_label.visible = false
	else:
		# Al cerrar, devolvemos el control al juego
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if aviso_label: aviso_label.visible = true
