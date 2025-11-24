extends Node

var nodes := {}
var edges := []
var current_path := []
var total_flow := 0

func _ready():
	load_graph()

func load_graph():
	for node in get_node("Nodes").get_children():
		nodes[node.node_id] = node
		node.node_clicked.connect(self._on_node_clicked)

	for edge in get_node("Edges").get_children():
		edges.append(edge)

func _on_node_clicked(id):
	if current_path.is_empty() and id != "S":
		return
	current_path.append(id)
	highlight_path()

	if id == "T":
		process_path()

func highlight_path():
	# Aquí puedes pintar los nodos/aristas seleccionados
	pass

func process_path():
	var min_residual = 99999
	var valid = true

	for i in range(current_path.size() - 1):
		var e = get_edge(current_path[i], current_path[i+1])
		if e == null or e.residual() <= 0:
			valid = false
			break
		min_residual = min(min_residual, e.residual())

	if not valid:
		print("ERROR: camino inválido.")
		current_path.clear()
		return

	# Enviar flujo
	for i in range(current_path.size() - 1):
		var e = get_edge(current_path[i], current_path[i+1])
		e.push(min_residual)

	total_flow += min_residual
	print("Flujo total:", total_flow)

	current_path.clear()

func get_edge(a, b):
	for e in edges:
		if e.from_id == a and e.to_id == b:
			return e
	return null
