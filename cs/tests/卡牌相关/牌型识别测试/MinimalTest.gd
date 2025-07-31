extends Control

## 🎯 牌型识别功能测试 - 逐步迁移版本
## 逐步从 HandTypeTest.gd 迁移代码，找出问题所在

# 第一步：添加所有 const 导入
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

# 第二步：添加变量声明
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

# 第三步：添加 UI 初始化函数
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

# 第四步：添加 V2.1 系统初始化
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

# 第五步：添加配置加载
# 🔧 步骤1：加载配置
func _load_config():
	var config_path = "res://assets/data/game_session_configs/default_session.tres"
	if ResourceLoader.exists(config_path):
		session_config = load(config_path)
	else:
		session_config = GameSessionConfig.create_default()

	print("SimplePlayTest: 配置加载完成 - %s" % session_config.get_config_summary())

# 第六步：添加管理器创建（关键步骤）
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
	if hand_dock and hand_dock.has_signal("discard_button_pressed"):
		hand_dock.discard_button_pressed.connect(_on_discard_button_pressed)
		print("SimplePlayTest: HandDock.discard_button_pressed已连接")

# 🔧 更新按钮状态
func _update_button_states():
	print("SimplePlayTest: 更新按钮状态")

# 🔧 调试：检查TurnManager状态
func _debug_turn_manager_state():
	if turn_manager:
		print("SimplePlayTest: TurnManager状态检查完成")

# 信号处理函数
func _on_cards_played_to_action_manager(played_cards, score):
	if turn_action_manager:
		turn_action_manager.perform_action("play")
		print("SimplePlayTest: 操作管理器已记录出牌动作")

func _on_cards_played_to_score_manager(played_cards, score):
	if score_manager:
		score_manager.add_score(score)
		print("SimplePlayTest: 得分管理器已添加得分: %d" % score)

func _on_discard_button_pressed():
	print("SimplePlayTest: 弃牌按钮被按下")

# 第七步：添加游戏初始化函数
# 🔧 步骤3：完整初始化游戏系统
func _initialize_game():
	print("SimplePlayTest: 开始完整游戏系统初始化")

	# 🔧 1. 初始化牌库
	card_manager.initialize_deck()
	card_manager.shuffle_deck()

	# 🔧 2. 设置TurnManager与所有组件的完整连接
	_setup_turn_manager_connections()

	# 🔧 3. 发放初始手牌并创建视图（在牌库UI设置之前）
	_deal_initial_hand_with_views()

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

func _ready():
	print("MinimalTest: 第七步测试 - 添加游戏初始化函数（先测试函数定义）")
	_initialize_ui_references()
	_initialize_v2_system()
	_load_config()
	_create_managers()
	await get_tree().process_frame  # 等待管理器创建完成
	print("MinimalTest: 准备调用 _initialize_game() - 分步测试")
	# 分步测试游戏初始化
	print("SimplePlayTest: 开始完整游戏系统初始化")

	# 🔧 1. 初始化牌库
	print("MinimalTest: 测试步骤1 - 初始化牌库")
	card_manager.initialize_deck()
	card_manager.shuffle_deck()
	print("MinimalTest: 步骤1完成")

	print("MinimalTest: 第七步测试完成，游戏初始化第一步成功")
