extends Popup

@onready var label_message = $Label  # tu Label adentro del Popup

func show_message(msg: String) -> void:
	label_message.text = msg
	popup_centered()
