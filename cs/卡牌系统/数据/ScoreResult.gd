class_name ScoreResult
extends RefCounted

## 🎯 得分计算结果数据结构 (V2.1)
##
## 职责：描述"这手牌值多少分，以及如何算出来的"
## 核心设计理念：公式透明化 - 每个计算步骤都可验证

## 最终得分
var final_score: int = 0        # 最终得分 (取整后)
var raw_score: float = 0.0      # 原始得分 (取整前)

## 得分组成部分（原子化拆解）
var base_score: int = 0         # 基础牌型分
var value_score: float = 0.0    # 牌面价值分
var bonus_score: int = 0        # 附加分
var total_base: float = 0.0     # 基础总分 (base + value + bonus)

## 倍率信息 (V2.3版本)
var hand_type_multiplier: float = 1.0  # 牌型倍率 (核心成长来源)
var final_multiplier: float = 1.0      # 最终倍率 (全局效果)
var core_score: float = 0.0            # 核心分数 ((基础分+牌面分) × 牌型倍率)

## 等级信息
var hand_type_level: int = 1    # 牌型等级
var level_info: Dictionary = {} # 等级详细信息

## 计算公式（用于验证和调试）
var calculation_formula: String = ""     # 简化公式
var detailed_formula: String = ""        # 详细公式
var step_by_step: Array = []     # 分步计算过程

## 性能指标
var calculation_time_ms: int = 0  # 计算耗时（毫秒）

## 🎯 构造函数
func _init():
	pass

## 🎯 设置最终得分
func set_final_score(raw: float, final: int):
	raw_score = raw
	final_score = final

## 🎯 设置得分组成部分
func set_score_components(base: int, value: int, bonus: int):
	base_score = base
	value_score = value
	bonus_score = bonus
	total_base = base + value + bonus

## 🎯 设置倍率信息 (V2.3版本)
func set_multiplier_info(hand_type_mult: float, level: int, level_details: Dictionary, final_mult: float = 1.0, core_sc: float = 0.0):
	hand_type_multiplier = hand_type_mult
	final_multiplier = final_mult
	core_score = core_sc
	hand_type_level = level
	level_info = level_details.duplicate()

## 🎯 设置计算公式
func set_calculation_formulas(simple: String, detailed: String, steps: Array):
	calculation_formula = simple
	detailed_formula = detailed
	step_by_step = steps.duplicate()

## 🎯 设置性能指标
func set_performance_metrics(time_ms: int):
	calculation_time_ms = time_ms

## 🎯 验证结果完整性
func is_valid() -> bool:
	return final_score >= 0 and not calculation_formula.is_empty()

## 🎯 转换为字典（用于调试和序列化 - V2.3版本）
func to_dict() -> Dictionary:
	return {
		"final_score": final_score,
		"raw_score": raw_score,
		"base_score": base_score,
		"value_score": value_score,
		"bonus_score": bonus_score,
		"total_base": total_base,
		"hand_type_multiplier": hand_type_multiplier,
		"final_multiplier": final_multiplier,
		"core_score": core_score,
		"hand_type_level": hand_type_level,
		"level_info": level_info,
		"calculation_formula": calculation_formula,
		"detailed_formula": detailed_formula,
		"step_by_step": step_by_step,
		"calculation_time_ms": calculation_time_ms
	}

## 🎯 格式化显示 (V2.3版本)
func format_display() -> String:
	var result = "💰 最终得分: %d\n" % final_score
	result += "📊 计算公式: %s\n" % calculation_formula
	result += "🔍 详细分解:\n"
	result += "   - 基础分: %d\n" % base_score
	result += "   - 牌面分: %d\n" % value_score
	result += "   - 牌型倍率: %.2fx (LV%d)\n" % [hand_type_multiplier, hand_type_level]
	result += "   - 核心分数: %.2f\n" % core_score
	result += "   - 附加分: %d\n" % bonus_score
	result += "   - 最终倍率: %.2fx\n" % final_multiplier
	result += "⏱️ 计算耗时: %dms\n" % calculation_time_ms

	if not step_by_step.is_empty():
		result += "📝 计算步骤:\n"
		for i in range(step_by_step.size()):
			result += "   %d. %s\n" % [i + 1, step_by_step[i]]

	return result

## 🎯 创建空结果
static func create_empty() -> ScoreResult:
	var result = ScoreResult.new()
	result.calculation_formula = "无有效计算"
	return result

## 🎯 快速创建结果
static func create_result(final: int, base: int, value: int, bonus: int, multiplier: float, level: int) -> ScoreResult:
	var result = ScoreResult.new()
	result.set_final_score(final, final)
	result.set_score_components(base, value, bonus)
	result.set_multiplier_info(multiplier, level, {})
	
	# 生成基础公式
	var formula = "ROUND((%d + %d + %d) × %.2f)" % [base, value, bonus, multiplier]
	result.set_calculation_formulas(formula, formula, [])
	
	return result
