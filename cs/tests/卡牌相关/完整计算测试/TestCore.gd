class_name CompleteHandTypeTestCore
extends RefCounted

## 🎯 完整计算测试核心模块
##
## 核心功能：
## - 统一的牌型识别测试接口
## - 完整的测试结果格式化
## - 性能测试和验证测试

# 导入依赖（使用V2.3系统组件）
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const HandTypeSystemV2Class = preload("res://cs/卡牌系统/数据/管理器/HandTypeSystemV2.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")

var ranking_system: HandTypeRankingManagerClass

## 🎯 初始化
func _init():
	ranking_system = HandTypeRankingManagerClass.new()
	print("HandTypeTestCore: 核心测试模块初始化完成")

## 🎯 分析手牌牌型（主要接口）
func analyze_hand_type(cards: Array) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if cards.is_empty():
		return _create_empty_test_result()
	
	# 使用V2.3系统进行完整分析
	var v2_result = HandTypeSystemV2Class.analyze_and_score(cards, ranking_system)

	var end_time = Time.get_ticks_msec()
	var analysis_time = end_time - start_time

	if not v2_result.is_valid:
		return _create_empty_test_result()

	var hand_result = v2_result.hand_result
	var score_result = v2_result.score_result

	# 构建完整的测试结果
	var test_result = {
		# 基础信息
		"hand_type": hand_result.hand_type,
		"hand_type_name": hand_result.hand_type_name,
		"hand_description": hand_result.description,

		# 卡牌信息
		"best_hand_cards": hand_result.contributing_cards,
		"discarded_cards": [],  # V2.3系统中暂不提供弃置卡牌信息
		"total_cards": cards.size(),

		# 得分信息
		"fixed_base_score": score_result.base_score,
		"dynamic_rank_score": score_result.value_score,
		"bonus_score": score_result.bonus_score,
		"dynamic_multiplier": score_result.hand_type_multiplier,
		"final_score": score_result.final_score,

		# 等级信息
		"hand_type_level": score_result.hand_type_level,
		"level_info": "LV%d (%.2fx)" % [score_result.hand_type_level, score_result.hand_type_multiplier],

		# 计算公式
		"calculation_formula": score_result.calculation_formula,
		"detailed_formula": score_result.detailed_formula,

		# 性能指标
		"analysis_time": analysis_time,
		"combinations_tested": hand_result.combinations_tested,

		# 分析详情
		"analysis_details": _generate_analysis_details_v2(hand_result, score_result),

		# 调试信息
		"debug_info": _generate_debug_info_v2(hand_result, score_result)
	}
	
	return test_result

## 🎯 批量分析多组手牌
func batch_analyze_hands(card_combinations: Array) -> Array:
	var results = []
	var total_start_time = Time.get_ticks_msec()
	
	print("HandTypeTestCore: 开始批量分析 %d 组手牌" % card_combinations.size())
	
	for i in range(card_combinations.size()):
		var cards = card_combinations[i]
		var result = analyze_hand_type(cards)
		result.batch_index = i
		results.append(result)
		
		if (i + 1) % 10 == 0:
			print("HandTypeTestCore: 已完成 %d/%d 组分析" % [i + 1, card_combinations.size()])
	
	var total_end_time = Time.get_ticks_msec()
	var total_time = total_end_time - total_start_time
	
	print("HandTypeTestCore: 批量分析完成，总耗时: %dms" % total_time)
	
	return results

## 🎯 性能测试
func performance_test(cards: Array, test_name: String = "性能测试") -> Dictionary:
	print("HandTypeTestCore: 开始性能测试 - %s" % test_name)
	
	var iterations = 100
	var times = []
	
	for i in range(iterations):
		var start_time = Time.get_ticks_usec()
		analyze_hand_type(cards)
		var end_time = Time.get_ticks_usec()
		times.append(end_time - start_time)
	
	times.sort()
	var total_time = times.reduce(func(sum, time): return sum + time, 0)
	
	var performance_result = {
		"test_name": test_name,
		"iterations": iterations,
		"total_time_us": total_time,
		"average_time_us": total_time / iterations,
		"min_time_us": times[0],
		"max_time_us": times[-1],
		"median_time_us": times[iterations / 2],
		"cards_count": cards.size(),
		"performance_rating": _get_performance_rating(total_time / iterations)
	}
	
	print("HandTypeTestCore: 性能测试完成 - 平均耗时: %.1fμs" % performance_result.average_time_us)
	
	return performance_result

## 🎯 验证测试
func validate_hand_type(cards: Array, expected_hand_type: String) -> Dictionary:
	var result = analyze_hand_type(cards)
	var actual_hand_type = result.hand_type_name
	var is_correct = actual_hand_type == expected_hand_type
	
	var validation_result = {
		"is_correct": is_correct,
		"expected_hand_type": expected_hand_type,
		"actual_hand_type": actual_hand_type,
		"cards_description": _format_cards_description(cards),
		"validation_message": "验证%s: 期望[%s]，实际[%s]" % [
			"通过" if is_correct else "失败",
			expected_hand_type,
			actual_hand_type
		],
		"full_result": result
	}
	
	if is_correct:
		print("✅ 验证通过: %s -> %s" % [validation_result.cards_description, actual_hand_type])
	else:
		print("❌ 验证失败: %s -> 期望[%s] 实际[%s]" % [
			validation_result.cards_description,
			expected_hand_type,
			actual_hand_type
		])
	
	return validation_result

## 🎯 格式化结果用于显示
func format_result_for_display(result: Dictionary) -> String:
	var display_text = ""
	
	# 牌型信息
	display_text += "🎯 牌型识别: %s\n" % result.hand_description
	
	# 最佳组合
	if result.best_hand_cards.size() > 0:
		var cards_text = ""
		for card in result.best_hand_cards:
			cards_text += "%s " % card.get_display_name()
		display_text += "🃏 最佳组合: %s\n" % cards_text
	
	# 弃置卡牌
	if result.discarded_cards.size() > 0:
		var discarded_text = ""
		for card in result.discarded_cards:
			discarded_text += "%s " % card.get_display_name()
		display_text += "🗑️ 弃置卡牌: %s\n" % discarded_text
	
	# 得分信息
	display_text += "💎 牌型得分: %d分 (%s)\n" % [result.final_score, result.calculation_formula]
	display_text += "📊 等级信息: %s\n" % result.level_info
	
	# 性能信息
	display_text += "⏱️ 分析耗时: %dms" % result.analysis_time
	if result.combinations_tested > 1:
		display_text += "，测试组合: %d个" % result.combinations_tested
	
	return display_text

## 🎯 设置牌型等级
func set_hand_type_level(hand_type: int, level: int) -> bool:
	return ranking_system.set_hand_type_level(hand_type, level)

## 🎯 获取等级系统
func get_ranking_system() -> HandTypeRankingManager:
	return ranking_system

## 🔧 生成分析详情 (V2.3版本)
func _generate_analysis_details_v2(hand_result, score_result) -> String:
	var details = ""

	details += "牌型分析详情:\n"
	details += "- 识别牌型: %s\n" % hand_result.hand_type_name
	details += "- 主要数值: %d\n" % hand_result.primary_value
	if hand_result.secondary_value > 0:
		details += "- 次要数值: %d\n" % hand_result.secondary_value

	if hand_result.kickers.size() > 0:
		details += "- 踢脚牌: %s\n" % str(hand_result.kickers)

	details += "\n得分计算详情:\n"
	details += "- 基础分: %d\n" % score_result.base_score
	details += "- 牌面分: %d\n" % score_result.value_score
	details += "- 附加分: %d\n" % score_result.bonus_score
	details += "- 牌型倍率: %.2fx\n" % score_result.hand_type_multiplier
	details += "- 最终倍率: %.2fx\n" % score_result.final_multiplier
	details += "- 最终得分: %d\n" % score_result.final_score

	return details

## 🔧 生成调试信息 (V2.3版本)
func _generate_debug_info_v2(hand_result, score_result) -> Dictionary:
	return {
		"hand_type_enum": hand_result.hand_type,
		"primary_value": hand_result.primary_value,
		"secondary_value": hand_result.secondary_value,
		"kickers": hand_result.kickers,
		"base_score": score_result.base_score,
		"value_score": score_result.value_score,
		"contributing_cards_count": hand_result.contributing_cards.size(),
		"level": score_result.hand_type_level,
		"hand_type_multiplier": score_result.hand_type_multiplier,
		"final_multiplier": score_result.final_multiplier
	}

## 🔧 获取性能评级
func _get_performance_rating(avg_time_us: float) -> String:
	if avg_time_us < 100:
		return "优秀"
	elif avg_time_us < 500:
		return "良好"
	elif avg_time_us < 1000:
		return "一般"
	elif avg_time_us < 5000:
		return "较慢"
	else:
		return "慢"

## 🔧 格式化卡牌描述
func _format_cards_description(cards: Array) -> String:
	if cards.is_empty():
		return "无卡牌"
	
	var description = ""
	for i in range(cards.size()):
		if i > 0:
			description += " "
		description += cards[i].get_display_name()
	
	return description

## 🔧 创建空测试结果
func _create_empty_test_result() -> Dictionary:
	return {
		"hand_type": HandTypeEnumsClass.HandType.HIGH_CARD,
		"hand_type_name": "无牌",
		"hand_description": "无有效卡牌",
		"best_hand_cards": [],
		"discarded_cards": [],
		"total_cards": 0,
		"fixed_base_score": 0,
		"dynamic_rank_score": 0,
		"bonus_score": 0,
		"dynamic_multiplier": 1.0,
		"final_score": 0,
		"hand_type_level": 1,
		"level_info": "LV1 (1.0x)",
		"calculation_formula": "无有效卡牌",
		"detailed_formula": "无有效卡牌",
		"analysis_time": 0,
		"combinations_tested": 0,
		"analysis_details": "无有效卡牌进行分析",
		"debug_info": {}
	}
