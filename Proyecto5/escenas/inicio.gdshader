shader_type canvas_item;

// --- COLORES ROJOS (NEMESIS STYLE) ---
uniform vec4 cyber_color : source_color = vec4(1.0, 0.1, 0.1, 1.0); // Rojo Neón
uniform vec4 background_color : source_color = vec4(0.05, 0.0, 0.0, 1.0); // Negro rojizo

// --- PARÁMETROS ---
uniform float grid_size : hint_range(10.0, 100.0) = 40.0;
uniform float scroll_speed : hint_range(0.0, 5.0) = 0.8;
uniform float glitch_intensity : hint_range(0.0, 0.1) = 0.03; // Un poco más fuerte que el verde
uniform float scan_beam_width : hint_range(0.0, 0.5) = 0.15;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	
	// 1. GLITCH AGRESIVO
	// Usamos el tiempo para cortar la imagen horizontalmente
	float glitch_trigger = sin(TIME * 15.0 + uv.y * 20.0);
	if (glitch_trigger > 0.90) { // Ocurre más a menudo
		uv.x += (random(vec2(TIME)) - 0.5) * glitch_intensity;
	}
	
	// 2. CUADRÍCULA (GRID)
	vec2 grid_uv = uv * grid_size;
	// Movimiento diagonal para diferenciarlo del otro
	grid_uv.x += TIME * scroll_speed * 0.5; 
	grid_uv.y += TIME * scroll_speed; 
	
	float grid_val = step(0.95, fract(grid_uv.x)) + step(0.95, fract(grid_uv.y));
	
	// 3. BARRIDO DE LUZ (SCANLINE)
	float beam = smoothstep(scan_beam_width, 0.0, abs(uv.y - fract(TIME * 0.5)));
	
	// 4. VIÑETA OSCURA (Bordes negros)
	float dist = distance(uv, vec2(0.5));
	float vignette = 1.0 - smoothstep(0.5, 1.5, dist * 1.5);

	// --- MEZCLA ---
	vec4 final_color = background_color;
	
	// Grid Rojo
	final_color.rgb += grid_val * cyber_color.rgb * 0.4;
	
	// Barra de luz blanca/roja
	final_color.rgb += beam * vec3(1.0, 0.8, 0.8); 
	
	// Ruido de fondo (Estática)
	float noise = random(uv + vec2(TIME * 10.0));
	if (noise > 0.95) final_color.rgb += cyber_color.rgb * 0.3;

	// Aplicar viñeta
	final_color.rgb *= vignette;

	COLOR = final_color;
}