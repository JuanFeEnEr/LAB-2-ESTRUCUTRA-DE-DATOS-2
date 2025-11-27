extends Label

@export var timer_a_observar: Timer 

# 1. Ponemos un guion bajo (_delta) para quitar la advertencia "delta never used"
func _process(_delta):
	if is_instance_valid(timer_a_observar) and not timer_a_observar.is_stopped():
		actualizar_texto()

func actualizar_texto():
	var tiempo_restante: int = int(timer_a_observar.time_left)
	
	var minutos: int = tiempo_restante / 60
	var segundos: int = tiempo_restante % 60
	
	text = "%02d:%02d" % [minutos, segundos]
	
	if tiempo_restante < 60:
		modulate = Color.RED
	else:
		modulate = Color.WHITE
