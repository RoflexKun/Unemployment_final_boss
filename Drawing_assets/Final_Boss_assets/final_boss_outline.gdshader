shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform bool is_highlighted = false;                             

uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    
    col.rgb = mix(col.rgb, flash_color.rgb, flash_amount * col.a);

    if (!is_highlighted) {
        COLOR = col;
    } 
    else {
        vec2 ps = TEXTURE_PIXEL_SIZE;
        float a;
        a = texture(TEXTURE, UV + vec2(0.0, -outline_width) * ps).a;
        a += texture(TEXTURE, UV + vec2(0.0, outline_width) * ps).a;
        a += texture(TEXTURE, UV + vec2(-outline_width, 0.0) * ps).a;
        a += texture(TEXTURE, UV + vec2(outline_width, 0.0) * ps).a;
        a = min(a, 1.0);
        
        vec4 outline = mix(vec4(0.0), outline_color, a);
        COLOR = mix(outline, col, col.a);
    }
}