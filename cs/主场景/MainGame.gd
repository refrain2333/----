extends Node2D

# 预加载卡牌场景和卡牌管理器
var Card = preload("res://cs/卡牌/Card.tscn")
# 注意：DeckManager已经作为节点在场景中，不需要预加载

# 游戏变量
var score = 0
var target_score = 500  # 目标分数
var magic_count = 0  # 魔法使用次数
var discard_count = 0  # 弃牌次数

# 手牌和牌桌
var hand = []  # 当前手牌
var table_cards = []  # 桌面上的卡牌

# 用于追踪界面元素的变量（稍后在ready中初始化）
var score_label
var target_score_label
var magic_count_label
var discard_count_label
var card_container
var deck_count_label
var hand_container

func _ready():
	# 初始化界面引用
	score_label = $MainContainer/LeftPanel/ScorePanel/ScoreLabel
	target_score_label = $MainContainer/LeftPanel/TargetPanel/TargetScore
	magic_count_label = $MainContainer/LeftPanel/MagicPanel/MagicCountLabel
	discard_count_label = $MainContainer/LeftPanel/DiscardPanel/DiscardCountLabel
	card_container = $MainContainer/CenterPanel/CardDisplayArea/CardContainer
	deck_count_label = $MainContainer/RightPanel/DeckPanel/CapacityLabel
	hand_container = $MainContainer/CenterPanel/HandContainer
	
	# 初始化UI
	update_ui()
	
	# 打印游戏启动信息
	print("游戏初始化完成")

# 更新界面显示
func update_ui():
	# 更新分数显示
	if score_label:
		score_label.text = str(score)
	
	# 更新目标分数
	if target_score_label:
		target_score_label.text = str(target_score)
	
	# 更新魔法使用次数
	if magic_count_label:
		magic_count_label.text = str(magic_count)
	
	# 更新弃牌次数
	if discard_count_label:
		discard_count_label.text = str(discard_count)
	
	# 更新牌组数量(这里使用35作为示例，实际应该从DeckManager获取)
	if deck_count_label:
		deck_count_label.text = str(35)

# 按钮事件处理
func _on_evaluate_button_pressed():
	# 模拟计算得分
	score += 50
	magic_count += 1
	update_ui()
	print("使用魔法！当前得分：", score)

func _on_new_hand_button_pressed():
	# 模拟弃牌
	discard_count += 1
	update_ui()
	print("弃牌！弃牌次数：", discard_count)

func _on_value_button_pressed():
	# 按点数排序
	print("按点数排序")

func _on_suit_button_pressed():
	# 按花色排序
	print("按花色排序")

func _on_options_button_pressed():
	# 打开选项菜单
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
	
