shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.012, 0.045, 0.055);
uniform vec3 shallow_color : source_color = vec3(0.10, 0.28, 0.22);
uniform vec3 reflect_tint : source_color = vec3(0.55, 0.68, 0.85);
uniform float foam_height : hint_range(0.0, 1.0) = 0.65;
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.22;
uniform vec3 sun_dir : source_color = vec3(0.3, 0.9, 0.1);
uniform float night : hint_range(0.0, 1.0) = 0.0;

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

float wave_h(vec2 p, float t) {
	float h = 0.0;
	h += vnoise(p * 0.35 + vec2(t * 0.05, 0.0)) * 1.0;
	h += vnoise(p * 0.9 + vec2(0.0, -t * 0.06)) * 0.45;
	h += vnoise(p * 2.2 + vec2(t * 0.12, 0.5)) * 0.18;
	return h;
}

void vertex() {
	float h = wave_h(VERTEX.xz, TIME);
	VERTEX.y += (h - 0.5) * wave_amplitude;
}

void fragment() {
	vec2 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float t = TIME;
	float e = 0.4;

	float h0 = wave_h(p, t);
	float hx = wave_h(p + vec2(e, 0.0), t);
	float hz = wave_h(p + vec2(0.0, e), t);

	vec3 wn = normalize(vec3((h0 - hx) * 0.9, 0.18, (h0 - hz) * 0.9));
	NORMAL = normalize(mat3(VIEW_MATRIX) * wn);

	float h01 = clamp((h0 - 0.5) * 2.0, -1.0, 1.0);
	vec3 col = mix(deep_color, shallow_color, smoothstep(-0.45, 0.35, h01));
	float foam = smoothstep(foam_height * 1.15, 1.05, h0 * 0.5 + 0.5);
	col = mix(col, vec3(0.92, 0.96, 0.98), foam * 0.75);

	ALBEDO = col;
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;

	float ndv = clamp(dot(NORMAL, normalize(-VIEW)), 0.0, 1.0);
	ALBEDO = mix(ALBEDO, reflect_tint, pow(1.0 - ndv, 3.0) * 0.8);

	vec3 refl = reflect(normalize(-VIEW), NORMAL);
	vec3 sun_view = mat3(INV_VIEW_MATRIX) * normalize(sun_dir);
	float glint = pow(clamp(dot(refl, normalize(sun_view)), 0.0, 1.0), 140.0);
	ALBEDO += vec3(1.0, 0.95, 0.8) * glint * 0.9 * (1.0 - night);
	ALPHA = 0.86;
}
