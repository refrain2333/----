class_name ICardEffect
extends RefCounted

# 卡牌效果接口：定义所有卡牌效果应该实现的方法

# 当效果激活时调用
func on_activate(card_data: CardData) -> void:
	pass

# 当效果失效时调用
func on_deactivate(card_data: CardData) -> void:
	pass

# 持续效果处理
func process_effect(delta: float) -> void:
	pass

# 回合开始时处理
func on_turn_start(card_data: CardData) -> void:
	pass

# 回合结束时处理
func on_turn_end(card_data: CardData) -> void:
	pass

# 获取效果描述
func get_description() -> String:
	return "基础卡牌效果"

# 序列化数据，用于存档
func serialize() -> Dictionary:
	return {}

# 静态方法：从序列化数据恢复（子类应该实现）
static func deserialize(data: Dictionary) -> ICardEffect:
	return ICardEffect.new() 
