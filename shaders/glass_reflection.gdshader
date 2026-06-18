shader_type spatial;

uniform float reflectivity : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform vec4 tint_color : source_color = vec4(0.6, 0.7, 0.8, 0.5);
uniform float fresnel_power : hint_range(0.1, 5.0) = 3.0;

void fragment() {
	// Fresnel-based reflectivity
	float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), fresnel_power);
	float reflect = mix(0.05, reflectivity, fresnel);
	
	ALBEDO = tint_color.rgb;
	ALPHA = mix(tint_color.a, 1.0, fresnel * 0.5);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = reflect;
}
