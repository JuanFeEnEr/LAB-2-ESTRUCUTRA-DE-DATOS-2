extends Node

var buildings: Array = []        
var last_building: Area3D = null
var player_edges: Array = []       
var connected_nodes: Dictionary = {} 

# Para calcular si la solución es óptima
var all_edges: Array = []         

@onready var drawer: Node3D = null
var status_label = null

var rng := RandomNumberGenerator.new()

# --- Base de datos de preguntas de Ciberseguridad ---
var cyber_questions = [
	{ "q": "¿Qué es Phishing?", "options": ["Suplantación de identidad", "Un antivirus", "Un firewall"], "correct": 0 },
	{ "q": "¿Qué puerto usa HTTPS?", "options": ["80", "443", "21"], "correct": 1 },
	{ "q": "¿Qué es un ataque DDoS?", "options": ["Robo de Wi-Fi", "Denegación de servicio", "Inyección SQL"], "correct": 1 },
	{ "q": "¿Contraseña más segura?", "options": ["admin123", "123456", "X#9mP2$v"], "correct": 2 },
	{ "q": "¿Qué es Ransomware?", "options": ["Software de rescate", "Hardware libre", "Un navegador"], "correct": 0 }
]

func _ready():
	add_to_group("graph_manager")

	drawer = get_tree().get_first_node_in_group("line_drawer")
	status_label = get_tree().get_first_node_in_group("status_label")

	rng.randomize()

	_collect_buildings()
	_assign_random_weights()
	_build_all_edges()
	_init_start_node()

# --- REINICIO (Nuevo) ---
func reset_simulation() -> void:
	player_edges.clear()
	connected_nodes.clear()
	
	# Limpiar líneas visuales
	if drawer and drawer.has_method("clear_all"):
		drawer.clear_all()
	
	_set_status("Simulación reiniciada. Conecta la red nuevamente.")
	_init_start_node()

func _collect_buildings() -> void:
	buildings.clear()
	var nodes = get_tree().get_nodes_in_group("building")
	for n in nodes:
		if n is Area3D:
			buildings.append(n)
	buildings.sort_custom(Callable(self, "_sort_by_node_id"))
	print("Edificios encontrados:", buildings.size())

func _sort_by_node_id(a, b) -> bool:
	return a.node_id < b.node_id

func _assign_random_weights() -> void:
	for b in buildings:
		var w = rng.randi_range(1, 9)
		if b.has_method("set_weight"):
			b.set_weight(w)
	print("Pesos asignados.")

func _build_all_edges() -> void:
	all_edges.clear()
	var n = buildings.size()
	for i in range(n):
		var a: Area3D = buildings[i]
		for j in range(i + 1, n):
			var b: Area3D = buildings[j]
			var w = 0
			if "weight" in a and "weight" in b:
				w = a.weight + b.weight  
			else:
				w = rng.randi_range(1, 9)
			var u = a.node_id
			var v = b.node_id
			if u == v: continue
			
			var edge = {"u": min(u, v), "v": max(u, v), "w": w}
			all_edges.append(edge)

func _init_start_node() -> void:
	if buildings.size() == 0: return
	
	# Buscamos siempre el ID menor para empezar
	last_building = buildings[0]
	for b in buildings:
		if b.node_id < last_building.node_id:
			last_building = b
	
	connected_nodes[last_building.node_id] = true
	print("Nodo inicial:", last_building.node_id)

func get_last_building() -> Area3D:
	return last_building

# --- Registro de Visitas (CORREGIDO: Permite moverse sin duplicar cables) ---
func register_visit(building: Area3D) -> void:
	if building == null: return
	if last_building == building: return # Ya estamos aquí

	var u = last_building.node_id
	var v = building.node_id
	var a = min(u, v)
	var b = max(u, v)

	# Verificar si esta conexión YA existe en la lista del jugador
	var exists = false
	for e in player_edges:
		if e["u"] == a and e["v"] == b:
			exists = true
			break

	if not exists:
		# Creamos nueva conexión
		var edge = {"u": a, "v": b}
		player_edges.append(edge)
		print("Nueva conexión creada: ", edge)

		if drawer and drawer.has_method("draw_connection"):
			drawer.draw_connection(last_building, building)
			
		_set_status("Conectado %d con %d" % [u, v])
	else:
		# Si ya existe, solo nos "movemos" sin tirar cable nuevo
		_set_status("Viajando por conexión existente %d-%d" % [u, v])

	connected_nodes[building.node_id] = true
	last_building = building

# --- Verificación (CORREGIDO: Basado en pesos y conectividad, no en orden) ---
func verify_solution() -> void:
	var n = buildings.size()
	if n == 0: return

	# 1. Verificar si todos los nodos están en la red
	if connected_nodes.size() < n:
		_set_status("Incompleto: Faltan nodos en tu red (%d/%d)." % [connected_nodes.size(), n])
		return

	# 2. Verificar cantidad de aristas (Para un árbol, siempre es N-1)
	if player_edges.size() != n - 1:
		if player_edges.size() < n - 1:
			_set_status("Faltan conexiones. Tienes %d, necesitas %d." % [player_edges.size(), n-1])
		else:
			_set_status("Tienes demasiadas conexiones (Ciclos). Tienes %d, necesitas %d." % [player_edges.size(), n-1])
		return

	# 3. Comparar PESO TOTAL del jugador vs PESO TOTAL del MST real
	var mst_edges = _compute_mst_edges() # El algoritmo perfecto
	
	var optimal_weight = 0
	for e in mst_edges:
		optimal_weight += e["w"]
		
	var player_weight = 0
	# Buscar el peso real de las aristas que eligió el jugador
	for pe in player_edges:
		var w = _find_weight_of_edge(pe["u"], pe["v"])
		player_weight += w
		
	print("Peso Jugador: ", player_weight, " | Peso Óptimo: ", optimal_weight)

	if player_weight == optimal_weight:
		_set_status("¡CORRECTO! Has creado un Árbol de Expansión Mínima.")
	else:
		_set_status("Incorrecto. Tu red funciona, pero es muy cara (%d vs %d)." % [player_weight, optimal_weight])

func _find_weight_of_edge(u, v) -> int:
	for e in all_edges:
		if e["u"] == min(u,v) and e["v"] == max(u,v):
			return e["w"]
	return 9999

# --- Kruskal Interno (Para comparar) ---
func _compute_mst_edges() -> Array:
	var mst: Array = []
	var n = buildings.size()
	if n == 0: return mst

	var sorted_edges = all_edges.duplicate()
	sorted_edges.sort_custom(Callable(self, "_sort_edge_by_weight"))

	var parent = {}
	var rank = {}
	
	for b in buildings:
		parent[b.node_id] = b.node_id
		rank[b.node_id] = 0

	for e in sorted_edges:
		if _union(parent, rank, e["u"], e["v"]):
			mst.append(e)
			if mst.size() == n - 1:
				break
	return mst

func _sort_edge_by_weight(a, b) -> bool:
	return a["w"] < b["w"]

func _find_parent(parent: Dictionary, x):
	if parent[x] != x:
		parent[x] = _find_parent(parent, parent[x])
	return parent[x]

func _union(parent: Dictionary, rank: Dictionary, x, y) -> bool:
	var rx = _find_parent(parent, x)
	var ry = _find_parent(parent, y)
	if rx == ry: return false

	if rank[rx] < rank[ry]:
		parent[rx] = ry
	elif rank[rx] > rank[ry]:
		parent[ry] = rx
	else:
		parent[ry] = rx
		rank[rx] += 1
	return true

func _edge_key(u, v) -> String:
	return "%d-%d" % [min(u, v), max(u, v)]

func _set_status(msg: String) -> void:
	if status_label != null:
		status_label.visible = true
		status_label.text = msg
	print(msg)

func get_random_question() -> Dictionary:
	return cyber_questions.pick_random()
