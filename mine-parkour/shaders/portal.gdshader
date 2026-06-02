shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform float time_speed = 1.0;
uniform float distortion_strength = 0.35;
uniform float swirl_speed = 1.5;
uniform float pixel_size = 64.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		   (c - a) * u.y * (1.0 - u.x) +
		   (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;
	uv = floor(uv * pixel_size) / pixel_size;

	// center UV for radial distortion
	vec2 center = uv - 0.5;

	float t = TIME * time_speed;

	// swirl deformation
	float angle = noise(uv * 3.0 + t) * 6.2831 * 2.0;
	mat2 rot = mat2(
		vec2(cos(angle), -sin(angle)),
		vec2(sin(angle),  cos(angle))
	);

	center = rot * center;

	// wave distortion
	float n = noise(uv * 10.0 + t * swirl_speed);
	center += normalize(center + 0.001) * n * distortion_strength;

	uv = center + 0.5;

	// layered portal color
	float pattern = noise(uv * 8.0 + t);
	float pattern2 = noise(uv * 16.0 - t * 0.5);

	vec3 purple = vec3(0.6, 0.1, 0.9);
	vec3 deep = vec3(0.1, 0.0, 0.2);

	vec3 col = mix(deep, purple, pattern);
	col += pattern2 * vec3(0.2, 0.0, 0.4);

	// emissive intensity boost
	float intensity = 1.5 + pattern * 2.0;

	ALBEDO = col;
	EMISSION = col * intensity;
	ALPHA = 0.5;
}