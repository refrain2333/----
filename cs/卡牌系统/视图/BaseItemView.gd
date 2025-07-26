class_name BaseItemView
extends Control

# 公共信号
signal item_clicked(view_instance)

# 共享属性
var item_data: Resource = null  # 将由子类指定具体类型
var rarity_colors = {
	GlobalEnums.Rarity.COMMON: Color(0.7, 0.7, 0.7),    # 灰色
	GlobalEnums.Rarity.RARE: Color(0.0, 0.5, 0.9),      # 蓝色
	GlobalEnums.Rarity.EPIC: Color(0.7, 0.2, 0.9),      # 紫色
	GlobalEnums.Rarity.LEGENDARY: Color(1.0, 0.7, 0.0)  # 金色
}

# 节点引用 - 子类中应该使用@onready获取具体节点
var background: TextureRect
var name_label: Label
var description_label: Label
var rarity_indicator: ColorRect

func _ready():
	# 设置输入处理
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接输入事件
	gui_input.connect(_on_gui_input)

# 子类需要实现此方法
func update_view():
	push_error("BaseItemView: 子类必须实现update_view()方法")

# 设置物品数据并更新视图
func setup(data: Resource):
	item_data = data
	update_view()

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 点击效果
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
			
			# 发出信号
			emit_signal("item_clicked", self)

# 设置选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # 亮起
	else:
		modulate = Color(1, 1, 1)  # 正常

# 根据稀有度获取颜色
func get_rarity_color(rarity_type) -> Color:
	return rarity_colors.get(rarity_type, Color(1, 1, 1)) 
