class_name WisdomHallManager
extends Node

# 预加载类型
const GlobalEnumsType = preload("res://cs/Global/GlobalEnums.gd")

# 商店状态
var available_items = []  # 当前可购买的物品列表
var current_shop_tier = 0  # 当前商店等级（影响稀有度概率）

# 信号
signal shop_refreshed(available_items)  # 商店更新
signal item_purchased(item_data, cost)  # 物品购买

# 引用
var game_manager = null
var effect_orchestrator = null

# 配置信息
var shop_config = {
	"max_items": 4,  # 每次显示的商品数量
	"refresh_cost": 10,  # 手动刷新费用
	"rarity_probabilities": {
		# 稀有度概率随商店等级提升
		0: {  # Tier 0
			"common": 0.7,
			"rare": 0.25,
			"epic": 0.05,
			"legendary": 0.0
		},
		1: {  # Tier 1
			"common": 0.55,
			"rare": 0.35,
			"epic": 0.09,
			"legendary": 0.01
		},
		2: {  # Tier 2
			"common": 0.40,
			"rare": 0.40,
			"epic": 0.15,
			"legendary": 0.05
		},
		3: {  # Tier 3
			"common": 0.30,
			"rare": 0.40,
			"epic": 0.20,
			"legendary": 0.10
		}
	},
	"cost_ranges": {
		"common": {"min": 10, "max": 30},
		"rare": {"min": 30, "max": 60},
		"epic": {"min": 60, "max": 100},
		"legendary": {"min": 100, "max": 200}
	},
	"item_type_weights": {
		"artifact": 0.40,  # 法器
		"spell": 0.40,     # 法术
		"joker": 0.20      # 守护灵
	}
}

# 引用所有可用物品资源
var all_artifacts = []
var all_spells = []
var all_jokers = []

func _init(game_scene):
	game_manager = get_node_or_null("/root/GameManager") 
	
	# 设置引用
	if game_scene and game_scene.has_method("get_effect_orchestrator"):
		effect_orchestrator = game_scene.get_effect_orchestrator()

func _ready():
	# 加载所有物品资源
	_load_all_item_resources()
	
	# 初始刷新商店
	refresh_shop_offers()

# 加载所有物品资源
func _load_all_item_resources():
	# 加载法器
	var artifact_dir = DirAccess.open("res://assets/data/artifacts")
	if artifact_dir:
		artifact_dir.list_dir_begin()
		var file_name = artifact_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var artifact_data = load("res://assets/data/artifacts/" + file_name)
				if artifact_data is ArtifactData:
					all_artifacts.append(artifact_data)
			file_name = artifact_dir.get_next()
	
	# 加载法术
	var spell_dir = DirAccess.open("res://assets/data/spells")
	if spell_dir:
		spell_dir.list_dir_begin()
		var file_name = spell_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var spell_data = load("res://assets/data/spells/" + file_name)
				if spell_data is SpellData:
					all_spells.append(spell_data)
			file_name = spell_dir.get_next()
	
	# 加载守护灵
	var joker_dir = DirAccess.open("res://assets/data/jokers")
	if joker_dir:
		joker_dir.list_dir_begin()
		var file_name = joker_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var joker_data = load("res://assets/data/jokers/" + file_name)
				if joker_data is JokerData:
					all_jokers.append(joker_data)
			file_name = joker_dir.get_next()
	
	print("WisdomHallManager: 加载了 %d 个法器, %d 个法术, %d 个守护灵" % 
		[all_artifacts.size(), all_spells.size(), all_jokers.size()])

# 刷新商店商品
func refresh_shop_offers():
	available_items.clear()
	
	# 确定要生成的商品数量
	var item_count = shop_config.max_items
	
	# 生成商品
	for i in range(item_count):
		var item = _generate_random_item()
		if item:
			available_items.append(item)
	
	emit_signal("shop_refreshed", available_items)
	
	print("WisdomHallManager: 刷新商店，生成 %d 个可购买物品" % available_items.size())
	return available_items

# 购买物品
func purchase(item_id: String) -> bool:
	if not game_manager:
		push_error("WisdomHallManager: 无法获取GameManager引用")
		return false
	
	# 查找物品
	var item_data = null
	var item_index = -1
	
	for i in range(available_items.size()):
		var item = available_items[i]
		if item.item_id == item_id:
			item_data = item
			item_index = i
			break
	
	if not item_data:
		push_error("WisdomHallManager: 未找到ID为 %s 的物品" % item_id)
		return false
	
	# 检查是否有足够的传说点数
	var cost = item_data.purchase_cost
	if game_manager.get_lore_points() < cost:
		push_error("WisdomHallManager: 传说点数不足，需要 %d，当前 %d" % 
			[cost, game_manager.get_lore_points()])
		return false
	
	# 扣除传说点数
	game_manager.add_lore_points(-cost)
	
	# 添加物品到玩家物品栏
	var success = false
	if item_data is ArtifactData:
		success = game_manager.add_artifact(item_data)
	elif item_data is SpellData:
		success = game_manager.add_spell(item_data)
	elif item_data is JokerData:
		success = game_manager.add_joker(item_data)
	
	if not success:
		# 如果添加失败，退还传说点数
		game_manager.add_lore_points(cost)
		push_error("WisdomHallManager: 添加物品失败")
		return false
	
	# 应用物品效果
	if effect_orchestrator:
		if item_data is ArtifactData and item_data.effect_type_id.begins_with("INSTANT_"):
			effect_orchestrator.trigger_artifact_effect(item_data)
		elif item_data is SpellData and item_data.spell_cast_type == GlobalEnumsType.SpellType.INSTANT_USE:
			effect_orchestrator.trigger_spell_effect(item_data)
	
	# 从商店移除已购买物品
	available_items.remove_at(item_index)
	
	# 发送购买信号
	emit_signal("item_purchased", item_data, cost)
	print("WisdomHallManager: 购买物品 %s，花费 %d 传说点数" % [item_data.item_name, cost])
	
	return true

# 手动刷新商店（花费传说点数）
func manual_refresh() -> bool:
	if not game_manager:
		push_error("WisdomHallManager: 无法获取GameManager引用")
		return false
	
	# 检查是否有足够的传说点数
	var refresh_cost = shop_config.refresh_cost
	if game_manager.get_lore_points() < refresh_cost:
		push_error("WisdomHallManager: 传说点数不足，需要 %d，当前 %d" % 
			[refresh_cost, game_manager.get_lore_points()])
		return false
	
	# 扣除传说点数
	game_manager.add_lore_points(-refresh_cost)
	
	# 刷新商店
	refresh_shop_offers()
	
	print("WisdomHallManager: 手动刷新商店，花费 %d 传说点数" % refresh_cost)
	return true

# 升级商店等级
func upgrade_shop_tier() -> bool:
	if current_shop_tier >= 3:  # 最高等级为3
		print("WisdomHallManager: 商店已达到最高等级")
		return false
	
	current_shop_tier += 1
	print("WisdomHallManager: 商店等级提升至 %d" % current_shop_tier)
	
	# 刷新商店，以便应用新的稀有度概率
	refresh_shop_offers()
	
	return true

# 生成随机商品
func _generate_random_item():
	# 随机决定物品类型
	var item_type = _select_random_item_type()
	
	# 根据当前商店等级确定稀有度概率表
	var rarity_table = shop_config.rarity_probabilities[current_shop_tier]
	
	# 随机稀有度
	var rarity = _select_random_rarity(rarity_table)
	
	# 根据稀有度决定价格范围
	var price_range = shop_config.cost_ranges[rarity]
	var cost = randi() % (price_range.max - price_range.min + 1) + price_range.min
	
	# 将稀有度字符串转换为枚举值
	var rarity_enum = _rarity_string_to_enum(rarity)
	
	# 根据物品类型、稀有度筛选并随机选择一个物品
	var item = null
	match item_type:
		"artifact":
			item = _select_random_artifact(rarity_enum)
		"spell":
			item = _select_random_spell(rarity_enum)
		"joker":
			item = _select_random_joker(rarity_enum)
	
	if item:
		# 克隆物品并设置价格
		var cloned_item = null
		if item is ArtifactData:
			cloned_item = item.clone()
		elif item is SpellData:
			cloned_item = item.clone()
		elif item is JokerData:
			cloned_item = item.clone()
		
		if cloned_item:
			cloned_item.purchase_cost = cost
			return cloned_item
	
	return null

# 选择随机物品类型
func _select_random_item_type() -> String:
	var weights = shop_config.item_type_weights
	var total_weight = 0.0
	
	for type in weights:
		total_weight += weights[type]
	
	var rand = randf() * total_weight
	var cumulative = 0.0
	
	for type in weights:
		cumulative += weights[type]
		if rand <= cumulative:
			return type
	
	# 默认返回法器
	return "artifact"

# 根据概率选择稀有度
func _select_random_rarity(rarity_table: Dictionary) -> String:
	var rand = randf()
	var cumulative = 0.0
	
	for rarity in rarity_table:
		cumulative += rarity_table[rarity]
		if rand <= cumulative:
			return rarity
	
	# 默认返回普通稀有度
	return "common"

# 将稀有度字符串转换为枚举值
func _rarity_string_to_enum(rarity: String) -> int:
	match rarity:
		"common":
			return GlobalEnumsType.Rarity.COMMON
		"rare":
			return GlobalEnumsType.Rarity.RARE
		"epic":
			return GlobalEnumsType.Rarity.EPIC
		"legendary":
			return GlobalEnumsType.Rarity.LEGENDARY
	
	# 默认普通稀有度
	return GlobalEnumsType.Rarity.COMMON

# 从法器池中选择指定稀有度的随机法器
func _select_random_artifact(rarity: int) -> ArtifactData:
	var filtered_artifacts = []
	
	for artifact in all_artifacts:
		if artifact.rarity_type == rarity:
			filtered_artifacts.append(artifact)
	
	if filtered_artifacts.is_empty():
		# 如果没有找到指定稀有度的法器，返回普通稀有度的
		for artifact in all_artifacts:
			if artifact.rarity_type == GlobalEnumsType.Rarity.COMMON:
				filtered_artifacts.append(artifact)
	
	if filtered_artifacts.is_empty():
		return null
	
	return filtered_artifacts[randi() % filtered_artifacts.size()]

# 从法术池中选择指定稀有度的随机法术
func _select_random_spell(rarity: int) -> SpellData:
	var filtered_spells = []
	
	for spell in all_spells:
		if spell.rarity_type == rarity:
			filtered_spells.append(spell)
	
	if filtered_spells.is_empty():
		# 如果没有找到指定稀有度的法术，返回普通稀有度的
		for spell in all_spells:
			if spell.rarity_type == GlobalEnumsType.Rarity.COMMON:
				filtered_spells.append(spell)
	
	if filtered_spells.is_empty():
		return null
	
	return filtered_spells[randi() % filtered_spells.size()]

# 从守护灵池中选择指定稀有度的随机守护灵
func _select_random_joker(rarity: int) -> JokerData:
	var filtered_jokers = []
	
	for joker in all_jokers:
		if joker.rarity_type == rarity:
			filtered_jokers.append(joker)
	
	if filtered_jokers.is_empty():
		# 如果没有找到指定稀有度的守护灵，返回普通稀有度的
		for joker in all_jokers:
			if joker.rarity_type == GlobalEnumsType.Rarity.COMMON:
				filtered_jokers.append(joker)
	
	if filtered_jokers.is_empty():
		return null
	
	return filtered_jokers[randi() % filtered_jokers.size()] 