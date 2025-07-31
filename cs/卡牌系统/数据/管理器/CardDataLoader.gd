class_name CardDataLoader
extends RefCounted

## 🎯 卡牌数据加载器 (V2.1 - 标准牌库版本)
##
## 核心功能：
## - 使用StandardDeckManager管理标准52张扑克牌
## - 提供标准化的卡牌数据访问接口
## - 支持按花色、数值、ID等方式查询卡牌
## - 兼容原有接口，无缝升级

# 导入标准牌库管理器
const StandardDeckManagerClass = preload("res://cs/卡牌系统/数据/管理器/StandardDeckManager.gd")

# 标准扑克牌定义
const STANDARD_SUITS = ["hearts", "diamonds", "clubs", "spades"]
const STANDARD_VALUES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]  # 标准面值1-13
const STANDARD_BASE_VALUES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]  # 允许的base_value（A可以是14）

# 卡牌数据缓存（现在基于标准牌库）
static var _card_cache: Dictionary = {}
static var _cards_by_suit: Dictionary = {}
static var _cards_by_value: Dictionary = {}
static var _variant_cards: Array = []
static var _test_cards: Array = []
static var _all_cards: Array = []
static var _is_initialized: bool = false

## 🎯 初始化卡牌数据（使用标准牌库管理器）
static func initialize():
	if _is_initialized:
		return

	print("🃏 开始加载标准卡牌数据...")
	var start_time = Time.get_ticks_msec()

	_card_cache.clear()
	_cards_by_suit.clear()
	_cards_by_value.clear()

	# 初始化标准牌库管理器
	StandardDeckManagerClass.initialize()

	# 获取标准卡牌并注册到缓存
	var standard_cards = StandardDeckManagerClass.get_standard_deck()
	for card in standard_cards:
		_register_card(card)

	# 验证标准牌库完整性
	var validation = StandardDeckManagerClass.validate_deck_integrity()

	var end_time = Time.get_ticks_msec()
	var load_time = end_time - start_time

	_is_initialized = true

	if validation.is_valid:
		print("✅ 标准卡牌数据加载完成: %d张卡牌, 耗时%dms" % [_card_cache.size(), load_time])
	else:
		print("❌ 标准牌库不完整: 缺少%d张卡牌" % validation.missing_cards.size())
		print("   缺失卡牌: %s" % str(validation.missing_cards))

	# 打印统计信息
	_print_statistics()

## 🔧 加载所有卡牌文件
static func _load_all_card_files():
	# 加载标准卡牌
	_load_cards_from_directory("res://assets/data/cards/")

	# 加载特殊卡牌
	_load_cards_from_directory("res://assets/data/cards/special/")

## 🔧 从指定目录加载卡牌
static func _load_cards_from_directory(cards_dir: String):
	var dir = DirAccess.open(cards_dir)

	if not dir:
		# 特殊文件夹可能不存在，这是正常的
		if cards_dir.ends_with("special/"):
			print("📦 特殊卡牌文件夹不存在，跳过: %s" % cards_dir)
			return
		else:
			push_error("无法打开卡牌数据目录: %s" % cards_dir)
			return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var card_path = cards_dir + file_name
			var card_data = load(card_path) as CardData

			if card_data:
				_all_cards.append(card_data)
			else:
				push_warning("无法加载卡牌数据: %s" % card_path)

		file_name = dir.get_next()

	dir.list_dir_end()

## 🔧 分类卡牌
static func _classify_cards():
	for card in _all_cards:
		if _is_standard_card(card):
			# 标准卡牌不需要特别存储，会在_get_standard_cards中获取
			pass
		elif _is_variant_card(card):
			_variant_cards.append(card)
		else:
			_test_cards.append(card)

## 🔧 获取标准卡牌
static func _get_standard_cards() -> Array:
	var standard_cards = []
	for card in _all_cards:
		if _is_standard_card(card):
			standard_cards.append(card)
	return standard_cards

## 🔧 判断是否为标准卡牌
static func _is_standard_card(card: CardData) -> bool:
	# 检查花色是否标准
	if not STANDARD_SUITS.has(card.suit):
		return false

	# 检查base_value是否在允许范围内
	if not STANDARD_BASE_VALUES.has(card.base_value):
		return false

	# 检查是否有强化属性（标准卡牌不应该有强化）
	if not card.wax_seals.is_empty() or not card.frame_type.is_empty() or not card.material_type.is_empty():
		return false

	# 检查ID格式是否标准（例如：H1, D2, C13, S10）
	# 使用面值（从ID提取）而不是base_value来验证
	var face_value = card.get_face_value()
	if not STANDARD_VALUES.has(face_value):
		return false

	var expected_id = _get_standard_card_id(card.suit, face_value)
	if card.id != expected_id:
		return false

	return true

## 🔧 判断是否为变体卡牌
static func _is_variant_card(card: CardData) -> bool:
	# 变体卡牌：有强化属性或特殊命名的标准牌
	if not card.wax_seals.is_empty() or not card.frame_type.is_empty() or not card.material_type.is_empty():
		return true

	# 检查是否为标准牌的变体版本（如：H3_Enhanced）
	if "_" in card.id:
		var base_id = card.id.split("_")[0]
		return _is_valid_base_card_id(base_id)

	return false

## 🔧 获取标准卡牌ID
static func _get_standard_card_id(suit: String, value: int) -> String:
	var suit_prefix = ""
	match suit:
		"hearts": suit_prefix = "H"
		"diamonds": suit_prefix = "D"
		"clubs": suit_prefix = "C"
		"spades": suit_prefix = "S"
		_: suit_prefix = suit.substr(0, 1).to_upper()

	return suit_prefix + str(value)

## 🔧 验证基础卡牌ID
static func _is_valid_base_card_id(base_id: String) -> bool:
	# 检查格式：字母+数字
	if base_id.length() < 2:
		return false

	var suit_char = base_id.substr(0, 1)
	var value_str = base_id.substr(1)

	# 验证花色字符
	if not suit_char in ["H", "D", "C", "S"]:
		return false

	# 验证面值（ID中的数字部分）
	var face_value = value_str.to_int()
	return STANDARD_VALUES.has(face_value)

## 🔧 验证标准牌库
static func _validate_standard_deck():
	var standard_cards = _get_standard_cards()
	var expected_count = STANDARD_SUITS.size() * STANDARD_VALUES.size()

	if standard_cards.size() != expected_count:
		push_warning("标准牌库数量不正确: 期望%d张, 实际%d张" % [expected_count, standard_cards.size()])

	# 检查是否有重复卡牌
	var card_ids = {}
	for card in standard_cards:
		if card_ids.has(card.id):
			push_warning("发现重复的标准卡牌: %s" % card.id)
		card_ids[card.id] = true

	# 检查是否缺少卡牌
	for suit in STANDARD_SUITS:
		for value in STANDARD_VALUES:
			var expected_id = _get_standard_card_id(suit, value)
			if not card_ids.has(expected_id):
				push_warning("缺少标准卡牌: %s" % expected_id)

## 🔧 注册单张卡牌
static func _register_card(card_data: CardData):
	# 按ID缓存
	_card_cache[card_data.id] = card_data
	
	# 按花色分组
	if not _cards_by_suit.has(card_data.suit):
		_cards_by_suit[card_data.suit] = []
	_cards_by_suit[card_data.suit].append(card_data)
	
	# 按数值分组
	if not _cards_by_value.has(card_data.base_value):
		_cards_by_value[card_data.base_value] = []
	_cards_by_value[card_data.base_value].append(card_data)

## 🔧 打印统计信息
static func _print_statistics():
	print("📊 标准卡牌数据统计:")
	print("  标准卡牌数: %d" % _card_cache.size())
	print("  花色数量: %d" % _cards_by_suit.size())

	for suit in _cards_by_suit:
		print("    %s: %d张" % [suit, _cards_by_suit[suit].size()])

	print("  数值范围: %d - %d" % [_cards_by_value.keys().min(), _cards_by_value.keys().max()])

	# 显示StandardDeckManager的额外信息
	var variant_cards = StandardDeckManagerClass.get_variant_cards()
	if variant_cards.size() > 0:
		print("  📦 变体卡牌: %d张 (不包含在标准牌库中)" % variant_cards.size())

	var test_cards = StandardDeckManagerClass.get_test_cards()
	if test_cards.size() > 0:
		print("  🧪 测试卡牌: %d张 (不包含在标准牌库中)" % test_cards.size())
		for card in _test_cards:
			print("    - %s (%s)" % [card.name, card.id])

## 🎯 获取单张卡牌
static func get_card(card_id: String) -> CardData:
	_ensure_initialized()
	return _card_cache.get(card_id, null)

## 🎯 获取所有卡牌
static func get_all_cards() -> Array:
	_ensure_initialized()
	var cards: Array[CardData] = []
	for card in _card_cache.values():
		cards.append(card)
	return cards

## 🎯 按花色获取卡牌
static func get_cards_by_suit(suit: String) -> Array:
	_ensure_initialized()
	var cards: Array[CardData] = []
	var suit_cards = _cards_by_suit.get(suit, [])
	for card in suit_cards:
		cards.append(card)
	return cards

## 🎯 按数值获取卡牌
static func get_cards_by_value(value: int) -> Array:
	_ensure_initialized()
	var cards: Array[CardData] = []
	var value_cards = _cards_by_value.get(value, [])
	for card in value_cards:
		cards.append(card)
	return cards

## 🎯 获取指定数量的随机卡牌
static func get_random_cards(count: int) -> Array:
	_ensure_initialized()
	var all_cards = get_all_cards()
	all_cards.shuffle()
	
	var result: Array[CardData] = []
	for i in range(min(count, all_cards.size())):
		result.append(all_cards[i])
	
	return result

## 🎯 创建标准测试手牌（使用标准牌库）
static func create_test_hands() -> Dictionary:
	_ensure_initialized()

	var test_hands = {}
	var standard_cards = StandardDeckManagerClass.get_standard_deck()

	# 皇家同花顺 (红桃10-J-Q-K-A)
	var royal_flush = []
	for value in [10, 11, 12, 13, 1]:
		var card = StandardDeckManagerClass.get_standard_card("hearts", value)
		if card:
			royal_flush.append(card)
	if royal_flush.size() == 5:
		test_hands["royal_flush"] = royal_flush

	# 四条 (四张A + 一张其他)
	var four_kind = []
	for suit in STANDARD_SUITS:
		var card = get_standard_card(suit, 1)  # A
		if card:
			four_kind.append(card)
	var kicker = get_standard_card("hearts", 10)
	if kicker:
		four_kind.append(kicker)
	if four_kind.size() == 5:
		test_hands["four_kind"] = four_kind

	# 葫芦 (三张K + 两张Q)
	var full_house = []
	for i in range(3):
		var card = get_standard_card(STANDARD_SUITS[i], 13)  # K
		if card:
			full_house.append(card)
	for i in range(2):
		var card = get_standard_card(STANDARD_SUITS[i], 12)  # Q
		if card:
			full_house.append(card)
	if full_house.size() == 5:
		test_hands["full_house"] = full_house

	# 同花 (红桃的5张不连续牌)
	var flush = []
	for value in [2, 5, 8, 11, 13]:
		var card = get_standard_card("hearts", value)
		if card:
			flush.append(card)
	if flush.size() == 5:
		test_hands["flush"] = flush

	# 对子 (两张J + 三张不同的牌)
	var pair = []
	for i in range(2):
		var card = get_standard_card(STANDARD_SUITS[i], 11)  # J
		if card:
			pair.append(card)
	for value in [3, 7, 10]:
		var card = get_standard_card("hearts", value)
		if card:
			pair.append(card)
	if pair.size() == 5:
		test_hands["pair"] = pair

	# 高牌 (5张不连续不同花色的牌)
	var high_card = []
	var values_suits = [[2, "hearts"], [5, "diamonds"], [8, "clubs"], [10, "spades"], [13, "hearts"]]
	for vs in values_suits:
		var card = get_standard_card(vs[1], vs[0])
		if card:
			high_card.append(card)
	if high_card.size() == 5:
		test_hands["high_card"] = high_card

	return test_hands

## 🎯 验证卡牌数据完整性（使用标准牌库验证）
static func validate_card_data() -> Dictionary:
	_ensure_initialized()

	# 使用StandardDeckManager的验证功能
	var deck_validation = StandardDeckManagerClass.validate_deck_integrity()

	# 转换为兼容格式
	var validation = {
		"total_cards": deck_validation.standard_count,
		"suits": StandardDeckManagerClass.get_available_suits(),
		"values": StandardDeckManagerClass.get_available_values(),
		"missing_cards": deck_validation.missing_cards,
		"duplicate_cards": deck_validation.duplicate_cards,
		"invalid_cards": [],
		"is_valid": deck_validation.is_valid,
		"variant_count": deck_validation.variant_count,
		"test_count": deck_validation.test_count,
		"expected_count": deck_validation.expected_count
	}

	return validation

## 🔧 确保已初始化
static func _ensure_initialized():
	if not _is_initialized:
		initialize()

## 🎯 重新加载数据
static func reload():
	_is_initialized = false
	initialize()

## 🎯 获取可用花色列表
static func get_available_suits() -> Array:
	_ensure_initialized()
	return _cards_by_suit.keys()

## 🎯 获取可用数值列表
static func get_available_values() -> Array:
	_ensure_initialized()
	return StandardDeckManagerClass.get_available_values()

# ========================================
# 🚀 扩展功能：访问变体和测试卡牌
# ========================================

## 🎯 获取变体卡牌（强化、弱化等）
static func get_variant_cards() -> Array:
	_ensure_initialized()
	return StandardDeckManagerClass.get_variant_cards()

## 🎯 获取测试卡牌
static func get_test_cards() -> Array:
	_ensure_initialized()
	return StandardDeckManagerClass.get_test_cards()

## 🎯 获取所有卡牌（包括变体和测试）
static func get_all_cards_including_variants() -> Array:
	_ensure_initialized()
	return StandardDeckManagerClass.get_all_cards()

## 🎯 获取指定标准卡牌
static func get_standard_card(suit: String, value: int) -> CardData:
	_ensure_initialized()
	return StandardDeckManagerClass.get_standard_card(suit, value)

## 🎯 检查是否为标准卡牌
static func is_standard_card(card: CardData) -> bool:
	if not card:
		return false

	_ensure_initialized()
	var standard_deck = StandardDeckManagerClass.get_standard_deck()

	for standard_card in standard_deck:
		if standard_card.id == card.id:
			return true

	return false

## 🎯 获取牌库统计信息
static func get_deck_statistics() -> Dictionary:
	_ensure_initialized()
	var validation = StandardDeckManagerClass.validate_deck_integrity()

	return {
		"standard_cards": validation.standard_count,
		"variant_cards": validation.variant_count,
		"test_cards": validation.test_count,
		"total_cards": validation.total_count,
		"is_complete": validation.is_valid,
		"missing_cards": validation.missing_cards,
		"duplicate_cards": validation.duplicate_cards
	}


