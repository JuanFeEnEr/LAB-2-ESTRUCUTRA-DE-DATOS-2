extends Node2D

# --- CONFIGURACIÓN ---
@export var node_scene: PackedScene 
@export var num_nodes: int = 10 

# --- FÍSICA ---
var simulation_running: bool = true
var repulsion_force: float = 80000.0 
var spring_length: float = 150.0
var spring_force: float = 0.1
var shake_strength: float = 0.0

# --- REFERENCIAS ---
@onready var instruction_label = $CanvasLayer/InstructionLabel
@onready var graph_container = $GraphContainer
@onready var terminal_panel = $CanvasLayer/HackingTerminal
@onready var nemesis_bar = $CanvasLayer/HackingTerminal/NemesisHealth
@onready var camera = $Camera2D 
@onready var terminal_text = $CanvasLayer/HackingTerminal/TerminalText 

# --- DATOS LÓGICOS ---
var nodes_list: Array = []
var adjacency: Dictionary = {} 
var edges_visuals: Array = []

var current_path: Array = []       # Usado en BFS y Dijkstra
var mst_visited: Array = []        # NUEVO: Usado en Fase 3 (Prim)
var current_weight_sum: int = 0
var target_node_id: int = -1

# AHORA SON 3 FASES DE JUEGO + VICTORIA
enum Phase { SCAN_BFS, ISOLATE_DIJKSTRA, REBUILD_MST, WIN }
var current_phase = Phase.SCAN_BFS

func _ready():
	randomize()
	terminal_panel.visible = false
	start_new_game()

func start_new_game():
	simulation_running = true
	shake_strength = 0.0
	current_path.clear()
	mst_visited.clear()
	current_weight_sum = 0
	if camera: camera.offset = Vector2.ZERO
	
	for n in graph_container.get_children(): n.queue_free()
	nodes_list.clear()
	adjacency.clear()
	edges_visuals.clear()
	
	if node_scene == null: 
		print("ERROR: Asigna NodeElement.tscn")
		return

	var vp = get_viewport_rect().size
	for i in range(num_nodes):
		var node = node_scene.instantiate()
		node.setup(i, Vector2(randf_range(100, vp.x-100), randf_range(100, vp.y-100)))
		node.node_clicked.connect(_on_node_clicked)
		graph_container.add_child(node)
		nodes_list.append(node)
		adjacency[i] = []

	for i in range(num_nodes - 1): _add_edge(i, i+1)
	for i in range(num_nodes): 
		if randf() > 0.35: 
			var dest = randi() % num_nodes
			if dest != i: _add_edge(i, dest)

	target_node_id = num_nodes - 1 
	nodes_list[target_node_id].set_infected()
	
	set_phase(Phase.SCAN_BFS)

# --- LÓGICA DE JUEGO (CLICS) ---
func _on_node_clicked(node):
	if current_phase == Phase.WIN: return
	var id = node.id
	
	# --- FASE 1: BFS ---
	if current_phase == Phase.SCAN_BFS:
		if current_path.is_empty():
			if id == 0: _add_step(node, 0)
			else: trigger_glitch("INICIA EN NODO 0")
			return
		
		var last_id = current_path[-1]
		var edge = _get_edge_data(last_id, id)
		
		if not edge or id in current_path:
			trigger_glitch("MOVIMIENTO INVÁLIDO")
			return
			
		var dist_actual = _bfs_hops(last_id, target_node_id)
		var dist_nueva = _bfs_hops(id, target_node_id)
		
		if dist_nueva >= dist_actual:
			trigger_glitch("RUTA INEFICIENTE (Más saltos)")
			return
		
		_add_step(node, 0)
		if id == target_node_id: trigger_phase_change(Phase.ISOLATE_DIJKSTRA)

	# --- FASE 2: DIJKSTRA ---
	elif current_phase == Phase.ISOLATE_DIJKSTRA:
		if current_path.is_empty():
			if id == 0: _add_step(node, 0)
			else: trigger_glitch("INICIA EN NODO 0")
			return
			
		var last_id = current_path[-1]
		var edge = _get_edge_data(last_id, id)
		
		if not edge or id in current_path:
			trigger_glitch("CONEXIÓN INVÁLIDA")
			return

		_add_step(node, edge.weight)
		
		if id == target_node_id:
			var optimal = _dijkstra_solve(0, target_node_id)
			if current_weight_sum <= optimal:
				trigger_phase_change(Phase.REBUILD_MST) # PASAMOS A FASE 3
			else:
				trigger_glitch("COSTO EXCESIVO (" + str(current_weight_sum) + " > " + str(optimal) + ")")
				_update_instruction("RECALCULANDO...")
				await get_tree().create_timer(2.0).timeout
				_reset_phase_logic()

	# --- FASE 3: PRIM (MST - RECONSTRUCCIÓN) ---
	elif current_phase == Phase.REBUILD_MST:
		# Regla: Debes hacer clic en un nodo NO visitado que tenga la conexión
		# MÁS BARATA hacia cualquiera de los nodos YA visitados (Verdes).
		
		if id in mst_visited: return # Ya está activado
		
		# Validamos si es la opción óptima de Prim
		if _is_valid_prim_choice(id):
			# Agregamos al árbol
			mst_visited.append(id)
			node.set_visited() # Se pone verde
			node.trigger_explosion(Color.GREEN) # Efecto de reparación
			
			# Verificar si completamos todos los nodos
			if mst_visited.size() == num_nodes:
				trigger_phase_change(Phase.WIN)
			else:
				_update_instruction("RED REPARADA: " + str(mst_visited.size()) + "/" + str(num_nodes))
		else:
			trigger_glitch("¡ERROR! EXISTE UNA CONEXIÓN MÁS BARATA")

# --- LÓGICA DE VALIDACIÓN PRIM (NUEVO) ---
func _is_valid_prim_choice(candidate_id) -> bool:
	# 1. ¿Está conectado a la zona segura?
	var connected_to_mst = false
	var candidate_cost = 999999
	
	for visited_id in mst_visited:
		var edge = _get_edge_data(visited_id, candidate_id)
		if edge:
			connected_to_mst = true
			if edge.weight < candidate_cost:
				candidate_cost = edge.weight
	
	if not connected_to_mst: return false # No se puede conectar aún
	
	# 2. ¿Es el costo más bajo posible de TODAS las opciones?
	# Buscamos la arista más barata disponible en todo el borde
	var min_global_cost = 999999
	
	for visited_id in mst_visited:
		for conn in adjacency[visited_id]:
			if not (conn.neighbor in mst_visited): # Si es un vecino no visitado
				if conn.weight < min_global_cost:
					min_global_cost = conn.weight
	
	# Si el costo de tu candidato es igual al mínimo global, es válido
	return candidate_cost == min_global_cost

# --- AUXILIARES ---
func _add_step(node, w):
	current_path.append(node.id)
	current_weight_sum += w
	node.set_visited()
	if current_phase == Phase.ISOLATE_DIJKSTRA:
		_update_instruction("DIJKSTRA ACTIVO\nCOSTO: " + str(current_weight_sum))

func _reset_phase_logic():
	current_path.clear(); current_weight_sum = 0
	mst_visited.clear()
	for n in nodes_list: n.reset_visual()
	
	if current_phase == Phase.REBUILD_MST:
		# En MST empezamos con el 0 ya visitado
		mst_visited.append(0)
		nodes_list[0].set_visited()
		_update_instruction("RECONECTA LA RED (Algoritmo Prim)")
	else:
		nodes_list[0].set_highlight()
		current_path.append(0)
		_update_instruction("INTENTA OTRA RUTA...")

func trigger_phase_change(next_phase):
	simulation_running = false; terminal_panel.visible = true
	var lines = []
	var hp = 100
	
	if next_phase == Phase.ISOLATE_DIJKSTRA:
		lines = ["BFS COMPLETE.", "FIREWALL 66%.", "FIND MINIMUM PATH."]
		hp = 66
	elif next_phase == Phase.REBUILD_MST:
		lines = ["VIRUS ISOLATED.", "FIREWALL 33%.", "NETWORK COLLAPSED.", "INITIATING REBUILD (MST)..."]
		hp = 33
	elif next_phase == Phase.WIN:
		lines = ["NETWORK RESTORED.", "DELETING NEMESIS...", "SYSTEM SECURE."]
		hp = 0
	
	if terminal_text.has_method("show_messages"):
		await terminal_text.show_messages(lines)
	
	var t = create_tween()
	t.tween_property(nemesis_bar, "value", hp, 1.0)
	await t.finished
	
	if next_phase == Phase.WIN:
		terminal_panel.visible = false; _play_win_sequence()
	else:
		await get_tree().create_timer(0.5).timeout
		terminal_panel.visible = false; simulation_running = true; set_phase(next_phase)

func set_phase(p):
	current_phase = p; _reset_phase_logic()
	if p == Phase.SCAN_BFS: _update_instruction("FASE 1: RASTREO (BFS)\nMenos saltos.")
	elif p == Phase.ISOLATE_DIJKSTRA: _update_instruction("FASE 2: AISLAMIENTO (Dijkstra)\nMenor peso.")
	elif p == Phase.REBUILD_MST: _update_instruction("FASE 3: RECONSTRUCCIÓN (Prim)\nExpande la red barato.")

# --- FÍSICA Y VISUALES (Se mantiene igual, solo copio lo esencial) ---
func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, 10.0 * delta)
		if camera: camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	if not simulation_running: return
	var center = get_viewport_rect().size / 2
	for i in range(nodes_list.size()):
		var node = nodes_list[i]
		var force = Vector2.ZERO
		for j in range(nodes_list.size()):
			if i == j: continue
			var diff = node.position - nodes_list[j].position
			if diff.length_squared() > 1.0: force += diff.normalized() * (repulsion_force / diff.length_squared())
		for conn in adjacency[node.id]:
			var diff = nodes_list[conn.neighbor].position - node.position
			force += diff.normalized() * (diff.length() - spring_length) * spring_force
		force += (center - node.position) * 0.05
		node.position += force * delta * 25.0
		var m = 60
		var s = get_viewport_rect().size
		node.position.x = clamp(node.position.x, m, s.x - m)
		node.position.y = clamp(node.position.y, m, s.y - m)
	queue_redraw()

func _draw():
	draw_rect(get_viewport_rect(), Color(0.02, 0.02, 0.08), true)
	var c = Color(1,1,1,0.03)
	for x in range(0, 2000, 50): draw_line(Vector2(x,0), Vector2(x,1200), c)
	for y in range(0, 1200, 50): draw_line(Vector2(0,y), Vector2(2000,y), c)
	for u in adjacency:
		for d in adjacency[u]:
			var v = d.neighbor
			var s = nodes_list[u].position; var e = nodes_list[v].position
			var pulse = (sin(Time.get_ticks_msec()*0.008)+1.0)*0.5
			# EN FASE 3 (MST), PINTAMOS LAS CONEXIONES VISITADAS DE VERDE
			var line_col = Color(0.4, 1.5, 2.0, 0.9) # Cyan por defecto
			if current_phase == Phase.REBUILD_MST:
				if (u in mst_visited) and (v in mst_visited):
					line_col = Color(0, 2.0, 0.5, 1.0) # Verde si ambos están conectados
				else:
					line_col = Color(0.5, 0.5, 0.5, 0.3) # Gris apagado si no
			
			draw_line(s, e, Color(0, 0.5, 1, 0.1), 6.0)
			draw_line(s, e, line_col, 2.0+(pulse))
			var m = (s+e)/2
			draw_circle(m, 12, Color(0,0,0,0.8))
			draw_string(ThemeDB.fallback_font, m+Vector2(-4,5), str(d.weight), 1, -1, 14, Color.YELLOW)

# ... (Mantén _play_win_sequence, _bfs_hops, _dijkstra_solve, _add_edge, _get_edge_data, trigger_glitch igual que antes) ...
# Solo asegúrate de copiar esas funciones auxiliares del script anterior si no las ves aquí.
# Para que funcione completo, aquí te pongo las faltantes resumidas:

func _play_win_sequence():
	simulation_running = false
	_update_instruction("¡NÚCLEO NEMESIS DESTRUIDO!")
	instruction_label.modulate = Color.GREEN
	for node_id in mst_visited: # Explotamos el MST
		var node = nodes_list[node_id]
		if node.has_method("trigger_explosion"): node.trigger_explosion(Color(1, 0.8, 0))
		shake_strength = 15.0
		await get_tree().create_timer(0.1).timeout
	nodes_list[target_node_id].trigger_explosion(Color.RED)
	shake_strength = 60.0
	await get_tree().create_timer(3.0).timeout
	_update_instruction("SISTEMA SEGURO. PRESIONA RESET.")

func _bfs_hops(start, end) -> int:
	var q = [{"id": start, "d": 0}]; var v = {start: true}
	while not q.is_empty():
		var c = q.pop_front()
		if c.id == end: return c.d
		for n in adjacency[c.id]:
			if not v.has(n.neighbor): v[n.neighbor]=true; q.append({"id": n.neighbor, "d": c.d+1})
	return 999

func _dijkstra_solve(start, end) -> int:
	var d = {}; for i in num_nodes: d[i] = 999999
	d[start] = 0; var uv = []
	for i in num_nodes: uv.append(i)
	while not uv.is_empty():
		var u=-1; var min_d=999999
		for n in uv: if d[n]<min_d: min_d=d[n]; u=n
		if u==-1 or u==end: break
		uv.erase(u)
		for c in adjacency[u]: if d[u]+c.weight < d[c.neighbor]: d[c.neighbor]=d[u]+c.weight
	return d[end]

func _update_instruction(text: String):
	if instruction_label.has_method("set_mission_text"): instruction_label.set_mission_text(text)
	else: instruction_label.text = text

func trigger_glitch(msg):
	shake_strength = 30.0; _update_instruction(msg); instruction_label.modulate = Color.RED
	var t = create_tween(); t.tween_property(instruction_label, "modulate", Color.WHITE, 0.5)

func _add_edge(u, v):
	if u == v: return
	for c in adjacency[u]: if c.neighbor == v: return
	var w = randi_range(1, 30)
	adjacency[u].append({"neighbor": v, "weight": w})
	adjacency[v].append({"neighbor": u, "weight": w})

func _get_edge_data(u, v):
	for c in adjacency[u]: if c.neighbor == v: return c
	return null

func _on_reset_button_pressed(): start_new_game()
