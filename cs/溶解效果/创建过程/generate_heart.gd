extends Node

@onready var preview = $Preview

func _ready():
    generate_heart_texture()
    preview_texture()
    await get_tree().create_timer(1.0).timeout
    get_tree().quit()

func generate_heart_texture():
    var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
    image.fill(Color.BLACK)
    
    var center_x = 128.0
    var center_y = 128.0
    var scale = 80.0
    
    for y in range(256):
        for x in range(256):
            var px = (x - center_x) / scale
            var py = (y - center_y) / scale
            
            # 心形方程
            var value = pow(px * px + py * py - 1, 3) - px * px * py * py * py
            # 添加一些模糊效果
            value = 1.0 - smoothstep(-0.3, 0.3, value)
            
            # 添加渐变效果
            var distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
            value *= max(0, 1.0 - distance / 180.0)
            
            var color = Color(value, value, value)
            image.set_pixel(x, y, color)
    
    var save_path = "res://cs/溶解效果/shader_patterns/heart.png"
    var err = image.save_png(save_path)
    if err != OK:
        print("保存心形纹理失败！")
    else:
        print("心形纹理生成成功！保存在：", save_path)
        return image

func preview_texture():
    var image = generate_heart_texture()
    if image:
        var texture = ImageTexture.create_from_image(image)
        preview.texture = texture 