extends Control

# --- CONFIGURACIÓN DE RUTAS (Actualizadas con tus archivos) ---
const SCENE_MISION_1 = "res://Carpeta_MARI/Script1/Inicio del Juego.tscn"
const SCENE_MISION_2 = SCENE_MISION_1  # Temporalmente apunta a Misión 1, como pediste.
const SCENE_MISION_3 = "res://Carpeta_PEDRO/Escenas/control.tscn"
const SCENE_MISION_4 = "res://Carpeta_JUAN/Escenas/control_juan.tscn"
const SCENE_MISION_5 = "res://Proyecto5/escenas/inicio.tscn"

# --- REFERENCIAS A LOS BOTONES (Asegúrate que los nombres sean EXACTOS) ---
@onready var btn_1 = $BtnMision1
@onready var btn_2 = $BtnMision2
@onready var btn_3 = $BtnMision3
@onready var btn_4 = $BtnMision4
@onready var btn_5 = $BtnMision5 

# Referencia al texto de descripción
@onready var descripcion = $Panel/RichTextLabel 

func _ready():
	# 1. Animación de Entrada
	modulate.a = 0.0
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 1.0)
	
	# 2. Lista de botones
	var botones = [btn_1, btn_2, btn_3, btn_4, btn_5]
	
	# 3. Conectar señales
	btn_1.pressed.connect(func(): cambiar_escena(SCENE_MISION_1))
	btn_2.pressed.connect(func(): cambiar_escena(SCENE_MISION_2))
	btn_3.pressed.connect(func(): cambiar_escena(SCENE_MISION_3))
	btn_4.pressed.connect(func(): cambiar_escena(SCENE_MISION_4))
	btn_5.pressed.connect(func(): cambiar_escena(SCENE_MISION_5))
	
	# 4. Configurar animaciones
	for btn in botones:
		if is_instance_valid(btn): 
			btn.pivot_offset = btn.size / 2
			btn.mouse_entered.connect(func(): _on_hover_enter(btn))
			btn.mouse_exited.connect(func(): _on_hover_exit(btn))

# --- LÓGICA DE CAMBIO DE ESCENA ---
func cambiar_escena(ruta: String):
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t = create_tween()
	t.tween_property(self, "modulate", Color.BLACK, 0.3)
	await t.finished
	
	if ResourceLoader.exists(ruta):
		get_tree().change_scene_to_file(ruta)
	else:
		printerr("ERROR: La escena no existe en la ruta: ", ruta)
		modulate = Color.WHITE
		mouse_filter = Control.MOUSE_FILTER_STOP

# --- ANIMACIONES Y DESCRIPCIONES ---
func _on_hover_enter(btn: Button):
	# Animar botón
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
	t.tween_property(btn, "modulate", Color(1.2, 1.0, 1.5), 0.1)
	
	# Actualizar Texto de Descripción
	if descripcion:
		var texto = "[center]SELECCIONA UNA MISIÓN[/center]"
		match btn.name:
			"BtnMision1": 
				texto = "[center][color=#00FFFF]MISIÓN 1: RASTREO (BFS)[/color]\nEncuentra el nodo infectado más rápido.[/center]"
			"BtnMision2": 
				texto = "[center][color=#FFFF00]MISIÓN 2: AISLAMIENTO (DIJKSTRA)[/color]\nCalcula la ruta más segura para aislar la brecha.[/center]"
			"BtnMision3": 
				texto = "[center][color=#00FF00]MISIÓN 3: REBUILDNET (MST)[/color]\nRepara la red con el mínimo gasto energético.[/center]"
			"BtnMision4": 
				texto = "[center][color=#FF00FF]MISIÓN 4: FLOW CONTROL (MAX FLOW)[/color]\nGestiona el flujo de datos para evitar el colapso.[/center]"
			"BtnMision5": 
				texto = "[center][color=#FF0000]MISIÓN FINAL: THE CORE[/color]\n¡COMBINACIÓN DE TODOS los protocolos para detener a NEMESIS![/center]"
		
		descripcion.parse_bbcode(texto)

func _on_hover_exit(btn: Button):
	# Restaurar botón
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	t.tween_property(btn, "modulate", Color.WHITE, 0.1)
	
	if descripcion:
		descripcion.parse_bbcode("[center]SELECCIONA UNA MISIÓN[/center]")
