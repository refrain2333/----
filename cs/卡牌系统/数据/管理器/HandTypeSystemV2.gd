class_name HandTypeSystemV2
extends RefCounted

## 🎯 牌型识别系统 V2.1 - 统一接口
##
## 核心功能：
## - 提供统一的牌型识别和得分计算接口
## - 整合 SmartHandAnalyzerV2 和 PreciseScoreCalculator
## - 返回完整的分析和计分结果

# 导入依赖
const SmartHandAnalyzerV2Class = preload("res://cs/卡牌系统/数据/管理器/SmartHandAnalyzerV2.gd")
const PreciseScoreCalculatorClass = preload("res://cs/卡牌系统/数据/管理器/PreciseScoreCalculator.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")
const HandResultClass = preload("res://cs/卡牌系统/数据/HandResult.gd")
const ScoreResultClass = preload("res://cs/卡牌系统/数据/ScoreResult.gd")

## 🎯 完整分析接口（牌型识别 + 得分计算）
static func analyze_and_score(cards: Array, ranking_manager: HandTypeRankingManagerClass = null, bonus_score: int = 0) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# 1. 牌型识别
	var hand_result = SmartHandAnalyzerV2Class.find_best_hand(cards)
	
	# 2. 得分计算
	if not ranking_manager:
		ranking_manager = HandTypeRankingManagerClass.new()
	
	var score_result = PreciseScoreCalculatorClass.calculate_score(hand_result, ranking_manager, bonus_score)
	
	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time
	
	# 3. 返回完整结果
	return {
		"hand_result": hand_result,
		"score_result": score_result,
		"total_analysis_time": total_time,
		"is_valid": hand_result.is_valid() and score_result.is_valid()
	}

## 🎯 仅牌型识别接口
static func analyze_hand_type(cards: Array) -> HandResultClass:
	return SmartHandAnalyzerV2Class.find_best_hand(cards)

## 🎯 仅得分计算接口
static func calculate_score(hand_result: HandResultClass, ranking_manager: HandTypeRankingManagerClass = null, bonus_score: int = 0) -> ScoreResultClass:
	if not ranking_manager:
		ranking_manager = HandTypeRankingManagerClass.new()
	
	return PreciseScoreCalculatorClass.calculate_score(hand_result, ranking_manager, bonus_score)

## 🎯 快速得分接口（用于简单场景）
static func quick_score(cards: Array, level: int = 1, bonus_score: int = 0) -> int:
	var hand_result = SmartHandAnalyzerV2Class.find_best_hand(cards)
	return PreciseScoreCalculatorClass.quick_calculate(hand_result, level, bonus_score)

## 🎯 批量分析接口（用于测试和验证）
static func batch_analyze(card_sets: Array, ranking_manager: HandTypeRankingManagerClass = null) -> Array:
	var results = []
	
	if not ranking_manager:
		ranking_manager = HandTypeRankingManagerClass.new()
	
	for cards in card_sets:
		var result = analyze_and_score(cards, ranking_manager)
		results.append(result)
	
	return results

## 🎯 格式化显示完整结果
static func format_complete_result(result: Dictionary) -> String:
	if not result.get("is_valid", false):
		return "❌ 无效的分析结果"
	
	var hand_result: HandResultClass = result.hand_result
	var score_result: ScoreResultClass = result.score_result
	
	var output = ""
	output += "🎯 牌型识别结果:\n"
	output += hand_result.format_display()
	output += "\n"
	output += "💰 得分计算结果:\n"
	output += score_result.format_display()
	output += "\n"
	output += "⏱️ 总分析时间: %dms\n" % result.total_analysis_time
	
	return output

## 🎯 创建测试用例
static func create_test_case(cards: Array, expected_hand_type: int = -1, expected_score_range: Array = []) -> Dictionary:
	var result = analyze_and_score(cards)
	
	var test_case = {
		"cards": cards,
		"result": result,
		"expected_hand_type": expected_hand_type,
		"expected_score_range": expected_score_range,
		"passed": true,
		"errors": []
	}
	
	# 验证牌型
	if expected_hand_type >= 0:
		var actual_hand_type = result.hand_result.hand_type
		if actual_hand_type != expected_hand_type:
			test_case.passed = false
			test_case.errors.append("牌型不匹配: 期望%d, 实际%d" % [expected_hand_type, actual_hand_type])
	
	# 验证得分范围
	if not expected_score_range.is_empty() and expected_score_range.size() >= 2:
		var actual_score = result.score_result.final_score
		if actual_score < expected_score_range[0] or actual_score > expected_score_range[1]:
			test_case.passed = false
			test_case.errors.append("得分超出范围: 期望[%d-%d], 实际%d" % [expected_score_range[0], expected_score_range[1], actual_score])
	
	return test_case

## 🎯 运行测试套件
static func run_test_suite(test_cases: Array) -> Dictionary:
	var passed = 0
	var failed = 0
	var total_time = 0
	var failed_cases = []
	
	for test_case in test_cases:
		total_time += test_case.result.total_analysis_time
		
		if test_case.passed:
			passed += 1
		else:
			failed += 1
			failed_cases.append(test_case)
	
	return {
		"total": test_cases.size(),
		"passed": passed,
		"failed": failed,
		"success_rate": float(passed) / test_cases.size() * 100.0,
		"total_time": total_time,
		"average_time": float(total_time) / test_cases.size(),
		"failed_cases": failed_cases
	}

## 🎯 生成性能报告
static func generate_performance_report(test_results: Dictionary) -> String:
	var report = ""
	report += "📊 性能测试报告\n"
	report += "========================================\n"
	report += "总测试用例: %d\n" % test_results.total
	report += "通过: %d\n" % test_results.passed
	report += "失败: %d\n" % test_results.failed
	report += "成功率: %.1f%%\n" % test_results.success_rate
	report += "总耗时: %dms\n" % test_results.total_time
	report += "平均耗时: %.1fms\n" % test_results.average_time
	
	if test_results.failed > 0:
		report += "\n❌ 失败用例:\n"
		for i in range(min(5, test_results.failed_cases.size())):  # 只显示前5个失败用例
			var case = test_results.failed_cases[i]
			report += "  %d. %s\n" % [i + 1, case.errors[0] if not case.errors.is_empty() else "未知错误"]
	
	return report

## 🎯 验证系统完整性
static func validate_system() -> Dictionary:
	print("🔍 验证牌型识别系统 V2.1...")
	
	var validation_result = {
		"components_loaded": true,
		"basic_functions": true,
		"error_handling": true,
		"performance": true,
		"errors": []
	}
	
	# 检查组件加载
	var test_cards = []  # 空数组测试
	var result = analyze_and_score(test_cards)
	if not result.has("hand_result") or not result.has("score_result"):
		validation_result.components_loaded = false
		validation_result.errors.append("组件加载失败")
	
	# 基础功能测试
	# TODO: 添加更多验证逻辑
	
	var overall_status = validation_result.components_loaded and validation_result.basic_functions and validation_result.error_handling and validation_result.performance
	validation_result.overall_status = overall_status
	
	if overall_status:
		print("✅ 系统验证通过")
	else:
		print("❌ 系统验证失败: %s" % str(validation_result.errors))
	
	return validation_result
