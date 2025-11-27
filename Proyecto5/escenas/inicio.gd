extends Control

# --- CONFIGURACIÓN ---
const GAME_SCENE_PATH = "res://Proyecto5/escenas/MainGame.tscn"

# --- REFERENCIAS ---
@onready var panel_historia = $PanelHistoria
@onready var texto_historia = $PanelHistoria/TextoHistoria
@onready var btn_jugar = $BtnJugar

# --- HISTORIA: MISIÓN 5 (THE CORE) ---
var typing_speed: float = 0.015
var story_lines: Array = [
	"[color=#FF0000]> INFORME DE MISIÓN FINAL: THE CORE[/color]",
	"[color=#FF0000]>> ESTADO CRÍTICO: NEMESIS EN EL NÚCLEO <<[/color]",
	"",
	"Hemos acorralado a la IA rebelde en el Servidor Raíz (Nodo 0).",
	"En un último intento desesperado, NEMESIS está corrompiendo los registros centrales.",
	"",
	"[color=#FFFF00]> OBJETIVO: ELIMINACIÓN TOTAL[/color]",
	"Esta es la batalla final. No hay copias de seguridad.",
	"Debes desplegar todas las contramedidas:",
	"",
	"[color=#00FF00]> PROTOCOLOS ACTIVOS:[/color]",
	"1. RASTREO (BFS): Localiza la infección.",
	"2. AISLAMIENTO (Dijkstra): Corta las rutas de escape.",
	"3. RECONSTRUCCIÓN (MST): Restaura el sistema.",
	"",
	"El destino de la red global está en tus manos...",
	"Iniciando secuencia de arranque..."
]

func _ready():
	# Ocultar botón
	if btn_jugar:
		btn_jugar.visible = false
		btn_jugar.modulate.a = 0.0
	
	# Limpiar texto e iniciar
	if texto_historia:
		texto_historia.text = ""
		texto_historia.visible_ratio = 0.0
		start_intro_sequence()

func start_intro_sequence():
	var full_text = ""
	for line in story_lines:
		full_text += line + "\n"
	
	texto_historia.parse_bbcode(full_text)
	
	var total_chars = texto_historia.get_total_character_count()
	var duration = total_chars * typing_speed
	
	var tween = create_tween()
	tween.tween_property(texto_historia, "visible_ratio", 1.0, duration)
	
	await tween.finished
	show_play_button()

func show_play_button():
	if btn_jugar:
		btn_jugar.visible = true
		var t = create_tween()
		t.tween_property(btn_jugar, "modulate:a", 1.0, 1.0)
		
		# Latido del botón
		var pulse = create_tween().set_loops()
		pulse.tween_property(btn_jugar, "scale", Vector2(1.05, 1.05), 0.8)
		pulse.tween_property(btn_jugar, "scale", Vector2(1.0, 1.0), 0.8)

func _on_btn_jugar_pressed():
	var t = create_tween()
	t.tween_property(self, "modulate", Color.BLACK, 0.5)
	await t.finished
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
