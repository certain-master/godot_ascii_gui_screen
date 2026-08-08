shader_type canvas_item;

uniform sampler2D color_map : filter_nearest;
uniform vec2 grid_size = vec2(1.0, 1.0);
uniform vec2 node_size = vec2(1.0, 1.0);

varying vec2 world_pos;

void vertex() {
	// VERTEX ist hier bereits in lokalen Koordinaten der Node (0,0 oben links)
	world_pos = VERTEX;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	vec2 local_uv = world_pos / node_size;
	vec2 cell = floor(local_uv * grid_size);
	vec2 color_uv = (cell + 0.5) / grid_size;
	
	vec4 cell_color = texture(color_map, color_uv);
	
	COLOR = vec4(cell_color.rgb, tex_color.a * cell_color.a);
}