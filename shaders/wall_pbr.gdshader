shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.4, 0.38, 0.35, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D roughness_map : hint_default_white;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D ao_map : hint_default_white;
uniform float normal_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float ao_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	
	vec4 albedo_color = albedo;
	float rough = texture(roughness_map, uv).r * roughness;
	float ao = texture(ao_map, uv).r;
	vec3 normal = texture(normal_map, uv).rgb;
	normal = normalize(mix(vec3(0.5, 0.5, 1.0), normal, normal_intensity));
	
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = rough;
	METALLIC = metallic;
	NORMAL_MAP = normal;
	AO = mix(1.0, ao, ao_intensity);
	AO_LIGHT_AFFECT = 0.5;
}
