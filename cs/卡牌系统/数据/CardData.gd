class_name CardData
extends Resource

# 卡牌基础属性
var id: String = ""         # 卡牌ID (例如 "fire_1")
var name: String = ""       # 显示名称，如"火之一"
var suit: String = ""        # 花色：spades（黑桃）, hearts（红桃）, clubs（梅花）, diamonds（方片）
var value: int = 0           # 牌值：1(A)-13(K)
var element: String = ""     # 元素属性（fire, water, earth, air）
var power: int = 0           # 能量值（可用于计分）
var cost: int = 1            # 卡牌费用
@export var point: int = 1   # 得分值（打出时获得的分数）
var modifiers: Array = []    # 卡牌修饰符数组
var texture_path: String = "" # 卡牌图像路径

# 构造函数
func _init(card_id = null):
	if card_id is int and card_id > 0 and card_id <= 52:
		_setup_from_numeric_id(card_id)
	elif card_id is String and card_id.length() > 0:
		id = card_id

# 检查是否有指定属性
func has(property: String) -> bool:
	return property in self

# 根据数字ID设置卡牌属性
func _setup_from_numeric_id(card_id: int):
	# 确定花色
	if card_id <= 13:
		suit = "spades"  # 黑桃
		element = "earth"  # 可以根据游戏设计分配元素
	elif card_id <= 26:
		suit = "hearts"  # 红桃
		element = "fire"
	elif card_id <= 39:
		suit = "clubs"   # 梅花
		element = "air"
	else:
		suit = "diamonds" # 方片
		element = "water"
	
	# 确定牌值
	value = (card_id - 1) % 13 + 1
	
	# 设置能量值（示例：A=14, K=13, Q=12, J=11, 其他=牌面值）
	if value == 1:  # A
		power = 14
		point = 5   # A牌得分高
	elif value >= 11:  # J, Q, K
		power = value
		point = 3   # 人物牌得分中等
	else:
		power = value
		point = 1   # 数字牌得分基础
	
	# 设置显示名称
	var element_name = ""
	match element:
		"fire": element_name = "火"
		"water": element_name = "水"
		"earth": element_name = "土"
		"air": element_name = "风"
	
	var value_name = ""
	match value:
		1: value_name = "一"
		2: value_name = "二"
		3: value_name = "三"
		4: value_name = "四"
		5: value_name = "五"
		6: value_name = "六"
		7: value_name = "七"
		8: value_name = "八"
		9: value_name = "九"
		10: value_name = "十"
		11: value_name = "王子"
		12: value_name = "王后"
		13: value_name = "国王"
	
	name = element_name + "之" + value_name
	
	# 设置ID
	id = element + "_" + str(value)
	
	# 设置费用
	cost = _calculate_cost(value)

# 计算卡牌费用
func _calculate_cost(value: int) -> int:
	if value <= 5:
		return 1
	elif value <= 10:
		return 2
	else:
		return 3

# 获取卡牌基本信息
func get_info() -> String:
	return name + " (能量:" + str(power) + ")"

# 获取卡牌比较值（用于排序）
func get_compare_value() -> int:
	return value

# 判断两张牌是否同花色
static func is_same_suit(card1: CardData, card2: CardData) -> bool:
	return card1.suit == card2.suit

# 判断两张牌是否同值
static func is_same_value(card1: CardData, card2: CardData) -> bool:
	return card1.value == card2.value

# 判断是否同色
static func is_same_color(card1: CardData, card2: CardData) -> bool:
	return card1.suit == card2.suit
	
# 判断是否同元素
static func is_same_element(card1: CardData, card2: CardData) -> bool:
	return card1.element == card2.element
	
# 判断是否顺子（连续的牌值）
static func is_straight(cards: Array) -> bool:
	if cards.size() < 2:
		return false
		
	# 对牌按值排序
	var sorted_cards = cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.value < b.value)
	
	# 检查是否连续
	for i in range(1, sorted_cards.size()):
		if sorted_cards[i].value != sorted_cards[i-1].value + 1:
			return false
			
	return true
	
# 判断是否同花（所有牌同一花色）
static func is_flush(cards: Array) -> bool:
	if cards.size() < 2:
		return false
		
	var first_suit = cards[0].suit
	for card in cards:
		if card.suit != first_suit:
			return false
			
	return true
	
# 计算卡牌组合的能量总值
static func calculate_total_power(cards: Array) -> int:
	var total = 0
	for card in cards:
		total += card.power
	return total 
	
# 添加修饰符
func add_modifier(mod: CardModifier) -> void:
	if not modifiers:
		modifiers = []
	modifiers.append(mod)
	mod.apply(self)

# 移除修饰符
func remove_modifier(mod: CardModifier) -> bool:
	if not modifiers:
		return false
	var idx = modifiers.find(mod)
	if idx >= 0:
		modifiers.remove_at(idx)
		return true
	return false
	
# 获取所有修饰符
func get_modifiers() -> Array:
	return modifiers

# 克隆卡牌数据
func clone() -> CardData:
	var c := CardData.new(id)
	# 复制修饰符
	if modifiers and not modifiers.is_empty():
		c.modifiers = modifiers.duplicate()
	return c
