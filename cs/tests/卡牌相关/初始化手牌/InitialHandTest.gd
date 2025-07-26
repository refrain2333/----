extends Control

# 初始化手牌测试 - 创建红桃3卡片
# 这个测试用于验证卡片的成功建立和显示

var CardData = preload("res://cs/卡牌系统/数据/CardData.gd")
var CardScene = preload("res://cs/卡牌系统/视图/Card.tscn")
var ResourcePaths = preload("res://cs/卡牌系统/视图/ResourcePaths.gd")

@onready var card_container: Control = $VBoxContainer/CardContainer
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var create_button: Button = $VBoxContainer/CreateButton

var created_card_data: CardData
var created_card_view: Control

func _ready():
	print("InitialHandTest: 初始化手牌测试开始")
	
	# 设置UI
	setup_ui()
	
	# 自动创建红桃3
	create_heart_3_card()

func setup_ui():
	# 设置信息标签
	info_label.text = "正在创建红桃3卡片..."
	
	# 设置按钮
	create_button.text = "重新创建红桃3"
	create_button.pressed.connect(_on_create_button_pressed)
	
	# 设置卡片容器 - 扩大容器以容纳更大的卡片
	card_container.custom_minimum_size = Vector2(200, 280)

func create_heart_3_card():
	print("InitialHandTest: 开始创建红桃3卡片")
	
	# 清理之前的卡片
	if created_card_view:
		created_card_view.queue_free()
		created_card_view = null
	
	# 创建红桃3的卡片数据
	created_card_data = CardData.new()
	created_card_data.id = "H3"
	created_card_data.base_value = 3
	created_card_data.suit = "hearts"
	created_card_data.name = "红桃3"
	# 使用ResourcePaths计算正确的图片路径
	created_card_data.image_path = ResourcePaths.get_card_image_path("H3")
	
	print("InitialHandTest: 卡片数据创建完成")
	print("  - ID: %s" % created_card_data.id)
	print("  - 名称: %s" % created_card_data.name)
	print("  - 花色: %s" % created_card_data.suit)
	print("  - 数值: %d" % created_card_data.base_value)
	print("  - 图片路径: %s" % created_card_data.image_path)
	
	# 创建卡片视图
	if CardScene:
		created_card_view = CardScene.instantiate()
		if created_card_view:
			# 添加到容器
			card_container.add_child(created_card_view)

			# 设置卡片数据
			if created_card_view.has_method("setup"):
				created_card_view.setup(created_card_data)
				print("InitialHandTest: 卡片视图设置完成")
			else:
				print("InitialHandTest: 警告 - 卡片视图没有setup方法")

			# 调整卡片大小
			created_card_view.scale = Vector2(0.8, 0.8)  # 缩放到80%，更大更清晰

			# 使用锚点居中显示卡片
			created_card_view.anchor_left = 0.5
			created_card_view.anchor_top = 0.5
			created_card_view.anchor_right = 0.5
			created_card_view.anchor_bottom = 0.5
			created_card_view.offset_left = -created_card_view.size.x * 0.4  # 考虑缩放的一半
			created_card_view.offset_top = -created_card_view.size.y * 0.4
			created_card_view.offset_right = created_card_view.size.x * 0.4
			created_card_view.offset_bottom = created_card_view.size.y * 0.4

			# 禁用拖拽功能（测试用）
			if created_card_view.has_method("set_draggable"):
				created_card_view.set_draggable(false)

			# 更新信息标签
			info_label.text = "✅ 红桃3卡片创建成功！\n" + created_card_data.get_info()

			print("InitialHandTest: 红桃3卡片创建并显示成功")
		else:
			print("InitialHandTest: 错误 - 无法实例化卡片视图")
			info_label.text = "❌ 卡片视图创建失败"
	else:
		print("InitialHandTest: 错误 - 无法加载Card场景")
		info_label.text = "❌ 无法加载Card场景"

func _on_create_button_pressed():
	print("InitialHandTest: 重新创建红桃3卡片")
	create_heart_3_card()

# 验证卡片数据的完整性
func validate_card_data() -> bool:
	if not created_card_data:
		print("InitialHandTest: 验证失败 - 卡片数据为空")
		return false
	
	var validation_results = []
	
	# 检查基础字段
	if created_card_data.id.is_empty():
		validation_results.append("ID为空")
	
	if created_card_data.name.is_empty():
		validation_results.append("名称为空")
	
	if created_card_data.suit.is_empty():
		validation_results.append("花色为空")
	
	if created_card_data.base_value <= 0:
		validation_results.append("数值无效")
	
	if created_card_data.image_path.is_empty():
		validation_results.append("图片路径为空")
	
	# 检查红桃3的特定值
	if created_card_data.id != "H3":
		validation_results.append("ID不是H3")
	
	if created_card_data.suit != "hearts":
		validation_results.append("花色不是hearts")
	
	if created_card_data.base_value != 3:
		validation_results.append("数值不是3")
	
	if validation_results.size() > 0:
		print("InitialHandTest: 验证失败 - " + str(validation_results))
		return false
	
	print("InitialHandTest: 卡片数据验证通过")
	return true

# 获取测试结果
func get_test_result() -> Dictionary:
	var result = {
		"success": false,
		"card_data_valid": false,
		"card_view_created": false,
		"message": ""
	}
	
	# 验证卡片数据
	result.card_data_valid = validate_card_data()
	
	# 验证卡片视图
	result.card_view_created = (created_card_view != null and is_instance_valid(created_card_view))
	
	# 综合判断
	result.success = result.card_data_valid and result.card_view_created
	
	if result.success:
		result.message = "红桃3卡片创建成功！所有验证通过。"
	else:
		var issues = []
		if not result.card_data_valid:
			issues.append("卡片数据无效")
		if not result.card_view_created:
			issues.append("卡片视图未创建")
		result.message = "创建失败：" + str(issues)
	
	return result
