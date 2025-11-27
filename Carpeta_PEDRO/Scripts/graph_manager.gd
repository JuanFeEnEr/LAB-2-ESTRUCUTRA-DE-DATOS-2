extends Node

# --- VARIABLES ---
var buildings: Array = []        
var player_edges: Array = []       
var connected_nodes: Dictionary = {} 
var all_edges: Array = []         

# --- TOPOLOGÍA (MAPA DE VECINOS) ---
# Esto define estrictamente quién conecta con quién según tu dibujo.
var allowed_connections = {
	1: [2, 9],             # a -> b, i
	2: [1, 3, 9],          # b -> a, c, i
	3: [2, 4, 8],          # c -> b, d, h
	4: [3, 5, 6],          # d -> c, e, f
	5: [4, 6],             # e -> d, f
	6: [4, 5, 7, 8],       # f -> d, e, g, h
	7: [6, 8, 9],          # g -> f, h, i
	8: [3, 6, 7, 9],       # h -> c, f, g, i
	9: [1, 2, 7, 8]        # i -> a, b, g, h
}

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
	# Autoregistro en grupo
	if not is_in_group("graph_manager"): add_to_group("graph_manager")
	
	drawer = get_tree().get_first_node_in_group("line_drawer")
	status_label = get_tree().get_first_node_in_group("status_label")
	rng.randomize()
	
	_collect_buildings()
	_assign_random_weights()
	# Construimos solo las aristas válidas internamente para calcular el MST real
	_build_allowed_edges_only()
	
	_set_status("Mapa cargado. Restricciones de vecinos ACTIVAS.")

# --- INTENTO DE CONEXIÓN (CON RESTRICCIÓN DE VECINOS) ---
func try_create_connection(node_a: Area3D, node_b: Area3D) -> bool:
	if node_a == node_b:
		_set_status("No puedes conectar un nodo consigo mismo.")
		return false

	var u = node_a.node_id
	var v = node_b.node_id
	
	# 1. VERIFICACIÓN DE MAPA (Aquí es donde fallaba)
	# Preguntamos: "¿Está 'v' en la lista de amigos de 'u'?"
	var neighbors = allowed_connections.get(u, [])
	
	if not (v in neighbors):
		_set_status("⛔ ACCESO DENEGADO: El nodo %d no es vecino directo del %d." % [u, v])
		return false
	
	# 2. Verificar duplicados
	for e in player_edges:
		if e["u"] == min(u, v) and e["v"] == max(u, v):
			_set_status("Esa conexión ya existe.")
			return false

	# 3. Éxito
	var edge = {"u": min(u, v), "v": max(u, v)}
	player_edges.append(edge)
	
	connected_nodes[u] = true
	connected_nodes[v] = true
	
	if drawer and drawer.has_method("draw_connection"):
		drawer.draw_connection(node_a, node_b)
		
	_set_status("✅ Cable conectado: %d <--> %d" % [u, v])
	return true

# --- VERIFICACIÓN DE VICTORIA ---
func verify_solution() -> void:
	var n = buildings.size()
	if n == 0: return

	if connected_nodes.size() < n:
		_set_status("Faltan nodos en la red (%d/%d)." % [connected_nodes.size(), n])
		return

	if player_edges.size() != n - 1:
		_set_status("Debes tener exactamente %d cables (tienes %d)." % [n-1, player_edges.size()])
		return

	# Verificación de Peso (Algoritmo Prim/Kruskal)
	var mst_edges = _compute_mst_edges()
	var optimal_weight = 0
	for e in mst_edges: optimal_weight += e["w"]
		
	var player_weight = 0
	for pe in player_edges:
		player_weight += _find_weight_of_edge(pe["u"], pe["v"])
		
	if player_weight == optimal_weight:
		_set_status("¡SISTEMA SEGURO! Has creado el MST perfecto.")
	else:
		_set_status("Red funcional pero INEFICIENTE (Peso %d vs Óptimo %d)." % [player_weight, optimal_weight])

# --- UTILIDADES ---
func get_random_question() -> Dictionary:
	return cyber_questions.pick_random()

func _set_status(msg):
	if status_label: status_label.text = msg
	print(msg)

func _collect_buildings():
	buildings.clear()
	var nodes = get_tree().get_nodes_in_group("building")
	for n in nodes: if n is Area3D: buildings.append(n)
	buildings.sort_custom(Callable(self, "_sort_by_node_id"))

func _sort_by_node_id(a, b): return a.node_id < b.node_id

func _assign_random_weights():
	for b in buildings:
		b.weight = rng.randi_range(1, 10)
		if b.has_method("set_weight"): b.set_weight(b.weight)

func _build_allowed_edges_only() -> void:
	all_edges.clear()
	# Solo creamos aristas donde el mapa lo permite
	for b in buildings:
		var u = b.node_id
		var neighbors = allowed_connections.get(u, [])
		for v in neighbors:
			if v > u: # Evitar duplicados
				var node_b = _find_building_by_id(v)
				if node_b:
					all_edges.append({"u": u, "v": v, "w": b.weight + node_b.weight})

func _find_building_by_id(id):
	for b in buildings: if b.node_id == id: return b
	return null

func _find_weight_of_edge(u, v) -> int:
	for e in all_edges:
		if e["u"] == min(u, v) and e["v"] == max(u, v): return e["w"]
	return 9999

# Kruskal Interno
func _compute_mst_edges() -> Array:
	var mst = []; var sorted = all_edges.duplicate()
	sorted.sort_custom(Callable(self, "_sort_edge_by_weight"))
	var parent = {}; var rank = {}
	for b in buildings: parent[b.node_id] = b.node_id; rank[b.node_id] = 0
	for e in sorted:
		if _union(parent, rank, e["u"], e["v"]): mst.append(e)
	return mst

func _sort_edge_by_weight(a, b): return a["w"] < b["w"]
func _find_parent(p, i):
	if p[i] != i: p[i] = _find_parent(p, p[i])
	return p[i]
func _union(p, r, x, y):
	var rx = _find_parent(p, x); var ry = _find_parent(p, y)
	if rx == ry: return false
	if r[rx] < r[ry]: p[rx] = ry
	elif r[rx] > r[ry]: p[ry] = rx
	else: p[ry] = rx; r[rx] += 1
	return true
