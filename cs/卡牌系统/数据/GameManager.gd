extends Node

# 回合状态枚举
enum TurnState {
	DRAW,    # 抽牌阶段
	ACTION,  # 行动阶段
	RESOLVE, # 结算阶段
	END      # 结束阶段
}

# 游戏常量
const MAX_HAND_SIZE = 10  # 最大手牌数量
const MIN_RUNE_COST = 0   # 最小符文费用
const MAX_FOCUS = 5       # 最大集中力
const MAX_ESSENCE = 3     # 最大精华

# 游戏状态
var current_turn = 1      # 当前回合数
var current_state = TurnState.DRAW  # 当前回合状态
var current_mana = 0      # 当前魔力值
var focus_count = MAX_FOCUS  # 集中力（剩余出牌次数）
var essence_count = MAX_ESSENCE  # 精华（弃牌次数）
var lore_points = 4       # 学识点（金币）

# 分数相关
var base_score = 50       # 基础分数
var score_multiplier = 1  # 分数倍率
var total_score = 0       # 总分数

# 牌库相关
var deck = []             # 牌库
var hand = []             # 手牌
var discard_pile = []     # 弃牌堆
var total_runes = 52      # 牌库总数
var remaining_runes = 52  # 剩余数量
var rune_cost = 1         # 当前符文费用

# 小丑卡相关
var active_jokers = []    # 激活的小丑卡
var max_jokers = 3        # 最大小丑卡数量

# 发现和法器相关
var discovery_cards = []  # 发现卡
var artifacts = []        # 法器
var max_discoveries = 3   # 最大发现数量
var max_artifacts = 6     # 最大法器数量

func _ready():
	# 设置为单例
	Engine.register_singleton("GameManager", self)
	
	# 初始化游戏
	initialize_game()

# 初始化游戏
func initialize_game():
	# 初始化牌库
	initialize_deck()
	
	# 初始化资源
	reset_resources()
	
	print("游戏管理器初始化完成")

# 初始化牌库
func initialize_deck():
	deck.clear()
	
	# 创建52张牌
	var suits = ["fire", "water", "earth", "air"]
	var values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
	
	for suit in suits:
		for value in values:
			var card = {
				"id": suit + "_" + str(value),
				"name": _get_card_name(suit, value),
				"element": suit,
				"value": value,
				"power": value,
				"cost": _calculate_cost(value)
			}
			deck.append(card)
	
	# 洗牌
	deck.shuffle()
	
	# 更新计数
	total_runes = deck.size()
	remaining_runes = deck.size()

# 获取卡牌名称
func _get_card_name(element, value):
	var element_names = {
		"fire": "火",
		"water": "水",
		"earth": "土",
		"air": "风"
	}
	
	var value_names = {
		1: "一",
		2: "二",
		3: "三",
		4: "四",
		5: "五",
		6: "六",
		7: "七",
		8: "八",
		9: "九",
		10: "十",
		11: "王子",
		12: "王后",
		13: "国王"
	}
	
	return element_names[element] + "之" + value_names[value]

# 计算卡牌费用
func _calculate_cost(value):
	if value <= 5:
		return 1
	elif value <= 10:
		return 2
	else:
		return 3

# 重置资源
func reset_resources():
	current_mana = 0
	focus_count = MAX_FOCUS
	essence_count = MAX_ESSENCE
	lore_points = 4
	base_score = 50
	score_multiplier = 1

# 重置回合资源
func reset_turn_resources():
	focus_count = MAX_FOCUS
	essence_count = MAX_ESSENCE

# 抽牌
func draw_card():
	if deck.size() == 0:
		return null
	
	if hand.size() >= MAX_HAND_SIZE:
		return null
	
	var card = deck.pop_front()
	hand.append(card)
	
	remaining_runes = deck.size()
	
	return card

# 检查手牌是否已满
func is_hand_full():
	return hand.size() >= MAX_HAND_SIZE

# 获取手牌
func get_hand():
	return hand

# 获取牌库
func get_deck():
	return deck

# 获取魔力值
func get_mana():
	return current_mana

# 获取集中力
func get_focus():
	return focus_count

# 获取精华
func get_essence():
	return essence_count

# 获取学识点
func get_lore():
	return lore_points

# 获取基础分数
func get_base_score():
	return base_score

# 获取倍率
func get_multiplier():
	return score_multiplier

# 获取牌库总数
func get_total_runes():
	return total_runes

# 获取剩余牌库数量
func get_remaining_runes():
	return remaining_runes

# 使用集中力
func use_focus():
	if focus_count > 0:
		focus_count -= 1
		return true
	return false

# 使用精华
func use_essence():
	if essence_count > 0:
		essence_count -= 1
		return true
	return false

# 增加魔力值
func add_mana(amount):
	current_mana += amount

# 增加学识点
func add_lore(amount):
	lore_points += amount

# 增加分数
func add_score(amount):
	total_score += amount

# 设置符文费用
func set_rune_cost(cost):
	rune_cost = max(MIN_RUNE_COST, cost)

# 设置分数值
func set_score_values(base, multiplier):
	base_score = base
	score_multiplier = multiplier

# 检查是否可以出牌
func can_play_card(card_data):
	if focus_count <= 0:
		return false
	
	if card_data.has("cost") and card_data.cost > rune_cost:
		return false
	
	return true

# 检查是否可以弃牌
func can_discard_card():
	return essence_count > 0

# 添加小丑卡
func add_joker(joker_data):
	if active_jokers.size() >= max_jokers:
		return false
	
	active_jokers.append(joker_data)
	return true

# 添加发现
func add_discovery(discovery_data):
	if discovery_cards.size() >= max_discoveries:
		return false
	
	discovery_cards.append(discovery_data)
	return true

# 添加法器
func add_artifact(artifact_data):
	if artifacts.size() >= max_artifacts:
		return false
	
	artifacts.append(artifact_data)
	return true

# 提供小丑卡选择
func offer_jokers(count: int = 3):
	return JokerData.get_random_jokers(count)

# 评估符文组合
func evaluate_rune_combination(cards):
	var result = {
		"base_score": 0,
		"multiplier": 1,
		"combinations": []
	}
	
	# 简单计算：基础分数为所有卡牌的power总和
	for card in cards:
		if card.has("power"):
			result.base_score += card.power
	
	# 检查是否有特殊组合
	var has_fire = false
	var has_water = false
	var has_earth = false
	var has_air = false
	
	for card in cards:
		if card.has("element"):
			match card.element:
				"fire":
					has_fire = true
				"water":
					has_water = true
				"earth":
					has_earth = true
				"air":
					has_air = true
	
	# 元素组合倍率
	if has_fire and has_water:
		result.multiplier += 1
		result.combinations.append("水火相克")
	
	if has_earth and has_air:
		result.multiplier += 1
		result.combinations.append("土风相生")
	
	if has_fire and has_earth:
		result.multiplier += 1
		result.combinations.append("火土相融")
	
	# 四元素齐聚
	if has_fire and has_water and has_earth and has_air:
		result.multiplier += 2
		result.combinations.append("四元素共鸣")
	
	return result

# 抽牌阶段处理
func on_draw_phase(turn_number):
	pass

# 行动阶段处理
func on_action_phase(turn_number):
	pass

# 结算阶段处理
func on_resolve_phase(turn_number):
	pass

# 结束阶段处理
func on_end_phase(turn_number):
	pass 