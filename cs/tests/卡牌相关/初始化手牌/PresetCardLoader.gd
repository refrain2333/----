extends Control

# 预制卡牌数据加载器
# 从assets/data/cards/目录读取.tres文件创建卡牌

var CardScene = preload("res://cs/卡牌系统/视图/Card.tscn")

@onready var hand_container: HBoxContainer = $VBoxContainer/HandContainer
@onready var info_label: Label = $VBoxContainer/HBoxContainer/RightPanel/InfoLabel
@onready var load_button: Button = $VBoxContainer/HBoxContainer/LeftPanel/LoadButton
@onready var card_list: ItemList = $VBoxContainer/HBoxContainer/LeftPanel/CardList

var available_cards: Array[String] = []  # 可用的卡牌文件列表
var loaded_cards: Array[CardData] = []   # 已加载的卡牌数据
var card_views: Array[Control] = []      # 卡牌视图

func _ready():
	print("PresetCardLoader: 预制卡牌加载器启动")
	setup_ui()
	scan_available_cards()

func setup_ui():
	info_label.text = "从预制数据文件加载卡牌"
	load_button.text = "加载选中卡牌"
	load_button.pressed.connect(_on_load_button_pressed)
	
	# 设置卡牌列表
	card_list.item_selected.connect(_on_card_selected)
	card_list.custom_minimum_size = Vector2(200, 150)

func scan_available_cards():
	"""扫描assets/data/cards/目录下的所有.tres文件"""
	print("PresetCardLoader: 扫描可用卡牌文件...")
	
	var cards_dir = "res://assets/data/cards/"
	var dir = DirAccess.open(cards_dir)
	
	if not dir:
		print("PresetCardLoader: 无法打开卡牌目录: %s" % cards_dir)
		info_label.text = "❌ 无法访问卡牌目录"
		return
	
	available_cards.clear()
	card_list.clear()
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card_path = cards_dir + file_name
			
			# 验证是否为有效的CardData资源
			if _validate_card_file(card_path):
				available_cards.append(card_path)
				
				# 添加到列表显示
				var display_name = file_name.get_basename()  # 去掉.tres扩展名
				card_list.add_item(display_name)
				
				print("  发现卡牌: %s" % display_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("PresetCardLoader: 扫描完成，共发现 %d 张卡牌" % available_cards.size())
	update_info_display()

func _validate_card_file(file_path: String) -> bool:
	"""验证文件是否为有效的CardData资源"""
	if not ResourceLoader.exists(file_path):
		return false
	
	# 尝试加载资源
	var resource = load(file_path)
	if not resource or not resource is CardData:
		print("  警告: %s 不是有效的CardData资源" % file_path)
		return false
	
	return true

func _on_card_selected(index: int):
	"""处理卡牌列表选择事件"""
	if index >= 0 and index < available_cards.size():
		var card_path = available_cards[index]
		var card_name = card_path.get_file().get_basename()
		print("PresetCardLoader: 选中卡牌 - %s" % card_name)

func _on_load_button_pressed():
	"""加载选中的卡牌"""
	var selected_indices = []
	
	# 获取所有选中的项目
	for i in range(card_list.item_count):
		if card_list.is_selected(i):
			selected_indices.append(i)
	
	if selected_indices.size() == 0:
		info_label.text = "❌ 请先选择要加载的卡牌"
		return
	
	print("PresetCardLoader: 开始加载 %d 张卡牌" % selected_indices.size())
	clear_current_hand()
	
	for index in selected_indices:
		load_card_from_file(index)
	
	update_info_display()

func clear_current_hand():
	"""清空当前手牌"""
	for view in card_views:
		if is_instance_valid(view):
			view.queue_free()
	
	card_views.clear()
	loaded_cards.clear()

func load_card_from_file(index: int):
	"""从文件加载单张卡牌"""
	if index < 0 or index >= available_cards.size():
		print("PresetCardLoader: 无效的卡牌索引 - %d" % index)
		return
	
	var card_path = available_cards[index]
	var card_name = card_path.get_file().get_basename()
	
	print("PresetCardLoader: 加载卡牌文件 - %s" % card_path)
	
	# 步骤1: 从文件加载CardData
	var card_data = load_card_data(card_path)
	if not card_data:
		print("  ❌ 加载失败")
		return
	
	# 步骤2: 创建卡牌视图
	var card_view = create_card_view(card_data)
	if not card_view:
		print("  ❌ 视图创建失败")
		return
	
	# 步骤3: 添加到手牌
	add_to_hand(card_data, card_view)
	
	print("  ✅ 卡牌加载成功: %s" % card_data.name)

func load_card_data(file_path: String) -> CardData:
	"""从文件加载CardData"""
	print("  步骤1: 从文件加载数据 - %s" % file_path)
	
	var card_data = load(file_path) as CardData
	if not card_data:
		print("    ❌ 无法加载CardData资源")
		return null
	
	# 验证数据完整性
	if not validate_card_data(card_data):
		print("    ❌ 卡牌数据验证失败")
		return null
	
	print("    ✅ 数据加载成功")
	print("      ID: %s" % card_data.id)
	print("      名称: %s" % card_data.name)
	print("      数值: %d" % card_data.base_value)
	print("      花色: %s" % card_data.suit)
	print("      图片: %s" % card_data.image_path)
	
	return card_data

func validate_card_data(card_data: CardData) -> bool:
	"""验证卡牌数据的完整性"""
	var issues = []
	
	if card_data.id.is_empty():
		issues.append("ID为空")
	
	if card_data.name.is_empty():
		issues.append("名称为空")
	
	if card_data.suit.is_empty():
		issues.append("花色为空")
	
	if card_data.base_value <= 0:
		issues.append("数值无效")
	
	if card_data.image_path.is_empty():
		issues.append("图片路径为空")
	elif not ResourceLoader.exists(card_data.image_path):
		issues.append("图片文件不存在: " + card_data.image_path)
	
	if issues.size() > 0:
		print("    验证失败: %s" % str(issues))
		return false
	
	return true

func create_card_view(card_data: CardData) -> Control:
	"""创建卡牌视图"""
	print("  步骤2: 创建卡牌视图")
	
	var card_view = CardScene.instantiate()
	if not card_view:
		print("    ❌ 无法实例化Card场景")
		return null
	
	# 设置卡牌数据
	card_view.setup(card_data)
	
	# 配置视图属性
	card_view.scale = Vector2(0.7, 0.7)
	card_view.set_draggable(true)
	
	# 连接信号
	if card_view.has_signal("card_clicked"):
		card_view.card_clicked.connect(_on_card_clicked)
	
	print("    ✅ 视图创建成功")
	return card_view

func add_to_hand(card_data: CardData, card_view: Control):
	"""添加到手牌"""
	print("  步骤3: 添加到手牌")
	
	# 添加到数据数组
	loaded_cards.append(card_data)
	card_views.append(card_view)
	
	# 添加到UI容器
	hand_container.add_child(card_view)
	
	# 设置位置（简单的线性排列）
	var index = card_views.size() - 1
	card_view.position.x = index * 20  # 轻微重叠效果
	
	print("    ✅ 添加完成，当前手牌: %d 张" % loaded_cards.size())

func _on_card_clicked(card_view):
	"""处理卡牌点击事件"""
	var index = card_views.find(card_view)
	if index >= 0:
		var card_data = loaded_cards[index]
		print("点击了卡牌: %s (数值:%d)" % [card_data.name, card_data.base_value])
		
		# 显示卡牌详细信息
		show_card_details(card_data)

func show_card_details(card_data: CardData):
	"""显示卡牌详细信息"""
	var details = "=== 卡牌详情 ===\n"
	details += "名称: %s\n" % card_data.name
	details += "ID: %s\n" % card_data.id
	details += "数值: %d\n" % card_data.base_value
	details += "花色: %s\n" % card_data.suit
	
	if card_data.wax_seals.size() > 0:
		details += "蜡封: %s\n" % str(card_data.wax_seals)
	if card_data.frame_type != "":
		details += "牌框: %s\n" % card_data.frame_type
	if card_data.material_type != "":
		details += "材质: %s\n" % card_data.material_type
	
	info_label.text = details

func update_info_display():
	"""更新信息显示"""
	if loaded_cards.size() == 0:
		info_label.text = "可用卡牌: %d 张\n点击列表选择要加载的卡牌" % available_cards.size()
	else:
		var info = "✅ 已加载 %d 张卡牌:\n" % loaded_cards.size()
		for card in loaded_cards:
			info += "• %s (数值:%d)\n" % [card.name, card.base_value]
		info_label.text = info

func get_loaded_cards_summary() -> Dictionary:
	"""获取已加载卡牌的摘要"""
	return {
		"total_count": loaded_cards.size(),
		"cards": loaded_cards.map(func(card): return {
			"id": card.id,
			"name": card.name,
			"value": card.base_value,
			"suit": card.suit
		})
	}
