class_name HandDock
extends Panel

## 优化后的HandDock - 核心手牌UI管理组件
## 主要改进：统一日志、配置分离、智能卡牌替换、清理调试代码

# 信号
signal card_selection_changed(selected_cards)
signal play_button_pressed
signal discard_button_pressed
signal card_selected_for_play(card_data)
signal card_deselected_for_play(card_data)

# 配置和组件
var config: Dictionary = {
	"debug_mode": false,
	"log_level": 1,
	"enable_position_validation": false,
	"enable_selection_animation": true,
	"animation_duration": 0.2,
	"max_hand_size": 8,
	"fixed_positions": {
		1: [452.5],  # 492.5 - 40 = 452.5 (补偿容器左偏移)
		2: [385.0, 520.0],  # 425.0-40, 560.0-40
		3: [317.5, 452.5, 587.5],  # 357.5-40, 492.5-40, 627.5-40
		4: [250.0, 385.0, 520.0, 655.0],  # 290.0-40, 425.0-40, 560.0-40, 695.0-40
		5: [182.5, 317.5, 452.5, 587.5, 722.5],  # 222.5-40, 357.5-40, 492.5-40, 627.5-40, 762.5-40
		6: [115.0, 250.0, 385.0, 520.0, 655.0, 790.0],  # 155.0-40, 290.0-40, 425.0-40, 560.0-40, 695.0-40, 830.0-40
		7: [47.5, 182.5, 317.5, 452.5, 587.5, 722.5, 857.5],  # 87.5-40, 222.5-40, 357.5-40, 492.5-40, 627.5-40, 762.5-40, 897.5-40
		8: [-20.0, 115.0, 250.0, 385.0, 520.0, 655.0, 790.0, 925.0]  # 20.0-40, 155.0-40, 290.0-40, 425.0-40, 560.0-40, 695.0-40, 830.0-40, 965.0-40
	}
}
var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")

# 节点引用
@onready var card_container = $CardContainer
@onready var play_button = $ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton
@onready var discard_button = $ButtonPanel/ButtonGrid/DiscardButtonContainer/DiscardButton
@onready var sort_value_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortValueButton
@onready var sort_suit_button = $ButtonPanel/ButtonGrid/SortButtonContainer/SortGrid/SortSuitButton

# 核心管理器
var selection_manager: SelectionManager
var turn_manager = null

# 位置映射系统 - 核心优化
var position_to_card: Dictionary = {}  # position_index -> card_instance
var card_to_position: Dictionary = {}  # card_instance -> position_index

# 排序锁机制（防止并发排序导致的问题）
var is_sorting: bool = false

# 状态控制
var is_batch_operation: bool = false

## 选择管理器内部类
class SelectionManager:
	var selected_cards: Array = []
	var hand_dock: HandDock

	func _init(dock: HandDock):
		hand_dock = dock

	func update_selection(card_instance, is_selected: bool) -> bool:
		var index = selected_cards.find(card_instance)
		var changed = false

		if is_selected and index == -1:
			selected_cards.append(card_instance)
			changed = true
			LogManager.debug("HandDock", "卡牌已选中: %s" % card_instance.name)
		elif not is_selected and index != -1:
			selected_cards.remove_at(index)
			changed = true
			LogManager.debug("HandDock", "卡牌已取消选中: %s" % card_instance.name)

		if changed:
			hand_dock.emit_signal("card_selection_changed", selected_cards)
			hand_dock.update_ui()

		return changed

	func clear_selection():
		for card in selected_cards:
			if card.has_method("set_selected"):
				card.set_selected(false)
		selected_cards.clear()
		hand_dock.emit_signal("card_selection_changed", selected_cards)
		LogManager.info("HandDock", "已清空所有选择状态")

	func get_selected_cards() -> Array:
		return selected_cards.duplicate()

	func has_selection() -> bool:
		return selected_cards.size() > 0

## 初始化
func _ready():
	_load_config()
	_setup_components()
	_setup_ui_references()
	_setup_signal_connections()
	_initialize_position_system()

	LogManager.info("HandDock", "HandDock初始化完成")

## 加载配置
func _load_config():
	# 设置日志系统
	LogManager.set_debug_mode(config["debug_mode"])
	LogManager.set_log_level(config["log_level"])

## 设置组件
func _setup_components():
	selection_manager = SelectionManager.new(self)

## 设置UI引用
func _setup_ui_references():
	# 设置鼠标过滤器
	mouse_filter = MOUSE_FILTER_PASS
	if card_container:
		card_container.mouse_filter = MOUSE_FILTER_PASS

	# 验证关键节点
	if not play_button:
		LogManager.error("HandDock", "找不到PlayButton")
	if not discard_button:
		LogManager.error("HandDock", "找不到DiscardButton")

## 设置信号连接
func _setup_signal_connections():
	_connect_button_signals()
	_connect_existing_card_signals()

func _connect_button_signals():
	# 安全连接按钮信号
	if play_button and not play_button.pressed.is_connected(_on_play_button_pressed):
		play_button.pressed.connect(_on_play_button_pressed)

	if discard_button and not discard_button.pressed.is_connected(_on_discard_button_pressed):
		discard_button.pressed.connect(_on_discard_button_pressed)

	if sort_value_button and not sort_value_button.pressed.is_connected(_on_sort_value_button_pressed):
		sort_value_button.pressed.connect(_on_sort_value_button_pressed)

	if sort_suit_button and not sort_suit_button.pressed.is_connected(_on_sort_suit_button_pressed):
		sort_suit_button.pressed.connect(_on_sort_suit_button_pressed)

func _connect_existing_card_signals():
	if not card_container:
		return

	var existing_cards = 0
	for card in card_container.get_children():
		if card.has_method("get_card_data"):
			_connect_card_signals(card)
			existing_cards += 1

	if existing_cards > 0:
		LogManager.info("HandDock", "连接了%d张现有卡牌的信号" % existing_cards)

## 初始化位置系统
func _initialize_position_system():
	position_to_card.clear()
	card_to_position.clear()

## 设置TurnManager引用
func set_turn_manager(tm):
	turn_manager = tm

	if turn_manager:
		# 连接TurnManager信号
		if turn_manager.has_signal("play_button_state_changed"):
			turn_manager.play_button_state_changed.connect(_on_play_button_state_changed)
		if turn_manager.has_signal("cards_selected"):
			turn_manager.cards_selected.connect(_on_turn_manager_cards_selected)
		if turn_manager.has_signal("cards_deselected"):
			turn_manager.cards_deselected.connect(_on_turn_manager_cards_deselected)

		# 🔧 重要：连接CardManager的hand_changed信号以支持卡牌替换
		if turn_manager.has_method("get_card_manager"):
			var card_manager = turn_manager.get_card_manager()
			if card_manager and card_manager.has_signal("hand_changed"):
				if not card_manager.hand_changed.is_connected(_on_card_manager_hand_changed):
					card_manager.hand_changed.connect(_on_card_manager_hand_changed)
					LogManager.info("HandDock", "已连接CardManager.hand_changed信号")

		LogManager.info("HandDock", "TurnManager引用设置完成")

## 连接单张卡牌信号
func _connect_card_signals(card_instance):
	if not card_instance.has_method("get_card_data"):
		return

	# 检查并连接必要信号
	var signals_to_connect = [
		{"signal": "card_clicked", "method": "_on_card_clicked"},
		{"signal": "selection_changed", "method": "_on_card_selection_changed"}
	]

	for signal_info in signals_to_connect:
		var signal_name = signal_info.signal
		var method_name = signal_info.method

		if card_instance.has_signal(signal_name):
			if not card_instance.is_connected(signal_name, Callable(self, method_name)):
				card_instance.connect(signal_name, Callable(self, method_name))
		else:
			LogManager.error("HandDock", "卡牌缺少%s信号: %s" % [signal_name, card_instance.name])

## 更新UI状态
func update_ui():
	var state = _get_ui_state()
	_update_button_states(state)

func _get_ui_state() -> Dictionary:
	return {
		"has_selected_cards": selection_manager.has_selection(),
		"focus_available": _is_resource_available("focus"),
		"essence_available": _is_resource_available("essence")
	}

func _update_button_states(state: Dictionary):
	if play_button:
		play_button.disabled = not (state.has_selected_cards and state.focus_available)
	if discard_button:
		discard_button.disabled = not (state.has_selected_cards and state.essence_available)

func _is_resource_available(resource_type: String) -> bool:
	var game_mgr = get_node_or_null("/root/GameManager")
	if not game_mgr:
		return true

	match resource_type:
		"focus":
			if game_mgr.has_method("get_focus_count"):
				return game_mgr.get_focus_count() > 0
			else:
				return true
		"essence":
			if game_mgr.has_method("get_essence_count"):
				return game_mgr.get_essence_count() > 0
			else:
				return true
		_: return true

## 核心功能：智能卡牌替换系统（修复版）
func remove_selected_cards_and_refill():
	var selected = selection_manager.get_selected_cards()
	if selected.is_empty():
		LogManager.warning("HandDock", "没有选中的卡牌需要移除")
		return

	LogManager.info("HandDock", "开始移除%d张选中卡牌并补牌" % selected.size())

	# 诊断替换前状态
	print("=== 替换前诊断 ===")
	print_diagnosis()

	# 1. 记录当前状态（在移除之前）
	var initial_hand_size = get_current_hand_size()
	var removed_positions: Array = []

	# 收集要移除的位置信息
	for card in selected:
		if card_to_position.has(card):
			removed_positions.append(card_to_position[card])

	# 2. 移除选中的卡牌
	for card in selected:
		_remove_card_from_position(card)

	# 3. 清空选择状态
	selection_manager.clear_selection()

	# 4. 请求新卡牌补充
	var cards_needed = removed_positions.size()
	var new_cards = _request_new_cards(cards_needed)

	# 5. 修复版智能填充位置（参数验证）
	if removed_positions.size() != cards_needed:
		LogManager.error("HandDock", "位置数量不匹配：移除位置%d，需要卡牌%d" % [removed_positions.size(), cards_needed])
		return

	if new_cards.size() != cards_needed:
		LogManager.warning("HandDock", "新卡牌数量不足：请求%d，获得%d" % [cards_needed, new_cards.size()])

	_smart_fill_positions_fixed(removed_positions, new_cards, initial_hand_size)

	# 诊断替换后状态
	print("=== 替换后诊断 ===")
	print_diagnosis()

	LogManager.info("HandDock", "卡牌移除和补充完成")

## 修复版智能填充位置逻辑
func _smart_fill_positions_fixed(removed_positions: Array, new_cards: Array, target_hand_size: int):
	removed_positions.sort()  # 从左到右排序

	LogManager.debug("HandDock", "智能填充 - 移除位置: %s, 新卡牌数: %d, 目标手牌数: %d" % [
		str(removed_positions), new_cards.size(), target_hand_size
	])

	if new_cards.size() < removed_positions.size():
		_handle_insufficient_cards_fixed(removed_positions, new_cards, target_hand_size)
	else:
		_handle_direct_replacement_fixed(removed_positions, new_cards, target_hand_size)

## 原版智能填充位置逻辑（保留兼容性）
func _smart_fill_positions(removed_positions: Array, new_cards: Array):
	removed_positions.sort()  # 从左到右排序

	if new_cards.size() < removed_positions.size():
		_handle_insufficient_cards(removed_positions, new_cards)
	else:
		_handle_direct_replacement(removed_positions, new_cards)

## 修复版直接替换模式（卡牌数量足够）
func _handle_direct_replacement_fixed(positions: Array, new_cards: Array, target_hand_size: int):
	LogManager.debug("HandDock", "直接替换模式 - 位置: %s, 目标手牌数: %d" % [str(positions), target_hand_size])

	for i in range(positions.size()):
		var position_index = positions[i]
		var new_card = new_cards[i]
		_place_card_at_position(new_card, position_index, target_hand_size)

## 原版直接替换模式（保留兼容性）
func _handle_direct_replacement(positions: Array, new_cards: Array):
	# 计算最终手牌数量：当前剩余卡牌 + 新卡牌
	var remaining_cards = _get_all_positioned_cards()
	var final_hand_size = remaining_cards.size() + new_cards.size()

	for i in range(positions.size()):
		var position_index = positions[i]
		var new_card = new_cards[i]
		_place_card_at_position(new_card, position_index, final_hand_size)

## 修复版处理卡牌不足的情况
func _handle_insufficient_cards_fixed(removed_positions: Array, new_cards: Array, target_hand_size: int):
	LogManager.debug("HandDock", "卡牌不足处理 - 移除位置: %s, 新卡牌数: %d, 初始目标: %d" % [
		str(removed_positions), new_cards.size(), target_hand_size
	])

	# 1. 计算最终手牌数量（移除的卡牌数 > 新卡牌数）
	var cards_removed = removed_positions.size()
	var cards_added = new_cards.size()
	var final_hand_size = target_hand_size - cards_removed + cards_added

	LogManager.debug("HandDock", "卡牌不足计算 - 移除: %d, 添加: %d, 最终手牌数: %d" % [
		cards_removed, cards_added, final_hand_size
	])

	# 2. 优先填充最左边的位置（使用临时位置）
	for i in range(new_cards.size()):
		var position_index = removed_positions[i]
		_place_card_at_position(new_cards[i], position_index, final_hand_size)

	# 3. 重新排列所有卡牌以消除空隙并确保位置连续性
	_rebuild_layout_after_insufficient_cards()

## 原版处理卡牌不足的情况（保留兼容性）
func _handle_insufficient_cards(removed_positions: Array, new_cards: Array):
	# 1. 优先填充最左边的位置
	var remaining_cards = _get_all_positioned_cards()
	var final_hand_size = remaining_cards.size() + new_cards.size()

	for i in range(new_cards.size()):
		var position_index = removed_positions[i]
		_place_card_at_position(new_cards[i], position_index, final_hand_size)

	# 2. 处理空隙 - 重新计算布局
	var all_cards = _get_all_positioned_cards()
	if config["fixed_positions"].has(all_cards.size()):
		var new_layout = config["fixed_positions"][all_cards.size()]
		_apply_layout_transition(all_cards, new_layout)

## 重建布局（消除空隙，确保位置连续性）
func _rebuild_layout_after_insufficient_cards():
	LogManager.debug("HandDock", "重建布局以消除空隙")

	# 获取所有现存卡牌（只计算有效映射的卡牌）
	var all_cards = []
	for card_instance in card_to_position.keys():
		if card_instance and card_instance.is_inside_tree() and not card_instance.is_queued_for_deletion():
			all_cards.append(card_instance)

	# 同时检查场景树中的孤立卡牌
	if card_container:
		for child in card_container.get_children():
			if child.has_method("get_card_data") and not child.is_queued_for_deletion():
				if not all_cards.has(child):
					all_cards.append(child)
					LogManager.warning("HandDock", "发现孤立卡牌: %s，将其加入重建" % child.name)

	if all_cards.size() == 0:
		LogManager.debug("HandDock", "没有卡牌需要重建布局")
		return

	# 按当前位置排序（从左到右）
	all_cards.sort_custom(func(a, b): return a.position.x < b.position.x)

	# 获取新的布局位置
	var new_layout = config["fixed_positions"].get(all_cards.size(), [])
	if new_layout.is_empty():
		LogManager.error("HandDock", "没有找到%d张卡牌的布局配置" % all_cards.size())
		return

	LogManager.debug("HandDock", "重建布局 - %d张卡牌使用位置: %s" % [all_cards.size(), str(new_layout)])

	# 清空映射并重建（确保位置索引连续性：0, 1, 2, ...）
	position_to_card.clear()
	card_to_position.clear()

	# 应用新布局，确保位置索引从0开始连续
	for i in range(all_cards.size()):
		var card = all_cards[i]
		var new_x = new_layout[i]
		var new_pos = Vector2(new_x, 0)

		# 平滑移动到新位置
		if config["enable_selection_animation"]:
			var tween = create_tween()
			tween.tween_property(card, "position", new_pos, config["animation_duration"])
			# 动画完成后更新original_position
			tween.tween_callback(_update_card_original_position.bind(card, new_pos))
		else:
			card.position = new_pos
			# 立即更新original_position
			_update_card_original_position(card, new_pos)

		# 重建映射（位置索引从0开始连续）
		position_to_card[i] = card
		card_to_position[card] = i

		LogManager.debug("HandDock", "重建位置[%d] %s -> (%.1f, %.1f)" % [
			i, card.name if card.has_method("get_card_data") else "Unknown", new_pos.x, new_pos.y
		])

	LogManager.debug("HandDock", "布局重建完成，%d张卡牌重新排列到连续位置" % all_cards.size())

## 获取所有已定位的卡牌
func _get_all_positioned_cards() -> Array:
	var cards: Array = []
	var positions = position_to_card.keys()
	positions.sort()

	for pos in positions:
		if position_to_card.has(pos):
			cards.append(position_to_card[pos])

	return cards

## 安全获取所有已定位的卡牌（带验证）
func _get_all_positioned_cards_safe() -> Array:
	"""安全地获取所有卡牌，包含完整的验证和错误处理"""
	var cards: Array = []
	var positions = position_to_card.keys()
	positions.sort()

	LogManager.debug("HandDock", "安全获取卡牌，映射中有%d个位置" % positions.size())

	for pos in positions:
		if position_to_card.has(pos):
			var card = position_to_card[pos]
			if card and is_instance_valid(card):
				if card.is_inside_tree():
					cards.append(card)
					LogManager.debug("HandDock", "位置%d的卡牌有效: %s" % [pos, card.name])
				else:
					LogManager.warning("HandDock", "位置%d的卡牌不在场景树中" % pos)
			else:
				LogManager.warning("HandDock", "位置%d的卡牌无效或已释放" % pos)
		else:
			LogManager.warning("HandDock", "位置%d在keys中但不在映射中" % pos)

	LogManager.debug("HandDock", "安全获取完成，有效卡牌数: %d" % cards.size())
	return cards

## 紧急卡牌恢复（当排序导致卡牌丢失时）
func _emergency_card_recovery():
	"""当检测到卡牌丢失时的紧急恢复机制"""
	LogManager.error("HandDock", "启动紧急卡牌恢复机制")

	# 1. 收集所有在容器中但不在映射中的卡牌
	var container_cards = []
	if card_container:
		for child in card_container.get_children():
			if child.has_method("get_card_data"):
				container_cards.append(child)

	LogManager.info("HandDock", "容器中发现%d张卡牌" % container_cards.size())

	# 2. 重建映射
	position_to_card.clear()
	card_to_position.clear()

	# 3. 重新分配位置
	for i in range(container_cards.size()):
		var card = container_cards[i]
		position_to_card[i] = card
		card_to_position[card] = i

	# 4. 重建布局
	if container_cards.size() > 0:
		_rebuild_layout_after_insufficient_cards()

	LogManager.info("HandDock", "紧急恢复完成，恢复了%d张卡牌" % container_cards.size())

## 同步所有CardView实例的视觉状态
func _sync_all_card_visual_states():
	"""确保所有CardView实例的视觉状态与选择管理器状态一致"""
	LogManager.debug("HandDock", "开始同步所有卡牌视觉状态")

	var synced_count = 0
	for card in position_to_card.values():
		if card and is_instance_valid(card):
			if card.has_method("set_selected"):
				# 强制设置为未选中状态
				card.set_selected(false)
				synced_count += 1
				LogManager.debug("HandDock", "已同步卡牌 %s 的视觉状态为未选中" % card.name)
			else:
				LogManager.warning("HandDock", "卡牌 %s 没有set_selected方法" % card.name)
		else:
			LogManager.warning("HandDock", "发现无效卡牌实例")

	LogManager.info("HandDock", "视觉状态同步完成，已同步 %d 张卡牌" % synced_count)

## 应用布局过渡动画
func _apply_layout_transition(cards: Array, new_positions: Array):
	if cards.size() != new_positions.size():
		LogManager.error("HandDock", "卡牌数量与位置数量不匹配")
		return

	# 更新位置映射
	position_to_card.clear()
	card_to_position.clear()

	# 应用新位置
	for i in range(cards.size()):
		var card = cards[i]
		var new_x = new_positions[i]
		var new_pos = Vector2(new_x, 0)

		# 平滑动画到新位置
		if config["enable_selection_animation"]:
			var tween = create_tween()
			tween.tween_property(card, "position", new_pos, config["animation_duration"])
			# 动画完成后更新original_position
			tween.tween_callback(_update_card_original_position.bind(card, new_pos))
		else:
			card.position = new_pos
			# 立即更新original_position
			_update_card_original_position(card, new_pos)

		# 更新映射
		position_to_card[i] = card
		card_to_position[card] = i

## 在指定位置放置卡牌（增强版）
func _place_card_at_position(card_data_or_instance, position_index: int, target_hand_size: int = -1):
	# 确定目标手牌数量
	var final_hand_size = target_hand_size
	if final_hand_size == -1:
		final_hand_size = get_current_hand_size() + 1

	LogManager.debug("HandDock", "放置卡牌到位置 %d，目标手牌数: %d" % [position_index, final_hand_size])

	# 检查位置配置
	var positions = []
	if config["fixed_positions"].has(final_hand_size):
		positions = config["fixed_positions"][final_hand_size]
	else:
		LogManager.error("HandDock", "没有找到%d张卡牌的位置配置" % final_hand_size)
		return

	if positions.is_empty() or position_index >= positions.size() or position_index < 0:
		LogManager.error("HandDock", "位置索引超出范围: %d，目标手牌数量: %d，可用位置: %d" % [
			position_index, final_hand_size, positions.size()
		])
		return

	# 检查位置冲突
	if position_to_card.has(position_index):
		var existing_card = position_to_card[position_index]
		LogManager.warning("HandDock", "位置 %d 已被卡牌 %s 占用，将被替换" % [
			position_index, existing_card.name if existing_card else "Unknown"
		])
		_remove_card_from_position(existing_card)

	var target_x = positions[position_index]
	var target_pos = Vector2(target_x, 0)

	# 确保我们有一个Card节点实例
	var card_instance
	if card_data_or_instance is CardData:
		# 如果传入的是CardData，创建Card节点
		card_instance = _create_card_view(card_data_or_instance)
	else:
		# 如果传入的已经是Card节点
		card_instance = card_data_or_instance

	if not card_instance:
		LogManager.error("HandDock", "无法创建或获取卡牌实例")
		return

	# 检查卡牌是否已经在映射中
	if card_to_position.has(card_instance):
		var old_position = card_to_position[card_instance]
		LogManager.warning("HandDock", "卡牌已在位置 %d，将移动到位置 %d" % [old_position, position_index])
		position_to_card.erase(old_position)

	# 添加到容器
	if not card_instance.is_inside_tree():
		card_container.add_child(card_instance)
	card_instance.position = target_pos

	# 更新卡牌的original_position
	_update_card_original_position(card_instance, target_pos)

	# 更新映射
	position_to_card[position_index] = card_instance
	card_to_position[card_instance] = position_index

	# 连接信号
	_connect_card_signals(card_instance)

	LogManager.debug("HandDock", "卡牌成功放置到位置 %d，坐标: (%.1f, %.1f)" % [
		position_index, target_pos.x, target_pos.y
	])

## 从位置移除卡牌
func _remove_card_from_position(card_instance):
	if card_to_position.has(card_instance):
		var position_index = card_to_position[card_instance]
		position_to_card.erase(position_index)
		card_to_position.erase(card_instance)

	if card_instance.is_inside_tree():
		card_instance.queue_free()

## 请求新卡牌（需要与CardManager集成）
func _request_new_cards(count: int) -> Array:
	var new_cards: Array = []

	if turn_manager and turn_manager.has_method("request_cards_for_hand"):
		new_cards = turn_manager.request_cards_for_hand(count)
	else:
		LogManager.warning("HandDock", "无法请求新卡牌，TurnManager未设置或不支持")

	return new_cards

## 获取当前手牌数量
func get_current_hand_size() -> int:
	return position_to_card.size()

# 添加卡牌到手牌（修复版本）
func add_card(card_instance):
	if not card_instance:
		LogManager.error("HandDock", "card_instance为空")
		return false

	# 找到下一个可用位置
	var next_position = _find_next_available_position()
	if next_position == -1:
		LogManager.error("HandDock", "没有可用位置添加卡牌")
		return false

	# 🔧 修复：传递正确的目标手牌数量
	var target_hand_size = get_current_hand_size() + 1
	_place_card_at_position(card_instance, next_position, target_hand_size)
	return true

# 批量添加卡牌（修复初始位置问题）
func add_cards_batch(card_instances: Array):
	if card_instances.is_empty():
		LogManager.warning("HandDock", "没有卡牌需要添加")
		return false

	var current_size = get_current_hand_size()
	var target_hand_size = current_size + card_instances.size()
	var max_size = config["max_hand_size"]

	LogManager.debug("HandDock", "批量添加%d张卡牌，当前: %d, 目标: %d, 最大: %d" % [
		card_instances.size(), current_size, target_hand_size, max_size
	])

	if target_hand_size > max_size:
		LogManager.error("HandDock", "批量添加失败：超出最大手牌数量限制")
		return false

	# 批量添加，使用统一的目标手牌数量
	for i in range(card_instances.size()):
		var card_instance = card_instances[i]
		var position_index = current_size + i

		if position_index >= max_size:
			LogManager.error("HandDock", "位置索引超出范围: %d" % position_index)
			break

		_place_card_at_position(card_instance, position_index, target_hand_size)

	LogManager.info("HandDock", "批量添加完成，当前手牌数: %d" % get_current_hand_size())
	return true

## 找到下一个可用位置（增强版）
func _find_next_available_position() -> int:
	var current_size = get_current_hand_size()
	var max_size = config["max_hand_size"]

	LogManager.debug("HandDock", "查找可用位置 - 当前手牌数: %d, 最大: %d" % [current_size, max_size])

	if current_size >= max_size:
		LogManager.warning("HandDock", "手牌已满，无法添加更多卡牌")
		return -1

	# 找到第一个空闲位置
	for i in range(max_size):
		if not position_to_card.has(i):
			LogManager.debug("HandDock", "找到可用位置: %d" % i)
			return i

	LogManager.error("HandDock", "映射表异常：手牌数量%d但找不到空闲位置" % current_size)
	return -1

## 移除单张卡牌
func remove_card(card_instance):
	if not card_instance:
		return false

	_remove_card_from_position(card_instance)

	# 如果卡牌在选中列表中，移除它
	if selection_manager.selected_cards.has(card_instance):
		selection_manager.update_selection(card_instance, false)

	return true

## 清空所有卡牌
func clear_cards():
	LogManager.info("HandDock", "清空所有卡牌")

	# 清空选择状态
	selection_manager.clear_selection()

	# 移除所有卡牌
	for card in position_to_card.values():
		if card and card.is_inside_tree():
			card.queue_free()

	# 重置位置系统
	_initialize_position_system()
## 排序功能（修复版 - 防止卡牌丢失）
func sort_cards_by_value():
	# 🔧 修复0：排序锁机制，防止并发排序
	if is_sorting:
		LogManager.warning("HandDock", "排序正在进行中，忽略重复请求")
		return

	is_sorting = true

	# 🔧 新增：排序前清除所有选中状态，防止选中状态与排序后位置不匹配
	if selection_manager.has_selection():
		LogManager.info("HandDock", "排序前清除选中状态，当前选中: %d 张" % selection_manager.get_selected_cards().size())
		# 先通知TurnManager清除选择状态
		if turn_manager and turn_manager.has_method("clear_selection"):
			turn_manager.clear_selection()
		# 再清除HandDock内部的选择状态
		selection_manager.clear_selection()
		# 🔧 关键修复：同步更新所有CardView实例的视觉状态
		_sync_all_card_visual_states()

	# 🔧 修复1：获取卡牌前先验证系统状态
	var initial_count = get_current_hand_size()
	if initial_count == 0:
		LogManager.warning("HandDock", "没有卡牌需要排序")
		is_sorting = false
		return

	LogManager.info("HandDock", "开始按能量值排序，当前卡牌数: %d" % initial_count)

	# 🔧 修复2：安全获取卡牌列表
	var cards = _get_all_positioned_cards_safe()
	if cards.is_empty():
		LogManager.error("HandDock", "无法获取卡牌列表进行排序")
		is_sorting = false
		return

	if cards.size() != initial_count:
		LogManager.error("HandDock", "卡牌数量不匹配：期望%d，实际%d" % [initial_count, cards.size()])
		is_sorting = false
		return

	# 🔧 修复3：安全的排序（带错误处理）
	var sorted_cards = []
	for card in cards:
		if card and is_instance_valid(card) and card.has_method("get_card_data"):
			var card_data = card.get_card_data()
			if card_data:
				sorted_cards.append(card)
			else:
				LogManager.warning("HandDock", "卡牌缺少数据，跳过排序")
		else:
			LogManager.warning("HandDock", "发现无效卡牌，跳过排序")

	if sorted_cards.size() != cards.size():
		LogManager.error("HandDock", "排序验证失败：原始%d张，有效%d张" % [cards.size(), sorted_cards.size()])
		is_sorting = false
		return

	# 按数值排序
	sorted_cards.sort_custom(func(a, b):
		var a_data = a.get_card_data()
		var b_data = b.get_card_data()
		return a_data.base_value < b_data.base_value
	)

	# 🔧 修复4：安全的重新排列
	_rearrange_cards_with_order(sorted_cards)

	# 🔧 修复5：验证排序结果
	var final_count = get_current_hand_size()
	if final_count != initial_count:
		LogManager.error("HandDock", "排序后卡牌数量异常：排序前%d，排序后%d" % [initial_count, final_count])
		# 尝试恢复
		_emergency_card_recovery()
		is_sorting = false
		return

	# 延迟同步原始位置（等待动画完成）
	if config["enable_selection_animation"]:
		await get_tree().create_timer(config["animation_duration"] + 0.1).timeout
	_sync_all_card_original_positions()

	# 🔧 修复6：释放排序锁
	is_sorting = false
	LogManager.info("HandDock", "能量值排序完成，卡牌数量: %d" % final_count)

func sort_cards_by_suit():
	# 🔧 修复0：排序锁机制，防止并发排序
	if is_sorting:
		LogManager.warning("HandDock", "排序正在进行中，忽略重复请求")
		return

	is_sorting = true

	# 🔧 新增：排序前清除所有选中状态，防止选中状态与排序后位置不匹配
	if selection_manager.has_selection():
		LogManager.info("HandDock", "排序前清除选中状态，当前选中: %d 张" % selection_manager.get_selected_cards().size())
		# 先通知TurnManager清除选择状态
		if turn_manager and turn_manager.has_method("clear_selection"):
			turn_manager.clear_selection()
		# 再清除HandDock内部的选择状态
		selection_manager.clear_selection()
		# 🔧 关键修复：同步更新所有CardView实例的视觉状态
		_sync_all_card_visual_states()

	# 🔧 修复1：获取卡牌前先验证系统状态
	var initial_count = get_current_hand_size()
	if initial_count == 0:
		LogManager.warning("HandDock", "没有卡牌需要排序")
		is_sorting = false
		return

	LogManager.info("HandDock", "开始按元素排序，当前卡牌数: %d" % initial_count)

	# 🔧 修复2：安全获取卡牌列表
	var cards = _get_all_positioned_cards_safe()
	if cards.is_empty():
		LogManager.error("HandDock", "无法获取卡牌列表进行排序")
		is_sorting = false
		return

	if cards.size() != initial_count:
		LogManager.error("HandDock", "卡牌数量不匹配：期望%d，实际%d" % [initial_count, cards.size()])
		is_sorting = false
		return

	# 🔧 修复3：安全的排序（带错误处理）
	var sorted_cards = []
	for card in cards:
		if card and is_instance_valid(card) and card.has_method("get_card_data"):
			var card_data = card.get_card_data()
			if card_data:
				sorted_cards.append(card)
			else:
				LogManager.warning("HandDock", "卡牌缺少数据，跳过排序")
		else:
			LogManager.warning("HandDock", "发现无效卡牌，跳过排序")

	if sorted_cards.size() != cards.size():
		LogManager.error("HandDock", "排序验证失败：原始%d张，有效%d张" % [cards.size(), sorted_cards.size()])
		is_sorting = false
		return

	# 按花色排序
	sorted_cards.sort_custom(func(a, b):
		var a_data = a.get_card_data()
		var b_data = b.get_card_data()
		if a_data.suit == b_data.suit:
			return a_data.base_value < b_data.base_value
		return a_data.suit < b_data.suit
	)

	# 🔧 修复4：安全的重新排列
	_rearrange_cards_with_order(sorted_cards)

	# 🔧 修复5：验证排序结果
	var final_count = get_current_hand_size()
	if final_count != initial_count:
		LogManager.error("HandDock", "排序后卡牌数量异常：排序前%d，排序后%d" % [initial_count, final_count])
		# 尝试恢复
		_emergency_card_recovery()
		is_sorting = false
		return

	# 延迟同步原始位置（等待动画完成）
	if config["enable_selection_animation"]:
		await get_tree().create_timer(config["animation_duration"] + 0.1).timeout
	_sync_all_card_original_positions()

	# 🔧 修复6：释放排序锁
	is_sorting = false
	LogManager.info("HandDock", "元素排序完成，卡牌数量: %d" % final_count)

## 按指定顺序重新排列卡牌（修复版 - 防止竞态条件）
func _rearrange_cards_with_order(ordered_cards: Array):
	var positions = []
	if config["fixed_positions"].has(ordered_cards.size()):
		positions = config["fixed_positions"][ordered_cards.size()]

	if positions.is_empty():
		LogManager.error("HandDock", "没有找到%d张卡牌的位置配置" % ordered_cards.size())
		return

	LogManager.debug("HandDock", "开始重新排列%d张卡牌" % ordered_cards.size())

	# 🔧 修复1：先停止所有现有的动画，防止冲突
	_stop_all_card_animations()

	# 🔧 修复2：验证所有卡牌都存在且有效
	var valid_cards = []
	for card in ordered_cards:
		if card and is_instance_valid(card) and card.is_inside_tree():
			valid_cards.append(card)
		else:
			LogManager.warning("HandDock", "发现无效卡牌，已跳过")

	if valid_cards.size() != ordered_cards.size():
		LogManager.error("HandDock", "卡牌验证失败：期望%d张，有效%d张" % [ordered_cards.size(), valid_cards.size()])
		return

	# 🔧 修复3：立即重建映射，不清空（避免竞态条件）
	var new_position_to_card = {}
	var new_card_to_position = {}

	# 应用新顺序并构建新映射
	for i in range(valid_cards.size()):
		var card = valid_cards[i]
		var new_x = positions[i]
		var new_pos = Vector2(new_x, 0)

		# 构建新映射
		new_position_to_card[i] = card
		new_card_to_position[card] = i

		# 移动卡牌
		if config["enable_selection_animation"]:
			var tween = create_tween()
			tween.tween_property(card, "position", new_pos, config["animation_duration"])
			# 动画完成后更新original_position（使用安全的回调）
			tween.tween_callback(_safe_update_card_original_position.bind(card, new_pos))
		else:
			card.position = new_pos
			# 立即更新original_position
			_safe_update_card_original_position(card, new_pos)

	# 🔧 修复4：原子性更新映射（一次性替换，避免中间状态）
	position_to_card = new_position_to_card
	card_to_position = new_card_to_position

	LogManager.info("HandDock", "卡牌重新排列完成，映射已更新：%d张卡牌" % valid_cards.size())

## 停止所有卡牌动画（防止冲突）
func _stop_all_card_animations():
	"""停止所有正在进行的卡牌动画，防止排序时的冲突"""
	for card in position_to_card.values():
		if card and is_instance_valid(card):
			# 停止卡牌上的所有Tween
			var tweens = card.get_tree().get_nodes_in_group("card_tweens")
			for tween in tweens:
				if tween and is_instance_valid(tween):
					tween.kill()

	LogManager.debug("HandDock", "已停止所有卡牌动画")

## 安全的原始位置更新（带验证）
func _safe_update_card_original_position(card, new_pos: Vector2):
	"""安全地更新卡牌的original_position，带有完整的验证"""
	if not card or not is_instance_valid(card):
		LogManager.warning("HandDock", "尝试更新无效卡牌的原始位置")
		return

	if not card.is_inside_tree():
		LogManager.warning("HandDock", "尝试更新不在场景树中的卡牌原始位置")
		return

	if card.has_method("set_original_position"):
		card.set_original_position(new_pos)
		LogManager.debug("HandDock", "已安全更新卡牌 %s 的原始位置到 (%.1f, %.1f)" % [
			card.name if card.has_method("get_card_name") else "Unknown",
			new_pos.x, new_pos.y
		])
	else:
		LogManager.warning("HandDock", "卡牌没有set_original_position方法")

## 更新卡牌的原始位置（排序后同步）
func _update_card_original_position(card, new_pos: Vector2):
	"""更新卡牌的original_position，确保悬停和选择效果正确"""
	if card and card.has_method("set_original_position"):
		card.set_original_position(new_pos)
		LogManager.debug("HandDock", "已更新卡牌 %s 的原始位置到 (%.1f, %.1f)" % [
			card.name if card.has_method("get_card_name") else "Unknown",
			new_pos.x, new_pos.y
		])

## 强制同步所有卡牌的原始位置（排序后的安全措施）
func _sync_all_card_original_positions():
	"""强制同步所有卡牌的original_position到当前position，解决排序后的位置不一致问题"""
	LogManager.debug("HandDock", "开始同步所有卡牌的原始位置")

	for card in position_to_card.values():
		if card and card.has_method("set_original_position"):
			var current_pos = card.position
			card.set_original_position(current_pos)
			LogManager.debug("HandDock", "同步卡牌 %s 原始位置到 (%.1f, %.1f)" % [
				card.name if card.has_method("get_card_name") else "Unknown",
				current_pos.x, current_pos.y
			])

	LogManager.info("HandDock", "所有卡牌原始位置同步完成")

## 信号处理函数

## 处理卡牌点击
func _on_card_clicked(card_instance):
	LogManager.debug("HandDock", "收到卡牌点击事件: %s" % card_instance.name)

	var card_data = card_instance.get_card_data()
	if not card_data:
		LogManager.error("HandDock", "无法获取卡牌数据")
		return

	# 获取当前选择状态
	var current_selected = card_instance.get_selected_state() if card_instance.has_method("get_selected_state") else false

	# 通过TurnManager处理选择逻辑
	if turn_manager:
		if current_selected:
			# 尝试取消选择
			if turn_manager.deselect_card(card_data):
				card_instance.set_selected(false)
				selection_manager.update_selection(card_instance, false)
				emit_signal("card_deselected_for_play", card_data)
			else:
				LogManager.debug("HandDock", "TurnManager拒绝取消选择")
		else:
			# 尝试选择
			if turn_manager.select_card(card_data):
				card_instance.set_selected(true)
				selection_manager.update_selection(card_instance, true)
				emit_signal("card_selected_for_play", card_data)
			else:
				LogManager.debug("HandDock", "TurnManager拒绝选择")
	else:
		# 回退逻辑
		var is_selected = card_instance.toggle_selected() if card_instance.has_method("toggle_selected") else false
		selection_manager.update_selection(card_instance, is_selected)

	# 更新UI
	update_ui()

## 处理卡牌选择状态变化
func _on_card_selection_changed(card_instance, is_selected):
	selection_manager.update_selection(card_instance, is_selected)

## 处理出牌按钮点击
func _on_play_button_pressed():
	LogManager.info("HandDock", "出牌按钮被点击")

	if turn_manager and turn_manager.has_method("play_selected_cards"):
		turn_manager.play_selected_cards()
	else:
		# 回退到发送信号
		if selection_manager.has_selection():
			emit_signal("play_button_pressed")
		else:
			LogManager.warning("HandDock", "没有选中卡牌")

## 处理弃牌按钮点击
func _on_discard_button_pressed():
	LogManager.info("HandDock", "弃牌按钮被点击")

	if selection_manager.has_selection():
		emit_signal("discard_button_pressed")
	else:
		LogManager.warning("HandDock", "没有选中卡牌")

## 处理排序按钮
func _on_sort_value_button_pressed():
	sort_cards_by_value()

func _on_sort_suit_button_pressed():
	sort_cards_by_suit()

## TurnManager信号处理
func _on_play_button_state_changed(enabled: bool, reason: String):
	LogManager.debug("HandDock", "出牌按钮状态变化 - 启用: %s, 原因: %s" % [enabled, reason])

	if play_button:
		play_button.disabled = not enabled

func _on_turn_manager_cards_selected(selected_card_data_list: Array):
	LogManager.debug("HandDock", "收到TurnManager卡牌选择信号，数量: %d" % selected_card_data_list.size())

func _on_turn_manager_cards_deselected(deselected_card_data_list: Array):
	LogManager.debug("HandDock", "收到TurnManager卡牌取消选择信号，数量: %d" % deselected_card_data_list.size())

## 🔧 处理CardManager的手牌变化信号（支持卡牌替换）
func _on_card_manager_hand_changed(hand_cards: Array):
	LogManager.info("HandDock", "收到CardManager手牌变化信号，当前手牌数量: %d" % hand_cards.size())

	# 同步HandDock的视图与CardManager的数据
	_sync_hand_with_card_manager(hand_cards)

## 🔧 同步HandDock视图与CardManager数据
func _sync_hand_with_card_manager(hand_cards: Array):
	LogManager.debug("HandDock", "开始同步HandDock视图与CardManager数据")

	# 清除当前所有卡牌视图
	_clear_all_cards()

	# 为新的手牌数据创建视图
	if hand_cards.size() > 0:
		_create_views_for_hand_cards(hand_cards)

	LogManager.info("HandDock", "HandDock视图同步完成，当前显示 %d 张卡牌" % hand_cards.size())

## 🔧 清除所有卡牌视图
func _clear_all_cards():
	# 清除映射
	for card_instance in position_to_card.values():
		if card_instance and is_instance_valid(card_instance):
			card_instance.queue_free()

	position_to_card.clear()
	card_to_position.clear()

	# 清除选择状态
	selection_manager.clear_selection()

## 🔧 为手牌数据创建视图
func _create_views_for_hand_cards(hand_cards: Array):
	var target_hand_size = hand_cards.size()

	for i in range(hand_cards.size()):
		var card_data = hand_cards[i]
		if card_data:
			# 创建卡牌视图
			var card_instance = _create_card_view(card_data)
			if card_instance:
				# 放置到正确位置
				_place_card_at_position(card_instance, i, target_hand_size)

## 公共接口方法

## 获取选中的卡牌
func get_selected_cards() -> Array:
	return selection_manager.get_selected_cards()

## 清空选择
func clear_selection():
	selection_manager.clear_selection()

## 获取卡牌容器
func get_card_container():
	return card_container

## 检查是否有选中的卡牌
func has_selected_cards() -> bool:
	return selection_manager.has_selection()

## 获取手牌数量
func get_hand_size() -> int:
	return get_current_hand_size()

## 移除已出牌的卡牌视图（供外部调用）
func remove_played_cards(played_card_data_list: Array):
	LogManager.info("HandDock", "开始移除已出牌的卡牌视图，数量: %d" % played_card_data_list.size())

	var cards_to_remove = []

	# 查找匹配的卡牌视图
	for card_data in played_card_data_list:
		for card_view in position_to_card.values():
			if card_view.has_method("get_card_data"):
				var view_card_data = card_view.get_card_data()
				if view_card_data == card_data:
					cards_to_remove.append(card_view)
					break

	# 移除卡牌视图
	for card_view in cards_to_remove:
		remove_card(card_view)

	LogManager.info("HandDock", "已移除%d张卡牌视图" % cards_to_remove.size())
## 调试功能（仅DEBUG模式）
func _verify_positions():
	if not config["debug_mode"] or not config["enable_position_validation"]:
		return

	LogManager.debug("HandDock", "开始位置验证")
	var cards = _get_all_positioned_cards()
	var expected_positions = []
	if config["fixed_positions"].has(cards.size()):
		expected_positions = config["fixed_positions"][cards.size()]

	if expected_positions.is_empty():
		LogManager.warning("HandDock", "无法获取预期位置")
		return

	var errors = []
	for i in range(cards.size()):
		var card = cards[i]
		var expected_x = expected_positions[i]
		var actual_x = card.position.x
		var error = abs(actual_x - expected_x)

		if error > 1.0:  # 允许1像素误差
			errors.append("卡牌[%d] 预期X=%.1f, 实际X=%.1f, 误差=%.1f" % [i, expected_x, actual_x, error])

	if errors.is_empty():
		LogManager.debug("HandDock", "位置验证通过")
	else:
		LogManager.warning("HandDock", "位置验证发现问题: %s" % str(errors))

## 创建卡牌视图
func _create_card_view(card_data: CardData):
	if not card_data:
		LogManager.error("HandDock", "CardData为空，无法创建卡牌视图")
		return null

	if not card_scene:
		LogManager.error("HandDock", "Card场景未设置，无法创建卡牌视图")
		return null

	var card_instance = card_scene.instantiate()
	if not card_instance:
		LogManager.error("HandDock", "无法实例化Card场景")
		return null

	# 设置卡牌数据
	if card_instance.has_method("setup"):
		card_instance.setup(card_data)
	elif card_instance.has_method("set_card_data"):
		card_instance.set_card_data(card_data)
	else:
		LogManager.warning("HandDock", "Card实例没有setup或set_card_data方法")

	LogManager.debug("HandDock", "成功创建卡牌视图: %s" % card_data.name)
	return card_instance

## 位置系统诊断函数
func diagnose_position_system() -> Dictionary:
	var diagnosis = {
		"timestamp": Time.get_datetime_string_from_system(),
		"total_cards": 0,
		"position_mapping_errors": [],
		"position_conflicts": [],
		"missing_positions": [],
		"orphaned_cards": [],
		"layout_consistency": true,
		"expected_positions": [],
		"actual_positions": []
	}

	# 获取所有有效映射的卡牌（修复版）
	var all_cards = []
	var mapped_cards = []

	# 从映射表获取有效卡牌
	for card_instance in card_to_position.keys():
		if card_instance and card_instance.is_inside_tree():
			mapped_cards.append(card_instance)

	# 从场景树获取所有卡牌（用于检测孤立卡牌）
	if card_container:
		for child in card_container.get_children():
			if child.has_method("get_card_data") and not child.is_queued_for_deletion():
				all_cards.append(child)

	diagnosis.total_cards = all_cards.size()

	# 检测孤立卡牌（在场景树中但不在映射中）
	for card in all_cards:
		if not card_to_position.has(card):
			diagnosis.orphaned_cards.append("卡牌 %s 没有位置映射" % card.name)

	# 检查双向映射一致性
	for card in mapped_cards:
		var pos_index = card_to_position[card]
		if not position_to_card.has(pos_index):
			diagnosis.position_mapping_errors.append("卡牌 %s 在card_to_position中但不在position_to_card中" % card.name)
		elif position_to_card[pos_index] != card:
			diagnosis.position_mapping_errors.append("位置 %d 的映射不一致" % pos_index)

	# 检查位置冲突
	var used_positions = {}
	for pos_index in position_to_card.keys():
		if used_positions.has(pos_index):
			diagnosis.position_conflicts.append("位置 %d 被多张卡牌占用" % pos_index)
		used_positions[pos_index] = true

	# 检查布局一致性（使用映射卡牌数量）
	var mapped_card_count = mapped_cards.size()
	if mapped_card_count > 0:
		var expected_layout = config["fixed_positions"].get(mapped_card_count, [])
		diagnosis.expected_positions = expected_layout

		# 获取实际位置（基于映射）
		for i in range(mapped_card_count):
			if position_to_card.has(i):
				var card = position_to_card[i]
				diagnosis.actual_positions.append({
					"index": i,
					"expected_x": expected_layout[i] if i < expected_layout.size() else -1,
					"actual_x": card.position.x,
					"card_name": card.name if card.has_method("get_card_data") else "Unknown"
				})
			else:
				diagnosis.missing_positions.append("位置 %d 没有卡牌" % i)

	return diagnosis

## 打印诊断报告
func print_diagnosis():
	var report = diagnose_position_system()
	print("=== HandDock位置系统诊断报告 ===")
	print("时间: %s" % report.timestamp)
	print("总卡牌数: %d" % report.total_cards)
	print("映射错误: %d" % report.position_mapping_errors.size())
	print("位置冲突: %d" % report.position_conflicts.size())
	print("缺失位置: %d" % report.missing_positions.size())
	print("孤立卡牌: %d" % report.orphaned_cards.size())

	if report.position_mapping_errors.size() > 0:
		print("映射错误详情:")
		for error in report.position_mapping_errors:
			print("  - %s" % error)

	if report.position_conflicts.size() > 0:
		print("位置冲突详情:")
		for conflict in report.position_conflicts:
			print("  - %s" % conflict)

	if report.actual_positions.size() > 0:
		print("位置详情:")
		for pos_info in report.actual_positions:
			var diff = abs(pos_info.actual_x - pos_info.expected_x) if pos_info.expected_x != -1 else 0
			print("  位置[%d] %s: 期望=%.1f, 实际=%.1f, 偏差=%.1f" % [
				pos_info.index, pos_info.card_name, pos_info.expected_x, pos_info.actual_x, diff
			])

	print("=== 诊断完成 ===")
	return report

## 🔄 卡牌替换功能
# 替换指定位置的卡牌
func replace_card_at_index(index: int, new_card_data: CardData) -> bool:
	"""
	替换指定位置的卡牌

	参数:
	- index: 要替换的卡牌位置索引
	- new_card_data: 新的卡牌数据

	返回:
	- bool: 替换是否成功
	"""
	if not new_card_data:
		LogManager.error("HandDock", "新卡牌数据无效")
		return false

	# 检查索引是否有效
	if not position_to_card.has(index):
		LogManager.error("HandDock", "位置 %d 没有卡牌可以替换" % index)
		return false

	var old_card = position_to_card[index]
	if not old_card:
		LogManager.error("HandDock", "位置 %d 的卡牌实例无效" % index)
		return false

	LogManager.info("HandDock", "开始替换位置 %d 的卡牌: %s -> %s" % [
		index,
		old_card.card_data.name if old_card.card_data else "Unknown",
		new_card_data.name
	])

	# 保存旧卡牌的位置信息
	var old_position = old_card.position
	var was_selected = old_card in selection_manager.selected_cards

	# 移除旧卡牌
	_remove_card_from_position(old_card)

	# 创建新卡牌视图
	var new_card_instance = _create_card_view(new_card_data)
	if not new_card_instance:
		LogManager.error("HandDock", "无法创建新卡牌视图")
		return false

	# 将新卡牌放置到相同位置
	_place_card_at_position_internal(new_card_instance, index, old_position)

	# 如果旧卡牌被选中，选中新卡牌
	if was_selected:
		if new_card_instance.has_method("set_selected"):
			new_card_instance.set_selected(true)
		selection_manager.update_selection(new_card_instance, true)

	LogManager.info("HandDock", "成功替换位置 %d 的卡牌" % index)

	# 发出卡牌变化信号
	emit_signal("hand_composition_changed")

	return true

# 内部方法：在指定位置放置卡牌（不进行额外检查）
func _place_card_at_position_internal(card_instance, position_index: int, target_pos: Vector2):
	"""
	内部方法：直接在指定位置放置卡牌

	参数:
	- card_instance: 卡牌实例
	- position_index: 位置索引
	- target_pos: 目标位置坐标
	"""
	# 添加到容器
	if not card_instance.is_inside_tree():
		card_container.add_child(card_instance)

	card_instance.position = target_pos

	# 更新卡牌的original_position
	_update_card_original_position(card_instance, target_pos)

	# 更新映射
	position_to_card[position_index] = card_instance
	card_to_position[card_instance] = position_index

	# 连接信号
	_connect_card_signals(card_instance)

	LogManager.debug("HandDock", "卡牌已放置在位置 %d: %s" % [position_index, card_instance.card_data.name])

# 获取所有卡牌的CardData数组
func get_card_data_array() -> Array:
	"""
	获取当前所有卡牌的CardData数组

	返回:
	- Array: CardData数组
	"""
	var card_data_array = []

	# 按位置顺序收集卡牌数据
	var positions = position_to_card.keys()
	positions.sort()

	for pos in positions:
		var card_instance = position_to_card[pos]
		if card_instance and card_instance.card_data:
			card_data_array.append(card_instance.card_data)

	return card_data_array
