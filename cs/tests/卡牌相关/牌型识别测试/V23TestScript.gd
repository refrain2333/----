extends Node

## 🎯 V2.3牌型识别系统测试脚本
##
## 测试内容：
## - 新的基础分数配置
## - 增强的等级倍率系统
## - V2.3双阶段得分公式
## - 核心分数和最终倍率

# 导入V2.3系统组件
const HandTypeSystemV2 = preload("res://cs/卡牌系统/数据/管理器/HandTypeSystemV2.gd")
const CardDataLoader = preload("res://cs/卡牌系统/数据/管理器/CardDataLoader.gd")
const HandTypeRankingManager = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")
const HandTypeEnums = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")

func _ready():
	print("🚀 开始V2.3牌型识别系统测试")
	
	# 初始化系统
	CardDataLoader.initialize()
	var ranking_manager = HandTypeRankingManager.new()
	
	# 测试1：基础分数验证
	print("\n📊 测试1：V2.3基础分数验证")
	_test_base_scores()
	
	# 测试2：等级倍率验证
	print("\n📈 测试2：V2.3等级倍率验证")
	_test_level_multipliers(ranking_manager)
	
	# 测试3：双阶段得分公式验证
	print("\n🔢 测试3：V2.3双阶段得分公式验证")
	_test_scoring_formula(ranking_manager)
	
	# 测试4：完整流程测试
	print("\n🔄 测试4：V2.3完整流程测试")
	_test_complete_workflow(ranking_manager)
	
	print("\n✅ V2.3系统测试完成")

## 🔧 测试基础分数
func _test_base_scores():
	var base_scores = HandTypeEnums.BASE_SCORES
	
	print("  基础分数配置:")
	for hand_type in base_scores:
		var hand_type_name = HandTypeEnums.get_hand_type_chinese_name(hand_type)
		var score = base_scores[hand_type]
		print("    %s: %d分" % [hand_type_name, score])
	
	# 验证分数递增
	var expected_order = [
		HandTypeEnums.HandType.HIGH_CARD,
		HandTypeEnums.HandType.PAIR,
		HandTypeEnums.HandType.TWO_PAIR,
		HandTypeEnums.HandType.THREE_KIND,
		HandTypeEnums.HandType.STRAIGHT,
		HandTypeEnums.HandType.FLUSH,
		HandTypeEnums.HandType.FULL_HOUSE,
		HandTypeEnums.HandType.FOUR_KIND,
		HandTypeEnums.HandType.STRAIGHT_FLUSH,
		HandTypeEnums.HandType.ROYAL_FLUSH,
		HandTypeEnums.HandType.FIVE_KIND
	]
	
	var is_ascending = true
	for i in range(expected_order.size() - 1):
		var current_score = base_scores[expected_order[i]]
		var next_score = base_scores[expected_order[i + 1]]
		if current_score >= next_score:
			is_ascending = false
			break
	
	print("  ✅ 基础分数递增验证: %s" % ("通过" if is_ascending else "失败"))

## 🔧 测试等级倍率
func _test_level_multipliers(ranking_manager: HandTypeRankingManager):
	print("  等级倍率测试:")
	
	# 测试不同牌型的等级倍率
	var test_hand_types = [
		HandTypeEnums.HandType.PAIR,
		HandTypeEnums.HandType.THREE_KIND,
		HandTypeEnums.HandType.FULL_HOUSE,
		HandTypeEnums.HandType.ROYAL_FLUSH
	]
	
	for hand_type in test_hand_types:
		var hand_type_name = HandTypeEnums.get_hand_type_chinese_name(hand_type)
		print("    %s:" % hand_type_name)
		
		for level in range(1, 6):  # LV1-LV5
			var multiplier = HandTypeEnums.calculate_dynamic_multiplier(hand_type, level)
			print("      LV%d: %.2fx" % [level, multiplier])

## 🔧 测试得分公式
func _test_scoring_formula(ranking_manager: HandTypeRankingManager):
	# 创建测试手牌
	var test_cards = CardDataLoader.get_random_cards(5)
	if test_cards.size() != 5:
		print("  ❌ 无法获取测试卡牌")
		return
	
	print("  测试卡牌: %s" % _format_cards(test_cards))
	
	# 测试不同参数组合
	var test_cases = [
		{"bonus": 0, "final_mult": 1.0, "desc": "基础计算"},
		{"bonus": 50, "final_mult": 1.0, "desc": "附加分数"},
		{"bonus": 0, "final_mult": 1.5, "desc": "最终倍率"},
		{"bonus": 30, "final_mult": 1.2, "desc": "完整参数"}
	]
	
	for test_case in test_cases:
		var result = HandTypeSystemV2.analyze_and_score(
			test_cards, 
			ranking_manager, 
			test_case.bonus, 
			test_case.final_mult
		)
		
		if result.is_valid:
			var score_result = result.score_result
			print("  %s:" % test_case.desc)
			print("    牌型: %s" % result.hand_result.hand_type_name)
			print("    基础分: %d, 牌面分: %d" % [score_result.base_score, score_result.value_score])
			print("    牌型倍率: %.2fx, 核心分数: %.2f" % [score_result.hand_type_multiplier, score_result.core_score])
			print("    附加分: %d, 最终倍率: %.2fx" % [score_result.bonus_score, score_result.final_multiplier])
			print("    最终得分: %d" % score_result.final_score)
			print("    公式: %s" % score_result.calculation_formula)

## 🔧 测试完整流程
func _test_complete_workflow(ranking_manager: HandTypeRankingManager):
	# 设置一些牌型等级
	ranking_manager.set_hand_type_level(HandTypeEnums.HandType.PAIR, 3)
	ranking_manager.set_hand_type_level(HandTypeEnums.HandType.THREE_KIND, 2)
	ranking_manager.set_hand_type_level(HandTypeEnums.HandType.FULL_HOUSE, 4)
	
	print("  等级设置:")
	print("    一对: LV3, 三条: LV2, 葫芦: LV4")
	
	# 创建测试手牌集合
	var test_hands = CardDataLoader.create_test_hands()
	
	print("  完整流程测试结果:")
	for hand_type_name in test_hands:
		var cards = test_hands[hand_type_name]
		if cards.size() >= 5:
			var result = HandTypeSystemV2.analyze_and_score(cards.slice(0, 5), ranking_manager, 25, 1.1)
			
			if result.is_valid:
				var score_result = result.score_result
				print("    %s: %d分 (LV%d, %.2fx核心倍率, %.2f核心分)" % [
					hand_type_name,
					score_result.final_score,
					score_result.hand_type_level,
					score_result.hand_type_multiplier,
					score_result.core_score
				])

## 🔧 格式化卡牌显示
func _format_cards(cards: Array) -> String:
	var card_strings = []
	for card in cards:
		if card.has_method("get_display_name"):
			card_strings.append(card.get_display_name())
		else:
			card_strings.append(str(card))
	return "[" + ", ".join(card_strings) + "]"
