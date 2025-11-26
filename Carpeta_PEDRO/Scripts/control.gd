extends Control

const LEVEL_SCENE := "res://Carpeta_PEDRO/Escenas/level_1.tscn"

func _on_button_pressed() -> void:   
	get_tree().change_scene_to_file(LEVEL_SCENE)

func _on_button_2_pressed() -> void: 
	get_tree().quit()
