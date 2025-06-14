class_name PowerUpModifier
extends CardModifier

# 能量提升修饰符：在回合开始时逐渐提升卡牌能量

var power_per_turn: int = 1  # 每回合增加的能量
var max_power_gain: int = 5  # 最大能量增益
var current_power_gain: int = 0  # 当前已增加的能量

# 构造函数
func _init(power_rate: int = 1, max_gain: int = 5):
	name = "能量成长"
	power_per_turn = power_rate
	max_power_gain = max_gain
	description = "每回合增加%d点能量，最多增加%d点" % [power_per_turn, max_power_gain]

# 应用修饰效果
func apply(card: CardData) -> void:
	# 初始应用时不增加能量，只在回合开始时增加
	pass

# 回合开始时调用
func on_turn_start(card: CardData) -> void:
	if current_power_gain < max_power_gain:
		var gain = min(power_per_turn, max_power_gain - current_power_gain)
		card.power += gain
		current_power_gain += gain
		print("【%s】能量成长: +%d (总计+%d/%d)" % [card.display_name, gain, current_power_gain, max_power_gain])

# 序列化数据，用于存档
func serialize() -> Dictionary:
	return {
		"type": "PowerUpModifier",
		"power_per_turn": power_per_turn,
		"max_power_gain": max_power_gain,
		"current_power_gain": current_power_gain
	}

# 从序列化数据恢复
static func deserialize(data: Dictionary) -> PowerUpModifier:
	var modifier = PowerUpModifier.new(data.power_per_turn, data.max_power_gain)
	modifier.current_power_gain = data.current_power_gain
	return modifier 
