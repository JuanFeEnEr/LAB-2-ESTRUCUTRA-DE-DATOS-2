extends Node

var buildings: Array = []        
var visited_sequence: Array = []   
var last_building: Area3D = null
var player_edges: Array = []       


var connected_nodes: Dictionary = {} 

var rng := RandomNumberGenerator.new()
var all_edges: Array = []         

@onready var drawer: Node3D = null
var status_label = null


func _ready():
	add_to_group("graph_manager")

	drawer = get_tree().get_first_node_in_group("line_drawer")
	status_label = get_tree().get_first_node_in_group("status_label")

	rng.randomize()

	_collect_buildings()
	_assign_random_weights()
	_build_all_edges()
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
	print("Pesos asignados a cada nodo.")


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
			if u == v:
				continue
			var edge = {"u": min(u, v), "v": max(u, v), "w": w}
			all_edges.append(edge)

	print("Total de aristas en el grafo completo:", all_edges.size())


func _init_start_node() -> void:
	if buildings.size() == 0:
		return
	
	last_building = buildings[0]
	for b in buildings:
		if b.node_id < last_building.node_id:
			last_building = b
	print("Nodo inicial del cable dinámico:", last_building.node_id)
	
	
	connected_nodes[last_building.node_id] = true


func get_last_building() -> Area3D:
	return last_building


func register_visit(building: Area3D) -> void:
	if building == null:
		return

	
	if connected_nodes.has(building.node_id):
		_set_status("⚠️ El nodo %d ya está conectado." % building.node_id)
		return

	
	if visited_sequence.size() == 0 or visited_sequence[-1] != building.node_id:
		visited_sequence.append(building.node_id)
		print("Secuencia de visita:", visited_sequence)

	
	if last_building != null and last_building != building:
		var u = last_building.node_id
		var v = building.node_id
		var a = min(u, v)
		var b = max(u, v)

		
		var exists = false
		for e in player_edges:
			if e["u"] == a and e["v"] == b:
				exists = true
				break

		if not exists:
			var edge = {"u": a, "v": b}
			player_edges.append(edge)
			print("Arista jugador añadida:", edge)

			if drawer and drawer.has_method("draw_connection"):
				drawer.draw_connection(last_building, building)
			
			
			connected_nodes[building.node_id] = true

	last_building = building


func verify_solution() -> void:
	var n = buildings.size()
	if n == 0:
		_set_status("No hay nodos en el grafo.")
		return

	
	var visited_dict = {}
	for id in visited_sequence:
		visited_dict[id] = true

	
	if connected_nodes.size() < n:
		_set_status("Debes conectar todos los nodos antes de verificar (faltan %d)." % (n - connected_nodes.size()))
		return

	
	if player_edges.size() != n - 1:
		_set_status("Debes crear exactamente %d conexiones. Ahora tienes %d." % [n - 1, player_edges.size()])
		return

	var mst_edges = _compute_mst_edges()
	if mst_edges.size() != n - 1:
		_set_status("No se pudo calcular el árbol mínimo.")
		return

	
	var mst_set = {}
	for e in mst_edges:
		var key = _edge_key(e["u"], e["v"])
		mst_set[key] = true

	var player_set = {}
	for e in player_edges:
		var key = _edge_key(e["u"], e["v"])
		player_set[key] = true

	var ok = true
	if player_set.size() != mst_set.size():
		ok = false
	else:
		for key in mst_set.keys():
			if not player_set.has(key):
				ok = false
				break

	if ok:
		_set_status("Correcto: construiste un árbol de expansión mínimo (Prim/Kruskal).")
	else:
		_set_status("La solución no es mínima. Intenta ajustar las conexiones.")


func _compute_mst_edges() -> Array:
	var mst: Array = []
	var n = buildings.size()
	if n == 0:
		return mst

	var sorted_edges = all_edges.duplicate()
	sorted_edges.sort_custom(Callable(self, "_sort_edge_by_weight"))

	var parent = {}
	var rank = {}

	
	for b in buildings:
		parent[b.node_id] = b.node_id
		rank[b.node_id] = 0

	for e in sorted_edges:
		var u = e["u"]
		var v = e["v"]
		if not parent.has(u) or not parent.has(v):
			continue
		if _union(parent, rank, u, v):
			mst.append(e)
			if mst.size() == n - 1:
				break

	print("Aristas del MST (Kruskal):", mst)
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
	if rx == ry:
		return false

	if rank[rx] < rank[ry]:
		parent[rx] = ry
	elif rank[rx] > rank[ry]:
		parent[ry] = rx
	else:
		parent[ry] = rx
		rank[rx] += 1

	return true


func _edge_key(u, v) -> String:
	var a = min(u, v)
	var b = max(u, v)
	return "%d-%d" % [a, b]


func _set_status(msg: String) -> void:
	if status_label != null:
		status_label.visible = true
		status_label.text = msg
	print(msg)


func compute_mst_edges_prim() -> Array:
	var n = buildings.size()
	if n == 0:
		return []
	var visited = {}
	var edges = []
	var start = buildings[0].node_id
	for b in buildings:
		if b.node_id < start:
			start = b.node_id
	visited[start] = true
	while visited.size() < n:
		var best = null
		for e in all_edges:
			if (e["u"] in visited and not (e["v"] in visited)) or (e["v"] in visited and not (e["u"] in visited)):
				if best == null or e["w"] < best["w"]:
					best = e
		if best == null:
			break
		edges.append(best)
		visited[best["u"]] = true
		visited[best["v"]] = true
	return edges
