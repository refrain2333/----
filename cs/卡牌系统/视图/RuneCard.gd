class_name RuneCard
extends Control

# 信号
signal card_drag_started(card)
signal card_dropped(card, position)
signal card_clicked(card)

# 卡牌数据
var card_data = null

# 节点引用
@onready var background = $Background
@onready var cost_label = $CostLabel
@onready var name_label = $NameLabel
@onready var element_label = $ElementLabel

# 拖拽相关
var dragging = false
var drag_offset = Vector2()
var original_position = Vector2()
var original_parent = null

# 卡牌纹理
var card_textures = {
	"fire": preload("res://assets/images/pokers/1.jpg"),  # 临时使用已有图像
	"water": preload("res://assets/images/pokers/2.jpg"),
	"earth": preload("res://assets/images/pokers/3.jpg"),
	"air": preload("res://assets/images/pokers/4.jpg")
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
	
	# 设置元素
	var element = card_data.element if card_data.has("element") else "neutral"
	element_label.text = _get_element_name(element)
	
	# 设置元素颜色
	if element_colors.has(element):
		element_label.add_theme_color_override("font_color", element_colors[element])
	
	# 设置背景纹理
	if card_textures.has(element):
		background.texture = card_textures[element]

# 获取元素名称
func _get_element_name(element_key):
	var names = {
		"fire": "火",
		"water": "水",
		"earth": "土",
		"air": "风",
		"neutral": "中性"
	}
	
	return names[element_key] if names.has(element_key) else element_key

# 获取卡牌数据
func get_card_data():
	return card_data

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖拽
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				original_position = global_position
				original_parent = get_parent()
				
				# 提高Z索引
				z_index = 10
				
				# 发出信号
				emit_signal("card_drag_started", self)
				
				# 创建拖拽效果
				var tween = create_tween()
				tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
				
				# 将卡牌移至顶层
				var canvas_layer = CanvasLayer.new()
				canvas_layer.layer = 10
				get_tree().root.add_child(canvas_layer)
				get_parent().remove_child(self)
				canvas_layer.add_child(self)
				global_position = original_position
			else:
				# 结束拖拽
				if dragging:
					dragging = false
					
					# 恢复Z索引
					z_index = 0
					
					# 恢复缩放
					var tween = create_tween()
					tween.tween_property(self, "scale", Vector2(1, 1), 0.1)
					
					# 从临时CanvasLayer移回原始父节点
					var canvas_layer = get_parent()
					if canvas_layer is CanvasLayer:
						canvas_layer.remove_child(self)
						original_parent.add_child(self)
						canvas_layer.queue_free()
					
					# 发出信号
					emit_signal("card_dropped", self, get_global_mouse_position())
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# 右键点击
			emit_signal("card_clicked", self)
	
	elif event is InputEventMouseMotion and dragging:
		# 拖拽移动
		global_position = get_global_mouse_position() - drag_offset

# 处理过程
func _process(delta):
	if dragging:
		# 更新拖拽位置
		global_position = get_global_mouse_position() - drag_offset 