extends CanvasLayer

## A basic dialogue balloon for use with Dialogue Manager.

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## --- LÓGICA PRINCIPAL CORREGIDA ---
# 1. Quitamos ': DialogueLine' para evitar errores de tipo. Ahora es 'Variant' (dinámico).
var _dialogue_line

var dialogue_line:
	get:
		return _dialogue_line
	set(value):
		_dialogue_line = value
		
		# Si hay una línea válida, la mostramos
		if value:
			print("DEBUG: Línea de diálogo recibida correctamente.")
			apply_dialogue_line()
		else:
			# --- AQUÍ EL DIÁLOGO HA TERMINADO ---
			print("DEBUG: Fin del diálogo detectado. Cambiando de escena...")
			hide()
			
			# ATENCIÓN: Revisa MUY BIEN esta ruta. 
			# Si la carpeta es "Carpeta_MARIAA" o "Carpeta_MARI". 
			# Un solo caracter mal y el juego crashea.
			var ruta_escena = "res://Carpeta_MARI/Escenas/Tipo.tscn"
			
			if ResourceLoader.exists(ruta_escena):
				get_tree().change_scene_to_file(ruta_escena)
			else:
				push_error("ERROR CRÍTICO: No se encuentra la escena: " + ruta_escena)
				# Si falla, al menos cerramos el diálogo para no bloquear el juego
				queue_free() 
## ------------------------------------

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			push_error("Falta asignar un DialogueResource en el Inspector para usar auto_start.")
			return
		start()


func _process(_delta: float) -> void:
	# Quitamos el tipado estricto aquí también
	if is_instance_valid(dialogue_line):
		progress.visible = (
			not dialogue_label.is_typing
			and dialogue_line.responses.size() == 0
			and not dialogue_line.has_tag("voice")
		)


func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource

	if not title.is_empty():
		start_from_title = title

	print("DEBUG: Iniciando diálogo...")
	# Aquí es donde podría estar fallando si devuelve null
	var linea = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	
	if linea == null:
		print("ERROR: get_next_dialogue_line devolvió NULL. Revisa el Resource o el Título.")
	
	dialogue_line = linea
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Verificación extra de seguridad
	if not is_instance_valid(dialogue_line): return

	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)

	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()

	# ATENCIÓN: Usamos "in" para evitar crasheos si la propiedad 'time' no existe
	elif "time" in dialogue_line and dialogue_line.time != "":
		var time: float = 0.0
		if dialogue_line.time == "auto":
			time = dialogue_line.text.length() * 0.02
		else:
			time = dialogue_line.time.to_float()
		
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)

	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.is_pressed()
		)
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)
