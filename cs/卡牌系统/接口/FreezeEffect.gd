class_name FreezeEffect
extends RefCounted
# 实现 ICardEffect 接口

# 冰冻效果：暂时禁用目标卡牌，持续一定回合数

var duration: int = 2  # 冰冻持续回合数
var turns_remaining: int = 0  # 剩余回合数
var is_active: bool = false  # 效果是否激活
var target_original_power: int = 0  # 目标原始能量值

# 构造函数
func _init(freeze_duration: int = 2):
	duration = freeze_duration
	turns_remaining = duration

# 当效果激活时调用
func on_activate(card_data: CardData) -> void:
	if is_active:
		return
		
	is_active = true
	turns_remaining = duration
	
	# 保存原始能量值并设置为0
	target_original_power = card_data.power
	card_data.power = 0
	
	print("【%s】被冰冻，持续%d回合" % [card_data.display_name, duration])
	
	# 这里可以添加视觉效果，例如添加冰冻图标
	# card_data.add_visual_effect("freeze")

# 当效果失效时调用
func on_deactivate(card_data: CardData) -> void:
	if not is_active:
		return
		
	is_active = false
	
	# 恢复原始能量值
	card_data.power = target_original_power
	
	print("【%s】冰冻效果结束，恢复能量值" % [card_data.display_name])
	
	# 移除视觉效果
	# card_data.remove_visual_effect("freeze")

# 持续效果处理
func process_effect(delta: float) -> void:
	if not is_active:
		return
		
	# 这里可以添加视觉效果更新
	# 例如冰晶粒子效果

# 回合结束时处理
func on_turn_end(card_data: CardData) -> void:
	if not is_active:
		return
		
	turns_remaining -= 1
	print("【%s】冰冻效果剩余%d回合" % [card_data.display_name, turns_remaining])
	
	if turns_remaining <= 0:
		on_deactivate(card_data)

# 获取效果描述
func get_description() -> String:
	if is_active:
		return "冰冻效果：禁用卡牌能量，剩余%d回合" % turns_remaining
	else:
		return "冰冻效果：禁用卡牌能量，持续%d回合" % duration

# 序列化数据，用于存档
func serialize() -> Dictionary:
	return {
		"type": "FreezeEffect",
		"duration": duration,
		"turns_remaining": turns_remaining,
		"is_active": is_active,
		"target_original_power": target_original_power
	}

# 从序列化数据恢复
static func deserialize(data: Dictionary) -> FreezeEffect:
	var effect = FreezeEffect.new(data.duration)
	effect.turns_remaining = data.turns_remaining
	effect.is_active = data.is_active
	effect.target_original_power = data.target_original_power
	return effect 
