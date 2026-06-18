shader_type canvas_item;

uniform float distortion_amount : hint_range(0.0, 2.0) = 0.0;
uniform float zoom : hint_range(0.5, 2.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - 0.5;
	
	// Barrel distortion
	float r2 = dot(center, center);
	vec2 distorted = uv + center * r2 * distortion_amount * 0.1;
	
	// Zoom to hide edge artifacts
	distorted = (distorted - 0.5) / zoom + 0.5;
	
	COLOR = texture(SCREEN_TEXTURE, distorted);
}
