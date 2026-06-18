shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float distort_strength : hint_range(0.0, 0.1) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.0;
uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.0;
uniform float pulse_time : hint_range(0.0, 6.28) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - 0.5;
	
	// Barrel distortion (increases with sanity loss)
	float dist = length(center);
	vec2 distorted_uv = uv + center * dist * dist * distort_strength;
	
	// Chromatic aberration
	vec2 dir = center * chromatic_aberration;
	float r = texture(SCREEN_TEXTURE, distorted_uv + dir).r;
	float g = texture(SCREEN_TEXTURE, distorted_uv).g;
	float b = texture(SCREEN_TEXTURE, distorted_uv - dir).b;
	
	vec3 color = vec3(r, g, b);
	
	// Vignette
	float vignette = 1.0 - dot(center, center) * vignette_intensity * 2.5;
	vignette = clamp(vignette, 0.0, 1.0);
	color *= vignette;
	
	// Scanlines (at very low sanity)
	float scanline = sin(uv.y * 800.0 + pulse_time * 3.0) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	color *= scanline;
	
	// Pulsing black border (sanity < 25)
	float pulse = sin(pulse_time * 2.0) * 0.5 + 0.5;
	float border = smoothstep(0.3, 0.5, max(abs(center.x), abs(center.y)));
	border = mix(1.0, border, pulse * scanline_intensity);
	color *= border;
	
	COLOR = vec4(color, 1.0);
}
