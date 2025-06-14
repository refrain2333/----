class_name RuneCardPreview
extends Control

# 信号
signal card_clicked(card)

# 卡牌数据
var card_data = null

# 节点引用
@onready var background = $Background
@onready var cost_label = $CostLabel
@onready var name_label = $NameLabel

# 卡牌纹理
var card_textures = {
	"fire": preload("res://assets/images/pokers/card_back.png"),  # 临时使用牌背
	"water": preload("res://assets/images/pokers/card_back.png"),
	"earth": preload("res://assets/images/pokers/card_back.png"),
	"air": preload("res://assets/images/pokers/card_back.png")
}

# 元素颜色
var element_colors = {
	"fire": Color(1, 0.3, 0.3),
	"water": Color(0.3, 0.5, 1),
	"earth": Color(0.5, 0.3, 0.1),
	"air": Color(0.8, 0.8, 1)
}

func _ready():
	# 设置输入处理
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接输入事件
	gui_input.connect(_on_gui_input)

# 设置卡牌数据
func setup(data):
	card_data = data
	
	# 更新显示
	update_display()

# 更新显示
func update_display():
	if not card_data:
		return
	
	# 设置费用
	cost_label.text = str(card_data.cost) if card_data.has("cost") else "0"
	
	# 设置名称
	name_label.text = card_data.name if card_data.has("name") else "未知符文"
	
	# 设置元素颜色
	var element = card_data.element if card_data.has("element") else "neutral"
	if element_colors.has(element):
		name_label.add_theme_color_override("font_color", element_colors[element])
	
	# 设置背景纹理
	if card_textures.has(element):
		background.texture = card_textures[element]

# 获取卡牌数据
func get_card_data():
	return card_data

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 点击效果
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
			
			# 发出信号
			emit_signal("card_clicked", self) 