extends Node2D

# --- CONFIGURACIÓN ---
@export var node_scene: PackedScene # ¡ARRASTRA AQUÍ NodeElement.tscn DESDE EL INSPECTOR!
@export var num_nodes: int = 6      # Cantidad de nodos a generar

# --- REFERENCIAS A TU UI ---
@onready var instruction_label = $Control/InstructionLabel
@onready var graph_container = $GraphContainer

# --- DATOS DEL GRAFO ---
var nodes_list: Array = []
var adjacency: Dictionary = {} # Guarda quién está conectado con quién
var edges_visuals: Array = []  # Datos para dibujar las líneas grises

# --- ESTADOS DEL JUEGO (FASES) ---
enum Phase { SCAN_BFS, ISOLATE_DIJKSTRA, WIN }
var current_phase = Phase.SCAN_BFS
var current_path: Array = [] 
var target_node_id: int = -1 # El ID del nodo infectado

func _ready():
	randomize()
	start_new_game()

func start_new_game():
	# 1. Limpiar partida anterior
	current_path.clear()
	for n in graph_container.get_children(): 
		n.queue_free()
	nodes_list.clear()
	adjacency.clear()
	edges_visuals.clear()
	
	# 2. Generar Nodos en posiciones aleatorias
	for i in range(num_nodes):
		var node = node_scene.instantiate()
		
		# Ajusta estos valores según el tamaño de tu pantalla (x, y)
		var x = randf_range(100, 1000) 
		var y = randf_range(150, 600)
		
		node.setup(i, Vector2(x, y))
		# Conectamos la señal del nodo a la función de este script
		node.node_clicked.connect(_on_node_clicked)
		
		graph_container.add_child(node)
		nodes_list.append(node)
		adjacency[i] = []

	# 3. Crear Conexiones (Grafo)
	# Conectamos en cadena (0-1, 1-2...) para asegurar que siempre haya camino
	for i in range(num_nodes - 1):
		_add_edge(i, i+1)
	
	# Añadimos algunas conexiones extra al azar para hacerlo interesante
	for i in range(num_nodes):
		var random_dest = randi() % num_nodes
		if random_dest != i:
			_add_edge(i, random_dest)

	# 4. Elegir a NEMESIS (El último nodo será el virus)
	target_node_id = num_nodes - 1 
	nodes_list[target_node_id].set_infected()
	
	# 5. Iniciar Fase 1
	set_phase(Phase.SCAN_BFS)
	queue_redraw() # Ordena a Godot dibujar las líneas (llama a _draw)

# Función auxiliar para guardar conexiones
func _add_edge(u, v):
	# Evitar duplicados
	for connection in adjacency[u]:
		if connection.neighbor == v: return
	
	var weight = randi_range(1, 10) # Peso aleatorio
	adjacency[u].append({"neighbor": v, "weight": weight})
	adjacency[v].append({"neighbor": u, "weight": weight}) 
	
	# Guardar posiciones para dibujar la línea visualmente
	edges_visuals.append({
		"u": nodes_list[u].position, 
		"v": nodes_list[v].position, 
		"w": str(weight)
	})

# --- DIBUJADO VISUAL ---
func _draw():
	# Este bucle dibuja todas las líneas grises y los números amarillos
	for edge in edges_visuals:
		draw_line(edge.u, edge.v, Color.GRAY, 2.0)
		var mid_pos = (edge.u + edge.v) / 2
		draw_string(ThemeDB.fallback_font, mid_pos, edge.w, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.YELLOW)

# --- CONTROL DE FASES ---
func set_phase(phase):
	current_phase = phase
	current_path.clear()
	
	# Limpiar colores (excepto el rojo del virus)
	for n in nodes_list: n.reset_visual()
	
	match phase:
		Phase.SCAN_BFS:
			instruction_label.text = "FASE 1: RASTREO (BFS)\nHaz clic nodo por nodo empezando en el 0 hasta llegar al ROJO."
			# Marcar el inicio automáticamente
			nodes_list[0].set_highlight()
			current_path.append(0) 
			
		Phase.ISOLATE_DIJKSTRA:
			instruction_label.text = "FASE 2: AISLAMIENTO (Dijkstra)\nMarca el camino MÁS CORTO (menor suma de pesos) desde el 0 al ROJO."
			
		Phase.WIN:
			instruction_label.text = "¡NEMESIS ELIMINADO!\nSistema restaurado correctamente."
			# Efecto de victoria visual
			for n in nodes_list: n.set_visited()

# --- LÓGICA AL HACER CLIC ---
func _on_node_clicked(node_ref):
	var node_id = node_ref.id
	
	# --- LÓGICA FASE 1: BFS (Moverse de vecino en vecino) ---
	if current_phase == Phase.SCAN_BFS:
		var last_id = current_path[-1]
		
		# Si clicaste un vecino válido y no lo has visitado aún
		if _are_neighbors(last_id, node_id) and not (node_id in current_path):
			current_path.append(node_id)
			node_ref.set_visited()
			
			# Si llegaste al virus
			if node_id == target_node_id:
				print("Fase BFS Completada")
				# Pequeña pausa antes de la siguiente fase
				await get_tree().create_timer(1.0).timeout
				set_phase(Phase.ISOLATE_DIJKSTRA)
		else:
			# Feedback visual de error (opcional)
			print("Movimiento inválido: No es vecino o ya visitado")

	# --- LÓGICA FASE 2: DIJKSTRA (Crear ruta completa) ---
	elif current_phase == Phase.ISOLATE_DIJKSTRA:
		
		# Primer clic debe ser el inicio (0) o continuar ruta
		if current_path.is_empty():
			if node_id == 0:
				current_path.append(node_id)
				node_ref.set_highlight()
			return
			
		var last_id = current_path[-1]
		if _are_neighbors(last_id, node_id):
			current_path.append(node_id)
			node_ref.set_highlight()
			
			if node_id == target_node_id:
				set_phase(Phase.WIN)

# Verificar si dos nodos están conectados
func _are_neighbors(u, v) -> bool:
	for conn in adjacency[u]:
		if conn.neighbor == v: return true
	return false

# Conecta esto a la señal 'pressed' de tu botón Reset en el editor
func _on_reset_button_pressed():
	start_new_game()
