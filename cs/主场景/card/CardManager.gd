class_name CardManager
extends Node

var main_game  # 引用主场景

# 卡牌预制体
var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")

# 添加最大手牌数量常量
const MAX_HAND_SIZE = 5  # 最大手牌数量

# 构造函数
func _init(game_scene):
	main_game = game_scene

# 初始化卡牌系统
func initialize():
	print("卡牌系统初始化")
	
	# 初始化牌库
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr:
		if game_mgr.has_method("initialize_rune_library"):
			game_mgr.initialize_rune_library()
	else:
		print("错误：初始化时无法获取GameManager单例")

# 发放初始手牌
func deal_initial_hand(n: int = 5):
	print("发放初始手牌: " + str(n) + "张")
	
	# 检查GameManager是否存在
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		print("错误：找不到GameManager单例")
		return
	
	# 获取HandDock
	var hand_dock = main_game.hand_dock
	if not hand_dock:
		print("错误：找不到HandDock")
		return
	
	# 抽取指定数量的卡牌
	for i in range(n):
		# 检查手牌是否已满
		if game_mgr.is_hand_full():
			print("手牌已满，无法抽取更多符文")
			break
		
		# 抽牌
		var card_data = game_mgr.draw_rune()
		if not card_data:
			print("符文库已空")
			break
		
		print("抽取了符文: " + card_data.name + " (元素: " + card_data.element + ", 花色: " + card_data.suit + ")")
		
		# 创建卡牌实例
		var card_scene = load("res://cs/卡牌系统/视图/Card.tscn")
		if card_scene:
			var card_instance = card_scene.instantiate()
			if card_instance:
				# 设置卡牌数据
				card_instance.setup(card_data)
				
				# 添加到手牌
				if hand_dock.has_method("add_card"):
					hand_dock.add_card(card_instance)
				else:
					var card_container = hand_dock.get_node("CardContainer")
					if card_container:
						card_container.add_child(card_instance)
					else:
						hand_dock.add_child(card_instance)
		else:
			print("错误：找不到卡牌场景")
	
	print("初始符文已发放")

# 从牌库抽一张卡
func draw_card_from_library():
	if not Engine.has_singleton("GameManager"):
		print("错误：找不到GameManager单例")
		return null
	
	var GameManager = Engine.get_singleton("GameManager")
	
	# 检查手牌是否已满
	if GameManager.is_hand_full():
		main_game.ui_manager.set_status("手牌已满，无法抽取更多符文")
		return null
	
	# 抽牌
	var card_data = GameManager.draw_card()
	if not card_data:
		main_game.ui_manager.set_status("符文库已空")
		return null
	
	# 添加到手牌UI
	var card_instance = main_game.ui_manager.add_card_to_hand(card_data)
	
	# 创建抽牌特效
	if main_game.effect_orchestrator:
		var deck_position = Vector2(1600, 500)  # 牌库位置
		var hand_position = card_instance.global_position
		main_game.effect_orchestrator.create_draw_effect(deck_position, hand_position)
	
	# 更新UI
	main_game.ui_manager.update_ui()
	main_game.ui_manager.set_status("抽取了一张符文")
	
	return card_instance

# 打出卡牌
func play_card(card_instance):
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		return
	
	# 获取卡牌数据
	var card_data = card_instance.get_card_data() if card_instance.has_method("get_card_data") else null
	if not card_data:
		return
	
	# 检查是否可以出牌
	if not game_mgr.can_play_card(card_data):
		main_game.ui_manager.set_status("无法出牌：集中力不足或费用不足")
		return
	
	# 从手牌移除
	main_game.ui_manager.remove_card_from_hand(card_instance)
	
	# 创建放置特效
	if main_game.effect_orchestrator:
		main_game.effect_orchestrator.create_card_drop_effect(card_instance.global_position)
	
	# 记录出牌
	main_game.turn_manager.record_play(card_instance)
	
	# 更新UI
	main_game.ui_manager.update_ui()
	main_game.ui_manager.set_status("打出了符文: " + card_data.name)

# 弃置卡牌
func discard_card(card_instance):
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		return
	
	# 检查是否可以弃牌
	if not game_mgr.can_discard_card():
		main_game.ui_manager.set_status("无法弃牌：精华不足")
		return
	
	# 获取卡牌数据
	var card_data = card_instance.get_card_data() if card_instance.has_method("get_card_data") else null
	if not card_data:
		return
	
	# 从手牌移除
	main_game.ui_manager.remove_card_from_hand(card_instance)
	
	# 消耗精华
	game_mgr.use_essence()
	
	# 更新UI
	main_game.ui_manager.update_ui()
	main_game.ui_manager.set_status("弃置了符文: " + card_data.name)

# 获取卡牌数据
func get_card_data(card_id):
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr and game_mgr.has_method("get_card_by_id"):
		return game_mgr.get_card_by_id(card_id)
	
	return null

# 打出选中的卡牌
func play_selected() -> bool:
	print("CardManager.play_selected: 开始执行")
	
	# 获取HandDock中选中的卡牌
	var hand_dock = main_game.hand_dock
	if not hand_dock:
		print("CardManager.play_selected: 错误 - 找不到手牌容器")
		return false
	
	# 检查是否有选中的卡牌
	if hand_dock.selected_cards.size() == 0:
		print("CardManager.play_selected: 未选择卡牌")
		if main_game.has_method("set_status"):
			main_game.set_status("请先选择要打出的卡牌")
		return false
	
	# 检查GameManager是否存在并获取资源
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		print("CardManager.play_selected: GameManager不存在")
		return false
	
	# 按任务要求：检查并消耗集中力
	if game_mgr.focus_count <= 0:
		print("CardManager.play_selected: 集中力不足，无法出牌")
		if main_game.has_method("set_status"):
			main_game.set_status("集中力不足，无法打出卡牌")
		return false
	
	# 消耗一点集中力
	print("CardManager.play_selected: 消耗一点集中力")
	game_mgr.focus_count -= 1
	
	# 保存选中的卡牌副本，因为在移除过程中会清空selected_cards数组
	var selected_cards = []
	for card in hand_dock.selected_cards:
		selected_cards.append(card)
	
	# 处理所有选中的卡牌
	var selected_count = selected_cards.size()
	print("CardManager.play_selected: 处理 %d 张选中的卡牌" % selected_count)
	
	# 打印卡牌详情
	print("CardManager.play_selected: 当前选中的卡牌:")
	var base_score = 0
	for card in selected_cards:
		# 获取卡牌数据
		var card_data = card.get_card_data() if card.has_method("get_card_data") else null
		if not card_data:
			continue
			
		print("  - %s (花色: %s, 点数: %d, 分值: %d)" % [
			card_data.name, card_data.suit, card_data.value, card_data.point
		])
		
		# 累加分数
		base_score += card_data.value
	
	# 计算最终得分（简化版：直接使用点数之和，倍率固定为1）
	var multiplier = 1
	var final_score = base_score * multiplier
	
	# 更新游戏状态
	print("CardManager.play_selected: 基础得分 %d x 倍率 %d = 最终得分 %d" % [base_score, multiplier, final_score])
	
	# 获取当前手牌数量（在移除前）
	var card_container = hand_dock.get_node_or_null("CardContainer")
	var current_count = 0
	if card_container:
		current_count = card_container.get_child_count()
		print("CardManager.play_selected: 移除前，当前手牌数量: %d/%d" % [current_count, MAX_HAND_SIZE])
	
	# 移除所有选中的卡牌
	for card in selected_cards:
		# 从手牌移除
		main_game.hand_dock.remove_card(card)
	
	# 清除选中状态
	hand_dock.selected_cards.clear()
	
	# 更新UI
	if main_game.sidebar:
		main_game.sidebar.set_score(final_score)  # 显示当次得分
		main_game.sidebar.set_multiplier(multiplier)  # 显示当前倍率
		
		# 显示组合名称
		if main_game.sidebar.has_method("set_combo_name"):
			main_game.sidebar.set_combo_name("打出卡牌")
	
	# 增加游戏总分数
	game_mgr.score += final_score
	
	# 计算移除后的实际手牌数量（不依赖场景树计数）
	var actual_hand_count = current_count - selected_count
	print("CardManager.play_selected: 移除卡牌后，实际手牌数量: %d/%d" % [actual_hand_count, MAX_HAND_SIZE])
	
	# 立即补充手牌至指定上限
	print("CardManager.play_selected: 立即补充手牌")
	var to_draw = MAX_HAND_SIZE - actual_hand_count
	print("CardManager.play_selected: 需要补充 %d 张卡牌" % to_draw)
	
	var drawn = 0
	if to_draw > 0:
		drawn = await draw_to_hand(MAX_HAND_SIZE, actual_hand_count)
		if drawn > 0:
			print("CardManager.play_selected: 成功补充了 %d 张卡牌" % drawn)
		else:
			print("CardManager.play_selected: 未能补充卡牌，可能牌库已空")
	else:
		print("CardManager.play_selected: 手牌已满，无需补充")
	
	# 再次获取当前手牌数量，确认补充结果
	if card_container:
		current_count = card_container.get_child_count()
		print("CardManager.play_selected: 补充后，当前手牌数量: %d/%d" % [current_count, MAX_HAND_SIZE])
	
	# 发送资源和分数变化信号
	game_mgr.emit_signal("resources_changed", game_mgr.focus_count, game_mgr.essence_count, game_mgr.remaining_runes)
	game_mgr.emit_signal("score_changed", game_mgr.score)
	
	# 检查胜利条件
	if game_mgr.score >= game_mgr.VICTORY_SCORE:
		print("CardManager.play_selected: 达成胜利条件！")
		game_mgr.emit_signal("game_won")
	
	print("CardManager.play_selected: 执行完成")
	return true

# 弃置选中的卡牌
func discard_selected() -> bool:
	print("CardManager.discard_selected: 开始执行")
	
	# 获取HandDock中选中的卡牌
	var hand_dock = main_game.hand_dock
	if not hand_dock:
		print("CardManager.discard_selected: 错误 - 找不到手牌容器")
		return false
	
	# 检查是否有选中的卡牌
	if hand_dock.selected_cards.size() == 0:
		print("CardManager.discard_selected: 未选择卡牌")
		if main_game.has_method("set_status"):
			main_game.set_status("请先选择要弃置的卡牌")
		return false
	
	# 检查GameManager是否存在并获取资源
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		print("CardManager.discard_selected: GameManager不存在")
		return false
	
	# 按任务要求：检查并消耗精华
	if game_mgr.essence_count <= 0:
		print("CardManager.discard_selected: 精华不足，无法弃牌")
		if main_game.has_method("set_status"):
			main_game.set_status("精华不足，无法弃置卡牌")
		return false
	
	# 消耗一点精华（每次操作只消耗一点，不管选了几张牌）
	print("CardManager.discard_selected: 消耗一点精华")
	game_mgr.essence_count -= 1
	
	# 保存选中的卡牌副本，因为在移除过程中会清空selected_cards数组
	var selected_cards = []
	for card in hand_dock.selected_cards:
		selected_cards.append(card)
	
	# 处理所有选中的卡牌
	var selected_count = selected_cards.size()
	print("CardManager.discard_selected: 处理 %d 张选中的卡牌" % selected_count)
	
	# 获取当前手牌数量（在移除前）
	var card_container = hand_dock.get_node_or_null("CardContainer")
	var current_count = 0
	if card_container:
		current_count = card_container.get_child_count()
		print("CardManager.discard_selected: 移除前，当前手牌数量: %d/%d" % [current_count, MAX_HAND_SIZE])
	
	# 打印卡牌详情
	print("CardManager.discard_selected: 当前选中的卡牌:")
	for card in selected_cards:
		# 获取卡牌数据
		var card_data = card.get_card_data() if card.has_method("get_card_data") else null
		if not card_data:
			continue
			
		print("  - %s (花色: %s, 点数: %d, 分值: %d)" % [
			card_data.name, card_data.suit, card_data.value, card_data.point
		])
		
		# 从手牌移除
		main_game.hand_dock.remove_card(card)
	
	# 清除选中状态
	hand_dock.selected_cards.clear()
	
	# 计算移除后的实际手牌数量（不依赖场景树计数）
	var actual_hand_count = current_count - selected_count
	print("CardManager.discard_selected: 移除卡牌后，实际手牌数量: %d/%d" % [actual_hand_count, MAX_HAND_SIZE])
	
	# 立即补充手牌至指定上限
	print("CardManager.discard_selected: 立即补充手牌")
	var to_draw = MAX_HAND_SIZE - actual_hand_count
	print("CardManager.discard_selected: 需要补充 %d 张卡牌" % to_draw)
	
	var drawn = 0
	if to_draw > 0:
		drawn = await draw_to_hand(MAX_HAND_SIZE, actual_hand_count)
		if drawn > 0:
			print("CardManager.discard_selected: 成功补充了 %d 张卡牌" % drawn)
		else:
			print("CardManager.discard_selected: 未能补充卡牌，可能牌库已空")
	else:
		print("CardManager.discard_selected: 手牌已满，无需补充")
	
	# 再次获取当前手牌数量，确认补充结果
	if card_container:
		current_count = card_container.get_child_count()
		print("CardManager.discard_selected: 补充后，当前手牌数量: %d/%d" % [current_count, MAX_HAND_SIZE])
	
	# 发送资源变化信号
	game_mgr.emit_signal("resources_changed", game_mgr.focus_count, game_mgr.essence_count, game_mgr.remaining_runes)
	
	print("CardManager.discard_selected: 执行完成")
	return true

# 手牌补充至指定数量
func draw_to_hand(max_size: int = MAX_HAND_SIZE, current_count: int = -1):
	print("CardManager.draw_to_hand: 开始补充手牌至 %d 张" % max_size)
	
	# 检查GameManager是否存在
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		print("CardManager.draw_to_hand: GameManager不存在")
		return 0
	
	# 获取HandDock
	var hand_dock = main_game.hand_dock
	if not hand_dock:
		print("CardManager.draw_to_hand: 错误 - 找不到HandDock")
		return 0
	
	# 获取当前手牌数量
	var card_container = hand_dock.get_node_or_null("CardContainer")
	if not card_container:
		print("CardManager.draw_to_hand: 错误 - 找不到CardContainer")
		return 0
	
	# 计算需要补充的卡牌数量
	var actual_count = current_count
	if actual_count < 0:
		# 如果没有传入当前手牌数，则从场景树中获取
		actual_count = card_container.get_child_count()
		print("CardManager.draw_to_hand: 从场景树获取当前手牌数: %d" % actual_count)
	else:
		print("CardManager.draw_to_hand: 使用传入的当前手牌数: %d" % actual_count)
	
	var to_draw = max_size - actual_count
	
	print("CardManager.draw_to_hand: 当前手牌数量 %d，需要补充 %d 张" % [actual_count, to_draw])
	
	# 如果已经达到上限，无需补充
	if to_draw <= 0:
		print("CardManager.draw_to_hand: 手牌已达到上限，无需补充")
		return 0
	
	# 检查牌库是否有足够的牌
	if game_mgr.remaining_runes <= 0:
		print("CardManager.draw_to_hand: 牌库已空，无法补充")
		return 0
		
	print("CardManager.draw_to_hand: 牌库中还有 %d 张牌" % game_mgr.remaining_runes)
	
	# 简化抽牌逻辑：循环抽取指定数量的卡牌
	var cards_drawn = 0
	for i in range(to_draw):
		# 停止条件：如果已经抽满或者牌库为空
		if cards_drawn >= to_draw:
			print("CardManager.draw_to_hand: 已补充足够的卡牌")
			break
		
		# 从GameManager抽取一张卡牌
		print("CardManager.draw_to_hand: 尝试从GameManager抽取第 %d 张卡牌" % (i+1))
		var card_data = game_mgr.draw_rune()
		if not card_data:
			print("CardManager.draw_to_hand: 牌库已空，只抽取了 %d 张" % cards_drawn)
			break
		
		print("CardManager.draw_to_hand: 抽取了卡牌 %s (花色: %s, 点数: %d)" % [card_data.name, card_data.suit, card_data.value])
		
		# 创建卡牌实例
		var card_instance = create_card_instance(card_data)
		if card_instance:
			# 添加到手牌
			var add_result = hand_dock.add_card(card_instance)
			if add_result:
				cards_drawn += 1
				print("CardManager.draw_to_hand: 成功添加卡牌到手牌")
			else:
				print("CardManager.draw_to_hand: 添加卡牌到手牌失败")
				card_instance.queue_free() # 清理未成功添加的卡牌实例
		else:
			print("CardManager.draw_to_hand: 创建卡牌实例失败")
	
	# 再次获取当前手牌数量，确认补充结果
	var final_count = card_container.get_child_count()
	print("CardManager.draw_to_hand: 手牌补充完成，共抽取 %d 张，当前手牌数: %d/%d" % 
		[cards_drawn, final_count, max_size])
	
	# 强制重新排列卡牌 - 确保卡牌位置正确
	if cards_drawn > 0 and hand_dock.has_method("_rearrange_cards"):
		print("CardManager.draw_to_hand: 调用_rearrange_cards重排卡牌")
		hand_dock._rearrange_cards()
	
	# 打印当前手牌详细信息
	print("CardManager.draw_to_hand: 当前手牌详细信息:")
	var index = 1
	for card in card_container.get_children():
		if card.has_method("get_card_data"):
			var card_data = card.get_card_data()
			if card_data:
				print("  %d. %s (花色: %s, 点数: %d, 分值: %d)" % 
					[index, card_data.name, card_data.suit, card_data.value, card_data.point])
		index += 1
	
	return cards_drawn

# 创建卡牌实例
func create_card_instance(card_data) -> Control:
	var card_scene = load("res://cs/卡牌系统/视图/Card.tscn")
	if not card_scene:
		print("CardManager.create_card_instance: 错误 - 找不到卡牌场景")
		return null
	
	var card_instance = card_scene.instantiate()
	if not card_instance:
		print("CardManager.create_card_instance: 错误 - 无法实例化卡牌场景")
		return null
	
	# 设置卡牌数据
	if card_instance.has_method("setup"):
		card_instance.setup(card_data)
		print("CardManager.create_card_instance: 成功创建卡牌 %s" % card_data.name)
	else:
		print("CardManager.create_card_instance: 警告 - 卡牌实例没有setup方法")
	
	return card_instance 
