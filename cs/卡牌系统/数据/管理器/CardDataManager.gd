class_name CardDataManager
extends RefCounted

# 卡牌数据管理器 - 负责加载、管理、修改预制卡牌数据

# 单例实例
static var instance: CardDataManager = null

# 数据存储
var all_cards: Dictionary = {}           # 所有卡牌数据 {id: CardData}
var cards_by_type: Dictionary = {}       # 按类型分组 {type: Array[CardData]}
var cards_by_rarity: Dictionary = {}     # 按稀有度分组 {rarity: Array[CardData]}

# 路径配置
const CARDS_DATA_PATH = "res://assets/data/cards/"

# 获取单例
static func get_instance() -> CardDataManager:
	if instance == null:
		instance = CardDataManager.new()
		instance.load_all_cards()
	return instance

# 加载所有卡牌数据
func load_all_cards():
	print("CardDataManager: 开始加载卡牌数据")
	
	# 清空现有数据
	all_cards.clear()
	cards_by_type.clear()
	cards_by_rarity.clear()
	
	# 扫描卡牌数据目录
	var dir = DirAccess.open(CARDS_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				load_card_file(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	# 构建索引
	build_indexes()
	
	print("CardDataManager: 加载完成，共 %d 张卡牌" % all_cards.size())

# 加载单个卡牌文件
func load_card_file(file_name: String):
	var file_path = CARDS_DATA_PATH + file_name
	
	if ResourceLoader.exists(file_path):
		var card_data = load(file_path) as CardData
		
		if card_data and card_data.id != "":
			all_cards[card_data.id] = card_data
			print("  加载卡牌: %s (%s)" % [card_data.name, card_data.id])
		else:
			print("  警告: 无效的卡牌数据文件 - %s" % file_name)
	else:
		print("  错误: 卡牌文件不存在 - %s" % file_path)

# 构建索引
func build_indexes():
	print("CardDataManager: 构建索引")
	
	for card_data in all_cards.values():
		# 按类型分组
		if not cards_by_type.has(card_data.card_type):
			cards_by_type[card_data.card_type] = []
		cards_by_type[card_data.card_type].append(card_data)
		
		# 按稀有度分组
		if not cards_by_rarity.has(card_data.rarity):
			cards_by_rarity[card_data.rarity] = []
		cards_by_rarity[card_data.rarity].append(card_data)

# 获取卡牌数据
func get_card(card_id: String) -> CardData:
	return all_cards.get(card_id, null)

# 获取所有卡牌
func get_all_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in all_cards.values():
		cards.append(card)
	return cards

# 按类型获取卡牌
func get_cards_by_type(card_type: String) -> Array[CardData]:
	return cards_by_type.get(card_type, [])

# 按稀有度获取卡牌
func get_cards_by_rarity(rarity: String) -> Array[CardData]:
	return cards_by_rarity.get(rarity, [])

# 创建牌库（考虑数量配置）
func create_deck_from_config(deck_config: Dictionary) -> Array[CardData]:
	"""
	根据配置创建牌库
	deck_config 格式: {"card_id": count, ...}
	例如: {"H3": 2, "S7": 1, "D11": 3}
	"""
	var deck: Array[CardData] = []
	
	for card_id in deck_config:
		var count = deck_config[card_id]
		var card_data = get_card(card_id)
		
		if card_data:
			# 检查数量限制
			var max_count = min(count, card_data.max_in_deck)
			
			for i in range(max_count):
				# 克隆卡牌数据（避免修改原始数据）
				var card_copy = card_data.clone()
				deck.append(card_copy)
			
			print("添加到牌库: %s x%d" % [card_data.name, max_count])
		else:
			print("警告: 未找到卡牌 %s" % card_id)
	
	return deck

# 创建标准牌库
func create_standard_deck() -> Array[CardData]:
	"""创建包含所有卡牌的标准牌库"""
	var deck: Array[CardData] = []
	
	for card_data in all_cards.values():
		for i in range(card_data.deck_count):
			var card_copy = card_data.clone()
			deck.append(card_copy)
	
	return deck

# 修改卡牌属性（运行时）
func modify_card_damage(card_id: String, new_damage: int):
	"""修改卡牌伤害值"""
	var card_data = get_card(card_id)
	if card_data:
		var old_damage = card_data.damage
		card_data.damage = new_damage
		print("修改卡牌伤害: %s %d -> %d" % [card_data.name, old_damage, new_damage])

func modify_card_cost(card_id: String, new_cost: int):
	"""修改卡牌消耗"""
	var card_data = get_card(card_id)
	if card_data:
		var old_cost = card_data.cost
		card_data.cost = new_cost
		print("修改卡牌消耗: %s %d -> %d" % [card_data.name, old_cost, new_cost])

# 保存修改到文件（可选）
func save_card_to_file(card_data: CardData):
	"""将修改后的卡牌数据保存到文件"""
	var file_path = CARDS_DATA_PATH + card_data.id.to_lower() + ".tres"
	var result = ResourceSaver.save(card_data, file_path)
	
	if result == OK:
		print("保存卡牌数据成功: %s" % file_path)
	else:
		print("保存卡牌数据失败: %s" % file_path)

# 获取统计信息
func get_statistics() -> Dictionary:
	return {
		"total_cards": all_cards.size(),
		"types": cards_by_type.keys(),
		"rarities": cards_by_rarity.keys(),
		"type_counts": _get_type_counts(),
		"rarity_counts": _get_rarity_counts()
	}

func _get_type_counts() -> Dictionary:
	var counts = {}
	for type in cards_by_type:
		counts[type] = cards_by_type[type].size()
	return counts

func _get_rarity_counts() -> Dictionary:
	var counts = {}
	for rarity in cards_by_rarity:
		counts[rarity] = cards_by_rarity[rarity].size()
	return counts

# 重新加载数据
func reload():
	load_all_cards()
