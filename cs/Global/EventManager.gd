extends Node



# Buff类定义
class Buff:
	var id: String
	var description: String
	var duration: int  # 回合数或学期数
	var modifiers: Dictionary  # 任意效果键值对
	
	func _init(p_id: String, p_description: String, p_duration: int = 1, p_modifiers: Dictionary = {}):
		id = p_id
		description = p_description
		duration = p_duration
		modifiers = p_modifiers
	
	func is_expired() -> bool:
		return duration <= 0
	
	func tick() -> void:
		if duration > 0:
			duration -= 1
	
	func get_modifier(key: String, default_value = 0):
		return modifiers.get(key, default_value)

# 事件系统状态
var active_term_buffs: Array[Buff] = [] # 学期内活跃的buff
var active_turn_buffs: Array[Buff] = [] # 回合内活跃的buff
var active_debuffs: Array[Buff] = [] # 活跃的debuff

# 奥术直觉考验状态
var is_arcane_intuition_active: bool = false
var arcane_intuition_target_score: int = 0
var arcane_intuition_snapshot: Dictionary = {}

# 事件管理相关信号
signal random_event_triggered(p_event_id, p_event_description)
signal arcane_intuition_finished(p_succeeded)
signal buff_applied(p_buff_data)
signal debuff_applied(p_debuff_data)
signal buff_expired(p_buff_data)
signal debuff_expired(p_debuff_data)

# 引用
@onready var game_manager = get_node_or_null("/root/GameManager") # 使用get_node_or_null避免错误
@onready var score_calculator = get_node_or_null("/root/ScoreCalculator")

# 随机事件库
var random_events: Array = [
	{
		"id": "LUCKY_FIND",
		"name": "幸运发现",
		"description": "在图书馆的角落里，你发现了一卷被遗忘的古代魔法书籍。",
		"effect": "lore_points_bonus",
		"value": 15,
		"weight": 10
	},
	{
		"id": "MAGICAL_MISHAP",
		"name": "魔法事故",
		"description": "一次实验魔法的意外波动干扰了你的研习。",
		"effect": "score_penalty",
		"value": -10,
		"weight": 8
	},
	{
		"id": "MENTOR_GUIDANCE",
		"name": "导师指导",
		"description": "一位资深教授对你的学术方向提供了宝贵的指导。",
		"effect": "temp_draw_bonus",
		"value": 1,
		"duration": 2,
		"weight": 7
	},
	{
		"id": "ARCANE_SURGE",
		"name": "奥术涌动",
		"description": "奥术能量的自然波动增强了你施放的所有魔法。",
		"effect": "score_multiplier",
		"value": 1.2,
		"duration": 1,
		"weight": 5
	},
	{
		"id": "POTION_ACCIDENT",
		"name": "药剂事故",
		"description": "炼金学实验中的一次小爆炸让你暂时失去了集中力。",
		"effect": "hand_size_penalty",
		"value": -1,
		"duration": 2,
		"weight": 6
	}
]

func _ready():
	# 获取单例引用 - 使用get_node_or_null以避免错误
	game_manager = get_node_or_null("/root/GameManager")
	score_calculator = get_node_or_null("/root/ScoreCalculator")

	# 连接GameManager信号
	_connect_game_manager_signals()

# 连接到GameManager信号
func _connect_game_manager_signals():
	if not game_manager:
		push_warning("EventManager: GameManager单例不可用，无法连接信号")
		return
	
	# 安全连接信号，先检查是否已连接
	var signals_to_connect = {
		"new_year_started": Callable(self, "_on_new_year_started"),
		"term_started": Callable(self, "_on_term_started"),
		"term_ended": Callable(self, "_on_term_ended")
	}
	
	for signal_name in signals_to_connect:
		if game_manager.has_signal(signal_name):
			if not game_manager.is_connected(signal_name, signals_to_connect[signal_name]):
				var result = game_manager.connect(signal_name, signals_to_connect[signal_name])
				if result != OK:
					push_warning("EventManager: 连接GameManager.%s信号失败" % signal_name)
				else:
					print("EventManager: 成功连接GameManager.%s信号" % signal_name)
	
# 信号处理方法
func _on_new_year_started(year):
	print("EventManager: 处理新学年开始事件，年份=%d" % year)
	# 执行新学年开始时的逻辑

func _on_term_started(term_type):
	print("EventManager: 处理学期开始事件，学期类型=%d" % term_type)
	on_term_start()
	
	# 尝试触发随机事件
	if randf() < game_manager.game_config.random_event_chance:
		trigger_random_event()

func _on_term_ended():
	print("EventManager: 处理学期结束事件")
	on_term_end()

# 尝试触发随机事件
func try_trigger_random_event() -> bool:
	if game_manager == null:
		return false
		
	# 检查随机事件触发概率
	var random_chance = randf()
	if random_chance > game_manager.game_config.random_event_chance:
		return false
	
	# 随机选择一个事件
	var event_id = _select_random_event()
	if event_id.is_empty():
		return false
		
	# 触发事件
	var event_data = _get_event_data(event_id)
	if event_data.is_empty():
		return false
		
	print("EventManager: 触发随机事件 %s" % event_id)
	emit_signal("random_event_triggered", event_id, event_data.description)
	
	# 应用事件效果
	_apply_event_effects(event_data)
	
	return true

# 直接触发随机事件 (符合阶段二要求)
func trigger_random_event() -> Dictionary:
	if random_events.is_empty():
		return {}
	
	# 根据权重随机选择事件
	var total_weight = 0
	for event in random_events:
		total_weight += event.get("weight", 1)
	
	var rand_value = randi() % total_weight
	var current_weight = 0
	var selected_event = null
	
	for event in random_events:
		current_weight += event.get("weight", 1)
		if rand_value < current_weight:
			selected_event = event.duplicate()
			break
	
	if selected_event == null:
		selected_event = random_events[0].duplicate()
	
	_apply_event_effect(selected_event)
	
	emit_signal("random_event_triggered", selected_event.id, selected_event.description)
	print("EventManager: 触发随机事件 - %s" % selected_event.name)
	
	return selected_event

# 启动奥术直觉考验
func start_arcane_intuition_challenge() -> bool:
	if is_arcane_intuition_active || game_manager == null:
		return false
	
	# 保存当前游戏状态快照
	arcane_intuition_snapshot = {
		"player_hand_cards": [], # 学期二重构时更新这里
		"current_term": 0, # 学期二重构时更新这里
		"current_year": 0, # 学期二重构时更新这里
		"card_type_levels": {} # 学期二重构时更新这里
	}
	
	# 计算理论最佳得分
	arcane_intuition_target_score = 0 # 学期二重构时更新这里
	
	is_arcane_intuition_active = true
	print("EventManager: 启动奥术直觉考验，目标分数: %d" % arcane_intuition_target_score)
	
	return true

# 结束奥术直觉考验
func end_arcane_intuition_challenge(achieved_score: int) -> bool:
	if not is_arcane_intuition_active:
		return false
	
	var success = achieved_score >= arcane_intuition_target_score
	is_arcane_intuition_active = false
	
	print("EventManager: 结束奥术直觉考验，%s (目标: %d, 实际: %d)" % 
		["成功" if success else "失败", arcane_intuition_target_score, achieved_score])
	
	emit_signal("arcane_intuition_finished", success)
	
	# 应用奖励或惩罚
	if success:
		_apply_arcane_intuition_success()
	else:
		_apply_arcane_intuition_failure()
	
	# 清除快照
	arcane_intuition_snapshot.clear()
	arcane_intuition_target_score = 0
	
	return true

# 添加学期Buff（持续整个学期）
func add_term_buff(buff: Buff) -> void:
	if buff:
		active_term_buffs.append(buff)
		emit_signal("buff_applied", buff)
		print("EventManager: 添加学期Buff: %s, 持续时间: %d" % [buff.id, buff.duration])
	else:
		push_error("EventManager: 添加学期Buff失败，传入值为null")

# 添加回合Buff（持续指定回合数）
func add_turn_buff(buff: Buff) -> void:
	if buff:
		active_turn_buffs.append(buff)
		emit_signal("buff_applied", buff)
		print("EventManager: 添加回合Buff: %s, 持续回合: %d" % [buff.id, buff.duration])
	else:
		push_error("EventManager: 添加回合Buff失败，传入值为null")

# 为兼容旧代码，添加旧格式的buff方法
func add_buff(effect_type_id: String, value: float, duration: int = -1, is_term_buff: bool = false) -> void:
	var modifiers = {effect_type_id: value}
	var buff = Buff.new(effect_type_id, "Buff: " + effect_type_id, duration, modifiers)
	
	if is_term_buff:
		add_term_buff(buff)
	else:
		add_turn_buff(buff)

# 添加Debuff
func add_debuff(effect_type_id: String, value: float, duration: int) -> void:
	var modifiers = {effect_type_id: value}
	var debuff = Buff.new(effect_type_id, "Debuff: " + effect_type_id, duration, modifiers)
	
	active_debuffs.append(debuff)
	emit_signal("debuff_applied", debuff)
	print("EventManager: 添加Debuff: %s, 值: %.2f, 持续回合: %d" % [effect_type_id, value, duration])

# 应用Buff效果到目标
func apply_buffs(target: String, params: Dictionary) -> Dictionary:
	var result = params.duplicate()
	
	# 应用学期buff
	for buff in active_term_buffs:
		if buff.modifiers.has(target):
			var modifier = buff.get_modifier(target)
			if modifier is float or modifier is int:
				if result.has(target) and (result[target] is float or result[target] is int):
					result[target] += modifier
				else:
					result[target] = modifier
	
	# 应用回合buff
	for buff in active_turn_buffs:
		if buff.modifiers.has(target):
			var modifier = buff.get_modifier(target)
			if modifier is float or modifier is int:
				if result.has(target) and (result[target] is float or result[target] is int):
					result[target] += modifier
				else:
					result[target] = modifier
	
	# 应用debuffs
	for debuff in active_debuffs:
		if debuff.modifiers.has(target):
			var modifier = debuff.get_modifier(target)
			if modifier is float or modifier is int:
				if result.has(target) and (result[target] is float or result[target] is int):
					result[target] += modifier
				else:
					result[target] = modifier
	
	return result

# 更新所有buff/debuff的持续时间
func tick_buffs() -> void:
	var expired_term_buffs = []
	var expired_turn_buffs = []
	var expired_debuffs = []
	
	# 更新回合buff持续时间
	for buff in active_turn_buffs:
		buff.tick()
		if buff.is_expired():
			expired_turn_buffs.append(buff)
	
	# 更新debuff持续时间
	for debuff in active_debuffs:
		debuff.tick()
		if debuff.is_expired():
			expired_debuffs.append(debuff)
	
	# 移除过期的buffs
	for buff in expired_term_buffs:
		active_term_buffs.erase(buff)
		emit_signal("buff_expired", buff)
	
	for buff in expired_turn_buffs:
		active_turn_buffs.erase(buff)
		emit_signal("buff_expired", buff)
	
	for debuff in expired_debuffs:
		active_debuffs.erase(debuff)
		emit_signal("debuff_expired", debuff)
	
	if expired_term_buffs.size() + expired_turn_buffs.size() + expired_debuffs.size() > 0:
		print("EventManager: %d个Buff和%d个Debuff过期" % 
			[expired_term_buffs.size() + expired_turn_buffs.size(), expired_debuffs.size()])

# 清理所有回合Buff（每回合结束时调用）
func clear_turn_buffs() -> void:
	active_turn_buffs.clear()
	print("EventManager: 所有回合Buff已清理")

# 清理所有学期Buff（每学期结束时调用）
func clear_term_buffs() -> void:
	active_term_buffs.clear()
	print("EventManager: 所有学期Buff已清理")

# 处理回合开始
func on_turn_start() -> void:
	# 在回合开始时不清理buff
	pass

# 处理回合结束
func on_turn_end() -> void:
	# 减少所有buff和debuff的持续时间
	tick_buffs()

# 处理学期开始
func on_term_start() -> void:
	# 清理学期buff和debuff
	active_term_buffs.clear()
	active_debuffs.clear()
	
	print("EventManager: 新学期开始，清理所有buff和debuff")

# 处理学期结束
func on_term_end() -> void:
	clear_term_buffs()
	# 这里可以添加学期结束时的逻辑
	pass

# 获取所有活跃buff效果的总和
func get_active_buff_value(effect_type_id: String) -> float:
	var total_value = 0.0
	
	# 计算学期buff
	for buff in active_term_buffs:
		if buff.effect_type_id == effect_type_id:
			total_value += buff.value
	
	# 计算回合buff
	for buff in active_turn_buffs:
		if buff.effect_type_id == effect_type_id:
			total_value += buff.value
			
	return total_value

# 获取所有活跃debuff效果的总和
func get_active_debuff_value(effect_type_id: String) -> float:
	var total_value = 0.0
	
	for debuff in active_debuffs:
		if debuff.effect_type_id == effect_type_id:
			total_value += debuff.value
			
	return total_value

# 检查是否有特定类型的buff活跃
func has_active_buff(effect_type_id: String) -> bool:
	for buff in active_term_buffs:
		if buff.effect_type_id == effect_type_id:
			return true
	
	for buff in active_turn_buffs:
		if buff.effect_type_id == effect_type_id:
			return true
			
	return false

# 获取所有当前活跃的效果 (新方法，符合阶段二要求)
func get_active_effects() -> Dictionary:
	var effects = {
		"score_modifier": 0,
		"draw_modifier": 0,
		"score_multiplier": 1.0,
		"hand_size_modifier": 0
	}
	
	# 计算各种buff和debuff
	effects.score_modifier = get_active_buff_value("score_modifier") + get_active_debuff_value("score_modifier")
	effects.draw_modifier = get_active_buff_value("draw_modifier") + get_active_debuff_value("draw_modifier")
	effects.score_multiplier = get_active_buff_value("score_multiplier") * (1.0 + get_active_debuff_value("score_multiplier"))
	effects.hand_size_modifier = get_active_buff_value("hand_size_modifier") + get_active_debuff_value("hand_size_modifier")
	
	return effects

# 辅助函数：随机选择事件ID
func _select_random_event() -> String:
	if random_events.is_empty():
		return ""
		
	# 基于权重选择事件
	var total_weight = 0
	for event in random_events:
		total_weight += event.get("weight", 1)
		
	var rand_val = randi() % total_weight
	var acc_weight = 0
		
	for event in random_events:
		acc_weight += event.get("weight", 1)
		if rand_val < acc_weight:
			return event.id
			
	return random_events[0].id

# 辅助函数：获取事件数据
func _get_event_data(event_id: String) -> Dictionary:
	for event in random_events:
		if event.id == event_id:
			return event
	return {}

# 辅助函数：应用事件效果
func _apply_event_effects(event_data: Dictionary) -> void:
	match event_data.effect:
		"lore_points_bonus":
			if game_manager != null:
				# game_manager.add_lore_points(event_data.value) # 待GameManager重构后实现
				pass
		"score_penalty", "score_bonus":
			add_buff("score_modifier", event_data.value, event_data.get("duration", 1))
		"temp_draw_bonus":
			add_buff("draw_modifier", event_data.value, event_data.get("duration", 1))
		"score_multiplier": 
			add_buff("score_multiplier", event_data.value, event_data.get("duration", 1))
		"hand_size_penalty":
			add_debuff("hand_size_modifier", event_data.value, event_data.get("duration", 1))

# 辅助函数：应用奥术直觉成功奖励
func _apply_arcane_intuition_success() -> void:
	if game_manager == null:
		return
		
	# 增加传说点数
	# game_manager.add_lore_points(25) # 待GameManager重构后实现
	
	# 添加buff
	add_buff("score_multiplier", 1.5, 3)
	
	print("EventManager: 应用奥术直觉成功奖励")

# 辅助函数：应用奥术直觉失败惩罚
func _apply_arcane_intuition_failure() -> void:
	if game_manager == null:
		return
		
	# 添加debuff
	add_debuff("hand_size_modifier", -1, 2)
	
	print("EventManager: 应用奥术直觉失败惩罚")

# 辅助函数：应用事件效果
func _apply_event_effect(event: Dictionary) -> void:
	match event.effect:
		"lore_points_bonus":
			# 增加传说点数（由GameManager处理）
			if game_manager:
				# game_manager.add_lore_points(event.value) # 待GameManager重构后实现
				pass
		"score_penalty", "score_bonus":
			# 分数惩罚或奖励
			add_buff("score_modifier", event.value, event.get("duration", 1))
		"temp_draw_bonus":
			# 临时增加抽牌数
			add_buff("draw_modifier", event.value, event.get("duration", 1))
		"score_multiplier":
			# 分数倍率
			add_buff("score_multiplier", event.value, event.get("duration", 1))
		"hand_size_penalty":
			# 手牌上限惩罚
			add_debuff("hand_size_modifier", event.value, event.get("duration", 2)) 
