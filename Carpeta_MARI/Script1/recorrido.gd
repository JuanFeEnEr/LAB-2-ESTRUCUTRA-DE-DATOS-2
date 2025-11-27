extends Control

# --- REFERENCIAS ---
@onready var contenedor_salas = $Control
@onready var contenedor_lineas = $Node2D # Aquí están tus nodos A-B, B-D, etc.

# --- COLORES HDR ---
var color_apagado = Color(0, 0.2, 0, 1)    # Verde oscuro casi negro
var color_actual = Color(0, 4.5, 0, 1)     # Verde neón brillante (Jugador)
var color_rastro = Color(0, 1.5, 0, 1)     # Verde encendido (Camino recorrido)

# Variable local temporal
var sala_anterior: String = ""

func _ready():
	print("[MiniMapa] Iniciando. Restaurando memoria desde Global...")
	resetear_visuales()
	
	# Restauramos lo que ya exploró el jugador en niveles anteriores
	restaurar_estado()

func registrar_paso(nombre_nueva_sala: String):
	if nombre_nueva_sala == "": return
	
	# Sincronizamos la variable local con la global por si acabamos de cambiar de escena
	if sala_anterior == "":
		sala_anterior = Global.ultima_sala

	# --- CASO 1: Primer paso del juego (inicio absoluto) ---
	if Global.ultima_sala == "":
		actualizar_global_sala(nombre_nueva_sala)
		iluminar_nodo(nombre_nueva_sala, true)
		sala_anterior = nombre_nueva_sala
		return

	# --- CASO 2: Movimiento entre salas ---
	if sala_anterior != nombre_nueva_sala:
		# 1. Visuales: Apagamos (un poco) la anterior
		iluminar_nodo(sala_anterior, false) 
		
		# 2. Visuales: Pintamos la ARISTA (Línea) entre la anterior y la nueva
		pintar_linea(sala_anterior, nombre_nueva_sala)
		
		# 3. Visuales: Encendemos la nueva
		iluminar_nodo(nombre_nueva_sala, true)
		
		# 4. MEMORIA: Guardamos en Global
		actualizar_global_sala(nombre_nueva_sala)
		actualizar_global_conexion(sala_anterior, nombre_nueva_sala)
		
		# 5. Actualizamos referencia local
		sala_anterior = nombre_nueva_sala

# --- GESTIÓN DE DATOS (GLOBAL) ---

func restaurar_estado():
	# 1. Restaurar Salas visitadas
	for sala in Global.salas_visitadas:
		iluminar_nodo(sala, false) # Color "visitado"
	
	# 2. Restaurar Aristas (Líneas) pintadas
	for conexion_guardada in Global.conexiones_pintadas:
		# conexion_guardada suele ser "A-B". Separamos para buscar la línea real.
		var nodos = conexion_guardada.split("-")
		if nodos.size() == 2:
			var linea = _obtener_linea_visual(nodos[0], nodos[1])
			if linea:
				linea.default_color = color_rastro
				linea.width = 4.0
			
	# 3. Resaltar dónde está el jugador ahora mismo
	if Global.ultima_sala != "":
		iluminar_nodo(Global.ultima_sala, true) # Color "actual" brillante
		sala_anterior = Global.ultima_sala

func actualizar_global_sala(sala: String):
	Global.ultima_sala = sala
	if not sala in Global.salas_visitadas:
		Global.salas_visitadas.append(sala)

func actualizar_global_conexion(desde: String, hasta: String):
	# Convertimos "SalaA" -> "A" y "SalaB" -> "B"
	var n1 = desde.replace("Sala", "")
	var n2 = hasta.replace("Sala", "")
	
	# Guardamos siempre en un orden consistente o tal cual ocurrió
	var nombre_conexion = n1 + "-" + n2
	
	# Verificamos si ya existe esta conexión (o su inversa) para no duplicar en memoria
	var inversa = n2 + "-" + n1
	if not (nombre_conexion in Global.conexiones_pintadas or inversa in Global.conexiones_pintadas):
		Global.conexiones_pintadas.append(nombre_conexion)

# --- FUNCIONES VISUALES ---

func iluminar_nodo(nombre_sala: String, es_actual: bool):
	var nodo = contenedor_salas.get_node_or_null(nombre_sala)
	if nodo:
		if es_actual:
			nodo.color = color_actual
			nodo.scale = Vector2(1.2, 1.2)
			nodo.z_index = 10 # Poner al frente
		else:
			nodo.color = color_rastro
			nodo.scale = Vector2(1.0, 1.0)
			nodo.z_index = 1

func pintar_linea(desde_sala: String, hasta_sala: String):
	# Extraemos las letras: "SalaA" -> "A"
	var letra1 = desde_sala.replace("Sala", "")
	var letra2 = hasta_sala.replace("Sala", "")
	
	# Buscamos la arista en el árbol
	var linea = _obtener_linea_visual(letra1, letra2)
	
	if linea:
		linea.default_color = color_rastro
		linea.width = 4.0
	else:
		print("ERROR: No se encontró la arista entre ", letra1, " y ", letra2)

# --- FUNCIÓN CLAVE PARA LAS ARISTAS ---
func _obtener_linea_visual(nodo_a: String, nodo_b: String) -> Line2D:
	# Tu árbol tiene nombres específicos (ej: "A-B", "D-E").
	# Pero el jugador puede ir de B a A, o de A a B.
	# Esta función prueba ambas combinaciones.
	
	var nombre_recto = nodo_a + "-" + nodo_b  # Ej: A-B
	var nombre_inverso = nodo_b + "-" + nodo_a # Ej: B-A
	
	var linea = contenedor_lineas.get_node_or_null(nombre_recto)
	if not linea:
		linea = contenedor_lineas.get_node_or_null(nombre_inverso)
		
	return linea

func resetear_visuales():
	# Apagar todas las salas
	for sala in contenedor_salas.get_children():
		if sala is ColorRect: 
			sala.color = color_apagado
			sala.scale = Vector2(1,1)
	
	# Apagar todas las líneas (aristas)
	for linea in contenedor_lineas.get_children():
		if linea is Line2D: 
			linea.default_color = color_apagado
			linea.width = 2.0 # Grosor apagado
