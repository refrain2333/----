class_name CardPool
extends Node

# 卡牌对象池：减少频繁创建和销毁CardView实例的开销

# 池配置
var pool_size: int = 20                # 池初始大小
var auto_expand: bool = true           # 是否自动扩展池大小
var expansion_step: int = 5            # 每次扩展的数量
var max_pool_size: int = 100           # 最大池大小
var card_scene: PackedScene            # 卡牌场景

# 池状态
var _available_cards: Array = []       # 可用卡牌数组
var _active_cards: Dictionary = {}     # 活跃卡牌字典，键为卡牌实例，值为使用时间
var _total_created: int = 0            # 总共创建的卡牌数
var _total_reused: int = 0             # 总共复用的卡牌数

# 信号
signal pool_expanded(new_size)         # 池扩展信号
signal pool_stats_changed(stats)       # 池状态变化信号

# 初始化池
func _init(scene: PackedScene, initial_size: int = 20):
	card_scene = scene
	pool_size = initial_size
	_initialize_pool()

# 初始化池，预创建指定数量的卡牌
func _initialize_pool() -> void:
	for i in range(pool_size):
		var card = _create_card_instance()
		card.visible = false
		_available_cards.append(card)
	
	print("卡牌对象池初始化完成，大小: %d" % pool_size)

# 创建一个卡牌实例
func _create_card_instance() -> Control:
	var card = card_scene.instantiate()
	add_child(card)
	_total_created += 1  # 增加创建计数
	return card

# 获取一个卡牌实例
func get_card() -> Control:
	var card: Control = null
	
	# 如果有可用卡牌，从池中获取
	if not _available_cards.is_empty():
		card = _available_cards.pop_back()
		_total_reused += 1
	else:
		# 如果池为空且允许扩展，则扩展池
		if auto_expand and _active_cards.size() + _available_cards.size() < max_pool_size:
			_expand_pool()
			if not _available_cards.is_empty():
				card = _available_cards.pop_back()
				_total_reused += 1
		
		# 如果仍然没有可用卡牌，创建一个新的
		if card == null:
			card = _create_card_instance()
	
	# 标记为活跃并重置状态
	card.visible = true
	_active_cards[card] = Time.get_ticks_msec()
	
	# 发送状态变化信号
	emit_signal("pool_stats_changed", get_stats())
	
	return card

# 释放一个卡牌实例回池
func release_card(card: Control) -> void:
	if card == null or not is_instance_valid(card):
		return
	
	# 如果卡牌在活跃列表中，移除并重置
	if _active_cards.has(card):
		_active_cards.erase(card)
		
		# 重置卡牌状态
		card.visible = false
		
		# 如果是CardView，重置其数据
		if card.has_method("setup"):
			card.setup(null)
		
		# 放回可用池
		_available_cards.append(card)
		
		# 发送状态变化信号
		emit_signal("pool_stats_changed", get_stats())

# 扩展池大小
func _expand_pool() -> void:
	var old_size = _active_cards.size() + _available_cards.size()
	var expansion_count = min(expansion_step, max_pool_size - old_size)
	
	if expansion_count <= 0:
		print("卡牌池已达到最大容量: %d" % max_pool_size)
		return
	
	for i in range(expansion_count):
		var card = _create_card_instance()
		card.visible = false
		_available_cards.append(card)
	
	var new_size = old_size + expansion_count
	print("卡牌池扩展: %d -> %d" % [old_size, new_size])
	
	emit_signal("pool_expanded", new_size)

# 获取池统计信息
func get_stats() -> Dictionary:
	return {
		"available": _available_cards.size(),
		"active": _active_cards.size(),
		"total_size": _available_cards.size() + _active_cards.size(),
		"max_size": max_pool_size,
		"total_created": _total_created,
		"total_reused": _total_reused,
		"reuse_ratio": float(_total_reused) / max(1, _total_created + _total_reused)
	}

# 清理长时间未使用的卡牌
func cleanup_unused(max_age_ms: int = 30000) -> int:
	var current_time = Time.get_ticks_msec()
	var cleanup_count = 0
	var cards_to_remove = []
	
	# 找出长时间未使用的卡牌
	for card in _active_cards:
		var age = current_time - _active_cards[card]
		if age > max_age_ms:
			cards_to_remove.append(card)
	
	# 释放这些卡牌
	for card in cards_to_remove:
		release_card(card)
		cleanup_count += 1
	
	if cleanup_count > 0:
		print("清理了 %d 张长时间未使用的卡牌" % cleanup_count)
	
	return cleanup_count

# 释放所有卡牌回池
func release_all() -> void:
	var cards_to_release = _active_cards.keys()
	for card in cards_to_release:
		release_card(card)
	
	print("释放了所有活跃卡牌回池")

# 销毁整个池
func destroy_pool() -> void:
	# 销毁所有卡牌
	for card in _available_cards:
		card.queue_free()
	
	for card in _active_cards:
		card.queue_free()
	
	_available_cards.clear()
	_active_cards.clear()
	
	print("销毁了卡牌对象池")

# 定期清理未使用的卡牌
func _process(_delta: float) -> void:
	# 禁用自动清理功能，避免卡牌被意外清理
	pass
	# 每30秒清理一次
	# if Engine.get_process_frames() % 1800 == 0:
	#    cleanup_unused() 
