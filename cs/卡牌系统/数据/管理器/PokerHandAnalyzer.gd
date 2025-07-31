class_name PokerHandAnalyzer
extends RefCounted

## 🎯 5张牌识别调度器 (V2.1)
##
## 核心功能：
## - 可插拔的牌型评估器架构
## - 按优先级调度各种牌型评估器
## - 返回标准化的 HandResult 对象

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const HandResultClass = preload("res://cs/卡牌系统/数据/HandResult.gd")

# 牌型评估器列表（按优先级排序）
static var evaluators: Array[Dictionary] = []

## 🎯 初始化评估器系统
static func _static_init():
	if evaluators.is_empty():
		_register_default_evaluators()

## 🎯 注册默认评估器
static func _register_default_evaluators():
	# 按优先级从高到低注册评估器
	register_evaluator("ROYAL_FLUSH", _evaluate_royal_flush, 11)
	register_evaluator("FIVE_KIND", _evaluate_five_kind, 10)
	register_evaluator("STRAIGHT_FLUSH", _evaluate_straight_flush, 9)
	register_evaluator("FOUR_KIND", _evaluate_four_kind, 8)
	register_evaluator("FULL_HOUSE", _evaluate_full_house, 7)
	register_evaluator("FLUSH", _evaluate_flush, 6)
	register_evaluator("STRAIGHT", _evaluate_straight, 5)
	register_evaluator("THREE_KIND", _evaluate_three_kind, 4)
	register_evaluator("TWO_PAIR", _evaluate_two_pair, 3)
	register_evaluator("PAIR", _evaluate_pair, 2)
	register_evaluator("HIGH_CARD", _evaluate_high_card, 1)
	
	# 按优先级排序
	evaluators.sort_custom(func(a, b): return a.priority > b.priority)
	
	print("PokerHandAnalyzer: 已注册 %d 个牌型评估器" % evaluators.size())

## 🎯 注册评估器
static func register_evaluator(name: String, evaluator_func: Callable, priority: int):
	evaluators.append({
		"name": name,
		"evaluator": evaluator_func,
		"priority": priority
	})

## 🎯 分析5张牌（主要接口）
static func analyze(cards: Array) -> HandResultClass:
	_static_init()  # 确保评估器已初始化
	
	if cards.size() != 5:
		push_error("PokerHandAnalyzer: 必须是5张牌，当前: %d张" % cards.size())
		return HandResultClass.create_empty()
	
	# 预处理卡牌数据
	var card_data = _preprocess_cards(cards)
	
	# 按优先级尝试各种牌型
	for evaluator_info in evaluators:
		var result = evaluator_info.evaluator.call(card_data)
		if result != null:
			print("🎯 PokerHandAnalyzer: 识别到牌型 %s, contributing_cards数量: %d" % [result.hand_type_name, result.contributing_cards.size()])
			# 设置分析元数据
			result.set_analysis_metadata(1, "direct")
			# 只设置all_cards，保留评估器设置的contributing_cards
			result.all_cards = cards.duplicate()
			return result
	
	# 如果没有匹配的牌型，返回空结果
	push_error("PokerHandAnalyzer: 无法识别牌型")
	return HandResultClass.create_empty()

## 🎯 预处理卡牌数据
static func _preprocess_cards(cards: Array) -> Dictionary:
	var face_values = []  # 用于牌型识别的面值
	var base_values = []  # 用于分数计算的实际数值
	var suits = []

	for card in cards:
		var face_value = card.get_face_value()  # 从ID提取面值
		var base_value = card.base_value        # 实际数值
		var suit = card.get_face_suit()         # 从ID提取花色

		face_values.append(face_value)
		base_values.append(base_value)
		suits.append(suit)

	# 排序面值（从大到小）- 用于牌型识别
	# 特殊处理：A(1)在高牌时应该被视为最大的牌
	var sorted_face_values = face_values.duplicate()
	sorted_face_values.sort_custom(func(a, b):
		# A(1)在非顺子情况下视为最大牌(14)
		var val_a = a if a != 1 else 14
		var val_b = b if b != 1 else 14
		return val_a > val_b
	)

	return {
		"cards": cards,
		"face_values": sorted_face_values,      # 用于牌型识别
		"base_values": base_values,             # 用于分数计算
		"suits": suits,
		"value_counts": _count_values(sorted_face_values),
		"is_flush": _is_flush(suits),
		"straight_info": _is_straight(sorted_face_values)
	}

## 🎯 统计数值出现次数
static func _count_values(values: Array) -> Dictionary:
	var counts = {}
	for value in values:
		counts[value] = counts.get(value, 0) + 1
	return counts

## 🎯 检查是否为同花
static func _is_flush(suits: Array) -> bool:
	var first_suit = suits[0]
	for suit in suits:
		if suit != first_suit:
			return false
	return true

## 🎯 检查是否为顺子
static func _is_straight(values: Array) -> Dictionary:
	var sorted_values = values.duplicate()
	sorted_values.sort()

	# 检查标准顺子
	var is_standard_straight = true
	for i in range(1, sorted_values.size()):
		if sorted_values[i] != sorted_values[i-1] + 1:
			is_standard_straight = false
			break

	if is_standard_straight:
		return {"is_straight": true, "high_value": sorted_values.max(), "is_wheel": false}

	# 检查A-2-3-4-5顺子（轮子）
	if sorted_values == [1, 2, 3, 4, 5]:
		return {"is_straight": true, "high_value": 5, "is_wheel": true}

	# 检查10-J-Q-K-A顺子（皇家顺子）
	if sorted_values == [1, 10, 11, 12, 13]:
		return {"is_straight": true, "high_value": 14, "is_wheel": false}  # A作为高牌

	return {"is_straight": false, "high_value": 0, "is_wheel": false}

## 🎯 皇家同花顺评估器
static func _evaluate_royal_flush(data: Dictionary) -> HandResultClass:
	if not data.is_flush or not data.straight_info.is_straight:
		return null

	# 检查是否为10-J-Q-K-A（使用面值）
	var face_values = data.face_values.duplicate()
	face_values.sort()

	# 将A=1转换为A=14进行皇家同花顺检查
	var converted_values = []
	for value in face_values:
		if value == 1:
			converted_values.append(14)  # A转换为14
		else:
			converted_values.append(value)
	converted_values.sort()

	if converted_values == [10, 11, 12, 13, 14]:  # 10-J-Q-K-A
		var result = HandResultClass.new()
		result.set_hand_type_info(
			HandTypeEnumsClass.HandType.ROYAL_FLUSH,
			"皇家同花顺",
			"10-J-Q-K-A同花顺"
		)
		# 使用实际的base_value来计算主要牌值
		var ace_base_value = _get_base_value_for_face_value(data.cards, 1)  # 找A的base_value
		result.set_core_values(ace_base_value)  # 使用A的实际base_value
		result.set_cards_info(data.cards, [], data.cards)
		return result

	return null

## 🎯 根据面值获取对应的base_value
static func _get_base_value_for_face_value(cards: Array, target_face_value: int) -> int:
	for card in cards:
		if card.get_face_value() == target_face_value:
			return card.base_value
	return target_face_value  # 如果找不到，返回面值本身

## 🎯 五条评估器
static func _evaluate_five_kind(data: Dictionary) -> HandResultClass:
	for value in data.value_counts:
		if data.value_counts[value] == 5:
			var result = HandResultClass.new()
			result.set_hand_type_info(
				HandTypeEnumsClass.HandType.FIVE_KIND,
				"五条",
				"五条%s" % _value_to_string(value)
			)
			result.set_core_values(value)
			return result
	
	return null

## 🎯 同花顺评估器
static func _evaluate_straight_flush(data: Dictionary) -> HandResultClass:
	if not data.is_flush or not data.straight_info.is_straight:
		return null

	var result = HandResultClass.new()
	result.set_hand_type_info(
		HandTypeEnumsClass.HandType.STRAIGHT_FLUSH,
		"同花顺",
		"同花顺至%s" % _value_to_string(data.straight_info.high_value)
	)
	# 使用最高牌的base_value
	var high_base_value = _get_base_value_for_face_value(data.cards, data.straight_info.high_value)
	result.set_core_values(high_base_value)
	result.set_cards_info(data.cards, [], data.cards)
	return result

## 🎯 四条评估器
static func _evaluate_four_kind(data: Dictionary) -> HandResultClass:
	var four_value = 0
	var kicker = 0
	
	for value in data.value_counts:
		if data.value_counts[value] == 4:
			four_value = value
		elif data.value_counts[value] == 1:
			kicker = value
	
	if four_value > 0:
		# 收集构成牌型的卡牌
		var contributing_cards = []
		for card in data.cards:
			if card.get_face_value() == four_value:
				contributing_cards.append(card)

		var result = HandResultClass.new()
		result.set_hand_type_info(
			HandTypeEnumsClass.HandType.FOUR_KIND,
			"四条",
			"四条%s" % _value_to_string(four_value)
		)
		# 使用四条牌的base_value
		var four_base_value = _get_base_value_for_face_value(data.cards, four_value)
		result.set_core_values(four_base_value)
		result.kickers = [kicker]
		result.contributing_cards = contributing_cards
		return result
	
	return null

## 🎯 葫芦评估器
static func _evaluate_full_house(data: Dictionary) -> HandResultClass:
	var three_value = 0
	var pair_value = 0

	for value in data.value_counts:
		if data.value_counts[value] == 3:
			three_value = value
		elif data.value_counts[value] == 2:
			pair_value = value

	if three_value > 0 and pair_value > 0:
		# 收集构成牌型的卡牌
		var contributing_cards = []
		for card in data.cards:
			var face_value = card.get_face_value()
			if face_value == three_value or face_value == pair_value:
				contributing_cards.append(card)

		var result = HandResultClass.new()
		result.set_hand_type_info(
			HandTypeEnumsClass.HandType.FULL_HOUSE,
			"葫芦",
			"葫芦%s带%s" % [_value_to_string(three_value), _value_to_string(pair_value)]
		)
		# 使用三条和对子的base_value
		var three_base_value = _get_base_value_for_face_value(data.cards, three_value)
		var pair_base_value = _get_base_value_for_face_value(data.cards, pair_value)
		result.set_core_values(three_base_value, pair_base_value)
		result.contributing_cards = contributing_cards
		return result

	return null

## 🎯 同花评估器
static func _evaluate_flush(data: Dictionary) -> HandResultClass:
	if not data.is_flush:
		return null

	var result = HandResultClass.new()
	result.set_hand_type_info(
		HandTypeEnumsClass.HandType.FLUSH,
		"同花",
		"同花至%s" % _value_to_string(data.face_values[0])
	)
	# 使用最高牌的base_value
	var high_base_value = _get_base_value_for_face_value(data.cards, data.face_values[0])
	result.set_core_values(high_base_value)
	result.kickers = data.face_values.slice(1)  # 其余4张作为踢脚牌
	result.set_cards_info(data.cards, result.kickers, data.cards)
	return result

## 🎯 顺子评估器
static func _evaluate_straight(data: Dictionary) -> HandResultClass:
	if not data.straight_info.is_straight:
		return null

	var result = HandResultClass.new()
	result.set_hand_type_info(
		HandTypeEnumsClass.HandType.STRAIGHT,
		"顺子",
		"顺子至%s" % _value_to_string(data.straight_info.high_value)
	)
	# 使用最高牌的base_value
	var high_base_value = _get_base_value_for_face_value(data.cards, data.straight_info.high_value)
	result.set_core_values(high_base_value)
	result.set_cards_info(data.cards, [], data.cards)
	return result

## 🎯 三条评估器
static func _evaluate_three_kind(data: Dictionary) -> HandResultClass:
	var three_value = 0
	var kickers = []

	for value in data.value_counts:
		if data.value_counts[value] == 3:
			three_value = value
		elif data.value_counts[value] == 1:
			kickers.append(value)

	if three_value > 0:
		kickers.sort()
		kickers.reverse()  # 从大到小排序

		# 找出构成三条的卡牌（使用面值匹配）
		var contributing_cards = []
		for card in data.cards:
			if card.get_face_value() == three_value:
				contributing_cards.append(card)

		var result = HandResultClass.new()
		result.set_hand_type_info(
			HandTypeEnumsClass.HandType.THREE_KIND,
			"三条",
			"三条%s" % _value_to_string(three_value)
		)
		# 使用三条牌的base_value
		var three_base_value = _get_base_value_for_face_value(data.cards, three_value)
		result.set_core_values(three_base_value)
		result.kickers = kickers
		result.contributing_cards = contributing_cards
		return result

	return null

## 🎯 两对评估器
static func _evaluate_two_pair(data: Dictionary) -> HandResultClass:
	var pairs = []
	var kicker = 0

	for value in data.value_counts:
		if data.value_counts[value] == 2:
			pairs.append(value)
		elif data.value_counts[value] == 1:
			kicker = value

	if pairs.size() == 2:
		# 找出构成两对的卡牌（使用面值匹配）
		var contributing_cards = []
		for card in data.cards:
			if pairs.has(card.get_face_value()):
				contributing_cards.append(card)

		# 获取两对的base_value并按base_value排序（大到小）
		var pair1_base_value = _get_base_value_for_face_value(data.cards, pairs[0])
		var pair2_base_value = _get_base_value_for_face_value(data.cards, pairs[1])

		# 确保primary是较大的base_value，secondary是较小的
		var primary_face_value = pairs[0]
		var secondary_face_value = pairs[1]
		var primary_base_value = pair1_base_value
		var secondary_base_value = pair2_base_value

		if pair2_base_value > pair1_base_value:
			primary_face_value = pairs[1]
			secondary_face_value = pairs[0]
			primary_base_value = pair2_base_value
			secondary_base_value = pair1_base_value

		var result = HandResultClass.new()
		result.set_hand_type_info(
			HandTypeEnumsClass.HandType.TWO_PAIR,
			"两对",
			"两对%s和%s" % [_value_to_string(primary_face_value), _value_to_string(secondary_face_value)]
		)
		print("🔍 两对评估器: pairs=%s, primary_base_value=%d, secondary_base_value=%d" % [str(pairs), primary_base_value, secondary_base_value])
		result.set_core_values(primary_base_value, secondary_base_value)
		result.kickers = [kicker]
		result.contributing_cards = contributing_cards
		return result

	return null

## 🎯 对子评估器
static func _evaluate_pair(data: Dictionary) -> HandResultClass:
	var pair_value = 0
	var kickers = []

	for value in data.value_counts:
		if data.value_counts[value] == 2:
			pair_value = value
		elif data.value_counts[value] == 1:
			kickers.append(value)

	if pair_value > 0:
		kickers.sort()
		kickers.reverse()  # 从大到小排序

		# 找出构成对子的卡牌（使用面值匹配）
		var contributing_cards = []
		for card in data.cards:
			if card.get_face_value() == pair_value:
				contributing_cards.append(card)

		var result = HandResultClass.new()
		result.set_hand_type_info(
			HandTypeEnumsClass.HandType.PAIR,
			"对子",
			"对子%s" % _value_to_string(pair_value)
		)
		# 使用对子牌的base_value
		var pair_base_value = _get_base_value_for_face_value(data.cards, pair_value)
		result.set_core_values(pair_base_value)
		result.kickers = kickers
		result.contributing_cards = contributing_cards
		return result

	return null

## 🎯 高牌评估器
static func _evaluate_high_card(data: Dictionary) -> HandResultClass:
	# 找出最高牌（使用面值）
	var high_face_value = data.face_values[0]
	var contributing_cards = []

	# 只找第一张最高牌作为构成牌型的核心卡牌
	for card in data.cards:
		if card.get_face_value() == high_face_value:
			contributing_cards.append(card)
			break  # 只取第一张最高牌

	# 使用最高牌的base_value
	var high_base_value = contributing_cards[0].base_value if contributing_cards.size() > 0 else high_face_value

	print("PokerHandAnalyzer: 高牌评估器 - 最高牌值: %d, contributing_cards数量: %d" % [high_base_value, contributing_cards.size()])

	var result = HandResultClass.new()
	result.set_hand_type_info(
		HandTypeEnumsClass.HandType.HIGH_CARD,
		"高牌",
		"高牌%s" % _value_to_string(high_face_value)
	)
	result.set_core_values(high_base_value)
	result.kickers = data.face_values.slice(1)  # 其余4张作为踢脚牌
	result.contributing_cards = contributing_cards
	return result

## 🎯 数值转字符串
static func _value_to_string(value: int) -> String:
	match value:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(value)
