class_name DeckViewDialogSimple
extends Window

# 常量 - 优化的单页面布局参数，充分利用空间
const CARD_SIZE = Vector2(85, 120)  # 适度增大卡牌尺寸，提高可读性
const CARD_SPACING = Vector2(8, 10)  # 适中间距，保持视觉清晰度和空间利用
const CARDS_PER_ROW = 13  # 每行显示13张牌
const CONTAINER_MARGIN = 20  # 适中的容器边距

# 简洁的颜色主题
const THEME_COLORS = {
	"background": Color(0.1, 0.1, 0.15, 0.95),
	"panel": Color(0.15, 0.15, 0.2, 0.8),
	"accent": Color(0.4, 0.6, 0.9, 1.0),
	"text_primary": Color(0.9, 0.9, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.7, 0.8, 1.0),
	"border": Color(0.3, 0.3, 0.4, 0.5)
}

# 节点引用
var tab_container: TabContainer
var all_cards_container: VBoxContainer
var current_deck_container: VBoxContainer
var background_panel: Panel

# 数据
var all_cards_data = []
var current_deck_data = []
var played_cards_data = []

# 点击防抖相关
var last_click_time = 0.0
var click_debounce_delay = 0.2  # 200ms防抖延迟

# 预加载场景
var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")

func _init():
	# 设置窗口属性 - 优化尺寸和体验
	title = "奥术学院 - 符文库"
	size = Vector2(1650, 980)  # 进一步优化窗口尺寸以适应改进的布局
	min_size = Vector2(1450, 850)
	exclusive = true
	unresizable = false
	transient = true

	# 设置关闭请求回调
	close_requested.connect(_on_close_requested)

	# 监听窗口大小变化以确保标题始终居中
	size_changed.connect(_on_window_size_changed)

	# 创建UI
	_create_ui()

# 创建UI
func _create_ui():
	# 创建背景面板
	background_panel = Panel.new()
	background_panel.anchor_right = 1.0
	background_panel.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = THEME_COLORS.background
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.corner_radius_bottom_right = 12
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = THEME_COLORS.border
	background_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(background_panel)

	# 创建主容器
	var main_container = VBoxContainer.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_left = 40  # 适中的左边距，保持视觉平衡
	main_container.offset_top = 15
	main_container.offset_right = -40  # 对称的右边距，充分利用窗口宽度
	main_container.offset_bottom = -15
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)

	# 创建标题栏
	_create_title_header(main_container)

	# 创建标签容器
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tab_container(tab_container)
	main_container.add_child(tab_container)

	# 创建"全部牌"标签页
	var all_cards_scroll = ScrollContainer.new()
	all_cards_scroll.name = "全部牌"
	all_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	all_cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	all_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(all_cards_scroll)

	# 添加边距容器防止卡牌被裁剪
	var all_cards_margin = MarginContainer.new()
	all_cards_margin.add_theme_constant_override("margin_left", 30)  # 增加左边距，改善视觉平衡
	all_cards_margin.add_theme_constant_override("margin_right", 30)  # 增加右边距，保持对称
	all_cards_margin.add_theme_constant_override("margin_top", 10)
	all_cards_margin.add_theme_constant_override("margin_bottom", 10)
	all_cards_scroll.add_child(all_cards_margin)

	all_cards_container = VBoxContainer.new()
	all_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_cards_container.add_theme_constant_override("separation", 8)
	all_cards_margin.add_child(all_cards_container)

	# 创建"当前牌库"标签页
	var current_deck_scroll = ScrollContainer.new()
	current_deck_scroll.name = "当前牌库"
	current_deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	current_deck_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	current_deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(current_deck_scroll)

	# 添加边距容器防止卡牌被裁剪
	var current_deck_margin = MarginContainer.new()
	current_deck_margin.add_theme_constant_override("margin_left", 30)  # 增加左边距，改善视觉平衡
	current_deck_margin.add_theme_constant_override("margin_right", 30)  # 增加右边距，保持对称
	current_deck_margin.add_theme_constant_override("margin_top", 10)
	current_deck_margin.add_theme_constant_override("margin_bottom", 10)
	current_deck_scroll.add_child(current_deck_margin)

	current_deck_container = VBoxContainer.new()
	current_deck_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_deck_container.add_theme_constant_override("separation", 8)
	current_deck_margin.add_child(current_deck_container)

	# 创建底部按钮栏
	_create_bottom_panel(main_container)

# 创建简洁标题栏
func _create_title_header(parent: Container):
	# 简单的标题文本
	var title_label = Label.new()
	title_label.text = "牌库查看器"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", THEME_COLORS.text_primary)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(title_label)

	# 调试输出：延迟调用以确保节点已添加到场景树
	call_deferred("_debug_title_position", title_label, parent)

# 调试标题位置
func _debug_title_position(title_label: Label, parent: Container):
	# 获取窗口尺寸
	var window_size = size
	var window_center_x = window_size.x / 2

	# 获取标题标签的全局位置和尺寸
	var title_global_rect = title_label.get_global_rect()
	var title_center_x = title_global_rect.position.x + title_global_rect.size.x / 2

	# 获取父容器的全局位置和尺寸
	var parent_global_rect = parent.get_global_rect()
	var parent_center_x = parent_global_rect.position.x + parent_global_rect.size.x / 2

	# 计算偏差
	var title_offset_from_window = title_center_x - window_center_x
	var title_offset_from_parent = title_center_x - parent_center_x

	# 检查并修复标题居中
	if abs(title_offset_from_window) > 10:
		_fix_title_centering(title_label)

# 修复标题居中
func _fix_title_centering(title_label: Label):
	# 强制设置标题标签的尺寸和对齐
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	# 确保父容器也正确设置
	var parent = title_label.get_parent()
	if parent is VBoxContainer:
		parent.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 强制更新布局
	title_label.queue_redraw()
	if parent:
		parent.queue_redraw()







# 修复统计数据栏居中 - 使用MarginContainer
func _fix_stats_centering_with_margin_container(stats_wrapper: MarginContainer, stats_panel: PanelContainer):
	# 获取窗口和面板的实际尺寸
	var window_width = size.x
	var panel_width = stats_panel.get_global_rect().size.x

	# 获取父容器的边距（考虑到对话框的边距）
	var parent_margin = 40  # 从调试输出可以看到父容器从X=40开始
	var available_width = window_width - (parent_margin * 2)
	var margin_needed = (available_width - panel_width) / 2

	# 设置左右边距来强制居中
	stats_wrapper.add_theme_constant_override("margin_left", margin_needed)
	stats_wrapper.add_theme_constant_override("margin_right", margin_needed)
	stats_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# 强制更新布局
	stats_wrapper.queue_redraw()
	stats_panel.queue_redraw()





# 触发调试输出
func _trigger_debug_output():
	# 查找标题标签
	var main_container = get_children()[1]  # 背景面板是第一个，主容器是第二个
	if main_container and main_container.get_child_count() > 0:
		var title_label = main_container.get_child(0)  # 标题是主容器的第一个子节点
		if title_label is Label:
			_debug_title_position(title_label, main_container)

# 样式化标签容器
func _style_tab_container(tab_cont: TabContainer):
	tab_cont.add_theme_font_size_override("font_size", 14)
	tab_cont.add_theme_color_override("font_selected_color", THEME_COLORS.text_primary)
	tab_cont.add_theme_color_override("font_unselected_color", THEME_COLORS.text_secondary)

# 创建底部面板
func _create_bottom_panel(parent: Container):
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(100, 35)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_button_pressed)
	parent.add_child(close_button)

# 设置数据
func set_data(all_cards, current_deck, played_cards):
	all_cards_data = all_cards
	current_deck_data = current_deck
	played_cards_data = played_cards
	_update_ui()

	# 在数据设置后触发调试输出
	call_deferred("_trigger_debug_output")

# 更新UI
func _update_ui():
	# 清空容器
	for child in all_cards_container.get_children():
		all_cards_container.remove_child(child)
		child.queue_free()
	
	for child in current_deck_container.get_children():
		current_deck_container.remove_child(child)
		child.queue_free()
	
	# 按花色分组卡牌
	var cards_by_suit = {
		"spades": [],   # 黑桃
		"hearts": [],   # 红心
		"diamonds": [], # 方片
		"clubs": []     # 梅花
	}
	
	# 分类所有卡牌
	for card_data in all_cards_data:
		var suit = card_data.suit
		if cards_by_suit.has(suit):
			cards_by_suit[suit].append(card_data)
	
	# 对每个花色的卡牌按点数排序（从小到大）
	for suit in cards_by_suit.keys():
		cards_by_suit[suit].sort_custom(func(a, b): return a.base_value < b.base_value)
	
	# 统计数据
	var all_stats = _calculate_stats(all_cards_data)
	var current_stats = _calculate_stats(current_deck_data)
	
	# 填充"全部牌"标签页
	_populate_simple_cards_view(all_cards_container, cards_by_suit, played_cards_data, all_stats)
	
	# 按花色分组当前牌库卡牌
	var current_cards_by_suit = {
		"spades": [],
		"hearts": [],
		"diamonds": [],
		"clubs": []
	}
	
	# 分类当前牌库卡牌
	for card_data in current_deck_data:
		var suit = card_data.suit
		if current_cards_by_suit.has(suit):
			current_cards_by_suit[suit].append(card_data)
	
	# 对每个花色的卡牌按点数排序
	for suit in current_cards_by_suit.keys():
		current_cards_by_suit[suit].sort_custom(func(a, b): return a.base_value < b.base_value)
	
	# 填充"当前牌库"标签页
	_populate_simple_cards_view(current_deck_container, current_cards_by_suit, [], current_stats)

# 计算统计数据
func _calculate_stats(cards_data):
	var stats = {
		"total": cards_data.size(),
		"aces": 0,
		"face_cards": 0,
		"jacks": 0,
		"queens": 0,
		"kings": 0,
		"suits": {
			"spades": 0,
			"hearts": 0,
			"diamonds": 0,
			"clubs": 0
		}
	}
	
	for card_data in cards_data:
		# 统计A牌
		if card_data.base_value == 1:
			stats.aces += 1
		
		# 统计人头牌
		if card_data.base_value >= 11:
			stats.face_cards += 1
			if card_data.base_value == 11:
				stats.jacks += 1
			elif card_data.base_value == 12:
				stats.queens += 1
			elif card_data.base_value == 13:
				stats.kings += 1
		
		# 统计花色
		var suit = card_data.suit
		if stats.suits.has(suit):
			stats.suits[suit] += 1
	
	return stats

# 简洁的卡牌视图填充 - 标准化花色标签定位系统
func _populate_simple_cards_view(container, cards_by_suit, played_cards, stats):
	# 花色标签定位规则：
	# 1. 标题区域上边距：20像素（与前一花色分离）
	# 2. 标题区域下边距：15像素（与卡牌网格分离）
	# 3. 标题内容：左对齐，符号+名称+数量
	# 4. 网格区域：左对齐排列，由标题区域控制间距
	# 5. 分组底部间距：10像素（标准化分隔）

	# 添加简洁的统计信息
	_add_enhanced_stats(container, stats)

	# 按花色顺序显示 - 标准化的花色显示系统
	var suit_order = ["spades", "hearts", "diamonds", "clubs"]
	var suit_names = {"spades": "黑桃", "hearts": "红心", "diamonds": "方片", "clubs": "梅花"}
	var suit_symbols = {"spades": "♠", "hearts": "♥", "diamonds": "♦", "clubs": "♣"}
	var suit_colors = {"spades": Color(0.9, 0.9, 0.9, 1.0), "hearts": Color(0.95, 0.3, 0.3, 1.0),
					   "diamonds": Color(0.95, 0.3, 0.3, 1.0), "clubs": Color(0.9, 0.9, 0.9, 1.0)}

	for suit in suit_order:
		var cards = cards_by_suit[suit]
		if cards.size() > 0:
			# 创建花色分组容器 - 标准化的组织结构
			var suit_section = VBoxContainer.new()
			suit_section.add_theme_constant_override("separation", 0)  # 使用精确的边距控制，而非默认间距
			container.add_child(suit_section)

			# 花色标题区域 - 放置在卡牌网格上方，完全分离，减少上边距
			var header_wrapper = MarginContainer.new()
			# 减少上边距，让花色标题更靠近上方
			header_wrapper.add_theme_constant_override("margin_top", 4)  # 从8px减少到4px
			header_wrapper.add_theme_constant_override("margin_bottom", 12)  # 下边距，为卡牌网格留出空间
			header_wrapper.add_theme_constant_override("margin_left", 20)  # 左边距
			header_wrapper.add_theme_constant_override("margin_right", 0)
			header_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			suit_section.add_child(header_wrapper)



			# 花色标题容器 - 左对齐的标题布局，恢复默认高度
			var header_container = HBoxContainer.new()
			header_container.alignment = BoxContainer.ALIGNMENT_BEGIN
			header_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header_container.add_theme_constant_override("separation", 8)
			# 恢复花色标题默认高度
			header_wrapper.add_child(header_container)

			# 花色符号 - 标准化的符号显示
			var symbol_label = Label.new()
			symbol_label.text = suit_symbols[suit]
			symbol_label.add_theme_font_size_override("font_size", 18)
			symbol_label.add_theme_color_override("font_color", suit_colors[suit])
			header_container.add_child(symbol_label)

			# 花色名称和数量 - 标准化的文本标签
			var name_label = Label.new()
			name_label.text = suit_names[suit] + " (" + str(cards.size()) + " 张)"
			name_label.add_theme_font_size_override("font_size", 14)
			name_label.add_theme_color_override("font_color", THEME_COLORS.text_primary)
			header_container.add_child(name_label)

			# 卡牌网格区域 - 使用HBoxContainer实现左对齐布局
			var grid_wrapper = HBoxContainer.new()
			grid_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# 移除负边距，避免遮盖花色标题
			suit_section.add_child(grid_wrapper)

			# 卡牌网格容器 - 左对齐的网格布局
			var suit_grid = GridContainer.new()
			suit_grid.columns = 13  # 每行13张牌的标准布局
			suit_grid.add_theme_constant_override("h_separation", CARD_SPACING.x)
			suit_grid.add_theme_constant_override("v_separation", CARD_SPACING.y)
			grid_wrapper.add_child(suit_grid)

			# 右侧弹性空间 - 保留右侧空间以实现左对齐
			var right_spacer = Control.new()
			right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid_wrapper.add_child(right_spacer)

			# 添加该花色的所有卡牌
			for card_data in cards:
				var card_container = _create_simple_card_view(card_data)

				# 检查卡牌是否已打出
				if _is_card_in_array(card_data, played_cards):
					_apply_enhanced_played_style(card_container)

				suit_grid.add_child(card_container)

			# 花色分组底部间距 - 紧凑的分组分隔
			var section_spacer = Control.new()
			section_spacer.custom_minimum_size = Vector2(0, 6)  # 紧凑的6像素底部间距
			suit_section.add_child(section_spacer)



# 添加增强的统计信息
func _add_enhanced_stats(container, stats):
	# 使用MarginContainer来强制居中统计数据栏
	var margin_wrapper = MarginContainer.new()
	margin_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(margin_wrapper)

	# 创建内部的CenterContainer来确保内容居中
	var center_wrapper = CenterContainer.new()
	center_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_wrapper.add_child(center_wrapper)

	var stats_panel = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = THEME_COLORS.panel
	stats_style.corner_radius_top_left = 10
	stats_style.corner_radius_top_right = 10
	stats_style.corner_radius_bottom_left = 10
	stats_style.corner_radius_bottom_right = 10
	stats_style.border_width_left = 1
	stats_style.border_width_top = 1
	stats_style.border_width_right = 1
	stats_style.border_width_bottom = 1
	stats_style.border_color = THEME_COLORS.border
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	stats_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # 改为收缩居中
	# 恢复统计栏默认高度
	center_wrapper.add_child(stats_panel)

	# 紧凑的统计信息 - 单行显示，恢复原始设置
	var stats_container = HBoxContainer.new()
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_theme_constant_override("separation", 20)  # 恢复原来的20px间距
	stats_panel.add_child(stats_container)

	# 总计 - 简化文本标签
	var total_label = Label.new()
	total_label.text = "总计: " + str(stats.total) + " 张"
	total_label.add_theme_font_size_override("font_size", 14)
	total_label.add_theme_color_override("font_color", THEME_COLORS.text_primary)
	stats_container.add_child(total_label)

	# A牌 - 移除图标
	var aces_label = Label.new()
	aces_label.text = "A牌: " + str(stats.aces) + " 张"
	aces_label.add_theme_font_size_override("font_size", 14)
	aces_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	stats_container.add_child(aces_label)

	# 人头牌 - 移除图标
	var face_label = Label.new()
	face_label.text = "人头牌: " + str(stats.face_cards) + " 张"
	face_label.add_theme_font_size_override("font_size", 14)
	face_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	stats_container.add_child(face_label)

	# 花色分布 - 使用修正的花色符号
	var suits_label = Label.new()
	suits_label.text = "♠" + str(stats.suits.spades) + " ♥" + str(stats.suits.hearts) + " ♦" + str(stats.suits.diamonds) + " ♣" + str(stats.suits.clubs)
	suits_label.add_theme_font_size_override("font_size", 14)
	suits_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	stats_container.add_child(suits_label)





# 创建简洁卡牌视图 - 改进的视觉设计
func _create_simple_card_view(card_data):
	var card_container = Control.new()
	card_container.custom_minimum_size = CARD_SIZE

	# 添加轻微的背景样式以提高视觉层次
	var background = Panel.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.1)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	background.add_theme_stylebox_override("panel", bg_style)
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_container.add_child(background)

	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)

	# 设置卡牌数据
	if card_instance:
		card_instance.setup(card_data)

		# 调整卡牌大小和位置，确保居中 - 优化尺寸
		card_instance.scale = Vector2(0.42, 0.42)  # 适度增大缩放，提高可读性
		# 计算居中位置
		var card_actual_size = Vector2(250, 350)  # 卡牌的实际大小
		var scaled_size = card_actual_size * 0.42
		card_instance.position = Vector2(
			(CARD_SIZE.x - scaled_size.x) / 2,
			(CARD_SIZE.y - scaled_size.y) / 2
		)

		# 禁用卡牌的拖拽效果，但保持悬停预览功能
		if card_instance.has_method("set_draggable"):
			card_instance.set_draggable(false)
		# 保持悬停预览功能启用，以便用户可以查看卡牌详情

		# 连接点击事件处理，使用lambda函数避免参数匹配问题
		if card_instance.has_signal("card_clicked"):
			card_instance.card_clicked.connect(func(card_view): _on_card_clicked(card_data, card_container))

		# 确保卡牌可以接收鼠标输入
		card_instance.mouse_filter = Control.MOUSE_FILTER_STOP

	return card_container

# 应用增强的已打出样式 - 简化设计
func _apply_enhanced_played_style(card_container):
	# 添加简洁的遮罩
	var overlay = Panel.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.2, 0.2, 0.2, 0.6)
	overlay_style.corner_radius_top_left = 4
	overlay_style.corner_radius_top_right = 4
	overlay_style.corner_radius_bottom_left = 4
	overlay_style.corner_radius_bottom_right = 4
	overlay_style.border_width_left = 1
	overlay_style.border_width_top = 1
	overlay_style.border_width_right = 1
	overlay_style.border_width_bottom = 1
	overlay_style.border_color = Color(0.6, 0.4, 0.4, 0.8)
	overlay.add_theme_stylebox_override("panel", overlay_style)
	card_container.add_child(overlay)

	# 简化的状态指示器 - 仅文字，无图标
	var status_container = Control.new()
	status_container.anchor_left = 0.5
	status_container.anchor_top = 0.5
	status_container.anchor_right = 0.5
	status_container.anchor_bottom = 0.5
	status_container.offset_left = -20
	status_container.offset_top = -8
	status_container.offset_right = 20
	status_container.offset_bottom = 8
	card_container.add_child(status_container)

	# 状态文字 - 移除图标，使用简洁文本
	var status_label = Label.new()
	status_label.text = "已打出"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(1, 0.9, 0.9, 1))
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 1.0
	status_container.add_child(status_label)

	# 降低整个卡牌的透明度
	card_container.modulate = Color(0.75, 0.75, 0.75, 0.85)

# 检查卡牌是否在数组中
func _is_card_in_array(card_data, card_array):
	for card in card_array:
		if card.id == card_data.id:
			return true
	return false

# 卡牌点击事件包装函数 - 处理信号参数（已弃用）
func _on_card_clicked_wrapper(card_data: CardData, card_container: Control, _extra_param = null):
	_on_card_clicked(card_data, card_container)

# 处理来自CardView的点击信号 - 修复参数匹配问题
func _on_card_clicked_from_view(card_view: CardView, card_data: CardData, card_container: Control):
	# CardView的card_clicked信号发送CardView实例作为第一个参数，绑定的参数跟在后面
	_on_card_clicked(card_data, card_container)

# 卡牌点击事件处理 - 改善响应性和防抖
func _on_card_clicked(card_data: CardData, card_container: Control):
	# 使用更简单和可靠的时间戳获取方法
	var current_time = Time.get_time_dict_from_system()
	var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second

	# 防抖处理 - 防止快速重复点击
	if current_timestamp - last_click_time < click_debounce_delay:
		return

	last_click_time = current_timestamp

	# 添加点击视觉反馈
	_add_click_feedback(card_container)

	# 输出点击信息（用于调试）
	print("卡牌点击: %s (%s)" % [card_data.name, card_data.id])

# 添加点击视觉反馈
func _add_click_feedback(card_container: Control):
	# 创建简单的缩放反馈效果
	var tween = create_tween()
	tween.set_parallel(true)

	# 缩放效果
	tween.tween_property(card_container, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)

	# 轻微的颜色变化
	tween.tween_property(card_container, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	tween.tween_property(card_container, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1).set_delay(0.1)

# 关闭按钮事件处理
func _on_close_button_pressed():
	queue_free()

# 窗口关闭请求处理
func _on_close_requested():
	queue_free()

# 窗口大小变化处理 - 确保标题和统计数据栏始终居中
func _on_window_size_changed():
	# 延迟调用以确保布局更新完成
	call_deferred("_update_title_centering")
	call_deferred("_update_stats_centering")

# 更新标题居中
func _update_title_centering():
	# 查找标题标签
	if get_child_count() > 1:
		var main_container = get_child(1)  # 背景面板是第一个，主容器是第二个
		if main_container and main_container.get_child_count() > 0:
			var title_label = main_container.get_child(0)  # 标题是主容器的第一个子节点
			if title_label is Label:
				# 强制更新标题居中设置
				title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				title_label.queue_redraw()



# 更新统计数据栏居中
func _update_stats_centering():
	# 查找统计数据栏
	if get_child_count() > 1:
		var main_container = get_child(1)  # 背景面板是第一个，主容器是第二个
		if main_container and main_container.get_child_count() > 1:
			var tab_container = main_container.get_child(1)  # 标签容器是主容器的第二个子节点
			if tab_container and tab_container.get_child_count() > 0:
				# 查找当前活动标签页中的统计数据栏
				var current_tab = tab_container.get_current_tab_control()
				if current_tab and current_tab.get_child_count() > 0:
					var first_child = current_tab.get_child(0)
					if first_child is MarginContainer:  # 这应该是stats_wrapper (MarginContainer)
						var stats_wrapper = first_child
						if stats_wrapper.get_child_count() > 0:
							var center_container = stats_wrapper.get_child(0)
							if center_container is CenterContainer and center_container.get_child_count() > 0:
								var stats_panel = center_container.get_child(0)
								if stats_panel is PanelContainer:
									# 重新计算边距来保持居中
									var window_width = size.x
									var panel_width = stats_panel.get_global_rect().size.x
									var parent_margin = 40  # 考虑父容器边距
									var available_width = window_width - (parent_margin * 2)
									var margin_needed = (available_width - panel_width) / 2

									stats_wrapper.add_theme_constant_override("margin_left", margin_needed)
									stats_wrapper.add_theme_constant_override("margin_right", margin_needed)
									stats_wrapper.queue_redraw()
									stats_panel.queue_redraw()
