extends Control

## 🔧 重构后的简化出牌系统测试
## 
## 使用组件化架构，代码量从1000+行减少到200行以内
## 所有复杂逻辑都封装在可复用的管理器组件中

# 导入组件类
const GameSessionConfig = preload("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd")
const TurnActionManager = preload("res://cs/卡牌系统/数据/管理器/TurnActionManager.gd")
const GameScoreManager = preload("res://cs/卡牌系统/数据/管理器/GameScoreManager.gd")
const DeckViewIntegrationManager = preload("res://cs/卡牌系统/数据/管理器/DeckViewIntegrationManager.gd")
const CardManager = preload("res://cs/卡牌系统/数据/管理器/CardManager.gd")

# UI组件引用
@onready var hand_dock = $HandDock
@onready var deck_widget = $DeckWidget
@onready var turn_info_label: Label = $TopInfoPanel/VBox/TurnInfoLabel
@onready var score_label: Label = $TopInfoPanel/VBox/ScoreLabel
@onready var start_turn_button: Button = $ControlPanel/VBox/StartTurnButton
@onready var next_turn_button: Button = $ControlPanel/VBox/NextTurnButton
@onready var status_text: Label = $StatusPanel/VBox/StatusText
@onready var actions_label: Label = $TopInfoPanel/VBox/ActionsLabel

# 🔧 完整组件系统 - 确保功能完全
var session_config: GameSessionConfig
var turn_action_manager: TurnActionManager
var score_manager: GameScoreManager
var deck_integration_manager: DeckViewIntegrationManager
var card_manager: CardManager
var card_effect_manager  # CardManager需要这个引用
var turn_manager  # TurnManager用于管理HandDock
var game_manager  # 模拟GameManager来提供资源管理

# 简化的初始化
func _ready():
	print("SimplePlayTest: 开始简化初始化")
	
	# 1. 加载配置
	_load_config()
	
	# 2. 创建管理器组件
	_create_managers()
	
	# 3. 初始化游戏
	_initialize_game()
	
	# 4. 连接信号
	_connect_signals()
	
	# 5. 设置UI
	_setup_ui()
	
	print("SimplePlayTest: 简化初始化完成")

# 🔧 清理资源
func _exit_tree():
	# 清理添加到/root的GameManager，避免影响其他场景
	var root_game_manager = get_tree().root.get_node_or_null("GameManager")
	if root_game_manager and root_game_manager == game_manager:
		root_game_manager.queue_free()
		print("SimplePlayTest: 已清理/root/GameManager")



# 🔧 步骤1：加载配置
func _load_config():
	var config_path = "res://assets/data/game_session_configs/default_session.tres"
	if ResourceLoader.exists(config_path):
		session_config = load(config_path)
	else:
		session_config = GameSessionConfig.create_default()
	
	print("SimplePlayTest: 配置加载完成 - %s" % session_config.get_config_summary())

# 🔧 步骤2：创建完整的管理器组件系统
func _create_managers():
	print("SimplePlayTest: 创建完整管理器组件系统")

	# 🔧 1. 创建简化GameManager（提供资源管理）
	_create_simple_game_manager()

	# 🔧 2. 创建CardEffectManager（CardManager需要）
	const CardEffectManagerData = preload("res://cs/卡牌系统/数据/管理器/CardEffectManager.gd")
	card_effect_manager = CardEffectManagerData.new()
	add_child(card_effect_manager)

	# 🔧 3. 创建卡牌管理器
	card_manager = CardManager.new(self)
	add_child(card_manager)

	# 🔧 4. 创建TurnManager来管理HandDock
	const PlayTurnManagerClass = preload("res://cs/主场景/game/TurnManager.gd")
	turn_manager = PlayTurnManagerClass.new()
	add_child(turn_manager)

	# 🔧 5. 设置TurnManager的外部验证器（连接到TurnActionManager）
	if turn_manager.has_method("set_external_play_validator"):
		turn_manager.set_external_play_validator(Callable(turn_action_manager, "can_perform_action").bind("play"))
		print("SimplePlayTest: TurnManager外部验证器已设置")

	print("SimplePlayTest: 完整管理器组件系统创建完成")

# 🔧 创建简化的GameManager来提供完整功能
func _create_simple_game_manager():
	# 使用预定义的SimpleGameManager类
	const SimpleGameManagerClass = preload("res://cs/tests/卡牌相关/出牌系统测试/SimpleGameManager.gd")
	game_manager = SimpleGameManagerClass.new()
	game_manager.name = "GameManager"  # 重要：使用正确的名称

	# 🔧 关键：将GameManager添加到/root路径，这样HandDock才能找到它
	get_tree().root.add_child(game_manager)

	print("SimplePlayTest: 简化GameManager已创建并添加到/root/GameManager路径")
	
	# 创建回合操作管理器
	turn_action_manager = TurnActionManager.new()
	add_child(turn_action_manager)
	
	# 创建得分管理器
	score_manager = GameScoreManager.new()
	
	# 创建牌库集成管理器
	deck_integration_manager = DeckViewIntegrationManager.new()
	add_child(deck_integration_manager)
	
	# 等待节点准备完成后配置
	await get_tree().process_frame
	
	# 配置管理器（使用call方法避免类型推断问题）
	if turn_action_manager.has_method("setup_with_config"):
		turn_action_manager.call("setup_with_config", session_config)

	if score_manager.has_method("setup_with_config"):
		score_manager.call("setup_with_config", session_config)

	if deck_integration_manager.has_method("update_config"):
		deck_integration_manager.call("update_config", session_config)

# 🔧 步骤3：完整初始化游戏系统
func _initialize_game():
	print("SimplePlayTest: 开始完整游戏系统初始化")

	# 🔧 1. 初始化牌库
	card_manager.initialize_deck()
	card_manager.shuffle_deck()

	# 🔧 2. 设置TurnManager与所有组件的完整连接
	_setup_turn_manager_connections()

	# 🔧 3. 设置牌库集成
	deck_integration_manager.setup(deck_widget, card_manager)

	# 🔧 4. 发放初始手牌并创建视图
	_deal_initial_hand_with_views()

	# 🔧 5. 连接所有信号
	_connect_all_signals()

	print("SimplePlayTest: 完整游戏系统初始化完成，手牌: %d张，牌库: %d张" % [
		card_manager.hand.size(), card_manager.deck.size()
	])

	# 🔧 重要：初始化完成后立即更新按钮状态
	_update_button_states()

	# 🔧 调试：检查TurnManager状态
	_debug_turn_manager_state()

	# 🔧 重要：确保TurnManager开始新回合（进入出牌阶段）
	if turn_manager and turn_manager.has_method("start_new_turn"):
		turn_manager.start_new_turn()
		print("SimplePlayTest: 已调用TurnManager.start_new_turn()")

		# 再次检查状态
		call_deferred("_debug_turn_manager_state")

	# 🔧 调试：检查按钮状态


# 🔧 设置TurnManager的完整连接（参考原始代码）
func _setup_turn_manager_connections():
	if not turn_manager:
		return

	print("SimplePlayTest: 设置TurnManager完整连接")

	# 🔧 关键：使用原始代码的setup方法
	if hand_dock:
		var play_button = hand_dock.get_node_or_null("ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton")
		if play_button:
			turn_manager.setup(card_manager, hand_dock, play_button)
			print("SimplePlayTest: TurnManager.setup完成（包含play_button）")
		else:
			turn_manager.setup(card_manager, hand_dock)
			print("SimplePlayTest: TurnManager.setup完成（无play_button）")

		# 设置HandDock的TurnManager引用
		hand_dock.set_turn_manager(turn_manager)
		print("SimplePlayTest: HandDock已连接到TurnManager")

		# 🔧 关键：设置外部出牌验证回调（次数限制检查）
		turn_manager.external_play_validator = _validate_play_action
		print("SimplePlayTest: 外部出牌验证器已设置")
	else:
		turn_manager.setup(card_manager)
		print("SimplePlayTest: TurnManager使用简化模式")

# 🔧 新增：外部出牌验证函数（供TurnManager调用）
func _validate_play_action() -> bool:
	"""验证是否可以进行出牌操作（次数限制检查）"""
	if not turn_action_manager:
		return true  # 如果没有操作管理器，允许出牌

	if not turn_action_manager.can_perform_action("play"):
		print("SimplePlayTest: 出牌验证失败 - 本回合出牌次数已用完")
		return false

	print("SimplePlayTest: 出牌验证通过")
	return true

# 🔧 发放初始手牌并创建视图
func _deal_initial_hand_with_views():
	var initial_hand_size = session_config.initial_hand_size
	var drawn_cards = card_manager.draw(initial_hand_size)
	print("SimplePlayTest: 通过CardManager发放初始手牌: %d张" % drawn_cards.size())

	# 为初始手牌创建视图并添加到HandDock
	if turn_manager and turn_manager.has_method("_create_card_views_for_drawn_cards") and drawn_cards.size() > 0:
		turn_manager._create_card_views_for_drawn_cards(drawn_cards)
		print("SimplePlayTest: 通过TurnManager为初始手牌创建视图")

		# 让TurnManager进入出牌阶段，使卡牌可以被选择
		if turn_manager.has_method("_change_phase"):
			turn_manager._change_phase(1)  # 1 = PLAY_PHASE
			print("SimplePlayTest: TurnManager已进入出牌阶段")

# 🔧 连接所有必要的信号
func _connect_all_signals():
	print("SimplePlayTest: 连接所有系统信号")

	# 连接TurnManager的信号到TurnActionManager
	if turn_manager.has_signal("cards_played") and turn_action_manager.has_method("perform_action"):
		turn_manager.cards_played.connect(_on_cards_played_to_action_manager)
		print("SimplePlayTest: TurnManager.cards_played已连接到操作管理器")

	# 连接TurnManager的信号到ScoreManager
	if turn_manager.has_signal("cards_played") and score_manager.has_method("add_score"):
		turn_manager.cards_played.connect(_on_cards_played_to_score_manager)
		print("SimplePlayTest: TurnManager.cards_played已连接到得分管理器")

	# 连接HandDock的弃牌信号
	if hand_dock.has_signal("discard_button_pressed"):
		hand_dock.discard_button_pressed.connect(_on_discard_button_pressed)
		print("SimplePlayTest: HandDock.discard_button_pressed已连接")

	# 🔧 重要：连接卡牌选择变化信号以实时更新按钮状态
	if hand_dock.has_signal("card_selection_changed"):
		hand_dock.card_selection_changed.connect(_on_card_selection_changed)
		print("SimplePlayTest: HandDock.card_selection_changed已连接")

	# 连接操作管理器信号
	if turn_action_manager.has_signal("action_performed"):
		turn_action_manager.action_performed.connect(_on_action_performed_buttons)
		print("SimplePlayTest: TurnActionManager.action_performed已连接")

# 🔧 处理出牌到操作管理器
func _on_cards_played_to_action_manager(played_cards: Array, score: int):
	if turn_action_manager.can_perform_action("play"):
		turn_action_manager.perform_action("play")
		print("SimplePlayTest: 出牌操作已记录到TurnActionManager")
		_update_button_states()  # 立即更新按钮状态
	else:
		print("SimplePlayTest: 出牌次数已达上限")

# 🔧 处理出牌到得分管理器
func _on_cards_played_to_score_manager(played_cards: Array, score: int):
	score_manager.add_score(score)
	print("SimplePlayTest: 得分 %d 已添加到ScoreManager" % score)

# 🔧 处理卡牌选择变化（实时更新按钮状态）
func _on_card_selection_changed(selected_cards: Array):
	print("SimplePlayTest: 卡牌选择变化，当前选中: %d 张" % selected_cards.size())
	# 实时更新按钮状态以反映选择变化
	_update_button_states()

# 🔧 处理操作执行（更新按钮状态）
func _on_action_performed_buttons(action_type: String, remaining_count: int, total_limit: int):
	print("SimplePlayTest: 操作执行 - %s，剩余: %d/%d" % [action_type, remaining_count, total_limit])
	_update_button_states()

# 🔧 处理弃牌按钮
func _on_discard_button_pressed():
	if not hand_dock or not turn_action_manager:
		return

	# 检查弃牌次数限制
	if not turn_action_manager.can_perform_action("discard"):
		print("SimplePlayTest: 弃牌次数已达上限")
		return

	# 获取选中的卡牌
	var selected_cards = []
	if hand_dock.has_method("get_selected_cards"):
		selected_cards = hand_dock.get_selected_cards()

	if selected_cards.size() == 0:
		print("SimplePlayTest: 没有选中卡牌进行弃牌")
		return

	# 执行弃牌
	for card_view in selected_cards:
		if card_view.has_method("get_card_data"):
			var card_data = card_view.get_card_data()
			# 从手牌移除到弃牌堆
			var index = card_manager.hand.find(card_data)
			if index >= 0:
				card_manager.hand.remove_at(index)
				card_manager.discard_pile.append(card_data)
				print("SimplePlayTest: 弃牌 %s" % card_data.name)

	# 记录弃牌操作
	turn_action_manager.perform_action("discard")

	# 移除选中的卡牌视图
	if hand_dock.has_method("remove_selected_cards_and_refill"):
		hand_dock.remove_selected_cards_and_refill()

	print("SimplePlayTest: 弃牌操作完成")

# 🔧 新增：更新按钮状态（参考原始代码）
func _update_button_states():
	if not hand_dock:
		return

	var play_button = hand_dock.get_node_or_null("ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton")
	var discard_button = hand_dock.get_node_or_null("ButtonPanel/ButtonGrid/DiscardButtonContainer/DiscardButton")

	# 获取选中卡牌数量
	var selected_count = 0
	if hand_dock.has_method("get_selected_cards"):
		selected_count = hand_dock.get_selected_cards().size()

	# 获取操作次数信息
	var max_play = session_config.max_play_actions_per_turn if session_config else 3
	var max_discard = session_config.max_discard_actions_per_turn if session_config else 2
	var current_play = turn_action_manager.get_current_actions("play") if turn_action_manager else 0
	var current_discard = turn_action_manager.get_current_actions("discard") if turn_action_manager else 0

	# 更新出牌按钮状态
	if play_button:
		var remaining_plays = max_play - current_play
		var can_play = (remaining_plays > 0) and (selected_count > 0)

		# 设置按钮状态
		play_button.disabled = not can_play

		# 根据状态设置按钮文本和样式
		if remaining_plays <= 0:
			play_button.text = "✧ 出牌次数已用完 ✧"
			_apply_disabled_button_style(play_button)
		elif selected_count == 0:
			play_button.text = "✧ 吟唱咒语 (%d/%d) ✧" % [current_play, max_play]
			_apply_waiting_button_style(play_button)
		else:
			play_button.text = "✧ 吟唱咒语 (%d/%d) ✧" % [current_play, max_play]
			_apply_active_button_style(play_button)

	# 更新弃牌按钮状态
	if discard_button:
		var remaining_discards = max_discard - current_discard
		var can_discard = (remaining_discards > 0) and (selected_count > 0)

		# 设置按钮状态
		discard_button.disabled = not can_discard

		# 根据状态设置按钮文本和样式
		if remaining_discards <= 0:
			discard_button.text = "✧ 弃牌次数已用完 ✧"
			_apply_disabled_button_style(discard_button)
		elif selected_count == 0:
			discard_button.text = "✧ 使用精华 (%d/%d) ✧" % [current_discard, max_discard]
			_apply_waiting_button_style(discard_button)
		else:
			discard_button.text = "✧ 使用精华 (%d/%d) ✧" % [current_discard, max_discard]
			_apply_active_button_style(discard_button)

# 🔧 新增：按钮样式管理函数（参考原始代码）
func _apply_disabled_button_style(button: Button):
	"""应用禁用状态的按钮样式"""
	if not button:
		return
	# 设置禁用状态的颜色（灰化效果）
	button.modulate = Color(0.6, 0.6, 0.6, 0.8)  # 灰化并降低透明度
	button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN

func _apply_waiting_button_style(button: Button):
	"""应用等待选择卡牌状态的按钮样式"""
	if not button:
		return
	# 设置等待状态的颜色（稍微暗淡）
	button.modulate = Color(0.8, 0.8, 0.9, 1.0)  # 稍微暗淡的蓝色调
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _apply_active_button_style(button: Button):
	"""应用可点击状态的按钮样式"""
	if not button:
		return
	# 设置正常状态的颜色（明亮可点击）
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 正常颜色
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# 🔧 调试：检查TurnManager状态
func _debug_turn_manager_state():
	if not turn_manager:
		print("DEBUG: TurnManager为null")
		return

	print("DEBUG: TurnManager状态检查:")
	print("  - current_phase: %s" % turn_manager.current_phase)
	print("  - is_player_turn: %s" % turn_manager.is_player_turn)
	print("  - turn_number: %s" % turn_manager.turn_number)

	if turn_manager.has_method("get_turn_info"):
		var info = turn_manager.get_turn_info()
		print("  - 详细信息: %s" % info)

	# 检查阶段枚举值
	print("  - PLAY_PHASE枚举值: %s" % turn_manager.TurnPhase.PLAY_PHASE)
	print("  - 当前阶段是否等于PLAY_PHASE: %s" % (turn_manager.current_phase == turn_manager.TurnPhase.PLAY_PHASE))



# 🔧 步骤4：连接信号
func _connect_signals():
	print("SimplePlayTest: 连接信号")
	
	# 连接按钮信号
	start_turn_button.pressed.connect(_on_start_turn_pressed)
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	
	# 连接管理器信号
	turn_action_manager.action_performed.connect(_on_action_performed)
	turn_action_manager.action_limit_reached.connect(_on_action_limit_reached)
	score_manager.score_changed.connect(_on_score_changed)
	card_manager.hand_changed.connect(_on_hand_changed)
	
	# 连接HandDock信号（如果存在）
	if hand_dock and hand_dock.has_signal("cards_played"):
		hand_dock.cards_played.connect(_on_cards_played)

# 🔧 步骤5：设置UI
func _setup_ui():
	print("SimplePlayTest: 设置UI")
	
	# 显示快捷键说明
	_show_controls_info()
	
	# 更新显示
	_update_display()

# 🔧 显示控制说明
func _show_controls_info():
	var controls_text = """
简化出牌系统测试 - 快捷键说明:
  R - 开始回合
  N - 下回合（重置操作次数）
  1 - 出牌（最多%d次/回合）
  2 - 弃牌（最多%d次/回合）
  点击右下角牌库图标 - 查看完整牌库

🔧 重构特性:
  • 组件化架构，代码量减少80%
  • 配置驱动的游戏规则
  • 可复用的管理器组件
""" % [session_config.max_play_actions_per_turn, session_config.max_discard_actions_per_turn]
	
	print(controls_text)

# 🔧 按钮事件处理
func _on_start_turn_pressed():
	print("SimplePlayTest: 开始回合")
	turn_action_manager.reset_turn_actions()
	score_manager.reset_turn_score()
	_update_display()

func _on_next_turn_pressed():
	print("SimplePlayTest: 下回合")
	turn_action_manager.reset_turn_actions()
	if session_config.reset_turn_score_on_new_turn:
		score_manager.reset_turn_score()
	_update_display()

# 🔧 管理器信号处理
func _on_action_performed(action_type: String, remaining_count: int, total_limit: int):
	print("SimplePlayTest: 操作执行 - %s，剩余: %d/%d" % [action_type, remaining_count, total_limit])
	_update_display()

func _on_action_limit_reached(action_type: String, current_count: int):
	var action_name = "出牌" if action_type == TurnActionManager.ACTION_PLAY else "弃牌"
	_update_status("本回合%s次数已用完 (%d次)" % [action_name, current_count])

func _on_score_changed(turn_score: int, total_score: int, source: String):
	print("SimplePlayTest: 得分变化 - 回合: %d，总计: %d (来源: %s)" % [turn_score, total_score, source])
	_update_display()

func _on_hand_changed(hand_cards: Array):
	print("SimplePlayTest: 手牌变化，当前手牌数量: %d" % hand_cards.size())
	_update_display()

func _on_cards_played(played_cards: Array):
	print("SimplePlayTest: 卡牌已出牌，数量: %d" % played_cards.size())
	
	# 使用管理器记录操作和得分
	turn_action_manager.perform_action(TurnActionManager.ACTION_PLAY)
	
	# 计算得分
	var score = 0
	for card_data in played_cards:
		score += card_data.base_value
	
	score_manager.add_score(score, "play_cards")

# 🔧 更新显示
func _update_display():
	# 更新回合信息
	if turn_info_label:
		var play_status = "%d/%d" % [
			turn_action_manager.get_current_actions(TurnActionManager.ACTION_PLAY),
			turn_action_manager.get_action_limit(TurnActionManager.ACTION_PLAY)
		]
		var discard_status = "%d/%d" % [
			turn_action_manager.get_current_actions(TurnActionManager.ACTION_DISCARD),
			turn_action_manager.get_action_limit(TurnActionManager.ACTION_DISCARD)
		]
		turn_info_label.text = "出牌: %s | 弃牌: %s" % [play_status, discard_status]
	
	# 更新得分信息
	if score_label:
		score_label.text = "回合得分: %d | 总得分: %d" % [
			score_manager.get_current_turn_score(),
			score_manager.get_total_score()
		]
	
	# 更新操作信息
	if actions_label:
		actions_label.text = turn_action_manager.get_status_summary()

# 🔧 更新状态文本
func _update_status(message: String):
	if status_text:
		status_text.text = message
	print("SimplePlayTest: %s" % message)

# 🔧 快捷键处理
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_on_start_turn_pressed()
			KEY_N:
				_on_next_turn_pressed()
			KEY_1:
				_try_play_cards()
			KEY_2:
				_try_discard_cards()

# 🔧 简化的出牌逻辑
func _try_play_cards():
	if not turn_action_manager.can_perform_action(TurnActionManager.ACTION_PLAY):
		_update_status("本回合出牌次数已用完")
		return
	
	if not hand_dock or not hand_dock.has_method("get_selected_cards"):
		_update_status("HandDock不可用")
		return
	
	var selected_cards = hand_dock.get_selected_cards()
	if selected_cards.is_empty():
		_update_status("请先选择要出的卡牌")
		return
	
	# 触发出牌（通过HandDock的现有机制）
	if hand_dock.has_method("play_selected_cards"):
		hand_dock.play_selected_cards()
	else:
		_update_status("出牌功能不可用")

# 🔧 简化的弃牌逻辑
func _try_discard_cards():
	if not turn_action_manager.can_perform_action(TurnActionManager.ACTION_DISCARD):
		_update_status("本回合弃牌次数已用完")
		return
	
	if not hand_dock or not hand_dock.has_method("get_selected_cards"):
		_update_status("HandDock不可用")
		return
	
	var selected_cards = hand_dock.get_selected_cards()
	if selected_cards.is_empty():
		_update_status("请先选择要弃的卡牌")
		return
	
	# 执行弃牌
	turn_action_manager.perform_action(TurnActionManager.ACTION_DISCARD)
	
	# 弃牌逻辑
	for card_view in selected_cards:
		var card_data = card_view.get_card_data()
		if card_data:
			card_manager.discard_card_by_data(card_data)
	
	# 清空选择
	if hand_dock.has_method("clear_selection"):
		hand_dock.clear_selection()
	
	_update_status("弃牌成功！弃了 %d 张卡牌" % selected_cards.size())
