extends Node

@onready var preview = $Preview

func _ready():
    generate_twist_texture()
    preview_texture()
    await get_tree().create_timer(1.0).timeout
    get_tree().quit()

func generate_twist_texture():
    var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
    image.fill(Color.BLACK)
    
    var center_x = 128.0
    var center_y = 128.0
    var max_radius = 180.0
    var twist_amount = 5.0  # 扭曲强度
    var noise = FastNoiseLite.new()
    noise.frequency = 0.05
    
    for y in range(256):
        for x in range(256):
            var dx = x - center_x
            var dy = y - center_y
            var distance = sqrt(dx * dx + dy * dy)
            var angle = atan2(dy, dx)
            
            # 创建扭曲效果
            var value = 0.0
            if distance <= max_radius:
                # 添加扭曲
                var twist = angle + (distance / max_radius) * twist_amount
                # 添加噪声
                var noise_value = noise.get_noise_2d(x + cos(twist) * 20.0, y + sin(twist) * 20.0)
                value = (1.0 + sin(twist + noise_value * 3.0)) * 0.5
                # 添加距离衰减
                value *= (1.0 - distance / max_radius)
                # 使效果更加清晰
                value = pow(value, 0.7)
            
            var color = Color(value, value, value)
            image.set_pixel(x, y, color)
    
    var save_path = "res://cs/溶解效果/shader_patterns/twist.png"
    var err = image.save_png(save_path)
    if err != OK:
        print("保存扭曲纹理失败！")
    else:
        print("扭曲纹理生成成功！保存在：", save_path)
        return image

func preview_texture():
    var image = generate_twist_texture()
    if image:
        var texture = ImageTexture.create_from_image(image)
        preview.texture = texture 