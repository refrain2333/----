class_name CardData
extends Resource

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 卡牌基础属性（符合v1.6规范）
@export var id: String = ""           # 唯一ID, 如 "H1", "S13"
@export var base_value: int = 0       # 1-13 (A-K)
@export var suit: String = ""         # "hearts", "diamonds", "clubs", "spades"
@export var name: String = ""         # "红桃A"
@export var image_path: String = ""   # 卡牌图片路径

# 强化属性（符合v1.6规范）
@export var wax_seals: Array[String] = [] # 存储各类蜡封
@export var frame_type: String = ""       # 存储牌框类型
@export var material_type: String = ""    # 存储材质类型

# 游戏特定属性
@export var damage: int = 0           # 伤害值
@export var defense: int = 0          # 防御值
@export var cost: int = 0             # 使用消耗
@export var rarity: String = "common" # 稀有度
@export var description: String = ""  # 卡牌描述
@export var card_type: String = ""    # 卡牌类型 (attack/defense/spell/etc)

# 牌库配置
@export var deck_count: int = 1       # 在牌库中的数量
@export var max_in_deck: int = 4      # 牌库中最大数量限制

# 用于效果扩展的字典
var effect_data: Dictionary = {}

# 动态属性系统
var modifiers: Dictionary = {}  # 存储各种修正值
var permanent_changes: Dictionary = {}  # 永久性改变
var temporary_effects: Array[Dictionary] = []  # 临时效果

## 🎯 从ID中提取面值（用于牌型识别）
func get_face_value() -> int:
	if id.is_empty():
		return base_value

	# 提取ID中的数字部分 (如 "S1" -> 1, "H13" -> 13)
	var number_part = id.substr(1)  # 去掉第一个字符（花色）
	var face_value = number_part.to_int()

	# 确保面值在有效范围内
	if face_value >= 1 and face_value <= 13:
		return face_value
	else:
		return base_value  # 如果ID格式不正确，回退到base_value

## 🎯 从ID中提取花色（用于牌型识别）
func get_face_suit() -> String:
	if id.is_empty():
		return suit

	# 提取ID中的花色部分
	var suit_char = id.substr(0, 1).to_upper()
	match suit_char:
		"S": return "spades"
		"H": return "hearts"
		"D": return "diamonds"
		"C": return "clubs"
		_: return suit  # 如果ID格式不正确，回退到suit属性

# 获取卡牌当前修正值（考虑强化和效果）
func get_modified_value(effect_provider = null) -> int:
	var modified_val = base_value
	
	# 基于强化的静态修饰
	if has_frame_reinforcement():
		match frame_type:
			"STONE":
				modified_val += 2
			"SILVER": 
				modified_val += 3
			"GOLD":
				modified_val += 5
		
	# 动态效果修饰（如果提供了效果提供者）
	if effect_provider:
		# 使用依赖注入模式，由外部提供效果
		if effect_provider.has_method("get_card_value_modifier"):
			var effect_mod = effect_provider.get_card_value_modifier(self)
			modified_val += effect_mod
			
	return modified_val

# 强化系统接口

# 添加强化效果 - 统一的接口
func add_reinforcement(type: String, effect: String) -> void:
	match type:
		"WAX_SEAL":
			if not effect in wax_seals:
				wax_seals.append(effect)
		"FRAME":
			frame_type = effect
		"MATERIAL":
			material_type = effect

# 移除蜡封
func remove_wax_seal(seal_type: String) -> bool:
	var idx = wax_seals.find(seal_type)
	if idx >= 0:
		wax_seals.remove_at(idx)
		return true
	return false
	
# 检查是否有特定类型的蜡封
func has_wax_seal(seal_type: String) -> bool:
	return seal_type in wax_seals

# 检查是否有任何蜡封
func has_any_wax_seal() -> bool:
	return not wax_seals.is_empty()

# 获取蜡封数量
func get_wax_seal_count() -> int:
	return wax_seals.size()

# 检查是否有牌框强化
func has_frame_reinforcement() -> bool:
	return frame_type != ""

# 检查是否有材质强化
func has_material_reinforcement() -> bool:
	return material_type != ""

# 效果系统接口

# 设置效果数据
func set_effect_data(key: String, value) -> void:
	effect_data[key] = value

# 获取效果数据
func get_effect_data(key: String, default_value = null):
	return effect_data.get(key, default_value)

# 检查是否有特定效果数据
func has_effect_data(key: String) -> bool:
	return effect_data.has(key)

# 清除效果数据
func clear_effect_data(key: String) -> void:
	if effect_data.has(key):
		effect_data.erase(key)

# 复制和信息接口

# 深拷贝卡牌实例，用于复制牌（符合v1.6规范）
func clone() -> CardData:
	var new_card = CardData.new()
	new_card.id = id + "_" + str(randi()) # 复制品有新ID
	new_card.base_value = base_value
	new_card.suit = suit
	new_card.name = name
	new_card.image_path = image_path
	new_card.wax_seals = wax_seals.duplicate() # 复制数组
	new_card.frame_type = frame_type
	new_card.material_type = material_type
	new_card.effect_data = effect_data.duplicate(true) # 深度复制效果数据
	return new_card

# 获取卡牌信息
func get_info() -> String:
	var info = name + " (值:" + str(base_value) + ")"

	if has_any_wax_seal():
		info += ", 蜡封:" + str(get_wax_seal_count())

	if has_frame_reinforcement():
		info += ", 框:" + frame_type

	if has_material_reinforcement():
		info += ", 材质:" + material_type

	return info

# 获取花色显示名称
func get_suit_display_name() -> String:
	match suit.to_lower():
		"hearts":
			return "红桃"
		"diamonds":
			return "方片"
		"clubs":
			return "梅花"
		"spades":
			return "黑桃"
		_:
			return "未知"

# 获取值的显示名称
func get_value_display_name() -> String:
	match base_value:
		1:
			return "A"
		11:
			return "J"
		12:
			return "Q"
		13:
			return "K"
		_:
			return str(base_value)

# 静态辅助方法
# 判断是否同花色
static func is_same_suit(card1: CardData, card2: CardData) -> bool:
	return card1.suit == card2.suit

# 判断是否同值
static func is_same_value(card1: CardData, card2: CardData) -> bool:
	return card1.base_value == card2.base_value

# 计算总能量值
static func calculate_total_power(cards: Array) -> int:
	var total = 0
	for card in cards:
		if card is CardData:
			total += card.base_value
	return total
	
# 检查是否是顺子
static func is_straight(cards: Array) -> bool:
	if cards.size() < 3:
		return false
		
	# 提取值并排序
	var values = []
	for card in cards:
		if card is CardData:
			values.append(card.base_value)
	
	values.sort()
	
	# 检查连续性
	for i in range(1, values.size()):
		if values[i] != values[i-1] + 1:
			return false
	
	return true
	
# 检查是否同花
static func is_flush(cards: Array) -> bool:
	if cards.size() < 3:
		return false
		
	var first_suit = ""
	
	for card in cards:
		if card is CardData:
			if first_suit == "":
				first_suit = card.suit
			elif card.suit != first_suit:
				return false
	
	return true
