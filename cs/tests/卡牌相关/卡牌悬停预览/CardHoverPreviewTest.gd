extends Control

# 卡牌悬停预览功能测试场景
# 用于测试和演示卡牌的悬停信息预览功能

# UI组件引用
@onready var cards_container: HBoxContainer = $VBoxContainer/CardsContainer
@onready var settings_panel: VBoxContainer = $VBoxContainer/SettingsPanel
@onready var delay_slider: HSlider = $VBoxContainer/SettingsPanel/DelayContainer/DelaySlider
@onready var delay_value_label: Label = $VBoxContainer/SettingsPanel/DelayContainer/DelayValueLabel
@onready var preview_toggle: CheckBox = $VBoxContainer/SettingsPanel/PreviewToggle

# 测试卡牌数组
var test_cards: Array[CardView] = []

# 预制卡牌数据路径
var test_card_files = [
	"res://assets/data/cards/C1.tres",  # 梅花A
	"res://assets/data/cards/H3.tres",  # 红桃3
	"res://assets/data/cards/S7.tres",  # 黑桃7
	"res://assets/data/cards/D11.tres", # 方片J
	"res://assets/data/cards/H13.tres"  # 红桃K
]

func _ready():
	print("=== 卡牌悬停预览功能测试 ===")
	
	# 初始化UI
	_setup_ui()
	
	# 创建测试卡牌
	_create_test_cards()

# 设置UI组件
func _setup_ui():
	# 设置延时滑块
	if delay_slider:
		delay_slider.min_value = 0.1
		delay_slider.max_value = 2.0
		delay_slider.step = 0.1
		delay_slider.value = 0.8
		delay_slider.value_changed.connect(_on_delay_changed)
		_update_delay_label(0.8)
	
	# 设置预览开关
	if preview_toggle:
		preview_toggle.button_pressed = true
		preview_toggle.toggled.connect(_on_preview_toggled)

# 创建测试卡牌
func _create_test_cards():
	print("开始创建测试卡牌...")
	
	for i in range(test_card_files.size()):
		var card_path = test_card_files[i]
		_create_card_from_file(card_path, i)
	
	print("测试卡牌创建完成，共 %d 张" % test_cards.size())

# 从文件创建单张卡牌
func _create_card_from_file(file_path: String, index: int):
	print("加载卡牌文件: %s" % file_path)
	
	# 步骤1: 验证文件存在
	if not ResourceLoader.exists(file_path):
		print("❌ 文件不存在: %s" % file_path)
		return
	
	# 步骤2: 加载卡牌数据
	var card_data = load(file_path) as CardData
	if not card_data:
		print("❌ 无法加载CardData: %s" % file_path)
		return
	
	# 步骤3: 创建卡牌视图
	var card_view = _create_card_view(card_data)
	if not card_view:
		print("❌ 卡牌视图创建失败")
		return
	
	# 步骤4: 添加到容器
	if cards_container:
		cards_container.add_child(card_view)
		test_cards.append(card_view)

		# HBoxContainer会自动处理间距，不需要手动设置position
	
	print("✅ 卡牌创建成功: %s" % card_data.name)

# 创建卡牌视图
func _create_card_view(card_data: CardData) -> CardView:
	# 加载卡牌场景
	var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")
	var card_view = card_scene.instantiate() as CardView
	
	if not card_view:
		print("❌ 无法实例化Card场景")
		return null
	
	# 设置卡牌数据
	card_view.setup(card_data)
	
	# 连接信号用于测试反馈
	card_view.card_hovered.connect(_on_card_hovered)
	card_view.card_unhovered.connect(_on_card_unhovered)
	card_view.card_clicked.connect(_on_card_clicked)
	
	return card_view



# 延时滑块值改变
func _on_delay_changed(value: float):
	_update_delay_label(value)
	
	# 更新所有卡牌的悬停延时
	for card in test_cards:
		if card and is_instance_valid(card):
			card.set_hover_delay(value)

# 更新延时标签
func _update_delay_label(value: float):
	if delay_value_label:
		delay_value_label.text = "%.1f秒" % value

# 预览功能开关切换
func _on_preview_toggled(enabled: bool):
	print("预览功能 %s" % ("启用" if enabled else "禁用"))
	
	# 更新所有卡牌的预览功能状态
	for card in test_cards:
		if card and is_instance_valid(card):
			card.set_preview_enabled(enabled)

# 卡牌悬停事件
func _on_card_hovered(card_view: CardView):
	var card_data = card_view.get_card_data()
	if card_data:
		print("🖱️ 鼠标悬停: %s" % card_data.name)

# 卡牌取消悬停事件
func _on_card_unhovered(card_view: CardView):
	var card_data = card_view.get_card_data()
	if card_data:
		print("🖱️ 鼠标离开: %s" % card_data.name)

# 卡牌点击事件
func _on_card_clicked(card_view: CardView):
	var card_data = card_view.get_card_data()
	if card_data:
		print("🖱️ 卡牌点击: %s" % card_data.name)
		
		# 显示卡牌详细信息
		_show_card_details(card_data)

# 显示卡牌详细信息（用于调试）
func _show_card_details(card_data: CardData):
	print("\n=== 卡牌详细信息 ===")
	print("ID: %s" % card_data.id)
	print("名称: %s" % card_data.name)
	print("基础数值: %d" % card_data.base_value)
	print("修正数值: %d" % card_data.get_modified_value())
	print("花色: %s (%s)" % [card_data.suit, card_data.get_suit_display_name()])
	print("稀有度: %s" % card_data.rarity)
	
	if card_data.damage > 0:
		print("伤害: %d" % card_data.damage)
	if card_data.defense > 0:
		print("防御: %d" % card_data.defense)
	if card_data.cost > 0:
		print("消耗: %d" % card_data.cost)
	
	if card_data.wax_seals.size() > 0:
		print("蜡封: %s" % str(card_data.wax_seals))
	if card_data.frame_type != "":
		print("牌框: %s" % card_data.frame_type)
	if card_data.material_type != "":
		print("材质: %s" % card_data.material_type)
	
	if not card_data.description.is_empty():
		print("描述: %s" % card_data.description)
	
	print("==================\n")

# 清理资源
func _exit_tree():
	print("清理测试场景资源...")
	
	# 清理卡牌视图
	for card in test_cards:
		if card and is_instance_valid(card):
			card.queue_free()
	
	test_cards.clear()
