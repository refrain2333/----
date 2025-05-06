extends Node

# 卡牌类型枚举
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
	var id = 0
	var type = 0
	var value = 0
	
	func _init(card_id=0, card_type=0, card_value=0):
		id = card_id
		type = card_type
		value = card_value

# 初始化卡牌管理器
func _ready():
	print("卡牌管理器初始化")

# 获取牌型名称 - 保留以供显示使用
func get_hand_type_name(hand_type):
	match hand_type:
		HandType.HIGH_CARD: return "高牌"
		HandType.PAIR: return "对子"
		HandType.TWO_PAIR: return "两对"
		HandType.THREE_OF_KIND: return "三条"
		HandType.STRAIGHT: return "顺子"
		HandType.FLUSH: return "同花"
		HandType.FULL_HOUSE: return "葫芦"
		HandType.FOUR_OF_KIND: return "四条"
		HandType.STRAIGHT_FLUSH: return "同花顺"
		HandType.ROYAL_FLUSH: return "皇家同花顺"
		_: return "未知"

# 获取牌型的分数
func get_hand_score(hand_type):
	match hand_type:
		HandType.HIGH_CARD: return 10
		HandType.PAIR: return 20
		HandType.TWO_PAIR: return 30
		HandType.THREE_OF_KIND: return 50
		HandType.STRAIGHT: return 80
		HandType.FLUSH: return 100
		HandType.FULL_HOUSE: return 150
		HandType.FOUR_OF_KIND: return 250
		HandType.STRAIGHT_FLUSH: return 400
		HandType.ROYAL_FLUSH: return 1000
		_: return 0 
