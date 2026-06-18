shader_type spatial;

uniform float inner_cone_angle : hint_range(0.0, 90.0) = 20.0;
uniform float outer_cone_angle : hint_range(0.0, 90.0) = 45.0;
uniform float flicker_speed : hint_range(0.0, 30.0) = 5.0;
uniform float flicker_amount : hint_range(0.0, 0.5) = 0.05;
uniform sampler2D cookie_texture : hint_default_white;
uniform float noise_time : hint_range(0.0, 100.0) = 0.0;

void light() {
	// Cone attenuation
	float cos_angle = dot(LIGHT, LIGHT);
	float inner = cos(radians(inner_cone_angle));
	float outer = cos(radians(outer_cone_angle));
	float cone_atten = smoothstep(outer, inner, cos_angle);
	
	// Cookie texture for dust scatter
	vec2 cookie_uv = LIGHT.xy * 0.5 + 0.5;
	float cookie = texture(cookie_texture, cookie_uv).r;
	
	// Flicker driven by noise
	float flicker = sin(noise_time * flicker_speed) * flicker_amount;
	flicker += sin(noise_time * flicker_speed * 2.3) * flicker_amount * 0.5;
	flicker = 1.0 - abs(flicker);
	
	DIFFUSE_LIGHT += LIGHT_COLOR * cone_atten * cookie * flicker * ATTENUATION;
}
