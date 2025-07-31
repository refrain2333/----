class_name StandardDeckManager
extends RefCounted

## 🎯 标准牌库管理器
##
## 核心功能：
## - 管理标准52张扑克牌
## - 过滤测试卡牌和变体卡牌
## - 支持卡牌复制和修改（预留框架）
## - 提供标准牌库和扩展牌库的分离管理

# 标准扑克牌定义
const STANDARD_SUITS = ["hearts", "diamonds", "clubs", "spades"]
const STANDARD_VALUES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]  # 标准面值1-13
const STANDARD_BASE_VALUES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]  # 允许的base_value（A可以是14）

# 卡牌集合
static var _standard_deck: Array = []           # 标准52张牌
static var _variant_cards: Array = []           # 变体卡牌（强化、弱化等）
static var _test_cards: Array = []              # 测试卡牌
static var _all_cards: Array = []               # 所有卡牌
static var _is_initialized: bool = false

## 🎯 初始化标准牌库系统
static func initialize():
	if _is_initialized:
		return
	
	print("🃏 初始化标准牌库管理器...")
	var start_time = Time.get_ticks_msec()
	
	# 清空所有集合
	_standard_deck.clear()
	_variant_cards.clear()
	_test_cards.clear()
	_all_cards.clear()
	
	# 加载所有卡牌文件
	_load_all_card_files()
	
	# 分类卡牌
	_classify_cards()
	
	# 验证标准牌库
	_validate_standard_deck()
	
	var end_time = Time.get_ticks_msec()
	var load_time = end_time - start_time
	
	_is_initialized = true
	print("✅ 标准牌库管理器初始化完成: 标准%d张, 变体%d张, 测试%d张, 耗时%dms" % [
		_standard_deck.size(), _variant_cards.size(), _test_cards.size(), load_time
	])
	
	_print_deck_statistics()

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
			_standard_deck.append(card)
		elif _is_variant_card(card):
			_variant_cards.append(card)
		else:
			_test_cards.append(card)

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

## 🔧 验证标准牌库
static func _validate_standard_deck():
	var expected_count = STANDARD_SUITS.size() * STANDARD_VALUES.size()
	
	if _standard_deck.size() != expected_count:
		push_warning("标准牌库数量不正确: 期望%d张, 实际%d张" % [expected_count, _standard_deck.size()])
	
	# 检查是否有重复卡牌
	var card_ids = {}
	for card in _standard_deck:
		if card_ids.has(card.id):
			push_warning("发现重复的标准卡牌: %s" % card.id)
		card_ids[card.id] = true
	
	# 检查是否缺少卡牌
	for suit in STANDARD_SUITS:
		for value in STANDARD_VALUES:
			var expected_id = _get_standard_card_id(suit, value)
			if not card_ids.has(expected_id):
				push_warning("缺少标准卡牌: %s" % expected_id)

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

## 🔧 打印牌库统计
static func _print_deck_statistics():
	print("📊 牌库统计信息:")
	print("  标准牌库: %d张" % _standard_deck.size())
	
	if not _variant_cards.is_empty():
		print("  变体卡牌: %d张" % _variant_cards.size())
		for card in _variant_cards:
			print("    - %s (%s)" % [card.name, card.id])
	
	if not _test_cards.is_empty():
		print("  测试卡牌: %d张" % _test_cards.size())
		for card in _test_cards:
			print("    - %s (%s)" % [card.name, card.id])

## 🎯 获取标准牌库（52张）
static func get_standard_deck() -> Array:
	_ensure_initialized()
	return _standard_deck.duplicate()

## 🎯 获取变体卡牌
static func get_variant_cards() -> Array:
	_ensure_initialized()
	return _variant_cards.duplicate()

## 🎯 获取测试卡牌
static func get_test_cards() -> Array:
	_ensure_initialized()
	return _test_cards.duplicate()

## 🎯 获取所有卡牌
static func get_all_cards() -> Array:
	_ensure_initialized()
	return _all_cards.duplicate()

## 🎯 按花色获取标准卡牌
static func get_standard_cards_by_suit(suit: String) -> Array:
	_ensure_initialized()
	var result = []
	for card in _standard_deck:
		if card.suit == suit:
			result.append(card)
	return result

## 🎯 按数值获取标准卡牌
static func get_standard_cards_by_value(value: int) -> Array:
	_ensure_initialized()
	var result = []
	for card in _standard_deck:
		if card.base_value == value:
			result.append(card)
	return result

## 🎯 获取随机标准卡牌
static func get_random_standard_cards(count: int) -> Array:
	_ensure_initialized()
	var deck = _standard_deck.duplicate()
	deck.shuffle()
	
	var result = []
	for i in range(min(count, deck.size())):
		result.append(deck[i])
	
	return result

## 🎯 创建标准测试手牌
static func create_standard_test_hands() -> Dictionary:
	_ensure_initialized()
	
	var test_hands = {}
	
	# 皇家同花顺 (红桃10-J-Q-K-A)
	var royal_flush = []
	for value in [10, 11, 12, 13, 1]:
		var card = get_standard_card("hearts", value)
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

## 🎯 获取指定的标准卡牌
static func get_standard_card(suit: String, value: int) -> CardData:
	_ensure_initialized()
	for card in _standard_deck:
		# 使用面值进行匹配（从ID提取）
		var face_value = card.get_face_value()
		if card.suit == suit and face_value == value:
			return card
	return null

## 🎯 验证牌库完整性
static func validate_deck_integrity() -> Dictionary:
	_ensure_initialized()
	
	var validation = {
		"is_valid": true,
		"standard_count": _standard_deck.size(),
		"expected_count": 52,
		"missing_cards": [],
		"duplicate_cards": [],
		"variant_count": _variant_cards.size(),
		"test_count": _test_cards.size(),
		"total_count": _all_cards.size()
	}
	
	# 检查标准牌库数量
	if validation.standard_count != validation.expected_count:
		validation.is_valid = false
	
	# 检查重复和缺失
	var card_ids = {}
	for card in _standard_deck:
		if card_ids.has(card.id):
			validation.duplicate_cards.append(card.id)
			validation.is_valid = false
		card_ids[card.id] = true
	
	# 检查缺失的标准卡牌
	for suit in STANDARD_SUITS:
		for value in STANDARD_VALUES:
			var expected_id = _get_standard_card_id(suit, value)
			if not card_ids.has(expected_id):
				validation.missing_cards.append(expected_id)
				validation.is_valid = false
	
	return validation

## 🔧 确保已初始化
static func _ensure_initialized():
	if not _is_initialized:
		initialize()

## 🎯 重新加载牌库
static func reload():
	_is_initialized = false
	initialize()

## 🎯 获取可用花色列表
static func get_available_suits() -> Array:
	return STANDARD_SUITS.duplicate()

## 🎯 获取可用数值列表
static func get_available_values() -> Array:
	return STANDARD_VALUES.duplicate()

# ========================================
# 🚀 预留框架：卡牌复制和修改系统
# ========================================

## 🎯 复制标准卡牌（预留接口）
static func duplicate_standard_card(_card: CardData, _modifications: Dictionary = {}) -> CardData:
	# TODO: 实现卡牌复制逻辑
	# 可以修改属性如：强化类型、数值调整、特殊效果等
	push_warning("卡牌复制功能尚未实现")
	return null

## 🎯 创建变体卡牌（预留接口）
static func create_variant_card(_base_card: CardData, _variant_type: String, _properties: Dictionary = {}) -> CardData:
	# TODO: 实现变体卡牌创建
	# 支持类型：enhanced, weakened, special, etc.
	push_warning("变体卡牌创建功能尚未实现")
	return null

## 🎯 注册自定义卡牌（预留接口）
static func register_custom_card(_card: CardData, _category: String = "custom"):
	# TODO: 实现自定义卡牌注册
	# 允许运行时添加新卡牌到指定分类
	push_warning("自定义卡牌注册功能尚未实现")
