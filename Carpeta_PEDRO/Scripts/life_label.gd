extends Label

func _ready():
	# 1. Aseguramos que esté en el grupo correcto para que el jugador lo encuentre
	add_to_group("life_label")
	
	# --- ESTILO DEL TEXTO (LabelSettings) ---
	var settings = LabelSettings.new()
	settings.font_size = 32                  # Letra grande
	settings.font_color = Color(1, 1, 1)     # Blanco puro
	settings.outline_size = 4                # Borde negro para lectura
	settings.outline_color = Color(0, 0, 0)
	settings.shadow_size = 4                 # Sombra suave
	settings.shadow_color = Color(0, 0, 0, 0.5)
	settings.shadow_offset = Vector2(2, 2)
	
	self.label_settings = settings
	
	# --- ESTILO DEL FONDO (StyleBox) ---
	# Creamos una "caja" de fondo por código
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.6) # Negro semitransparente
	style.set_corner_radius_all(10)            # Bordes redondeados
	style.content_margin_left = 20             # Espacio interno (padding)
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	
	add_theme_stylebox_override("normal", style)
	
	# --- POSICIÓN EN PANTALLA ---
	# Lo anclamos arriba a la izquierda con un margen
	# Desactivamos los anclajes automáticos para moverlo manualmente
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Margen de separación del borde de la pantalla
	position = Vector2(20, 20)
	
	# Alineación del texto
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Texto inicial de prueba (se sobrescribirá rápido, pero sirve para ver)
	text = "VIDAS: ❤️❤️❤️"
