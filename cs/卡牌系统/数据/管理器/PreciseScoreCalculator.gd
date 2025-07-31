class_name PreciseScoreCalculator
extends RefCounted

## 🎯 精确化得分计算器 (V2.1)
##
## 核心功能：
## - 原子化的得分公式：最终得分 = ROUND((基础牌型分 + 牌面价值分 + 附加分) × 动态倍率)
## - 踢脚牌识别但不计分，为未来扩展预留接口
## - 返回详细的计算过程用于验证

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const HandResultClass = preload("res://cs/卡牌系统/数据/HandResult.gd")
const ScoreResultClass = preload("res://cs/卡牌系统/数据/ScoreResult.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")

## 🎯 计算得分（主要接口 - V2.3核心模型）
static func calculate_score(hand_result: HandResultClass, ranking_manager: HandTypeRankingManagerClass, bonus_score: int = 0, final_multiplier: float = 1.0) -> ScoreResultClass:
	var start_time = Time.get_ticks_msec()

	if not hand_result or not hand_result.is_valid():
		return ScoreResultClass.create_empty()

	# 1. 获取基础牌型分
	var base_score = hand_result.get_base_score()

	# 2. 计算牌面价值分（核心变化点）
	var value_score = _calculate_value_score(hand_result)

	# 3. 获取牌型倍率
	var level = ranking_manager.get_hand_type_level(hand_result.hand_type)
	var hand_type_multiplier = ranking_manager.get_multiplier(hand_result.hand_type)
	var level_info = {"level": level, "multiplier": hand_type_multiplier}

	# 4. 应用V2.3得分公式
	# 核心分数 = (基础分 + 牌面分) * 牌型倍率
	var core_score = float(base_score + value_score) * hand_type_multiplier
	# 最终得分 = ROUND((核心分数 + 附加分) * 最终倍率)
	var raw_score = (core_score + bonus_score) * final_multiplier
	var final_score = roundi(raw_score)

	# 5. 生成计算公式
	var simple_formula = "ROUND(((%d + %d) × %.2f + %d) × %.2f)" % [base_score, value_score, hand_type_multiplier, bonus_score, final_multiplier]
	var detailed_formula = "ROUND(((基础分%d + 牌面分%d) × 牌型倍率%.2f + 附加分%d) × 最终倍率%.2f)" % [base_score, value_score, hand_type_multiplier, bonus_score, final_multiplier]
	
	# 6. 生成分步计算过程 (V2.3版本)
	var steps = [
		"基础牌型分: %d (%s)" % [base_score, hand_result.hand_type_name],
		"牌面价值分: %.1f (%s)" % [value_score, _get_value_calculation_explanation(hand_result)],
		"牌型倍率: %.2fx (LV%d)" % [hand_type_multiplier, level],
		"核心分数: (%d + %.1f) × %.2f = %.2f" % [base_score, value_score, hand_type_multiplier, core_score],
		"附加分: %d (外部效果)" % bonus_score,
		"最终倍率: %.2fx (全局效果)" % final_multiplier,
		"最终得分: ROUND((%.2f + %d) × %.2f) = %d" % [core_score, bonus_score, final_multiplier, final_score]
	]

	# 7. 构建结果对象
	var result = ScoreResultClass.new()
	result.set_final_score(raw_score, final_score)
	result.set_score_components(base_score, value_score, bonus_score)
	result.set_multiplier_info(hand_type_multiplier, level, level_info, final_multiplier, core_score)
	result.set_calculation_formulas(simple_formula, detailed_formula, steps)
	
	var end_time = Time.get_ticks_msec()
	result.set_performance_metrics(end_time - start_time)
	
	return result

## 🎯 计算牌面价值分（V2.3核心逻辑）
static func _calculate_value_score(hand_result: HandResultClass) -> int:
	var hand_type = hand_result.hand_type
	var primary = hand_result.primary_value
	var secondary = hand_result.secondary_value

	match hand_type:
		HandTypeEnumsClass.HandType.HIGH_CARD:
			# 最高牌价值 × 1
			return primary

		HandTypeEnumsClass.HandType.PAIR:
			# 对子价值 × 2
			return primary * 2

		HandTypeEnumsClass.HandType.TWO_PAIR:
			# 大对子 × 2.5 + 小对子 × 1.5 (保留小数，在最终计算时舍入)
			return primary * 2.5 + secondary * 1.5

		HandTypeEnumsClass.HandType.THREE_KIND:
			# 三条价值 × 4
			return primary * 4

		HandTypeEnumsClass.HandType.STRAIGHT:
			# 所有5张牌价值总和
			return _calculate_all_cards_sum(hand_result)

		HandTypeEnumsClass.HandType.FLUSH:
			# 所有5张牌价值总和
			return _calculate_all_cards_sum(hand_result)

		HandTypeEnumsClass.HandType.FULL_HOUSE:
			# 三条 × 5 + 对子 × 2
			return primary * 5 + secondary * 2

		HandTypeEnumsClass.HandType.FOUR_KIND:
			# 四条价值 × 10
			return primary * 10

		HandTypeEnumsClass.HandType.STRAIGHT_FLUSH:
			# 最高牌价值 × 5
			return primary * 5

		HandTypeEnumsClass.HandType.ROYAL_FLUSH:
			# 固定高额牌面分
			return 100

		HandTypeEnumsClass.HandType.FIVE_KIND:
			# 五条价值 × 20
			return primary * 20

		_:
			return 0

## 🔧 计算所有卡牌价值总和（用于顺子、同花、同花顺）
static func _calculate_all_cards_sum(hand_result: HandResultClass) -> int:
	var total_sum = 0

	# 使用contributing_cards计算总和
	for card in hand_result.contributing_cards:
		if card and card.has_method("get") and card.get("base_value"):
			var card_value = card.base_value
			# 特殊处理A-2-3-4-5顺子中的A值
			if _is_wheel_straight(hand_result) and card_value == 1:
				total_sum += 1  # A在轮子顺子中计为1
			elif card_value == 1:
				total_sum += 14  # 其他情况A计为14
			else:
				total_sum += card_value
		elif card and typeof(card) == TYPE_INT:
			# 如果直接存储的是数值
			total_sum += card

	# 如果contributing_cards为空或无效，使用primary_value作为备用
	if total_sum == 0:
		total_sum = hand_result.primary_value * 5  # 假设5张牌的平均值

	return total_sum

## 🔧 检查是否为A-2-3-4-5顺子（轮子）
static func _is_wheel_straight(hand_result: HandResultClass) -> bool:
	# 检查是否为顺子且最高牌值为5
	if hand_result.hand_type == HandTypeEnumsClass.HandType.STRAIGHT or hand_result.hand_type == HandTypeEnumsClass.HandType.STRAIGHT_FLUSH:
		return hand_result.primary_value == 5
	return false

## 🎯 获取牌面价值计算说明（符合12345.md文档）
static func _get_value_calculation_explanation(hand_result: HandResultClass) -> String:
	var hand_type = hand_result.hand_type
	var primary = hand_result.primary_value
	var secondary = hand_result.secondary_value

	match hand_type:
		HandTypeEnumsClass.HandType.HIGH_CARD:
			return "%s×2" % _value_to_string(primary)

		HandTypeEnumsClass.HandType.PAIR:
			return "%s×4" % _value_to_string(primary)

		HandTypeEnumsClass.HandType.TWO_PAIR:
			return "%s×6 + %s×4" % [_value_to_string(primary), _value_to_string(secondary)]

		HandTypeEnumsClass.HandType.THREE_KIND:
			return "%s×8" % _value_to_string(primary)

		HandTypeEnumsClass.HandType.STRAIGHT:
			var cards_sum = _calculate_all_cards_sum(hand_result)
			return "所有5张牌总和=%d" % cards_sum

		HandTypeEnumsClass.HandType.FLUSH:
			var cards_sum = _calculate_all_cards_sum(hand_result)
			return "(所有5张牌总和=%d)×1.2" % cards_sum

		HandTypeEnumsClass.HandType.FULL_HOUSE:
			return "%s×10 + %s×6" % [_value_to_string(primary), _value_to_string(secondary)]

		HandTypeEnumsClass.HandType.FOUR_KIND:
			return "%s×15" % _value_to_string(primary)

		HandTypeEnumsClass.HandType.STRAIGHT_FLUSH:
			var cards_sum = _calculate_all_cards_sum(hand_result)
			return "(所有5张牌总和=%d)×2" % cards_sum

		HandTypeEnumsClass.HandType.ROYAL_FLUSH:
			return "固定200分"

		HandTypeEnumsClass.HandType.FIVE_KIND:
			return "%s×20" % _value_to_string(primary)

		_:
			return "未知计算"

## 🎯 数值转字符串
static func _value_to_string(value: int) -> String:
	match value:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(value)

## 🎯 快速计算接口（V2.3简化版本）
static func quick_calculate(hand_result: HandResultClass, level: int = 1, bonus_score: int = 0, final_multiplier: float = 1.0) -> int:
	if not hand_result or not hand_result.is_valid():
		return 0

	var base_score = hand_result.get_base_score()
	var value_score = _calculate_value_score(hand_result)

	# 使用V2.3倍率计算
	var hand_type_multiplier = HandTypeEnumsClass.calculate_dynamic_multiplier(hand_result.hand_type, level)

	# 应用V2.3公式
	var core_score = float(base_score + value_score) * hand_type_multiplier
	var raw_score = (core_score + bonus_score) * final_multiplier
	return roundi(raw_score)
