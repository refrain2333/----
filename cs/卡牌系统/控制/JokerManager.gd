extends Node

# 小丑卡牌管理器，负责处理小丑卡牌的生成和效果

@export var joker_container: Control  # 小丑容器
@export var max_jokers: int = 3       # 最大小丑数量
@export var joker_scene_path: String = "res://cs/卡牌系统/视图/JokerView.tscn"  # 小丑场景路径

# 小丑相关信号
signal joker_activated(joker_data)
signal joker_effect_triggered(joker_data, effect_name)

# 活跃的小丑数据
var active_jokers: Array[JokerData] = []

# 游戏管理器引用
var game_manager = null

# 初始化
func _ready():
	# 寻找游戏管理器
	if get_tree() and get_tree().current_scene:
		game_manager = get_tree().current_scene

# 添加小丑卡牌
func add_joker(joker_id: int) -> JokerData:
	if active_jokers.size() >= max_jokers:
		print("小丑卡牌数量已达上限")
		return null
	
	var joker_data = JokerData.new(joker_id)
	active_jokers.append(joker_data)
	
	# 创建小丑视图
	var joker_view = load(joker_scene_path).instantiate()
	joker_view.setup(joker_data)
	joker_container.add_child(joker_view)
	
	# 连接信号
	joker_view.joker_clicked.connect(_on_joker_clicked)
	
	print("添加小丑卡牌: %s" % joker_data.display_name)
	
	# 触发小丑添加事件
	_trigger_joker_added(joker_data)
	
	return joker_data

# 移除小丑卡牌
func remove_joker(joker_view) -> void:
	var joker_data = joker_view.get_joker_data()
	if joker_data in active_jokers:
		active_jokers.erase(joker_data)
		
	# 移除视图
	joker_view.queue_free()
	
	print("移除小丑卡牌: %s" % joker_data.display_name)
	
	# 触发小丑移除事件
	_trigger_joker_removed(joker_data)

# 处理小丑点击事件
func _on_joker_clicked(joker_view) -> void:
	var joker_data = joker_view.get_joker_data()
	
	# 激活小丑效果
	if joker_data.can_activate():
		_activate_joker(joker_data)
		joker_view.update_view()

# 激活小丑效果
func _activate_joker(joker_data: JokerData) -> void:
	if not joker_data.can_activate():
		return
	
	print("激活小丑效果: %s" % joker_data.display_name)
	
	# 执行小丑效果
	match joker_data.joker_type:
		"trickster":
			_execute_trickster_effect(joker_data)
		"jester":
			_execute_jester_effect(joker_data)
		"fool":
			_execute_fool_effect(joker_data)
		_:
			print("未知小丑类型: %s" % joker_data.joker_type)
	
	# 设置冷却
	joker_data.activate()
	
	emit_signal("joker_activated", joker_data)

# 执行诡术师效果
func _execute_trickster_effect(joker_data: JokerData) -> void:
	# 例如：对所有敌人造成伤害
	var damage = joker_data.power
	
	print("诡术师效果: 对所有敌人造成%d点伤害" % damage)
	
	# 通知游戏管理器
	if game_manager and game_manager.has_method("apply_damage_to_all_enemies"):
		game_manager.apply_damage_to_all_enemies(damage)
	
	emit_signal("joker_effect_triggered", joker_data, "trickster_damage")

# 执行弄臣效果
func _execute_jester_effect(joker_data: JokerData) -> void:
	# 例如：抽取额外的卡牌
	var cards_to_draw = joker_data.power / 2 + 1
	
	print("弄臣效果: 抽取%d张卡牌" % cards_to_draw)
	
	# 通知游戏管理器
	if game_manager and game_manager.has_method("draw_cards"):
		game_manager.draw_cards(cards_to_draw)
	
	emit_signal("joker_effect_triggered", joker_data, "jester_draw")

# 执行愚者效果
func _execute_fool_effect(joker_data: JokerData) -> void:
	# 例如：获得临时护盾
	var shield_amount = joker_data.power * 2
	
	print("愚者效果: 获得%d点护盾" % shield_amount)
	
	# 通知游戏管理器
	if game_manager and game_manager.has_method("add_player_shield"):
		game_manager.add_player_shield(shield_amount)
	
	emit_signal("joker_effect_triggered", joker_data, "fool_shield")

# 卡牌被打出时的处理（被动效果）
func on_card_played(card_data: CardData) -> void:
	print("小丑管理器: 卡牌被打出 - %s" % card_data.display_name)
	
	for joker in active_jokers:
		# 根据小丑类型处理被动效果
		match joker.joker_type:
			"trickster":
				_on_trickster_card_played(joker, card_data)
			"jester":
				_on_jester_card_played(joker, card_data)
			"fool":
				_on_fool_card_played(joker, card_data)

# 诡术师被动效果：增加卡牌伤害
func _on_trickster_card_played(joker: JokerData, card_data: CardData) -> void:
	if card_data.element == "fire":
		var bonus_damage = joker.power / 2
		
		print("诡术师被动: %s 获得额外%d点伤害" % [card_data.display_name, bonus_damage])
		
		# 通知游戏管理器
		if game_manager and game_manager.has_method("apply_bonus_damage"):
			game_manager.apply_bonus_damage(card_data, bonus_damage)
		
		emit_signal("joker_effect_triggered", joker, "trickster_passive")

# 弄臣被动效果：有几率抽取额外卡牌
func _on_jester_card_played(joker: JokerData, card_data: CardData) -> void:
	# 25%几率触发
	if randf() <= 0.25:
		print("弄臣被动: 触发额外抽牌")
		
		# 通知游戏管理器
		if game_manager and game_manager.has_method("draw_cards"):
			game_manager.draw_cards(1)
		
		emit_signal("joker_effect_triggered", joker, "jester_passive")

# 愚者被动效果：打出低能量卡牌时获得少量护盾
func _on_fool_card_played(joker: JokerData, card_data: CardData) -> void:
	if card_data.power <= 5:
		var shield_amount = joker.power / 2
		
		print("愚者被动: 获得%d点护盾" % shield_amount)
		
		# 通知游戏管理器
		if game_manager and game_manager.has_method("add_player_shield"):
			game_manager.add_player_shield(shield_amount)
		
		emit_signal("joker_effect_triggered", joker, "fool_passive")

# 卡牌被抽取时的处理（被动效果）
func on_card_drawn(card_data: CardData) -> void:
	for joker in active_jokers:
		# 根据小丑类型处理被动效果
		if joker.joker_type == "jester":
			# 弄臣有几率增强抽到的卡牌
			if randf() <= 0.2:  # 20%几率
				var power_bonus = joker.power / 3
				card_data.power += power_bonus
				
				print("弄臣被动: %s 获得额外%d点能量" % [card_data.display_name, power_bonus])
				
				emit_signal("joker_effect_triggered", joker, "jester_draw_bonus")

# 回合开始时的处理
func on_turn_start() -> void:
	for joker in active_jokers:
		# 更新冷却
		joker.on_turn_start()
		
		# 根据小丑类型处理回合开始效果
		match joker.joker_type:
			"fool":
				# 愚者在回合开始时有几率给予少量护盾
				if randf() <= 0.3:  # 30%几率
					var shield_amount = joker.power / 3
					
					print("愚者回合开始: 获得%d点护盾" % shield_amount)
					
					# 通知游戏管理器
					if game_manager and game_manager.has_method("add_player_shield"):
						game_manager.add_player_shield(shield_amount)
					
					emit_signal("joker_effect_triggered", joker, "fool_turn_start")

# 回合结束时的处理
func on_turn_end() -> void:
	for joker in active_jokers:
		# 更新状态
		joker.on_turn_end()

# 小丑被添加时的处理
func _trigger_joker_added(joker_data: JokerData) -> void:
	# 通知其他小丑
	for other_joker in active_jokers:
		if other_joker != joker_data:
			if other_joker.joker_type == "jester":
				# 弄臣会增强新添加的小丑
				var power_bonus = other_joker.power / 4
				joker_data.power += power_bonus
				
				print("弄臣协同: %s 获得额外%d点能量" % [joker_data.display_name, power_bonus])

# 小丑被移除时的处理
func _trigger_joker_removed(joker_data: JokerData) -> void:
	# 可以在这里处理小丑被移除时的特殊效果
	pass

# 序列化管理器状态，用于存档
func serialize() -> Dictionary:
	var jokers_data = []
	
	for joker in active_jokers:
		jokers_data.append(joker.serialize())
	
	return {
		"active_jokers": jokers_data
	}

# 从序列化数据恢复
func deserialize(data: Dictionary) -> void:
	# 清空当前小丑
	for child in joker_container.get_children():
		child.queue_free()
	
	active_jokers.clear()
	
	# 恢复小丑
	if data.has("active_jokers"):
		for joker_info in data.active_jokers:
			var joker_data = JokerData.new(joker_info.id)
			joker_data.deserialize(joker_info)
			
			active_jokers.append(joker_data)
			
			# 创建小丑视图
			var joker_view = load(joker_scene_path).instantiate()
			joker_view.setup(joker_data)
			joker_container.add_child(joker_view)
			
			# 连接信号
			joker_view.joker_clicked.connect(_on_joker_clicked) 
