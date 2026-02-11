shader_type canvas_item;

uniform vec4 mask_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float radius = 0.5;       // normalized radius (0..1)
uniform float softness = 0.1;     // how smooth the edge is
uniform vec2 center = vec2(0.5, 0.5); // center of the mask (UV space)

void fragment() {
    // UV relative to center
    vec2 uv_rel = UV - center;
    
    // distance from center
    float dist = length(uv_rel);
    
    // smooth circular mask
    float alpha = 1.0 - smoothstep(radius - softness, radius, dist);
    
    COLOR = vec4(mask_color.rgb, mask_color.a * alpha);
}
