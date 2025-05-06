extends Node2D

# 游戏状态变量 - 仅保留UI显示需要的变量
var current_score: int = 0
var target_score: int = 300
var plays_left: int = 5
var hands_left: int = 3
var money: int = 4
var bet_value: int = 1
var max_bet: int = 8

# 当节点加入场景树时调用
func _ready():
	# 初始化UI
	update_ui()

# 更新界面上的所有文本标签
func update_ui():
	# 更新魔力分数显示
	$UIContainer/LeftPanel/VBoxContainer/ScorePanel/ValueContainer/ScoreLabel.text = str(current_score)
	$UIContainer/LeftPanel/VBoxContainer/BlindPanel/TargetScore.text = str(target_score)
	
	# 更新施法和理论计数
	$UIContainer/LeftPanel/VBoxContainer/MagicPanel/HBoxContainer/MagicContainer/MagicCountLabel.text = str(plays_left)
	$UIContainer/LeftPanel/VBoxContainer/MagicPanel/HBoxContainer/TheoryContainer/TheoryCountLabel.text = str(hands_left)
	
	# 更新学业试炼级别
	$UIContainer/LeftPanel/VBoxContainer/PlaysPanel/HBoxContainer/StudyContainer/StudyLevelLabel.text = str(bet_value) + " / " + str(max_bet)
	
	# 更新牌堆计数器
	var remaining_cards = 44  # 固定值
	var total_cards = 52
	$UIContainer/RightPanel/CapacityLabel.text = str(remaining_cards) + " / " + str(total_cards)

# 按钮事件处理函数 - 简化为仅打印信息
func _on_new_hand_button_pressed():
	print("补充新牌")
	
# 按钮事件处理函数 - 结算当前出牌
func _on_evaluate_button_pressed():
	print("释放法术")
	
# 点数排序按钮事件
func _on_value_button_pressed():
	print("按数值排序")

# 花色排序按钮事件
func _on_suit_button_pressed():
	print("按花色排序")

# 选项按钮事件
func _on_options_button_pressed():
	print("打开选项菜单")

# 卡牌放置区域检查(保留简化版以防场景引用)
func check_card_in_play_area(_card_instance):
	print("尝试放置卡牌")
	return false

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

# 检查关卡完成
func check_level_completion():
	if current_score >= target_score:
		print("恭喜！达到目标分数，关卡完成！")
		# TODO: 这里可以添加关卡完成的逻辑，如显示成功消息、进入下一关等

# 处理出牌次数用尽
func handle_no_plays_left():
	if hands_left > 0:
		print("出牌次数已用尽，但仍可抽新手牌。")
		# TODO: 可以添加提示玩家抽新手牌的逻辑
	else:
		handle_game_over()

# 处理游戏结束
func handle_game_over():
	if current_score >= target_score:
		print("游戏成功完成！")
		# TODO: 显示成功界面
	else:
		print("游戏失败，未达到目标分数！")
		# TODO: 显示失败界面

func show_score_animation(value: int, position: Vector2):
	# 创建一个浮动文本显示得分
	var score_text = Label.new()
	score_text.text = "+" + str(value)
	score_text.position = position
	score_text.add_theme_color_override("font_color", Color(0.9, 0.95, 0.2, 1.0)) # 金色文字
	score_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	score_text.add_theme_constant_override("shadow_offset_x", 2)
	score_text.add_theme_constant_override("shadow_offset_y", 2)
	score_text.add_theme_font_size_override("font_size", 28)
	add_child(score_text)
	
	# 创建动画效果
	var tween = create_tween()
	tween.tween_property(score_text, "position", position + Vector2(0, -100), 1.0)
	tween.parallel().tween_property(score_text, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(score_text.queue_free)

# 从一个区域创建扇形发牌动画
func create_fan_deal_animation(card_instances, start_pos, target_positions, delay = 0.1):
	for i in range(card_instances.size()):
		var card = card_instances[i]
		var target_pos = target_positions[i]
		
		# 设置初始位置
		card.position = start_pos
		
		# 创建发牌动画
		var tween = create_tween()
		tween.set_delay(i * delay) # 每张牌发牌有延迟
		tween.tween_property(card, "position", target_pos, 0.3)
	
