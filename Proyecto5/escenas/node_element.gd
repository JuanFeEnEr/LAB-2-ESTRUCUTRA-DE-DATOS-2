extends Area2D

signal node_clicked(node_ref)

var id: int = 0
var is_infected: bool = false 

@onready var label = $Label
@onready var sprite = $Sprite2D
@onready var particles = $CPUParticles2D 

func _ready():
	# Forzamos que se actualice el texto al iniciar
	update_label()
	
	if particles:
		particles.emitting = false
		particles.one_shot = true

func setup(new_id: int, pos: Vector2):
	id = new_id
	position = pos
	modulate = Color(0.2, 1.5, 2.0) # Color Cyan Base
	
	# Intentamos actualizar el texto si el nodo ya está listo
	if label:
		update_label()

func update_label():
	label.text = str(id)
	# ¡TRUCO VISUAL! 
	# Ponemos el texto en NEGRO para que contraste con el brillo neón
	label.modulate = Color.BLACK 
	# Lo hacemos un poco más grande
	label.scale = Vector2(1.5, 1.5)

func set_infected():
	is_infected = true
	modulate = Color(5.0, 0.0, 0.1) # Rojo Sangre
	scale = Vector2(1.8, 1.8)
	
	label.text = "☠" 
	label.modulate = Color.BLACK # El negro sobre rojo se ve brutal
	
	if particles:
		particles.one_shot = false
		particles.amount = 60
		particles.color = Color(0, 0, 0)
		particles.orbit_velocity_min = 1.5
		particles.emitting = true
	
	var t = create_tween().set_loops()
	t.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	t.tween_property(self, "scale", Vector2(1.8, 1.8), 0.4)

func set_visited():
	if is_infected: return
	modulate = Color(0.0, 2.5, 0.5) # Verde Hacker
	
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	if particles:
		particles.color = Color(0,1,0)
		particles.one_shot = true
		particles.orbit_velocity_min = 0.0
		particles.emitting = true

func set_highlight():
	modulate = Color(2.5, 2.0, 0.0) # Amarillo

func reset_visual():
	if is_infected: set_infected()
	else:
		modulate = Color(0.2, 1.5, 2.0)
		update_label() # Restaurar el número y color

func trigger_explosion(custom_color: Color):
	if particles:
		particles.one_shot = true
		particles.orbit_velocity_min = 0.0
		particles.color = custom_color
		particles.amount = 50
		particles.emitting = true
	
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(2.5, 2.5), 0.1)
	t.tween_property(self, "scale", Vector2(0.0, 0.0), 0.2)
	t.tween_property(self, "modulate:a", 0.0, 0.2)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("node_clicked", self)
