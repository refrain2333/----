class_name SmartHandAnalyzerV2
extends RefCounted

## 🎯 智能手牌分析器 V2.1
##
## 核心功能：
## - 使用新的可插拔架构进行牌型识别
## - 返回标准化的 HandResult 对象
## - 支持1-N张牌的智能分析策略

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const PokerHandAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/PokerHandAnalyzer.gd")
const HandResultClass = preload("res://cs/卡牌系统/数据/HandResult.gd")

## 🎯 智能分析N张牌的最佳牌型（主要接口）
static func find_best_hand(cards: Array) -> HandResultClass:
	if cards.is_empty():
		return HandResultClass.create_empty()
	
	var result: HandResultClass
	var combinations_tested: int = 0
	var analysis_method: String = ""
	
	if cards.size() < 5:
		# 少于5张牌：分析部分手牌
		result = _analyze_partial_hand(cards)
		combinations_tested = 1
		analysis_method = "partial"
	elif cards.size() == 5:
		# 正好5张牌：直接分析
		result = PokerHandAnalyzerClass.analyze(cards)
		combinations_tested = 1
		analysis_method = "direct"
	else:
		# 超过5张牌：找最佳组合
		var best_combination_result = _find_best_combination(cards)
		result = best_combination_result.result
		combinations_tested = best_combination_result.combinations_tested
		analysis_method = best_combination_result.method
	
	# 设置分析元数据
	if result:
		result.set_analysis_metadata(combinations_tested, analysis_method)
		print("SmartHandAnalyzerV2: 调用set_cards_info前 - contributing_cards数量: %d" % result.contributing_cards.size())
		# 只设置all_cards，保留已经正确设置的contributing_cards和kickers
		result.all_cards = cards.duplicate()
		print("SmartHandAnalyzerV2: 调用set_cards_info后 - contributing_cards数量: %d" % result.contributing_cards.size())
	
	return result

## 🔧 分析少于5张的牌
static func _analyze_partial_hand(cards: Array) -> HandResultClass:
	if cards.is_empty():
		return HandResultClass.create_empty()
	
	# 提取数值和花色
	var values = []
	var suits = []
	for card in cards:
		values.append(card.base_value)
		suits.append(card.suit)
	
	# 排序数值（从大到小）
	values.sort()
	values.reverse()
	
	# 统计数值出现次数
	var value_counts = {}
	for value in values:
		value_counts[value] = value_counts.get(value, 0) + 1
	
	# 根据卡牌数量判断牌型
	var result = HandResultClass.new()
	
	match cards.size():
		1:
			result.set_hand_type_info(
				HandTypeEnumsClass.HandType.HIGH_CARD,
				"高牌",
				"高牌: %s" % _value_to_string(values[0])
			)
			result.set_core_values(values[0])
			# 设置构成牌型的卡牌（只有最高牌）
			result.contributing_cards = [cards[0]]

		2:
			if _has_pair_in_counts(value_counts):
				var pair_value = _get_pair_value_from_counts(value_counts)
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.PAIR,
					"对子",
					"对子: %s" % _value_to_string(pair_value)
				)
				result.set_core_values(pair_value)
				# 设置构成对子的卡牌
				var pair_cards = []
				for card in cards:
					if card.base_value == pair_value:
						pair_cards.append(card)
				result.contributing_cards = pair_cards
			else:
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.HIGH_CARD,
					"高牌",
					"高牌: %s" % _value_to_string(values[0])
				)
				result.set_core_values(values[0])
				result.kickers = [values[1]]
				# 设置构成牌型的卡牌（只有最高牌）
				var high_card = null
				for card in cards:
					if card.base_value == values[0]:
						high_card = card
						break
				result.contributing_cards = [high_card] if high_card else []
		
		3:
			if _has_three_of_kind_in_counts(value_counts):
				var three_value = _get_three_of_kind_value_from_counts(value_counts)
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.THREE_KIND,
					"三条",
					"三条: %s" % _value_to_string(three_value)
				)
				result.set_core_values(three_value)
				# 设置构成三条的卡牌
				var three_cards = []
				for card in cards:
					if card.base_value == three_value:
						three_cards.append(card)
				result.contributing_cards = three_cards
			elif _has_pair_in_counts(value_counts):
				var pair_value = _get_pair_value_from_counts(value_counts)
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.PAIR,
					"对子",
					"对子: %s" % _value_to_string(pair_value)
				)
				result.set_core_values(pair_value)
				result.kickers = _get_kickers_from_counts(value_counts, [pair_value])
				# 设置构成对子的卡牌
				var pair_cards = []
				for card in cards:
					if card.base_value == pair_value:
						pair_cards.append(card)
				result.contributing_cards = pair_cards
			else:
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.HIGH_CARD,
					"高牌",
					"高牌: %s" % _value_to_string(values[0])
				)
				result.set_core_values(values[0])
				result.kickers = values.slice(1)
				# 设置构成牌型的卡牌（只有最高牌）
				var high_card = null
				for card in cards:
					if card.base_value == values[0]:
						high_card = card
						break
				result.contributing_cards = [high_card] if high_card else []
		
		4:
			if _has_four_of_kind_in_counts(value_counts):
				var four_value = _get_four_of_kind_value_from_counts(value_counts)
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.FOUR_KIND,
					"四条",
					"四条: %s" % _value_to_string(four_value)
				)
				result.set_core_values(four_value)
				result.kickers = _get_kickers_from_counts(value_counts, [four_value])
				# 设置构成四条的卡牌
				var four_cards = []
				for card in cards:
					if card.base_value == four_value:
						four_cards.append(card)
				result.contributing_cards = four_cards
			elif _has_three_of_kind_in_counts(value_counts):
				var three_value = _get_three_of_kind_value_from_counts(value_counts)
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.THREE_KIND,
					"三条",
					"三条: %s" % _value_to_string(three_value)
				)
				result.set_core_values(three_value)
				result.kickers = _get_kickers_from_counts(value_counts, [three_value])
				# 设置构成三条的卡牌
				var three_cards = []
				for card in cards:
					if card.base_value == three_value:
						three_cards.append(card)
				result.contributing_cards = three_cards
			elif _has_two_pair_in_counts(value_counts):
				var pairs = _get_pair_values_from_counts(value_counts)
				pairs.sort()
				pairs.reverse()
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.TWO_PAIR,
					"两对",
					"两对: %s和%s" % [_value_to_string(pairs[0]), _value_to_string(pairs[1])]
				)
				result.set_core_values(pairs[0], pairs[1])
				# 设置构成两对的卡牌
				var two_pair_cards = []
				for card in cards:
					if card.base_value == pairs[0] or card.base_value == pairs[1]:
						two_pair_cards.append(card)
				result.contributing_cards = two_pair_cards
			elif _has_pair_in_counts(value_counts):
				var pair_value = _get_pair_value_from_counts(value_counts)
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.PAIR,
					"对子",
					"对子: %s" % _value_to_string(pair_value)
				)
				result.set_core_values(pair_value)
				result.kickers = _get_kickers_from_counts(value_counts, [pair_value])
				# 设置构成对子的卡牌
				var pair_cards = []
				for card in cards:
					if card.base_value == pair_value:
						pair_cards.append(card)
				result.contributing_cards = pair_cards
			else:
				result.set_hand_type_info(
					HandTypeEnumsClass.HandType.HIGH_CARD,
					"高牌",
					"高牌: %s" % _value_to_string(values[0])
				)
				result.set_core_values(values[0])
				result.kickers = values.slice(1)
				# 设置构成牌型的卡牌（只有最高牌）
				var high_card = null
				for card in cards:
					if card.base_value == values[0]:
						high_card = card
						break
				result.contributing_cards = [high_card] if high_card else []

		_:
			result.set_hand_type_info(
				HandTypeEnumsClass.HandType.HIGH_CARD,
				"高牌",
				"高牌: %s" % _value_to_string(values[0])
			)
			result.set_core_values(values[0])
			result.kickers = values.slice(1)
			# 设置构成牌型的卡牌（只有最高牌）
			var high_card = null
			for card in cards:
				if card.base_value == values[0]:
					high_card = card
					break
			result.contributing_cards = [high_card] if high_card else []

	# 不要覆盖已经设置的contributing_cards
	# result.contributing_cards = cards.duplicate()  # 这行代码会覆盖之前的设置！
	return result

## 🔧 寻找最佳5张牌组合
static func _find_best_combination(cards: Array) -> Dictionary:
	var best_result: HandResultClass = null
	var combinations_tested = 0
	var method = ""
	
	# 根据卡牌数量选择策略
	if cards.size() <= 10:
		# 穷举所有组合
		var combinations = _generate_combinations(cards, 5)
		combinations_tested = combinations.size()
		method = "exhaustive"
		
		for combination in combinations:
			var result = PokerHandAnalyzerClass.analyze(combination)
			if not best_result or _is_better_hand(result, best_result):
				best_result = result
	else:
		# 使用启发式算法
		var smart_combinations = _generate_smart_combinations(cards, 5)
		combinations_tested = smart_combinations.size()
		method = "heuristic"
		
		for combination in smart_combinations:
			var result = PokerHandAnalyzerClass.analyze(combination)
			if not best_result or _is_better_hand(result, best_result):
				best_result = result
	
	if not best_result:
		best_result = HandResultClass.create_empty()
	
	return {
		"result": best_result,
		"combinations_tested": combinations_tested,
		"method": method
	}

## 🔧 生成所有可能的组合
static func _generate_combinations(cards: Array, size: int) -> Array:
	var combinations = []
	_generate_combinations_recursive(cards, [], 0, size, combinations)
	return combinations

static func _generate_combinations_recursive(cards: Array, current: Array, start: int, size: int, results: Array):
	if current.size() == size:
		results.append(current.duplicate())
		return
	
	for i in range(start, cards.size()):
		current.append(cards[i])
		_generate_combinations_recursive(cards, current, i + 1, size, results)
		current.pop_back()

## 🔧 生成智能组合（启发式）
static func _generate_smart_combinations(cards: Array, size: int) -> Array:
	# 简化版本：随机选择一些组合
	var combinations = []
	var max_combinations = min(50, _calculate_combination_count(cards.size(), size))
	
	for i in range(max_combinations):
		var combination = _select_random_combination(cards, size)
		combinations.append(combination)
	
	return combinations

static func _select_random_combination(cards: Array, size: int) -> Array:
	var shuffled = cards.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, size)

static func _calculate_combination_count(n: int, r: int) -> int:
	if r > n or r < 0:
		return 0
	if r == 0 or r == n:
		return 1
	
	var result = 1
	for i in range(min(r, n - r)):
		result = result * (n - i) / (i + 1)
	
	return result

## 🔧 比较两手牌的大小
static func _is_better_hand(hand1: HandResultClass, hand2: HandResultClass) -> bool:
	if not hand1 or not hand2:
		return hand1 != null
	
	# 首先比较牌型
	if hand1.hand_type != hand2.hand_type:
		return hand1.hand_type > hand2.hand_type
	
	# 牌型相同，比较主要数值
	if hand1.primary_value != hand2.primary_value:
		return hand1.primary_value > hand2.primary_value
	
	# 主要数值相同，比较次要数值
	if hand1.secondary_value != hand2.secondary_value:
		return hand1.secondary_value > hand2.secondary_value
	
	# 比较踢脚牌
	for i in range(min(hand1.kickers.size(), hand2.kickers.size())):
		if hand1.kickers[i] != hand2.kickers[i]:
			return hand1.kickers[i] > hand2.kickers[i]
	
	return false

## 🔧 辅助函数：检查是否有对子
static func _has_pair_in_counts(value_counts: Dictionary) -> bool:
	for count in value_counts.values():
		if count >= 2:
			return true
	return false

## 🔧 辅助函数：获取对子数值
static func _get_pair_value_from_counts(value_counts: Dictionary) -> int:
	for value in value_counts:
		if value_counts[value] >= 2:
			return value
	return 0

## 🔧 辅助函数：检查是否有三条
static func _has_three_of_kind_in_counts(value_counts: Dictionary) -> bool:
	for count in value_counts.values():
		if count >= 3:
			return true
	return false

## 🔧 辅助函数：获取三条数值
static func _get_three_of_kind_value_from_counts(value_counts: Dictionary) -> int:
	for value in value_counts:
		if value_counts[value] >= 3:
			return value
	return 0

## 🔧 辅助函数：检查是否有四条
static func _has_four_of_kind_in_counts(value_counts: Dictionary) -> bool:
	for count in value_counts.values():
		if count >= 4:
			return true
	return false

## 🔧 辅助函数：获取四条数值
static func _get_four_of_kind_value_from_counts(value_counts: Dictionary) -> int:
	for value in value_counts:
		if value_counts[value] >= 4:
			return value
	return 0

## 🔧 辅助函数：检查是否有两对
static func _has_two_pair_in_counts(value_counts: Dictionary) -> bool:
	var pair_count = 0
	for count in value_counts.values():
		if count >= 2:
			pair_count += 1
	return pair_count >= 2

## 🔧 辅助函数：获取所有对子数值
static func _get_pair_values_from_counts(value_counts: Dictionary) -> Array:
	var pairs = []
	for value in value_counts:
		if value_counts[value] >= 2:
			pairs.append(value)
	return pairs

## 🔧 辅助函数：获取踢脚牌
static func _get_kickers_from_counts(value_counts: Dictionary, exclude_values: Array) -> Array:
	var kickers = []
	for value in value_counts:
		if not exclude_values.has(value):
			for i in range(value_counts[value]):
				kickers.append(value)
	kickers.sort()
	kickers.reverse()
	return kickers

## 🔧 辅助函数：数值转字符串
static func _value_to_string(value: int) -> String:
	match value:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
		_: return str(value)
