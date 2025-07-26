class_name DeckViewIntegrationManager
extends Node

## 牌库查看集成管理器
##
## 负责管理DeckWidget与CardManager之间的数据同步，
## 作为中介者模式的实现，解耦牌库显示和卡牌管理逻辑。

# 导入依赖
const GameSessionConfigClass = preload("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd")

# 信号
signal deck_data_updated(current_deck_size: int, total_cards: int)
signal deck_view_refreshed()
signal integration_setup_completed()

# 组件引用
var deck_widget: DeckWidget = null
var card_manager: CardManager = null
var session_config = null

# 数据缓存
var all_cards_data: Array = []
var current_deck_data: Array = []
var played_cards_data: Array = []

# 更新控制
var auto_update_enabled: bool = true
var update_timer: Timer = null
var pending_update: bool = false

# 调试选项
var enable_logging: bool = true

func _init():
	# 初始化基本状态
	all_cards_data = []
	current_deck_data = []
	played_cards_data = []
	auto_update_enabled = true
	pending_update = false
	enable_logging = false

	# 创建更新定时器
	_setup_update_timer()

# 设置更新定时器
func _setup_update_timer():
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # 默认延迟
	update_timer.one_shot = true
	update_timer.timeout.connect(_perform_delayed_update)
	add_child(update_timer)

# 设置组件引用
func setup(deck_widget_ref: DeckWidget, card_manager_ref: CardManager):
	deck_widget = deck_widget_ref
	card_manager = card_manager_ref
	
	if not deck_widget:
		push_error("DeckViewIntegrationManager: DeckWidget引用为空")
		return false
	
	if not card_manager:
		push_error("DeckViewIntegrationManager: CardManager引用为空")
		return false
	
	# 连接CardManager信号
	_connect_card_manager_signals()
	
	# 初始化数据
	_initialize_data()
	
	# 首次更新显示
	update_deck_display()
	
	if enable_logging:
		print("DeckViewIntegrationManager: 集成设置完成")
	
	emit_signal("integration_setup_completed")
	return true

# 连接CardManager信号
func _connect_card_manager_signals():
	if not card_manager:
		return
	
	# 连接相关信号
	if card_manager.has_signal("deck_changed"):
		if not card_manager.is_connected("deck_changed", _on_deck_changed):
			card_manager.deck_changed.connect(_on_deck_changed)
	
	if card_manager.has_signal("hand_changed"):
		if not card_manager.is_connected("hand_changed", _on_hand_changed):
			card_manager.hand_changed.connect(_on_hand_changed)
	
	if card_manager.has_signal("cards_played"):
		if not card_manager.is_connected("cards_played", _on_cards_played):
			card_manager.cards_played.connect(_on_cards_played)
	
	if card_manager.has_signal("discard_pile_changed"):
		if not card_manager.is_connected("discard_pile_changed", _on_discard_pile_changed):
			card_manager.discard_pile_changed.connect(_on_discard_pile_changed)
	
	if enable_logging:
		print("DeckViewIntegrationManager: CardManager信号连接完成")

# 初始化数据
func _initialize_data():
	# 加载所有卡牌数据
	all_cards_data = _load_all_card_data()
	
	# 获取当前牌库数据
	if card_manager:
		current_deck_data = card_manager.get_deck()
		played_cards_data = _get_played_cards_data()
	
	if enable_logging:
		print("DeckViewIntegrationManager: 数据初始化完成 - 全部:%d张，当前牌库:%d张，已打出:%d张" % [
			all_cards_data.size(), current_deck_data.size(), played_cards_data.size()
		])

# 加载所有卡牌数据
func _load_all_card_data() -> Array:
	var all_cards = []
	var suit_codes = ["S", "H", "D", "C"]  # 黑桃、红心、方片、梅花
	var values = range(1, 14)  # A-K (1-13)
	
	for suit_code in suit_codes:
		for value in values:
			var card_id = "%s%d" % [suit_code, value]
			var card_path = "res://assets/data/cards/" + card_id + ".tres"
			
			if ResourceLoader.exists(card_path):
				var card_resource = load(card_path)
				if card_resource:
					all_cards.append(card_resource)
	
	if enable_logging:
		print("DeckViewIntegrationManager: 加载了 %d 张卡牌数据" % all_cards.size())
	
	return all_cards

# 获取已打出的卡牌数据
func _get_played_cards_data() -> Array:
	var played_cards = []
	
	if card_manager and card_manager.has_method("get_discard_pile"):
		played_cards = card_manager.get_discard_pile()
	
	return played_cards

# 更新牌库显示
func update_deck_display():
	if not deck_widget or not card_manager:
		if enable_logging:
			push_warning("DeckViewIntegrationManager: 组件引用缺失，无法更新显示")
		return
	
	# 更新数据
	current_deck_data = card_manager.get_deck()
	played_cards_data = _get_played_cards_data()
	
	# 设置DeckWidget数据
	deck_widget.all_cards_data = all_cards_data
	deck_widget.current_deck_data = current_deck_data
	deck_widget.played_cards_data = played_cards_data
	
	# 更新牌库信息显示
	deck_widget.update_deck_info(current_deck_data.size(), all_cards_data.size())
	
	if enable_logging:
		print("DeckViewIntegrationManager: 牌库显示已更新 - 当前:%d张，已打出:%d张" % [
			current_deck_data.size(), played_cards_data.size()
		])
	
	emit_signal("deck_data_updated", current_deck_data.size(), all_cards_data.size())

# 刷新所有数据
func refresh_all_data():
	_initialize_data()
	update_deck_display()
	
	if enable_logging:
		print("DeckViewIntegrationManager: 所有数据已刷新")
	
	emit_signal("deck_view_refreshed")

# 延迟更新（防抖机制）
func _schedule_update():
	if not auto_update_enabled:
		return
	
	pending_update = true
	
	if session_config:
		update_timer.wait_time = session_config.deck_view_update_delay
	
	update_timer.start()

# 执行延迟更新
func _perform_delayed_update():
	if pending_update:
		pending_update = false
		update_deck_display()

# CardManager信号处理
func _on_deck_changed(deck_size: int):
	if enable_logging:
		print("DeckViewIntegrationManager: 牌库变化 - 当前大小: %d" % deck_size)
	
	_schedule_update()

func _on_hand_changed(hand_cards: Array):
	# 手牌变化可能影响牌库显示
	_schedule_update()

func _on_cards_played(played_cards: Array, score_gained: int):
	if enable_logging:
		print("DeckViewIntegrationManager: 卡牌已打出 - %d张，得分: %d" % [played_cards.size(), score_gained])
	
	_schedule_update()

func _on_discard_pile_changed(discard_size: int):
	if enable_logging:
		print("DeckViewIntegrationManager: 弃牌堆变化 - 当前大小: %d" % discard_size)
	
	_schedule_update()

# 设置自动更新
func set_auto_update_enabled(enabled: bool):
	auto_update_enabled = enabled
	
	if enable_logging:
		print("DeckViewIntegrationManager: 自动更新 %s" % ("启用" if enabled else "禁用"))

# 强制立即更新
func force_update():
	if update_timer.is_stopped():
		update_deck_display()
	else:
		# 取消延迟更新，立即执行
		update_timer.stop()
		_perform_delayed_update()

# 获取集成状态
func get_integration_status() -> Dictionary:
	return {
		"deck_widget_valid": is_instance_valid(deck_widget),
		"card_manager_valid": is_instance_valid(card_manager),
		"auto_update_enabled": auto_update_enabled,
		"pending_update": pending_update,
		"all_cards_count": all_cards_data.size(),
		"current_deck_count": current_deck_data.size(),
		"played_cards_count": played_cards_data.size()
	}

# 更新配置
func update_config(new_config):
	session_config = new_config
	enable_logging = new_config.enable_debug_logging
	auto_update_enabled = new_config.auto_update_deck_view
	
	if update_timer:
		update_timer.wait_time = new_config.deck_view_update_delay
	
	if enable_logging:
		print("DeckViewIntegrationManager: 配置已更新")

# 断开连接
func disconnect_signals():
	if card_manager:
		if card_manager.has_signal("deck_changed") and card_manager.is_connected("deck_changed", _on_deck_changed):
			card_manager.deck_changed.disconnect(_on_deck_changed)
		
		if card_manager.has_signal("hand_changed") and card_manager.is_connected("hand_changed", _on_hand_changed):
			card_manager.hand_changed.disconnect(_on_hand_changed)
		
		if card_manager.has_signal("cards_played") and card_manager.is_connected("cards_played", _on_cards_played):
			card_manager.cards_played.disconnect(_on_cards_played)
		
		if card_manager.has_signal("discard_pile_changed") and card_manager.is_connected("discard_pile_changed", _on_discard_pile_changed):
			card_manager.discard_pile_changed.disconnect(_on_discard_pile_changed)
	
	if enable_logging:
		print("DeckViewIntegrationManager: 信号连接已断开")

# 清理资源
func _exit_tree():
	disconnect_signals()
	
	if update_timer:
		update_timer.queue_free()
