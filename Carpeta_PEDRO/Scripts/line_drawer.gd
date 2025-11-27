extends Node3D

var lines: Array = []                
var dynamic_line: MeshInstance3D = null 

func _ready():
	add_to_group("line_drawer")

func clear_all() -> void:
	for l in lines:
		if is_instance_valid(l): l.queue_free()
	lines.clear()
	clear_dynamic_cable()

func update_dynamic_cable(from_world: Vector3, to_world: Vector3) -> void:
	var from_local = to_local(from_world)
	var to_local_pos = to_local(to_world)
	var mesh = _create_line_mesh(from_local, to_local_pos)

	if dynamic_line == null or not is_instance_valid(dynamic_line):
		dynamic_line = MeshInstance3D.new()
		add_child(dynamic_line)
	
	dynamic_line.mesh = mesh
	dynamic_line.material_override = _create_material(Color(1.0, 0.9, 0.1)) # Amarillo

# --- ESTA FUNCIÓN ES LA QUE NECESITAMOS ---
func clear_dynamic_cable() -> void:
	if dynamic_line != null and is_instance_valid(dynamic_line):
		dynamic_line.queue_free()
	dynamic_line = null

func draw_connection(building_a: Area3D, building_b: Area3D) -> void:
	if not building_a or not building_b: return

	var p1 = building_a.get_connection_point() if building_a.has_method("get_connection_point") else building_a.global_position
	var p2 = building_b.get_connection_point() if building_b.has_method("get_connection_point") else building_b.global_position

	var mesh = _create_line_mesh(to_local(p1), to_local(p2))
	var line_instance = MeshInstance3D.new()
	line_instance.mesh = mesh
	line_instance.material_override = _create_material(Color(0.1, 1.0, 0.1)) # Verde
	
	add_child(line_instance)
	lines.append(line_instance)

func _create_line_mesh(pos1, pos2) -> ImmediateMesh:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(pos1)
	mesh.surface_add_vertex(pos2)
	mesh.surface_end()
	return mesh

func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
