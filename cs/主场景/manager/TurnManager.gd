class_name TurnManager
extends Node

# 回合状态枚举
enum TurnState {
	DRAW,    # 抽牌阶段
	ACTION,  # 行动阶段
	RESOLVE, # 结算阶段
	END      # 结束阶段
}

# 当前回合状态
var current_state: TurnState = TurnState.DRAW
var current_turn: int = 0  # 从0开始，start_turn时自增到1
var main_game  # 引用主场景

# 信号
signal turn_started(turn_number)  # 回合开始
signal turn_ended(turn_number)    # 回合结束
signal turn_state_changed(old_state, new_state)  # 状态变化
signal play_recorded(card_data)   # 记录了出牌

# 构造函数
func _init(game_scene):
	main_game = game_scene
	
	# 连接特效编排器的信号
	if game_scene.effect_orchestrator:
		game_scene.effect_orchestrator.effect_queue_empty.connect(_on_effect_queue_empty)

# 开始新回合
func start_turn():
	current_turn += 1
	
	# 重置回合状态
	_reset_turn_state()
	
	# 发出回合开始信号
	emit_signal("turn_started", current_turn)
	
	# 转换到抽牌阶段
	change_state(TurnState.DRAW)

# 结束当前回合
func end_turn():
	if current_state == TurnState.ACTION:
		change_state(TurnState.RESOLVE)
	else:
		print("警告: 当前不在行动阶段，无法结束回合")

# 强制结束回合（用于测试或特殊情况）
func force_end_turn():
	change_state(TurnState.END) 

# 改变回合状态
func change_state(new_state: TurnState):
	var old_state = current_state
	current_state = new_state
	
	# 发出状态改变信号
	emit_signal("turn_state_changed", old_state, new_state)
	
	# 执行新状态的逻辑
	match new_state:
		TurnState.DRAW:
			execute_draw_phase()
		TurnState.ACTION:
			execute_action_phase()
		TurnState.RESOLVE:
			execute_resolve_phase()
		TurnState.END:
			execute_end_phase()

# 执行抽牌阶段逻辑
func execute_draw_phase():
	print("执行抽牌阶段逻辑")
	
	# 通知GameManager抽牌阶段开始
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("on_draw_phase"):
			GameManager.on_draw_phase(current_turn)
	
	# 自动抽牌
	_auto_draw_card()
	
	# 激活抽牌阶段效果
	_trigger_phase_effects(TurnState.DRAW)
	
	# 转换到行动阶段
	call_deferred("change_state", TurnState.ACTION)

# 执行行动阶段逻辑
func execute_action_phase():
	print("执行行动阶段逻辑")
	
	# 通知GameManager行动阶段开始
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("on_action_phase"):
			GameManager.on_action_phase(current_turn)
	
	# 激活行动阶段效果
	_trigger_phase_effects(TurnState.ACTION)
	
	# 行动阶段不自动结束，由玩家操作触发

# 执行结算阶段逻辑
func execute_resolve_phase():
	print("执行结算阶段逻辑")
	
	# 通知GameManager结算阶段开始
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("on_resolve_phase"):
			GameManager.on_resolve_phase(current_turn)
	
	# 激活结算阶段效果
	_trigger_phase_effects(TurnState.RESOLVE)
	
	# 评估符文组合并显示分数
	var played_cards = main_game.game_state.played_cards
	if played_cards.size() > 0:
		var result = GameManager.evaluate_rune_combination(played_cards)
		var total_score = result.base_score * result.multiplier
		main_game.effect_orchestrator.show_score(total_score)
	
	# 结算分数和奖励
	_resolve_score_and_rewards()
	
	# 转换到结束阶段
	# 不再自动转到END阶段，将由EffectOrchestrator通知何时特效结束

# 执行结束阶段逻辑
func execute_end_phase():
	print("执行结束阶段逻辑")
	
	# 通知GameManager结束阶段开始
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("on_end_phase"):
			GameManager.on_end_phase(current_turn)
	
	# 激活结束阶段效果
	_trigger_phase_effects(TurnState.END)
	
	# 发出回合结束信号
	emit_signal("turn_ended", current_turn)
	
	# 自动开始新回合（延迟一帧，确保结束逻辑完成）
	call_deferred("start_turn")

# 记录出牌
func record_play(card):
	# 获取卡牌数据
	var card_data = _get_card_data(card)
	if not card_data:
		return
	
	# 记录到游戏状态
	main_game.game_state.record_played_card(card_data)
	
	# 更新分数
	_update_score(card_data)
	
	# 发出信号
	emit_signal("play_recorded", card_data)
	
	# 如果在行动阶段，转到结算阶段
	if current_state == TurnState.ACTION:
		change_state(TurnState.RESOLVE)
	
	# 检查集中力是否用尽
	_check_focus_depleted()

# 辅助方法：重置回合状态
func _reset_turn_state():
	main_game.game_state.reset_turn_state()
	
	# 通知GameManager重置回合状态
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("reset_turn_resources"):
			GameManager.reset_turn_resources()

# 辅助方法：自动抽牌
func _auto_draw_card():
	# 检查是否可以抽牌
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("can_draw_card") and GameManager.can_draw_card():
			GameManager.draw_card()

# 辅助方法：激活阶段效果
func _trigger_phase_effects(phase: TurnState):
	# 触发小丑卡被动效果
	var joker_mgr = main_game.find_child("JokerManager", true)
	if joker_mgr and joker_mgr.has_method("activate_passive_effects"):
		joker_mgr.activate_passive_effects(phase)

# 辅助方法：获取卡牌数据
func _get_card_data(card):
	if card.has_method("get_card_data"):
		return card.get_card_data()
	return null

# 辅助方法：更新分数
func _update_score(card_data):
	# 获取当前分数状态
	var base_score = main_game.game_state.score.base
	var multiplier = main_game.game_state.score.multiplier
	
	# 根据卡牌更新分数
	base_score += card_data.power if card_data.has("power") else 0
	
	# 根据元素类型更新倍数
	if card_data.has("element") and card_data.element == "fire":
		multiplier += 1
	
	# 更新游戏状态
	main_game.game_state.score.base = base_score
	main_game.game_state.score.multiplier = multiplier
	
	# 同步到GameManager
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("set_score_values"):
			GameManager.set_score_values(base_score, multiplier)

# 辅助方法：结算分数和奖励
func _resolve_score_and_rewards():
	# 计算最终分数
	var base_score = main_game.game_state.score.base
	var multiplier = main_game.game_state.score.multiplier
	var final_score = base_score * multiplier
	
	# 通知GameManager添加分数
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("add_score"):
			GameManager.add_score(final_score)
	
	# 处理奖励
	_process_rewards(final_score)

# 辅助方法：处理奖励
func _process_rewards(score_value: int):
	# 检查是否达到奖励阈值
	if score_value >= 100:
		# 触发小丑卡奖励
		var joker_mgr = main_game.find_child("JokerManager", true)
		if joker_mgr and joker_mgr.has_method("offer_joker_reward"):
			joker_mgr.offer_joker_reward()
	
	# 检查是否达到发现阈值
	if score_value >= 150:
		# 触发发现奖励
		var discovery_mgr = main_game.find_child("DiscoveryManager", true)
		if discovery_mgr and discovery_mgr.has_method("offer_discovery"):
			discovery_mgr.offer_discovery()

# 辅助方法：检查集中力是否用尽
func _check_focus_depleted():
	# 获取当前集中力
	var focus = main_game.game_state.resources.focus
	
	# 减少一点集中力
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("use_focus"):
			GameManager.use_focus()
	
	# 如果集中力已用尽，自动结束回合
	if focus <= 1:
		call_deferred("end_turn")

# 特效队列为空时的回调
func _on_effect_queue_empty():
	# 如果当前在结算阶段，则转到结束阶段
	if current_state == TurnState.RESOLVE:
		change_state(TurnState.END) 

# 连接UI信号
func connect_ui(hud: Node):
	# 不再需要连接end_turn_pressed信号，因为我们已经移除了EndTurnButton
	
	print("TurnManager: UI信号已连接")

# 处理结束回合按钮点击
func _on_end_turn_pressed():
	end_turn() 