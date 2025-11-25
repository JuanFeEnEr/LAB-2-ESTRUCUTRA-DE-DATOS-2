extends Node2D

@onready var nodes_container = $Nodes
@onready var edges_container = $Edges

var selected_nodes: Array[String] = []
var edges: Dictionary = {}    # "A->B" : Edge (Line2D)


func _ready():
	_load_edges()
	_connect_node_signals()


# -----------------------------------------------------
# CARGAR ARISTAS YA EXISTENTES
# -----------------------------------------------------
func _load_edges():
	for edge in edges_container.get_children():
		if edge is Line2D:
			var key = "%s->%s" % [edge.from_id, edge.to_id]
			edges[key] = edge
			_update_edge_visual(edge)

# -----------------------------------------------------
# CONECTAR CLICS DE NODOS
# -----------------------------------------------------
func _connect_node_signals():
	for node in nodes_container.get_children():
		if node.has_signal("node_clicked"):
			node.connect("node_clicked", Callable(self, "_on_node_clicked"))


func _on_node_clicked(id: String):
	selected_nodes.append(id)
	if selected_nodes.size() == 2:
		var a = selected_nodes[0]
		var b = selected_nodes[1]
		_highlight_if_edge_exists(a, b)
		selected_nodes.clear()

# -----------------------------------------------------
# RESALTAR ARISTA SI EXISTE
# -----------------------------------------------------
func _highlight_if_edge_exists(a: String, b: String):
	var key1 = "%s->%s" % [a, b]
	var key2 = "%s->%s" % [b, a]
	var edge = edges.get(key1, null)
	if edge == null:
		edge = edges.get(key2, null)
	if edge:
		edge.default_color = Color.ORANGE_RED
		edge.width = 6
	else:
		print("No hay arista entre ", a, " y ", b)

# -----------------------------------------------------
# DIBUJAR ARISTA SEGÚN POSICIÓN DE NODOS
# -----------------------------------------------------
func _update_edge_visual(edge: Line2D):
	var from_node = nodes_container.get_node(edge.from_id)
	var to_node = nodes_container.get_node(edge.to_id)
	if from_node and to_node:
		edge.points = [
			from_node.position,
			to_node.position
		]
		edge.default_color = Color.SKY_BLUE
		edge.width = 4
	else:
		print("Error: nodo no encontrado para arista ", edge.from_id, " -> ", edge.to_id)
