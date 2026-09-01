shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform float wind_strength : hint_range(0.0, 1.0) = 0.25;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float s1 = sin(TIME * 1.5 + world_pos.x * 0.35 + world_pos.z * 0.2);
	float s2 = sin(TIME * 0.9 + world_pos.x * 0.2 + 1.3);
	vec3 wind = vec3(s1, 0.0, s2 * 0.8);
	VERTEX += wind * wind_strength * VERTEX.y;

	float d = vnoise(world_pos.xz * 2.2 + vec2(world_pos.y * 0.5));
	float j = smoothstep(0.3, 1.0, d);
	VERTEX += NORMAL * j * 0.32 * VERTEX.y;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 base = COLOR.rgb;
	float d = vnoise(world_pos.xz * 3.5 + world_pos.y * 1.2);
	float shade = 0.72 + 0.38 * d;
	ALBEDO = base * shade;
	ROUGHNESS = 0.95;
	SPECULAR = 0.05;
}
