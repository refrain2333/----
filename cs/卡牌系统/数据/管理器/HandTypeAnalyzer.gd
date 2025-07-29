class_name HandTypeAnalyzer
extends RefCounted

## 🎯 基础5张牌牌型识别器
## 
## 核心功能：
## - 识别标准扑克牌型（高牌到皇家同花顺）
## - 支持A的特殊处理（1和14）
## - 提供详细的牌型分析结果
## - 遵循项目架构规范，放置在管理器目录

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")

# 使用共享的枚举定义
const HandType = HandTypeEnumsClass.HandType
const HAND_TYPE_NAMES = HandTypeEnumsClass.HAND_TYPE_NAMES
const BASE_SCORES = HandTypeEnumsClass.BASE_SCORES

## 🎯 分析5张牌的牌型
static func analyze_hand(cards: Array) -> Dictionary:
	if cards.size() != 5:
		push_error("HandTypeAnalyzer: 必须是5张牌，当前: %d张" % cards.size())
		return _create_empty_result()
	
	# 提取数值和花色
	var values = []
	var suits = []
	for card in cards:
		values.append(card.base_value)
		suits.append(card.suit)
	
	# 排序数值（从大到小）
	values.sort()
	values.reverse()
	
	# 检测各种牌型
	var is_flush = _is_flush(suits)
	var straight_info = _is_straight(values)
	var value_counts = _count_values(values)
	
	# 按优先级判断牌型
	var hand_type: HandType
	var primary_value: int = 0
	var secondary_value: int = 0
	var kickers: Array = []
	var description: String = ""
	
	# 五条（最高优先级）
	if _has_five_of_kind(value_counts):
		hand_type = HandType.FIVE_KIND
		primary_value = _get_five_of_kind_value(value_counts)
		description = "五条: %s" % _value_to_string(primary_value)
	
	# 皇家同花顺
	elif is_flush and straight_info.is_straight and straight_info.high_card == 14:
		hand_type = HandType.ROYAL_FLUSH
		primary_value = 14
		description = "皇家同花顺"
	
	# 同花顺
	elif is_flush and straight_info.is_straight:
		hand_type = HandType.STRAIGHT_FLUSH
		primary_value = straight_info.high_card
		description = "同花顺: %s高" % _value_to_string(primary_value)
	
	# 四条
	elif _has_four_of_kind(value_counts):
		hand_type = HandType.FOUR_KIND
		primary_value = _get_four_of_kind_value(value_counts)
		kickers = _get_kickers(value_counts, [primary_value])
		description = "四条: %s" % _value_to_string(primary_value)
	
	# 葫芦
	elif _has_full_house(value_counts):
		var full_house_info = _get_full_house_values(value_counts)
		hand_type = HandType.FULL_HOUSE
		primary_value = full_house_info.three_kind
		secondary_value = full_house_info.pair
		description = "葫芦: %s带%s" % [_value_to_string(primary_value), _value_to_string(secondary_value)]
	
	# 同花
	elif is_flush:
		hand_type = HandType.FLUSH
		primary_value = values[0]
		kickers = values.slice(1)
		description = "同花: %s高" % _value_to_string(primary_value)
	
	# 顺子
	elif straight_info.is_straight:
		hand_type = HandType.STRAIGHT
		primary_value = straight_info.high_card
		description = "顺子: %s高" % _value_to_string(primary_value)
	
	# 三条
	elif _has_three_of_kind(value_counts):
		hand_type = HandType.THREE_KIND
		primary_value = _get_three_of_kind_value(value_counts)
		kickers = _get_kickers(value_counts, [primary_value])
		description = "三条: %s" % _value_to_string(primary_value)
	
	# 两对
	elif _has_two_pair(value_counts):
		var pair_values = _get_pair_values(value_counts)
		hand_type = HandType.TWO_PAIR
		primary_value = max(pair_values[0], pair_values[1])
		secondary_value = min(pair_values[0], pair_values[1])
		kickers = _get_kickers(value_counts, [primary_value, secondary_value])
		description = "两对: %s和%s" % [_value_to_string(primary_value), _value_to_string(secondary_value)]
	
	# 一对
	elif _has_pair(value_counts):
		hand_type = HandType.PAIR
		primary_value = _get_pair_value(value_counts)
		kickers = _get_kickers(value_counts, [primary_value])
		description = "一对: %s" % _value_to_string(primary_value)
	
	# 高牌
	else:
		hand_type = HandType.HIGH_CARD
		primary_value = values[0]
		kickers = values.slice(1)
		description = "高牌: %s" % _value_to_string(primary_value)
	
	return {
		"hand_type": hand_type,
		"hand_type_name": HAND_TYPE_NAMES[hand_type],
		"description": description,
		"primary_value": primary_value,
		"secondary_value": secondary_value,
		"kickers": kickers,
		"cards": cards,
		"base_score": BASE_SCORES[hand_type]
	}

## 🔧 检测同花
static func _is_flush(suits: Array) -> bool:
	var first_suit = suits[0]
	for suit in suits:
		if suit != first_suit:
			return false
	return true

## 🔧 检测顺子
static func _is_straight(values: Array) -> Dictionary:
	var sorted_values = values.duplicate()
	sorted_values.sort()
	
	# 检测A-2-3-4-5（轮子顺）
	if sorted_values == [1, 2, 3, 4, 5]:
		return {"is_straight": true, "high_card": 5}
	
	# 检测10-J-Q-K-A（皇家顺）
	if sorted_values == [1, 10, 11, 12, 13]:
		return {"is_straight": true, "high_card": 14}
	
	# 检测普通连续顺子
	for i in range(1, sorted_values.size()):
		if sorted_values[i] != sorted_values[i-1] + 1:
			return {"is_straight": false, "high_card": 0}
	
	return {"is_straight": true, "high_card": sorted_values[-1]}

## 🔧 统计数值频率
static func _count_values(values: Array) -> Dictionary:
	var counts = {}
	for value in values:
		counts[value] = counts.get(value, 0) + 1
	return counts

## 🔧 检测五条
static func _has_five_of_kind(counts: Dictionary) -> bool:
	for count in counts.values():
		if count == 5:
			return true
	return false

static func _get_five_of_kind_value(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] == 5:
			return value
	return 0

## 🔧 检测四条
static func _has_four_of_kind(counts: Dictionary) -> bool:
	for count in counts.values():
		if count == 4:
			return true
	return false

static func _get_four_of_kind_value(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] == 4:
			return value
	return 0

## 🔧 检测葫芦
static func _has_full_house(counts: Dictionary) -> bool:
	var has_three = false
	var has_pair = false
	for count in counts.values():
		if count == 3:
			has_three = true
		elif count == 2:
			has_pair = true
	return has_three and has_pair

static func _get_full_house_values(counts: Dictionary) -> Dictionary:
	var three_kind = 0
	var pair = 0
	for value in counts:
		if counts[value] == 3:
			three_kind = value
		elif counts[value] == 2:
			pair = value
	return {"three_kind": three_kind, "pair": pair}

## 🔧 检测三条
static func _has_three_of_kind(counts: Dictionary) -> bool:
	for count in counts.values():
		if count == 3:
			return true
	return false

static func _get_three_of_kind_value(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] == 3:
			return value
	return 0

## 🔧 检测两对
static func _has_two_pair(counts: Dictionary) -> bool:
	var pair_count = 0
	for count in counts.values():
		if count == 2:
			pair_count += 1
	return pair_count == 2

## 🔧 检测一对
static func _has_pair(counts: Dictionary) -> bool:
	for count in counts.values():
		if count == 2:
			return true
	return false

static func _get_pair_value(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] == 2:
			return value
	return 0

static func _get_pair_values(counts: Dictionary) -> Array:
	var pairs = []
	for value in counts:
		if counts[value] == 2:
			pairs.append(value)
	pairs.sort()
	pairs.reverse()
	return pairs

## 🔧 获取踢脚牌
static func _get_kickers(counts: Dictionary, exclude_values: Array) -> Array:
	var kickers = []
	for value in counts:
		if not exclude_values.has(value):
			for i in range(counts[value]):
				kickers.append(value)
	kickers.sort()
	kickers.reverse()
	return kickers

## 🔧 数值转字符串
static func _value_to_string(value: int) -> String:
	match value:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(value)

## 🔧 创建空结果
static func _create_empty_result() -> Dictionary:
	return {
		"hand_type": HandType.HIGH_CARD,
		"hand_type_name": "无牌",
		"description": "无有效卡牌",
		"primary_value": 0,
		"secondary_value": 0,
		"kickers": [],
		"cards": [],
		"base_score": 0
	}
