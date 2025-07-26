@tool
extends Node

# 该工具用于生成卡牌强化系统所需的资源
# 包括：蜡封图标、牌框图像和材质着色器

const OUTPUT_PATH = "res://assets/images/card_reinforcements/"
const SEAL_SIZE = Vector2(64, 64)
const FRAME_SIZE = Vector2(105, 150) # 与卡牌尺寸一致

# 蜡封颜色
const WAX_COLORS = {
	"RED": Color(0.9, 0.2, 0.2),
	"BLUE": Color(0.2, 0.4, 0.9),
	"PURPLE": Color(0.6, 0.2, 0.8),
	"GOLD": Color(1.0, 0.8, 0.2),
	"GREEN": Color(0.2, 0.8, 0.4),
	"ORANGE": Color(1.0, 0.6, 0.2),
	"BROWN": Color(0.6, 0.4, 0.2),
	"WHITE": Color(0.9, 0.9, 0.9)
}

# 牌框颜色
const FRAME_COLORS = {
	"STONE": Color(0.5, 0.5, 0.5),  # 更灰色的石质
	"SILVER": Color(0.9, 0.9, 1.0),  # 更亮的银质
	"GOLD": Color(1.0, 0.8, 0.2)
}

func _ready():
	# 在编辑器中运行时才执行
	if Engine.is_editor_hint():
		generate_all_resources()

# 生成所有资源
func generate_all_resources():
	# 创建输出目录
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(OUTPUT_PATH):
		dir.make_dir_recursive(OUTPUT_PATH)
	
	# 生成蜡封图标
	for seal_name in WAX_COLORS:
		generate_wax_seal(seal_name, WAX_COLORS[seal_name])
	
	# 生成牌框
	for frame_name in FRAME_COLORS:
		generate_card_frame(frame_name, FRAME_COLORS[frame_name])
	
	# 生成着色器
	generate_all_shaders()
	
	print("所有强化资源已生成到: ", OUTPUT_PATH)

# 生成蜡封图标
func generate_wax_seal(seal_name: String, color: Color):
	var image = Image.create(SEAL_SIZE.x, SEAL_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	var center = SEAL_SIZE / 2
	var radius = min(center.x, center.y) * 0.8
	
	# 绘制圆形蜡封
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius:
				# 主体颜色
				var alpha = 1.0
				var pixel_color = color
				
				# 添加一些纹理变化
				var noise_factor = sin(x * 0.2) * cos(y * 0.2) * 0.15
				pixel_color = pixel_color.lerp(Color(1, 1, 1, 1), noise_factor)
				
				# 边缘淡化
				if dist > radius * 0.85:
					alpha = 1.0 - (dist - radius * 0.85) / (radius * 0.15)
				
				pixel_color.a = alpha
				image.set_pixel(x, y, pixel_color)
	
	# 添加蜡封图案
	var pattern_radius = radius * 0.5
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= pattern_radius:
				# 在中心添加一个简单的图案
				var angle = pos.angle_to_point(center)
				var pattern_val = (sin(angle * 8) * 0.5 + 0.5) * 0.3
				
				var current = image.get_pixel(x, y)
				var pattern_color = current.lerp(Color(1, 1, 1, current.a), pattern_val)
				image.set_pixel(x, y, pattern_color)
	
	# 保存图像
	var file_path = OUTPUT_PATH + "wax_seal_" + seal_name.to_lower() + ".png"
	image.save_png(file_path)
	print("已保存蜡封图标: ", file_path)

# 生成牌框
func generate_card_frame(frame_name: String, color: Color):
	var image = Image.create(FRAME_SIZE.x, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	var border_width = 4  # 边框宽度
	var corner_radius = 8  # 圆角半径
	
	# 绘制边框
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			# 检查是否在边框区域内
			var is_border = (
				x < border_width or 
				y < border_width or 
				x >= image.get_width() - border_width or 
				y >= image.get_height() - border_width
			)
			
			if is_border:
				# 处理圆角
				var corner_check = true
				if x < corner_radius and y < corner_radius:
					# 左上角
					if Vector2(corner_radius, corner_radius).distance_to(Vector2(x, y)) > corner_radius:
						corner_check = false
				elif x >= image.get_width() - corner_radius and y < corner_radius:
					# 右上角
					if Vector2(image.get_width() - corner_radius, corner_radius).distance_to(Vector2(x, y)) > corner_radius:
						corner_check = false
				elif x < corner_radius and y >= image.get_height() - corner_radius:
					# 左下角
					if Vector2(corner_radius, image.get_height() - corner_radius).distance_to(Vector2(x, y)) > corner_radius:
						corner_check = false
				elif x >= image.get_width() - corner_radius and y >= image.get_height() - corner_radius:
					# 右下角
					if Vector2(image.get_width() - corner_radius, image.get_height() - corner_radius).distance_to(Vector2(x, y)) > corner_radius:
						corner_check = false
						
				if corner_check:
					# 添加纹理和亮度变化
					var pixel_color = color
					var noise_factor = sin(x * 0.1) * cos(y * 0.1) * 0.2
					
					# 边缘发光效果
					var edge_glow = 0.0
					if x < 2*border_width or y < 2*border_width or x >= image.get_width() - 2*border_width or y >= image.get_height() - 2*border_width:
						edge_glow = 0.3
						
					pixel_color = pixel_color.lerp(Color(1, 1, 1, 1), noise_factor + edge_glow)
					
					# 根据牌框类型添加特殊效果
					match frame_name:
						"STONE":
							# 增强石纹效果，更多纹理和更深的暗部
							var stone_texture = fmod(sin(x * 0.4) * sin(y * 0.4) * cos(x * 0.2 + y * 0.1), 0.25)
							# 随机添加更粗糙的纹理
							var stone_roughness = fmod(abs(sin(x * 1.5) * cos(y * 1.2)), 0.15)
							pixel_color = pixel_color.darkened(stone_texture + stone_roughness)
							
							# 添加更明显的暗色斑点
							if randf() > 0.97:
								pixel_color = pixel_color.darkened(0.2)
						"SILVER":
							# 增强银质闪耀效果
							var angle = atan2(float(y - image.get_height()/2), float(x - image.get_width()/2))
							# 更明显的放射状闪光
							var silver_shine = pow(sin(angle * 8.0 + x * 0.1), 2) * 0.4
							# 增加随机闪耀点
							var sparkle = 0.0
							if randf() > 0.98:
								sparkle = 0.5
							pixel_color = pixel_color.lightened(silver_shine + sparkle)
						"GOLD":
							# 添加金纹
							var gold_shine = pow(sin(x * 0.1) * cos(y * 0.1), 2) * 0.3
							pixel_color = pixel_color.lightened(gold_shine)
					
					image.set_pixel(x, y, pixel_color)
	
	# 保存图像
	var file_path = OUTPUT_PATH + "frame_" + frame_name.to_lower() + ".png"
	image.save_png(file_path)
	print("已保存牌框: ", file_path)

# 生成所有着色器
func generate_all_shaders():
	# 玻璃材质
	var glass_shader = """
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
"""
	
	# 岩石材质
	var rock_shader = """
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
"""
	
	# 金属材质
	var metal_shader = """
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
"""
	
	# 保存着色器文件
	save_shader_file("glass_material.gdshader", glass_shader)
	save_shader_file("rock_material.gdshader", rock_shader)
	save_shader_file("metal_material.gdshader", metal_shader)

# 保存着色器文件
func save_shader_file(file_name: String, shader_code: String):
	var file_path = OUTPUT_PATH + file_name
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(shader_code)
		file.close()
		print("已保存着色器: ", file_path)
	else:
		push_error("无法保存着色器: " + file_path)

# 编辑器插件部分
func _get_plugin_name():
	return "卡牌强化资源生成器"

func _get_plugin_icon():
	return null 
