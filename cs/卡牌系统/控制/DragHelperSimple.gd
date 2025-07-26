extends Node

# 简化版拖拽辅助工具，避免与自动加载单例冲突

# 悬停偏移
var hover_offset = Vector2(0, -20)

# 拖拽对象
var dragged_object = null
var original_positions = {}

# 开始拖拽
func begin_drag(control):
	if control == null:
		return
		
	dragged_object = control
	
	# 保存原始位置
	if not original_positions.has(control):
		original_positions[control] = control.global_position
	
# 结束拖拽
func end_drag():
	dragged_object = null
	
# 更新拖拽位置
func update_position(node, global_mouse_pos, drag_offset = Vector2.ZERO):
	if node == null:
		return
		
	node.global_position = global_mouse_pos - drag_offset
	
# 悬停效果
func hover(control, is_hovering, custom_offset = null):
	if control == null:
		return
	
	# 使用自定义偏移或默认偏移	
	var offset = custom_offset if custom_offset != null else hover_offset
	
	# 保存原始位置
	if not original_positions.has(control):
		original_positions[control] = control.position
		
	if is_hovering:
		control.position = original_positions[control] + offset
	else:
		control.position = original_positions[control]

# 获取原始位置
func get_original_position(control):
	if control != null and original_positions.has(control):
		return original_positions[control]
	return null

# 清理引用
func clear_references(control = null):
	if control != null:
		if original_positions.has(control):
			original_positions.erase(control)
		if dragged_object == control:
			dragged_object = null
	else:
		original_positions.clear()
		dragged_object = null 
