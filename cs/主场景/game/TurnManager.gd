class_name PlayTurnManager
extends Node

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 信号 - 遵循项目信号命名规范
signal turn_started(phase)
signal turn_ended
signal phase_changed(old_phase, new_phase)
signal cards_selected(selected_cards)
signal cards_deselected(deselected_cards)
signal cards_played(played_cards, score_gained)
signal play_button_state_changed(enabled, reason)
signal concentration_changed(current, required)
signal selection_limit_reached(max_count)
signal play_phase_started
signal play_phase_ended
signal selection_cleared

# 回合状态枚举
enum TurnPhase {
	DRAW_PHASE,		# 抽牌阶段
	PLAY_PHASE,		# 出牌阶段
	SCORE_PHASE,	# 计分阶段
	END_PHASE		# 结束阶段
}

# 状态变量
var current_phase: TurnPhase = TurnPhase.DRAW_PHASE
var selected_cards: Array[CardData] = []
var is_player_turn: bool = false
var turn_number: int = 0

# 配置参数
var max_selection_count: int = 5
var base_concentration_cost: int = 1
var min_cards_to_play: int = 1

# 组件引用
var card_manager: CardManager = null
var game_manager = null
var event_manager = null
var game_scene = null

# UI组件引用
var hand_dock = null
var play_button = null

# 外部验证回调（用于次数限制等）
var external_play_validator: Callable = Callable()

# 初始化
func _ready():
	# 延迟初始化单例引用，避免在_ready阶段访问可能未完全初始化的单例
	call_deferred("_initialize_singletons")
	print("TurnManager: 初始化完成")

# 延迟初始化单例引用
func _initialize_singletons():
	# 获取全局管理器引用
	game_manager = Engine.get_singleton("GameManager")
	event_manager = Engine.get_singleton("EventManager")

	if not game_manager:
		# 在测试环境中，可能没有注册GameManager单例，这是正常的
		print("TurnManager: GameManager单例不可用（可能在测试环境中）")
	if not event_manager:
		# 在测试环境中，可能没有注册EventManager单例，这是正常的
		print("TurnManager: EventManager单例不可用（可能在测试环境中）")

	# 连接GameManager信号（如果可用）
	_connect_game_manager_signals()

# 设置组件引用
func setup(card_mgr: CardManager, hand_dock_ref = null, play_btn = null):
	card_manager = card_mgr
	hand_dock = hand_dock_ref
	play_button = play_btn

	# 连接CardManager信号
	if card_manager:
		if card_manager.has_signal("hand_changed"):
			card_manager.hand_changed.connect(_on_hand_changed)
		if card_manager.has_signal("cards_played"):
			card_manager.cards_played.connect(_on_cards_played_to_manager)

	# 连接出牌按钮信号
	if play_button and play_button.has_signal("pressed"):
		play_button.pressed.connect(_on_play_button_pressed)

	print("TurnManager: 组件设置完成")

# 连接GameManager信号
func _connect_game_manager_signals():
	if game_manager and game_manager.has_signal("resources_changed"):
		if not game_manager.is_connected("resources_changed", _on_resources_changed):
			game_manager.resources_changed.connect(_on_resources_changed)

# 开始新回合
func start_new_turn():
	turn_number += 1
	current_phase = TurnPhase.DRAW_PHASE
	is_player_turn = true
	selected_cards.clear()
	
	print("TurnManager: 开始第 %d 回合" % turn_number)
	emit_signal("turn_started", current_phase)

	# 执行抽牌阶段
	_execute_draw_phase()

# 执行抽牌阶段
func _execute_draw_phase():
	print("TurnManager: 执行抽牌阶段")
	
	if card_manager:
		# 计算抽牌数量（考虑事件效果）
		var draw_count = _calculate_draw_count()

		# 执行抽牌
		var drawn_cards = card_manager.draw(draw_count)
		print("TurnManager: 抽取了 %d 张卡牌" % drawn_cards.size())
	
	# 进入出牌阶段
	_change_phase(TurnPhase.PLAY_PHASE)

# 计算抽牌数量（考虑事件效果）
func _calculate_draw_count() -> int:
	var base_count = 1  # 默认抽牌数量

	# 尝试从GameManager获取基础抽牌数量
	if game_manager:
		if game_manager.has_method("get_base_draw_count"):
			base_count = game_manager.get_base_draw_count()
		elif "base_draw_count" in game_manager:
			base_count = game_manager.base_draw_count

	var bonus_count = 0

	# 检查EventManager的抽牌加成效果
	if event_manager and event_manager.has_method("get_active_effects"):
		var effects = event_manager.get_active_effects()
		if effects.has("extra_draw"):
			bonus_count = effects.extra_draw
			print("TurnManager: 额外抽牌效果 +%d" % bonus_count)

	return base_count + bonus_count

# 切换回合阶段
func _change_phase(new_phase: TurnPhase):
	var old_phase = current_phase
	current_phase = new_phase

	print("TurnManager: 阶段切换 %s -> %s" % [_get_phase_name(old_phase), _get_phase_name(new_phase)])
	emit_signal("phase_changed", old_phase, new_phase)

	# 根据新阶段执行相应逻辑
	match new_phase:
		TurnPhase.PLAY_PHASE:
			_enter_play_phase()
		TurnPhase.SCORE_PHASE:
			_enter_score_phase()
		TurnPhase.END_PHASE:
			_enter_end_phase()

# 进入出牌阶段
func _enter_play_phase():
	print("TurnManager: 进入出牌阶段")
	emit_signal("play_phase_started")
	_update_play_button_state()

# 进入计分阶段
func _enter_score_phase():
	print("TurnManager: 进入计分阶段")

# 进入结束阶段
func _enter_end_phase():
	print("TurnManager: 进入结束阶段")
	_end_turn()

# 选择卡牌
func select_card(card_data: CardData) -> bool:
	if not is_player_turn or current_phase != TurnPhase.PLAY_PHASE:
		print("TurnManager: 当前不是出牌阶段，无法选择卡牌")
		return false
	
	if selected_cards.size() >= max_selection_count:
		print("TurnManager: 已达到最大选择数量 (%d)" % max_selection_count)
		emit_signal("selection_limit_reached", max_selection_count)
		return false
	
	if card_data in selected_cards:
		print("TurnManager: 卡牌已被选择")
		return false
	
	selected_cards.append(card_data)
	print("TurnManager: 选择卡牌 %s，当前已选 %d/%d 张" % [card_data.name, selected_cards.size(), max_selection_count])
	emit_signal("cards_selected", selected_cards.duplicate())
	_update_play_button_state()
	return true

# 取消选择卡牌
func deselect_card(card_data: CardData) -> bool:
	var index = selected_cards.find(card_data)
	if index == -1:
		print("TurnManager: 卡牌未被选择")
		return false
	
	selected_cards.remove_at(index)
	print("TurnManager: 取消选择卡牌 %s，当前已选 %d/%d 张" % [card_data.name, selected_cards.size(), max_selection_count])
	emit_signal("cards_deselected", [card_data])
	_update_play_button_state()
	return true

# 清空选择
func clear_selection():
	if selected_cards.size() > 0:
		var deselected = selected_cards.duplicate()
		selected_cards.clear()
		print("TurnManager: 清空卡牌选择")
		emit_signal("selection_cleared")
		emit_signal("cards_deselected", deselected)
		_update_play_button_state()

# 打出选中的卡牌
func play_selected_cards() -> bool:
	# 首先保存已选卡牌的副本（在任何处理之前）
	var played_cards_copy = selected_cards.duplicate()

	# 外部验证（例如次数限制检查）
	if external_play_validator.is_valid():
		var external_result = external_play_validator.call()
		if not external_result:
			print("TurnManager: 外部验证失败，无法出牌")
			return false

	var check_result = can_play_cards()
	if not check_result.can_play:
		print("TurnManager: 无法出牌 - %s" % check_result.reason)
		return false

	if played_cards_copy.size() == 0:
		print("TurnManager: 没有选择卡牌")
		return false

	print("TurnManager: 执行出牌，选择的卡牌数量: %d" % played_cards_copy.size())

	# 进入计分阶段
	_change_phase(TurnPhase.SCORE_PHASE)

	# 简化的得分计算（使用保存的副本）
	var score = _calculate_simple_score(played_cards_copy)
	print("TurnManager: 计算得分: %d" % score)

	# 应用EventManager的得分修正
	score = _apply_score_modifiers(score)

	# 简化的出牌处理（使用保存的副本）
	if card_manager:
		# 直接从手牌中移除卡牌
		for card_data in played_cards_copy:
			var index = card_manager.hand.find(card_data)
			if index >= 0:
				card_manager.hand.remove_at(index)
				card_manager.discard_pile.append(card_data)
				print("TurnManager: 移除卡牌 %s 从手牌到弃牌堆" % card_data.name)

		# 发送手牌变化信号
		if card_manager.has_signal("hand_changed"):
			card_manager.emit_signal("hand_changed", card_manager.hand)

	# 更新GameManager分数
	if game_manager:
		game_manager.add_assessment_score(score)

	# 消耗集中力
	var concentration_cost = _calculate_concentration_cost()
	_consume_concentration(concentration_cost)

	# 发送出牌信号
	emit_signal("cards_played", played_cards_copy, score)

	# 清空选择状态
	selected_cards.clear()
	if hand_dock and hand_dock.has_method("clear_selection"):
		hand_dock.clear_selection()

	# 自动补牌到目标手牌数量
	_auto_refill_hand()

	# 检查是否应该继续留在出牌阶段
	# 只有在特定条件下才结束回合（比如达到出牌次数限制）
	# 现在我们让玩家可以继续出牌，直到手动结束回合
	print("TurnManager: 出牌完成，继续留在出牌阶段")

	# 重新进入出牌阶段（刷新状态）
	_change_phase(TurnPhase.PLAY_PHASE)
	return true

# 应用得分修正效果
func _apply_score_modifiers(base_score: int) -> int:
	var final_score = base_score

	if event_manager and event_manager.has_method("get_active_effects"):
		var effects = event_manager.get_active_effects()

		# 应用得分加成
		if effects.has("score_bonus"):
			final_score += effects.score_bonus
			print("TurnManager: 得分加成效果 +%d" % effects.score_bonus)

		# 应用得分倍率
		if effects.has("score_multiplier"):
			final_score = int(final_score * effects.score_multiplier)
			print("TurnManager: 得分倍率效果 x%.2f" % effects.score_multiplier)

	return final_score

# 简化的得分计算（用于测试）
func _calculate_simple_score(cards: Array) -> int:
	var total_score = 0

	# 基础得分：卡牌数值总和
	for card_data in cards:
		total_score += card_data.base_value
		print("TurnManager: 卡牌 %s 贡献 %d 分" % [card_data.name, card_data.base_value])

	# 简单的组合加成
	var card_count = cards.size()
	if card_count >= 3:
		var combo_bonus = card_count * 2  # 每张额外卡牌+2分
		total_score += combo_bonus
		print("TurnManager: %d张卡牌组合加成 +%d 分" % [card_count, combo_bonus])

	print("TurnManager: 总得分 %d 分" % total_score)
	return total_score

# 自动补牌到目标手牌数量
func _auto_refill_hand():
	if not card_manager:
		print("TurnManager: 无CardManager，跳过自动补牌")
		return

	var target_hand_size = 5  # 目标手牌数量
	var current_hand_size = card_manager.hand.size()
	var cards_to_draw = target_hand_size - current_hand_size

	if cards_to_draw > 0:
		print("TurnManager: 自动补牌 %d 张 (当前: %d, 目标: %d)" % [cards_to_draw, current_hand_size, target_hand_size])

		# 从牌堆抽取卡牌
		var drawn_cards = card_manager.draw(cards_to_draw)
		print("TurnManager: 实际抽取了 %d 张卡牌" % drawn_cards.size())

		# HandDock会通过hand_changed信号自动同步，无需手动创建视图
		print("TurnManager: HandDock将通过信号自动更新视图")
	else:
		print("TurnManager: 手牌已满，无需补牌 (当前: %d)" % current_hand_size)

# 为新抽取的卡牌创建视图（使用批量添加优化）
func _create_card_views_for_drawn_cards(drawn_cards: Array):
	print("TurnManager: 为 %d 张新卡牌创建视图" % drawn_cards.size())

	var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")
	var card_views = []

	for card_data in drawn_cards:
		# 创建卡牌视图
		var card_view = card_scene.instantiate()

		# 设置卡牌数据
		card_view.setup(card_data)

		# 添加到批量数组
		card_views.append(card_view)

		print("TurnManager: 创建新卡牌视图 %s" % card_data.name)

	# 批量添加到HandDock（避免频繁重排）
	if hand_dock and hand_dock.has_method("add_cards_batch"):
		print("TurnManager: 使用批量添加方法")
		hand_dock.add_cards_batch(card_views)
	elif hand_dock:
		print("TurnManager: 回退到逐个添加")
		for card_view in card_views:
			hand_dock.add_card(card_view)
	else:
		print("TurnManager: 跳过卡牌视图添加 - HandDock不存在")

# 消耗集中力
func _consume_concentration(amount: int):
	print("TurnManager: 消耗集中力 %d" % amount)

# 结束回合
func _end_turn():
	# 注意：不要设置is_player_turn = false，这样会阻止开始新回合
	selected_cards.clear()

	print("TurnManager: 回合结束")
	emit_signal("turn_ended")
	emit_signal("play_phase_ended")

	# 通知EventManager回合结束
	if event_manager and event_manager.has_method("on_turn_end"):
		event_manager.on_turn_end()

# 手动结束回合（供外部调用）
func end_turn():
	_end_turn()

# 获取当前选中的卡牌
func get_selected_cards() -> Array[CardData]:
	return selected_cards.duplicate()

# 获取当前回合阶段
func get_current_phase() -> TurnPhase:
	return current_phase

# 检查是否可以出牌
func can_play_cards() -> Dictionary:
	var result = {
		"can_play": false,
		"reason": ""
	}

	# 检查基本条件
	if not is_player_turn:
		result.reason = "不是玩家回合"
		return result

	if current_phase != TurnPhase.PLAY_PHASE:
		result.reason = "不在出牌阶段"
		return result

	if selected_cards.size() < min_cards_to_play:
		result.reason = "至少需要选择%d张卡牌" % min_cards_to_play
		return result

	# 检查集中力消耗
	var required_concentration = _calculate_concentration_cost()
	var current_concentration = _get_current_concentration()

	if current_concentration < required_concentration:
		result.reason = "集中力不足 (%d/%d)" % [current_concentration, required_concentration]
		return result

	result.can_play = true
	result.reason = "可以出牌"
	return result

# 计算集中力消耗
func _calculate_concentration_cost() -> int:
	var base_cost = base_concentration_cost
	var card_cost = selected_cards.size() * base_cost
	return card_cost

# 获取当前集中力
func _get_current_concentration() -> int:
	if game_manager:
		if game_manager.has_method("get_current_concentration"):
			return game_manager.get_current_concentration()
		elif "current_assessment_score" in game_manager:
			return game_manager.current_assessment_score
	return 100  # 默认集中力

# 更新出牌按钮状态
func _update_play_button_state():
	var check_result = can_play_cards()
	var enabled = check_result.can_play
	var reason = check_result.reason

	emit_signal("play_button_state_changed", enabled, reason)

	# 更新集中力显示
	var required = _calculate_concentration_cost()
	var current = _get_current_concentration()
	emit_signal("concentration_changed", current, required)

# 出牌按钮点击处理
func _on_play_button_pressed():
	print("TurnManager: 出牌按钮被点击")
	play_selected_cards()

# 信号处理函数
func _on_hand_changed(hand_cards: Array):
	print("TurnManager: 手牌变化，当前手牌数量: %d" % hand_cards.size())

	# 检查选择的卡牌是否还在手牌中
	var cards_to_remove = []
	for card in selected_cards:
		if card not in hand_cards:
			cards_to_remove.append(card)

	# 移除不在手牌中的选择
	for card in cards_to_remove:
		deselect_card(card)

func _on_cards_played_to_manager(played_cards: Array, score: int):
	print("TurnManager: 收到CardManager的出牌确认")

func _on_resources_changed(lore: int, score: int, runes: int):
	# 资源变化时更新出牌按钮状态
	_update_play_button_state()

# 工具函数
func _get_phase_name(phase: TurnPhase) -> String:
	match phase:
		TurnPhase.DRAW_PHASE: return "抽牌阶段"
		TurnPhase.PLAY_PHASE: return "出牌阶段"
		TurnPhase.SCORE_PHASE: return "计分阶段"
		TurnPhase.END_PHASE: return "结束阶段"
		_: return "未知阶段"

# 获取回合信息
func get_turn_info() -> Dictionary:
	return {
		"turn_number": turn_number,
		"current_phase": current_phase,
		"phase_name": _get_phase_name(current_phase),
		"is_player_turn": is_player_turn,
		"selected_count": selected_cards.size(),
		"max_selection": max_selection_count,
		"can_play": can_play_cards().can_play
	}

# HandDock请求新卡牌的接口（支持智能卡牌替换）
func request_cards_for_hand(count: int) -> Array:
	if not card_manager:
		LogManager.error("TurnManager", "CardManager未设置，无法提供卡牌")
		return []

	LogManager.info("TurnManager", "HandDock请求%d张新卡牌" % count)

	# 通过CardManager抽取新卡牌
	var new_cards = []
	for i in range(count):
		var drawn_cards = card_manager.draw(1)
		if drawn_cards.size() > 0:
			new_cards.append_array(drawn_cards)
		else:
			LogManager.warning("TurnManager", "牌库已空，无法继续抽牌")
			break

	LogManager.info("TurnManager", "成功提供%d张卡牌给HandDock" % new_cards.size())
	return new_cards

# 🔧 获取CardManager引用（用于HandDock连接信号）
func get_card_manager() -> CardManager:
	return card_manager
