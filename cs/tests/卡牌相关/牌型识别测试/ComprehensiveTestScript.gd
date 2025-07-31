extends Node

## 🧪 V2.3系统完整测试脚本
## 基于修正后的测试文档，验证所有牌型和计算逻辑

# 导入必要的类
const HandTypeSystemV2Class = preload("res://cs/卡牌系统/数据/管理器/HandTypeSystemV2.gd")
const CardDataLoaderClass = preload("res://cs/卡牌系统/数据/管理器/CardDataLoader.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")

## 测试用例数据结构
class TestCase:
	var id: String
	var description: String
	var card_ids: Array  # 卡牌ID数组
	var level: int
	var bonus_score: int
	var expected_score: int
	var expected_hand_type: HandTypeEnumsClass.HandType
	var expected_multiplier: float
	
	func _init(p_id: String, p_desc: String, p_cards: Array, p_level: int, p_bonus: int, p_expected: int, p_hand_type: HandTypeEnumsClass.HandType, p_multiplier: float):
		id = p_id
		description = p_desc
		card_ids = p_cards
		level = p_level
		bonus_score = p_bonus
		expected_score = p_expected
		expected_hand_type = p_hand_type
		expected_multiplier = p_multiplier

func _ready():
	print("🧪 开始V2.3系统完整测试")
	await get_tree().process_frame
	
	# 初始化系统
	CardDataLoaderClass.initialize()

	# 运行所有测试
	run_comprehensive_tests()

## 🎯 运行完整测试
func run_comprehensive_tests():
	var test_cases = create_test_cases()
	var ranking_manager = HandTypeRankingManagerClass.new()
	
	var passed = 0
	var failed = 0
	
	print("\n📊 开始执行 %d 个测试用例..." % test_cases.size())
	
	for test_case in test_cases:
		var result = run_single_test(test_case, ranking_manager)
		if result:
			passed += 1
			print("✅ %s: 通过" % test_case.id)
		else:
			failed += 1
			print("❌ %s: 失败" % test_case.id)
	
	print("\n🎯 测试结果总结:")
	print("  通过: %d" % passed)
	print("  失败: %d" % failed)
	print("  总计: %d" % (passed + failed))
	print("  成功率: %.1f%%" % (float(passed) / (passed + failed) * 100))

## 🔧 运行单个测试用例
func run_single_test(test_case: TestCase, ranking_manager: HandTypeRankingManagerClass) -> bool:
	# 设置牌型等级
	ranking_manager.set_hand_type_level(test_case.expected_hand_type, test_case.level)
	
	# 获取卡牌
	var cards = []
	for card_id in test_case.card_ids:
		var card = CardDataLoaderClass.get_card(card_id)
		if card:
			cards.append(card)
			print("🔍 获取卡牌: %s, base_value=%d, face_value=%d" % [card_id, card.base_value, card.get_face_value()])
		else:
			print("❌ 无法找到卡牌: %s" % card_id)
			return false

	if cards.size() != 5:
		print("❌ 卡牌数量不正确: %d" % cards.size())
		return false

	# 分析手牌
	var result = HandTypeSystemV2Class.analyze_and_score(cards, ranking_manager, test_case.bonus_score, 1.0)
	
	if not result.is_valid:
		print("❌ 手牌分析失败")
		return false
	
	var score_result = result.score_result
	var hand_result = result.hand_result
	
	# 验证结果
	var success = true
	
	# 检查牌型
	if hand_result.hand_type != test_case.expected_hand_type:
		print("❌ 牌型不匹配: 期望 %s, 实际 %s" % [
			HandTypeEnumsClass.get_hand_type_chinese_name(test_case.expected_hand_type),
			HandTypeEnumsClass.get_hand_type_chinese_name(hand_result.hand_type)
		])
		success = false
	
	# 检查倍率
	if abs(score_result.hand_type_multiplier - test_case.expected_multiplier) > 0.01:
		print("❌ 倍率不匹配: 期望 %.2fx, 实际 %.2fx" % [test_case.expected_multiplier, score_result.hand_type_multiplier])
		success = false
	
	# 检查最终得分
	if score_result.final_score != test_case.expected_score:
		print("❌ 得分不匹配: 期望 %d, 实际 %d" % [test_case.expected_score, score_result.final_score])
		print("   详细信息: 基础分=%d, 牌面分=%.1f, 核心分=%.1f, 附加分=%d" % [
			score_result.base_score,
			score_result.value_score,
			score_result.core_score,
			score_result.bonus_score
		])
		success = false
	
	if success:
		print("✅ %s: %s - %d分 (%.2fx)" % [
			test_case.id,
			test_case.description,
			score_result.final_score,
			score_result.hand_type_multiplier
		])
	
	return success

## 🎯 创建测试用例
func create_test_cases() -> Array:
	var cases = []
	
	# 1. 高牌测试
	cases.append(TestCase.new("1.1", "高牌K", ["S13", "D12", "H8", "C5", "D2"], 1, 0, 23, HandTypeEnumsClass.HandType.HIGH_CARD, 1.0))
	cases.append(TestCase.new("1.2", "高牌A", ["S1", "D12", "H8", "C5", "D2"], 1, 0, 24, HandTypeEnumsClass.HandType.HIGH_CARD, 1.0))
	cases.append(TestCase.new("1.3", "高牌A LV5", ["S1", "D12", "H8", "C5", "D2"], 5, 50, 88, HandTypeEnumsClass.HandType.HIGH_CARD, 1.6))

	# 2. 一对测试
	cases.append(TestCase.new("2.1", "一对3", ["D3", "S3", "H13", "C11", "D8"], 1, 0, 37, HandTypeEnumsClass.HandType.PAIR, 1.2))
	cases.append(TestCase.new("2.2", "一对A", ["D1", "S1", "H13", "C11", "D8"], 1, 0, 64, HandTypeEnumsClass.HandType.PAIR, 1.2))
	cases.append(TestCase.new("2.3", "一对A LV5", ["D1", "S1", "H13", "C11", "D8"], 5, 0, 106, HandTypeEnumsClass.HandType.PAIR, 2.0))

	# 3. 两对测试
	cases.append(TestCase.new("3.1", "两对8和5", ["D8", "S8", "H5", "C5", "D13"], 1, 0, 108, HandTypeEnumsClass.HandType.TWO_PAIR, 1.4))
	cases.append(TestCase.new("3.2", "两对A和K LV3", ["D1", "S1", "H13", "C13", "D12"], 3, 0, 198, HandTypeEnumsClass.HandType.TWO_PAIR, 1.9))

	# 4. 三条测试
	cases.append(TestCase.new("4.1", "三条7", ["D7", "S7", "H7", "C1", "D5"], 1, 0, 173, HandTypeEnumsClass.HandType.THREE_KIND, 1.6))
	cases.append(TestCase.new("4.2", "三条Q LV5", ["D12", "S12", "H12", "C1", "D5"], 5, 100, 484, HandTypeEnumsClass.HandType.THREE_KIND, 3.0))
	
	# 5. 顺子测试
	cases.append(TestCase.new("5.1", "顺子A-5", ["D1", "S2", "H3", "C4", "D5"], 1, 0, 266, HandTypeEnumsClass.HandType.STRAIGHT, 1.8))
	cases.append(TestCase.new("5.2", "顺子10-A", ["D10", "S11", "H12", "C13", "D1"], 1, 0, 324, HandTypeEnumsClass.HandType.STRAIGHT, 1.8))
	cases.append(TestCase.new("5.3", "顺子10-A LV5", ["D10", "S11", "H12", "C13", "D1"], 5, 0, 612, HandTypeEnumsClass.HandType.STRAIGHT, 3.4))

	# 6. 同花测试
	cases.append(TestCase.new("6.1", "同花J高", ["D2", "D5", "D7", "D9", "D11"], 1, 0, 368, HandTypeEnumsClass.HandType.FLUSH, 2.0))
	cases.append(TestCase.new("6.2", "同花A高 LV4", ["S1", "S13", "S11", "S9", "S5"], 4, 0, 707, HandTypeEnumsClass.HandType.FLUSH, 3.5))

	# 7. 葫芦测试
	cases.append(TestCase.new("7.1", "葫芦3带2", ["H3", "S3", "D3", "C2", "D2"], 1, 0, 673, HandTypeEnumsClass.HandType.FULL_HOUSE, 2.5))
	cases.append(TestCase.new("7.2", "葫芦A带K LV5", ["H1", "S1", "D1", "C13", "D13"], 5, 200, 1895, HandTypeEnumsClass.HandType.FULL_HOUSE, 4.9))

	# 8. 四条测试
	cases.append(TestCase.new("8.1", "四条6", ["D6", "S6", "H6", "C6", "D1"], 1, 0, 1680, HandTypeEnumsClass.HandType.FOUR_KIND, 3.0))
	cases.append(TestCase.new("8.2", "四条A LV5", ["D1", "S1", "H1", "C1", "D13"], 5, 0, 3968, HandTypeEnumsClass.HandType.FOUR_KIND, 6.2))

	# 9. 同花顺测试
	cases.append(TestCase.new("9.1", "同花顺Q高", ["H8", "H9", "H10", "H11", "H12"], 1, 0, 4240, HandTypeEnumsClass.HandType.STRAIGHT_FLUSH, 4.0))
	cases.append(TestCase.new("9.2", "同花顺Q高 LV5", ["H8", "H9", "H10", "H11", "H12"], 5, 500, 8980, HandTypeEnumsClass.HandType.STRAIGHT_FLUSH, 8.0))

	# 10. 皇家同花顺测试
	cases.append(TestCase.new("10.1", "皇家同花顺", ["C10", "C11", "C12", "C13", "C1"], 1, 0, 10500, HandTypeEnumsClass.HandType.ROYAL_FLUSH, 5.0))
	cases.append(TestCase.new("10.2", "皇家同花顺 LV5", ["C10", "C11", "C12", "C13", "C1"], 5, 0, 23100, HandTypeEnumsClass.HandType.ROYAL_FLUSH, 11.0))

	return cases

## 🔧 获取卡牌的辅助函数
func get_card_by_id(card_id: String):
	return CardDataLoaderClass.get_card(card_id)
