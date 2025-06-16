class_name HandDock
extends Panel

# 信号
signal card_selection_changed(selected_cards)
signal play_button_pressed
signal discard_button_pressed

# 节点引用
@onready var card_container = $CardContainer
@onready var play_button = $ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton
@onready var discard_button = $ButtonPanel/ButtonGrid/DiscardButtonContainer/DiscardButton
@onready var sort_value_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortValueButton
@onready var sort_suit_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortSuitButton

# 卡牌场景 - 更新为使用Card.tscn
var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")

# 状态变量
var selected_cards = []  # 选中的卡牌

# 初始化
func _ready():
	print("HandDock._ready: 开始初始化")
	# 允许鼠标事件穿透此面板，到达子节点
	mouse_filter = MOUSE_FILTER_PASS

	# 获取UI元素引用
	card_container = $CardContainer
	# 同样允许卡牌容器穿透事件，这是关键修复！
	if card_container:
		card_container.mouse_filter = MOUSE_FILTER_PASS
		print("HandDock._ready: 设置card_container的mouse_filter=PASS")
		
	play_button = $ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton
	discard_button = $ButtonPanel/ButtonGrid/DiscardButtonContainer/DiscardButton
	sort_value_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortValueButton
	sort_suit_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortSuitButton
	
	# 打印按钮节点信息
	if play_button:
		print("HandDock._ready: PlayButton存在，位置=%s，尺寸=%s" % [play_button.position, play_button.size])
		print("HandDock._ready: PlayButton鼠标过滤器=%d，禁用状态=%s" % [play_button.mouse_filter, str(play_button.disabled)])
	else:
		print("HandDock._ready: 错误-找不到PlayButton")
	
	if discard_button:
		print("HandDock._ready: DiscardButton存在，位置=%s，尺寸=%s" % [discard_button.position, discard_button.size])
		print("HandDock._ready: DiscardButton鼠标过滤器=%d，禁用状态=%s" % [discard_button.mouse_filter, str(discard_button.disabled)])
	else:
		print("HandDock._ready: 错误-找不到DiscardButton")
	
	# 设置按钮鼠标过滤器
	if play_button:
		play_button.mouse_filter = Control.MOUSE_FILTER_STOP
		# 强制启用按钮
		play_button.disabled = false
		print("HandDock._ready: 设置PlayButton的mouse_filter=STOP，disabled=false")
	
	if discard_button:
		discard_button.mouse_filter = Control.MOUSE_FILTER_STOP
		# 强制启用按钮
		discard_button.disabled = false
		print("HandDock._ready: 设置DiscardButton的mouse_filter=STOP，disabled=false")
	
	if sort_value_button:
		sort_value_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if sort_suit_button:
		sort_suit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接按钮信号
	if play_button:
		if play_button.pressed.is_connected(_on_play_button_pressed):
			print("HandDock._ready: PlayButton信号已连接，断开旧连接")
			play_button.pressed.disconnect(_on_play_button_pressed)
		
		print("HandDock._ready: 连接PlayButton.pressed信号")
		play_button.pressed.connect(_on_play_button_pressed)
	
	if discard_button:
		if discard_button.pressed.is_connected(_on_discard_button_pressed):
			print("HandDock._ready: DiscardButton信号已连接，断开旧连接")
			discard_button.pressed.disconnect(_on_discard_button_pressed)
		
		print("HandDock._ready: 连接DiscardButton.pressed信号")
		discard_button.pressed.connect(_on_discard_button_pressed)
	
	if sort_value_button and not sort_value_button.pressed.is_connected(_on_sort_value_button_pressed):
		sort_value_button.pressed.connect(_on_sort_value_button_pressed)
	
	if sort_suit_button and not sort_suit_button.pressed.is_connected(_on_sort_suit_button_pressed):
		sort_suit_button.pressed.connect(_on_sort_suit_button_pressed)
	
	# 连接已存在的卡牌信号
	if card_container:
		for card in card_container.get_children():
			_connect_card_signals(card)
	
	print("HandDock._ready: 初始化完成")

# 连接卡牌信号
func _connect_card_signals(card_instance):
	print("HandDock._connect_card_signals: 尝试连接卡牌信号，卡牌=%s" % card_instance.name)
	
	# 检查节点是否是卡牌类型
	if not card_instance.has_method("get_card_data"):
		print("HandDock._connect_card_signals: 警告 - 节点不是卡牌，跳过信号连接: %s" % card_instance.name)
		return
	
	# 检查卡牌是否有必要的信号
	print("HandDock._connect_card_signals: 检查是否有card_clicked信号")
	if not card_instance.has_signal("card_clicked"):
		print("HandDock._connect_card_signals: 错误 - 卡牌没有card_clicked信号: %s" % card_instance.name)
		return
		
	print("HandDock._connect_card_signals: 检查是否有selection_changed信号")
	if not card_instance.has_signal("selection_changed"):
		print("HandDock._connect_card_signals: 错误 - 卡牌没有selection_changed信号: %s" % card_instance.name)
	
	# 连接卡牌点击信号
	print("HandDock._connect_card_signals: 准备连接card_clicked信号")
	# 先断开可能存在的连接，避免重复
	if card_instance.is_connected("card_clicked", Callable(self, "_on_card_clicked")):
		print("HandDock._connect_card_signals: 断开已存在的card_clicked连接")
		card_instance.disconnect("card_clicked", Callable(self, "_on_card_clicked"))
	
	# 重新连接信号
	print("HandDock._connect_card_signals: 连接card_clicked到_on_card_clicked")
	card_instance.connect("card_clicked", Callable(self, "_on_card_clicked"))
	
	# 连接卡牌选择状态变化信号
	print("HandDock._connect_card_signals: 准备连接selection_changed信号")
	if card_instance.has_signal("selection_changed"):
		# 先断开可能存在的连接，避免重复
		if card_instance.is_connected("selection_changed", Callable(self, "_on_card_selection_changed")):
			print("HandDock._connect_card_signals: 断开已存在的selection_changed连接")
			card_instance.disconnect("selection_changed", Callable(self, "_on_card_selection_changed"))
		
		# 重新连接信号
		print("HandDock._connect_card_signals: 连接selection_changed到_on_card_selection_changed")
		card_instance.connect("selection_changed", Callable(self, "_on_card_selection_changed"))
	
	print("HandDock._connect_card_signals: 卡牌信号连接完成: %s" % card_instance.name)

# 更新UI
func update_ui():
	# 检查是否有选中的卡牌
	var has_selected = selected_cards.size() > 0
	
	# 获取资源信息
	var has_focus = true  # 默认假设有足够的集中力
	var has_essence = true  # 默认假设有足够的精华
	
	# 获取GameManager单例
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr:
		has_focus = game_mgr.focus_count > 0
		has_essence = game_mgr.essence_count > 0
		
		print("HandDock.update_ui: 资源状态 - 集中力: %d, 精华: %d" % [game_mgr.focus_count, game_mgr.essence_count])
	else:
		print("HandDock.update_ui: 警告 - 无法获取GameManager")
	
	# 更新按钮状态
	if play_button:
		play_button.disabled = not (has_selected and has_focus)
		print("HandDock.update_ui: 设置PlayButton.disabled=%s" % str(play_button.disabled))
	
	if discard_button:
		discard_button.disabled = not (has_selected and has_essence)
		print("HandDock.update_ui: 设置DiscardButton.disabled=%s" % str(discard_button.disabled))
	
	# 更新排序按钮状态
	if sort_value_button:
		sort_value_button.disabled = false
	
	if sort_suit_button:
		sort_suit_button.disabled = false

# 添加卡牌到手牌
func add_card(card_instance):
	print("HandDock.add_card: 开始添加卡牌")
	
	if not card_container:
		print("HandDock.add_card: 错误 - card_container为空")
		return false
	
	if not card_instance:
		print("HandDock.add_card: 错误 - card_instance为空")
		return false
	
	# 确保卡牌实例有card_clicked信号
	if not card_instance.has_signal("card_clicked"):
		print("HandDock.add_card: 警告 - 卡牌没有card_clicked信号")
		# 动态添加信号
		if card_instance is Object:
			print("HandDock.add_card: 尝试动态添加信号")
	
	# 添加到容器
	print("HandDock.add_card: 添加卡牌到容器")
	card_container.add_child(card_instance)
	
	# 确保卡牌的鼠标过滤器设置正确
	print("HandDock.add_card: 设置卡牌鼠标过滤器为STOP")
	card_instance.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接卡牌信号
	print("HandDock.add_card: 连接卡牌信号")
	_connect_card_signals(card_instance)
	
	print("HandDock.add_card: 卡牌添加完成")
	return true

# 从手牌移除卡牌
func remove_card(card_instance):
	print("HandDock.remove_card: 开始移除卡牌")
	if card_instance and card_instance.is_inside_tree():
		# 如果卡牌在选中列表中，移除它
		var index = selected_cards.find(card_instance)
		if index != -1:
			selected_cards.remove_at(index)
			print("HandDock.remove_card: 已从选中列表中移除")
		
		# 从场景树中移除
		card_instance.queue_free()
		print("HandDock.remove_card: 已从场景树移除")
		
		# 立即重新排列剩余卡牌（不使用延迟调用）
		print("HandDock.remove_card: 立即重新排列剩余卡牌")
		_rearrange_cards()
		
		print("HandDock.remove_card: 完成移除")
		return true
	return false

# 重新排列所有卡牌
func _rearrange_cards():
	print("HandDock._rearrange_cards: 开始重新排列卡牌")
	if not card_container:
		print("HandDock._rearrange_cards: 错误 - card_container为空")
		return
		
	# 获取所有卡牌
	var cards = []
	for child in card_container.get_children():
		if child.has_method("get_card_data"):
			cards.append(child)
	
	print("HandDock._rearrange_cards: 找到 %d 张卡牌需要重排" % cards.size())
	
	# 固定参数
	var card_width = 135  # 卡牌宽度
	var container_width = card_container.size.x
	var unselected_y = 0  # 未选中卡牌的Y坐标
	var selected_y = -30  # 选中卡牌的Y坐标（向上偏移30像素）
	
	# 固定的6个位置X坐标（从左到右）
	var fixed_positions = [
		80,   # 位置1（最左）
		190,  # 位置2
		300,  # 位置3
		410,  # 位置4
		520,  # 位置5
		630   # 位置6（最右）
	]
	
	# 根据卡牌数量选择起始位置索引
	var start_index = 0
	if cards.size() <= 6:
		# 居中处理：例如，如果有3张牌，起始索引应该是1，以使用位置2,3,4
		start_index = int(max(0, (6 - cards.size()) / 2))
	
	print("HandDock._rearrange_cards: 卡牌数量=%d，起始索引=%d" % [cards.size(), start_index])
	
	# 设置每张卡牌的位置
	for i in range(cards.size()):
		var card = cards[i]
		var position_index = start_index + i
		
		# 安全检查，确保索引在有效范围内
		if position_index >= fixed_positions.size():
			print("HandDock._rearrange_cards: 警告 - 卡牌索引超出固定位置范围，使用最后一个位置")
			position_index = fixed_positions.size() - 1
		
		# 获取X坐标（固定）
		var x_pos = fixed_positions[position_index]
		
		# 根据选择状态确定Y坐标
		var y_pos = unselected_y
		var is_selected = false
		if card.has_method("get_selected_state"):
			is_selected = card.get_selected_state()
			if is_selected:
				y_pos = selected_y
		
		# 设置卡牌位置
		var target_pos = Vector2(x_pos, y_pos)
		print("HandDock._rearrange_cards: 设置卡牌 %d 的位置为 (%d, %d), 选中状态=%s" % 
			[i, x_pos, y_pos, "是" if is_selected else "否"])
		
		# 设置卡牌位置并缓存原始位置
		card.position = target_pos
		
		# 更新卡牌的原始位置（用于取消选中时恢复）
		if card.has_method("set_original_position"):
			# 强制设置新的原始位置为水平固定位置，垂直为未选中位置
			card.set_original_position(Vector2(x_pos, unselected_y))
			print("HandDock._rearrange_cards: 设置卡牌 %d 的原始位置为 (%d, %d)" % [i, x_pos, unselected_y])
	
	print("HandDock._rearrange_cards: 卡牌重排完成")

# 获取卡牌容器
func get_card_container():
	return card_container

# 处理卡牌点击
func _on_card_clicked(card_instance):
	print("HandDock._on_card_clicked: 收到卡牌点击事件，卡牌=%s" % card_instance.name)
	
	# 切换卡牌选择状态
	print("HandDock._on_card_clicked: 调用卡牌的toggle_selected方法")
	var is_selected = card_instance.toggle_selected()
	print("HandDock._on_card_clicked: 卡牌新的选择状态=%s" % str(is_selected))
	
	# 更新选中卡牌列表
	if is_selected:
		print("HandDock._on_card_clicked: 卡牌被选中，添加到选中列表")
		if selected_cards.find(card_instance) == -1:
			selected_cards.append(card_instance)
			print("HandDock._on_card_clicked: 卡牌已添加到选中列表")
		else:
			print("HandDock._on_card_clicked: 卡牌已经在选中列表中，无需再添加")
	else:
		print("HandDock._on_card_clicked: 卡牌被取消选中，从选中列表移除")
		var index = selected_cards.find(card_instance)
		if index != -1:
			selected_cards.remove_at(index)
			print("HandDock._on_card_clicked: 卡牌已从选中列表移除")
		else:
			print("HandDock._on_card_clicked: 卡牌不在选中列表中，无需移除")
	
	# 调试：打印当前已选卡牌
	_print_selected_cards()
	
	# 更新UI（例如按钮状态）
	update_ui()

# 处理卡牌选择状态变化
func _on_card_selection_changed(card_instance, is_selected):
	# 更新选中卡牌列表
	if is_selected:
		if selected_cards.find(card_instance) == -1:
			selected_cards.append(card_instance)
	else:
		var index = selected_cards.find(card_instance)
		if index != -1:
			selected_cards.remove_at(index)
	
	# 调试：打印当前已选卡牌
	_print_selected_cards()
	
	# 发送选择变化信号
	emit_signal("card_selection_changed", selected_cards)
	
	# 更新UI状态
	update_ui()

# 打印当前已选卡牌集合
func _print_selected_cards():
	if selected_cards.is_empty():
		print("HandDock: 当前无已选卡牌")
		return
	
	var names := []
	for card in selected_cards:
		if card.has_method("get_card_name"):
			names.append(card.get_card_name())
		else:
			names.append(str(card))
	print("HandDock: 已选卡牌 -> ", names)

# 处理出牌按钮点击
func _on_play_button_pressed():
	print("HandDock._on_play_button_pressed: 出牌按钮被点击")
	# 检查是否有选中的卡牌
	if selected_cards.size() > 0:
		print("HandDock._on_play_button_pressed: 有选中卡牌，发送play_button_pressed信号")
		emit_signal("play_button_pressed")
	else:
		print("HandDock._on_play_button_pressed: 没有选中卡牌")

# 处理按能量排序按钮点击
func _on_sort_value_button_pressed():
	sort_cards_by_value()

# 处理按元素排序按钮点击
func _on_sort_suit_button_pressed():
	sort_cards_by_suit()

# 处理弃牌按钮点击
func _on_discard_button_pressed():
	print("HandDock._on_discard_button_pressed: 弃牌按钮被点击")
	# 检查是否有选中的卡牌
	if selected_cards.size() > 0:
		print("HandDock._on_discard_button_pressed: 有选中卡牌，发送discard_button_pressed信号")
		emit_signal("discard_button_pressed")
	else:
		print("HandDock._on_discard_button_pressed: 没有选中卡牌")

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

# 捕获全局输入事件，用于调试按钮点击
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("HandDock._input: 检测到鼠标左键点击，位置=%s" % event.position)
		
		# 测试是否点击在PlayButton区域内
		if play_button:
			var play_button_rect = play_button.get_global_rect()
			if play_button_rect.has_point(event.position):
				print("HandDock._input: 点击在PlayButton区域内!")
				_on_play_button_pressed()
				return
		
		# 测试是否点击在DiscardButton区域内
		if discard_button:
			var discard_button_rect = discard_button.get_global_rect()
			if discard_button_rect.has_point(event.position):
				print("HandDock._input: 点击在DiscardButton区域内!")
				_on_discard_button_pressed()
				return

# 添加一个处理按钮直接点击的函数，专门用于调试
func debug_button_press(button_name):
	print("HandDock.debug_button_press: 模拟点击按钮 " + button_name)
	
	match button_name:
		"play":
			_on_play_button_pressed()
		"discard":
			_on_discard_button_pressed()
		_:
			print("HandDock.debug_button_press: 未知的按钮名称 " + button_name)

# 添加一个可以在场景中直接使用的函数，为了方便调试
func _process(_delta):
	# 按P键模拟点击"吟唱咒语"按钮
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_P):
		print("HandDock._process: 检测到P键按下，模拟点击吟唱咒语按钮")
		debug_button_press("play")
	
	# 按D键模拟点击"使用精华"按钮
	if Input.is_key_pressed(KEY_D):
		print("HandDock._process: 检测到D键按下，模拟点击使用精华按钮")
		debug_button_press("discard")
