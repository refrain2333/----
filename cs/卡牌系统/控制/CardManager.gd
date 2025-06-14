class_name CardManager
extends Node

# 卡牌管理器，负责处理卡牌的生成、抽取和管理

@export var hand_container: HBoxContainer  # 手牌容器
@export var max_hand_size: int = 10  # 最大手牌数量
@export var use_object_pool: bool = true  # 是否使用对象池

# 卡牌相关信号
signal card_drawn(card_data)
signal card_played(card_data, position)
signal hand_updated()
signal card_effect_activated(card_data, effect)

# 对象池
var card_pool: CardPool = null

# 游戏管理器引用
var game_manager = null

# 小丑管理器引用
var joker_manager = null

# 设置手牌容器
func setup(container: HBoxContainer):
	hand_container = container
	print("CardManager: 手牌容器已设置")

# 初始化
func _ready():
	# 初始化对象池
	if use_object_pool:
		card_pool = CardPool.new(preload("res://cs/卡牌系统/视图/Card.tscn"), 20)
		add_child(card_pool)
	
	# 寻找游戏管理器
	if get_tree() and get_tree().current_scene:
		game_manager = get_tree().current_scene
		
		# 尝试获取小丑管理器
		if game_manager.has_node("JokerManager"):
			joker_manager = game_manager.get_node("JokerManager")

# 抽取初始手牌
func deal_initial_hand(n: int = 5):
	for i in n:
		# 从GameManager中获取卡牌数据
		var data = GameManager.draw_rune()
		if data:
			_spawn_card_view(data)
	
	emit_signal("hand_updated")
	
	# 通知小丑管理器初始手牌已发放
	if joker_manager:
		for joker in joker_manager.active_jokers:
			if joker.has_method("on_initial_hand_dealt"):
				joker.on_initial_hand_dealt(n)

# 抽取一张卡牌
func draw_card():
	var data = _draw_card_data()
	if data:
		_spawn_card_view(data)
		emit_signal("card_drawn", data)
		emit_signal("hand_updated")
		
		# 通知小丑管理器卡牌被抽取
		if joker_manager:
			for joker in joker_manager.active_jokers:
				if joker.has_method("on_card_drawn"):
					joker.on_card_drawn(data)
		
		return data
	return null

# 从数据创建卡牌视图
func _spawn_card_view(data: CardData):
	var view = null
	
	# 使用对象池或直接实例化
	if use_object_pool and card_pool:
		view = card_pool.get_card()
	else:
		view = preload("res://cs/卡牌系统/视图/Card.tscn").instantiate()
	
	# 确保卡牌没有父节点
	if view.get_parent():
		view.get_parent().remove_child(view)
	
	view.setup(data)
	
	# 确保手牌容器存在
	if hand_container:
		hand_container.add_child(view)
		view.card_clicked.connect(_on_card_clicked)
		view.card_dropped.connect(_on_card_dropped)
		_arrange_hand_cards()
	else:
		print("错误: 手牌容器不存在，无法添加卡牌")
		# 如果没有容器，释放卡牌视图以避免内存泄漏
		if use_object_pool and card_pool:
			card_pool.release_card(view)
		else:
			view.queue_free()

# 处理卡牌点击事件
func _on_card_clicked(card_view):
	# 处理卡牌选中逻辑
	if card_view.is_selected():
		card_view.set_selected(false)
	else:
		# 取消其他卡牌的选中状态
		for child in hand_container.get_children():
			if child != card_view and child.has_method("set_selected"):
				child.set_selected(false)
		
		card_view.set_selected(true)
		
		# 通知小丑管理器卡牌被选中
		if joker_manager and card_view.get_card_data():
			for joker in joker_manager.active_jokers:
				if joker.has_method("on_card_selected"):
					joker.on_card_selected(card_view.get_card_data())

# 处理卡牌拖放事件
func _on_card_dropped(card_view, drop_position):
	# 判断是否放入出牌区等逻辑
	var in_play_area = false
	if game_manager and game_manager.has_method("check_card_in_play_area"):
		in_play_area = game_manager.check_card_in_play_area(card_view, drop_position)
	
	if in_play_area:
		play_card(card_view)
	else:
		# 回到原位
		_arrange_hand_cards()

# 出牌
func play_card(card_view):
	if card_view:
		var card_data = card_view.get_card_data()
		if card_data:
			# 执行出牌逻辑
			var position = card_view.global_position
			
			# 通知小丑管理器卡牌被打出
			if joker_manager:
				for joker in joker_manager.active_jokers:
					if joker.has_method("on_card_played"):
						joker.on_card_played(card_data)
			
			# 从手牌中移除
			if use_object_pool and card_pool:
				# 使用对象池回收
				card_pool.release_card(card_view)
				card_view.get_parent().remove_child(card_view)
			else:
				card_view.queue_free()
			
			_arrange_hand_cards()
			
			# 激活卡牌效果
			_activate_card_effects(card_data)
			
			emit_signal("card_played", card_data, position)
			emit_signal("hand_updated")

# 激活卡牌效果
func _activate_card_effects(card_data: CardData):
	# 处理卡牌自身效果
	if card_data.element == "fire":
		var effect = FireElementEffect.new(2, 3)
		effect.on_activate(card_data)
		emit_signal("card_effect_activated", card_data, effect)
	elif card_data.element == "water":
		var effect = FreezeEffect.new(2)
		effect.on_activate(card_data)
		emit_signal("card_effect_activated", card_data, effect)
	
	# 处理卡牌修饰符效果
	for modifier in card_data.modifiers:
		if modifier.has_method("on_card_played"):
			modifier.on_card_played(card_data)

# 重新排列手牌
func _arrange_hand_cards():
	if not hand_container:
		print("警告: 手牌容器不存在，无法排列卡牌")
		return
		
	var cards = hand_container.get_children()
	var card_width = 140  # 卡牌宽度
	var spacing = 20      # 卡牌间距
	var total_width = cards.size() * (card_width + spacing)
	var start_x = (hand_container.size.x - total_width) / 2
	
	for i in range(cards.size()):
		var card = cards[i]
		var target_pos = Vector2(start_x + i * (card_width + spacing), 0)
		card.set_original_position(target_pos)

# 内部方法：抽取卡牌数据
func _draw_card_data() -> CardData:
	# 在实际游戏中，这里通常会从卡组中抽取
	# 这里简单创建一个随机卡牌作为示例
	var random_id = randi() % 52 + 1
	return CardData.new(random_id)

# 回合开始时调用
func on_turn_start():
	# 处理手牌中卡牌的回合开始效果
	for card_view in hand_container.get_children():
		if card_view.has_method("get_card_data"):
			var card_data = card_view.get_card_data()
			if card_data:
				# 应用修饰符的回合开始效果
				for modifier in card_data.modifiers:
					if modifier.has_method("on_turn_start"):
						modifier.on_turn_start(card_data)
				
				# 更新卡牌视图
				card_view.update_view()

# 回合结束时调用
func on_turn_end():
	# 处理手牌中卡牌的回合结束效果
	for card_view in hand_container.get_children():
		if card_view.has_method("get_card_data"):
			var card_data = card_view.get_card_data()
			if card_data:
				# 应用修饰符的回合结束效果
				for modifier in card_data.modifiers:
					if modifier.has_method("on_turn_end"):
						modifier.on_turn_end(card_data)
				
				# 更新卡牌视图
				card_view.update_view()

# 添加卡牌修饰符
func add_card_modifier(card_view, modifier: CardModifier):
	if card_view and card_view.has_method("get_card_data"):
		var card_data = card_view.get_card_data()
		if card_data:
			card_data.add_modifier(modifier)
			card_view.update_view()

# 序列化管理器状态，用于存档
func serialize() -> Dictionary:
	var hand_cards = []
	
	for card_view in hand_container.get_children():
		if card_view.has_method("get_card_data"):
			var card_data = card_view.get_card_data()
			if card_data:
				var modifiers = []
				for mod in card_data.modifiers:
					if mod.has_method("serialize"):
						modifiers.append(mod.serialize())
				
				hand_cards.append({
					"id": card_data.id,
					"modifiers": modifiers
				})
	
	return {
		"hand_cards": hand_cards
	}

# 从序列化数据恢复
func deserialize(data: Dictionary) -> void:
	# 清空当前手牌
	for child in hand_container.get_children():
		if use_object_pool and card_pool:
			card_pool.release_card(child)
		else:
			child.queue_free()
	
	# 恢复手牌
	if data.has("hand_cards"):
		for card_info in data.hand_cards:
			var card_data = CardData.new(card_info.id)
			
			# 恢复修饰符
			if card_info.has("modifiers"):
				for mod_data in card_info.modifiers:
					if mod_data.has("type"):
						var modifier = null
						
						match mod_data.type:
							"PowerUpModifier":
								modifier = PowerUpModifier.deserialize(mod_data)
							# 添加其他修饰符类型的恢复逻辑
						
						if modifier:
							card_data.add_modifier(modifier)
			
			# 创建卡牌视图
			_spawn_card_view(card_data)
	
	emit_signal("hand_updated") 
