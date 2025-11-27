extends Control

# --- RUTA A TU JUEGO ---
# Asegúrate de que esta ruta sea exacta a donde tienes tu MainGame.tscn
const GAME_SCENE_PATH := "res://Carpeta_PEDRO/Escenas/level_1.tscn"

# --- REFERENCIAS A NODOS (Deben ser exactas) ---
# Si te da error aquí, borra la línea y escribe "$" para buscar el nodo tú mismo.
@onready var btn_jugar = $BtnJugar
@onready var btn_salir = $BtnSalir
@onready var panel_historia = $PanelHistoria
# Buscamos el texto DENTRO del panel
@onready var texto_historia = $PanelHistoria/TextoHistoria

# --- CONFIGURACIÓN ---
var typing_speed: float = 0.015

# Historia: Misión 3 (MST/RebuildNet)
var story_lines: Array = [
	"[color=#00FFFF]> INFORME DE MISIÓN 3: REBUILDNET[/color]",
	"[color=#FF0000]>> ALERTA: RED FÍSICA COLAPSADA <<[/color]",
	"",
	"NEMESIS ha detonado los nodos principales.",
	"La infraestructura global está desconectada.",
	"",
	"[color=#FFFF00]> PROTOCOLO 'CYBER-DRONE' ACTIVADO[/color]",
	"Hemos desplegado un dron de reparación bajo tu mando.",
	"TU OBJETIVO: Reconectar los servidores aislados.",
	"",
	"[color=#00FF00]> INSTRUCCIONES (MST):[/color]",
	"1. Usa el algoritmo de Árbol de Expansión Mínima (Prim).",
	"2. Conecta TODOS los nodos gastando la menor energía posible.",
	"3. Evita rutas costosas o el sistema fallará.",
	"",
	"Esperando enlace neural..."
]

func _ready():
	# 1. Ocultar botones al inicio
	# Verificamos que existan antes de ocultarlos para evitar errores
	if btn_jugar: 
		btn_jugar.visible = false
		btn_jugar.modulate.a = 0.0
	
	if btn_salir:
		btn_salir.visible = false
		btn_salir.modulate.a = 0.0
	
	# 2. Limpiar texto
	if texto_historia:
		texto_historia.text = ""
		texto_historia.visible_ratio = 0.0
		# Iniciar historia
		start_intro_sequence()
	else:
		print("ERROR: No se encuentra el nodo TextoHistoria dentro de PanelHistoria")

func start_intro_sequence():
	var full_text = ""
	for line in story_lines:
		full_text += line + "\n"
	
	texto_historia.parse_bbcode(full_text)
	
	var total_chars = texto_historia.get_total_character_count()
	var duration = total_chars * typing_speed
	
	# Animación de escritura
	var tween = create_tween()
	tween.tween_property(texto_historia, "visible_ratio", 1.0, duration)
	
	await tween.finished
	show_buttons()

func show_buttons():
	if btn_jugar: btn_jugar.visible = true
	if btn_salir: btn_salir.visible = true
	
	# Fade In suave
	var t = create_tween().set_parallel(true)
	if btn_jugar: t.tween_property(btn_jugar, "modulate:a", 1.0, 0.8)
	if btn_salir: t.tween_property(btn_salir, "modulate:a", 1.0, 0.8)
	
	pulsate_play_button()

func pulsate_play_button():
	if not btn_jugar: return
	var t = create_tween().set_loops()
	t.tween_property(btn_jugar, "scale", Vector2(1.05, 1.05), 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(btn_jugar, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE)

# --- SEÑALES ---
# Asegúrate de reconectar estas señales en el editor si se desconectaron
func _on_btn_jugar_pressed():
	# Fade a negro antes de cambiar
	var t = create_tween()
	t.tween_property(self, "modulate", Color.BLACK, 0.5)
	await t.finished
	
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_btn_salir_pressed():
	get_tree().quit()
