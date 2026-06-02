shader_type canvas_item;

uniform vec2 crosshair_size = vec2(10.0, 2.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 pixel = (UV - vec2(0.5)) / SCREEN_PIXEL_SIZE;
    
    float half_len = crosshair_size.x;
    float half_thick = crosshair_size.y / 2.0;
    
    bool on_h = abs(pixel.y) <= half_thick && abs(pixel.x) <= half_len;
    bool on_v = abs(pixel.x) <= half_thick && abs(pixel.y) <= half_len;
    
    if (on_h || on_v) {
        vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
        COLOR = vec4(1.0 - screen.rgb, 1.0);  // invert screen color
    } else {
        discard;
    }
}