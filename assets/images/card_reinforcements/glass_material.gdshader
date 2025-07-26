
shader_type canvas_item;

uniform float transparency : hint_range(0.0, 1.0) = 0.7;
uniform float refraction : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	// 获取原始颜色
	vec4 color = texture(TEXTURE, UV);
	
	// 添加半透明效果
	color.a *= transparency;
	
	// 添加轻微扭曲效果模拟光线折射
	vec2 distortion = vec2(sin(UV.y * 20.0) * refraction, cos(UV.x * 20.0) * refraction);
	color.rgb = texture(TEXTURE, UV + distortion).rgb;
	
	COLOR = color;
}
