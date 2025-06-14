class_name DiscoveryCard
extends Control

# 信号
signal discovery_clicked(discovery)

# 发现卡数据
var discovery_data = null

# 节点引用
@onready var background = $Background
@onready var name_label = $NameLabel

# 发现卡纹理
var discovery_textures = {
	"fire": preload("res://assets/images/pokers/card_back.png"),
	"water": preload("res://assets/images/pokers/card_back.png")
}

# 元素颜色
var element_colors = {
	"fire": Color(1, 0.3, 0.3),
	"water": Color(0.3, 0.5, 1)
}

func _ready():
	# 设置输入处理
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接输入事件
	gui_input.connect(_on_gui_input)

# 设置发现卡数据
func setup(data):
	discovery_data = data
	
	# 更新显示
	update_display()

# 更新显示
func update_display():
	if not discovery_data:
		return
	
	# 设置名称
	name_label.text = discovery_data.name if discovery_data.has("name") else "未知发现"
	
	# 设置元素颜色
	var element = discovery_data.element if discovery_data.has("element") else "neutral"
	if element_colors.has(element):
		name_label.add_theme_color_override("font_color", element_colors[element])
	
	# 设置背景纹理
	if discovery_textures.has(element):
		background.texture = discovery_textures[element]

# 获取发现卡数据
func get_discovery_data():
	return discovery_data

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 点击效果
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
			
			# 发出信号
			emit_signal("discovery_clicked", self)

# 设置选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # 亮起
	else:
		modulate = Color(1, 1, 1)  # 正常 