extends Node2D

# 卡牌文字生成器
# 用于生成带有指定文字的白底黑字卡牌图片

# 卡牌尺寸
const CARD_WIDTH = 105
const CARD_HEIGHT = 150

# 文件保存路径 - 修改为项目目录下的生成文件夹
var save_path = "res://生成/"

# 背景颜色 - 纯灰色
const BACKGROUND_COLOR = Color(0.5, 0.5, 0.5, 1.0)  # 灰色 RGB(128, 128, 128)

# 预加载字体资源
var font: Font

# UI元素引用
var text_input: LineEdit
var font_size_input: SpinBox
var status_label: Label

func _ready():
	# 加载字体，优先使用中文字体
	font = load("res://assets/font/ZCOOL_KuaiLe/ZCOOLKuaiLe-Regular.ttf")
	if font == null:
		font = ThemeDB.fallback_font

	# 确保保存目录存在
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("生成"):
		dir.make_dir("生成")
	
	# 创建UI
	create_ui()
	
	# 显示保存路径信息
	print("文件将保存到: ", ProjectSettings.globalize_path(save_path))

func create_ui():
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(400, 300)
	add_child(vbox)
	
	# 标题标签
	var title_label = Label.new()
	title_label.text = "卡牌文字生成器"
	title_label.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(title_label)
	
	# 输入说明
	var instructions = Label.new()
	instructions.text = "请输入卡牌文字:"
	vbox.add_child(instructions)
	
	# 文本输入框
	text_input = LineEdit.new()
	text_input.placeholder_text = "例如：对子大师"
	text_input.custom_minimum_size = Vector2(300, 30)
	vbox.add_child(text_input)
	
	# 字体大小选择
	var font_size_hbox = HBoxContainer.new()
	vbox.add_child(font_size_hbox)
	
	var font_size_label = Label.new()
	font_size_label.text = "字体大小:"
	font_size_hbox.add_child(font_size_label)
	
	font_size_input = SpinBox.new()
	font_size_input.min_value = 10
	font_size_input.max_value = 72
	font_size_input.value = 20
	font_size_hbox.add_child(font_size_input)
	
	# 间距
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# 生成按钮
	var generate_button = Button.new()
	generate_button.text = "生成卡牌"
	generate_button.custom_minimum_size = Vector2(150, 40)
	generate_button.connect("pressed", _on_generate_button_pressed)
	vbox.add_child(generate_button)
	
	# 状态标签
	status_label = Label.new()
	status_label.text = "准备就绪"
	vbox.add_child(status_label)
	
	# 保存路径标签
	var path_label = Label.new()
	path_label.text = "文件将保存到: " + ProjectSettings.globalize_path(save_path)
	path_label.custom_minimum_size = Vector2(0, 40)
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(path_label)

func _on_generate_button_pressed():
	if text_input == null or font_size_input == null or status_label == null:
		print("找不到必要的UI元素")
		return
	
	var card_text = text_input.text.strip_edges()
	var font_size = int(font_size_input.value)
	
	if card_text.is_empty():
		status_label.text = "错误: 请输入卡牌文字"
		return
	
	var filename = card_text + ".png"
	# 生成图像
	generate_card_image(card_text, font_size, filename)
	status_label.text = "已生成: " + filename

func generate_card_image(text: String, font_size: int, filename: String):
	# 直接创建图像并绘制，不依赖于场景捕获
	var image = Image.create(CARD_WIDTH, CARD_HEIGHT, false, Image.FORMAT_RGBA8)
	
	# 填充灰色背景
	image.fill(BACKGROUND_COLOR)
	
	# 创建一个临时的SubViewport用于绘制
	var viewport = SubViewport.new()
	viewport.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	viewport.transparent_bg = false
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	
	# 创建一个ColorRect作为背景
	var background = ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	viewport.add_child(background)
	
	# 创建Label用于显示文字
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	viewport.add_child(label)
	
	# 等待渲染完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 获取渲染结果
	var result_image = viewport.get_texture().get_image()
	
	# 保存图像
	var save_error = result_image.save_png(save_path + filename)
	
	# 清理临时节点
	viewport.queue_free()
	
	if save_error != OK:
		print("保存图像失败: ", save_error)
	else:
		print("图像保存成功: ", save_path + filename)
		print("完整路径: ", ProjectSettings.globalize_path(save_path + filename))

# 创建一个单独的场景来运行此脚本
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# 清理资源
		if font is Resource and font.get_reference_count() > 0:
			font = null 
