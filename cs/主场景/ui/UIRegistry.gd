extends Node

# UIRegistry - 全局UI组件注册表
# 用于在不同场景之间共享UI引用和状态

# UI组件引用
var sidebar = null
var hud = null
var hand_dock = null
var deck_widget = null
var top_dock = null

# UI管理器引用
var ui_manager = null

# 注册UI组件
func register_ui_component(component_name: String, component):
	match component_name:
		"sidebar":
			sidebar = component
		"hud":
			hud = component
		"hand_dock":
			hand_dock = component
		"deck_widget":
			deck_widget = component
		"top_dock":
			top_dock = component
		"ui_manager":
			ui_manager = component

# 获取UI组件
func get_ui_component(component_name: String):
	match component_name:
		"sidebar":
			return sidebar
		"hud":
			return hud
		"hand_dock":
			return hand_dock
		"deck_widget":
			return deck_widget
		"top_dock":
			return top_dock
		"ui_manager":
			return ui_manager
	return null

# 更新所有UI组件
func update_all_ui():
	if ui_manager and ui_manager.has_method("update_ui"):
		ui_manager.update_ui()

# 设置状态文本
func set_status(text: String, duration: float = 3.0):
	if ui_manager and ui_manager.has_method("set_status"):
		ui_manager.set_status(text, duration) 
