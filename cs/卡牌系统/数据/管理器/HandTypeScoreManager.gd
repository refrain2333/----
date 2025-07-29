class_name HandTypeScoreManager
extends RefCounted

## 💰 牌型得分计算管理器
## 
## 核心功能：
## - 动态等级分计算
## - 附加分协同效应
## - 完整的得分公式实现
## - 遵循项目架构规范，放置在管理器目录

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const SmartHandAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/SmartHandAnalyzer.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")

# 信号
signal score_calculated(result: Dictionary)
signal batch_calculation_completed(results: Array)

## 🎯 计算扑克牌型得分
static func calculate_poker_hand_score(cards: Array, ranking_manager: HandTypeRankingManagerClass = null) -> Dictionary:
	if cards.is_empty():
		return _create_empty_score_result()

	# 使用智能分析器获取最佳牌型
	var hand_analysis = SmartHandAnalyzerClass.find_best_hand(cards)

	# 创建默认等级系统（如果未提供）
	if not ranking_manager:
		ranking_manager = HandTypeRankingManagerClass.new()
	
	# 计算各部分得分
	var fixed_base_score = hand_analysis.base_score
	var dynamic_rank_score = _calculate_dynamic_rank_score(hand_analysis)
	var bonus_score = _calculate_bonus_from_cards(hand_analysis.best_hand_cards)
	var dynamic_multiplier = ranking_manager.get_multiplier(hand_analysis.hand_type)
	
	# 应用得分公式：最终得分 = ((固定基础分 + 动态等级分) + 附加分) × 动态倍率
	var final_score = roundi(((fixed_base_score + dynamic_rank_score) + bonus_score) * dynamic_multiplier)
	
	# 构建详细的计算公式字符串
	var calculation_formula = "((%d + %d) + %d) × %.1f = %d" % [
		fixed_base_score,
		dynamic_rank_score,
		bonus_score,
		dynamic_multiplier,
		final_score
	]
	
	var detailed_formula = "固定基础分(%d) + 动态等级分(%d) + 附加分(%d) × 倍率(%.1fx) = %d分" % [
		fixed_base_score,
		dynamic_rank_score,
		bonus_score,
		dynamic_multiplier,
		final_score
	]
	
	return {
		"hand_analysis": hand_analysis,
		"fixed_base_score": fixed_base_score,
		"dynamic_rank_score": dynamic_rank_score,
		"bonus_score": bonus_score,
		"dynamic_multiplier": dynamic_multiplier,
		"final_score": final_score,
		"calculation_formula": calculation_formula,
		"detailed_formula": detailed_formula,
		"hand_type_level": ranking_manager.get_hand_type_level(hand_analysis.hand_type),
		"level_info": "LV%d (%.1fx)" % [
			ranking_manager.get_hand_type_level(hand_analysis.hand_type),
			dynamic_multiplier
		]
	}

## 🧮 计算动态等级分
static func _calculate_dynamic_rank_score(hand_analysis: Dictionary) -> int:
	var hand_type = hand_analysis.hand_type
	var primary_value = hand_analysis.primary_value
	var secondary_value = hand_analysis.secondary_value
	var kickers = hand_analysis.get("kickers", [])
	
	match hand_type:
		HandTypeEnumsClass.HandType.HIGH_CARD:
			# 最高牌价值 × 2
			return primary_value * 2

		HandTypeEnumsClass.HandType.PAIR:
			# 对子价值 × 4 + 踢脚牌总和
			var kicker_sum = 0
			for kicker in kickers:
				kicker_sum += kicker
			return primary_value * 4 + kicker_sum

		HandTypeEnumsClass.HandType.TWO_PAIR:
			# 大对子 × 6 + 小对子 × 4 + 踢脚牌
			var kicker_sum = 0
			for kicker in kickers:
				kicker_sum += kicker
			return primary_value * 6 + secondary_value * 4 + kicker_sum
		
		HandTypeEnumsClass.HandType.THREE_KIND:
			# 三条价值 × 8 + 踢脚牌总和
			var kicker_sum = 0
			for kicker in kickers:
				kicker_sum += kicker
			return primary_value * 8 + kicker_sum

		HandTypeEnumsClass.HandType.STRAIGHT:
			# 所有卡牌价值总和（A特殊处理）
			return _calculate_straight_score(hand_analysis.cards)

		HandTypeEnumsClass.HandType.FLUSH:
			# 所有卡牌价值总和 × 1.2
			var total_value = 0
			for card in hand_analysis.cards:
				total_value += card.base_value
			return roundi(total_value * 1.2)

		HandTypeEnumsClass.HandType.FULL_HOUSE:
			# 三条 × 10 + 对子 × 6
			return primary_value * 10 + secondary_value * 6
		
		HandTypeEnumsClass.HandType.FOUR_KIND:
			# 四条价值 × 15 + 踢脚牌
			var kicker_sum = 0
			for kicker in kickers:
				kicker_sum += kicker
			return primary_value * 15 + kicker_sum

		HandTypeEnumsClass.HandType.STRAIGHT_FLUSH:
			# 顺子分数 × 2
			return _calculate_straight_score(hand_analysis.cards) * 2

		HandTypeEnumsClass.HandType.ROYAL_FLUSH:
			# 固定200分（传奇牌型特殊处理）
			return 200

		HandTypeEnumsClass.HandType.FIVE_KIND:
			# 五条价值 × 20
			return primary_value * 20
		
		_:
			return 0

## 🔧 计算顺子得分（处理A的特殊情况）
static func _calculate_straight_score(cards: Array) -> int:
	var values = []
	for card in cards:
		values.append(card.base_value)
	
	values.sort()
	
	# 检测A-2-3-4-5（轮子顺）
	if values == [1, 2, 3, 4, 5]:
		return 1 + 2 + 3 + 4 + 5  # A=1
	
	# 检测10-J-Q-K-A（皇家顺）
	if values == [1, 10, 11, 12, 13]:
		return 14 + 10 + 11 + 12 + 13  # A=14
	
	# 普通顺子
	var total = 0
	for value in values:
		total += value
	return total

## 🎁 计算附加分（蜡封、牌框等特殊效果）
static func _calculate_bonus_from_cards(cards: Array) -> int:
	var bonus = 0
	
	for card in cards:
		# 检查卡牌的特殊属性
		if card.has_method("get_bonus_score"):
			bonus += card.get_bonus_score()
		elif "bonus_score" in card:
			bonus += card.bonus_score

		# 检查蜡封效果
		if "foil_type" in card:
			match card.foil_type:
				"normal": bonus += 0
				"common": bonus += 5
				"rare": bonus += 15
				"legendary": bonus += 30

		# 检查牌框效果
		if "frame_type" in card:
			match card.frame_type:
				"basic": bonus += 0
				"enhanced": bonus += 10
				"premium": bonus += 20

		# 检查其他特殊效果
		if "special_effects" in card and card.special_effects is Array:
			for effect in card.special_effects:
				if "bonus_score" in effect:
					bonus += effect.bonus_score
	
	return bonus

## 🎯 快速计算得分（简化版本）
static func calculate_quick_score(cards: Array) -> int:
	if cards.is_empty():
		return 0

	var hand_analysis = SmartHandAnalyzerClass.find_best_hand(cards)
	var ranking_manager = HandTypeRankingManagerClass.new()
	
	var fixed_base_score = hand_analysis.base_score
	var dynamic_rank_score = _calculate_dynamic_rank_score(hand_analysis)
	var bonus_score = _calculate_bonus_from_cards(hand_analysis.best_hand_cards)
	var dynamic_multiplier = ranking_manager.get_multiplier(hand_analysis.hand_type)
	
	return roundi(((fixed_base_score + dynamic_rank_score) + bonus_score) * dynamic_multiplier)

## 🎯 批量计算得分
static func calculate_batch_scores(card_combinations: Array, ranking_manager: HandTypeRankingManager = null) -> Array:
	var results = []
	
	for cards in card_combinations:
		var score_result = calculate_poker_hand_score(cards, ranking_manager)
		results.append(score_result)
	
	return results

## 🎯 比较两组卡牌的得分
static func compare_card_scores(cards1: Array, cards2: Array, ranking_manager: HandTypeRankingManager = null) -> Dictionary:
	var score1 = calculate_poker_hand_score(cards1, ranking_manager)
	var score2 = calculate_poker_hand_score(cards2, ranking_manager)
	
	var winner = ""
	var score_difference = score1.final_score - score2.final_score
	
	if score_difference > 0:
		winner = "cards1"
	elif score_difference < 0:
		winner = "cards2"
	else:
		winner = "tie"
	
	return {
		"cards1_score": score1,
		"cards2_score": score2,
		"winner": winner,
		"score_difference": abs(score_difference),
		"comparison_summary": "组合1: %d分 vs 组合2: %d分 (差距: %d分)" % [
			score1.final_score,
			score2.final_score,
			abs(score_difference)
		]
	}

## 🎯 获取得分统计信息
static func get_score_statistics(score_results: Array) -> Dictionary:
	if score_results.is_empty():
		return {"error": "无得分数据"}
	
	var scores = []
	var hand_type_distribution = {}
	var total_bonus = 0
	var total_multiplier = 0.0
	
	for result in score_results:
		scores.append(result.final_score)
		
		var hand_type_name = result.hand_analysis.hand_type_name
		if not hand_type_distribution.has(hand_type_name):
			hand_type_distribution[hand_type_name] = 0
		hand_type_distribution[hand_type_name] += 1
		
		total_bonus += result.bonus_score
		total_multiplier += result.dynamic_multiplier
	
	scores.sort()
	var count = scores.size()
	
	return {
		"count": count,
		"min_score": scores[0],
		"max_score": scores[-1],
		"average_score": scores.reduce(func(sum, score): return sum + score, 0) / count,
		"median_score": scores[count / 2] if count % 2 == 1 else (scores[count / 2 - 1] + scores[count / 2]) / 2,
		"hand_type_distribution": hand_type_distribution,
		"average_bonus": total_bonus / count,
		"average_multiplier": total_multiplier / count
	}

## 🔧 创建空得分结果
static func _create_empty_score_result() -> Dictionary:
	return {
		"hand_analysis": SmartHandAnalyzerClass._create_empty_result(),
		"fixed_base_score": 0,
		"dynamic_rank_score": 0,
		"bonus_score": 0,
		"dynamic_multiplier": 1.0,
		"final_score": 0,
		"calculation_formula": "无有效卡牌",
		"detailed_formula": "无有效卡牌",
		"hand_type_level": 1,
		"level_info": "LV1 (1.0x)"
	}

## 🎯 验证得分计算
static func validate_score_calculation(cards: Array, expected_score: int, ranking_manager: HandTypeRankingManager = null) -> Dictionary:
	var result = calculate_poker_hand_score(cards, ranking_manager)
	var actual_score = result.final_score
	var is_correct = actual_score == expected_score
	var difference = actual_score - expected_score
	
	return {
		"is_correct": is_correct,
		"expected_score": expected_score,
		"actual_score": actual_score,
		"difference": difference,
		"calculation_details": result.detailed_formula,
		"validation_message": "验证%s: 期望%d分，实际%d分%s" % [
			"通过" if is_correct else "失败",
			expected_score,
			actual_score,
			"" if is_correct else "，差距%d分" % difference
		]
	}
