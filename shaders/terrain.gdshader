shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform float detail_strength : hint_range(0.0, 1.0) = 0.35;
uniform float water_level : hint_range(-10.0, 30.0) = 0.0;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.0 + 17.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float d = fbm(world_pos.xz * 0.7);
	float big = fbm(world_pos.xz * 0.13 + 7.3);
	vec3 base = COLOR.rgb * (0.80 + 0.30 * d) * (0.9 + 0.2 * big);

	float e = 0.6;
	vec2 p = world_pos.xz;
	float h0 = fbm(p * 1.4);
	float hx = fbm((p + vec2(e, 0.0)) * 1.4);
	float hz = fbm((p + vec2(0.0, e)) * 1.4);

	vec3 wn = normalize(mat3(INV_VIEW_MATRIX) * NORMAL);
	vec3 dn = normalize(vec3((h0 - hx) * e, 1.0, (h0 - hz) * e));
	vec3 wf = normalize(mix(wn, dn, detail_strength));
	NORMAL = normalize(mat3(VIEW_MATRIX) * wf);

	float moss = smoothstep(1.0, 5.0, d);
	base = mix(base, base * vec3(0.85, 1.1, 0.8), moss * 0.35);

	float y = world_pos.y - water_level;
	float wet = smoothstep(0.5, -0.4, y);
	base = mix(base, base * vec3(0.70, 0.78, 0.85), wet * 0.55);
	float sand = smoothstep(2.2, 0.6, y) * (1.0 - wet);
	base = mix(base, base * vec3(1.18, 1.12, 0.92), sand * 0.5);

	float snow = smoothstep(13.5, 17.0, world_pos.y);
	base = mix(base, vec3(0.94, 0.96, 0.98), snow * 0.9);

	float slope = 1.0 - clamp(dn.y, 0.0, 1.0);
	base *= 1.0 - slope * 0.16;

	ALBEDO = base;
	ROUGHNESS = mix(0.92, 0.58, wet * 0.7);
	METALLIC = 0.0;
}
