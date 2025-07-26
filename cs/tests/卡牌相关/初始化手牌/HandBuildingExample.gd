extends Control

# 手牌构建完整示例
# 演示如何从零开始构建一副完整的手牌

var CardData = preload("res://cs/卡牌系统/数据/CardData.gd")
var CardScene = preload("res://cs/卡牌系统/视图/Card.tscn")
var CardDataManager = preload("res://cs/卡牌系统/数据/管理器/CardDataManager.gd")

@onready var hand_container: HBoxContainer = $VBoxContainer/HandContainer
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var build_button: Button = $VBoxContainer/BuildButton

var hand_cards: Array[CardData] = []
var hand_views: Array[Control] = []

func _ready():
	print("HandBuildingExample: 手牌构建示例开始")
	setup_ui()

func setup_ui():
	info_label.text = "点击按钮构建一副5张牌的手牌"
	build_button.text = "构建手牌"
	build_button.pressed.connect(_on_build_hand_pressed)

func _on_build_hand_pressed():
	print("HandBuildingExample: 开始构建手牌")
	clear_hand()
	build_sample_hand()

func clear_hand():
	# 清理现有手牌
	for view in hand_views:
		if is_instance_valid(view):
			view.queue_free()
	hand_views.clear()
	hand_cards.clear()

func build_sample_hand():
	# 使用预制卡牌数据构建手牌
	var card_manager = CardDataManager.get_instance()

	# 要构建的卡牌ID列表
	var sample_card_ids = ["H3", "S7", "D11"]

	print("HandBuildingExample: 从预制数据构建 %d 张卡牌" % sample_card_ids.size())

	for i in range(sample_card_ids.size()):
		var card_id = sample_card_ids[i]
		create_and_add_card_from_data(card_id, i)

	update_info_display()

func create_and_add_card_from_data(card_id: String, index: int):
	print("HandBuildingExample: 从预制数据创建卡牌 %d - %s" % [index + 1, card_id])

	# 第一步：从预制数据获取卡片
	var card_data = load_card_from_presets(card_id)

	if not card_data:
		print("  ❌ 未找到卡牌数据: %s" % card_id)
		return

	# 第二步：创建卡片视图
	var card_view = create_card_view(card_data)

	# 第三步：添加到手牌容器
	add_card_to_hand(card_data, card_view, index)

func load_card_from_presets(card_id: String) -> CardData:
	"""从预制数据加载卡片"""
	print("  步骤1: 从CardDataManager获取卡片数据")
	var card_manager = CardDataManager.get_instance()
	var card_data = card_manager.get_card(card_id)

	if card_data:
		print("    ✅ 找到卡片: %s" % card_data.name)
		print("    属性: 伤害=%d, 防御=%d, 消耗=%d" % [card_data.damage, card_data.defense, card_data.cost])

		# 克隆数据避免修改原始数据
		return card_data.clone()
	else:
		print("    ❌ 未找到卡片: %s" % card_id)
		return null

func create_card_data(card_info: Dictionary) -> CardData:
	"""
	创建卡片数据的详细步骤
	"""
	print("  步骤1: 创建CardData实例")
	var card_data = CardData.new()
	
	print("  步骤2: 设置基础属性")
	card_data.id = card_info.id
	card_data.base_value = card_info.value
	card_data.suit = card_info.suit
	card_data.name = card_info.name
	
	print("  步骤3: 计算图片路径")
	card_data.image_path = ResourcePaths.get_card_image_path(card_info.id)
	print("    图片路径: %s" % card_data.image_path)
	
	print("  步骤4: 验证数据完整性")
	if validate_card_data(card_data):
		print("    ✅ 卡片数据验证通过")
	else:
		print("    ❌ 卡片数据验证失败")
	
	return card_data

func create_card_view(card_data: CardData) -> Control:
	"""
	创建卡片视图的详细步骤
	"""
	print("  步骤5: 实例化Card场景")
	var card_view = CardScene.instantiate()
	
	if not card_view:
		print("    ❌ 卡片视图创建失败")
		return null
	
	print("  步骤6: 设置卡片数据")
	card_view.setup(card_data)
	
	print("  步骤7: 配置视图属性")
	card_view.scale = Vector2(0.7, 0.7)  # 适合手牌显示的缩放
	card_view.set_draggable(true)        # 启用拖拽
	
	print("  步骤8: 连接信号")
	if card_view.has_signal("card_clicked"):
		card_view.card_clicked.connect(_on_card_clicked)
	
	print("    ✅ 卡片视图创建完成")
	return card_view

func add_card_to_hand(card_data: CardData, card_view: Control, index: int):
	"""
	将卡片添加到手牌的详细步骤
	"""
	print("  步骤9: 添加到数据数组")
	hand_cards.append(card_data)
	
	print("  步骤10: 添加到视图数组")
	hand_views.append(card_view)
	
	print("  步骤11: 添加到UI容器")
	hand_container.add_child(card_view)
	
	print("  步骤12: 设置手牌位置")
	# 手牌扇形排列效果
	var total_cards = hand_cards.size()
	var angle_step = 10.0  # 每张牌之间的角度
	var start_angle = -(total_cards - 1) * angle_step / 2
	var card_angle = start_angle + index * angle_step
	
	# 应用旋转（可选的视觉效果）
	card_view.rotation_degrees = card_angle * 0.3
	
	print("    ✅ 卡片已添加到手牌位置 %d" % index)

func validate_card_data(card_data: CardData) -> bool:
	"""
	验证卡片数据的完整性
	"""
	var issues = []
	
	if card_data.id.is_empty():
		issues.append("ID为空")
	
	if card_data.name.is_empty():
		issues.append("名称为空")
	
	if card_data.suit.is_empty():
		issues.append("花色为空")
	
	if card_data.base_value < 1 or card_data.base_value > 13:
		issues.append("数值超出范围(1-13)")
	
	if card_data.image_path.is_empty():
		issues.append("图片路径为空")
	
	if not ResourceLoader.exists(card_data.image_path):
		issues.append("图片文件不存在")
	
	if issues.size() > 0:
		print("    验证失败: %s" % str(issues))
		return false
	
	return true

func update_info_display():
	"""
	更新信息显示
	"""
	var info_text = "✅ 手牌构建完成！\n"
	info_text += "手牌数量: %d 张\n" % hand_cards.size()
	info_text += "卡牌列表:\n"
	
	for i in range(hand_cards.size()):
		var card = hand_cards[i]
		info_text += "  %d. %s (ID:%s, 值:%d)\n" % [i+1, card.name, card.id, card.base_value]
	
	info_label.text = info_text
	print("HandBuildingExample: 手牌构建完成，共 %d 张卡牌" % hand_cards.size())

func _on_card_clicked(card_view):
	"""
	处理卡片点击事件
	"""
	var card_index = hand_views.find(card_view)
	if card_index >= 0:
		var card_data = hand_cards[card_index]
		print("点击了卡牌: %s (位置:%d)" % [card_data.name, card_index])

func get_hand_summary() -> Dictionary:
	"""
	获取手牌摘要信息
	"""
	return {
		"total_cards": hand_cards.size(),
		"card_names": hand_cards.map(func(card): return card.name),
		"card_values": hand_cards.map(func(card): return card.base_value),
		"suits": hand_cards.map(func(card): return card.suit)
	}
