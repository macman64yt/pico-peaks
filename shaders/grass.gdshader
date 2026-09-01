shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform float wind_strength : hint_range(0.0, 1.0) = 0.35;

void vertex() {
	float s1 = sin(TIME * 2.1 + VERTEX.x * 0.8 + VERTEX.z * 1.1);
	float s2 = sin(TIME * 1.4 + VERTEX.z * 0.6 + 2.0);
	vec3 wind = vec3(s1 * 0.5 + s2 * 0.5, 0.0, s2 * 0.9);
	VERTEX += wind * wind_strength * VERTEX.y;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
}
