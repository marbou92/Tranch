shader_type spatial;

uniform vec4 blood_color : source_color = vec4(0.3, 0.05, 0.02, 0.7);
uniform sampler2D blood_mask : hint_default_white;
uniform sampler2D normal_map : hint_normal;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 uv = UV;
	float mask = texture(blood_mask, uv).r;
	
	// Edge fade
	vec2 centered = uv - 0.5;
	float dist = length(centered) * 2.0;
	float fade = smoothstep(1.0, 1.0 - edge_fade, dist);
	
	float alpha = mask * fade;
	
	ALBEDO = blood_color.rgb;
	ALPHA = alpha * blood_color.a;
	
	vec3 norm = texture(normal_map, uv).rgb;
	NORMAL_MAP = norm;
}
