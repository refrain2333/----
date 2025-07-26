class_name CardLibraryManager
extends RefCounted

# 基于预制数据文件的卡牌库管理器
# 负责加载、管理和创建卡牌实例

const CARDS_DATA_PATH = "res://assets/data/cards/"

# 卡牌库缓存
static var _card_library: Dictionary = {}
static var _is_loaded: bool = false

# 加载所有卡牌数据到内存
static func load_card_library():
	"""
	从assets/data/cards/目录加载所有卡牌数据
	只需要调用一次，数据会缓存在内存中
	"""
	if _is_loaded:
		print("CardLibraryManager: 卡牌库已加载，跳过重复加载")
		return
	
	print("CardLibraryManager: 开始加载卡牌库...")
	_card_library.clear()
	
	# 获取cards目录下的所有.tres文件
	var dir = DirAccess.open(CARDS_DATA_PATH)
	if not dir:
		push_error("CardLibraryManager: 无法打开卡牌数据目录: " + CARDS_DATA_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var loaded_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card_path = CARDS_DATA_PATH + file_name
			var card_data = load(card_path) as CardData
			
			if card_data:
				_card_library[card_data.id] = card_data
				loaded_count += 1
				print("  加载卡牌: %s (%s)" % [card_data.name, card_data.id])
			else:
				push_warning("CardLibraryManager: 加载失败: " + card_path)
		
		file_name = dir.get_next()
	
	_is_loaded = true
	print("CardLibraryManager: 卡牌库加载完成，共 %d 张卡牌" % loaded_count)

# 获取指定ID的卡牌数据
static func get_card_data(card_id: String) -> CardData:
	"""
	获取指定ID的卡牌数据
	
	参数:
		card_id: 卡牌ID，如"H3", "D11"
	
	返回:
		CardData: 卡牌数据，如果不存在返回null
	"""
	if not _is_loaded:
		load_card_library()
	
	if card_id in _card_library:
		# 返回克隆的数据，避免修改原始数据
		return _card_library[card_id].clone()
	else:
		push_warning("CardLibraryManager: 未找到卡牌: " + card_id)
		return null

# 获取所有卡牌ID列表
static func get_all_card_ids() -> Array[String]:
	"""获取所有可用的卡牌ID"""
	if not _is_loaded:
		load_card_library()
	
	var ids: Array[String] = []
	for id in _card_library.keys():
		ids.append(id)
	
	return ids

# 按花色获取卡牌ID列表
static func get_cards_by_suit(suit: String) -> Array[String]:
	"""
	获取指定花色的所有卡牌ID
	
	参数:
		suit: 花色 ("hearts", "diamonds", "clubs", "spades")
	
	返回:
		Array[String]: 该花色的所有卡牌ID
	"""
	if not _is_loaded:
		load_card_library()
	
	var suit_cards: Array[String] = []
	
	for card_id in _card_library.keys():
		var card_data = _card_library[card_id]
		if card_data.suit == suit:
			suit_cards.append(card_id)
	
	# 按数值排序
	suit_cards.sort_custom(func(a, b): return _card_library[a].base_value < _card_library[b].base_value)
	
	return suit_cards

# 按数值范围获取卡牌
static func get_cards_by_value_range(min_value: int, max_value: int) -> Array[String]:
	"""
	获取指定数值范围的卡牌ID
	
	参数:
		min_value: 最小数值
		max_value: 最大数值
	
	返回:
		Array[String]: 符合条件的卡牌ID
	"""
	if not _is_loaded:
		load_card_library()
	
	var range_cards: Array[String] = []
	
	for card_id in _card_library.keys():
		var card_data = _card_library[card_id]
		if card_data.base_value >= min_value and card_data.base_value <= max_value:
			range_cards.append(card_id)
	
	return range_cards

# 创建标准52张牌的牌库
static func create_standard_deck() -> Array[CardData]:
	"""
	创建标准52张扑克牌的牌库
	
	返回:
		Array[CardData]: 包含52张卡牌数据的数组
	"""
	if not _is_loaded:
		load_card_library()
	
	var deck: Array[CardData] = []
	var all_ids = get_all_card_ids()
	
	for card_id in all_ids:
		var card_data = get_card_data(card_id)
		if card_data:
			deck.append(card_data)
	
	print("CardLibraryManager: 创建标准牌库，共 %d 张卡牌" % deck.size())
	return deck

# 创建自定义牌库
static func create_custom_deck(card_ids: Array[String]) -> Array[CardData]:
	"""
	根据指定的卡牌ID列表创建自定义牌库
	
	参数:
		card_ids: 要包含的卡牌ID数组
	
	返回:
		Array[CardData]: 自定义牌库
	"""
	if not _is_loaded:
		load_card_library()
	
	var deck: Array[CardData] = []
	
	for card_id in card_ids:
		var card_data = get_card_data(card_id)
		if card_data:
			deck.append(card_data)
		else:
			push_warning("CardLibraryManager: 跳过无效卡牌ID: " + card_id)
	
	print("CardLibraryManager: 创建自定义牌库，共 %d 张卡牌" % deck.size())
	return deck

# 创建多副牌库（某些卡牌可以有多张）
static func create_multi_deck(card_counts: Dictionary) -> Array[CardData]:
	"""
	创建包含多张相同卡牌的牌库
	
	参数:
		card_counts: 卡牌数量字典，格式: {"H3": 2, "D11": 3, ...}
	
	返回:
		Array[CardData]: 包含指定数量卡牌的牌库
	"""
	if not _is_loaded:
		load_card_library()
	
	var deck: Array[CardData] = []
	
	for card_id in card_counts.keys():
		var count = card_counts[card_id]
		
		for i in range(count):
			var card_data = get_card_data(card_id)
			if card_data:
				deck.append(card_data)
			else:
				push_warning("CardLibraryManager: 跳过无效卡牌ID: " + card_id)
	
	print("CardLibraryManager: 创建多副牌库，共 %d 张卡牌" % deck.size())
	return deck

# 获取卡牌库统计信息
static func get_library_stats() -> Dictionary:
	"""获取卡牌库的统计信息"""
	if not _is_loaded:
		load_card_library()
	
	var stats = {
		"total_cards": _card_library.size(),
		"suits": {},
		"values": {}
	}
	
	# 统计花色分布
	for card_data in _card_library.values():
		var suit = card_data.suit
		if suit in stats.suits:
			stats.suits[suit] += 1
		else:
			stats.suits[suit] = 1
		
		# 统计数值分布
		var value = card_data.base_value
		if value in stats.values:
			stats.values[value] += 1
		else:
			stats.values[value] = 1
	
	return stats

# 验证卡牌库完整性
static func validate_library() -> bool:
	"""验证卡牌库是否包含完整的52张标准扑克牌"""
	if not _is_loaded:
		load_card_library()
	
	var expected_cards = []
	var suits = ["S", "H", "D", "C"]
	
	# 生成期望的52张牌ID
	for suit in suits:
		for value in range(1, 14):
			expected_cards.append(suit + str(value))
	
	var missing_cards = []
	for expected_id in expected_cards:
		if not expected_id in _card_library:
			missing_cards.append(expected_id)
	
	if missing_cards.size() > 0:
		push_warning("CardLibraryManager: 缺少卡牌: " + str(missing_cards))
		return false
	
	print("CardLibraryManager: 卡牌库验证通过，包含完整的52张标准扑克牌")
	return true
