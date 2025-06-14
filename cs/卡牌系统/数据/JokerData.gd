class_name JokerData
extends RefCounted

# 小丑卡数据库
static var joker_database = {
	"common_joker": {
		"name": "普通小丑",
		"type": "common_joker",
		"description": "基础小丑卡",
		"effect_description": "每回合获得1点额外集中力",
		"rarity": 1
	},
	"greedy_joker": {
		"name": "贪婪小丑",
		"type": "greedy_joker",
		"description": "渴望金币的小丑",
		"effect_description": "每次获得学识点时额外获得1点",
		"rarity": 2
	}
}

# 小丑卡基础属性
var id: int = 0                    # 小丑卡ID
var name: String = ""              # 名称
var image_name: String = ""        # 图像文件名
var type: String = "common"        # 类型：common（普通）, rare（稀有）, legendary（传奇）, negative（负面）, special（特殊）
var joker_type: String = "trickster" # 小丑类型：trickster（诡术师）, jester（弄臣）, fool（愚者）
var effect_description: String = "" # 效果描述
var effect_type: String = ""        # 效果类型
var effect_value: int = 0           # 效果数值
var passive_script: Script = null   # 被动效果脚本，实现 ICardEffect

# 游戏属性
var power: int = 0                  # 能量值
var cooldown: int = 0               # 当前冷却回合数
var max_cooldown: int = 3           # 最大冷却回合数
var display_name: String = ""       # 显示名称

# 构造函数
func _init(joker_id: int = 0, joker_name: String = "", joker_image: String = ""):
	id = joker_id
	name = joker_name
	image_name = joker_image if joker_image else joker_name.to_lower().replace(" ", "_")
	display_name = name
	
	# 根据ID设置属性
	_setup_from_id(joker_id)
	
# 根据ID设置小丑卡属性
func _setup_from_id(joker_id: int) -> void:
	if joker_id <= 0:
		return
	
	# 设置小丑类型和能量
	match joker_id % 3:
		0:
			joker_type = "trickster"  # 诡术师
			power = 5 + int(joker_id / 3.0)
			max_cooldown = 3
		1:
			joker_type = "jester"     # 弄臣
			power = 3 + int(joker_id / 2.0)
			max_cooldown = 2
		2:
			joker_type = "fool"       # 愚者
			power = 4 + int(joker_id / 4.0)
			max_cooldown = 4
	
	# 根据ID设置稀有度
	if joker_id <= 5:
		type = "common"
	elif joker_id <= 10:
		type = "rare"
	elif joker_id <= 15:
		type = "legendary"
	else:
		type = "special"
	
	# 设置效果描述
	match joker_type:
		"trickster":
			effect_description = "对所有敌人造成%d点伤害" % power
		"jester":
			effect_description = "抽取%d张卡牌" % int(power / 2.0 + 1.0)
		"fool":
			effect_description = "获得%d点护盾" % (power * 2)
	
# 设置效果
func set_effect(description: String, effect: String, value: int = 0):
	effect_description = description
	effect_type = effect
	effect_value = value

# 设置类型
func set_type(type_name: String):
	type = type_name

# 检查是否可以激活
func can_activate() -> bool:
	return cooldown <= 0

# 激活小丑效果
func activate() -> void:
	if can_activate():
		cooldown = max_cooldown
		print("%s 激活效果，进入冷却状态 (%d回合)" % [name, cooldown])

# 回合开始时处理
func on_turn_start() -> void:
	if cooldown > 0:
		cooldown -= 1
		print("%s 冷却中，剩余%d回合" % [name, cooldown])

# 回合结束时处理
func on_turn_end() -> void:
	# 可以在这里添加回合结束时的效果
	pass

# 应用效果
func apply_effect():
	# 基类中为空实现，子类可覆盖
	print("应用小丑牌 [%s] 的效果: %s" % [name, effect_description])
	
	# 这里可以根据effect_type执行不同的效果
	match effect_type:
		"score_multiply":
			# 可以发送信号给GameManager应用效果
			pass
		"card_draw":
			# 抽牌效果
			pass
		"card_discard":
			# 弃牌效果
			pass
		"card_transform":
			# 变换卡牌效果
			pass
		"focus_modify":
			# 修改集中力效果
			pass
		"essence_modify":
			# 修改精华效果
			pass
		_:
			# 默认行为
			pass

# 获取效果信息
func get_effect_info() -> String:
	return effect_description

# 序列化数据，用于存档
func serialize() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"image_name": image_name,
		"type": type,
		"joker_type": joker_type,
		"effect_description": effect_description,
		"effect_type": effect_type,
		"effect_value": effect_value,
		"power": power,
		"cooldown": cooldown,
		"max_cooldown": max_cooldown
	}

# 从序列化数据恢复
func deserialize(data: Dictionary) -> void:
	id = data.id
	name = data.name
	image_name = data.image_name
	type = data.type
	joker_type = data.joker_type
	effect_description = data.effect_description
	effect_type = data.effect_type
	effect_value = data.effect_value
	power = data.power
	cooldown = data.cooldown
	max_cooldown = data.max_cooldown
	display_name = name

# 创建小丑卡
static func create_joker(joker_id: String) -> Dictionary:
	if joker_database.has(joker_id):
		# 复制数据，避免修改原始数据
		var joker_data = joker_database[joker_id].duplicate(true)
		return joker_data
	else:
		# 返回默认小丑卡
		return {
			"name": "未知小丑",
			"type": "common_joker",
			"description": "神秘的小丑卡",
			"effect_description": "无特殊效果",
			"rarity": 1
		}

# 获取随机小丑卡
static func get_random_joker() -> Dictionary:
	var keys = joker_database.keys()
	var random_index = randi() % keys.size()
	var random_key = keys[random_index]
	
	return create_joker(random_key)

# 获取多个随机小丑卡
static func get_random_jokers(count: int) -> Array:
	var result = []
	var keys = joker_database.keys()
	
	# 如果请求数量超过可用数量，返回所有
	if count >= keys.size():
		for key in keys:
			result.append(create_joker(key))
		return result
	
	# 否则随机选择不重复的
	var available_keys = keys.duplicate()
	for i in range(count):
		var random_index = randi() % available_keys.size()
		var random_key = available_keys[random_index]
		
		result.append(create_joker(random_key))
		available_keys.remove_at(random_index)
	
	return result 
