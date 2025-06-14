class_name FireElementEffect
extends RefCounted
# 实现 ICardEffect 接口

# 火焰效果：对目标造成持续伤害，持续一定回合数

var damage_per_turn: int = 2  # 每回合伤害
var duration: int = 3         # 持续回合数
var turns_remaining: int = 0  # 剩余回合数
var is_active: bool = false   # 效果是否激活
var total_damage: int = 0     # 累计造成的伤害

# 构造函数
func _init(damage: int = 2, effect_duration: int = 3):
	damage_per_turn = damage
	duration = effect_duration
	turns_remaining = duration

# 当效果激活时调用
func on_activate(card_data: CardData) -> void:
	if is_active:
		return
		
	is_active = true
	turns_remaining = duration
	total_damage = 0
	
	print("【%s】施放火焰效果，每回合造成%d点伤害，持续%d回合" % [card_data.display_name, damage_per_turn, duration])
	
	# 这里可以添加视觉效果，例如添加火焰图标
	# card_data.add_visual_effect("fire")

# 当效果失效时调用
func on_deactivate(card_data: CardData) -> void:
	if not is_active:
		return
		
	is_active = false
	
	print("【%s】火焰效果结束，总计造成%d点伤害" % [card_data.display_name, total_damage])
	
	# 移除视觉效果
	# card_data.remove_visual_effect("fire")

# 持续效果处理
func process_effect(delta: float) -> void:
	if not is_active:
		return
		
	# 这里可以添加视觉效果更新
	# 例如火焰粒子效果

# 回合结束时处理
func on_turn_end(card_data: CardData) -> void:
	if not is_active:
		return
		
	# 造成伤害
	var damage = damage_per_turn
	total_damage += damage
	
	print("【%s】火焰效果造成%d点伤害，剩余%d回合" % [card_data.display_name, damage, turns_remaining - 1])
	
	# 这里应该通知游戏管理器造成伤害
	# game_manager.apply_damage(damage)
	
	turns_remaining -= 1
	if turns_remaining <= 0:
		on_deactivate(card_data)

# 获取效果描述
func get_description() -> String:
	if is_active:
		return "火焰效果：每回合造成%d点伤害，剩余%d回合" % [damage_per_turn, turns_remaining]
	else:
		return "火焰效果：每回合造成%d点伤害，持续%d回合" % [damage_per_turn, duration]

# 序列化数据，用于存档
func serialize() -> Dictionary:
	return {
		"type": "FireElementEffect",
		"damage_per_turn": damage_per_turn,
		"duration": duration,
		"turns_remaining": turns_remaining,
		"is_active": is_active,
		"total_damage": total_damage
	}

# 从序列化数据恢复
static func deserialize(data: Dictionary) -> FireElementEffect:
	var effect = FireElementEffect.new(data.damage_per_turn, data.duration)
	effect.turns_remaining = data.turns_remaining
	effect.is_active = data.is_active
	effect.total_damage = data.total_damage
	return effect 
