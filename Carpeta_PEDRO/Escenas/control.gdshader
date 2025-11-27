shader_type canvas_item;

// --- CONFIGURACIÓN DE COLORES ---
uniform vec4 cyber_color : source_color = vec4(0.0, 1.0, 0.3, 0.8); // Verde Matrix
uniform vec4 background_color : source_color = vec4(0.0, 0.1, 0.0, 0.5); // Fondo oscuro

// --- PARÁMETROS DE EFECTOS ---
uniform float grid_size : hint_range(10.0, 100.0) = 50.0;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.5;
uniform float glitch_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float scan_beam_width : hint_range(0.0, 0.5) = 0.1;

// Función de ruido aleatorio
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// 1. EFECTO GLITCH (Desplazamiento horizontal aleatorio)
	// Creamos bandas horizontales usando el tiempo y la posición Y
	float glitch_trigger = sin(TIME * 20.0 + uv.y * 10.0);
	// Si el valor supera un umbral, aplicamos el desplazamiento
	if (glitch_trigger > 0.95) {
		uv.x += (random(vec2(TIME)) - 0.5) * glitch_intensity;
	}

	// 2. CUADRÍCULA (GRID)
	// Movemos la cuadrícula con el tiempo
	vec2 grid_uv = uv * grid_size;
	grid_uv.y += TIME * scroll_speed * 5.0; // Movimiento vertical

	// Dibujamos líneas verticales y horizontales
	float grid_val = step(0.95, fract(grid_uv.x)) + step(0.95, fract(grid_uv.y));
	grid_val = clamp(grid_val, 0.0, 1.0);

	// 3. BARRA DE ESCANEO (Luz brillante que baja)
	float beam_pos = fract(TIME * 0.3); // Posición de la barra (0 a 1)
	float beam = smoothstep(scan_beam_width, 0.0, abs(uv.y - beam_pos));

	// 4. BORDES TECNOLÓGICOS
	vec2 border_dist = min(uv, 1.0 - uv);
	float border = step(min(border_dist.x, border_dist.y), 0.02);

	// --- MEZCLA FINAL ---
	vec4 final_color = background_color;

	// Añadimos la cuadrícula
	final_color.rgb += grid_val * cyber_color.rgb * 0.5;

	// Añadimos el borde fuerte
	final_color.rgb += border * cyber_color.rgb;
	final_color.a += border;

	// Añadimos la barra de escaneo (muy brillante)
	final_color.rgb += beam * vec3(1.0, 1.0, 1.0); // Luz blanca
	final_color.a += beam * 0.5;

	// Ruido digital sutil en el fondo
	float noise = random(uv + vec2(TIME * 5.0));
	if (noise > 0.9) {
		final_color.rgb += cyber_color.rgb * 0.2;
	}

	COLOR = final_color;
}