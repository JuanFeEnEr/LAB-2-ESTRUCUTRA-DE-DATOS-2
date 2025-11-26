extends Panel

# Variable para conectar el texto de aviso
@export var label_aviso: Label

func _ready():
	# 1. Al iniciar, ocultamos el Panel (y por ende la imagen)
	self.visible = false
	
	# 2. Mostramos el aviso
	if label_aviso:
		label_aviso.text = "Presiona 'M' para ver el Mapa"
		label_aviso.visible = true

func _input(event):
	# Detectar tecla M
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		
		# Alternar visibilidad del Panel (Mapa)
		self.visible = not self.visible
		
		# Lógica del aviso:
		if label_aviso:
			# Si el mapa está visible, ocultamos el aviso.
			# Si el mapa está oculto, mostramos el aviso.
			label_aviso.visible = not self.visible
