extends Node

# GameManager单例 - 全局变量和状态管理器

# 游戏核心数据常量
const INITIAL_FOCUS: int = 5      # 初始集中力值
const INITIAL_ESSENCE: int = 3    # 初始精华值
const INITIAL_MANA: int = 0       # 初始学识魔力值
const INITIAL_LORE_POINTS: int = 4  # 初始学识点值
const MIN_RUNE_COST: int = 1      # 最小符文费用
const MAX_RUNE_COST: int = 8      # 最大符文费用
const MAX_HAND_SIZE: int = 5      # 最大手牌数量
const INITIAL_HAND_SIZE: int = 5  # 初始手牌数量
const VICTORY_SCORE: int = 50     # 胜利分数要求
const MAX_FOCUS: int = 5          # 最大集中力值
const MAX_ESSENCE: int = 3        # 最大精华值

# 游戏进度相关
var current_level: int = 1        # 当前关卡
var is_tutorial_completed: bool = false  # 是否完成教程

# 游戏状态变量
var current_mana: int = INITIAL_MANA  # 当前学识魔力
var target_mana: int = 300            # 目标学识魔力
var focus_count: int = INITIAL_FOCUS  # 剩余集中力
var essence_count: int = INITIAL_ESSENCE  # 剩余精华
var lore_points: int = INITIAL_LORE_POINTS  # 学识点
var rune_cost: int = MIN_RUNE_COST    # 符文费用
var max_cost: int = MAX_RUNE_COST     # 最大符文费用
var current_turn: int = 1             # 当前回合数
var base_score: int = 50              # 当前出牌基础分数
var score_multiplier: int = 1         # 当前出牌倍数
var score: int = 0                    # 当前总分数

# 符文库相关
var total_runes: int = 52             # 符文库总数
var remaining_runes: int = 52         # 符文库剩余数量
var all_runes: Array = []             # 所有符文数据
var current_hand: Array = []          # 当前手牌
var cast_runes: Array = []            # 已施放的符文
var discarded_runes: Array = []       # 已弃置的符文

# 小丑卡相关
var active_jokers: Array = []         # 激活的小丑卡
var max_jokers: int = 5               # 最大小丑卡数量
var joker_pool: Array = []            # 小丑卡池
var joker_offer_count: int = 3        # 每次提供的小丑卡数量

# 卡牌组合类型及得分
var combo_types = {
	"high_card": {"name": "高能符文", "base_multiplier": 1},
	"pair": {"name": "双生符文", "base_multiplier": 2},
	"two_pairs": {"name": "双重双生", "base_multiplier": 3},
	"three_kind": {"name": "三元共振", "base_multiplier": 4},
	"straight": {"name": "符文连锁", "base_multiplier": 5},
	"flush": {"name": "元素灌注", "base_multiplier": 6},
	"full_house": {"name": "元素归一", "base_multiplier": 7},
	"four_kind": {"name": "四元共振", "base_multiplier": 8},
	"straight_flush": {"name": "元素风暴", "base_multiplier": 10},
	"royal_flush": {"name": "奥术完美", "base_multiplier": 15}
}

# 魔法发现与传奇法器
var discovery_cards: Array = []       # 魔法发现卡牌
var artifacts: Array = []             # 传奇法器
var max_discoveries: int = 3          # 最大魔法发现数量
var max_artifacts: int = 6            # 最大传奇法器数量

# 元素系统相关（可扩展）
var elements = ["fire", "water", "earth", "air", "arcane"]
var element_counters = {
	"fire": "water",
	"water": "earth",
	"earth": "air",
	"air": "fire",
	"arcane": ""  # 奥术没有克制关系
}

# 解锁内容管理
var unlocked_elements: Array = ["arcane"]  # 初始只解锁奥术元素
var unlocked_artifacts: Array = []         # 已解锁的传奇法器
var unlocked_spells: Array = []            # 已解锁的法术

# 玩家进度存档
var player_stats = {
	"total_mana_earned": 0,
	"total_games_played": 0,
	"max_score": 0,
	"artifacts_found": 0
}

# 信号 - 用于通知游戏状态变化
signal mana_changed(new_value)
signal focus_changed(new_value)
signal essence_changed(new_value)
signal lore_points_changed(new_value)
signal turn_changed(new_turn)
signal rune_cost_changed(new_cost)
signal artifact_added(artifact_data)
signal discovery_added(card_data)
signal card_drawn(card_data)
signal hand_updated()
signal rune_library_updated()
signal deck_size_changed(remaining, total)
signal joker_added(joker_data)
signal joker_removed(joker_data)
signal joker_effect_applied(joker_data)
signal score_changed(new_score)
signal game_won()
signal resources_changed(focus_count, essence_count, remaining_runes)

func _ready():
	# 初始化游戏状态
	reset_game_state()
	# 初始化小丑卡池
	initialize_joker_pool()
	
	# 确保符文库已初始化
	if all_runes.size() == 0:
		initialize_rune_library()
	
	print("GameManager单例已初始化")

# 重置游戏状态到初始值
func reset_game_state():
	# 重置所有状态变量为初始值
	current_mana = INITIAL_MANA
	focus_count = INITIAL_FOCUS
	essence_count = INITIAL_ESSENCE
	lore_points = INITIAL_LORE_POINTS
	rune_cost = MIN_RUNE_COST
	remaining_runes = total_runes
	current_turn = 1
	base_score = 50
	score_multiplier = 1
	score = 0
	
	# 清空卡牌相关数组
	current_hand.clear()
	cast_runes.clear()
	discovery_cards.clear()
	artifacts.clear()
	discarded_runes.clear()
	
	# 初始化卡牌库并洗牌
	initialize_rune_library()
	
	# 清空小丑卡数组
	active_jokers.clear()
	
	# 发出信号通知UI更新
	emit_signal("mana_changed", current_mana)
	emit_signal("focus_changed", focus_count)
	emit_signal("essence_changed", essence_count)
	emit_signal("lore_points_changed", lore_points)
	emit_signal("turn_changed", current_turn)
	emit_signal("rune_cost_changed", rune_cost)
	emit_signal("rune_library_updated")

# 更新学识魔力
func add_mana(value: int):
	current_mana += value
	player_stats.total_mana_earned += value
	emit_signal("mana_changed", current_mana)
	
	# 更新最高分记录
	if current_mana > player_stats.max_score:
		player_stats.max_score = current_mana
	
	# 返回是否达到目标
	return current_mana >= target_mana

# 更新集中力
func set_focus(value: int):
	focus_count = value
	if focus_count < 0:
		focus_count = 0
	emit_signal("focus_changed", focus_count)
	return focus_count

# 更新精华
func set_essence(value: int):
	essence_count = value
	if essence_count < 0:
		essence_count = 0
	emit_signal("essence_changed", essence_count)
	return essence_count

# 增加回合数
func next_turn():
	current_turn += 1
	emit_signal("turn_changed", current_turn)
	return current_turn

# 设置符文费用
func set_rune_cost(value: int):
	if value < MIN_RUNE_COST:
		rune_cost = MIN_RUNE_COST
	elif value > max_cost:
		rune_cost = max_cost
	else:
		rune_cost = value
	emit_signal("rune_cost_changed", rune_cost)
	return rune_cost

# 添加魔法发现卡牌
func add_discovery(card_data):
	if discovery_cards.size() >= max_discoveries:
		return false
	discovery_cards.append(card_data)
	emit_signal("discovery_added", card_data)
	return true

# 添加传奇法器
func add_artifact(artifact_data):
	if artifacts.size() >= max_artifacts:
		return false
	artifacts.append(artifact_data)
	player_stats.artifacts_found += 1
	emit_signal("artifact_added", artifact_data)
	return true

# 计算分数
func calculate_score(base: int, multiplier: int) -> int:
	var total = base * multiplier
	base_score = base
	score_multiplier = multiplier
	return total

# 初始化符文库（洗牌）
func initialize_rune_library():
	all_runes.clear()
	
	# 创建52张卡牌
	for id in range(1, 53):
		var card = CardData.new(id)
		all_runes.append(card)
	
	# 洗牌
	shuffle_rune_library()
	
	# 重置剩余符文数量
	remaining_runes = all_runes.size()
	emit_signal("rune_library_updated")
	emit_signal("deck_size_changed", remaining_runes, total_runes)
	
	print("符文库已初始化，共%d张符文" % all_runes.size())

# 洗牌
func shuffle_rune_library():
	# 随机打乱卡牌顺序
	randomize()  # 确保真正的随机性
	all_runes.shuffle()
	emit_signal("deck_size_changed", all_runes.size(), total_runes)
	print("符文库已洗牌，共%d张符文" % all_runes.size())
	
	# 输出前几张牌的信息用于调试
	var debug_count = min(5, all_runes.size())
	print("洗牌后前%d张符文:" % debug_count)
	for i in range(debug_count):
		var card = all_runes[i]
		print("  #%d: %s (%s, 能量值: %d)" % [i+1, card.name, card.element, card.power])

# 从符文库抽取一张符文
func draw_rune() -> CardData:
	if remaining_runes <= 0:
		print("符文库已空，无法抽取")
		return null
	
	if all_runes.size() == 0:
		print("符文库未初始化，尝试初始化")
		initialize_rune_library()
		if all_runes.size() == 0:
			print("符文库初始化失败")
			return null
	
	# 计算要抽取的卡牌索引
	var index = all_runes.size() - remaining_runes
	if index < 0 or index >= all_runes.size():
		print("错误：抽牌索引超出范围 index=%d, size=%d" % [index, all_runes.size()])
		return null
		
	var card = all_runes[index]
	remaining_runes -= 1
	emit_signal("card_drawn", card)
	emit_signal("deck_size_changed", remaining_runes, total_runes)
	emit_signal("rune_library_updated")
	
	print("抽取了符文: " + card.name)
	return card

# 添加卡牌到手牌
func add_card_to_hand(card: CardData) -> bool:
	# 检查手牌上限
	if current_hand.size() >= MAX_HAND_SIZE:
		print("手牌已满，无法添加更多符文")
		return false
	
	# 添加到手牌
	current_hand.append(card)
	emit_signal("hand_updated")
	
	print("符文已添加到手牌: " + card.name)
	return true

# 移除手牌中的卡牌
func remove_card_from_hand(card: CardData):
	var index = current_hand.find(card)
	if index != -1:
		current_hand.remove_at(index)
		emit_signal("hand_updated")
		print("符文已从手牌移除: " + card.name)

# 检查手牌是否已满
func is_hand_full() -> bool:
	return current_hand.size() >= MAX_HAND_SIZE

# 发起始手牌
func deal_initial_hand():
	# 清空当前手牌
	current_hand.clear()
	
	print("准备发放%d张初始手牌..." % INITIAL_HAND_SIZE)
	
	# 确保符文库已初始化
	if all_runes.size() == 0 or remaining_runes == 0:
		print("符文库为空，重新初始化...")
		initialize_rune_library()
	
	# 确保remaining_runes正确设置
	if remaining_runes != all_runes.size():
		remaining_runes = all_runes.size()
		print("修正remaining_runes为%d" % remaining_runes)
	
	# 抽取指定数量的起始手牌
	for i in range(INITIAL_HAND_SIZE):
		var card = draw_rune()
		if card:
			add_card_to_hand(card)
			print("初始手牌 #%d: %s" % [i+1, card.name])
		else:
			print("警告：无法抽取初始手牌 #%d" % [i+1])
	
	print("已发放初始手牌，共%d张" % current_hand.size())

# 施放手牌中的一张符文
func cast_rune(card: CardData) -> bool:
	# 检查是否有足够的集中力
	if focus_count <= 0:
		print("集中力不足，无法施放符文")
		return false
	
	# 从手牌移除
	remove_card_from_hand(card)
	
	# 添加到已施放的符文
	cast_runes.append(card)
	
	# 消耗集中力
	set_focus(focus_count - 1)
	
	print("施放了符文: " + card.name)
	return true

# 弃置手牌中的一张符文
func discard_rune(card: CardData) -> bool:
	# 检查是否有足够的精华
	if essence_count <= 0:
		print("精华不足，无法弃置符文")
		return false
	
	# 从手牌移除
	remove_card_from_hand(card)
	
	# 添加到已弃置的符文
	discarded_runes.append(card)
	
	# 消耗精华
	set_essence(essence_count - 1)
	
	# 恢复集中力
	set_focus(INITIAL_FOCUS)
	
	print("弃置了符文: " + card.name + "，恢复了集中力")
	return true

# 判断符文组合类型并计算得分
func evaluate_rune_combination(runes: Array) -> Dictionary:
	# 保存原始值
	var original_base_score = base_score
	var original_multiplier = score_multiplier
	
	# 应用小丑卡效果（评分前）
	apply_joker_effects("card_evaluation")
	
	# 至少需要1张牌
	if runes.size() < 1:
		return {"type": "none", "name": "无效组合", "multiplier": 0, "base_score": 0}
	
	var result = {"type": "high_card", "name": combo_types.high_card.name, "multiplier": combo_types.high_card.base_multiplier}
	
	# 检查是否有对子、三条、四条等
	var value_counts = {}
	for card in runes:
		if not value_counts.has(card.value):
			value_counts[card.value] = 0
		value_counts[card.value] += 1
	
	var pairs = 0
	var three_kind = false
	var four_kind = false
	
	for value in value_counts:
		if value_counts[value] == 2:
			pairs += 1
		elif value_counts[value] == 3:
			three_kind = true
		elif value_counts[value] == 4:
			four_kind = true
	
	# 检查是否同花
	var is_flush = CardData.is_flush(runes)
	
	# 检查是否顺子
	var is_straight = CardData.is_straight(runes)
	
	# 判断牌型
	if is_straight and is_flush:
		# 检查是否皇家同花顺(10-A同花)
		var has_ten = false
		var has_ace = false
		for card in runes:
			if card.value == 10:
				has_ten = true
			elif card.value == 1:  # A
				has_ace = true
		
		if has_ten and has_ace and runes.size() >= 5:
			result.type = "royal_flush"
			result.name = combo_types.royal_flush.name
			result.multiplier = combo_types.royal_flush.base_multiplier
		else:
			result.type = "straight_flush"
			result.name = combo_types.straight_flush.name
			result.multiplier = combo_types.straight_flush.base_multiplier
	elif four_kind:
		result.type = "four_kind"
		result.name = combo_types.four_kind.name
		result.multiplier = combo_types.four_kind.base_multiplier
	elif three_kind and pairs > 0:
		result.type = "full_house"
		result.name = combo_types.full_house.name
		result.multiplier = combo_types.full_house.base_multiplier
	elif is_flush:
		result.type = "flush"
		result.name = combo_types.flush.name
		result.multiplier = combo_types.flush.base_multiplier
	elif is_straight:
		result.type = "straight"
		result.name = combo_types.straight.name
		result.multiplier = combo_types.straight.base_multiplier
	elif three_kind:
		result.type = "three_kind"
		result.name = combo_types.three_kind.name
		result.multiplier = combo_types.three_kind.base_multiplier
	elif pairs == 2:
		result.type = "two_pairs"
		result.name = combo_types.two_pairs.name
		result.multiplier = combo_types.two_pairs.base_multiplier
	elif pairs == 1:
		result.type = "pair"
		result.name = combo_types.pair.name
		result.multiplier = combo_types.pair.base_multiplier
	
	# 计算基础分数（所有卡牌能量值总和 × 符文费用）
	var calc_base_score = CardData.calculate_total_power(runes) * rune_cost
	result.base_score = calc_base_score
	
	# 符文数量加成
	var count_bonus = 1.0 + (runes.size() - 1) * 0.1  # 每多一张牌，倍数+0.1
	result.multiplier = int(result.multiplier * count_bonus)
	
	# 应用小丑卡效果（特定牌型）
	if result.type == "pair" or result.type == "two_pairs":
		apply_joker_effects("pair_combination")
	
	if result.type == "straight" or result.type == "straight_flush" or result.type == "royal_flush":
		apply_joker_effects("straight_combination")
	
	# 应用小丑卡效果（评分后）
	apply_joker_effects("score_calculation")
	
	# 应用小丑卡的修改
	result.base_score = calc_base_score  # 使用可能被小丑卡修改过的基础分数
	result.multiplier = result.multiplier * score_multiplier  # 应用小丑卡倍数效果
	
	# 恢复原始值（为下次评估准备）
	base_score = original_base_score
	score_multiplier = original_multiplier
	
	print("符文组合评估: " + result.name + ", 基础分数: " + str(result.base_score) + ", 倍数: " + str(result.multiplier))
	return result

# 保存游戏进度
func save_game():
	var save_data = {
		"player_stats": player_stats,
		"unlocked_elements": unlocked_elements,
		"unlocked_artifacts": unlocked_artifacts,
		"unlocked_spells": unlocked_spells,
		"current_level": current_level,
		"is_tutorial_completed": is_tutorial_completed
	}
	
	# 这里可以添加实际的存档逻辑
	# 例如: var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	
	print("游戏进度已保存")
	return save_data

# 加载游戏进度
func load_game():
	# 这里可以添加实际的读档逻辑
	# 例如: var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
	
	# 暂时返回默认值
	print("游戏进度已加载")
	return true 

# 初始化小丑卡池
func initialize_joker_pool():
	joker_pool.clear()
	
	# 添加所有可能的小丑卡到池中
	joker_pool.append("common_joker")
	joker_pool.append("wrathful_joker")
	joker_pool.append("greedy_joker")
	joker_pool.append("lusty_joker")
	joker_pool.append("gluttonous_joker")
	joker_pool.append("the_duo")
	joker_pool.append("the_order")
	joker_pool.append("yorick")
	joker_pool.append("bootstraps")
	joker_pool.append("square_joker")
	joker_pool.append("odd_todd")
	joker_pool.append("even_steven")
	joker_pool.append("hiker")
	joker_pool.append("bull")
	joker_pool.append("spare_trousers")
	
	# 随机打乱小丑卡池
	joker_pool.shuffle()
	
	print("小丑卡池已初始化，共%d张小丑卡" % joker_pool.size())

# 提供小丑卡选择
func offer_jokers() -> Array:
	var offered_jokers = []
	var offer_count = min(joker_offer_count, joker_pool.size())
	
	for i in range(offer_count):
		if joker_pool.size() > 0:
			var joker_name = joker_pool.pop_front()
			var joker_data = JokerData.create_joker(joker_name)
			offered_jokers.append(joker_data)
	
	return offered_jokers

# 添加小丑卡到激活区
func add_joker(joker_data) -> bool:
	if active_jokers.size() >= max_jokers:
		print("小丑卡数量已达上限")
		return false
	
	active_jokers.append(joker_data)
	emit_signal("joker_added", joker_data)
	
	print("已添加小丑卡: " + joker_data.name)
	return true

# 移除小丑卡
func remove_joker(joker_data) -> bool:
	var index = active_jokers.find(joker_data)
	if index != -1:
		active_jokers.remove_at(index)
		emit_signal("joker_removed", joker_data)
		print("已移除小丑卡: " + joker_data.name)
		return true
	
	print("未找到要移除的小丑卡")
	return false

# 应用所有小丑卡效果
func apply_joker_effects(context: String = ""):
	for joker in active_jokers:
		# 可以传入上下文，以便小丑卡根据不同情况执行不同效果
		apply_joker_effect(joker, context)

# 应用单个小丑卡效果
func apply_joker_effect(joker_data, context: String = ""):
	# 根据不同的效果类型和上下文应用效果
	var effect_applied = false
	
	match joker_data.effect_type:
		"score_add":
			if context == "score_calculation":
				base_score += joker_data.effect_value
				effect_applied = true
		
		"score_multiply":
			if context == "score_calculation":
				score_multiplier *= joker_data.effect_value
				effect_applied = true
		
		"extra_draw":
			if context == "turn_start":
				# 额外抽牌逻辑在这里
				effect_applied = true
		
		"focus_recovery":
			if context == "after_combination":
				set_focus(focus_count + joker_data.effect_value)
				effect_applied = true
		
		"heart_bonus", "diamond_bonus", "odd_bonus", "even_bonus", "red_bonus":
			# 这些效果需要在评估牌型时考虑
			if context == "card_evaluation":
				effect_applied = true
		
		"pair_multiply", "straight_multiply":
			# 这些效果需要在评估特定牌型时考虑
			if context == "combination_evaluation":
				effect_applied = true
		
		# 添加更多效果类型处理...
	
	if effect_applied:
		emit_signal("joker_effect_applied", joker_data)
		print("应用小丑卡效果: " + joker_data.name + " - " + joker_data.effect_description) 

# 增加分数
func add_score(amount):
	score += amount
	current_mana += amount  # 同时更新学识魔力
	
	print("GameManager.add_score: 增加分数 %d，当前分数=%d，学识魔力=%d" % [amount, score, current_mana])
	
	# 发送信号
	emit_signal("score_changed", score)
	emit_signal("mana_changed", current_mana)
	
	# 检查胜利条件
	if score >= VICTORY_SCORE:
		print("GameManager.add_score: 达成胜利条件，发送game_won信号")
		emit_signal("game_won")
	
	return score

# 发送资源和分数信号
func _emit_resource_score():
	print("GameManager._emit_resource_score: 发送资源变化信号，focus=%d, essence=%d, remaining_runes=%d" % [focus_count, essence_count, remaining_runes])
	emit_signal("resources_changed", focus_count, essence_count, remaining_runes)
	
	print("GameManager._emit_resource_score: 发送分数变化信号，score=%d" % score)
	emit_signal("score_changed", score)
	
	if score >= VICTORY_SCORE:
		print("GameManager._emit_resource_score: 发送胜利信号，score=%d >= VICTORY_SCORE=%d" % [score, VICTORY_SCORE])
		emit_signal("game_won")

# ---------------- 新增：资源与分数工具函数 ----------------
# 重置主要资源（供 MainGame 调用）
func reset_resources():
	set_focus(INITIAL_FOCUS)
	set_essence(INITIAL_ESSENCE)
	_emit_resource_score()

# 消耗 1 点集中力
func use_focus() -> bool:
	if focus_count > 0:
		focus_count -= 1
		_emit_resource_score()
		return true
	return false

# 消耗 1 点精华
func use_essence() -> bool:
	if essence_count > 0:
		essence_count -= 1
		_emit_resource_score()
		return true
	return false 
 
