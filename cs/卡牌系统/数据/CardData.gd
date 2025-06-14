class_name CardData
extends Resource

# 卡牌基础属性
var id: int = 0              # 卡牌ID (1-52)
var suit: String = ""        # 花色：spades（黑桃）, hearts（红桃）, clubs（梅花）, diamonds（方片）
var value: int = 0           # 牌值：1(A)-13(K)
var display_name: String = "" # 显示名称，如"黑桃A"
var texture_path: String = "" # 贴图路径
var color: String = ""       # 颜色：black（黑）或red（红）
var element: String = ""     # 元素属性（可选，用于游戏特殊规则）
var power: int = 0           # 能量值（可用于计分）
var modifiers: Array = []    # 卡牌修饰符数组

# 构造函数
func _init(card_id: int = 0):
	if card_id > 0 and card_id <= 52:
		id = card_id
		_setup_from_id()

# 根据ID设置卡牌属性
func _setup_from_id():
	# 确定花色
	if id <= 13:
		suit = "spades"  # 黑桃
		color = "black"
		element = "earth"  # 可以根据游戏设计分配元素
	elif id <= 26:
		suit = "hearts"  # 红桃
		color = "red"
		element = "fire"
	elif id <= 39:
		suit = "clubs"   # 梅花
		color = "black"
		element = "air"
	else:
		suit = "diamonds" # 方片
		color = "red"
		element = "water"
	
	# 确定牌值
	value = (id - 1) % 13 + 1
	
	# 设置能量值（示例：A=14, K=13, Q=12, J=11, 其他=牌面值）
	if value == 1:  # A
		power = 14
	elif value >= 11:  # J, Q, K
		power = value
	else:
		power = value
	
	# 设置显示名称
	var suit_name = ""
	match suit:
		"spades": suit_name = "黑桃"
		"hearts": suit_name = "红桃"
		"clubs": suit_name = "梅花"
		"diamonds": suit_name = "方片"
	
	var value_name = ""
	match value:
		1: value_name = "A"
		11: value_name = "J"
		12: value_name = "Q"
		13: value_name = "K"
		_: value_name = str(value)
	
	display_name = suit_name + value_name
	
	# 设置贴图路径
	texture_path = "res://assets/images/pokers/" + str(id) + ".jpg"

# 获取卡牌基本信息
func get_info() -> String:
	return display_name + " (能量:" + str(power) + ")"

# 获取卡牌比较值（用于排序）
func get_compare_value() -> int:
	return id

# 判断两张牌是否同花色
static func is_same_suit(card1: CardData, card2: CardData) -> bool:
	return card1.suit == card2.suit

# 判断两张牌是否同值
static func is_same_value(card1: CardData, card2: CardData) -> bool:
	return card1.value == card2.value

# 判断是否同色
static func is_same_color(card1: CardData, card2: CardData) -> bool:
	return card1.color == card2.color
	
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
