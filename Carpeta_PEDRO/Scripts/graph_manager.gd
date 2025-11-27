extends Node

# --- VARIABLES ---
var buildings: Array = []        
var player_edges: Array = []       
var connected_nodes: Dictionary = {} 
var all_edges: Array = []         

# --- TOPOLOGÍA DEL MAPA (Basada en tu imagen) ---
# Aquí definimos qué nodo puede conectarse con cuál.
# Formato: { ID_NODO: [VECINO_1, VECINO_2, ...] }
var allowed_connections = {
	0: [2, 9],             # a conecta con b, i
	2: [1, 3, 9],          # b conecta con a, c, i
	3: [2, 4, 8],          # c conecta con b, d, h
	4: [3, 5, 6],          # d conecta con c, e, f
	5: [4, 6],             # e conecta con d, f
	6: [4, 5, 7, 8],       # f conecta con d, e, g, h
	7: [6, 8, 9],          # g conecta con f, h, i
	8: [3, 6, 7, 9],       # h conecta con c, f, g, i
	9: [1, 2, 7, 8]        # i conecta con a, b, g, h
}

@onready var drawer: Node3D = null
@onready var status_label: Label = null
var rng := RandomNumberGenerator.new()

# Preguntas
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
	
	# Construimos solo las aristas permitidas por el mapa
	_build_allowed_edges_only()
	
	_set_status("Mapa cargado. Estrictamente basado en el diseño.")

func reset_simulation() -> void:
	player_edges.clear()
	connected_nodes.clear()
	if drawer and drawer.has_method("clear_all"):
		drawer.clear_all()
	_set_status("Reiniciado. Sigue la estructura del grafo.")

# --- INTENTO DE CONEXIÓN (CON RESTRICCIÓN) ---
func try_create_connection(node_a: Area3D, node_b: Area3D) -> bool:
	if node_a == node_b:
		_set_status("Error: No puedes conectar un nodo consigo mismo.")
		return false

	var u = node_a.node_id
	var v = node_b.node_id
	
	# 1. VERIFICACIÓN DE TOPOLOGÍA (NUEVO)
	# Revisamos si esta conexión existe en el diccionario 'allowed_connections'
	var allowed_neighbors = allowed_connections.get(u, [])
	if not (v in allowed_neighbors):
		_set_status("⛔ CONEXIÓN ILEGAL: El mapa no permite unir %d con %d." % [u, v])
		# Dibujar línea roja temporal o sonido de error aquí sería genial
		return false
	
	# 2. Verificar si ya la hiciste
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
		
	_set_status("✅ Conexión establecida: %d <--> %d" % [u, v])
	return true

# --- VERIFICACIÓN DE SOLUCIÓN ---
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

	# 3. Comparar pesos con el MST del MAPA (no el completo)
	var mst_edges = _compute_mst_edges()
	var optimal_weight = 0
	for e in mst_edges: optimal_weight += e["w"]
		
	var player_weight = 0
	for pe in player_edges:
		player_weight += _find_weight_of_edge(pe["u"], pe["v"])
		
	if player_weight == optimal_weight:
		_set_status("¡PERFECTO! Has dominado el algoritmo en este mapa.")
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
		# Asignamos peso aleatorio, pero idealmente podrías poner
		# los pesos fijos de la imagen aquí si quisieras.
		b.weight = rng.randi_range(1, 10)
		if b.has_method("set_weight"): b.set_weight(b.weight)

# --- CONSTRUCCIÓN DEL GRAFO VÁLIDO ---
func _build_allowed_edges_only() -> void:
	all_edges.clear()
	var n = buildings.size()
	
	# Recorremos solo los nodos que existen
	for i in range(n):
		var node_a = buildings[i]
		var u = node_a.node_id
		
		# Obtenemos sus vecinos permitidos del diccionario
		var neighbors = allowed_connections.get(u, [])
		
		for neighbor_id in neighbors:
			# Solo agregamos si v > u para no duplicar aristas (1-2 y 2-1)
			if neighbor_id > u:
				# Buscar el nodo objeto B
				var node_b = _find_building_by_id(neighbor_id)
				if node_b:
					var w = node_a.weight + node_b.weight
					# Si quieres usar los pesos EXACTOS de la imagen, 
					# tendrías que definir otro diccionario de pesos aquí.
					
					all_edges.append({"u": u, "v": neighbor_id, "w": w})
	
	print("Grafo construido con %d aristas válidas." % all_edges.size())

func _find_building_by_id(id):
	for b in buildings:
		if b.node_id == id: return b
	return null

func _find_weight_of_edge(u, v) -> int:
	for e in all_edges:
		if e["u"] == min(u, v) and e["v"] == max(u, v): return e["w"]
	return 9999

func get_random_question() -> Dictionary:
	return cyber_questions.pick_random()

func _set_status(msg):
	if status_label: status_label.text = msg
	print(msg)

# Algoritmo Kruskal
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
