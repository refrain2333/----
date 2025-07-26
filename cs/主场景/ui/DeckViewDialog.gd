class_name DeckViewDialog
extends Window

# 常量
const CARD_SIZE = Vector2(70, 105)  # 缩小卡牌尺寸以适应一页
const CARD_SPACING = Vector2(4, 6)  # 减小卡牌间距
const CARDS_PER_ROW = 13  # 每行显示13张牌

# 简化的颜色主题
const THEME_COLORS = {
	"background": Color(0.1, 0.1, 0.15, 0.95),
	"panel": Color(0.15, 0.15, 0.2, 0.8),
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

# 预加载场景
var card_scene = preload("res://cs/卡牌系统/视图/Card.tscn")

func _init():
	# 设置窗口属性
	title = "牌库查看器"
	size = Vector2(1200, 800)  # 适中的窗口尺寸
	min_size = Vector2(1000, 600)
	exclusive = true
	unresizable = false
	transient = true

	# 设置关闭请求回调
	close_requested.connect(_on_close_requested)

	# 创建UI
	_create_ui()

# 设置数据
func setup(all_cards, current_deck, played_cards):
	all_cards_data = all_cards
	current_deck_data = current_deck
	played_cards_data = played_cards
	
	# 更新UI
	_update_ui()

# 创建UI
func _create_ui():
	# 创建背景面板
	background_panel = Panel.new()
	background_panel.anchor_right = 1.0
	background_panel.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = THEME_COLORS.background
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	background_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(background_panel)

	# 创建主容器
	var main_container = VBoxContainer.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_left = 15
	main_container.offset_top = 15
	main_container.offset_right = -15
	main_container.offset_bottom = -15
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)

	# 创建简单标题
	var title_label = Label.new()
	title_label.text = "牌库查看器"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", THEME_COLORS.text_primary)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(title_label)

	# 创建标签容器
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(tab_container)

	# 创建"全部牌"标签页
	var all_cards_scroll = ScrollContainer.new()
	all_cards_scroll.name = "全部牌"
	all_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	all_cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	all_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(all_cards_scroll)

	all_cards_container = VBoxContainer.new()
	all_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_cards_container.add_theme_constant_override("separation", 8)
	all_cards_scroll.add_child(all_cards_container)

	# 创建"当前牌库"标签页
	var current_deck_scroll = ScrollContainer.new()
	current_deck_scroll.name = "当前牌库"
	current_deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	current_deck_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	current_deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_child(current_deck_scroll)

	current_deck_container = VBoxContainer.new()
	current_deck_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_deck_container.add_theme_constant_override("separation", 8)
	current_deck_scroll.add_child(current_deck_container)

	# 创建底部按钮
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(100, 35)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_on_close_button_pressed)
	main_container.add_child(close_button)



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
		"aces": 0,        # A
		"jacks": 0,       # J
		"queens": 0,      # Q
		"kings": 0,       # K
		"face_cards": 0,  # 所有人头牌(J,Q,K)
		"suits": {
			"spades": 0,   # 黑桃
			"hearts": 0,   # 红心
			"diamonds": 0, # 方片
			"clubs": 0     # 梅花
		}
	}
	
	# 统计卡牌
	for card in cards_data:
		# 统计花色
		if stats.suits.has(card.suit):
			stats.suits[card.suit] += 1
		
		# 统计特殊牌
		match card.base_value:
			1: stats.aces += 1
			11: stats.jacks += 1
			12: stats.queens += 1
			13: stats.kings += 1
	
	stats.face_cards = stats.jacks + stats.queens + stats.kings
	
	return stats

# 简化的卡牌视图填充
func _populate_simple_cards_view(container, cards_by_suit, played_cards, stats):
	# 添加简单统计信息
	_add_simple_stats(container, stats)

	# 按花色顺序显示
	var suit_order = ["spades", "hearts", "diamonds", "clubs"]
	var suit_names = {"spades": "黑桃", "hearts": "红心", "diamonds": "方片", "clubs": "梅花"}

	for suit in suit_order:
		var cards = cards_by_suit[suit]
		if cards.size() > 0:
			# 花色标题
			var suit_label = Label.new()
			suit_label.text = suit_names[suit] + " (" + str(cards.size()) + " 张)"
			suit_label.add_theme_font_size_override("font_size", 14)
			suit_label.add_theme_color_override("font_color", THEME_COLORS.text_primary)
			suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			suit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.add_child(suit_label)

			# 创建该花色的卡牌网格
			var suit_grid = GridContainer.new()
			suit_grid.columns = 13  # 每行13张牌
			suit_grid.add_theme_constant_override("h_separation", CARD_SPACING.x)
			suit_grid.add_theme_constant_override("v_separation", CARD_SPACING.y)
			container.add_child(suit_grid)

			# 添加该花色的所有卡牌
			for card_data in cards:
				var card_container = _create_simple_card_view(card_data)

				# 检查卡牌是否已打出
				if _is_card_in_array(card_data, played_cards):
					_apply_simple_played_style(card_container)

				suit_grid.add_child(card_container)

# 添加简单统计信息
func _add_simple_stats(container, stats):
	var stats_container = HBoxContainer.new()
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_theme_constant_override("separation", 20)
	container.add_child(stats_container)

	# 总计
	var total_label = Label.new()
	total_label.text = "总计: " + str(stats.total) + " 张"
	total_label.add_theme_font_size_override("font_size", 12)
	total_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	stats_container.add_child(total_label)

	# A牌
	var aces_label = Label.new()
	aces_label.text = "A: " + str(stats.aces) + " 张"
	aces_label.add_theme_font_size_override("font_size", 12)
	aces_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	stats_container.add_child(aces_label)

	# 人头牌
	var face_label = Label.new()
	face_label.text = "人头牌: " + str(stats.face_cards) + " 张"
	face_label.add_theme_font_size_override("font_size", 12)
	face_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	stats_container.add_child(face_label)

# 创建简单卡牌视图
func _create_simple_card_view(card_data):
	var card_container = Control.new()
	card_container.custom_minimum_size = CARD_SIZE

	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)

	# 设置卡牌数据
	if card_instance:
		card_instance.setup(card_data)

		# 调整卡牌大小和位置，确保居中
		card_instance.scale = Vector2(0.32, 0.32)
		card_instance.position = Vector2(
			(CARD_SIZE.x - card_instance.size.x * 0.32) / 2,
			(CARD_SIZE.y - card_instance.size.y * 0.32) / 2
		)

		# 禁用卡牌的悬停和拖拽效果
		card_instance.set_hover_enabled(false)
		card_instance.set_draggable(false)

	return card_container

# 应用简单的已打出样式
func _apply_simple_played_style(card_container):
	# 添加简单的半透明遮罩
	var overlay = ColorRect.new()
	overlay.color = Color(0.2, 0.2, 0.2, 0.6)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	card_container.add_child(overlay)

	# 添加简单的"已打出"标签
	var label = Label.new()
	label.text = "已打出"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	card_container.add_child(label)



# 检查卡牌是否在数组中
func _is_card_in_array(card_data, card_array):
	for card in card_array:
		if card.card_id == card_data.card_id:
			return true
	return false

# 关闭按钮事件处理
func _on_close_button_pressed():
	queue_free()

# 窗口关闭请求处理
func _on_close_requested():
	queue_free()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(THEME_COLORS.panel.r * 0.8, THEME_COLORS.panel.g * 0.8, THEME_COLORS.panel.b * 0.8, 0.6)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = THEME_COLORS.border
	cards_panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(cards_panel)

	# 创建内容容器
	var content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 20)
	cards_panel.add_child(content_container)

	# 按花色分组显示，带动画效果 - 修正花色符号
	var suit_order = ["spades", "hearts", "diamonds", "clubs"]
	var suit_names = {"spades": "♠ 黑桃", "hearts": "♥ 红心", "diamonds": "♦ 方片", "clubs": "♣ 梅花"}
	var suit_colors = {"spades": Color(0.3, 0.3, 0.3, 1.0), "hearts": Color(0.8, 0.2, 0.2, 1.0),
					   "diamonds": Color(0.8, 0.2, 0.2, 1.0), "clubs": Color(0.3, 0.3, 0.3, 1.0)}

	var delay = 0.0
	for suit in suit_order:
		var cards = cards_by_suit[suit]
		if cards.size() > 0:
			# 创建花色分组容器
			var suit_group = _create_suit_group(suit_names[suit], suit_colors[suit], cards, played_cards)
			content_container.add_child(suit_group)

			# 添加入场动画
			suit_group.modulate.a = 0.0
			suit_group.position.x = -50

			var tween = create_tween()
			tween.tween_interval(delay)
			tween.parallel().tween_property(suit_group, "modulate:a", 1.0, 0.3)
			tween.parallel().tween_property(suit_group, "position:x", 0, 0.3)

			delay += 0.1

# 创建花色分组
func _create_suit_group(suit_name: String, suit_color: Color, cards: Array, played_cards: Array) -> Control:
	var group_container = VBoxContainer.new()
	group_container.add_theme_constant_override("separation", 12)

	# 花色标题栏
	var header_container = HBoxContainer.new()
	header_container.add_theme_constant_override("separation", 10)
	group_container.add_child(header_container)

	# 花色标题
	var suit_header = Label.new()
	suit_header.text = suit_name + " (" + str(cards.size()) + " 张)"
	suit_header.add_theme_font_size_override("font_size", 16)
	suit_header.add_theme_color_override("font_color", suit_color)
	suit_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_container.add_child(suit_header)

	# 添加分隔线
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color(suit_color.r, suit_color.g, suit_color.b, 0.3))
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(separator)

	# 创建该花色的卡牌网格
	var suit_grid = GridContainer.new()
	suit_grid.columns = 13  # 每行13张牌
	suit_grid.add_theme_constant_override("h_separation", CARD_SPACING.x)
	suit_grid.add_theme_constant_override("v_separation", CARD_SPACING.y)
	group_container.add_child(suit_grid)

	# 添加该花色的所有卡牌
	for i in range(cards.size()):
		var card_data = cards[i]
		var card_container = _create_enhanced_card_view(card_data, i)

		# 检查卡牌是否已打出
		if _is_card_in_array(card_data, played_cards):
			_apply_played_card_style(card_container)

		suit_grid.add_child(card_container)

	return group_container

# 创建增强版卡牌视图
func _create_enhanced_card_view(card_data, index: int):
	var card_container = Control.new()
	card_container.custom_minimum_size = CARD_SIZE

	# 添加卡牌背景效果
	var card_bg = Panel.new()
	card_bg.anchor_right = 1.0
	card_bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(1.0, 1.0, 1.0, 0.05)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.5, 0.7, 1.0, 0.2)
	card_bg.add_theme_stylebox_override("panel", bg_style)
	card_container.add_child(card_bg)

	# 添加光晕效果
	var glow_effect = Panel.new()
	glow_effect.anchor_left = 0.1
	glow_effect.anchor_top = 0.1
	glow_effect.anchor_right = 0.9
	glow_effect.anchor_bottom = 0.9
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(0.7, 0.9, 1.0, 0.1)
	glow_style.corner_radius_top_left = 6
	glow_style.corner_radius_top_right = 6
	glow_style.corner_radius_bottom_left = 6
	glow_style.corner_radius_bottom_right = 6
	glow_effect.add_theme_stylebox_override("panel", glow_style)
	glow_effect.visible = false
	card_container.add_child(glow_effect)

	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)

	# 设置卡牌数据
	if card_instance:
		card_instance.setup(card_data)

		# 调整卡牌大小和位置
		card_instance.scale = Vector2(0.4, 0.4)
		card_instance.position = Vector2(CARD_SIZE.x / 10, CARD_SIZE.y / 10)

		# 添加增强的悬停效果
		card_instance.mouse_entered.connect(_on_enhanced_card_hover.bind(card_container, glow_effect, true))
		card_instance.mouse_exited.connect(_on_enhanced_card_hover.bind(card_container, glow_effect, false))

		# 添加点击效果
		card_instance.gui_input.connect(_on_card_clicked.bind(card_container, card_data))

	# 添加入场动画延迟
	card_container.modulate.a = 0.0
	card_container.scale = Vector2(0.8, 0.8)

	var delay = index * 0.02  # 每张卡牌延迟0.02秒
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.parallel().tween_property(card_container, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.2)

	return card_container

# 增强版卡牌悬停效果
func _on_enhanced_card_hover(card_container: Control, glow_effect: Panel, is_hovering: bool):
	if is_hovering:
		glow_effect.visible = true
		var tween = create_tween()
		tween.parallel().tween_property(card_container, "scale", Vector2(1.08, 1.08), 0.15)
		tween.parallel().tween_property(card_container, "modulate", Color(1.15, 1.15, 1.3, 1.0), 0.15)
		tween.parallel().tween_property(glow_effect, "modulate:a", 1.0, 0.15)
	else:
		var tween = create_tween()
		tween.parallel().tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.15)
		tween.parallel().tween_property(card_container, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		tween.parallel().tween_property(glow_effect, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): glow_effect.visible = false)

# 卡牌点击效果
func _on_card_clicked(card_container: Control, card_data: CardData, event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 创建点击波纹效果
		var ripple = Panel.new()
		ripple.anchor_left = 0.5
		ripple.anchor_top = 0.5
		ripple.anchor_right = 0.5
		ripple.anchor_bottom = 0.5
		ripple.size = Vector2.ZERO
		var ripple_style = StyleBoxFlat.new()
		ripple_style.bg_color = Color(1.0, 1.0, 1.0, 0.3)
		ripple_style.corner_radius_top_left = 50
		ripple_style.corner_radius_top_right = 50
		ripple_style.corner_radius_bottom_left = 50
		ripple_style.corner_radius_bottom_right = 50
		ripple.add_theme_stylebox_override("panel", ripple_style)
		card_container.add_child(ripple)

		var tween = create_tween()
		tween.parallel().tween_property(ripple, "size", Vector2(100, 100), 0.3)
		tween.parallel().tween_property(ripple, "offset_left", -50, 0.3)
		tween.parallel().tween_property(ripple, "offset_top", -50, 0.3)
		tween.parallel().tween_property(ripple, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): ripple.queue_free())

		# 显示卡牌信息（可以在这里添加更多交互）
		print("点击了卡牌: ", card_data.card_name)



# 创建统计卡片
func _create_stat_card(parent: Container, icon: String, card_title: String, value: String, color: Color):
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(color.r, color.g, color.b, 0.2)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = color
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(120, 80)
	parent.add_child(card)

	var card_content = VBoxContainer.new()
	card_content.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(card_content)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_content.add_child(icon_label)

	var title_label = Label.new()
	title_label.text = card_title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_content.add_child(title_label)

	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_content.add_child(value_label)

# 创建花色统计 - 简化设计，减少图标依赖
func _create_suit_stat(parent: Container, icon: String, suit_name: String, count: int, color: Color):
	var suit_container = HBoxContainer.new()
	suit_container.alignment = BoxContainer.ALIGNMENT_CENTER
	suit_container.add_theme_constant_override("separation", 6)
	parent.add_child(suit_container)

	# 简化的花色符号
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.add_theme_color_override("font_color", color)
	suit_container.add_child(icon_label)

	# 合并名称和数量为一个标签
	var info_label = Label.new()
	info_label.text = suit_name + ": " + str(count) + " 张"
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", THEME_COLORS.text_primary)
	suit_container.add_child(info_label)

# 添加花色分布图表
func _add_suit_distribution_chart(parent: Container, stats):
	# 创建图表标题
	var chart_title = Label.new()
	chart_title.text = "📊 花色分布图表"
	chart_title.add_theme_font_size_override("font_size", 16)
	chart_title.add_theme_color_override("font_color", THEME_COLORS.text_primary)
	chart_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(chart_title)

	# 创建图表容器
	var chart_container = HBoxContainer.new()
	chart_container.alignment = BoxContainer.ALIGNMENT_CENTER
	chart_container.add_theme_constant_override("separation", 20)
	parent.add_child(chart_container)

	# 计算总数用于百分比计算
	var total = stats.total
	if total == 0:
		total = 1  # 避免除零错误

	# 花色数据
	var suit_data = [
		{"name": "♠️", "count": stats.suits.spades, "color": Color(0.3, 0.3, 0.3, 1.0)},
		{"name": "♥️", "count": stats.suits.hearts, "color": Color(0.8, 0.2, 0.2, 1.0)},
		{"name": "♦️", "count": stats.suits.diamonds, "color": Color(0.8, 0.2, 0.2, 1.0)},
		{"name": "♣️", "count": stats.suits.clubs, "color": Color(0.3, 0.3, 0.3, 1.0)}
	]

	# 创建条形图
	for suit in suit_data:
		_create_bar_chart_item(chart_container, suit.name, suit.count, total, suit.color)

# 创建条形图项目
func _create_bar_chart_item(parent: Container, suit_name: String, count: int, total: int, color: Color):
	var item_container = VBoxContainer.new()
	item_container.alignment = BoxContainer.ALIGNMENT_END
	item_container.custom_minimum_size = Vector2(60, 120)
	parent.add_child(item_container)

	# 计算百分比和条形高度
	var percentage = float(count) / float(total) * 100.0
	var bar_height = int(percentage * 0.8)  # 最大高度80像素

	# 百分比标签
	var percentage_label = Label.new()
	percentage_label.text = "%.1f%%" % percentage
	percentage_label.add_theme_font_size_override("font_size", 10)
	percentage_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_container.add_child(percentage_label)

	# 数量标签
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", color)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_container.add_child(count_label)

	# 创建条形图
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(40, 80)
	bar_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_container.add_child(bar_container)

	# 背景条
	var bg_bar = Panel.new()
	bg_bar.anchor_left = 0.2
	bg_bar.anchor_right = 0.8
	bg_bar.anchor_top = 0.0
	bg_bar.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.3, 0.3)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bg_bar.add_theme_stylebox_override("panel", bg_style)
	bar_container.add_child(bg_bar)

	# 实际数据条
	var data_bar = Panel.new()
	data_bar.anchor_left = 0.2
	data_bar.anchor_right = 0.8
	data_bar.anchor_bottom = 1.0
	data_bar.anchor_top = 1.0 - (percentage / 100.0)
	var data_style = StyleBoxFlat.new()
	data_style.bg_color = color
	data_style.corner_radius_top_left = 4
	data_style.corner_radius_top_right = 4
	data_style.corner_radius_bottom_left = 4
	data_style.corner_radius_bottom_right = 4
	data_bar.add_theme_stylebox_override("panel", data_style)
	bar_container.add_child(data_bar)

	# 花色标签
	var suit_label = Label.new()
	suit_label.text = suit_name
	suit_label.add_theme_font_size_override("font_size", 16)
	suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_container.add_child(suit_label)

	# 添加动画效果
	data_bar.anchor_top = 1.0
	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(data_bar, "anchor_top", 1.0 - (percentage / 100.0), 0.5)

# 添加详细统计信息
func _add_detailed_stats(parent: Container, stats):
	# 创建详细统计面板
	var detail_panel = PanelContainer.new()
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(THEME_COLORS.panel.r * 0.9, THEME_COLORS.panel.g * 0.9, THEME_COLORS.panel.b * 0.9, 0.7)
	detail_style.corner_radius_top_left = 8
	detail_style.corner_radius_top_right = 8
	detail_style.corner_radius_bottom_left = 8
	detail_style.corner_radius_bottom_right = 8
	detail_style.border_width_left = 1
	detail_style.border_width_top = 1
	detail_style.border_width_right = 1
	detail_style.border_width_bottom = 1
	detail_style.border_color = THEME_COLORS.border
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	parent.add_child(detail_panel)

	var detail_container = VBoxContainer.new()
	detail_container.add_theme_constant_override("separation", 10)
	detail_panel.add_child(detail_container)

	# 详细统计标题
	var detail_title = Label.new()
	detail_title.text = "🔍 详细分析"
	detail_title.add_theme_font_size_override("font_size", 16)
	detail_title.add_theme_color_override("font_color", THEME_COLORS.text_primary)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_container.add_child(detail_title)

	# 创建分析网格
	var analysis_grid = GridContainer.new()
	analysis_grid.columns = 3
	analysis_grid.add_theme_constant_override("h_separation", 20)
	analysis_grid.add_theme_constant_override("v_separation", 8)
	detail_container.add_child(analysis_grid)

	# 计算各种统计数据
	var low_cards = 0  # 2-6
	var mid_cards = 0  # 7-10
	var high_cards = stats.aces + stats.face_cards  # A, J, Q, K

	# 计算低中牌数量（需要遍历所有卡牌数据）
	for card_data in all_cards_data:
		if card_data.base_value >= 2 and card_data.base_value <= 6:
			low_cards += 1
		elif card_data.base_value >= 7 and card_data.base_value <= 10:
			mid_cards += 1

	# 添加分析项目
	_add_analysis_item(analysis_grid, "🔻", "低牌 (2-6)", str(low_cards), Color(0.6, 0.8, 0.6, 1.0))
	_add_analysis_item(analysis_grid, "🔸", "中牌 (7-10)", str(mid_cards), Color(0.8, 0.8, 0.6, 1.0))
	_add_analysis_item(analysis_grid, "🔺", "高牌 (A,J,Q,K)", str(high_cards), Color(0.8, 0.6, 0.6, 1.0))

	# 计算红黑比例
	var red_cards = stats.suits.hearts + stats.suits.diamonds
	var black_cards = stats.suits.spades + stats.suits.clubs

	_add_analysis_item(analysis_grid, "❤️", "红色牌", str(red_cards), Color(0.8, 0.2, 0.2, 1.0))
	_add_analysis_item(analysis_grid, "🖤", "黑色牌", str(black_cards), Color(0.3, 0.3, 0.3, 1.0))
	_add_analysis_item(analysis_grid, "⚖️", "红黑比例", "%.1f:%.1f" % [red_cards, black_cards], THEME_COLORS.text_secondary)

# 添加分析项目
func _add_analysis_item(grid: GridContainer, icon: String, label: String, value: String, color: Color):
	# 图标
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid.add_child(icon_label)

	# 标签
	var text_label = Label.new()
	text_label.text = label
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_color_override("font_color", THEME_COLORS.text_secondary)
	grid.add_child(text_label)

	# 数值
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_label)



# 创建卡牌视图
func _create_card_view(card_data):
	var card_container = Control.new()
	card_container.custom_minimum_size = CARD_SIZE

	# 添加卡牌背景效果
	var card_bg = Panel.new()
	card_bg.anchor_right = 1.0
	card_bg.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(1.0, 1.0, 1.0, 0.1)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.5, 0.7, 1.0, 0.3)
	card_bg.add_theme_stylebox_override("panel", bg_style)
	card_container.add_child(card_bg)

	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)

	# 设置卡牌数据 - 直接使用card_instance，因为它本身就是CardView
	if card_instance:
		card_instance.setup(card_data)

		# 调整卡牌大小和位置
		card_instance.scale = Vector2(0.38, 0.38)  # 稍微增大卡牌
		card_instance.position = Vector2(CARD_SIZE.x / 8, CARD_SIZE.y / 8)  # 居中

		# 添加悬停效果
		card_instance.mouse_entered.connect(_on_card_hover.bind(card_container, true))
		card_instance.mouse_exited.connect(_on_card_hover.bind(card_container, false))

	return card_container

# 卡牌悬停效果
func _on_card_hover(card_container: Control, is_hovering: bool):
	if is_hovering:
		var tween = create_tween()
		tween.tween_property(card_container, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(card_container, "modulate", Color(1.1, 1.1, 1.2, 1.0), 0.1)
	else:
		var tween = create_tween()
		tween.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(card_container, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

# 检查卡牌是否在数组中
func _is_card_in_array(card_data, card_array):
	for card in card_array:
		if card.card_id == card_data.card_id:
			return true
	return false

# 应用已打出卡牌样式
func _apply_played_card_style(card_container):
	# 添加渐变遮罩效果
	var overlay = Panel.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	overlay_style.corner_radius_top_left = 6
	overlay_style.corner_radius_top_right = 6
	overlay_style.corner_radius_bottom_left = 6
	overlay_style.corner_radius_bottom_right = 6
	overlay_style.border_width_left = 2
	overlay_style.border_width_top = 2
	overlay_style.border_width_right = 2
	overlay_style.border_width_bottom = 2
	overlay_style.border_color = Color(0.8, 0.3, 0.3, 0.8)
	overlay.add_theme_stylebox_override("panel", overlay_style)
	card_container.add_child(overlay)

	# 添加状态图标和文字
	var status_container = VBoxContainer.new()
	status_container.anchor_left = 0.5
	status_container.anchor_top = 0.5
	status_container.anchor_right = 0.5
	status_container.anchor_bottom = 0.5
	status_container.offset_left = -30
	status_container.offset_top = -20
	status_container.offset_right = 30
	status_container.offset_bottom = 20
	status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_child(status_container)

	var icon_label = Label.new()
	icon_label.text = "❌"
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(icon_label)

	var status_label = Label.new()
	status_label.text = "已打出"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	status_container.add_child(status_label)

	# 降低整个卡牌的透明度
	card_container.modulate = Color(0.6, 0.6, 0.6, 0.8)

# 关闭按钮事件处理
func _on_close_button_pressed():
	queue_free()

# 窗口关闭请求处理
func _on_close_requested():
	queue_free() 