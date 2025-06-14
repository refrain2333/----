class_name ElementModifier
extends CardModifier

# 元素修饰符：修改卡牌的元素属性

var new_element: String = ""  # 新的元素属性
var original_element: String = ""  # 原始元素属性

# 构造函数
func _init(element: String):
	name = "元素转换"
	new_element = element
	
	match new_element:
		"fire": 
			description = "转换为火元素"
		"water": 
			description = "转换为水元素"
		"earth": 
			description = "转换为土元素"
		"air": 
			description = "转换为风元素"
		"arcane": 
			description = "转换为奥术元素"
		_: 
			description = "转换为%s元素" % new_element

# 应用修饰效果
func apply(card: CardData) -> void:
	# 保存原始元素
	original_element = card.element
	# 修改卡牌元素
	card.element = new_element 
