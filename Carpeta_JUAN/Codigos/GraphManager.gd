extends Node2D

@onready var nodes_container: Node = $Nodes
@onready var edges_container: Node = $Edges
@onready var btn_checar = $"/root/Main Scene/UI/ChecarFlujo"
@onready var btn_reiniciar = $"/root/Main Scene/UI/ReiniciarFlujo"
var used_edges: Dictionary = {}   # "A|B" → true si ya se usó


var selected_nodes: Array[String] = []
var edges: Dictionary = {}                    # "A|B" → Edge.gd (Line2D)
var original_capacities: Dictionary = {}
var total_flow: int = 0


func _ready() -> void:
	_load_edges()
	_connect_node_signals()

	if btn_checar:
		btn_checar.pressed.connect(checar_flujo)
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(_reiniciar_flujo)


# ---------------------------------------------------------
# CARGAR ARISTAS EXISTENTES
# ---------------------------------------------------------
func _load_edges() -> void:
	edges.clear()
	original_capacities.clear()

	for edge_node in edges_container.get_children():
		if edge_node is Line2D:
			var key: String = edge_node.from_id + "|" + edge_node.to_id
			edges[key] = edge_node
			original_capacities[key] = int(edge_node.capacity)

			var from_node: Node2D = nodes_container.get_node_or_null(edge_node.from_id)
			var to_node: Node2D = nodes_container.get_node_or_null(edge_node.to_id)

			if from_node and to_node:
				edge_node.update_points(from_node.position, to_node.position)
			else:
				print("GraphManager: No se encontró algún nodo para la arista ", key)


# ---------------------------------------------------------
# CONECTAR CLICS DE NODOS
# ---------------------------------------------------------
func _connect_node_signals() -> void:
	for node in nodes_container.get_children():
		if node.has_signal("node_clicked"):
			node.node_clicked.connect(_on_node_clicked)


func _on_node_clicked(id: String) -> void:
	if id == "":
		print("GraphManager: ID inválido recibido:", id)
		return

	selected_nodes.append(id)

	if selected_nodes.size() >= 2:
		var a: String = selected_nodes[selected_nodes.size() - 2]
		var b: String = selected_nodes[selected_nodes.size() - 1]
		_highlight_if_edge_exists(a, b)


# ---------------------------------------------------------
# RESALTAR ARISTA SI EXISTE
# ---------------------------------------------------------
func _highlight_if_edge_exists(a: String, b: String) -> void:
	var key := a + "|" + b
	var rev_key := b + "|" + a

	var edge: Variant = edges.get(key, edges.get(rev_key, null))

	if edge:
		edge.highlight(true)

		# --- NUEVO: registrar flujo del jugador ---
		var final_key := key if edges.has(key) else rev_key

		if not used_edges.has(final_key):
			used_edges[final_key] = true
			total_flow += edge.capacity
			print("Suma flujo: +", edge.capacity, " (total:", total_flow, ")")

	else:
		print("No hay arista entre ", a, " y ", b)


# ---------------------------------------------------------
# BOTÓN: CHECAR FLUJO
# ---------------------------------------------------------
func checar_flujo() -> void:
	var source := "S"
	var sink := "T"

	if not nodes_container.has_node(source) or not nodes_container.has_node(sink):
		print("No existe S o T.")
		return

	var max_theoretical: int = _edmonds_karp_maxflow(source, sink, original_capacities)

	print("Flujo máximo teórico:", max_theoretical)
	print("Flujo del jugador:", total_flow)

	if total_flow >= max_theoretical:
		_on_level_success()
	else:
		var faltante := max_theoretical - total_flow
		_show_message("Aún no alcanzas el flujo máximo.\n"
			+ "Actual: " + str(total_flow) + " / " + str(max_theoretical)
			+ "\nFaltan: " + str(faltante))

func _reiniciar_flujo() -> void:
	# limpiar selección
	selected_nodes.clear()
	total_flow = 0

	# apagar TODAS las aristas
	for key: String in edges.keys():
		var e = edges[key]
		if e:
			e.highlight(false)

	_show_message("Flujo reiniciado. Puedes intentar otro camino.")


func _on_level_success() -> void:
	_show_message("FLUJO COMPLETO: El ataque ha sido contenido.")


func _show_message(text: String) -> void:
	print(text)

	var popup_path := "/root/Main Scene/UI/PopupMessage"

	if has_node(popup_path):
		var p = get_node(popup_path)
		if p.has_method("show_message"):
			p.show_message(text)
		else:
			print("PopupMessage no tiene método show_message()")
	else:
		print("PopupMessage no encontrado en la ruta:", popup_path)



# ---------------------------------------------------------
# FUNCIÓN AUXILIAR: VECINOS
# ---------------------------------------------------------
func neighbors(u: String, capacities: Dictionary) -> Array[String]:
	var res: Array[String] = []

	for key: String in capacities.keys():
		var parts: PackedStringArray = key.split("|")
		if parts.size() == 2 and parts[0] == u:
			res.append(parts[1])

	for key: String in capacities.keys():
		var parts: PackedStringArray = key.split("|")
		if parts.size() == 2 and parts[1] == u and not res.has(parts[0]):
			res.append(parts[0])

	return res


# ---------------------------------------------------------
# ALGORITMO EDMONDS–KARP
# ---------------------------------------------------------
func _edmonds_karp_maxflow(src: String, dst: String, caps_input: Dictionary) -> int:
	var capacities: Dictionary = {}

	for k: String in caps_input.keys():
		capacities[k] = caps_input[k]

	var max_flow: int = 0

	while true:
		var queue: Array[String] = [src]
		var visited: Dictionary = {src: true}
		var parent: Dictionary = {}
		var found: bool = false

		while queue.size() > 0:
			var u: String = queue.pop_front()

			for v: String in neighbors(u, capacities):
				if visited.get(v, false):
					continue

				var k2: String = u + "|" + v
				var cap: int = capacities.get(k2, 0)

				if cap > 0:
					visited[v] = true
					parent[v] = u
					queue.append(v)

					if v == dst:
						found = true
						break

			if found:
				break

		if not found:
			break

		var path: Array[String] = []
		var v2: String = dst

		while v2 != src:
			path.insert(0, v2)
			v2 = parent[v2]

		path.insert(0, src)

		var path_flow: int = 999999999

		for i in range(path.size() - 1):
			var a: String = path[i]
			var b: String = path[i + 1]
			var fk: String = a + "|" + b
			path_flow = min(path_flow, capacities.get(fk, 0))

		if path_flow <= 0:
			break

		for i in range(path.size() - 1):
			var a2: String = path[i]
			var b2: String = path[i + 1]

			var fk2: String = a2 + "|" + b2
			var rk2: String = b2 + "|" + a2

			capacities[fk2] = capacities.get(fk2, 0) - path_flow
			capacities[rk2] = capacities.get(rk2, 0) + path_flow

		max_flow += path_flow

	return max_flow
