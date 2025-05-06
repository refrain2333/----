extends Node

# 卡牌类型枚举，与Card.gd中保持一致
enum CardType { CLUB, DIAMOND, HEART, SPADE }

# 卡牌牌型枚举
enum HandType {
	HIGH_CARD,    # 高牌
	PAIR,         # 对子
	TWO_PAIR,     # 两对
	THREE_OF_KIND,# 三条
	STRAIGHT,     # 顺子
	FLUSH,        # 同花
	FULL_HOUSE,   # 葫芦
	FOUR_OF_KIND, # 四条
	STRAIGHT_FLUSH,# 同花顺
	ROYAL_FLUSH   # 皇家同花顺
}

# 简化版卡牌数据类
class CardData:
	var id: int
	var type: int
	var value: int
	
	func _init(card_id: int, card_type: int, card_value: int):
		id = card_id
		type = card_type
		value = card_value

# 仅保留牌组相关基本变量
var full_deck = []
var current_deck = []

# 初始化卡牌管理器
func _ready():
	print("卡牌管理器初始化")

# 获取牌型名称 - 保留以供显示使用
func get_hand_type_name(hand_type: int) -> String:
	match hand_type:
		HandType.HIGH_CARD:
			return "高牌"
		HandType.PAIR:
			return "对子"
		HandType.TWO_PAIR:
			return "两对"
		HandType.THREE_OF_KIND:
			return "三条"
		HandType.STRAIGHT:
			return "顺子"
		HandType.FLUSH:
			return "同花"
		HandType.FULL_HOUSE:
			return "葫芦"
		HandType.FOUR_OF_KIND:
			return "四条"
		HandType.STRAIGHT_FLUSH:
			return "同花顺"
		HandType.ROYAL_FLUSH:
			return "皇家同花顺"
		_:
			return "未知"

# 创建一副完整的牌组
func create_full_deck():
	full_deck.clear()
	
	# 生成52张牌
	var card_id = 1
	
	# 每种花色13张牌
	for type in range(4):  # CLUB, DIAMOND, HEART, SPADE
		for value in range(1, 14):  # 1(A)到13(K)
			var card = CardData.new(card_id, type, value)
			full_deck.append(card)
			card_id += 1
	
	print("已创建完整牌组，共 ", full_deck.size(), " 张牌")

# 重置并洗牌
func reset_and_shuffle():
	# 复制完整牌组到当前牌组
	current_deck = full_deck.duplicate()
	# 清空已发卡牌
	dealt_cards.clear()
	# 洗牌
	shuffle_deck()
	
	print("牌组已重置并洗牌，当前牌组有 ", current_deck.size(), " 张牌")

# 洗牌算法
func shuffle_deck():
	# 使用Fisher-Yates洗牌算法
	var n = current_deck.size()
	for i in range(n - 1, 0, -1):
		# 随机选择0到i之间的一个索引
		var j = randi() % (i + 1)
		# 交换位置i和j的卡牌
		var temp = current_deck[i]
		current_deck[i] = current_deck[j]
		current_deck[j] = temp

# 发牌（返回指定数量的卡牌）
func deal_cards(count):  # 删除返回值类型限制
	var hand = []  # 使用动态数组
	
	# 检查牌组中是否有足够的牌
	if current_deck.size() < count:
		print("警告：牌组中卡牌不足！")
		return hand
	
	# 从牌组顶部发出指定数量的牌
	for i in range(count):
		var card = current_deck.pop_front()
		hand.append(card)
		dealt_cards.append(card)
	
	print("已发出 ", count, " 张牌，牌组还剩 ", current_deck.size(), " 张")
	return hand

# 判断牌型
func evaluate_hand(cards):  # 删除参数类型限制
	# 检查是否有足够的牌判断牌型
	if cards.size() < 5:
		return HandType.HIGH_CARD
	
	# 统计相同点数的卡牌
	var value_counts = {}
	# 统计相同花色的卡牌
	var type_counts = {}
	
	# 遍历所有卡牌，统计点数和花色
	for card in cards:
		# 统计点数
		if card.value in value_counts:
			value_counts[card.value] += 1
		else:
			value_counts[card.value] = 1
		
		# 统计花色
		if card.type in type_counts:
			type_counts[card.type] += 1
		else:
			type_counts[card.type] = 1
	
	# 检查是否同花
	var is_flush = false
	for type in type_counts:
		if type_counts[type] >= 5:
			is_flush = true
			break
	
	# 检查是否顺子
	var is_straight = false
	var sorted_values = value_counts.keys()
	sorted_values.sort()
	
	if sorted_values.size() >= 5:
		for i in range(sorted_values.size() - 4):
			if sorted_values[i+4] - sorted_values[i] == 4:
				is_straight = true
				break
	
	# 特殊情况：A2345顺子
	if 1 in value_counts and 2 in value_counts and 3 in value_counts and 4 in value_counts and 5 in value_counts:
		is_straight = true
	
	# 特殊情况：10JQKA顺子
	if 1 in value_counts and 10 in value_counts and 11 in value_counts and 12 in value_counts and 13 in value_counts:
		is_straight = true
	
	# 判断牌型
	# 同花顺
	if is_flush and is_straight:
		# 皇家同花顺：同花顺中包含10JQKA
		if 1 in value_counts and 10 in value_counts and 11 in value_counts and 12 in value_counts and 13 in value_counts:
			return HandType.ROYAL_FLUSH
		else:
			return HandType.STRAIGHT_FLUSH
	
	# 四条
	for value in value_counts:
		if value_counts[value] == 4:
			return HandType.FOUR_OF_KIND
	
	# 葫芦：三条+对子
	var has_three = false
	var has_pair = false
	for value in value_counts:
		if value_counts[value] == 3:
			has_three = true
		elif value_counts[value] == 2:
			has_pair = true
	
	if has_three and has_pair:
		return HandType.FULL_HOUSE
	
	# 同花
	if is_flush:
		return HandType.FLUSH
	
	# 顺子
	if is_straight:
		return HandType.STRAIGHT
	
	# 三条
	if has_three:
		return HandType.THREE_OF_KIND
	
	# 两对
	var pair_count = 0
	for value in value_counts:
		if value_counts[value] == 2:
			pair_count += 1
	
	if pair_count >= 2:
		return HandType.TWO_PAIR
	elif pair_count == 1:
		return HandType.PAIR
	
	# 高牌
	return HandType.HIGH_CARD

# 获取牌型的分数
func get_hand_score(hand_type: HandType) -> int:
	match hand_type:
		HandType.HIGH_CARD:
			return 10
		HandType.PAIR:
			return 20
		HandType.TWO_PAIR:
			return 30
		HandType.THREE_OF_KIND:
			return 50
		HandType.STRAIGHT:
			return 80
		HandType.FLUSH:
			return 100
		HandType.FULL_HOUSE:
			return 150
		HandType.FOUR_OF_KIND:
			return 250
		HandType.STRAIGHT_FLUSH:
			return 400
		HandType.ROYAL_FLUSH:
			return 1000
		_:
			return 0 
