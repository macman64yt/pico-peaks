shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec3 sun_dir = vec3(-0.45, 0.35, -0.3);
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_scale : hint_range(0.0, 5.0) = 1.5;
uniform float wind_speed : hint_range(0.0, 0.05) = 0.006;
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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + 31.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 d = normalize(world_pos - CAMERA_POSITION_WORLD);
	vec2 u = d.xz / (d.y + 0.22);

	float t = TIME * wind_speed;
	float n = fbm(u * cloud_scale + vec2(t, t * 0.6));
	float dens = smoothstep(coverage, 1.0, n);
	float alpha = dens * smoothstep(-0.03, 0.22, d.y);

	float light = clamp(dot(d, normalize(sun_dir)), 0.0, 1.0);
	vec3 day = vec3(0.78, 0.83, 0.92);
	vec3 sunlit = vec3(0.97, 0.88, 0.68);
	vec3 col = mix(day, sunlit, pow(light, 2.0) * 0.85 + light * 0.15);

	ALBEDO = col * (0.40 + 0.50 * light) * mix(1.0, 0.30, night);
	ALPHA = alpha * mix(0.95, 0.55, night);
}
