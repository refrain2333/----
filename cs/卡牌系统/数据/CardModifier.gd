class_name CardModifier
extends RefCounted

# 卡牌修饰符基类：用于给卡牌添加特殊效果或属性修改

# 基本属性
var name: String = "修饰符"
var description: String = "基础修饰符"
var icon_path: String = ""  # 修饰符图标路径
var duration: int = -1  # 持续回合数，-1表示永久

# 构造函数
func _init():
	pass

# 应用修饰效果
func apply(_card: CardData) -> void:
	pass

# 移除修饰效果
func remove(_card: CardData) -> void:
	pass

# 回合开始时调用
func on_turn_start(_card: CardData) -> void:
	pass

# 回合结束时调用
func on_turn_end(_card: CardData) -> void:
	pass

# 卡牌被打出时调用
func on_card_played(_card: CardData) -> void:
	pass

# 卡牌被抽取时调用
func on_card_drawn(_card: CardData) -> void:
	pass

# 卡牌被丢弃时调用
func on_card_discarded(_card: CardData) -> void:
	pass

# 获取修饰符描述
func get_description() -> String:
	return description

# 序列化数据，用于存档
func serialize() -> Dictionary:
	return {
		"type": "CardModifier",
		"name": name,
		"description": description,
		"icon_path": icon_path,
		"duration": duration
	}

# 从序列化数据恢复
static func deserialize(data: Dictionary) -> CardModifier:
	var modifier = CardModifier.new()
	modifier.name = data.name
	modifier.description = data.description
	modifier.icon_path = data.icon_path
	modifier.duration = data.duration
	return modifier 
