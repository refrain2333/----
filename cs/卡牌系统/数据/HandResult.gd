class_name HandResult
extends RefCounted

## 🎯 牌型识别结果数据结构 (V2.1)
##
## 职责：描述"这是一手什么牌"
## 核心设计理念：数据隔离 - 牌型识别与计分分离

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")

## 基础牌型信息
var hand_type: HandTypeEnumsClass.HandType = HandTypeEnumsClass.HandType.HIGH_CARD  # 牌型枚举
var hand_type_name: String = ""              # 牌型中文名称
var description: String = ""                 # 牌型描述

## 核心牌值（用于计分）
var primary_value: float = 0.0      # 主要牌值 (e.g., 对子/三条的值)
var secondary_value: float = 0.0    # 次要牌值 (e.g., 两对/葫芦的次级值)

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
func set_core_values(primary: float, secondary: float = 0.0):
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

## 🎯 格式化显示（增强版 - 显示具体卡牌）
func format_display() -> String:
	var result = "🎯 牌型: %s\n" % hand_type_name
	result += "📝 描述: %s\n" % description

	# 显示构成牌型的核心卡牌
	if not contributing_cards.is_empty():
		result += "🃏 核心卡牌: %s\n" % _format_cards_display(contributing_cards)

	# 显示踢脚牌（如果有）
	if not kickers.is_empty():
		var kicker_cards = _get_kicker_cards_from_all_cards()
		if not kicker_cards.is_empty():
			result += "🎴 踢脚牌: %s (不计分)\n" % _format_cards_display(kicker_cards)
		else:
			result += "🎴 踢脚牌: %s (不计分)\n" % _format_values_as_cards(kickers)

	result += "🔢 核心牌值: %d" % primary_value
	if secondary_value > 0:
		result += " / %d" % secondary_value
	result += "\n"

	result += "📊 分析: %s方法, 测试%d种组合\n" % [analysis_method, combinations_tested]

	return result

## 🔧 格式化卡牌显示（牌面形式）
func _format_cards_display(cards: Array) -> String:
	var card_strings = []

	for card in cards:
		if card and card.has_method("get"):
			# 如果是CardData对象
			var suit_symbol = _get_suit_symbol(card.suit)
			var value_symbol = _get_value_symbol(card.base_value)
			card_strings.append("%s%s" % [suit_symbol, value_symbol])
		elif card and typeof(card) == TYPE_DICTIONARY:
			# 如果是字典格式
			var suit_symbol = _get_suit_symbol(card.get("suit", ""))
			var value_symbol = _get_value_symbol(card.get("base_value", 0))
			card_strings.append("%s%s" % [suit_symbol, value_symbol])

	return " ".join(card_strings)

## 🔧 将数值转换为卡牌显示格式
func _format_values_as_cards(values: Array) -> String:
	var card_strings = []

	for value in values:
		var value_symbol = _get_value_symbol(value)
		card_strings.append("?%s" % value_symbol)  # 用?表示未知花色

	return " ".join(card_strings)

## 🔧 获取花色符号
func _get_suit_symbol(suit: String) -> String:
	match suit.to_lower():
		"hearts": return "♥"
		"diamonds": return "♦"
		"clubs": return "♣"
		"spades": return "♠"
		_: return "?"

## 🔧 获取数值符号
func _get_value_symbol(value: int) -> String:
	match value:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"  # 高位A
		_: return str(value)

## 🔧 从all_cards中获取踢脚牌卡牌对象
func _get_kicker_cards_from_all_cards() -> Array:
	var kicker_cards = []

	# 如果有all_cards，尝试匹配踢脚牌数值
	if not all_cards.is_empty() and not kickers.is_empty():
		for card in all_cards:
			if card and card.has_method("get"):
				var card_value = card.base_value
				# 处理A的特殊情况
				if card_value == 1 and kickers.has(14):
					kicker_cards.append(card)
				elif card_value == 14 and kickers.has(1):
					kicker_cards.append(card)
				elif kickers.has(card_value):
					kicker_cards.append(card)

	return kicker_cards

## 🎯 创建空结果
static func create_empty() -> HandResult:
	var result = HandResult.new()
	result.description = "无有效卡牌"
	return result
