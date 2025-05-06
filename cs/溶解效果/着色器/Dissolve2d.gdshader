shader_type canvas_item;

uniform sampler2D dissolve_texture;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool fade = false;
uniform bool inverted = false;
uniform float edge_width : hint_range(0.0, 0.1) = 0.05; // 新增参数：过渡边缘宽度

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    if (dissolve_amount < 0.0001 || dissolve_amount > 0.9999 || fade) {
        COLOR = original_color;
    } else {
        float sample = texture(dissolve_texture, UV).r;
        if (inverted) {
            sample = 1.0 - sample;
        }
        // 使用 smoothstep 实现平滑过渡
        float edge0 = dissolve_amount - edge_width; // 渐变开始边界
        float edge1 = dissolve_amount + edge_width; // 渐变结束边界
        float alpha_factor = smoothstep(edge0, edge1, sample);
        COLOR = vec4(original_color.rgb, alpha_factor * original_color.a);
    }
}
