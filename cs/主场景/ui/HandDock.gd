class_name HandDock
extends Panel

# 信号
signal play_button_pressed
signal sort_value_pressed
signal sort_suit_pressed
signal discard_button_pressed

# 节点引用
@onready var card_container = $CardContainer
@onready var play_button = $ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton
@onready var sort_value_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortValueButton
@onready var sort_suit_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortSuitButton
@onready var discard_button = $ButtonPanel/ButtonGrid/DiscardButtonContainer/DiscardButton

# 卡牌场景
var card_scene = preload("res://cs/卡牌系统/视图/RuneCard.tscn")

# 选中的卡牌
var selected_cards = []

func _ready():
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("hand_dock", self)
		
	# 连接按钮信号
	play_button.pressed.connect(_on_play_button_pressed)
	sort_value_button.pressed.connect(_on_sort_value_button_pressed)
	sort_suit_button.pressed.connect(_on_sort_suit_button_pressed)
	discard_button.pressed.connect(_on_discard_button_pressed)

# 添加卡牌到手牌
func add_card(card_data):
	if not card_container:
		print("错误：找不到卡牌容器")
		return null
	
	# 实例化卡牌
	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)
	
	# 设置卡牌数据
	if card_instance.has_method("setup"):
		card_instance.setup(card_data)
	
	# 连接卡牌信号
	if card_instance.has_signal("card_clicked"):
		card_instance.card_clicked.connect(_on_card_clicked.bind(card_instance))
	
	return card_instance

# 从手牌移除卡牌
func remove_card(card_instance):
	if card_instance and card_instance.is_inside_tree():
		# 如果卡牌在选中列表中，移除它
		var index = selected_cards.find(card_instance)
		if index != -1:
			selected_cards.remove_at(index)
		
		# 从场景树中移除
		card_instance.queue_free()

# 获取卡牌容器
func get_card_container():
	return card_container

# 更新UI
func update_ui():
	# 更新按钮状态 - 默认启用按钮
	if play_button:
		play_button.disabled = false
	
	if discard_button:
		discard_button.disabled = false

# 处理卡牌点击
func _on_card_clicked(card_instance):
	var index = selected_cards.find(card_instance)
	
	# 如果卡牌已经选中，取消选中
	if index != -1:
		selected_cards.remove_at(index)
		if card_instance.has_method("set_selected"):
			card_instance.set_selected(false)
	else:
		# 否则，选中卡牌
		selected_cards.append(card_instance)
		if card_instance.has_method("set_selected"):
			card_instance.set_selected(true)
	
	# 更新UI
	update_ui()

# 处理吟唱咒语按钮点击
func _on_play_button_pressed():
	emit_signal("play_button_pressed")
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.get_ui_component("ui_manager").set_status("准备吟唱咒语")

# 处理按能量排序按钮点击
func _on_sort_value_button_pressed():
	emit_signal("sort_value_pressed")
	sort_cards_by_value()

# 处理按元素排序按钮点击
func _on_sort_suit_button_pressed():
	emit_signal("sort_suit_pressed")
	sort_cards_by_suit()

# 处理使用精华按钮点击
func _on_discard_button_pressed():
	emit_signal("discard_button_pressed")
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.get_ui_component("ui_manager").set_status("使用精华获取新符文")

# 按能量值排序卡牌
func sort_cards_by_value():
	if not card_container:
		return
	
	# 获取所有卡牌
	var cards = []
	for child in card_container.get_children():
		if child.has_method("get_card_data"):
			cards.append(child)
	
	# 按能量值排序
	cards.sort_custom(func(a, b): 
		var a_data = a.get_card_data()
		var b_data = b.get_card_data()
		return a_data.power < b_data.power
	)
	
	# 重新排列
	for i in range(cards.size()):
		card_container.move_child(cards[i], i)

# 按元素类型排序卡牌
func sort_cards_by_suit():
	if not card_container:
		return
	
	# 获取所有卡牌
	var cards = []
	for child in card_container.get_children():
		if child.has_method("get_card_data"):
			cards.append(child)
	
	# 按元素类型排序
	cards.sort_custom(func(a, b): 
		var a_data = a.get_card_data()
		var b_data = b.get_card_data()
		if a_data.element == b_data.element:
			return a_data.power < b_data.power
		return a_data.element < b_data.element
	)
	
	# 重新排列
	for i in range(cards.size()):
		card_container.move_child(cards[i], i) 
