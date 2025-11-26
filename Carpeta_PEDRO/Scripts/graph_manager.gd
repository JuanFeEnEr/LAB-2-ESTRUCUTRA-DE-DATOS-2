extends Node

# --- VARIABLES ---
var buildings: Array = []        
var player_edges: Array = []       
var connected_nodes: Dictionary = {} 
var all_edges: Array = []         

@onready var drawer: Node3D = null
@onready var status_label: Label = null
var rng := RandomNumberGenerator.new()

# Preguntas de Ciberseguridad
var cyber_questions = [
	{ "q": "¿Qué es Phishing?", "options": ["Suplantación", "Antivirus", "Firewall"], "correct": 0 },
	{ "q": "¿Puerto HTTPS?", "options": ["80", "443", "21"], "correct": 1 },
	{ "q": "¿Ataque DDoS?", "options": ["Robo Wi-Fi", "Denegación Servicio", "SQL"], "correct": 1 },
	{ "q": "¿Password segura?", "options": ["admin", "12345", "X#9mP2$"], "correct": 2 }
]

func _ready():
	add_to_group("graph_manager")
	drawer = get_tree().get_first_node_in_group("line_drawer")
	status_label = get_tree().get_first_node_in_group("status_label")
	rng.randomize()
	
	_collect_buildings()
	_assign_random_weights()
	_build_all_edges()
	
	# Ya no iniciamos nodos automáticamente. El jugador decide dónde empezar.
	_set_status("Sistema listo. Conecta los nodos manualmente.")

func reset_simulation() -> void:
	player_edges.clear()
	connected_nodes.clear()
	if drawer and drawer.has_method("clear_all"):
		drawer.clear_all()
	_set_status("Reiniciado. Crea conexiones manualmente.")

# --- NUEVA LÓGICA DE CONEXIÓN ---
func try_create_connection(node_a: Area3D, node_b: Area3D) -> bool:
	if node_a == node_b:
		_set_status("Error: No puedes conectar un nodo consigo mismo.")
		return false

	var u = node_a.node_id
	var v = node_b.node_id
	
	# Verificar si ya existe esa conexión (A->B es igual que B->A)
	for e in player_edges:
		if e["u"] == min(u, v) and e["v"] == max(u, v):
			_set_status("Esa conexión ya existe.")
			return false

	# Crear la conexión lógica
	var edge = {"u": min(u, v), "v": max(u, v)}
	player_edges.append(edge)
	
	# Marcar nodos como "parte de la red"
	connected_nodes[u] = true
	connected_nodes[v] = true
	
	# Dibujar línea fija (Verde)
	if drawer and drawer.has_method("draw_connection"):
		drawer.draw_connection(node_a, node_b)
		
	_set_status("Conexión exitosa: %d <--> %d" % [u, v])
	return true

# --- VERIFICACIÓN (PRIM / KRUSKAL) ---
func verify_solution() -> void:
	var n = buildings.size()
	if n == 0: return

	# 1. ¿Están todos conectados?
	if connected_nodes.size() < n:
		_set_status("Incompleto: Faltan nodos en la red (%d/%d)." % [connected_nodes.size(), n])
		return

	# 2. ¿Es un árbol? (N-1 aristas)
	if player_edges.size() != n - 1:
		if player_edges.size() < n - 1:
			_set_status("Faltan cables. Tienes %d, necesitas %d." % [player_edges.size(), n-1])
		else:
			_set_status("Sobran cables (Ciclos). Tienes %d, necesitas %d." % [player_edges.size(), n-1])
		return

	# 3. ¿Es el Mínimo? (Comparar pesos)
	var mst_edges = _compute_mst_edges()
	var optimal_weight = 0
	for e in mst_edges: optimal_weight += e["w"]
		
	var player_weight = 0
	for pe in player_edges:
		player_weight += _find_weight_of_edge(pe["u"], pe["v"])
		
	if player_weight == optimal_weight:
		_set_status("¡EXCELENTE! Solución Óptima (MST). Peso: %d" % player_weight)
	else:
		_set_status("Válido pero CARO (Peso %d vs Óptimo %d)." % [player_weight, optimal_weight])

# --- UTILIDADES ---
func _collect_buildings():
	buildings.clear()
	var nodes = get_tree().get_nodes_in_group("building")
	for n in nodes: if n is Area3D: buildings.append(n)
	buildings.sort_custom(Callable(self, "_sort_by_node_id"))

func _sort_by_node_id(a, b): return a.node_id < b.node_id

func _assign_random_weights():
	for b in buildings:
		b.weight = rng.randi_range(1, 9)
		if b.has_method("set_weight"): b.set_weight(b.weight)

func _build_all_edges():
	all_edges.clear()
	var n = buildings.size()
	for i in range(n):
		for j in range(i+1, n):
			var w = buildings[i].weight + buildings[j].weight
			all_edges.append({"u": buildings[i].node_id, "v": buildings[j].node_id, "w": w})

func _find_weight_of_edge(u, v) -> int:
	for e in all_edges:
		if e["u"] == min(u, v) and e["v"] == max(u, v): return e["w"]
	return 9999

func get_random_question() -> Dictionary:
	return cyber_questions.pick_random()

func _set_status(msg):
	if status_label: status_label.text = msg
	print(msg)

# Algoritmo Kruskal interno (para comparar)
func _compute_mst_edges() -> Array:
	var mst: Array = []
	var sorted = all_edges.duplicate()
	sorted.sort_custom(Callable(self, "_sort_edge_by_weight"))
	var parent = {}
	var rank = {}
	for b in buildings:
		parent[b.node_id] = b.node_id
		rank[b.node_id] = 0
	for e in sorted:
		if _union(parent, rank, e["u"], e["v"]):
			mst.append(e)
	return mst

func _sort_edge_by_weight(a, b): return a["w"] < b["w"]
func _find_parent(parent, x):
	if parent[x] != x: parent[x] = _find_parent(parent, parent[x])
	return parent[x]
func _union(parent, rank, x, y):
	var rx = _find_parent(parent, x)
	var ry = _find_parent(parent, y)
	if rx == ry: return false
	if rank[rx] < rank[ry]: parent[rx] = ry
	elif rank[rx] > rank[ry]: parent[ry] = rx
	else:
		parent[ry] = rx
		rank[rx] += 1
	return true
