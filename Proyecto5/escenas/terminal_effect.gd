extends RichTextLabel

func show_messages(lines: Array):
	# Configuración visual
	bbcode_enabled = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # Ajuste inteligente
	
	# Limpiar texto
	text = ""
	visible_ratio = 0.0
	
	# Construir el texto
	var final_text = ""
	for line in lines:
		# Texto sin saltos de línea forzados extraños
		final_text += "[font_size=24][color=#20C20E]> " + line + "[/color][/font_size]\n"
	
	text = final_text
	
	# Animación suave
	var tween = create_tween()
	tween.tween_property(self, "visible_ratio", 1.0, 2.0)
	await tween.finished
	
	# Cursor
	await _blink_cursor()

func _blink_cursor():
	var original = text
	for i in range(3):
		text = original + "_"
		await get_tree().create_timer(0.4).timeout
		text = original
		await get_tree().create_timer(0.4).timeout
