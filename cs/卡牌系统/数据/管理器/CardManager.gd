extends Node

class_name CardManager

# 导入必要的类
const CardEffectManagerDataClass = preload("res://cs/卡牌系统/数据/管理器/CardEffectManager.gd")


# 牌库相关
var deck: Array[CardData] = []  # 牌库（主抽牌堆）
var hand: Array[CardData] = []  # 玩家手牌
var discard_pile: Array[CardData] = []  # 弃牌堆
var destroyed_pile: Array[CardData] = []  # 销毁堆（永久移出游戏）
var all_base_cards: Array[CardData] = []  # 所有原始卡牌资源

# 配置参数
var max_hand_size: int = 5
var base_draw_count: int = 1

# 游戏状态引用
var score_calculator: ScoreCalculator = null
var game_config: GameConfigResource = null

# 引用效果管理器 - 修复类型声明，使用Node类型以兼容不同的效果管理器实现
var effect_manager: Node = null

# 引用游戏场景
var game_scene = null

# 信号
signal hand_changed(hand_cards)
signal deck_changed(deck_size)
signal discard_pile_changed(discard_size)
signal destroyed_pile_changed(destroyed_size)
signal card_played(card_data)
signal cards_played(played_cards, score_gained)
signal card_drawn(card_data)
signal cards_drawn(drawn_cards)
signal card_discarded(card_data)
signal cards_discarded(discarded_cards)
signal card_destroyed(card_data)
signal discard_pile_shuffled()
signal card_reinforced(card_data, reinforcement_type, reinforcement_effect)
signal deck_updated()  # 新增：牌库更新信号

# 引用
@onready var _game_config: GameConfigResource = preload("res://assets/data/game_config.tres")

# 初始化
func _init(scene):
	game_scene = scene  # 保存游戏场景引用

func _ready():
	# 获取单例引用
	score_calculator = get_node("/root/ScoreCalculator")

	# 使用游戏场景中的CardEffectManager引用
	if game_scene and game_scene.has_method("get") and game_scene.card_effect_manager:
		effect_manager = game_scene.card_effect_manager
		print("CardManager: 使用游戏场景提供的效果管理器 (类型: %s)" % effect_manager.get_class())
	else:
		# 创建自己的效果管理器作为备用
		effect_manager = CardEffectManagerDataClass.new()
		add_child(effect_manager)
		print("CardManager: 没有找到共享效果管理器，创建独立实例")

	# 加载所有卡牌资源
	_load_all_card_resources()

# 加载所有卡牌资源
func _load_all_card_resources():
	# 找到所有卡牌资源文件
	var dir = DirAccess.open("res://assets/data/cards")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card_data: CardData = load("res://assets/data/cards/" + file_name)
				if card_data:
					all_base_cards.append(card_data)
			file_name = dir.get_next()
	
	print("CardManager: 已加载 %d 个卡牌资源" % all_base_cards.size())
	
# 初始化卡牌管理器
func initialize(card_pool: Array = []):
	initialize_deck(card_pool)
	
	# 连接信号到EffectOrchestrator（如果存在）
	if game_scene and game_scene.effect_orchestrator:
		_connect_signals_to_orchestrator(game_scene.effect_orchestrator)
		print("CardManager: 已连接信号到效果协调器")
	
# 连接信号到效果协调器
func _connect_signals_to_orchestrator(orchestrator):
	# 防止重复连接
	if orchestrator:
		if not card_played.is_connected(orchestrator._on_card_played):
			card_played.connect(orchestrator._on_card_played)
		if not cards_played.is_connected(orchestrator._on_cards_played):
			cards_played.connect(orchestrator._on_cards_played)

# 初始化牌库
func initialize_deck(card_pool: Array = []):
	# 清空各个卡堆
	deck.clear()
	hand.clear()
	discard_pile.clear()
	destroyed_pile.clear()
	
	# 如果提供了指定卡池，则使用它；否则使用所有基础卡牌
	var source_cards = []
	if card_pool.size() > 0:
		source_cards = card_pool
	else:
		# 确保基础卡牌已加载
		if all_base_cards.is_empty():
			_load_all_card_resources()
		source_cards = all_base_cards
	
	print("CardManager: 使用卡牌资源数量: %d" % source_cards.size())
	
	# 克隆所有卡牌资源到牌库
	for card_resource in source_cards:
		if card_resource != null:
			var card_clone = card_resource.clone()
			deck.append(card_clone)
		else:
			print("CardManager: 警告 - 跳过空卡牌资源")

	# 洗牌
	shuffle_deck()
	
	# 发出信号
	emit_signal("deck_changed", deck.size())
	emit_signal("discard_pile_changed", discard_pile.size())
	emit_signal("destroyed_pile_changed", destroyed_pile.size())
	emit_signal("hand_changed", hand)
	
	print("CardManager: 牌库已初始化，共 %d 张牌" % deck.size())

# 洗牌
func shuffle_deck():
	if deck.is_empty():
		_reshuffle_discard_pile()
		if deck.is_empty():
			return
			
	# 随机打乱卡牌顺序
	randomize()
	deck.shuffle()
	print("CardManager: 牌库已洗牌，共 %d 张牌" % deck.size())
	
	emit_signal("deck_changed", deck.size())

# 从弃牌堆重组牌库
func _reshuffle_discard_pile():
	if discard_pile.is_empty():
		return
		
	for card in discard_pile:
		deck.append(card)
	
	discard_pile.clear()
	shuffle_deck()
	
	emit_signal("discard_pile_changed", 0)
	emit_signal("discard_pile_shuffled")
	print("CardManager: 弃牌堆已洗回牌库")

# 抽牌
func draw(count: int = 1) -> Array[CardData]:
	var drawn_cards: Array[CardData] = []
	var actual_count = min(count, max_hand_size - hand.size())
	
	for i in range(actual_count):
		# 检查牌库是否为空
		if deck.is_empty():
			# 如果弃牌堆也为空，则无法继续抽牌
			_reshuffle_discard_pile()
			if deck.is_empty():
				break
		
		# 从牌库顶抽一张牌
		var card = deck.pop_back()
		drawn_cards.append(card)
		hand.append(card)
		emit_signal("card_drawn", card)
	
	if drawn_cards.size() > 0:
		emit_signal("cards_drawn", drawn_cards)
		emit_signal("hand_changed", hand)
		emit_signal("deck_changed", deck.size())
	
	return drawn_cards

# 发初始手牌
func deal_initial_hand(hand_size: int = -1) -> Array[CardData]:
	# 确保之前没有手牌
	hand.clear()
	
	# 使用指定手牌数量或默认最大数量
	var target_size = hand_size if hand_size > 0 else max_hand_size
	
	# 抽牌
	var drawn_cards = draw(target_size)
	
	print("CardManager: 已发初始手牌，共 %d 张" % drawn_cards.size())
	return drawn_cards

# 根据索引打出单张卡牌
func play_card(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		push_error("无效的手牌索引: " + str(index))
		return null
		
	var card = hand[index]
	hand.remove_at(index)
	
	# 应用卡牌效果
	if effect_manager:
		var effects_result = effect_manager.process_card_effects(card)
		# 这里可以处理效果结果，例如更新UI显示
	
	# 将卡牌移至弃牌堆
	discard_pile.append(card)
	
	# 发出信号
	emit_signal("card_played", card)
	emit_signal("hand_changed", hand)
	emit_signal("discard_pile_changed", discard_pile.size())
	
	return card

# 打出多张卡牌（用于组合）
func play_cards(indices: Array) -> Array[CardData]:
	# 验证索引
	for idx in indices:
		if idx < 0 or idx >= hand.size():
			push_error("无效的手牌索引: " + str(idx))
			return []
	
	# 按索引从大到小排序，以便从后往前移除（避免索引变化）
	indices.sort_custom(func(a, b): return a > b)
	
	var played_cards: Array[CardData] = []
	
	# 收集要打出的牌
	for idx in indices:
		played_cards.append(hand[idx])
	
	# 从手牌中移除
	for idx in indices:
		hand.remove_at(idx)
	
	# 简化的得分计算（避免ScoreCalculator问题）
	var score = 0
	for card in played_cards:
		score += card.base_value
	print("CardManager: 简化得分计算，总分: %d" % score)
	
	# 应用效果（如果需要）
	# ...
	
	# 将牌移至弃牌堆
	for card in played_cards:
		discard_pile.append(card)
	
	# 发出信号
	emit_signal("cards_played", played_cards, score)
	emit_signal("hand_changed", hand)
	emit_signal("discard_pile_changed", discard_pile.size())
	
	return played_cards

# 打出多张卡牌（支持CardData数组）- 新方法，用于TurnManager集成
func play_cards_by_data(card_data_list: Array) -> Array[CardData]:
	if card_data_list.is_empty():
		print("CardManager: 没有卡牌需要打出")
		return []

	var played_cards: Array[CardData] = []
	var cards_to_remove: Array[CardData] = []

	# 验证所有卡牌都在手牌中
	for card_data in card_data_list:
		if card_data in hand:
			played_cards.append(card_data)
			cards_to_remove.append(card_data)
		else:
			push_error("CardManager: 卡牌不在手牌中: " + str(card_data.name if card_data else "null"))

	if played_cards.is_empty():
		print("CardManager: 没有有效的卡牌可以打出")
		return []

	# 从手牌中移除
	for card in cards_to_remove:
		var index = hand.find(card)
		if index >= 0:
			hand.remove_at(index)

	# 简化的得分计算（避免ScoreCalculator问题）
	var score = 0
	for card in played_cards:
		score += card.base_value
	print("CardManager: 简化得分计算，总分: %d" % score)

	# 应用卡牌效果
	if effect_manager:
		for card in played_cards:
			var effects_result = effect_manager.process_card_effects(card)
			# 这里可以处理效果结果

	# 将卡牌移至弃牌堆
	for card in played_cards:
		discard_pile.append(card)

	# 发送信号
	emit_signal("cards_played", played_cards, score)
	emit_signal("hand_changed", hand)
	emit_signal("discard_pile_changed", discard_pile.size())

	print("CardManager: 成功打出 %d 张卡牌，得分: %d" % [played_cards.size(), score])
	return played_cards

# 弃牌
func discard(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		push_error("无效的手牌索引: " + str(index))
		return null
		
	var card = hand[index]
	hand.remove_at(index)
	discard_pile.append(card)
	
	emit_signal("card_discarded", card)
	emit_signal("hand_changed", hand)
	emit_signal("discard_pile_changed", discard_pile.size())
	
	return card

# 批量弃牌
func discard_multiple(indices: Array) -> Array[CardData]:
	# 验证索引
	for idx in indices:
		if idx < 0 or idx >= hand.size():
			push_error("无效的手牌索引: " + str(idx))
			return []
	
	# 按索引从大到小排序，以便从后往前移除（避免索引变化）
	indices.sort_custom(func(a, b): return a > b)
	
	var discarded_cards: Array[CardData] = []
	
	# 收集要弃的牌
	for idx in indices:
		discarded_cards.append(hand[idx])
	
	# 从手牌中移除
	for idx in indices:
		hand.remove_at(idx)
	
	# 将牌移至弃牌堆
	for card in discarded_cards:
		discard_pile.append(card)
	
	# 发出信号
	emit_signal("cards_discarded", discarded_cards)
	emit_signal("hand_changed", hand)
	emit_signal("discard_pile_changed", discard_pile.size())
	
	return discarded_cards

# 通过CardData打出卡牌
func play_card_by_data(card_data: CardData) -> bool:
	var index = hand.find(card_data)
	if index == -1:
		print("CardManager: 卡牌不在手牌中: %s" % card_data.name)
		return false

	play_card(index)
	return true

# 通过CardData弃牌
func discard_card_by_data(card_data: CardData) -> bool:
	var index = hand.find(card_data)
	if index == -1:
		print("CardManager: 卡牌不在手牌中: %s" % card_data.name)
		return false

	discard(index)
	return true

# 销毁卡牌（永久移出游戏）
func destroy_card(index: int) -> CardData:
	if index < 0 or index >= hand.size():
		push_error("无效的手牌索引: " + str(index))
		return null
		
	var card = hand[index]
	hand.remove_at(index)
	destroyed_pile.append(card)
	
	emit_signal("card_destroyed", card)
	emit_signal("hand_changed", hand)
	emit_signal("destroyed_pile_changed", destroyed_pile.size())
	
	return card

# 向手牌中的卡牌添加强化效果
func add_reinforcement_to_card_in_hand(card_id: String, type: String, effect: String) -> bool:
	# 查找卡牌
	var card_index = -1
	for i in range(hand.size()):
		if hand[i].card_id == card_id:
			card_index = i
			break
	
	if card_index == -1:
		push_error("在手牌中找不到ID为 " + card_id + " 的卡牌")
		return false
	
	# 添加强化效果
	var card = hand[card_index]
	card.add_reinforcement(type, effect)
	
	# 发出信号
	emit_signal("card_reinforced", card, type, effect)
	emit_signal("hand_changed", hand)
	
	return true

# 从牌库中永久移除卡牌
func remove_card_from_deck(card_id: String) -> bool:
	# 查找卡牌
	var card_index = -1
	for i in range(deck.size()):
		if deck[i].card_id == card_id:
			card_index = i
			break
	
	if card_index == -1:
		push_error("在牌库中找不到ID为 " + card_id + " 的卡牌")
		return false
	
	# 移除卡牌
	var card = deck[card_index]
	deck.remove_at(card_index)
	
	# 发出信号
	emit_signal("deck_changed", deck.size())
	
	return true

# 向牌库中添加卡牌
func add_card_to_deck(card_data: CardData) -> bool:
	if not card_data:
		push_error("尝试添加无效的卡牌")
		return false
	
	# 添加卡牌到牌库
	deck.append(card_data)
	
	# 发出信号
	emit_signal("deck_changed", deck.size())
	emit_signal("deck_updated")
	
	return true

# 将卡牌添加到牌库底部
func add_card_to_bottom_of_deck(card_data: CardData) -> bool:
	if not card_data:
		push_error("尝试添加无效的卡牌")
		return false
	
	# 添加卡牌到牌库底部
	deck.insert(0, card_data)
	
	# 发出信号
	emit_signal("deck_changed", deck.size())
	emit_signal("deck_updated")
	
	return true

# 获取所有卡牌（包括基础卡牌）
func get_all_cards() -> Array:
	return all_base_cards.duplicate()

# 获取当前牌库
func get_deck() -> Array:
	return deck.duplicate()

# 获取弃牌堆
func get_discard_pile() -> Array:
	return discard_pile.duplicate()

# 获取销毁堆
func get_destroyed_pile() -> Array:
	return destroyed_pile.duplicate()

# 查看牌库顶部的卡牌
func peek_top_card() -> CardData:
	if deck.is_empty():
		return null
	return deck[deck.size() - 1]

# 修改牌库中的卡牌
func modify_card_in_deck(card_id: String, modification_func: Callable) -> bool:
	# 查找卡牌
	var card_index = -1
	for i in range(deck.size()):
		if deck[i].card_id == card_id:
			card_index = i
			break
	
	if card_index == -1:
		push_error("在牌库中找不到ID为 " + card_id + " 的卡牌")
		return false
	
	# 修改卡牌
	var card = deck[card_index]
	modification_func.call(card)
	
	# 发出信号
	emit_signal("deck_updated")
	
	return true

# 强化牌库中的卡牌
func reinforce_card_in_deck(card_id: String, reinforcement_type: String, reinforcement_effect: String) -> bool:
	return modify_card_in_deck(card_id, func(card): card.add_reinforcement(reinforcement_type, reinforcement_effect))

# 重置牌库（用于新游戏或测试）
func reset_deck():
	initialize_deck()
	emit_signal("deck_updated")

## 🔄 卡牌替换功能
# 替换手牌中的卡牌
func replace_card_in_hand(old_card: CardData, new_card: CardData) -> bool:
	"""
	在手牌中替换指定的卡牌

	参数:
	- old_card: 要被替换的卡牌
	- new_card: 新的替换卡牌

	返回:
	- bool: 替换是否成功
	"""
	if not old_card or not new_card:
		push_error("CardManager: 替换卡牌参数无效")
		return false

	# 查找旧卡牌在手牌中的位置
	var card_index = -1
	for i in range(hand.size()):
		if hand[i] == old_card:
			card_index = i
			break

	if card_index == -1:
		push_error("CardManager: 在手牌中找不到要替换的卡牌: %s" % old_card.name)
		return false

	# 执行替换
	hand[card_index] = new_card

	# 发出信号通知手牌变化
	emit_signal("hand_changed", hand)

	print("CardManager: 成功替换卡牌 %s -> %s" % [old_card.name, new_card.name])
	return true

# 根据卡牌ID替换手牌中的卡牌
func replace_card_in_hand_by_id(old_card_id: String, new_card: CardData) -> bool:
	"""
	根据卡牌ID在手牌中替换卡牌

	参数:
	- old_card_id: 要被替换的卡牌ID
	- new_card: 新的替换卡牌

	返回:
	- bool: 替换是否成功
	"""
	if old_card_id.is_empty() or not new_card:
		push_error("CardManager: 替换卡牌参数无效")
		return false

	# 查找旧卡牌在手牌中的位置
	var card_index = -1
	for i in range(hand.size()):
		if hand[i].id == old_card_id:
			card_index = i
			break

	if card_index == -1:
		push_error("CardManager: 在手牌中找不到ID为 %s 的卡牌" % old_card_id)
		return false

	var old_card = hand[card_index]

	# 执行替换
	hand[card_index] = new_card

	# 发出信号通知手牌变化
	emit_signal("hand_changed", hand)

	print("CardManager: 成功替换卡牌 %s -> %s" % [old_card.name, new_card.name])
	return true

# 获取手牌的副本（用于外部访问）
func get_hand() -> Array:
	"""
	获取当前手牌的副本

	返回:
	- Array: 手牌卡牌数组的副本
	"""
	return hand.duplicate()
