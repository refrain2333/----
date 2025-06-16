extends Node

# 简化版拖拽辅助工具，避免与自动加载单例冲突

# 悬停偏移
var hover_offset = Vector2(0, -20)

# 拖拽对象
var dragged_object = null

# 开始拖拽
func begin_drag(control):
	if control == null:
		return
		
	dragged_object = control
	
# 结束拖拽
func end_drag():
	dragged_object = null
	
# 更新拖拽位置
func update_position(node, global_mouse_pos, drag_offset = Vector2.ZERO):
	if node == null:
		return
		
	node.global_position = global_mouse_pos - drag_offset
	
# 悬停效果
func hover(control, is_hovering):
	if control == null:
		return
		
	if is_hovering:
		control.position.y -= 20  # 悬停时向上移动
	else:
		control.position.y += 20  # 悬停结束时移回原位 
