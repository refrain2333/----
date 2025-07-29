extends Node



@onready var game_config: GameConfigResource = preload("res://assets/data/game_config.tres")
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 新接口：计算一组卡牌组合分数（入口）
static func calculate_combination_score(cards: Array) -> int:
	if cards.is_empty():
		return 0
	
	var game_config = preload("res://assets/data/game_config.tres")
	var game_manager = Engine.get_singleton("GameManager")
	
	if game_manager == null:
		push_error("ScoreCalculator: GameManager单例不可用")
		return 0
	
	# 识别牌型
	var combination_type = get_combination_type(cards)
	
	# 获取牌型字符串
	var combination_type_string = get_type_string(combination_type)

	# 获取该牌型等级
	var level = 1  # 默认等级1
	if game_manager.card_type_levels.has(combination_type_string):
		level = game_manager.card_type_levels[combination_type_string]

	# 计算基本分数
	var base_score = calculate_single_type(combination_type_string, level, game_config.card_type_base_scores,
											game_config.card_type_level_multipliers)

	# 计算附加分（来自卡牌点数和强化）
	var bonus_score = calculate_bonus_from_cards(cards)

	# 计算最终分数
	var final_score = base_score + bonus_score

	print("ScoreCalculator: 牌型=%s, 等级=%d, 基础分=%d, 附加分=%d, 最终分数=%d" %
		[combination_type_string, level, base_score, bonus_score, final_score])
	
	return final_score

# 新接口：返回单一牌型得分
static func calculate_single_type(type_name: String, level: int, base_scores: Dictionary, multipliers: Dictionary) -> int:
	# 参数校验
	if not base_scores.has(type_name):
		push_warning("ScoreCalculator: 未知牌型 " + type_name)
		return 0
		
	# 获取基础分
	var base_score = base_scores[type_name]
	
	# 获取对应等级的倍率
	var multiplier = 1.0
	if multipliers.has(type_name):
		var level_multipliers = multipliers[type_name]
		var clamped_level = clamp(level, 1, 5) - 1  # 等级范围1-5，对应索引0-4
		if clamped_level < level_multipliers.size():
			multiplier = level_multipliers[clamped_level]
	
	# 计算最终分数
	var final_score = roundi(base_score * multiplier)
	return final_score

# 从卡牌计算附加分
static func calculate_bonus_from_cards(cards: Array) -> int:
	var bonus = 0
	
	for card in cards:
		# 累加基础点数
		bonus += card.base_value
		
		# 累加蜡封加成
		if "wax_seals" in card and card.wax_seals:
			if card.wax_seals.has("RED"):
				bonus += 2  # 红色蜡封每个+2分

			if card.wax_seals.has("BLUE"):
				bonus += 3  # 蓝色蜡封每个+3分

			if card.wax_seals.has("GREEN"):
				bonus += 4  # 绿色蜡封每个+4分

			if card.wax_seals.has("GOLD"):
				bonus += 5  # 金色蜡封每个+5分
	
	return bonus

# 获取牌型字符串
static func get_type_string(combination_type: int) -> String:
	match combination_type:
		GlobalEnums.CardCombinationType.HIGH_CARD:
			return "HIGH_CARD"
		GlobalEnums.CardCombinationType.PAIR:
			return "PAIR"
		GlobalEnums.CardCombinationType.TWO_PAIR:
			return "TWO_PAIR"
		GlobalEnums.CardCombinationType.THREE_OF_KIND:
			return "THREE_OF_KIND"
		GlobalEnums.CardCombinationType.STRAIGHT:
			return "STRAIGHT"
		GlobalEnums.CardCombinationType.FLUSH:
			return "FLUSH"
		GlobalEnums.CardCombinationType.FULL_HOUSE:
			return "FULL_HOUSE"
		GlobalEnums.CardCombinationType.FOUR_OF_KIND:
			return "FOUR_OF_KIND"
		GlobalEnums.CardCombinationType.STRAIGHT_FLUSH:
			return "STRAIGHT_FLUSH"
		GlobalEnums.CardCombinationType.ROYAL_FLUSH:
			return "ROYAL_FLUSH"
	
	return "HIGH_CARD"  # 默认返回高牌

# 识别卡牌组合类型（静态方法）
static func get_combination_type(cards: Array) -> int:
	# 对牌按点数排序
	var sorted_cards = cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.base_value < b.base_value)
	
	# 检查是否同花
	var is_flush = true
	var first_suit = sorted_cards[0].suit
	for card in sorted_cards:
		if card.suit != first_suit:
			is_flush = false
			break
	
	# 检查是否顺子
	var is_straight = true
	for i in range(1, sorted_cards.size()):
		if sorted_cards[i].base_value != sorted_cards[i-1].base_value + 1:
			# 特殊情况：A-K顺子
			if i == sorted_cards.size() - 1 and sorted_cards[0].base_value == 1 and sorted_cards[i].base_value == 13:
				continue
			is_straight = false
			break
	
	# 计算每个点数的数量
	var value_counts = {}
	for card in sorted_cards:
		if value_counts.has(card.base_value):
			value_counts[card.base_value] += 1
		else:
			value_counts[card.base_value] = 1
	
	# 按数量排序
	var pairs = []
	var three_of_kind = []
	var four_of_kind = []
	
	for value in value_counts:
		var count = value_counts[value]
		if count == 4:
			four_of_kind.append(value)
		elif count == 3:
			three_of_kind.append(value)
		elif count == 2:
			pairs.append(value)
	
	# 皇家同花顺
	if is_flush and is_straight and sorted_cards[sorted_cards.size() - 1].base_value == 13 and sorted_cards[0].base_value == 1:
		return GlobalEnums.CardCombinationType.ROYAL_FLUSH
	
	# 同花顺
	if is_flush and is_straight:
		return GlobalEnums.CardCombinationType.STRAIGHT_FLUSH
	
	# 四条
	if four_of_kind.size() > 0:
		return GlobalEnums.CardCombinationType.FOUR_OF_KIND
	
	# 葫芦
	if three_of_kind.size() > 0 and pairs.size() > 0:
		return GlobalEnums.CardCombinationType.FULL_HOUSE
	
	# 同花
	if is_flush:
		return GlobalEnums.CardCombinationType.FLUSH
	
	# 顺子
	if is_straight:
		return GlobalEnums.CardCombinationType.STRAIGHT
	
	# 三条
	if three_of_kind.size() > 0:
		return GlobalEnums.CardCombinationType.THREE_OF_KIND
	
	# 两对
	if pairs.size() >= 2:
		return GlobalEnums.CardCombinationType.TWO_PAIR
	
	# 对子
	if pairs.size() == 1:
		return GlobalEnums.CardCombinationType.PAIR
	
	# 高牌
	return GlobalEnums.CardCombinationType.HIGH_CARD

# 计算一组卡牌的得分 (保留旧接口向后兼容)
func calculate_score(cards: Array[CardData], game_manager) -> int:
	if cards.is_empty():
		return 0
	
	# 检查游戏管理器
	if not game_manager:
		push_error("ScoreCalculator: 游戏管理器为空")
		return 0
		
	if not game_manager.has_method("get_card_type_level") or not game_manager.has_method("get_state_snapshot"):
		push_warning("ScoreCalculator: 游戏管理器缺少必要的方法")
	
	# 识别牌型
	var combination_type = identify_combination(cards)
	
	# 获取基础得分
	var base_score = get_base_score(combination_type, game_manager)
	
	# 计算附加分
	var bonus_score = calculate_bonus_score(cards)
	
	# 计算倍率
	var multiplier = calculate_multiplier(combination_type, cards, game_manager)
	
	# 应用效果修饰 (如果有事件管理器)
	var event_manager_node = get_node_or_null("/root/EventManager")
	if event_manager_node and event_manager_node.has_method("get_active_effects"):
		var effects = event_manager_node.get_active_effects()
		if effects.has("score_modifier"):
			base_score += effects.score_modifier
		if effects.has("score_multiplier"):
			multiplier *= effects.score_multiplier
	
	# 计算最终得分
	var final_score = roundi((base_score + bonus_score) * multiplier)
	
	# 获取牌型名称
	var global_enums = Engine.get_singleton("GlobalEnums")
	var combination_name = get_type_string(combination_type)
	if global_enums:
		combination_name = global_enums.get_combination_name(combination_type)
	
	print("ScoreCalculator: 牌型=%s, 基础分=%d, 附加分=%d, 倍率=%.2f, 最终得分=%d" % 
		[combination_name, base_score, bonus_score, multiplier, final_score])
	
	return final_score

# 识别卡牌组合类型 (保留旧接口向后兼容)
func identify_combination(cards: Array[CardData]) -> int:
	return get_combination_type(cards)

# 获取基础得分 (保留旧接口向后兼容)
func get_base_score(combination_type: int, game_manager) -> int:
	var combination_type_string = get_type_string(combination_type)

	# 检查game_manager是否有game_config属性
	if game_manager and "game_config" in game_manager and game_manager.game_config:
		return game_manager.game_config.card_type_base_scores.get(combination_type_string, 5)
	else:
		# 使用默认得分表
		var default_scores = {
			"high_card": 5,
			"pair": 10,
			"two_pair": 15,
			"three_of_a_kind": 20,
			"straight": 25,
			"flush": 30,
			"full_house": 35,
			"four_of_a_kind": 40,
			"straight_flush": 50,
			"royal_flush": 100
		}
		return default_scores.get(combination_type_string, 5)

# 计算倍率（基于牌型等级和其他加成）
func calculate_multiplier(combination_type: int, cards: Array[CardData], game_manager) -> float:
	var combination_type_string = get_type_string(combination_type)

	# 获取牌型等级
	var level = 1  # 默认等级1
	if game_manager and "card_type_levels" in game_manager and game_manager.card_type_levels.has(combination_type_string):
		level = game_manager.card_type_levels[combination_type_string]

	# 获取牌型等级倍率
	var level_multiplier = 1.0
	var default_multipliers = [1.0, 1.2, 1.4, 1.6, 1.8]
	var level_multipliers = default_multipliers

	if game_manager and "game_config" in game_manager and game_manager.game_config:
		level_multipliers = game_manager.game_config.card_type_level_multipliers.get(combination_type_string, default_multipliers)
	var clamped_level = clamp(level - 1, 0, 4)  # 等级1-5对应索引0-4
	level_multiplier = level_multipliers[clamped_level]
	
	# 基于卡牌强化的倍率
	var reinforcement_multiplier = 1.0
	
	# 检查黄金牌框
	for card in cards:
		if card.frame_type == "GOLD":
			reinforcement_multiplier *= 1.5
			print("ScoreCalculator: 检测到黄金牌框，倍率×1.5")
	
	# 获取活跃"紫色蜡封"效果
	var purple_seal_count = 0
	for card in cards:
		# 检查卡牌是否有wax_seals属性
		if "wax_seals" in card and card.wax_seals and card.wax_seals.has("PURPLE"):
			purple_seal_count += 1
	
	if purple_seal_count > 0:
		var purple_bonus = 0.2 * purple_seal_count
		reinforcement_multiplier *= (1.0 + purple_bonus)
		print("ScoreCalculator: 检测到%d个紫色蜡封，倍率额外增加%.1f" % [purple_seal_count, purple_bonus])
	
	# 检查玻璃材质
	for card in cards:
		if card.material_type == "GLASS" and randf() > 0.25:  # 不被销毁的情况
			var glass_effect = game_manager.get_node("CardManager").get_glass_material_multiplier(card)
			print("ScoreCalculator: 检测到玻璃材质，基础点数倍率×%.1f" % glass_effect)
			# 玻璃材质效果在基础点数上体现，不在这里计算
	
	# 游戏管理器中的其他倍率效果
	var other_multipliers = 1.0
	if game_manager.has_method("get_score_multiplier"):
		other_multipliers = game_manager.get_score_multiplier()
	
	# 返回组合倍率
	var final_multiplier = level_multiplier * reinforcement_multiplier * other_multipliers
	
	return final_multiplier

# 计算附加分（基于卡牌点数总和、蜡封等）(保留旧接口向后兼容)
func calculate_bonus_score(cards: Array[CardData]) -> int:
	var bonus = 0
	
	# 卡牌点数总和
	for card in cards:
		bonus += card.base_value
	
	# 计算蜡封加成
	var seal_bonus = 0
	var seal_types = {
		"RED": {"bonus": 10, "desc": "红色蜡封"},
		"GOLD": {"bonus": 15, "desc": "金色蜡封"},
		"BLUE": {"bonus": 8, "desc": "蓝色蜡封"},
		"GREEN": {"bonus": 12, "desc": "绿色蜡封"},
		"ORANGE": {"bonus": 7, "desc": "橙色蜡封"},
		"PURPLE": {"bonus": 9, "desc": "紫色蜡封"},
		"BROWN": {"bonus": 6, "desc": "棕色蜡封"},
		"WHITE": {"bonus": 11, "desc": "白色蜡封"}
	}
	
	for card in cards:
		# 检查卡牌是否有wax_seals属性
		if "wax_seals" in card and card.wax_seals:
			for seal in card.wax_seals:
				if seal_types.has(seal):
					seal_bonus += seal_types[seal].bonus
					print("ScoreCalculator: 检测到%s，+%d分" % [seal_types[seal].desc, seal_types[seal].bonus])
	
	bonus += seal_bonus
	
	# 计算牌框加成
	var frame_bonus = 0
	var frame_types = {
		"STONE": {"bonus": 5, "desc": "石质牌框"},
		"SILVER": {"bonus": 10, "desc": "银质牌框"},
		"GOLD": {"bonus": 15, "desc": "金质牌框"}
	}
	
	for card in cards:
		if card.frame_type and frame_types.has(card.frame_type):
			frame_bonus += frame_types[card.frame_type].bonus
			print("ScoreCalculator: 检测到%s，+%d分" % 
				[frame_types[card.frame_type].desc, frame_types[card.frame_type].bonus])
	
	bonus += frame_bonus
	
	# 计算材质加成
	var material_bonus = 0
	var material_types = {
		"GLASS": {"bonus": 8, "desc": "玻璃材质"},
		"ROCK": {"bonus": 7, "desc": "岩石材质"},
		"METAL": {"bonus": 12, "desc": "金属材质"}
	}
	
	for card in cards:
		if card.material_type and material_types.has(card.material_type):
			material_bonus += material_types[card.material_type].bonus
			print("ScoreCalculator: 检测到%s，+%d分" % 
				[material_types[card.material_type].desc, material_types[card.material_type].bonus])
	
	bonus += material_bonus
	
	return bonus

# 计算一组卡牌的最佳理论得分（用于奥术直觉）
func calculate_theoretical_best_score(cards: Array[CardData], game_manager) -> int:
	# 如果没有牌，无法计算
	if cards.is_empty():
		return 0
	
	# 复制卡牌用于模拟
	var card_copies = cards.duplicate()
	
	# 尝试所有可能的组合，找出最高分
	var best_score = 0
	var max_cards_to_play = min(5, card_copies.size()) # 最多出5张牌
	
	# 从1张到max_cards_to_play张的所有可能性
	for num_cards in range(1, max_cards_to_play + 1):
		var combinations = generate_combinations(card_copies, num_cards)
		
		for combo in combinations:
			var score = calculate_score(combo, game_manager)
			if score > best_score:
				best_score = score
	
	return best_score

# 生成所有可能的卡牌组合
func generate_combinations(cards: Array, k: int) -> Array:
	var result = []
	_generate_combinations_helper(cards, k, 0, [], result)
	return result

# 组合生成的辅助函数
func _generate_combinations_helper(cards: Array, k: int, start: int, current: Array, result: Array) -> void:
	if current.size() == k:
		result.append(current.duplicate())
		return
	
	for i in range(start, cards.size()):
		current.append(cards[i])
		_generate_combinations_helper(cards, k, i + 1, current, result)
		current.pop_back() 

# 为了测试和调试的方法，输出卡牌的强化信息
static func print_card_reinforcements(cards: Array) -> void:
	var wax_seals = {}
	var frames = {}
	var materials = {}
	
	for card in cards:
		if not card is CardData:
			continue
		
		# 统计蜡封
		if "wax_seals" in card and card.wax_seals:
			for seal in card.wax_seals:
				if wax_seals.has(seal):
					wax_seals[seal] += 1
				else:
					wax_seals[seal] = 1
		
		# 统计牌框
		if card.frame_type and not card.frame_type.is_empty():
			if frames.has(card.frame_type):
				frames[card.frame_type] += 1
			else:
				frames[card.frame_type] = 1
		
		# 统计材质
		if card.material_type and not card.material_type.is_empty():
			if materials.has(card.material_type):
				materials[card.material_type] += 1
			else:
				materials[card.material_type] = 1
	
	# 输出统计结果
	var output = "卡牌强化统计:\n"
	
	if not wax_seals.is_empty():
		output += "蜡封: "
		for seal in wax_seals:
			output += "%s(%d) " % [seal, wax_seals[seal]]
		output += "\n"
	
	if not frames.is_empty():
		output += "牌框: "
		for frame in frames:
			output += "%s(%d) " % [frame, frames[frame]]
		output += "\n"
	
	if not materials.is_empty():
		output += "材质: "
		for material in materials:
			output += "%s(%d) " % [material, materials[material]]
		output += "\n"
	
	print(output) 
