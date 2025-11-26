extends CharacterBody3D

# Estas son las variables que DEBEN aparecerte en el Inspector
@export var projectile_scene: PackedScene 
@export var attack_range: float = 20.0
@export var shoot_interval: float = 3.0

var player: Node3D = null
var is_active: bool = true
var timer: Timer = null

func _ready():
	add_to_group("virus")
	player = get_tree().get_first_node_in_group("player")
	
	# Crear el Timer dinámicamente si no existe en la escena
	timer = Timer.new()
	timer.wait_time = shoot_interval
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_shoot)

func _physics_process(delta):
	if not is_active or player == null: return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Mirar siempre al jugador
	look_at(player.global_position, Vector3.UP)
	
	# Acercarse si está lejos, pero detenerse para disparar
	if dist > 10.0:
		velocity = -transform.basis.z * 2.0
		move_and_slide()

func _shoot():
	if not is_active or player == null: return
	if global_position.distance_to(player.global_position) > attack_range: return
	
	if projectile_scene:
		var acid = projectile_scene.instantiate()
		get_parent().add_child(acid)
		acid.global_transform = global_transform
		# Que salga un poco por delante del virus
		acid.global_position += -transform.basis.z * 1.5

func interact_to_destroy():
	# Esta función la llama el jugador con la tecla F
	print("¡Intentando hackear!")

func die():
	is_active = false
	queue_free()
