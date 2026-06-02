shader_type spatial;

uniform float pixel_size = 4.0;
uniform float bubble_speed = 2.0;

void fragment() {
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz * 64.0;
    vec2 uv = floor(world_pos.xz / pixel_size) * pixel_size;
    
    float t = floor(TIME * bubble_speed * 4.0) / 4.0;
    float n1 = sin(uv.x * 0.3 + sin(uv.y * 0.2 + t));
    float n2 = cos(uv.y * 0.25 + cos(uv.x * 0.15 + t * 0.7));
    float n3 = sin((uv.x + uv.y) * 0.2 + t * 0.5);
    float n = (n1 + n2 + n3) / 3.0;
    n = n * 0.5 + 0.5;
    n = floor(n * 4.0) / 4.0;
    
    vec3 dark   = vec3(0.6, 0.05, 0.0);
    vec3 mid    = vec3(0.9, 0.2,  0.0);
    vec3 bright = vec3(1.0, 0.65, 0.0);
    
    vec3 lava_color = n < 0.5 ? mix(dark, mid, n * 2.0) : mix(mid, bright, (n - 0.5) * 2.0);
    
    ALBEDO = lava_color;
    EMISSION = lava_color * 0.9;
}