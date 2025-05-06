extends Node2D

# 卡牌类型枚举
enum CardType { CLUB, DIAMOND, HEART, SPADE }

# 卡牌属性
var card_id = 0
var card_type = CardType.CLUB
var card_value = 1  # A=1, 2-10=2-10, J=11, Q=12, K=13

# 用于显示的节点引用
onready var card_bg = $Background
onready var card_value_label = $ValueLabel
onready var card_suit_icon = $SuitIcon

# 设置卡牌属性
func setup(id, type, value):
	card_id = id
	card_type = type
	card_value = value
	update_appearance()
	
# 更新卡牌外观
func update_appearance():
	# 设置背景颜色
	match card_type:
		CardType.CLUB:
			card_bg.color = Color(0.2, 0.2, 0.2, 1.0)  # 深灰色
		CardType.DIAMOND:
			card_bg.color = Color(0.8, 0.2, 0.2, 1.0)  # 红色
		CardType.HEART:
			card_bg.color = Color(0.8, 0.2, 0.4, 1.0)  # 粉红色
		CardType.SPADE:
			card_bg.color = Color(0.1, 0.1, 0.3, 1.0)  # 深蓝色
	
	# 设置点数文本
	var value_text = ""
	match card_value:
		1: value_text = "A"
		11: value_text = "J"
		12: value_text = "Q"
		13: value_text = "K"
		_: value_text = str(card_value)
	
	card_value_label.text = value_text
	
	# 设置花色图标文本
	var suit_text = ""
	match card_type:
		CardType.CLUB: suit_text = "♣"
		CardType.DIAMOND: suit_text = "♦"
		CardType.HEART: suit_text = "♥"
		CardType.SPADE: suit_text = "♠"
	
	card_suit_icon.text = suit_text

# 获取卡牌名称
func get_card_name():
	var value_name = ""
	match card_value:
		1: value_name = "A"
		11: value_name = "J"
		12: value_name = "Q"
		13: value_name = "K"
		_: value_name = str(card_value)
	
	var suit_name = ""
	match card_type:
		CardType.CLUB: suit_name = "梅花"
		CardType.DIAMOND: suit_name = "方块"
		CardType.HEART: suit_name = "红桃"
		CardType.SPADE: suit_name = "黑桃"
	
	return suit_name + value_name

# 卡牌点击处理
func _on_CardButton_pressed():
	print("卡牌被点击：", get_card_name()) 