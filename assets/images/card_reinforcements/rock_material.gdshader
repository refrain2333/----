
shader_type canvas_item;

uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform vec4 tint_color : source_color = vec4(0.7, 0.7, 0.7, 1.0);

void fragment() {
	// 获取原始颜色
	vec4 color = texture(TEXTURE, UV);
	
	// 添加岩石纹理效果
	float noise = fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 rock_effect = mix(color.rgb, tint_color.rgb, roughness * noise * 0.2);
	
	COLOR = vec4(rock_effect, color.a);
}
