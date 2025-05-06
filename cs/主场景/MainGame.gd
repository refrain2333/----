extends Node2D

# 游戏状态变量
var current_score: int = 0
var target_score: int = 300
var plays_left: int = 5  # 修改为5次出牌机会
var hands_left: int = 3
var money: int = 4
var bet_value: int = 1
var max_bet: int = 8

# 游戏状态文本
var current_status: String = "请选择要出的牌"

# 资源预加载
var card_scene = preload("res://cs/主场景/Card.tscn")
var deck_manager_script = preload("res://cs/主场景/DeckManager.gd")

# 卡牌管理器
var deck_manager

# 当前的手牌
var current_hand = []
# 已打出的牌
var played_cards = []

# 当节点加入场景树时调用
func _ready():
	# 初始化卡牌管理器
	deck_manager = deck_manager_script.new()
	add_child(deck_manager)
	
	# 初始化随机数生成器
	randomize()
	
	# 重置并洗牌
	deck_manager.reset_and_shuffle()
	
	# 确保界面初始化
	update_ui()
	
	# 发起始手牌
	deal_initial_hand()
	
# 更新界面上的所有文本标签
func update_ui():
	# 更新分数显示
	$UIContainer/LeftPanel/VBoxContainer/ScorePanel/ScoreLabel.text = str(current_score)
	$UIContainer/LeftPanel/VBoxContainer/BlindPanel/TargetScoreContainer/TargetScore.text = str(target_score)
	$UIContainer/LeftPanel/VBoxContainer/PlaysPanel/HBoxContainer/PlayContainer/PlaysLeftLabel.text = str(plays_left)
	$UIContainer/LeftPanel/VBoxContainer/PlaysPanel/HBoxContainer/DiscardContainer/HandsLeftLabel.text = str(hands_left)
	$UIContainer/LeftPanel/VBoxContainer/MoneyPanel/MoneyContainer/MoneyLabel.text = str(money)
	$UIContainer/LeftPanel/VBoxContainer/BetPanel/HBoxContainer/BetValue.text = str(bet_value) + " / " + str(max_bet)
	
	# 更新牌堆计数器
	var remaining_cards = deck_manager.current_deck.size()
	var total_cards = 52
	$UIContainer/RightPanel/DeckCountLabel.text = str(remaining_cards) + " / " + str(total_cards)
	
	# 更新状态文本
	$UIContainer/StatusPanel/StatusLabel.text = current_status

# 设置状态文本
func set_status(text: String):
	current_status = text
	$UIContainer/StatusPanel/StatusLabel.text = current_status

# 发初始手牌
func deal_initial_hand():
	# 清空当前手牌显示
	clear_hand_display()
	
	# 从牌组中抽5张牌
	var card_data_array = deck_manager.deal_cards(5)
	
	# 为每张牌创建实例
	for i in range(card_data_array.size()):
		var card_data = card_data_array[i]
		var card_instance = create_card_instance(card_data)
		
		# 设置卡牌位置
		var card_spacing = 120  # 卡牌间距
		var start_x = 500  # 起始X位置
		card_instance.position = Vector2(start_x + i * card_spacing, 900)
		
		# 添加到当前场景
		add_child(card_instance)
		current_hand.append(card_instance)
	
	# 减少剩余手牌次数
	reduce_hands_left()
	
	# 更新状态
	set_status("新手牌已发放，请选择要出的牌")

# 清空手牌显示
func clear_hand_display():
	# 移除所有现有的卡牌实例
	for card in current_hand:
		if is_instance_valid(card):
			card.queue_free()
	
	# 清空手牌数组
	current_hand.clear()

# 创建卡牌实例
func create_card_instance(card_data):
	var card_instance = card_scene.instantiate()
	# 初始化卡牌属性
	card_instance.init_card(card_data.id, card_data.type, card_data.value)
	
	return card_instance

# 计分功能
func add_score(value: int):
	current_score += value
	update_ui()
	# 检查是否达到目标分数
	check_level_completion()

# 减少剩余出牌次数
func reduce_plays_left():
	plays_left -= 1
	update_ui()
	# 检查是否无法出牌
	if plays_left <= 0:
		handle_no_plays_left()

# 减少剩余手牌次数
func reduce_hands_left():
	hands_left -= 1
	update_ui()
	# 检查是否无法再抽新手牌
	if hands_left <= 0 and plays_left <= 0:
		handle_game_over()

# 增加/减少金币
func change_money(value: int):
	money += value
	update_ui()

# 按点数排序手牌
func sort_cards_by_value():
	# 按点数排序
	current_hand.sort_custom(func(a, b): return a.card_value < b.card_value)
	
	# 重新排列卡牌位置
	rearrange_hand_cards()
	
	# 更新状态
	set_status("手牌已按点数排序")

# 按花色排序手牌
func sort_cards_by_suit():
	# 按花色排序
	current_hand.sort_custom(func(a, b): 
		if a.card_type == b.card_type:
			return a.card_value < b.card_value
		else:
			return a.card_type < b.card_type
	)
	
	# 重新排列卡牌位置
	rearrange_hand_cards()
	
	# 更新状态
	set_status("手牌已按花色排序")

# 重新排列手牌位置
func rearrange_hand_cards():
	var card_spacing = 120  # 卡牌间距
	var start_x = 500  # 起始X位置
	
	for i in range(current_hand.size()):
		var card = current_hand[i]
		card.original_position = Vector2(start_x + i * card_spacing, 900)
		# 创建一个补间动画使卡牌平滑移动
		var tween = create_tween()
		tween.tween_property(card, "position", card.original_position, 0.3)

# 检查牌型并计算分数
func evaluate_played_cards():
	# 获取已打出的卡牌数据，转换为DeckManager需要的格式
	var card_data_array = []
	for card in played_cards:
		var card_data = deck_manager.CardData.new(card.card_id, card.card_type, card.card_value)
		card_data_array.append(card_data)
	
	# 使用卡牌管理器评估牌型
	var hand_type = deck_manager.evaluate_hand(card_data_array)
	var score = deck_manager.get_hand_score(hand_type)
	var hand_name = deck_manager.get_hand_type_name(hand_type)
	
	# 显示牌型名称和得分
	print("牌型: ", hand_name, "，得分: ", score)
	
	# 添加分数
	add_score(score)
	
	# 更新状态
	set_status("获得 " + hand_name + "！得分：" + str(score) + " 点")
	
	# 清空已打出的牌
	clear_played_cards()

# 清空已打出的牌
func clear_played_cards():
	# 移除所有已打出的卡牌实例
	for card in played_cards:
		if is_instance_valid(card):
			card.queue_free()
	
	# 清空数组
	played_cards.clear()

# 检查关卡完成
func check_level_completion():
	if current_score >= target_score:
		print("恭喜！达到目标分数，关卡完成！")
		set_status("恭喜！达到目标分数" + str(target_score) + "，关卡完成！")
		# TODO: 这里可以添加关卡完成的逻辑，如显示成功消息、进入下一关等

# 处理出牌次数用尽
func handle_no_plays_left():
	if hands_left > 0:
		print("出牌次数已用尽，但仍可抽新手牌。")
		set_status("出牌次数已用尽，请使用"弃牌"获取新手牌")
		# TODO: 可以添加提示玩家抽新手牌的逻辑
	else:
		handle_game_over()

# 处理游戏结束
func handle_game_over():
	if current_score >= target_score:
		print("游戏成功完成！")
		set_status("游戏成功完成！最终得分：" + str(current_score))
		# TODO: 显示成功界面
	else:
		print("游戏失败，未达到目标分数！")
		set_status("游戏失败！未达到目标分数" + str(target_score))
		# TODO: 显示失败界面

# 接收卡牌放置在出牌区的信号
# 这个函数会被卡牌实例调用，检查是否可以放置在出牌区
func check_card_in_play_area(card_instance) -> bool:
	# 获取出牌区域的全局位置和尺寸
	var play_area = $UIContainer/PlayArea/CardDisplayArea
	var play_area_rect = Rect2(
		play_area.global_position,
		play_area.size
	)
	
	# 检查卡牌是否在出牌区域内
	if play_area_rect.has_point(card_instance.global_position):
		# 确认出牌(如果还有出牌次数)
		if plays_left > 0:
			# 移除这张牌从手牌中
			current_hand.erase(card_instance)
			# 添加到已打出牌中
			played_cards.append(card_instance)
			# 减少出牌次数
			reduce_plays_left()
			# 放置到出牌区中央
			card_instance.global_position = $UIContainer/PlayArea/CardDisplayArea.global_position + Vector2(400, 120)
			
			# 更新状态
			var card_name = card_instance.get_card_name()
			set_status("已出牌：" + card_name + "，点击"出牌"按钮评估")
			
			return true
		else:
			# 更新状态
			set_status("出牌次数已用尽！请使用"弃牌"获取新手牌")
	
	return false

# 按钮事件处理函数 - 抽新手牌（弃牌）
func _on_new_hand_button_pressed():
	if hands_left > 0:
		deal_initial_hand()
	else:
		print("没有剩余手牌次数了！")
		set_status("没有剩余手牌次数了！")

# 按钮事件处理函数 - 结算当前出牌
func _on_evaluate_button_pressed():
	if played_cards.size() > 0:
		evaluate_played_cards()
	else:
		print("请先出牌！")
		set_status("请先将卡牌拖到出牌区！")

# 点数排序按钮事件
func _on_value_button_pressed():
	sort_cards_by_value()

# 花色排序按钮事件
func _on_suit_button_pressed():
	sort_cards_by_suit()

# 选项按钮事件
func _on_options_button_pressed():
	print("打开选项菜单")
	set_status("即将推出：选项菜单")
	# TODO: 实现选项菜单 
