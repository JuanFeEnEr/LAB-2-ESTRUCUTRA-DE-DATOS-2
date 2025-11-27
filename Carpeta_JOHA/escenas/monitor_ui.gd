extends Control

@onready var imagen_ganadora = $FondoEncendido
# Ya no necesitamos referenciar el PanelVictoria del editor, ¡lo crearemos nosotros!

var camino_desbloqueado = false

func _ready():
	add_to_group("ui_monitor")
	
	# Aseguramos que la foto verde empiece oculta
	if imagen_ganadora: 
		imagen_ganadora.visible = false

# Esta función la llama el Fantasma 4 al morir
func mostrar_mapa_completo():
	print("UI: Camino desbloqueado. Mostrando grafo verde.")
	camino_desbloqueado = true
	if imagen_ganadora:
		imagen_ganadora.visible = true

# Esta función la llama la Meta Final (Area2D de salida)
func mostrar_mensaje_final():
	if camino_desbloqueado:
		print("UI: Generando mensaje de victoria...")
		crear_ventana_victoria() # <--- Llamamos a nuestra función constructora
	else:
		print("UI: Llegaste a la meta, pero falta la clave.")

# --- AQUÍ ESTÁ LA MAGIA DE PROGRAMAR LA UI ---
func crear_ventana_victoria():
	# 1. CREAR EL PANEL (FONDO)
	var panel = Panel.new()
	# Lo centramos en la pantalla
	panel.set_anchors_preset(Control.PRESET_CENTER)
	# Le damos un tamaño
	panel.custom_minimum_size = Vector2(400, 200)
	
	# 2. DARLE ESTILO (Borde verde y fondo negro transparente)
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.9) # Negro casi sólido
	estilo.border_width_left = 4
	estilo.border_width_top = 4
	estilo.border_width_right = 4
	estilo.border_width_bottom = 4
	estilo.border_color = Color(0, 1, 0) # Verde Hacker
	estilo.set_corner_radius_all(10) # Bordes redondeados
	panel.add_theme_stylebox_override("panel", estilo)
	
	# 3. CREAR EL TEXTO (LABEL)
	var etiqueta = Label.new()
	etiqueta.text = "¡NODO INFECTADO ENCONTRADO!\n\nProtocolo completado.\nAccediendo al siguiente nivel..."
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Hacemos que ocupe todo el panel para que se centre bien
	etiqueta.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 4. JUNTARLO TODO Y MOSTRARLO
	panel.add_child(etiqueta) # Metemos el texto en el panel
	add_child(panel) # Metemos el panel en la pantalla
	
	# Opcional: Pausar el juego para que celebren
	# get_tree().paused = true
