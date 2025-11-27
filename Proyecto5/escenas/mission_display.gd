extends Label

func _ready():
	# --- 1. CONFIGURACIÓN VISUAL AUTOMÁTICA ---
	# Creamos una configuración de estilo por código para asegurar que se vea BIEN.
	var settings = LabelSettings.new()
	
	# Tamaño grande para que se lea fácil
	settings.font_size = 28 
	
	# Color llamativo (Cyan Cyberpunk)
	settings.font_color = Color(0.2, 1.0, 1.0) 
	
	# Borde Negro Grueso (Clave para que se lea sobre cualquier fondo)
	settings.outline_size = 8
	settings.outline_color = Color.BLACK
	
	# Sombra para profundidad
	settings.shadow_size = 4
	settings.shadow_color = Color(0, 0, 0, 0.5)
	settings.shadow_offset = Vector2(2, 2)
	
	# Aplicamos la configuración
	label_settings = settings
	
	# Aseguramos que no estorbe al ratón
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# --- 2. FUNCIÓN PARA CAMBIAR TEXTO CON ESTILO ---
# En lugar de usar 'text = ...' en el main_game, puedes usar esta función
# para que haga una animación bonita.
func set_mission_text(new_text: String):
	# Si el texto es el mismo, no hacemos nada
	if text == new_text: return
	
	# 1. Animación de salida (Desaparece rápido)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	await t.finished
	
	# 2. Cambiamos el texto
	text = new_text
	
	# 3. Sonido de "Misión Actualizada" (Si tienes SFX)
	# $AudioStreamPlayer.play() 
	
	# 4. Animación de entrada (Aparece con un flash)
	modulate = Color(2, 2, 2, 0) # Blanco brillante transparente
	t = create_tween()
	t.set_parallel(true)
	t.tween_property(self, "modulate", Color.WHITE, 0.3) # Vuelve a color normal
	t.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1) # Se agranda un poco
	t.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1) # Vuelve a tamaño normal
