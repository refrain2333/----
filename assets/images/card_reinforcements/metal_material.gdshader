
shader_type canvas_item;

uniform vec4 highlight_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// 获取原始颜色
	vec4 color = texture(TEXTURE, UV);
	
	// 添加金属光泽效果
	float highlight = pow(1.0 - abs(UV.y - 0.5) * 2.0, 5.0) * metallic;
	vec3 metal_color = mix(color.rgb, highlight_color.rgb, highlight);
	
	COLOR = vec4(metal_color, color.a);
}
