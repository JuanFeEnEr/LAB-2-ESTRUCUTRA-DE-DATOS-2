extends Area3D

@export var node_id: int = 0   # ID del nodo en el grafo

var weight: int = 0            # peso del nodo
var label3d: Label3D           # referencia al Label3D
var solid_body: StaticBody3D   # cuerpo estático para colisiones
var node_sphere: MeshInstance3D  # esfera visual para el punto de conexión


func _ready():
	# Este Area3D es un nodo del grafo
	add_to_group("building")

	# Buscar o crear el Label3D
	label3d = get_node_or_null("Label3D")
	if label3d == null:
		label3d = Label3D.new()
		label3d.name = "Label3D"
		add_child(label3d)
 #mama
	# Buscar un MeshInstance3D para calcular la altura y posición
	var mesh_node: MeshInstance3D = _find_mesh_instance(self)

	var top_pos_local := Vector3.ZERO
	var label_pos_local := Vector3.ZERO

	if mesh_node != null and mesh_node.mesh != null:
		var aabb := mesh_node.mesh.get_aabb()
		var scale := mesh_node.scale

		
		var height := aabb.size.y * scale.y

		
		var base_y := mesh_node.position.y + aabb.position.y * scale.y
		var top_y := base_y + height

		
		var sphere_y := top_y + 1.0
		
		var label_y := sphere_y + 0.5

		top_pos_local = Vector3(mesh_node.position.x, sphere_y, mesh_node.position.z)
		label_pos_local = Vector3(mesh_node.position.x, label_y, mesh_node.position.z)
	else:
	
		top_pos_local = Vector3(0, 5.0, 0)
		label_pos_local = Vector3(0, 5.5, 0)

	
	label3d.position = label_pos_local
	
	label3d.pixel_size = 0.005

	
	var palette := [
		Color(1.0, 0.4, 0.8),  # rosa
		Color(0.3, 0.8, 1.0),  # celeste
		Color(0.4, 1.0, 0.4),  # verde
		Color(1.0, 0.8, 0.3)   # naranja
	]
	var idx := int(max(0, node_id - 1)) % palette.size()
	label3d.modulate = palette[idx]
	label3d.visible = true

	
	if node_sphere == null:
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = 0.7

		node_sphere = MeshInstance3D.new()
		node_sphere.name = "NodeSphere"
		node_sphere.mesh = sphere_mesh
		node_sphere.position = top_pos_local

		var sphere_mat := StandardMaterial3D.new()
		sphere_mat.albedo_color = Color(0.2, 0.6, 1.0)
		node_sphere.material_override = sphere_mat

		add_child(node_sphere)

	
	_create_solid_body(mesh_node)

	_update_label()


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			return child
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null


func _create_solid_body(mesh_node: MeshInstance3D) -> void:
	if mesh_node == null or mesh_node.mesh == null:
		return

	solid_body = StaticBody3D.new()
	solid_body.name = "SolidBody"
	add_child(solid_body)

	
	var aabb := mesh_node.mesh.get_aabb()
	var scale := mesh_node.scale

	var box := BoxShape3D.new()
	
	box.extents = aabb.size * 0.25 * scale

	var col := CollisionShape3D.new()
	col.shape = box

	
	col.position = mesh_node.position

	solid_body.add_child(col)


func get_connection_point() -> Vector3:
	
	if node_sphere != null:
		return node_sphere.global_transform.origin
	if label3d != null:
		return label3d.global_transform.origin
	return global_transform.origin


func set_weight(new_weight: int) -> void:
	weight = new_weight
	_update_label()


func _update_label() -> void:
	if label3d:
		label3d.text = "Nodo %d  w=%d" % [node_id, weight]
