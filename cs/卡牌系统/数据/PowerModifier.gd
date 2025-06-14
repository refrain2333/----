class_name PowerModifier
extends CardModifier

# 能量修饰符：修改卡牌的能量值

var power_change: int = 0  # 能量变化值

# 构造函数
func _init(change_amount: int):
	name = "能量修饰"
	power_change = change_amount
	
	if power_change > 0:
		description = "增加%d点能量" % power_change
	else:
		description = "减少%d点能量" % abs(power_change)

# 应用修饰效果
func apply(card: CardData) -> void:
	# 修改卡牌能量值
	card.power += power_change 
