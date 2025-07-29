extends Control

## 🎯 牌型识别系统 V2.1 专用测试脚本
##
## 功能：
## - 验证重构后的牌型识别系统
## - 测试真实卡牌数据集成
## - 性能基准测试

# 导入新的V2.1系统
const HandTypeSystemV2Class = preload("res://cs/卡牌系统/数据/管理器/HandTypeSystemV2.gd")
const CardDataLoaderClass = preload("res://cs/卡牌系统/数据/管理器/CardDataLoader.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")

# UI组件
@onready var output_label: RichTextLabel = $VBoxContainer/ScrollContainer/OutputLabel
@onready var test_button: Button = $VBoxContainer/HBoxContainer/TestButton
@onready var benchmark_button: Button = $VBoxContainer/HBoxContainer/BenchmarkButton
@onready var validate_button: Button = $VBoxContainer/HBoxContainer/ValidateButton

# 测试数据
var ranking_manager: HandTypeRankingManagerClass
var test_results: Array = []

## 🎯 初始化
func _ready():
	print("🎯 牌型识别系统 V2.1 测试启动")
	
	# 连接按钮信号
	test_button.pressed.connect(_on_test_button_pressed)
	benchmark_button.pressed.connect(_on_benchmark_button_pressed)
	validate_button.pressed.connect(_on_validate_button_pressed)
	
	# 初始化系统
	_initialize_system()
	
	# 显示欢迎信息
	_display_welcome_message()

## 🔧 初始化系统
func _initialize_system():
	# 初始化卡牌数据加载器
	CardDataLoaderClass.initialize()
	
	# 创建等级管理器
	ranking_manager = HandTypeRankingManagerClass.new()
	
	# 验证系统完整性
	var validation = HandTypeSystemV2Class.validate_system()
	if not validation.overall_status:
		_append_output("❌ 系统验证失败: %s" % str(validation.errors))
	else:
		_append_output("✅ 系统验证通过")

## 🔧 显示欢迎信息
func _display_welcome_message():
	var welcome = """
🎯 牌型识别系统 V2.1 测试界面

📋 功能说明:
• 测试基础功能 - 验证牌型识别和得分计算
• 性能基准测试 - 测试系统性能和稳定性
• 系统验证 - 检查数据完整性和组件状态

🎮 操作说明:
• 点击对应按钮执行测试
• 结果将显示在下方输出区域
• 支持滚动查看详细信息

🔧 V2.1 新特性:
• 可插拔的牌型评估器架构
• 原子化的得分公式
• 标准化的数据结构
• 真实卡牌数据集成
"""
	_append_output(welcome)

## 🎯 测试基础功能
func _on_test_button_pressed():
	_append_output("\n🧪 开始基础功能测试...")
	
	# 1. 测试卡牌数据加载
	_test_card_data_loading()
	
	# 2. 测试牌型识别
	_test_hand_type_recognition()
	
	# 3. 测试得分计算
	_test_score_calculation()
	
	# 4. 测试完整流程
	_test_complete_workflow()
	
	_append_output("✅ 基础功能测试完成")

## 🔧 测试卡牌数据加载
func _test_card_data_loading():
	_append_output("\n📂 测试卡牌数据加载...")
	
	# 验证数据完整性
	var validation = CardDataLoaderClass.validate_card_data()
	_append_output("  总卡牌数: %d" % validation.total_cards)
	_append_output("  可用花色: %s" % str(validation.suits))
	_append_output("  数值范围: %s" % str(validation.values))
	
	if not validation.is_valid:
		_append_output("  ❌ 数据验证失败:")
		if not validation.duplicate_cards.is_empty():
			_append_output("    重复卡牌: %s" % str(validation.duplicate_cards))
		if not validation.invalid_cards.is_empty():
			_append_output("    无效卡牌: %s" % str(validation.invalid_cards))
	else:
		_append_output("  ✅ 数据验证通过")

## 🔧 测试牌型识别
func _test_hand_type_recognition():
	_append_output("\n🎯 测试牌型识别...")
	
	# 获取测试手牌
	var test_hands = CardDataLoaderClass.create_test_hands()
	
	for hand_type in test_hands:
		var cards = test_hands[hand_type]
		var result = HandTypeSystemV2Class.analyze_hand_type(cards)
		
		_append_output("  %s: %s (%s)" % [hand_type, result.hand_type_name, result.description])
		_append_output("    核心牌值: %d/%d, 踢脚牌: %s" % [result.primary_value, result.secondary_value, str(result.kickers)])

## 🔧 测试得分计算
func _test_score_calculation():
	_append_output("\n💰 测试得分计算...")
	
	# 获取一些测试手牌
	var random_cards = CardDataLoaderClass.get_random_cards(5)
	if random_cards.size() == 5:
		var result = HandTypeSystemV2Class.analyze_and_score(random_cards, ranking_manager)
		
		if result.is_valid:
			_append_output("  测试手牌: %s" % _format_cards(random_cards))
			_append_output("  牌型: %s" % result.hand_result.hand_type_name)
			_append_output("  得分: %d" % result.score_result.final_score)
			_append_output("  公式: %s" % result.score_result.calculation_formula)
		else:
			_append_output("  ❌ 得分计算失败")

## 🔧 测试完整流程
func _test_complete_workflow():
	_append_output("\n🔄 测试完整工作流程...")
	
	# 创建多个测试用例
	var test_cases = []
	
	for i in range(5):
		var cards = CardDataLoaderClass.get_random_cards(5)
		if cards.size() == 5:
			var test_case = HandTypeSystemV2Class.create_test_case(cards)
			test_cases.append(test_case)
	
	# 运行测试套件
	var suite_result = HandTypeSystemV2Class.run_test_suite(test_cases)
	_append_output("  测试用例: %d" % suite_result.total)
	_append_output("  通过率: %.1f%%" % suite_result.success_rate)
	_append_output("  平均耗时: %.1fms" % suite_result.average_time)

## 🎯 性能基准测试
func _on_benchmark_button_pressed():
	_append_output("\n⚡ 开始性能基准测试...")
	
	var benchmark_sizes = [100, 500, 1000]
	
	for size in benchmark_sizes:
		_append_output("\n📊 测试规模: %d次分析" % size)
		
		var start_time = Time.get_ticks_msec()
		var successful_analyses = 0
		
		for i in range(size):
			var cards = CardDataLoaderClass.get_random_cards(5)
			if cards.size() == 5:
				var result = HandTypeSystemV2Class.analyze_and_score(cards, ranking_manager)
				if result.is_valid:
					successful_analyses += 1
		
		var end_time = Time.get_ticks_msec()
		var total_time = end_time - start_time
		var avg_time = float(total_time) / size
		var success_rate = float(successful_analyses) / size * 100.0
		
		_append_output("  总耗时: %dms" % total_time)
		_append_output("  平均耗时: %.2fms" % avg_time)
		_append_output("  成功率: %.1f%%" % success_rate)
		_append_output("  吞吐量: %.1f次/秒" % (1000.0 / avg_time))

## 🎯 系统验证
func _on_validate_button_pressed():
	_append_output("\n🔍 开始系统验证...")
	
	# 1. 验证系统组件
	var system_validation = HandTypeSystemV2Class.validate_system()
	_append_output("  组件加载: %s" % ("✅" if system_validation.components_loaded else "❌"))
	_append_output("  基础功能: %s" % ("✅" if system_validation.basic_functions else "❌"))
	_append_output("  错误处理: %s" % ("✅" if system_validation.error_handling else "❌"))
	_append_output("  性能表现: %s" % ("✅" if system_validation.performance else "❌"))
	
	# 2. 验证卡牌数据
	var data_validation = CardDataLoaderClass.validate_card_data()
	_append_output("  数据完整性: %s" % ("✅" if data_validation.is_valid else "❌"))
	
	# 3. 验证等级系统
	_append_output("  等级系统: %s" % ("✅" if ranking_manager != null else "❌"))
	
	# 4. 综合评估
	var overall_valid = system_validation.overall_status and data_validation.is_valid and ranking_manager != null
	_append_output("\n🎯 系统状态: %s" % ("✅ 正常" if overall_valid else "❌ 异常"))
	
	if not overall_valid:
		_append_output("❌ 发现问题:")
		if not system_validation.overall_status:
			_append_output("  - 系统组件异常: %s" % str(system_validation.errors))
		if not data_validation.is_valid:
			_append_output("  - 数据完整性问题")

## 🔧 格式化卡牌显示
func _format_cards(cards: Array) -> String:
	var card_names = []
	for card in cards:
		if card:
			card_names.append(card.name)
	return str(card_names)

## 🔧 添加输出文本
func _append_output(text: String):
	if output_label:
		output_label.append_text(text + "\n")
		# 自动滚动到底部
		await get_tree().process_frame
		var scroll_container = output_label.get_parent()
		if scroll_container is ScrollContainer:
			scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
	
	# 同时输出到控制台
	print(text)
