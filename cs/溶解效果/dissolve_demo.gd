# scene_transition.gd

extends Node2D

# 定义所有可用的溶解模式
enum DissolvePattern {
	CIRCLE,
	RADIAL,
	SQUARES,
	SCRIBBLES,
	HORIZONTAL,
	VERTICAL,
	DIAGONAL,
	CURTAINS,
	LIQUID,     # 新增液体效果
	RIPPLE,     # 新增波纹效果
	NOISE,      # 新增噪声效果
	HEART,      # 新增心形效果
	SPIRAL,     # 新增螺旋效果
	TWIST,      # 新增扭曲效果
	FIRE        # 新增火焰效果
}

var dissolve_materials = {}
var active_tweens = {}

func _ready():
	# 连接所有按钮信号
	var buttons = {
		"CircleButton": DissolvePattern.CIRCLE,
		"RadialButton": DissolvePattern.RADIAL,
		"SquaresButton": DissolvePattern.SQUARES,
		"ScribblesButton": DissolvePattern.SCRIBBLES,
		"HorizontalButton": DissolvePattern.HORIZONTAL,
		"VerticalButton": DissolvePattern.VERTICAL,
		"DiagonalButton": DissolvePattern.DIAGONAL,
		"CurtainsButton": DissolvePattern.CURTAINS,
		"LiquidButton": DissolvePattern.LIQUID,
		"RippleButton": DissolvePattern.RIPPLE,
		"NoiseButton": DissolvePattern.NOISE,
		"HeartButton": DissolvePattern.HEART,
		"SpiralButton": DissolvePattern.SPIRAL,
		"TwistButton": DissolvePattern.TWIST,
		"FireButton": DissolvePattern.FIRE
	}
	
	for button_name in buttons:
		var button = find_button(button_name)
		if button:
			button.pressed.connect(_on_button_pressed.bind(buttons[button_name]))
	
	# 初始化所有精灵的材质
	setup_all_sprites()

func find_button(button_name: String) -> Button:
	var row = "Row1"
	if button_name in ["CircleButton", "RadialButton", "SquaresButton", "ScribblesButton"]:
		row = "Row1"
	elif button_name in ["HorizontalButton", "VerticalButton", "DiagonalButton", "CurtainsButton"]:
		row = "Row2"
	elif button_name in ["LiquidButton", "RippleButton", "NoiseButton", "HeartButton"]:
		row = "Row3"
	else:
		row = "Row4"  # 新的按钮行
	return $MainContainer/ButtonsContainer.get_node(row).get_node(button_name)

func setup_all_sprites():
	for sprite in $MainContainer/SpritesContainer.get_children():
		setup_sprite_material(sprite)

func setup_sprite_material(sprite: TextureRect):
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://cs/溶解效果/着色器/Dissolve2d.gdshader")
	shader_material.set_shader_parameter("dissolve_amount", 0.0)
	shader_material.set_shader_parameter("fade_color", Color(1, 1, 1, 1))
	sprite.material = shader_material

func _get_pattern_path(pattern: DissolvePattern) -> String:
	var base_path = "res://cs/溶解效果/shader_patterns/"
	match pattern:
		DissolvePattern.CIRCLE: return base_path + "circle.png"
		DissolvePattern.RADIAL: return base_path + "radial.png"
		DissolvePattern.SQUARES: return base_path + "squares.png"
		DissolvePattern.SCRIBBLES: return base_path + "scribbles.png"
		DissolvePattern.HORIZONTAL: return base_path + "horizontal.png"
		DissolvePattern.VERTICAL: return base_path + "vertical.png"
		DissolvePattern.DIAGONAL: return base_path + "diagonal.png"
		DissolvePattern.CURTAINS: return base_path + "curtains.png"
		DissolvePattern.LIQUID: return base_path + "液体_看图王.png"
		DissolvePattern.RIPPLE: return base_path + "ripple.png"
		DissolvePattern.NOISE: return base_path + "noise.png"
		DissolvePattern.HEART: return base_path + "heart.png"
		DissolvePattern.SPIRAL: return base_path + "spiral.png"
		DissolvePattern.TWIST: return base_path + "twist.png"
		DissolvePattern.FIRE: return base_path + "fire.png"
		_: return base_path + "circle.png"

func _on_button_pressed(pattern: DissolvePattern):
	var sprite = get_sprite_for_pattern(pattern)
	if sprite:
		start_dissolve_effect(sprite, pattern)

func get_sprite_for_pattern(pattern: DissolvePattern) -> TextureRect:
	var index = pattern as int
	if index >= 0 and index < $MainContainer/SpritesContainer.get_child_count():
		return $MainContainer/SpritesContainer.get_child(index)
	return null

func start_dissolve_effect(sprite: TextureRect, pattern: DissolvePattern):
	# 如果已经有正在进行的动画，先停止它
	if sprite in active_tweens:
		active_tweens[sprite].kill()
	
	# 设置溶解纹理
	var pattern_texture = load(_get_pattern_path(pattern))
	sprite.material.set_shader_parameter("dissolve_texture", pattern_texture)
	
	# 创建溶解动画序列
	var tween = create_tween()
	# 先溶解消失
	tween.tween_method(
		func(value: float): sprite.material.set_shader_parameter("dissolve_amount", value),
		0.0,  # 从0开始（完全显示）
		1.0,  # 到1（完全溶解）
		1.0   # 持续1秒
	)
	# 等待一小段时间
	tween.tween_interval(0.2)
	# 然后重新显示
	tween.tween_method(
		func(value: float): sprite.material.set_shader_parameter("dissolve_amount", value),
		1.0,  # 从1开始（完全溶解）
		0.0,  # 到0（完全显示）
		1.0   # 持续1秒
	)
	active_tweens[sprite] = tween
