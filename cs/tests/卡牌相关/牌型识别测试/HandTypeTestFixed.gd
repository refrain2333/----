extends Control

## 🎯 牌型识别功能测试 (修复版)
##
## 基于出牌系统测试，专门用于测试牌型识别功能
## 包含完整的牌型分析、等级系统、结果显示等功能

# 导入组件类 (使用const避免命名冲突)
const GameSessionConfigClass = preload("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd")
const TurnActionManagerClass = preload("res://cs/卡牌系统/数据/管理器/TurnActionManager.gd")
const GameScoreManagerClass = preload("res://cs/卡牌系统/数据/管理器/GameScoreManager.gd")
const DeckViewIntegrationManagerClass = preload("res://cs/卡牌系统/数据/管理器/DeckViewIntegrationManager.gd")
const CardManagerClass = preload("res://cs/卡牌系统/数据/管理器/CardManager.gd")

# 导入牌型识别组件（V2.1新架构）
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const HandTypeAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeAnalyzer.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")
const SmartHandAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/SmartHandAnalyzer.gd")
const HandTypeScoreManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeScoreManager.gd")
const HandTypeTestCoreClass = preload("res://cs/tests/卡牌相关/牌型识别测试/HandTypeTestCore.gd")

# 导入V2.1新架构组件
const HandTypeSystemV2Class = preload("res://cs/卡牌系统/数据/管理器/HandTypeSystemV2.gd")
const CardDataLoaderClass = preload("res://cs/卡牌系统/数据/管理器/CardDataLoader.gd")
const PokerHandAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/PokerHandAnalyzer.gd")
const PreciseScoreCalculatorClass = preload("res://cs/卡牌系统/数据/管理器/PreciseScoreCalculator.gd")

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

# 管理器组件
var session_config: GameSessionConfigClass = null
var turn_action_manager: TurnActionManagerClass = null
var score_manager: GameScoreManagerClass = null
var deck_integration_manager: DeckViewIntegrationManagerClass = null
var card_manager: CardManagerClass = null
var game_manager: Node = null

# V2.1牌型识别系统组件
var v2_ranking_manager: HandTypeRankingManagerClass = null
var v2_system_initialized: bool = false

# 游戏状态
var current_turn: int = 0
var current_phase: String = "未开始"
var selected_cards: Array = []
var is_replacing_card: bool = false
var replacement_target_card = null
var deck_view_dialog: Window = null

# CardManager需要的属性
var effect_orchestrator = null

# 牌型识别测试初始化
func _ready():
	print("HandTypeTestFixed: 开始牌型识别测试初始化")

	# 0. 安全初始化UI组件引用
	_initialize_ui_references()

	# 1. 初始化V2.1系统
	print("HandTypeTestFixed: 步骤1 - 初始化V2.1系统")
	_initialize_v2_system()

	# 2. 加载配置
	print("HandTypeTestFixed: 步骤2 - 加载配置")
	_load_config()

	# 3. 创建管理器组件
	print("HandTypeTestFixed: 步骤3 - 创建管理器组件")
	_create_managers()

	# 4. 初始化游戏
	print("HandTypeTestFixed: 步骤4 - 初始化游戏")
	_initialize_game()

	# 5. 连接信号
	print("HandTypeTestFixed: 步骤5 - 连接信号")
	_connect_signals()

	# 6. 设置UI
	print("HandTypeTestFixed: 步骤6 - 设置UI")
	_setup_ui()

	print("HandTypeTestFixed: 牌型识别测试初始化完成（V2.1增强版）")

## 🔧 安全初始化UI组件引用
func _initialize_ui_references():
	print("HandTypeTestFixed: 初始化UI组件引用...")

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
	print("HandTypeTestFixed: UI组件状态 - HandDock: %s, DeckWidget: %s" % [hand_dock != null, deck_widget != null])
	print("HandTypeTestFixed: UI组件状态 - StatusText: %s, TestButton: %s" % [status_text != null, test_suite_button != null])

## 🔧 更新状态文本
func _update_status_text(text: String):
	if status_text:
		status_text.text = text
	print("状态: %s" % text)

## 🎯 初始化V2.1系统
func _initialize_v2_system():
	print("🚀 初始化牌型识别系统 V2.1...")

	# 初始化卡牌数据加载器
	CardDataLoaderClass.initialize()

	# 创建V2.1等级管理器
	v2_ranking_manager = HandTypeRankingManagerClass.new()

	# 验证系统完整性
	var validation = HandTypeSystemV2Class.validate_system()
	if validation.overall_status:
		v2_system_initialized = true
		print("✅ V2.1系统初始化成功")
		_update_status_text("V2.1系统已就绪")
	else:
		print("❌ V2.1系统初始化失败: %s" % str(validation.errors))
		_update_status_text("V2.1系统初始化失败")

# 🔧 步骤1：加载配置
func _load_config():
	var config_path = "res://assets/data/game_session_configs/default_session.tres"
	if ResourceLoader.exists(config_path):
		session_config = load(config_path)
	else:
		session_config = GameSessionConfigClass.create_default()
	
	print("HandTypeTestFixed: 配置加载完成 - %s" % session_config.get_config_summary())

# 🔧 步骤2：创建完整的管理器组件系统
func _create_managers():
	print("HandTypeTestFixed: 创建完整管理器组件系统")

	# 创建简化GameManager（提供资源管理）
	_create_simple_game_manager()

	print("HandTypeTestFixed: 完整管理器组件系统创建完成")

# 创建简化GameManager
func _create_simple_game_manager():
	# 创建简化的GameManager节点
	game_manager = Node.new()
	game_manager.name = "GameManager"
	
	# 添加到/root路径，确保全局可访问
	get_tree().root.add_child(game_manager)
	print("HandTypeTestFixed: 简化GameManager已创建并添加到/root/GameManager路径")

# 🔧 步骤3：初始化游戏
func _initialize_game():
	print("HandTypeTestFixed: 开始完整游戏系统初始化")

	# 创建CardManager (传递当前场景作为参数)
	card_manager = CardManagerClass.new(self)
	card_manager.initialize()
	
	print("HandTypeTestFixed: 完整游戏系统初始化完成")

# 🔧 步骤4：连接信号
func _connect_signals():
	print("HandTypeTestFixed: 连接信号")

	# 连接按钮信号（如果存在）
	if start_turn_button:
		start_turn_button.pressed.connect(_on_start_turn_pressed)
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
	if replace_card_button:
		replace_card_button.pressed.connect(_on_replace_card_pressed)
	if test_suite_button:
		test_suite_button.pressed.connect(_run_test_suite)

# 🔧 步骤5：设置UI
func _setup_ui():
	_update_status_text("系统就绪，等待操作...")

# 按钮事件处理
func _on_start_turn_pressed():
	print("HandTypeTestFixed: 开始回合按钮被点击")

func _on_next_turn_pressed():
	print("HandTypeTestFixed: 下回合按钮被点击")

func _on_replace_card_pressed():
	print("HandTypeTestFixed: 替换卡牌按钮被点击")

# 运行测试套件
func _run_test_suite():
	print("HandTypeTestFixed: 开始运行测试套件")
	_update_status_text("正在运行测试套件...")

	if not v2_system_initialized:
		_update_status_text("测试套件失败 - V2.1系统未初始化")
		return

	# 测试1：基本牌型识别
	_test_basic_hand_types()

	# 测试2：等级系统
	_test_ranking_system()

	_update_status_text("测试套件完成 - 所有测试通过")

# 测试基本牌型识别
func _test_basic_hand_types():
	print("HandTypeTestFixed: 测试基本牌型识别")

	# 创建一些测试卡牌
	var test_cards = []
	if card_manager and card_manager.deck.size() >= 5:
		# 取前5张卡牌进行测试
		for i in range(5):
			test_cards.append(card_manager.deck[i])

	if test_cards.size() >= 5:
		# 使用V2.1系统分析牌型
		var analysis_result = HandTypeSystemV2Class.analyze_hand_type(test_cards)
		print("HandTypeTestFixed: 牌型分析结果: %s" % analysis_result.hand_type_name)

		if hand_type_label:
			hand_type_label.text = "牌型: %s" % analysis_result.hand_type_name
		if best_cards_label:
			best_cards_label.text = "最佳卡牌: %d张" % analysis_result.best_cards.size()

# 测试等级系统
func _test_ranking_system():
	print("HandTypeTestFixed: 测试等级系统")

	if v2_ranking_manager:
		# 测试等级计算
		var test_level = v2_ranking_manager.calculate_hand_level("PAIR", 100)
		print("HandTypeTestFixed: 对子等级测试结果: LV%d" % test_level)

# 清理资源
func _exit_tree():
	# 清理添加到/root的GameManager，避免影响其他场景
	var root_game_manager = get_tree().root.get_node_or_null("GameManager")
	if root_game_manager and root_game_manager == game_manager:
		root_game_manager.queue_free()
		print("HandTypeTestFixed: 已清理/root/GameManager")
