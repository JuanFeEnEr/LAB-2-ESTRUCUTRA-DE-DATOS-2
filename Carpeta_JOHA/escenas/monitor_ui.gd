extends Control

@onready var imagen_ganadora = $FondoEncendido

func _ready():
	# Nos aseguramos que al empezar el juego la imagen verde esté oculta
	if imagen_ganadora:
		imagen_ganadora.visible = false
	
	# Nos añadimos al grupo para que el fantasma nos encuentre
	add_to_group("ui_monitor")

# Esta función la llama el Fantasma Elegido al morir
func mostrar_mapa_completo():
	print("¡CAMINO DESBLOQUEADO! Mostrando imagen verde.")
	if imagen_ganadora:
		imagen_ganadora.visible = true
