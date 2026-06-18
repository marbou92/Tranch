shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float outline_width : hint_range(0.001, 0.05) = 0.01;

void vertex() {
	// Expand vertices outward for outline effect
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
