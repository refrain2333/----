class_name CardManager
extends Node

var main_game  # 引用主场景

# 卡牌预制体
var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")

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
func play_selected():
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
		print("CardManager.play_selected: 集中力不足，无法打出")
		if main_game.has_method("set_status"):
			main_game.set_status("集中力不足，无法打出卡牌")
		return false
	
	# 消耗一点集中力（每次操作只消耗一点，不管选了几张牌）
	print("CardManager.play_selected: 消耗一点集中力")
	game_mgr.focus_count -= 1
	
	# 处理所有选中的卡牌
	var total_points = 0
	print("CardManager.play_selected: 处理 %d 张选中的卡牌" % hand_dock.selected_cards.size())
	
	for card in hand_dock.selected_cards:
		# 获取卡牌数据
		var card_data = card.get_card_data() if card.has_method("get_card_data") else null
		if not card_data:
			continue
			
		# 获取卡牌分数
		var points = card_data.point if card_data.has("point") else 1
		total_points += points
		print("CardManager.play_selected: 卡牌 %s 提供 %d 分" % [card_data.name, points])
		
		# 从手牌移除
		main_game.hand_dock.remove_card(card)
	
	# 增加分数
	if total_points > 0:
		print("CardManager.play_selected: 增加总分 %d 分" % total_points)
		game_mgr.score += total_points
	
	# 发送资源和分数变化信号
	game_mgr.emit_signal("resources_changed", game_mgr.focus_count, game_mgr.essence_count, game_mgr.remaining_runes)
	game_mgr.emit_signal("score_changed", game_mgr.score)
	
	# 检查胜利条件
	if game_mgr.score >= game_mgr.VICTORY_SCORE:
		print("CardManager.play_selected: 达成胜利条件！")
		game_mgr.emit_signal("game_won")
	
	# 清除选中状态
	hand_dock.selected_cards.clear()
	
	# 手牌补充至5张
	draw_to_hand(5)
	
	print("CardManager.play_selected: 执行完成")
	return true

# 弃置选中的卡牌
func discard_selected():
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
	
	# 处理所有选中的卡牌
	print("CardManager.discard_selected: 处理 %d 张选中的卡牌" % hand_dock.selected_cards.size())
	
	for card in hand_dock.selected_cards:
		# 获取卡牌数据
		var card_data = card.get_card_data() if card.has_method("get_card_data") else null
		if not card_data:
			continue
			
		print("CardManager.discard_selected: 弃置卡牌 %s" % card_data.name)
		
		# 从手牌移除
		main_game.hand_dock.remove_card(card)
	
	# 发送资源变化信号
	game_mgr.emit_signal("resources_changed", game_mgr.focus_count, game_mgr.essence_count, game_mgr.remaining_runes)
	
	# 清除选中状态
	hand_dock.selected_cards.clear()
	
	# 手牌补充至5张
	draw_to_hand(5)
	
	print("CardManager.discard_selected: 执行完成")
	return true

# 手牌补充至指定数量
func draw_to_hand(max_size: int = 5):
	print("CardManager.draw_to_hand: 开始补充手牌至 %d 张" % max_size)
	
	# 检查GameManager是否存在
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		print("CardManager.draw_to_hand: GameManager不存在")
		return
	
	# 获取HandDock
	var hand_dock = main_game.hand_dock
	if not hand_dock:
		print("CardManager.draw_to_hand: 错误 - 找不到HandDock")
		return
	
	# 获取当前手牌数量
	var card_container = hand_dock.get_node_or_null("CardContainer")
	if not card_container:
		print("CardManager.draw_to_hand: 错误 - 找不到CardContainer")
		return
		
	var current_count = card_container.get_child_count()
	var to_draw = max_size - current_count
	
	print("CardManager.draw_to_hand: 当前手牌数量 %d，需要补充 %d 张" % [current_count, to_draw])
	
	# 抽取卡牌
	for i in range(to_draw):
		# 检查手牌是否已满
		if game_mgr.is_hand_full():
			print("CardManager.draw_to_hand: 手牌已满，无法抽取更多")
			break
		
		# 抽牌
		var card_data = game_mgr.draw_rune()
		if not card_data:
			print("CardManager.draw_to_hand: 牌库已空")
			break
		
		print("CardManager.draw_to_hand: 抽取卡牌 %s" % card_data.name)
		
		# 创建卡牌实例
		var card_scene = load("res://cs/卡牌系统/视图/Card.tscn")
		if card_scene:
			var card_instance = card_scene.instantiate()
			if card_instance:
				# 设置卡牌数据
				card_instance.setup(card_data)
				
				# 添加到手牌
				hand_dock.add_card(card_instance)
		else:
			print("CardManager.draw_to_hand: 错误 - 找不到卡牌场景")
	
	print("CardManager.draw_to_hand: 手牌补充完毕") 