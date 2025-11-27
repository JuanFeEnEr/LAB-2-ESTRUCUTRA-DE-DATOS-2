shader_type canvas_item;

// --- COLORES DE NEÓN MORADO ---
uniform vec4 bg_color : source_color = vec4(0.1, 0.0, 0.2, 1.0); // Fondo violeta oscuro
uniform vec4 grid_color : source_color = vec4(0.8, 0.2, 1.0, 0.5); // Rejilla fucsia
uniform vec4 pulse_color : source_color = vec4(0.4, 0.0, 1.0, 0.3); // Pulso índigo

// --- PARÁMETROS ---
uniform float speed : hint_range(0.0, 2.0) = 0.2;
uniform float grid_size : hint_range(10.0, 100.0) = 40.0;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	
	// 1. Movimiento de fondo (Nebulosa Digital)
	float fog = sin(uv.x * 10.0 + TIME * speed) * cos(uv.y * 5.0 - TIME * speed * 0.5);
	fog += sin(uv.x * 20.0 - TIME * speed * 2.0) * 0.2;
	
	// 2. Cuadrícula de Perspectiva (Grid)
	vec2 grid_uv = uv * grid_size;
	// Deformamos el UV para dar sensación de profundidad
	grid_uv.y += TIME * speed * 2.0;
	
	// Dibujamos líneas
	float grid_val = step(0.96, fract(grid_uv.x)) + step(0.96, fract(grid_uv.y));
	
	// Hacemos que la rejilla se desvanezca en los bordes (Viñeta)
	float vignette = distance(uv, vec2(0.5));
	vignette = 1.0 - smoothstep(0.2, 0.8, vignette);
	
	// 3. Pulso de Energía (Círculos que se expanden)
	float pulse = distance(uv, vec2(0.5));
	pulse = sin(pulse * 20.0 - TIME * 2.0);
	pulse = smoothstep(0.8, 0.9, pulse); // Anillos finos
	
	// --- COMPOSICIÓN FINAL ---
	vec4 final_color = bg_color;
	
	// Añadir la niebla morada
	final_color.rgb += pulse_color.rgb * (fog * 0.2);
	
	// Añadir la rejilla brillante
	final_color.rgb += grid_color.rgb * grid_val * vignette;
	
	// Añadir los anillos de pulso
	final_color.rgb += pulse_color.rgb * pulse * 0.5;
	
	// Ruido estático muy sutil
	float noise = random(uv * TIME);
	final_color.rgb += noise * 0.02;

	COLOR = final_color;
}