class_name ArtifactItem
extends Control

# 信号
signal artifact_clicked(artifact)

# 法器数据
var artifact_data = null

# 节点引用
@onready var background = $Background
@onready var name_label = $NameLabel

# 法器纹理
var artifact_textures = {
	"crystal": preload("res://assets/images/pokers/card_back.png"),
	"hourglass": preload("res://assets/images/pokers/card_back.png"),
	"ring": preload("res://assets/images/pokers/card_back.png")
}

func _ready():
	# 设置输入处理
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接输入事件
	gui_input.connect(_on_gui_input)

# 设置法器数据
func setup(data):
	artifact_data = data
	
	# 更新显示
	update_display()

# 更新显示
func update_display():
	if not artifact_data:
		return
	
	# 设置名称
	name_label.text = artifact_data.name if artifact_data.has("name") else "未知法器"
	
	# 设置背景纹理
	var artifact_type = artifact_data.type if artifact_data.has("type") else "crystal"
	if artifact_textures.has(artifact_type):
		background.texture = artifact_textures[artifact_type]

# 获取法器数据
func get_artifact_data():
	return artifact_data

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 点击效果
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
			
			# 发出信号
			emit_signal("artifact_clicked", self)

# 设置选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # 亮起
	else:
		modulate = Color(1, 1, 1)  # 正常 