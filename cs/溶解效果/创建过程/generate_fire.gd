extends Node

@onready var preview = $Preview

func _ready():
    generate_fire_texture()
    preview_texture()
    await get_tree().create_timer(1.0).timeout
    get_tree().quit()

func generate_fire_texture():
    var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
    image.fill(Color.BLACK)
    
    var noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.seed = randi()
    noise.frequency = 0.04
    
    # 第二层噪声用于火焰细节
    var detail_noise = FastNoiseLite.new()
    detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
    detail_noise.seed = randi()
    detail_noise.frequency = 0.1
    
    for y in range(256):
        for x in range(256):
            # 基础渐变，从下到上
            var gradient = 1.0 - (y / 256.0)
            
            # 添加主要噪声
            var main_noise = noise.get_noise_2d(x, y * 1.5) * 0.5 + 0.5
            
            # 添加细节噪声
            var detail = detail_noise.get_noise_2d(x, y * 2.0) * 0.25 + 0.75
            
            # 组合效果
            var value = gradient * main_noise * detail
            
            # 添加火焰形状
            value *= pow(1.0 - (y / 256.0), 0.5)  # 使火焰向上变窄
            
            # 使火焰更亮更锐利
            value = pow(value, 0.7)
            
            var color = Color(value, value, value)
            image.set_pixel(x, y, color)
    
    var save_path = "res://cs/溶解效果/shader_patterns/fire.png"
    var err = image.save_png(save_path)
    if err != OK:
        print("保存火焰纹理失败！")
    else:
        print("火焰纹理生成成功！保存在：", save_path)
        return image

func preview_texture():
    var image = generate_fire_texture()
    if image:
        var texture = ImageTexture.create_from_image(image)
        preview.texture = texture 