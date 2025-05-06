extends Node

@onready var preview = $Preview

func _ready():
	generate_ripple_texture()
	preview_texture()
	await get_tree().create_timer(1.0).timeout  # 等待1秒查看预览
	get_tree().quit()  # 生成完成后自动退出

func generate_ripple_texture():
	var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	
	var center_x = 128.0
	var center_y = 128.0
	var max_radius = 180.0  # 最大波纹半径
	var wave_count = 5.0    # 波纹数量
	
	# 生成同心圆波纹
	for y in range(256):
		for x in range(256):
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			
			# 创建多重波纹效果
			var value = 0.0
			if distance <= max_radius:
				# 使用正弦函数创建波纹
				value = (1.0 + sin(distance * wave_count * PI / max_radius)) * 0.5
				# 添加距离衰减
				value *= (1.0 - distance / max_radius)
				# 使波纹更加清晰
				value = pow(value, 0.7)
			
			var color = Color(value, value, value)
			image.set_pixel(x, y, color)
	
	# 保存图片
	var save_path = "res://cs/溶解效果/shader_patterns/ripple.png"
	var err = image.save_png(save_path)
	if err != OK:
		print("保存波纹纹理失败！")
	else:
		print("波纹纹理生成成功！保存在：", save_path)
		return image

func preview_texture():
	var image = generate_ripple_texture()
	if image:
		var texture = ImageTexture.create_from_image(image)
		preview.texture = texture 
