class_name SmartHandAnalyzer
extends RefCounted

## 🧠 智能多张牌最佳组合分析器
## 
## 核心功能：
## - 支持1-13张任意数量卡牌的牌型识别
## - 智能组合算法：从N张卡牌中找出最佳5张组合
## - 性能优化：大量卡牌时使用启发式算法
## - 遵循项目架构规范，放置在管理器目录

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")
const HandTypeAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeAnalyzer.gd")
const HandTypeRankingManagerClass = preload("res://cs/卡牌系统/数据/管理器/HandTypeRankingManager.gd")
const PokerHandAnalyzerClass = preload("res://cs/卡牌系统/数据/管理器/PokerHandAnalyzer.gd")
const HandResultClass = preload("res://cs/卡牌系统/数据/HandResult.gd")

## 🎯 智能分析入口
static func find_best_hand(cards: Array) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	if cards.is_empty():
		return _create_empty_result()
	
	var result: Dictionary
	var combinations_tested = 0
	
	# 根据卡牌数量选择分析策略
	if cards.size() < 5:
		# 少于5张牌：分析现有牌型
		result = _analyze_partial_hand(cards)
		combinations_tested = 1
	elif cards.size() == 5:
		# 正好5张牌：直接分析
		result = HandTypeAnalyzerClass.analyze_hand(cards)
		combinations_tested = 1
	else:
		# 超过5张牌：找出最佳5张组合
		var analysis_result = _find_best_combination(cards)
		result = analysis_result.result
		combinations_tested = analysis_result.combinations_tested
	
	var end_time = Time.get_ticks_msec()
	var analysis_time = end_time - start_time
	
	# 添加智能分析特有的信息
	result.best_hand_cards = result.get("cards", [])
	result.discarded_cards = _get_discarded_cards(cards, result.best_hand_cards)
	result.analysis_time = analysis_time
	result.combinations_tested = combinations_tested
	result.total_cards = cards.size()
	
	return result

## 🔧 分析少于5张的牌
static func _analyze_partial_hand(cards: Array) -> Dictionary:
	if cards.is_empty():
		return _create_empty_result()
	
	# 提取数值进行分析
	var values = []
	for card in cards:
		values.append(card.base_value)
	
	var value_counts = {}
	for value in values:
		value_counts[value] = value_counts.get(value, 0) + 1
	
	# 按卡牌数量分析
	var hand_type: int
	var description: String
	var primary_value: int = 0
	
	match cards.size():
		1:
			hand_type = HandTypeEnumsClass.HandType.HIGH_CARD
			primary_value = values[0]
			description = "高牌: %s" % _value_to_string(primary_value)

		2:
			if _has_pair_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.PAIR
				primary_value = _get_pair_value_from_counts(value_counts)
				description = "对子: %s" % _value_to_string(primary_value)
			else:
				hand_type = HandTypeEnumsClass.HandType.HIGH_CARD
				primary_value = values.max()
				description = "高牌: %s" % _value_to_string(primary_value)
		
		3:
			if _has_three_of_kind_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.THREE_KIND
				primary_value = _get_three_of_kind_value_from_counts(value_counts)
				description = "三条: %s" % _value_to_string(primary_value)
			elif _has_pair_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.PAIR
				primary_value = _get_pair_value_from_counts(value_counts)
				description = "对子: %s" % _value_to_string(primary_value)
			else:
				hand_type = HandTypeEnumsClass.HandType.HIGH_CARD
				primary_value = values.max()
				description = "高牌: %s" % _value_to_string(primary_value)
		
		4:
			if _has_four_of_kind_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.FOUR_KIND
				primary_value = _get_four_of_kind_value_from_counts(value_counts)
				description = "四条: %s" % _value_to_string(primary_value)
			elif _has_three_of_kind_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.THREE_KIND
				primary_value = _get_three_of_kind_value_from_counts(value_counts)
				description = "三条: %s" % _value_to_string(primary_value)
			elif _has_two_pair_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.TWO_PAIR
				var pairs = _get_pair_values_from_counts(value_counts)
				primary_value = max(pairs[0], pairs[1])
				description = "两对: %s和%s" % [_value_to_string(pairs[0]), _value_to_string(pairs[1])]
			elif _has_pair_in_counts(value_counts):
				hand_type = HandTypeEnumsClass.HandType.PAIR
				primary_value = _get_pair_value_from_counts(value_counts)
				description = "对子: %s" % _value_to_string(primary_value)
			else:
				hand_type = HandTypeEnumsClass.HandType.HIGH_CARD
				primary_value = values.max()
				description = "高牌: %s" % _value_to_string(primary_value)
		
		_:
			hand_type = HandTypeEnumsClass.HandType.HIGH_CARD
			primary_value = values.max()
			description = "高牌: %s" % _value_to_string(primary_value)

	return {
		"hand_type": hand_type,
		"hand_type_name": HandTypeEnumsClass.HAND_TYPE_NAMES[hand_type],
		"description": description,
		"primary_value": primary_value,
		"secondary_value": 0,
		"kickers": [],
		"cards": cards,
		"base_score": HandTypeEnumsClass.BASE_SCORES[hand_type]
	}

## 🔧 找出最佳5张组合
static func _find_best_combination(cards: Array) -> Dictionary:
	var best_result = null
	var combinations_tested = 0
	
	if cards.size() <= 10:
		# 穷举所有组合
		var combinations = _generate_combinations(cards, 5)
		combinations_tested = combinations.size()
		
		for combination in combinations:
			var result = HandTypeAnalyzerClass.analyze_hand(combination)
			if not best_result or _is_better_hand(result, best_result):
				best_result = result
	else:
		# 使用启发式算法
		var smart_combinations = _generate_smart_combinations(cards, 5)
		combinations_tested = smart_combinations.size()

		for combination in smart_combinations:
			var result = HandTypeAnalyzerClass.analyze_hand(combination)
			if not best_result or _is_better_hand(result, best_result):
				best_result = result
	
	return {
		"result": best_result if best_result else _create_empty_result(),
		"combinations_tested": combinations_tested
	}

## 🔧 生成所有组合（穷举法）
static func _generate_combinations(cards: Array, k: int) -> Array:
	var combinations = []
	_generate_combinations_recursive(cards, k, 0, [], combinations)
	return combinations

static func _generate_combinations_recursive(cards: Array, k: int, start: int, current: Array, result: Array):
	if current.size() == k:
		result.append(current.duplicate())
		return
	
	for i in range(start, cards.size()):
		current.append(cards[i])
		_generate_combinations_recursive(cards, k, i + 1, current, result)
		current.pop_back()

## 🔧 生成智能组合（启发式算法）
static func _generate_smart_combinations(cards: Array, k: int) -> Array:
	# 优先选择策略：
	# 1. 相同数值的卡牌
	# 2. 相同花色的卡牌
	# 3. 连续数值的卡牌
	# 4. 高价值卡牌
	
	var combinations = []
	var max_combinations = 50  # 限制组合数量以提高性能
	
	# 按价值排序
	var sorted_cards = cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.base_value > b.base_value)
	
	# 生成基于高价值的组合
	var high_value_combinations = _generate_combinations(sorted_cards.slice(0, min(8, sorted_cards.size())), k)
	combinations.append_array(high_value_combinations.slice(0, max_combinations / 2))
	
	# 生成基于相同数值的组合
	var value_groups = _group_by_value(cards)
	for value in value_groups:
		if value_groups[value].size() >= 2:
			var remaining_cards = []
			for card in cards:
				if card.base_value != value:
					remaining_cards.append(card)
			
			if remaining_cards.size() >= k - value_groups[value].size():
				var base_cards = value_groups[value].slice(0, min(value_groups[value].size(), k))
				var needed = k - base_cards.size()
				if needed > 0:
					var fill_combinations = _generate_combinations(remaining_cards, needed)
					for fill_combo in fill_combinations.slice(0, 5):  # 限制数量
						var combo = base_cards.duplicate()
						combo.append_array(fill_combo)
						if combo.size() == k:
							combinations.append(combo)
	
	# 去重并限制数量
	var unique_combinations = []
	for combo in combinations:
		if unique_combinations.size() >= max_combinations:
			break
		if not _has_duplicate_combination(unique_combinations, combo):
			unique_combinations.append(combo)
	
	return unique_combinations

## 🔧 按数值分组
static func _group_by_value(cards: Array) -> Dictionary:
	var groups = {}
	for card in cards:
		var value = card.base_value
		if not groups.has(value):
			groups[value] = []
		groups[value].append(card)
	return groups

## 🔧 检查重复组合
static func _has_duplicate_combination(combinations: Array, new_combo: Array) -> bool:
	for existing_combo in combinations:
		if _are_same_combination(existing_combo, new_combo):
			return true
	return false

static func _are_same_combination(combo1: Array, combo2: Array) -> bool:
	if combo1.size() != combo2.size():
		return false
	
	var values1 = []
	var values2 = []
	for card in combo1:
		values1.append(card.base_value)
	for card in combo2:
		values2.append(card.base_value)
	
	values1.sort()
	values2.sort()
	
	return values1 == values2

## 🔧 比较牌型优劣
static func _is_better_hand(hand1: Dictionary, hand2: Dictionary) -> bool:
	return HandTypeRankingManager.compare_hands(hand1, hand2) > 0

## 🔧 获取弃置的卡牌
static func _get_discarded_cards(all_cards: Array, best_cards: Array) -> Array:
	var discarded = []
	for card in all_cards:
		if not best_cards.has(card):
			discarded.append(card)
	return discarded

## 🔧 辅助函数：检测函数
static func _has_pair_in_counts(counts: Dictionary) -> bool:
	for count in counts.values():
		if count >= 2:
			return true
	return false

static func _has_two_pair_in_counts(counts: Dictionary) -> bool:
	var pair_count = 0
	for count in counts.values():
		if count == 2:
			pair_count += 1
	return pair_count >= 2

static func _has_three_of_kind_in_counts(counts: Dictionary) -> bool:
	for count in counts.values():
		if count >= 3:
			return true
	return false

static func _has_four_of_kind_in_counts(counts: Dictionary) -> bool:
	for count in counts.values():
		if count >= 4:
			return true
	return false

static func _get_pair_value_from_counts(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] >= 2:
			return value
	return 0

static func _get_pair_values_from_counts(counts: Dictionary) -> Array:
	var pairs = []
	for value in counts:
		if counts[value] == 2:
			pairs.append(value)
	return pairs

static func _get_three_of_kind_value_from_counts(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] >= 3:
			return value
	return 0

static func _get_four_of_kind_value_from_counts(counts: Dictionary) -> int:
	for value in counts:
		if counts[value] >= 4:
			return value
	return 0

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
		"hand_type": HandTypeEnumsClass.HandType.HIGH_CARD,
		"hand_type_name": "无牌",
		"description": "无有效卡牌",
		"primary_value": 0,
		"secondary_value": 0,
		"kickers": [],
		"cards": [],
		"base_score": 0,
		"best_hand_cards": [],
		"discarded_cards": [],
		"analysis_time": 0,
		"combinations_tested": 0,
		"total_cards": 0
	}
