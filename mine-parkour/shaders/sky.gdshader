shader_type sky;
render_mode use_debanding;

uniform vec4 sky_top_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float inv_sky_curve : hint_range(1, 100) = 4.0;
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float inv_ground_curve : hint_range(1, 100) = 30.0;
uniform float sun_angle_max = 0.877;
uniform float inv_sun_curve : hint_range(1, 100) = 22.78;
uniform float exposure : hint_range(0, 128) = 1.0;
uniform sampler2D sunCurve : repeat_disable;
uniform float sunLayers : hint_range(0, 9999) = 5;
uniform float sunSize : hint_range(0, 1, 0.01) = 0.1;

uniform sampler2D sky_cover : filter_linear, source_color, hint_default_black;
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float get_square_angle(vec3 light_dir, vec3 eye_dir) {
	float z = dot(light_dir, eye_dir);
	if (z <= 0.0) return -1.;
	vec3 right = cross(vec3(0.0, 1.0, 0.0), light_dir);
	if (length(right) < 0.001) {
		right = vec3(1.0, 0.0, 0.0);
	} else {
		right = normalize(right);
	}
	vec3 up = cross(light_dir, right);
	float u = abs(dot(eye_dir, right));
	float v = abs(dot(eye_dir, up));
	float maxV = max(u, v);
	for (float i = 0.; i < sunLayers; i++) {
		if (maxV < i * (sunSize / sunLayers)) {
			return i / sunLayers;
		}
	}
	return -1.;
}

void sky() {
	float v_angle = clamp(EYEDIR.y, -1.0, 1.0);
	vec3 sky = mix(sky_top_color.rgb, sky_horizon_color.rgb, clamp(pow(1.0 - v_angle, inv_sky_curve), 0.0, 1.0));

	if (LIGHT0_ENABLED) {
		float sun_angle = get_square_angle(LIGHT0_DIRECTION, EYEDIR);
		if (sun_angle == 0.) {
			sky = vec3(1.);
		}
		if (sun_angle >= 0.) {
			vec3 sun_color = texture(sunCurve, vec2(sun_angle, 0.)).xyz;
			float sun_size = sin(LIGHT0_SIZE);
			float sun_max = sin(acos(sun_angle_max));
			sky = sun_color;
			//if (sun_angle < 0.) {
				//sky = sun_color * LIGHT0_ENERGY;
			//} else if (sun_angle < sun_max) {
				//float c2 = (sun_angle - sun_size) / (sun_max - sun_size);
				//sky = mix(sky, sun_color * LIGHT0_ENERGY, clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
			//}
		}
	}
	
	
	vec3 ground = mix(ground_bottom_color.rgb, ground_horizon_color.rgb, clamp(pow(1.0 + v_angle, inv_ground_curve), 0.0, 1.0));

	COLOR = mix(ground, sky, step(0.0, EYEDIR.y)) * exposure;
}