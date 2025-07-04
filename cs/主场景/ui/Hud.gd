class_name Hud
extends Control

# 节点引用
@onready var status_label = $StatusLabel

func _ready():
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("hud", self)

# 更新UI
func update_ui():
	# 在这里可以添加其他HUD元素的更新逻辑
	pass

# 设置状态文本
func set_status_text(text: String):
	if status_label:
		status_label.text = text 
