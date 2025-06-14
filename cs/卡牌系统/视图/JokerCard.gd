class_name JokerCard
extends Control

# 信号
signal joker_clicked(joker)

# 小丑卡数据
var joker_data = null

# 节点引用
@onready var background = $Background
@onready var name_label = $NameLabel

# 小丑卡纹理
var joker_textures = {
	"common_joker": preload("res://assets/images/pokers/5.jpg"),  # 临时使用已有图像
	"greedy_joker": preload("res://assets/images/pokers/6.jpg")
}

func _ready():
	# 设置输入处理
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接输入事件
	gui_input.connect(_on_gui_input)

# 设置小丑卡数据
func setup(data):
	joker_data = data
	
	# 更新显示
	update_display()

# 更新显示
func update_display():
	if not joker_data:
		return
	
	# 设置名称
	name_label.text = joker_data.name if joker_data.has("name") else "未知小丑"
	
	# 设置背景纹理
	var joker_type = joker_data.type if joker_data.has("type") else "common_joker"
	if joker_textures.has(joker_type):
		background.texture = joker_textures[joker_type]

# 获取小丑卡数据
func get_joker_data():
	return joker_data

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 点击效果
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
			
			# 发出信号
			emit_signal("joker_clicked", self)

# 设置选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # 亮起
	else:
		modulate = Color(1, 1, 1)  # 正常 