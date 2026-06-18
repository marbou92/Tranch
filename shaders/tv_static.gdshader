shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float static_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_offset : hint_range(0.0, 1.0) = 0.0;

// 12 FPS simulation for analogue interference look
void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Snap time to 12fps steps
	float snapped_time = floor(time * 12.0) / 12.0;
	
	// Static noise
	float noise = fract(sin(dot(uv + snapped_time * 0.1, vec2(12.9898, 78.233))) * 43758.5453);
	
	// Horizontal displacement
	float offset = fract(sin(snapped_time * 3.0) * 43758.5453) * 0.02;
	vec2 displaced_uv = vec2(uv.x + offset * static_intensity, uv.y);
	
	vec3 color = texture(SCREEN_TEXTURE, displaced_uv).rgb;
	
	// Mix with noise
	color = mix(color, vec3(noise), static_intensity * 0.3);
	
	// Scanlines
	float scanline = sin(uv.y * 400.0 + scanline_offset * 100.0) * 0.5 + 0.5;
	color *= mix(1.0, 0.7 + scanline * 0.3, static_intensity * 0.4);
	
	COLOR = vec4(color, 1.0);
}
