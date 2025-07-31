extends Control

## 🎯 牌型识别功能测试
##
## 基于出牌系统测试，专门用于测试牌型识别功能
## 包含完整的牌型分析、等级系统、结果显示等功能

# 导入组件类
const GameSessionConfig = preload("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd")
const TurnActionManager = preload("res://cs/卡牌系统/数据/管理器/TurnActionManager.gd")
const GameScoreManager = preload("res://cs/卡牌系统/数据/管理器/GameScoreManager.gd")
const DeckViewIntegrationManager = preload("res://cs/卡牌系统/数据/管理器/DeckViewIntegrationManager.gd")
const CardManager = preload("res://cs/卡牌系统/数据/管理器/CardManager.gd")

# 导入牌型识别组件（V2.1新架构）
const HandTypeEnums = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const HandTypeAnalyzer = preload("res://cs/卡牌系统/数据/管理器/HandTypeAnalyzer.gd")
const HandTypeRankingManager = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")
const SmartHandAnalyzer = preload("res://cs/卡牌系统/数据/管理器/SmartHandAnalyzer.gd")
const HandTypeScoreManager = preload("res://cs/卡牌系统/数据/管理器/HandTypeScoreManager.gd")
const HandTypeTestCore = preload("res://cs/tests/卡牌相关/牌型识别测试/HandTypeTestCore.gd")

# 导入V2.1新架构组件
const HandTypeSystemV2 = preload("res://cs/卡牌系统/数据/管理器/HandTypeSystemV2.gd")
const CardDataLoader = preload("res://cs/卡牌系统/数据/管理器/CardDataLoader.gd")
const PokerHandAnalyzer = preload("res://cs/卡牌系统/数据/管理器/PokerHandAnalyzer.gd")
const PreciseScoreCalculator = preload("res://cs/卡牌系统/数据/管理器/PreciseScoreCalculator.gd")

# UI组件引用 - 使用安全的get_node_or_null方式
var hand_dock = null
var deck_widget = null
var turn_info_label: Label = null
var score_label: Label = null
var start_turn_button: Button = null
var next_turn_button: Button = null
var replace_card_button: Button = null
var status_text: Label = null
var actions_label: Label = null

# 牌型识别专用UI组件（状态分离版）
var hand_type_result_panel: Panel = null
var hand_type_label: Label = null
var best_cards_label: Label = null

# 实时状态组件（显示详细计算过程）
var status_panel: Panel = null
var test_suite_button: Button = null

# 卡牌可视化显示容器（动态创建）
var cards_display_container: HBoxContainer = null

# 卡牌替换功能相关变量
var replacement_mode_active: bool = false
var selected_card_to_replace: CardData = null
var available_replacement_cards: Array = []

# 🔧 完整组件系统 - 确保功能完全
var session_config  # 避免与const GameSessionConfig冲突
var turn_action_manager  # 避免与const TurnActionManager冲突
var score_manager  # 避免与const GameScoreManager冲突
var deck_integration_manager  # 避免与const DeckViewIntegrationManager冲突
var card_manager  # 避免与const CardManager冲突
var card_effect_manager  # CardManager需要这个引用
var turn_manager  # TurnManager用于管理HandDock
var game_manager  # 模拟GameManager来提供资源管理

# 牌型识别专用变量
var current_test_results: Dictionary = {}
var test_history: Array = []
var hand_type_test_core  # 核心测试模块，避免与const HandTypeTestCore冲突
var hand_ranking_system  # 等级系统，避免与const HandTypeRankingManager冲突

# V2.1新架构组件
var v2_system_initialized: bool = false
var v2_ranking_manager  # 避免与const HandTypeRankingManager冲突
var v2_test_results: Array = []

# 卡牌替换功能状态
var is_replacing_card: bool = false
var replacement_target_card: CardData = null
var deck_view_dialog: Window = null

# CardManager需要的属性
var effect_orchestrator = null

# 牌型识别测试初始化
func _ready():
	print("HandTypeTest: 开始牌型识别测试初始化")

	# 0. 安全初始化UI组件引用
	_initialize_ui_references()

	# 1. 初始化V2.1系统
	print("HandTypeTest: 步骤1 - 初始化V2.1系统")
	_initialize_v2_system()

	# 2. 加载配置
	print("HandTypeTest: 步骤2 - 加载配置")
	_load_config()

	# 3. 创建管理器组件
	print("HandTypeTest: 步骤3 - 创建管理器组件")
	_create_managers()

	# 等待管理器创建完成
	await get_tree().process_frame

	# 4. 初始化游戏
	print("HandTypeTest: 步骤4 - 初始化游戏")
	_initialize_game()

	# 5. 连接信号
	print("HandTypeTest: 步骤5 - 连接信号")
	_connect_signals()

	# 6. 设置UI
	print("HandTypeTest: 步骤6 - 设置UI")
	_setup_ui()

	# 7. 初始化牌型识别组件
	print("HandTypeTest: 步骤7 - 初始化牌型识别组件")
	_setup_hand_type_analyzer()

	# 8. 初始化卡牌可视化显示容器
	print("HandTypeTest: 步骤8 - 初始化卡牌可视化显示容器")
	_setup_cards_display_container()

	print("HandTypeTest: 牌型识别测试初始化完成（V2.1增强版）")

## 🔧 安全初始化UI组件引用
func _initialize_ui_references():
	print("HandTypeTest: 初始化UI组件引用...")

	# 安全获取UI组件引用
	hand_dock = get_node_or_null("HandDock")
	deck_widget = get_node_or_null("DeckWidget")
	turn_info_label = get_node_or_null("TopInfoPanel/VBox/TurnInfoLabel")
	score_label = get_node_or_null("TopInfoPanel/VBox/ScoreLabel")
	start_turn_button = get_node_or_null("ControlPanel/VBox/StartTurnButton")
	next_turn_button = get_node_or_null("ControlPanel/VBox/NextTurnButton")
	replace_card_button = get_node_or_null("ControlPanel/VBox/ReplaceCardButton")
	status_text = get_node_or_null("StatusPanel/VBox/StatusText")
	actions_label = get_node_or_null("TopInfoPanel/VBox/ActionsLabel")
	hand_type_result_panel = get_node_or_null("HandTypeResultPanel")
	hand_type_label = get_node_or_null("HandTypeResultPanel/HandTypeLabel")
	best_cards_label = get_node_or_null("HandTypeResultPanel/BestCardsLabel")
	status_panel = get_node_or_null("StatusPanel")
	test_suite_button = get_node_or_null("ControlPanel/VBox/TestSuiteButton")

	# 报告UI组件状态
	print("HandTypeTest: UI组件状态 - HandDock: %s, DeckWidget: %s" % [hand_dock != null, deck_widget != null])
	print("HandTypeTest: UI组件状态 - StatusText: %s, TestButton: %s" % [status_text != null, test_suite_button != null])

## 🔧 更新状态文本
func _update_status_text(text: String):
	if status_text:
		status_text.text = text
	print("状态: %s" % text)

## 🎯 初始化V2.1系统
func _initialize_v2_system():
	print("🚀 初始化牌型识别系统 V2.1...")

	# 初始化卡牌数据加载器
	CardDataLoader.initialize()

	# 创建V2.1等级管理器
	v2_ranking_manager = HandTypeRankingManager.new()

	# 验证系统完整性
	var validation = HandTypeSystemV2.validate_system()
	if validation.overall_status:
		v2_system_initialized = true
		print("✅ V2.1系统初始化成功")
		_update_status_text("V2.1系统已就绪")
	else:
		print("❌ V2.1系统初始化失败: %s" % str(validation.errors))
		_update_status_text("V2.1系统初始化失败")

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
	add_child.call_deferred(card_effect_manager)

	# 🔧 3. 创建卡牌管理器
	card_manager = CardManager.new(self)
	add_child.call_deferred(card_manager)

	# 🔧 4. 创建TurnManager来管理HandDock
	const PlayTurnManagerClass = preload("res://cs/主场景/game/TurnManager.gd")
	turn_manager = PlayTurnManagerClass.new()
	add_child.call_deferred(turn_manager)

	# 🔧 5. 设置TurnManager的外部验证器（连接到TurnActionManager）
	if turn_manager.has_method("set_external_play_validator"):
		turn_manager.set_external_play_validator(Callable(turn_action_manager, "can_perform_action").bind("play"))
		print("SimplePlayTest: TurnManager外部验证器已设置")

	print("SimplePlayTest: 完整管理器组件系统创建完成")

# 🔧 创建简化的GameManager来提供完整功能
func _create_simple_game_manager():
	# 使用预定义的SimpleGameManager类
	const HandTypeTestGameManagerClass = preload("res://cs/tests/卡牌相关/牌型识别测试/SimpleGameManager.gd")
	game_manager = HandTypeTestGameManagerClass.new()
	game_manager.name = "GameManager"  # 重要：使用正确的名称

	# 🔧 关键：将GameManager添加到/root路径，这样HandDock才能找到它
	get_tree().root.add_child.call_deferred(game_manager)

	print("SimplePlayTest: 简化GameManager已创建并添加到/root/GameManager路径")
	
	# 创建回合操作管理器
	turn_action_manager = TurnActionManager.new()
	add_child.call_deferred(turn_action_manager)

	# 创建得分管理器
	score_manager = GameScoreManager.new()

	# 创建牌库集成管理器
	deck_integration_manager = DeckViewIntegrationManager.new()
	add_child.call_deferred(deck_integration_manager)
	
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

	# 🔧 3. 发放初始手牌并创建视图（在牌库UI设置之前）
	print("HandTypeTest: 准备调用 _deal_initial_hand_with_views()")
	_deal_initial_hand_with_views()
	print("HandTypeTest: 初始手牌发放完成")

	# 🔧 4. 设置牌库集成（在抽牌之后，确保显示正确的牌库数量）
	if deck_widget:
		deck_integration_manager.setup(deck_widget, card_manager)
		# 🔧 重要：强制立即更新牌库显示，确保显示正确的牌库数量
		deck_integration_manager.force_update()
	else:
		print("HandTypeTest: 跳过牌库集成设置 - DeckWidget不存在")

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

	# 手牌变化会自动触发HandDock的更新，不需要手动创建视图
	print("SimplePlayTest: 初始手牌发放完成，HandDock会自动更新视图")

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
	if hand_dock and hand_dock.has_signal("discard_button_pressed"):
		hand_dock.discard_button_pressed.connect(_on_discard_button_pressed)
		print("SimplePlayTest: HandDock.discard_button_pressed已连接")
	else:
		print("SimplePlayTest: 跳过HandDock信号连接 - HandDock不存在")

	# 🔧 重要：连接卡牌选择变化信号以实时更新按钮状态
	if hand_dock and hand_dock.has_signal("card_selection_changed"):
		hand_dock.card_selection_changed.connect(_on_card_selection_changed)
		print("SimplePlayTest: HandDock.card_selection_changed已连接")
	else:
		print("SimplePlayTest: 跳过卡牌选择信号连接 - HandDock不存在")

	# 连接操作管理器信号
	if turn_action_manager.has_signal("action_performed"):
		turn_action_manager.action_performed.connect(_on_action_performed_buttons)
		print("SimplePlayTest: TurnActionManager.action_performed已连接")

# 🔧 处理出牌到操作管理器
func _on_cards_played_to_action_manager(played_cards: Array, score: int):
	print("HandTypeTest: 🎯 开始牌型识别分析，出牌数量: %d" % played_cards.size())

	# 🎯 执行牌型识别分析
	var analysis_result = _analyze_hand_type(played_cards)

	# 🎯 更新牌型识别显示
	_update_hand_type_display(analysis_result)

	# 🎯 记录测试历史
	test_history.append(analysis_result)

	# 状态显示已由_update_hand_type_display()处理，无需重复更新

	print("HandTypeTest: 🎯 牌型识别完成 - %s，得分: %d分" % [analysis_result.hand_type_name, analysis_result.get("final_score", 0)])

	# 执行原有的操作管理器逻辑
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
	
	# 连接按钮信号（如果存在）
	if start_turn_button:
		start_turn_button.pressed.connect(_on_start_turn_pressed)
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
	if replace_card_button:
		replace_card_button.pressed.connect(_on_replace_card_pressed)
	if test_suite_button:
		test_suite_button.pressed.connect(_run_test_suite)
	
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
  • 组件化架构，代码量减少80%%
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

## 🔄 卡牌替换功能实现
func _on_replace_card_pressed():
	print("HandTypeTest: 🔄 开始卡牌替换模式")

	if is_replacing_card:
		# 取消替换模式
		_cancel_card_replacement()
		return

	# 进入替换模式
	is_replacing_card = true
	replace_card_button.text = "❌ 取消替换"
	_update_status("🔄 替换模式：请右键点击要替换的手牌")

	# 连接手牌的右键点击事件
	print("HandTypeTest: 🔧 准备设置右键监听器")
	_setup_card_replacement_listeners()
	print("HandTypeTest: 🔧 右键监听器设置完成")

func _cancel_card_replacement():
	print("HandTypeTest: ❌ 取消卡牌替换模式")

	is_replacing_card = false
	replacement_target_card = null
	replace_card_button.text = "🔄 替换卡牌 (T)"
	_update_status("替换模式已取消")

	# 断开手牌的右键点击事件
	_cleanup_card_replacement_listeners()

func _setup_card_replacement_listeners():
	# 为所有手牌添加右键点击监听
	print("HandTypeTest: 🔧 检查hand_dock引用，hand_dock存在: %s" % (hand_dock != null))
	if hand_dock:
		# 通过position_to_card获取所有卡牌视图
		if hand_dock.has_method("get") and "position_to_card" in hand_dock:
			var card_views = hand_dock.position_to_card.values()
			print("HandTypeTest: 🔧 设置右键监听，找到 %d 张卡牌" % card_views.size())
			for card_view in card_views:
				if card_view and card_view.has_signal("card_right_clicked"):
					if not card_view.card_right_clicked.is_connected(_on_card_right_clicked):
						card_view.card_right_clicked.connect(_on_card_right_clicked)
						print("HandTypeTest: ✅ 已连接卡牌右键信号: %s" % card_view.card_data.name)
					else:
						print("HandTypeTest: ⚠️ 卡牌右键信号已连接: %s" % card_view.card_data.name)
				else:
					print("HandTypeTest: ❌ 卡牌没有card_right_clicked信号")
		else:
			print("HandTypeTest: ❌ hand_dock没有position_to_card属性")
	else:
		print("HandTypeTest: ❌ hand_dock引用为null")

func _cleanup_card_replacement_listeners():
	# 移除所有手牌的右键点击监听
	if hand_dock and "position_to_card" in hand_dock:
		var card_views = hand_dock.position_to_card.values()
		for card_view in card_views:
			if card_view and card_view.has_signal("card_right_clicked"):
				if card_view.card_right_clicked.is_connected(_on_card_right_clicked):
					card_view.card_right_clicked.disconnect(_on_card_right_clicked)

func _on_card_right_clicked(card_view):
	print("HandTypeTest: 🔧 _on_card_right_clicked被调用，is_replacing_card: %s" % is_replacing_card)

	if not is_replacing_card:
		print("HandTypeTest: ⚠️ 不在替换模式，忽略右键点击")
		return

	print("HandTypeTest: 🎯 选择要替换的卡牌: %s" % card_view.card_data.name)

	replacement_target_card = card_view.card_data
	_update_status("已选择卡牌：%s，正在打开牌库选择器..." % replacement_target_card.name)

	# 打开牌库查看器进行卡牌选择
	_open_deck_viewer_for_replacement()

# 🔧 管理器信号处理
func _on_action_performed(action_type: String, remaining_count: int, total_limit: int):
	print("SimplePlayTest: 操作执行 - %s，剩余: %d/%d" % [action_type, remaining_count, total_limit])
	_update_display()

func _on_action_limit_reached(action_type: String, current_count: int):
	var action_name = "出牌" if action_type == "play" else "弃牌"
	_update_status("本回合%s次数已用完 (%d次)" % [action_name, current_count])

func _on_score_changed(turn_score: int, total_score: int, source: String):
	print("SimplePlayTest: 得分变化 - 回合: %d，总计: %d (来源: %s)" % [turn_score, total_score, source])
	_update_display()

func _on_hand_changed(hand_cards: Array):
	print("SimplePlayTest: 手牌变化，当前手牌数量: %d" % hand_cards.size())

	# 🔧 重要：检查是否是卡牌替换导致的手牌变化
	if is_replacing_card:
		print("SimplePlayTest: 🔄 检测到卡牌替换导致的手牌变化，跳过出牌逻辑")
		_update_display()
		return

	# 🔧 正常的手牌变化处理
	_update_display()

func _on_cards_played(played_cards: Array):
	print("HandTypeTest: 🎯 开始牌型识别分析，出牌数量: %d" % played_cards.size())

	# 🎯 执行牌型识别分析
	var analysis_result = _analyze_hand_type(played_cards)

	# 🎯 更新牌型识别显示
	_update_hand_type_display(analysis_result)

	# 🎯 记录测试历史
	test_history.append(analysis_result)

	# 使用管理器记录操作和得分
	turn_action_manager.perform_action(TurnActionManager.ACTION_PLAY)

	# 使用牌型识别的得分而不是简单相加
	var final_score = analysis_result.get("final_score", 0)
	score_manager.add_score(final_score, "hand_type_play")

	# 状态显示已由_update_hand_type_display()处理，无需重复更新

	print("HandTypeTest: 🎯 牌型识别完成 - %s，得分: %d分" % [analysis_result.hand_type_name, final_score])

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
			KEY_T:
				_on_replace_card_pressed()
			KEY_1:
				_try_play_cards()
			KEY_2:
				_try_discard_cards()

# 🎯 集成牌型识别的出牌逻辑
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

	print("HandTypeTest: 开始牌型识别分析，选中卡牌: %d张" % selected_cards.size())

	# 🎯 执行牌型识别分析
	var analysis_result = _analyze_hand_type(selected_cards)

	# 🎯 更新牌型识别显示
	_update_hand_type_display(analysis_result)

	# 🎯 记录测试历史
	test_history.append(analysis_result)

	# 🎯 执行原有的出牌逻辑
	if hand_dock.has_method("play_selected_cards"):
		hand_dock.play_selected_cards()
	else:
		_update_status("出牌功能不可用")

	# 状态显示已由_update_hand_type_display()处理，无需重复更新

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

## 🎯 牌型识别专用函数

# 初始化牌型识别组件
func _setup_hand_type_analyzer():
	print("HandTypeTest: 初始化牌型识别组件")

	# 创建核心组件
	hand_ranking_system = HandTypeRankingManager.new()
	hand_type_test_core = HandTypeTestCore.new()

	# 设置一些牌型为高等级进行测试
	hand_ranking_system.set_hand_type_level(HandTypeEnums.HandType.PAIR, 3)  # 一对LV3
	hand_ranking_system.set_hand_type_level(HandTypeEnums.HandType.THREE_KIND, 2)  # 三条LV2

	# 连接测试套件按钮
	if test_suite_button:
		test_suite_button.pressed.connect(_run_test_suite)
		test_suite_button.text = "运行测试套件 (T)"

	print("HandTypeTest: 牌型识别组件初始化完成")
	print(hand_ranking_system.get_level_summary())

# 分析手牌牌型（V2.1增强版）
func _analyze_hand_type(cards: Array) -> Dictionary:
	# 转换为CardData数组
	var card_data_array = []
	for card_view in cards:
		var card_data = null

		# 检查是否是Node对象（CardView）
		if card_view is Node:
			if card_view.has_method("get_card_data"):
				card_data = card_view.get_card_data()
			elif "card_data" in card_view:
				card_data = card_view.card_data
		else:
			# 假设已经是CardData对象
			card_data = card_view

		if card_data:
			card_data_array.append(card_data)

	# 使用V2.1系统进行分析（如果可用）
	var v2_result = null
	if v2_system_initialized and card_data_array.size() > 0:
		v2_result = HandTypeSystemV2.analyze_and_score(card_data_array, v2_ranking_manager)
		if v2_result.is_valid:
			print("🎯 V2.1分析完成: %s，得分: %d分，耗时: %dms" % [
				v2_result.hand_result.hand_type_name,
				v2_result.score_result.final_score,
				v2_result.total_analysis_time
			])

	# 使用V1系统作为备用（如果V2.1不可用）
	var v1_result = null
	if hand_type_test_core:
		v1_result = hand_type_test_core.analyze_hand_type(card_data_array)
		print("🔧 V1分析完成: %s，得分: %d分" % [
			v1_result.hand_description,
			v1_result.final_score
		])

	# 合并结果，优先使用V2.1
	var final_result = _merge_analysis_results(v2_result, v1_result, card_data_array)

	# 记录当前测试结果
	current_test_results = final_result

	return final_result

## 🔧 合并V1和V2.1分析结果
func _merge_analysis_results(v2_result, v1_result, card_data_array: Array) -> Dictionary:
	# 如果V2.1结果可用，优先使用
	if v2_result and v2_result.is_valid:
		var hand_result = v2_result.hand_result
		var score_result = v2_result.score_result

		return {
			"hand_type": hand_result.hand_type,
			"hand_type_name": hand_result.hand_type_name,
			"hand_description": hand_result.description,
			"primary_value": hand_result.primary_value,
			"secondary_value": hand_result.secondary_value,
			"kickers": hand_result.kickers,
			"final_score": score_result.final_score,
			"base_score": score_result.base_score,
			"value_score": score_result.value_score,
			"bonus_score": score_result.bonus_score,
			"multiplier": score_result.dynamic_multiplier,
			"level_info": "LV%d (%.2fx)" % [score_result.hand_type_level, score_result.dynamic_multiplier],
			"calculation_formula": score_result.calculation_formula,
			"detailed_formula": score_result.detailed_formula,
			"step_by_step": score_result.step_by_step,
			"analysis_time": v2_result.total_analysis_time,
			"combinations_tested": hand_result.combinations_tested,
			"analysis_method": hand_result.analysis_method,
			"cards": card_data_array,
			"version": "V2.1",
			"v2_available": true,
			"hand_result": hand_result,  # 添加原始HandResult对象
			"score_result": score_result  # 添加原始ScoreResult对象
		}

	# 使用V1结果作为备用
	elif v1_result:
		return v1_result.duplicate()

	# 创建空结果
	else:
		return _create_fallback_result(card_data_array)

## 🔄 卡牌替换功能 - 使用现有牌库显示器
func _open_deck_viewer_for_replacement():
	print("HandTypeTest: 📚 打开牌库选择界面")

	# 获取所有可用卡牌
	var all_cards = _get_all_available_cards()

	if all_cards.is_empty():
		_update_status("❌ 没有可用的替换卡牌")
		_cancel_card_replacement()
		return

	print("HandTypeTest: 📦 找到 %d 张可用卡牌，使用现有牌库显示器" % all_cards.size())
	_update_status("请在牌库中点击要替换成的卡牌...")

	# 使用现有的牌库显示器
	_open_existing_deck_viewer_for_selection(all_cards)

func _get_all_available_cards() -> Array:
	# 获取所有标准卡牌和变体卡牌
	var all_cards = []

	# 从CardDataLoader获取所有卡牌（使用静态方法）
	all_cards = CardDataLoader.get_all_cards_including_variants()

	print("HandTypeTest: 📦 获取到 %d 张可用卡牌" % all_cards.size())
	return all_cards

## 使用现有牌库显示器进行卡牌选择
func _open_existing_deck_viewer_for_selection(available_cards: Array):
	print("HandTypeTest: 使用现有牌库显示器")

	# 直接使用deck_widget引用
	if deck_widget and deck_widget.has_method("_on_deck_button_pressed"):
		print("HandTypeTest: 找到DeckWidget，准备打开牌库显示器")

		# 设置替换模式标志
		replacement_mode_active = true

		# 临时保存可用卡牌列表
		available_replacement_cards = available_cards

		# 触发DeckWidget的牌库显示
		deck_widget._on_deck_button_pressed()

		# 连接牌库对话框的卡牌点击事件
		_connect_deck_dialog_events()

		print("HandTypeTest: 牌库显示器已打开，等待用户选择")
	else:
		print("HandTypeTest: 未找到DeckWidget或方法，回退到简化选择")
		_fallback_card_selection(available_cards)

## 回退的卡牌选择方法
func _fallback_card_selection(available_cards: Array):
	print("HandTypeTest: 使用回退选择方法（等待用户手动选择）")

	if available_cards.is_empty():
		_cancel_card_replacement()
		return

	# 不自动选择，而是等待用户操作
	print("HandTypeTest: 等待用户手动选择替换卡牌")
	_update_status("请手动选择要替换成的卡牌（当前为回退模式）")

	# 保存可用卡牌列表，等待用户选择
	available_replacement_cards = available_cards

## 连接牌库对话框的卡牌点击事件
func _connect_deck_dialog_events():
	print("HandTypeTest: 尝试连接牌库对话框事件")

	# 等待一帧，确保对话框已创建
	await get_tree().process_frame

	# 查找当前打开的牌库对话框
	var deck_dialog = _find_deck_dialog()
	if deck_dialog:
		print("HandTypeTest: 找到牌库对话框，准备重写卡牌点击处理")
		_override_deck_dialog_card_clicks(deck_dialog)
	else:
		print("HandTypeTest: 未找到牌库对话框")

## 查找当前打开的牌库对话框
func _find_deck_dialog():
	# 在场景树中查找DeckViewDialog
	var root = get_tree().current_scene
	if not root:
		return null

	# 递归查找对话框
	return _find_dialog_recursive(root)

## 递归查找对话框
func _find_dialog_recursive(node):
	# 检查是否是牌库对话框
	if node.get_script() and (
		"DeckViewDialog" in str(node.get_script().get_global_name()) or
		"DeckViewDialog" in str(node.get_script().resource_path)
	):
		return node

	# 递归查找子节点
	for child in node.get_children():
		var result = _find_dialog_recursive(child)
		if result:
			return result

	return null

## 重写牌库对话框的卡牌点击处理
func _override_deck_dialog_card_clicks(dialog):
	print("HandTypeTest: 开始重写牌库对话框的卡牌点击处理")

	# 查找对话框中的所有CardView实例
	var card_views = _find_all_card_views(dialog)
	print("HandTypeTest: 找到 %d 个CardView实例" % card_views.size())

	# 为每个CardView连接自定义点击处理
	for card_view in card_views:
		if card_view.has_signal("card_clicked"):
			# 断开原有连接（如果有的话）
			if card_view.card_clicked.is_connected(_on_deck_card_clicked_for_replacement):
				card_view.card_clicked.disconnect(_on_deck_card_clicked_for_replacement)

			# 连接新的处理函数
			card_view.card_clicked.connect(_on_deck_card_clicked_for_replacement)
			print("HandTypeTest: 已连接CardView点击事件: %s" % card_view.get_card_data().name)

## 查找所有CardView实例
func _find_all_card_views(node):
	var card_views = []

	# 检查当前节点是否是CardView
	if node.get_script() and "CardView" in str(node.get_script().get_global_name()):
		card_views.append(node)

	# 递归查找子节点
	for child in node.get_children():
		card_views.append_array(_find_all_card_views(child))

	return card_views

## 处理牌库中卡牌的点击事件（用于替换）
func _on_deck_card_clicked_for_replacement(card_view):
	if not replacement_mode_active:
		return

	var selected_card = card_view.get_card_data()
	print("HandTypeTest: 用户在牌库中选择了卡牌: %s" % selected_card.name)

	# 关闭牌库对话框
	_close_deck_dialog()

	# 执行替换，
	_on_replacement_card_selected(selected_card)

## 关闭牌库对话框
func _close_deck_dialog():
	var deck_dialog = _find_deck_dialog()
	if deck_dialog:
		deck_dialog.queue_free()
		print("HandTypeTest: 牌库对话框已关闭")

func _on_replacement_card_selected(selected_card: CardData):
	print("HandTypeTest: ✅ 选择了替换卡牌: %s" % selected_card.name)

	if not replacement_target_card:
		_update_status("错误：未找到要替换的目标卡牌")
		return

	# 执行卡牌替换
	_perform_card_replacement(replacement_target_card, selected_card)

	# 退出替换模式
	_cancel_card_replacement()

func _perform_card_replacement(old_card: CardData, new_card: CardData):
	print("HandTypeTest: 🔄 执行卡牌替换: %s -> %s" % [old_card.name, new_card.name])

	# 🔧 设置替换标志，防止触发出牌逻辑
	is_replacing_card = true
	print("HandTypeTest: 🔧 设置is_replacing_card = true，防止触发出牌逻辑")

	# 在CardManager中替换卡牌
	if card_manager and card_manager.has_method("replace_card_in_hand"):
		print("HandTypeTest: 🔧 调用CardManager.replace_card_in_hand")
		var success = card_manager.replace_card_in_hand(old_card, new_card)
		if success:
			print("HandTypeTest: ✅ CardManager替换成功")
			_update_status("✅ 卡牌替换成功: %s -> %s" % [old_card.name, new_card.name])

			# 立即更新牌型识别结果
			call_deferred("_trigger_hand_analysis")
		else:
			print("HandTypeTest: ❌ CardManager替换失败")
			_update_status("❌ 卡牌替换失败")
	else:
		print("HandTypeTest: ⚠️ CardManager不支持替换，使用备用方案")
		# 备用方案：通过HandDock直接替换
		_replace_card_via_hand_dock(old_card, new_card)

	# 🔧 延迟重置替换标志
	call_deferred("_reset_replacement_flag")

func _replace_card_via_hand_dock(old_card: CardData, new_card: CardData):
	print("HandTypeTest: 🔄 通过HandDock替换卡牌")

	if not hand_dock:
		_update_status("❌ HandDock不可用")
		return

	# 找到旧卡牌的位置
	var card_views = hand_dock.get_card_views() if hand_dock.has_method("get_card_views") else []
	var target_index = -1

	for i in range(card_views.size()):
		var card_view = card_views[i]
		if card_view and card_view.card_data == old_card:
			target_index = i
			break

	if target_index == -1:
		_update_status("❌ 未找到要替换的卡牌")
		return

	# 替换卡牌数据
	if hand_dock.has_method("replace_card_at_index"):
		hand_dock.replace_card_at_index(target_index, new_card)
		_update_status("✅ 卡牌替换成功: %s -> %s" % [old_card.name, new_card.name])

		# 立即更新牌型识别结果
		call_deferred("_trigger_hand_analysis")
	else:
		_update_status("❌ HandDock不支持卡牌替换")

## 🔧 重置替换标志
func _reset_replacement_flag():
	is_replacing_card = false
	print("HandTypeTest: 🔧 重置is_replacing_card = false")

func _trigger_hand_analysis():
	# 触发牌型识别分析
	print("HandTypeTest: 🎯 触发牌型识别分析")

	# 获取当前手牌
	var current_hand = []
	if card_manager and card_manager.has_method("get_hand"):
		current_hand = card_manager.get_hand()
	elif hand_dock and hand_dock.has_method("get_card_data_array"):
		current_hand = hand_dock.get_card_data_array()

	if current_hand.size() > 0:
		# 执行牌型识别
		var result = _analyze_hand_type(current_hand)
		_update_hand_type_display(result)

# 简化版本不需要牌库查看器相关函数

# 🎯 初始化卡牌可视化显示容器（固定定位版）
func _setup_cards_display_container():
	if not hand_type_result_panel:
		print("HandTypeTest: 警告 - hand_type_result_panel未找到，无法创建卡牌显示容器")
		return

	# 获取专门的卡牌显示区域
	var cards_display_area = hand_type_result_panel.get_node("CardsDisplayArea")
	if not cards_display_area:
		print("HandTypeTest: 警告 - CardsDisplayArea未找到")
		return

	# 🎯 在固定区域内创建卡牌显示布局
	_create_fixed_cards_layout(cards_display_area)

	print("HandTypeTest: 固定定位卡牌显示容器创建成功")

# 🎨 创建优化的卡牌显示布局（扩展版）
func _create_fixed_cards_layout(display_area: Control):
	# 创建标题标签（固定在顶部）
	var cards_title_label = Label.new()
	cards_title_label.name = "CardsTitleLabel"
	cards_title_label.text = "构成卡牌:"
	cards_title_label.position = Vector2(10, 5)
	cards_title_label.size = Vector2(320, 20)
	cards_title_label.add_theme_font_size_override("font_size", 11)
	cards_title_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0))
	cards_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 创建卡牌显示容器（大幅扩展空间）
	cards_display_container = HBoxContainer.new()
	cards_display_container.name = "CardsDisplayContainer"
	cards_display_container.position = Vector2(10, 30)
	cards_display_container.size = Vector2(320, 55)  # 大幅增加高度到55px
	cards_display_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_display_container.add_theme_constant_override("separation", 8)  # 增加卡牌间距到8px

	# 添加到显示区域
	display_area.add_child(cards_title_label)
	display_area.add_child(cards_display_container)

# 🧹 清理卡牌显示容器
func _clear_cards_display():
	if cards_display_container:
		# 清理所有子节点
		for child in cards_display_container.get_children():
			child.queue_free()
		cards_display_container.get_children().clear()

# 更新牌型识别结果显示（V2.1增强版 - 显示具体卡牌）
func _update_hand_type_display(result: Dictionary):
	print("HandTypeTest: _update_hand_type_display被调用，结果版本: %s" % result.get("version", "未知"))
	# 首先清理之前的卡牌显示
	_clear_cards_display()
	if hand_type_label:
		var version_info = ""
		if result.get("version", "") == "V2.1":
			version_info = " [V2.1]"

		hand_type_label.text = "牌型: %s (%s)%s" % [
			result.get("hand_type_name", "未知"),
			result.get("level_info", "LV1"),
			version_info
		]

	if best_cards_label:
		# V2.1增强显示：使用HandResult的格式化方法
		if result.get("version", "") == "V2.1" and result.has("hand_result"):
			var hand_result = result.hand_result
			if hand_result and hand_result.has_method("format_display"):
				# 使用HandResult的增强格式化显示
				var formatted_display = hand_result.format_display()
				best_cards_label.text = formatted_display
			else:
				# 备用显示方式
				best_cards_label.text = "V2.1结果: %s" % result.get("hand_type_name", "未知")
		else:
			# V1兼容显示
			var cards_text = ""
			for card in result.get("best_hand_cards", []):
				# 使用CardData的基本属性来构建显示名称
				var suit_name = ""
				match card.suit:
					"hearts": suit_name = "红桃"
					"diamonds": suit_name = "方片"
					"clubs": suit_name = "梅花"
					"spades": suit_name = "黑桃"
					_: suit_name = card.suit

				var value_name = ""
				match card.base_value:
					1: value_name = "A"
					11: value_name = "J"
					12: value_name = "Q"
					13: value_name = "K"
					_: value_name = str(card.base_value)

				cards_text += "%s%s " % [suit_name, value_name]
			best_cards_label.text = "最佳组合: %s" % cards_text

			# 显示弃置卡牌
			if result.get("discarded_cards", []).size() > 0:
				var discarded_text = ""
				for card in result.discarded_cards:
					var suit_name = ""
					match card.suit:
						"hearts": suit_name = "红桃"
						"diamonds": suit_name = "方片"
						"clubs": suit_name = "梅花"
						"spades": suit_name = "黑桃"
						_: suit_name = card.suit

					var value_name = ""
					match card.base_value:
						1: value_name = "A"
						11: value_name = "J"
						12: value_name = "Q"
						13: value_name = "K"
						_: value_name = str(card.base_value)

					discarded_text += "%s%s " % [suit_name, value_name]
				best_cards_label.text += "\n弃置: %s" % discarded_text

	# 准备详细计算过程信息
	var calc_text = ""
	if result.get("version", "") == "V2.1":
		# V2.1显示详细的原子化公式
		calc_text = "V2.1: %s\n详细: %s" % [
			result.get("calculation_formula", "无"),
			result.get("detailed_formula", "无")
		]

		# 如果有分步计算，显示第一步
		var steps = result.get("step_by_step", [])
		if not steps.is_empty():
			calc_text += "\n步骤: %s..." % steps[0]
	else:
		# V1显示简化公式
		calc_text = "V1: %s" % result.get("detailed_formula", result.get("calculation_formula", "无"))

	print("HandTypeTest: 计算过程文本生成完成，长度: %d字符" % calc_text.length())
	print("HandTypeTest: 计算过程内容: %s" % calc_text)

	# 将详细计算过程显示在实时状态组件中
	print("HandTypeTest: 准备更新status_text，status_text存在: %s" % (status_text != null))
	if status_text:
		var status_info = "🎯 牌型识别结果\n"
		status_info += "牌型: %s\n" % result.get("hand_type_name", "未知")
		status_info += "得分: %s\n" % result.get("final_score", 0)
		status_info += "计算过程: %s" % calc_text

		status_text.text = status_info
		print("HandTypeTest: status_text已更新，内容长度: %d字符" % status_info.length())
	else:
		print("HandTypeTest: 错误 - status_text为null，无法更新状态信息")

	# 计算过程已移至实时状态组件

	# 🎯 显示构成牌型的卡牌（可视化增强）
	_display_contributing_cards(result)

# 🎯 显示构成牌型的卡牌
func _display_contributing_cards(result: Dictionary):
	if not cards_display_container:
		print("HandTypeTest: 警告 - 卡牌显示容器未初始化")
		return

	print("HandTypeTest: 开始显示构成牌型的卡牌，结果版本: %s" % result.get("version", "未知"))

	var contributing_cards = []

	# 从结果中提取构成牌型的卡牌
	if result.get("version", "") == "V2.1" and result.has("hand_result"):
		var hand_result = result.hand_result
		print("HandTypeTest: V2.1结果，hand_result存在: %s" % (hand_result != null))
		if hand_result and hand_result.contributing_cards:
			contributing_cards = hand_result.contributing_cards
			print("HandTypeTest: 找到V2.1 contributing_cards: %d张" % contributing_cards.size())
		else:
			print("HandTypeTest: V2.1 hand_result中没有contributing_cards或为空")
	else:
		# V1兼容：使用best_hand_cards
		contributing_cards = result.get("best_hand_cards", [])
		print("HandTypeTest: 使用V1兼容模式，best_hand_cards: %d张" % contributing_cards.size())

	if contributing_cards.is_empty():
		print("HandTypeTest: 没有找到构成牌型的卡牌")
		return

	print("HandTypeTest: 显示 %d 张构成牌型的卡牌" % contributing_cards.size())

	# 为每张卡牌创建真实的CardView
	var created_count = 0
	for card_data in contributing_cards:
		if card_data:
			var card_view = _create_mini_card_view(card_data)
			if card_view:
				cards_display_container.add_child(card_view)
				created_count += 1
			else:
				print("HandTypeTest: 警告 - 无法为卡牌 %s 创建视图" % card_data.name)

	print("HandTypeTest: 成功创建 %d/%d 张卡牌视图" % [created_count, contributing_cards.size()])

# 🎯 创建真实卡牌视图（使用HandDock的卡牌渲染系统）
func _create_mini_card_view(card_data: CardData) -> Control:
	if not card_data:
		print("HandTypeTest: 警告 - 卡牌数据为空")
		return null

	# 使用与HandDock相同的Card场景
	var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")
	if not card_scene:
		print("HandTypeTest: 错误 - 无法加载Card场景")
		return null

	# 创建卡牌实例
	var card_instance = card_scene.instantiate()
	if not card_instance:
		print("HandTypeTest: 错误 - 无法实例化Card场景")
		return null

	# 设置卡牌数据（使用与HandDock相同的方法）
	if card_instance.has_method("setup"):
		card_instance.setup(card_data)
	elif card_instance.has_method("set_card_data"):
		card_instance.set_card_data(card_data)
	else:
		print("HandTypeTest: 警告 - Card实例没有setup或set_card_data方法")
		card_instance.queue_free()
		return null

	# 🎨 设置扩展的卡牌显示效果（适配90px高度区域）
	card_instance.scale = Vector2(0.35, 0.35)  # 进一步增大到35%，充分利用空间
	card_instance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_instance.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# 添加清晰的视觉效果
	card_instance.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 完全不透明，确保最佳清晰度

	# 禁用交互功能（这些卡牌仅用于显示）
	if card_instance.has_method("set_draggable"):
		card_instance.set_draggable(false)
	if card_instance.has_method("set_selectable"):
		card_instance.set_selectable(false)

	# 设置鼠标过滤器为忽略，避免干扰
	card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

	print("HandTypeTest: 成功创建真实卡牌视图: %s" % card_data.name)
	return card_instance

# 🎯 获取花色符号
func _get_suit_symbol(suit: String) -> String:
	match suit.to_lower():
		"hearts": return "♥"
		"diamonds": return "♦"
		"clubs": return "♣"
		"spades": return "♠"
		_: return "?"

# 🎯 获取数值符号
func _get_value_symbol(value: int) -> String:
	match value:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"  # 高位A
		_: return str(value)

# 运行完整测试套件（V2.1增强版）
func _run_test_suite():
	print("HandTypeTest: 开始运行完整测试套件（V2.1增强版）")

	var test_results = []
	var total_start_time = Time.get_ticks_msec()

	# V2.1系统测试
	if v2_system_initialized:
		print("🚀 运行V2.1系统测试...")
		_run_v2_test_suite()

	# V1系统测试（备用）
	if hand_type_test_core:
		print("🔧 运行V1系统测试...")
		_run_v1_test_suite()

	var total_time = Time.get_ticks_msec() - total_start_time
	_update_status_text("测试套件完成，耗时: %dms" % total_time)

## 🎯 运行V2.1测试套件
func _run_v2_test_suite():
	# 测试1：基础功能测试
	print("🧪 V2.1测试1: 基础功能测试")
	_run_v2_basic_tests()

	# 测试2：性能基准测试
	print("🧪 V2.1测试2: 性能基准测试")
	_run_v2_performance_tests()

	# 测试3：当前手牌分析
	if hand_dock and hand_dock.has_method("get_all_cards"):
		var all_cards = hand_dock.get_all_cards()
		if not all_cards.is_empty():
			print("🧪 V2.1测试3: 当前手牌分析")
			var result = _analyze_hand_type(all_cards)
			_update_hand_type_display(result)

## 🔧 运行V2.1基础功能测试
func _run_v2_basic_tests():
	# 获取测试手牌
	var test_hands = CardDataLoader.create_test_hands()
	var test_count = 0
	var success_count = 0

	for hand_type in test_hands:
		var cards = test_hands[hand_type]
		if cards.size() >= 5:
			test_count += 1
			var result = HandTypeSystemV2.analyze_and_score(cards, v2_ranking_manager)

			if result.is_valid:
				success_count += 1
				print("  ✅ %s: %s, 得分: %d" % [
					hand_type,
					result.hand_result.hand_type_name,
					result.score_result.final_score
				])
			else:
				print("  ❌ %s: 分析失败" % hand_type)

	print("  📊 基础测试结果: %d/%d 通过" % [success_count, test_count])

## 🔧 运行V2.1性能测试
func _run_v2_performance_tests():
	var test_sizes = [10, 50, 100]

	for size in test_sizes:
		var start_time = Time.get_ticks_msec()
		var success_count = 0

		for i in range(size):
			var cards = CardDataLoader.get_random_cards(5)
			if cards.size() == 5:
				var result = HandTypeSystemV2.analyze_and_score(cards, v2_ranking_manager)
				if result.is_valid:
					success_count += 1

		var end_time = Time.get_ticks_msec()
		var total_time = end_time - start_time
		var avg_time = float(total_time) / size

		print("  📊 %d次测试: 总耗时%dms, 平均%.2fms, 成功率%.1f%%" % [
			size, total_time, avg_time, float(success_count) / size * 100.0
		])

## 🔧 运行V1测试套件
func _run_v1_test_suite():
	var test_results = []
	var total_start_time = Time.get_ticks_msec()

	# 测试1：当前手牌分析
	if hand_dock and hand_dock.has_method("get_all_cards"):
		var all_cards = hand_dock.get_all_cards()
		if not all_cards.is_empty():
			print("🧪 测试1: 当前手牌分析")
			var result = _analyze_hand_type(all_cards)
			_update_hand_type_display(result)
			test_results.append(result)
			test_history.append(result)

	# 测试2：性能测试
	if hand_dock and hand_dock.has_method("get_all_cards"):
		var cards = hand_dock.get_all_cards()
		if cards.size() >= 5:
			print("🧪 测试2: 性能测试")
			var card_data_array = []
			for card_view in cards:
				var card_data = card_view.get_card_data() if card_view.has_method("get_card_data") else card_view
				if card_data:
					card_data_array.append(card_data)

			var performance_result = hand_type_test_core.performance_test(card_data_array.slice(0, 5), "手牌性能测试")
			print("性能测试结果: %s，平均耗时: %.1fμs" % [performance_result.performance_rating, performance_result.average_time_us])

	# 测试3：等级系统测试
	print("🧪 测试3: 等级系统测试")
	var original_level = hand_ranking_system.get_hand_type_level(HandTypeEnums.HandType.PAIR)
	hand_ranking_system.set_hand_type_level(HandTypeEnums.HandType.PAIR, 5)  # 临时设为LV5

	if hand_dock and hand_dock.has_method("get_all_cards"):
		var cards = hand_dock.get_all_cards()
		if not cards.is_empty():
			var high_level_result = _analyze_hand_type(cards)
			print("LV5测试结果: %s，得分: %d" % [high_level_result.hand_type_name, high_level_result.final_score])

	# 恢复原等级
	hand_ranking_system.set_hand_type_level(HandTypeEnums.HandType.PAIR, original_level)

	var total_end_time = Time.get_ticks_msec()
	var total_time = total_end_time - total_start_time

	var status_message = "🎯 测试套件完成！\n"
	status_message += "总耗时: %dms\n" % total_time
	status_message += "测试数量: %d个\n" % test_results.size()
	status_message += "历史记录: %d条" % test_history.size()

	_update_status(status_message)
	print("HandTypeTest: 测试套件运行完成，总耗时: %dms" % total_time)

# 重写出牌函数，添加牌型识别
func _on_play_cards_with_analysis():
	if not hand_dock or not hand_dock.has_method("get_selected_cards"):
		_update_status("HandDock不可用")
		return

	var selected_cards = hand_dock.get_selected_cards()
	if selected_cards.is_empty():
		_update_status("请先选择要出的卡牌")
		return

	# 执行牌型识别
	var card_data_array = []
	for card_view in selected_cards:
		var card_data = card_view.get_card_data()
		if card_data:
			card_data_array.append(card_data)

	var analysis_result = _analyze_hand_type(card_data_array)

	# 更新牌型识别显示
	_update_hand_type_display(analysis_result)

	# 执行原有的出牌逻辑（通过TurnActionManager）
	turn_action_manager.perform_action(TurnActionManager.ACTION_PLAY)

	_update_status("出牌完成 - 识别牌型: %s，得分: %d" % [analysis_result.hand_type_name, analysis_result.final_score])

## 🔧 创建回退结果（当核心模块未初始化时）
func _create_fallback_result(cards: Array) -> Dictionary:
	return {
		"hand_type": HandTypeEnums.HandType.HIGH_CARD,
		"hand_type_name": "高牌",
		"hand_description": "简化分析: 高牌",
		"best_hand_cards": cards,
		"discarded_cards": [],
		"total_cards": cards.size(),
		"fixed_base_score": 1,
		"dynamic_rank_score": cards.size() * 2,
		"bonus_score": 0,
		"dynamic_multiplier": 1.0,
		"final_score": 1 + cards.size() * 2,
		"hand_type_level": 1,
		"level_info": "LV1 (1.0x)",
		"calculation_formula": "(1 + %d) × 1.0 = %d" % [cards.size() * 2, 1 + cards.size() * 2],
		"detailed_formula": "简化计算: 基础1分 + %d张卡牌×2 = %d分" % [cards.size(), 1 + cards.size() * 2],
		"analysis_time": 0,
		"combinations_tested": 1,
		"analysis_details": "使用简化分析（核心模块未初始化）",
		"debug_info": {"fallback": true}
	}
