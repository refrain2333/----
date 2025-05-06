extends Node

@onready var preview = $Preview

func _ready():
    generate_noise_texture()
    preview_texture()
    await get_tree().create_timer(1.0).timeout
    get_tree().quit()

func generate_noise_texture():
    var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
    image.fill(Color.BLACK)
    
    # 使用简化的柏林噪声算法
    var noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.seed = randi()  # 随机种子
    noise.frequency = 0.03
    
    for y in range(256):
        for x in range(256):
            var noise_value = (noise.get_noise_2d(x, y) + 1.0) * 0.5  # 转换到0-1范围
            var color = Color(noise_value, noise_value, noise_value)
            image.set_pixel(x, y, color)
    
    var save_path = "res://cs/溶解效果/shader_patterns/noise.png"
    var err = image.save_png(save_path)
    if err != OK:
        print("保存噪声纹理失败！")
    else:
        print("噪声纹理生成成功！保存在：", save_path)
        return image

func preview_texture():
    var image = generate_noise_texture()
    if image:
        var texture = ImageTexture.create_from_image(image)
        preview.texture = texture 