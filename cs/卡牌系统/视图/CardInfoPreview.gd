class_name CardInfoPreview
extends Control

# 卡牌信息预览面板
# 用于显示卡牌的详细信息，包括基础属性、游戏属性、强化效果等

# 节点引用
@onready var card_name_label: Label = $VBoxContainer/HeaderPanel/CardNameLabel
@onready var value_text: Label = $VBoxContainer/ContentContainer/BasicInfoContainer/ValueContainer/ValueText
@onready var suit_text: Label = $VBoxContainer/ContentContainer/BasicInfoContainer/SuitContainer/SuitText
@onready var damage_text: Label = $VBoxContainer/ContentContainer/GameStatsContainer/DamageContainer/DamageText
@onready var defense_text: Label = $VBoxContainer/ContentContainer/GameStatsContainer/DefenseContainer/DefenseText
@onready var cost_text: Label = $VBoxContainer/ContentContainer/GameStatsContainer/CostContainer/CostText
@onready var wax_seals_text: Label = $VBoxContainer/ContentContainer/EnhancementsContainer/WaxSealsText
@onready var frame_text: Label = $VBoxContainer/ContentContainer/EnhancementsContainer/FrameText
@onready var material_text: Label = $VBoxContainer/ContentContainer/EnhancementsContainer/MaterialText
@onready var rarity_text: Label = $VBoxContainer/ContentContainer/RarityContainer/RarityText
@onready var description_text: Label = $VBoxContainer/ContentContainer/DescriptionContainer/DescriptionText

# 游戏属性容器引用（用于动态显示/隐藏）
@onready var game_stats_container: VBoxContainer = $VBoxContainer/ContentContainer/GameStatsContainer
@onready var enhancements_container: VBoxContainer = $VBoxContainer/ContentContainer/EnhancementsContainer

# 当前显示的卡牌数据
var current_card_data: CardData = null

func _ready():
	# 确保面板默认不可见
	visible = false
	# 设置鼠标过滤，避免干扰卡牌交互
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# 设置卡牌数据并更新显示
func setup_card_info(card_data: CardData):
	if not card_data:
		hide_preview()
		return
	
	current_card_data = card_data
	_update_display()

# 更新显示内容
func _update_display():
	if not current_card_data or not is_inside_tree():
		return
	
	# 更新基础信息
	_update_basic_info()
	
	# 更新游戏属性
	_update_game_stats()
	
	# 更新强化效果
	_update_enhancements()
	
	# 更新稀有度和描述
	_update_rarity_and_description()

# 更新基础信息
func _update_basic_info():
	if card_name_label:
		card_name_label.text = current_card_data.name
	
	if value_text:
		var base_value = current_card_data.base_value
		var modified_value = current_card_data.get_modified_value()
		
		if base_value != modified_value:
			# 显示修正后的数值
			value_text.text = "%d → %d" % [base_value, modified_value]
			value_text.modulate = Color.YELLOW  # 高亮显示修正值
		else:
			value_text.text = str(base_value)
			value_text.modulate = Color.WHITE
	
	if suit_text:
		suit_text.text = current_card_data.get_suit_display_name()
		# 根据花色设置颜色
		match current_card_data.suit:
			"hearts", "diamonds":
				suit_text.modulate = Color.RED
			"clubs", "spades":
				suit_text.modulate = Color.WHITE

# 更新游戏属性
func _update_game_stats():
	var has_game_stats = false
	
	if damage_text:
		damage_text.text = str(current_card_data.damage)
		if current_card_data.damage > 0:
			has_game_stats = true
	
	if defense_text:
		defense_text.text = str(current_card_data.defense)
		if current_card_data.defense > 0:
			has_game_stats = true
	
	if cost_text:
		cost_text.text = str(current_card_data.cost)
		if current_card_data.cost > 0:
			has_game_stats = true
	
	# 如果没有游戏属性，隐藏整个容器
	if game_stats_container:
		game_stats_container.visible = has_game_stats

# 更新强化效果
func _update_enhancements():
	var has_enhancements = false
	
	# 更新蜡封
	if wax_seals_text:
		if current_card_data.wax_seals.size() > 0:
			var wax_seals_str = "蜡封：" + ", ".join(current_card_data.wax_seals)
			wax_seals_text.text = wax_seals_str
			has_enhancements = true
		else:
			wax_seals_text.text = "蜡封：无"
	
	# 更新牌框
	if frame_text:
		if current_card_data.frame_type != "":
			frame_text.text = "牌框：" + _get_frame_display_name(current_card_data.frame_type)
			has_enhancements = true
		else:
			frame_text.text = "牌框：无"
	
	# 更新材质
	if material_text:
		if current_card_data.material_type != "":
			material_text.text = "材质：" + _get_material_display_name(current_card_data.material_type)
			has_enhancements = true
		else:
			material_text.text = "材质：无"
	
	# 如果没有强化效果，隐藏整个容器
	if enhancements_container:
		enhancements_container.visible = has_enhancements

# 更新稀有度和描述
func _update_rarity_and_description():
	if rarity_text:
		var rarity_display = _get_rarity_display_name(current_card_data.rarity)
		rarity_text.text = rarity_display
		
		# 根据稀有度设置颜色
		match current_card_data.rarity:
			"common":
				rarity_text.modulate = Color.WHITE
			"rare":
				rarity_text.modulate = Color.CYAN
			"epic":
				rarity_text.modulate = Color.MAGENTA
			"legendary":
				rarity_text.modulate = Color.GOLD
			_:
				rarity_text.modulate = Color.WHITE
	
	if description_text:
		var description = current_card_data.description
		if description.is_empty():
			description = "一张基础的" + current_card_data.name + "卡牌"
		description_text.text = description

# 显示预览面板（带淡入动画）
func show_preview():
	if visible:
		return
	
	visible = true
	modulate.a = 0.0
	
	# 淡入动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.set_ease(Tween.EASE_OUT)

# 隐藏预览面板（带淡出动画）
func hide_preview():
	if not visible:
		return
	
	# 淡出动画
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)

# 设置预览面板位置
func set_preview_position(target_position: Vector2, card_size: Vector2):
	# 根据卡牌尺寸动态调整预览面板大小
	var preview_size = _calculate_adaptive_preview_size(card_size)

	# 应用计算出的尺寸
	custom_minimum_size = preview_size
	size = preview_size

	# 根据预览面板尺寸调整字体大小和样式
	_adjust_font_sizes(preview_size)
	_adjust_panel_style(preview_size, card_size)

	# 获取正确的视口尺寸
	var viewport_size = _get_effective_viewport_size()

	# 直接使用传入的全局坐标，不进行任何转换
	var actual_card_pos = target_position
	var actual_card_size = card_size


	# 计算卡牌的中心位置
	var card_center_x = actual_card_pos.x + actual_card_size.x / 2.0
	var card_top_y = actual_card_pos.y
	var card_bottom_y = actual_card_pos.y + actual_card_size.y



	# 根据卡牌和预览面板尺寸动态调整间距
	var vertical_gap = max(6.0, card_size.y * 0.1)  # 间距至少6像素，或卡牌高度的10%
	var margin = max(5.0, preview_size.x * 0.025)  # 边距至少5像素，或预览面板宽度的2.5%



	# 默认位置：卡牌正上方，水平居中对齐
	var pos = Vector2()
	pos.x = card_center_x - preview_size.x / 2.0  # 水平居中
	pos.y = card_top_y - preview_size.y - vertical_gap  # 上方



	# 边界检查和智能调整
	# 检查上方空间是否足够
	if pos.y < margin:
		# 上方空间不足，尝试下方
		pos.y = card_bottom_y + vertical_gap

		# 检查下方空间是否足够
		if pos.y + preview_size.y > viewport_size.y - margin:
			# 下方也不足，尝试右侧
			pos.y = actual_card_pos.y + (actual_card_size.y - preview_size.y) / 2.0  # 垂直居中对齐卡牌
			pos.x = actual_card_pos.x + actual_card_size.x + vertical_gap  # 右侧

			# 检查右侧空间是否足够
			if pos.x + preview_size.x > viewport_size.x - margin:
				# 右侧也不足，使用左侧
				pos.x = actual_card_pos.x - preview_size.x - vertical_gap  # 左侧

	# 智能边界检查（只在必要时调整）
	var final_pos = pos

	# 只有在预览面板真正超出可视区域时才进行调整
	if pos.x < margin:
		final_pos.x = margin
		print("  边界调整: X坐标从", pos.x, "调整到", final_pos.x)
	elif pos.x + preview_size.x > viewport_size.x - margin:
		final_pos.x = viewport_size.x - preview_size.x - margin
		print("  边界调整: X坐标从", pos.x, "调整到", final_pos.x)

	if pos.y < margin:
		final_pos.y = margin
		print("  边界调整: Y坐标从", pos.y, "调整到", final_pos.y)
	elif pos.y + preview_size.y > viewport_size.y - margin:
		final_pos.y = viewport_size.y - preview_size.y - margin
		print("  边界调整: Y坐标从", pos.y, "调整到", final_pos.y)

	# 使用全局坐标设置位置
	global_position = final_pos




# 根据卡牌尺寸计算自适应的预览面板尺寸
func _calculate_adaptive_preview_size(card_size: Vector2) -> Vector2:
	# 基础尺寸比例：预览面板应该比卡牌大一些，但不要太大
	var base_width_ratio = 3.5  # 预览面板宽度是卡牌宽度的3.5倍
	var base_height_ratio = 2.0  # 预览面板高度是卡牌高度的2倍

	# 计算基础尺寸
	var base_width = card_size.x * base_width_ratio
	var base_height = card_size.y * base_height_ratio

	# 设置最小和最大尺寸限制
	var min_size = Vector2(180, 120)  # 最小尺寸，确保内容可读
	var max_size = Vector2(300, 200)  # 最大尺寸，避免过大

	# 应用限制
	var final_width = clamp(base_width, min_size.x, max_size.x)
	var final_height = clamp(base_height, min_size.y, max_size.y)

	var result = Vector2(final_width, final_height)

	return result

# 根据预览面板尺寸调整字体大小
func _adjust_font_sizes(panel_size: Vector2):
	# 基于预览面板宽度计算字体大小
	var base_width = 200.0  # 基准宽度
	var scale_factor = panel_size.x / base_width

	# 计算字体大小
	var title_font_size = int(16 * scale_factor)
	var content_font_size = int(12 * scale_factor)

	# 限制字体大小范围
	title_font_size = clamp(title_font_size, 12, 20)
	content_font_size = clamp(content_font_size, 10, 16)



	# 应用字体大小
	if card_name_label:
		card_name_label.add_theme_font_size_override("font_size", title_font_size)

	# 调整所有内容标签的字体大小
	_apply_content_font_size(content_font_size)

# 应用内容字体大小到所有相关标签
func _apply_content_font_size(font_size: int):
	var labels_to_update = [
		value_text, suit_text, damage_text, defense_text, cost_text,
		wax_seals_text, frame_text, material_text, rarity_text, description_text
	]

	for label in labels_to_update:
		if label:
			label.add_theme_font_size_override("font_size", font_size)

# 调整面板样式以匹配卡牌
func _adjust_panel_style(panel_size: Vector2, card_size: Vector2):
	# 获取背景面板
	var background_panel = $Background
	if not background_panel:
		return

	# 根据卡牌尺寸调整圆角半径
	var corner_radius = max(4, min(card_size.x * 0.1, 12))

	# 根据面板尺寸调整边框宽度和阴影
	var border_width = max(1, panel_size.x / 100)
	var shadow_size = max(2, panel_size.x / 50)



	# 创建新的样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.4, 0.4, 0.6, 1)

	# 设置边框
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width

	# 设置圆角
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	# 设置阴影
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(2, 2)

	# 应用样式
	background_panel.add_theme_stylebox_override("panel", style)



# 获取有效的视口尺寸
func _get_effective_viewport_size() -> Vector2:
	# 始终使用主视口尺寸，不受Window影响
	return get_viewport().get_visible_rect().size



# 辅助方法：获取牌框显示名称
func _get_frame_display_name(frame_type: String) -> String:
	match frame_type:
		"STONE":
			return "石质"
		"SILVER":
			return "银质"
		"GOLD":
			return "金质"
		_:
			return frame_type

# 辅助方法：获取材质显示名称
func _get_material_display_name(material_type: String) -> String:
	match material_type:
		"GLASS":
			return "玻璃"
		"ROCK":
			return "岩石"
		"METAL":
			return "金属"
		_:
			return material_type

# 辅助方法：获取稀有度显示名称
func _get_rarity_display_name(rarity: String) -> String:
	match rarity:
		"common":
			return "普通"
		"rare":
			return "稀有"
		"epic":
			return "史诗"
		"legendary":
			return "传说"
		_:
			return "未知"
