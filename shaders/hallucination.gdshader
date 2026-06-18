shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float scanline_speed : hint_range(0.0, 50.0) = 15.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Chromatic aberration
	vec2 dir = (uv - 0.5) * intensity * 0.03;
	float r = texture(SCREEN_TEXTURE, uv + dir).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv - dir).b;
	vec3 color = vec3(r, g, b);
	
	// Scanline overlay
	float scanline = sin(uv.y * 600.0 + time * scanline_speed) * 0.5 + 0.5;
	scanline = mix(1.0, scanline * 0.8 + 0.2, intensity * 0.6);
	color *= scanline;
	
	// Static noise
	float noise = fract(sin(dot(uv * time, vec2(12.9898, 78.233))) * 43758.5453);
	color = mix(color, vec3(noise), intensity * 0.15);
	
	// Color shift at very high intensity
	color.r = mix(color.r, color.r * 1.2, intensity * 0.3);
	color.b = mix(color.b, color.b * 0.8, intensity * 0.3);
	
	COLOR = vec4(color, 1.0);
}
