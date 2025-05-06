extends Node2D

# 卡牌类型枚举
enum CardType { CLUB, DIAMOND, HEART, SPADE }

# 卡牌基本属性
var card_id: int = 1       # 卡牌的唯一ID
var card_type: int = 0     # 卡牌花色
var card_value: int = 1    # 卡牌点数 (1-13)
var original_position: Vector2  # 卡牌的原始位置

# 准备阶段 - 当节点进入场景树时
func _ready():
	# 记录初始位置
	original_position = position
	
	# 创建简单卡牌显示
	create_card_display()

# 初始化卡牌属性
func init_card(id: int, type: int, value: int):
	card_id = id
	card_type = type
	card_value = value
	
	# 更新卡牌显示
	create_card_display()

# 创建简单卡牌显示
func create_card_display():
	# 创建默认卡牌外观
	var default_color
	var symbol = ""
	
	# 设置花色颜色和符号
	match card_type:
		CardType.CLUB: 
			default_color = Color(0.2, 0.6, 0.3) # 梅花绿色
			symbol = "♣"
		CardType.DIAMOND: 
			default_color = Color(0.7, 0.2, 0.2) # 方块红色
			symbol = "♦"
		CardType.HEART: 
			default_color = Color(0.9, 0.2, 0.2) # 红桃红色
			symbol = "♥"
		CardType.SPADE: 
			default_color = Color(0.1, 0.1, 0.2) # 黑桃黑色
			symbol = "♠"
		_: 
			default_color = Color(0.5, 0.5, 0.5) # 灰色默认
			symbol = "?"
	
	# 创建卡牌背景
	if has_node("CardSprite"):
		$CardSprite.modulate = Color(0.15, 0.2, 0.4) # 深蓝色背景
	
	# 移除旧标签
	if has_node("ValueLabel"):
		get_node("ValueLabel").queue_free()
	if has_node("SymbolLabel"):
		get_node("SymbolLabel").queue_free()
	
	# 动态创建卡牌数值标签
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	
	# 设置卡牌数值文本
	match card_value:
		1: value_label.text = "A"
		11: value_label.text = "J"
		12: value_label.text = "Q"
		13: value_label.text = "K"
		_: value_label.text = str(card_value)
	
	# 设置标签位置
	value_label.position = Vector2(-50, -70)
	value_label.size = Vector2(100, 40)
	
	# 动态创建花色标签
	var symbol_label = Label.new()
	symbol_label.name = "SymbolLabel"
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol_label.add_theme_font_size_override("font_size", 36)
	symbol_label.text = symbol
	symbol_label.add_theme_color_override("font_color", default_color)
	
	# 设置花色标签位置
	symbol_label.position = Vector2(-50, -20)
	symbol_label.size = Vector2(100, 70)
	
	# 添加标签到卡牌
	add_child(value_label)
	add_child(symbol_label) 
