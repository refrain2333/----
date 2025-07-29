class_name HandResult
extends RefCounted

## 🎯 牌型识别结果数据结构 (V2.1)
##
## 职责：描述"这是一手什么牌"
## 核心设计理念：数据隔离 - 牌型识别与计分分离

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")

## 基础牌型信息
var hand_type: HandTypeEnumsClass.HandType  # 牌型枚举
var hand_type_name: String = ""              # 牌型中文名称
var description: String = ""                 # 牌型描述

## 核心牌值（用于计分）
var primary_value: int = 0      # 主要牌值 (e.g., 对子/三条的值)
var secondary_value: int = 0    # 次要牌值 (e.g., 两对/葫芦的次级值)

## 卡牌组织
var contributing_cards: Array = []  # 构成牌型的核心卡牌
var kickers: Array = []          # 踢脚牌数值 (仅用于比大小, 不参与计分!)
var all_cards: Array = []       # 所有参与分析的卡牌

## 分析元数据
var combinations_tested: int = 0    # 测试的组合数量
var analysis_method: String = ""    # 分析方法 ("direct", "exhaustive", "heuristic")

## 🎯 构造函数
func _init():
	hand_type = HandTypeEnumsClass.HandType.HIGH_CARD
	hand_type_name = "高牌"
	description = "无特殊牌型"

## 🎯 设置牌型信息
func set_hand_type_info(type: HandTypeEnumsClass.HandType, name: String, desc: String):
	hand_type = type
	hand_type_name = name
	description = desc

## 🎯 设置核心牌值
func set_core_values(primary: int, secondary: int = 0):
	primary_value = primary
	secondary_value = secondary

## 🎯 设置卡牌信息
func set_cards_info(core_cards: Array, kicker_values: Array, total_cards: Array):
	contributing_cards = core_cards.duplicate()
	kickers = kicker_values.duplicate()
	all_cards = total_cards.duplicate()

## 🎯 设置分析元数据
func set_analysis_metadata(tested_combinations: int, method: String):
	combinations_tested = tested_combinations
	analysis_method = method

## 🎯 获取基础分数（从枚举中查询）
func get_base_score() -> int:
	return HandTypeEnumsClass.BASE_SCORES.get(hand_type, 0)

## 🎯 验证结果完整性
func is_valid() -> bool:
	return hand_type != null and not hand_type_name.is_empty() and not contributing_cards.is_empty()

## 🎯 转换为字典（用于调试和序列化）
func to_dict() -> Dictionary:
	return {
		"hand_type": hand_type,
		"hand_type_name": hand_type_name,
		"description": description,
		"primary_value": primary_value,
		"secondary_value": secondary_value,
		"contributing_cards_count": contributing_cards.size(),
		"kickers": kickers,
		"total_cards_count": all_cards.size(),
		"combinations_tested": combinations_tested,
		"analysis_method": analysis_method,
		"base_score": get_base_score()
	}

## 🎯 格式化显示
func format_display() -> String:
	var result = "🎯 牌型: %s\n" % hand_type_name
	result += "📝 描述: %s\n" % description
	result += "🔢 核心牌值: %d" % primary_value
	if secondary_value > 0:
		result += " / %d" % secondary_value
	result += "\n"
	
	if not kickers.is_empty():
		result += "🃏 踢脚牌: %s (不计分)\n" % str(kickers)
	
	result += "📊 分析: %s方法, 测试%d种组合\n" % [analysis_method, combinations_tested]
	
	return result

## 🎯 创建空结果
static func create_empty() -> HandResult:
	var result = HandResult.new()
	result.description = "无有效卡牌"
	return result
