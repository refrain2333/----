class_name DragHelper
extends Node

# 拖拽辅助工具，统一管理Area2D和Control的拖拽逻辑

# 拖拽状态常量
enum DragState { NONE, STARTED, DRAGGING, ENDED }

# 拖拽配置
class DragConfig:
	var highlight_color: Color = Color(1, 1, 0.5, 0.3)  # 高亮颜色
	var drag_z_index: int = 100                          # 拖拽时的Z顺序
	var drag_opacity: float = 0.8                        # 拖拽时的不透明度
	var hover_offset: Vector2 = Vector2(0, -20)          # 悬停时的偏移
	var hover_tween_duration: float = 0.1                # 悬停动画持续时间
	var drag_threshold: float = 10.0                     # 拖拽阈值（像素）
	var use_cursor_change: bool = true                   # 是否改变光标
	var cursor_shape: int = Input.CURSOR_DRAG            # 拖拽时的光标形状

# 默认配置
static var default_config: DragConfig = DragConfig.new()

# 当前正在拖拽的对象
static var current_dragged_object = null

# 拖拽开始前缓存的数据
static var _drag_cache = {}

# 单例Tween，用于减少创建开销
static var _shared_tween: Tween = null

# 初始化共享Tween
static func _init_shared_tween(node: Node) -> Tween:
	if _shared_tween == null or not is_instance_valid(_shared_tween):
		_shared_tween = node.create_tween()
	return _shared_tween

# 适用于Control节点的拖拽开始
static func begin_drag_control(control: Control, config: DragConfig = null) -> void:
	if config == null:
		config = default_config
		
	# 缓存原始状态
	_drag_cache[control] = {
		"z_index": control.z_index,
		"modulate": control.modulate,
		"original_position": control.global_position
	}
	
	# 设置拖拽状态
	control.z_index = config.drag_z_index
	control.modulate.a = config.drag_opacity
	
	# 设置当前拖拽对象
	current_dragged_object = control
	
	# 改变光标
	if config.use_cursor_change:
		Input.set_default_cursor_shape(config.cursor_shape)

# 适用于Area2D节点的拖拽开始
static func begin_drag_area2d(area: Area2D, config: DragConfig = null) -> void:
	if config == null:
		config = default_config
		
	# 缓存原始状态
	_drag_cache[area] = {
		"z_index": area.z_index,
		"modulate": area.modulate,
		"original_position": area.global_position
	}
	
	# 设置拖拽状态
	area.z_index = config.drag_z_index
	area.modulate.a = config.drag_opacity
	
	# 设置当前拖拽对象
	current_dragged_object = area
	
	# 改变光标
	if config.use_cursor_change:
		Input.set_default_cursor_shape(config.cursor_shape)

# 通用拖拽结束
static func end_drag(node: Node) -> void:
	if not _drag_cache.has(node):
		return
		
	# 恢复原始状态
	if _drag_cache[node].has("z_index"):
		node.z_index = _drag_cache[node].z_index
	if _drag_cache[node].has("modulate"):
		node.modulate = _drag_cache[node].modulate
	
	# 清除缓存
	_drag_cache.erase(node)
	
	# 清除当前拖拽对象
	if current_dragged_object == node:
		current_dragged_object = null
	
	# 恢复光标
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# 更新拖拽位置
static func update_drag_position(node: Node, global_mouse_pos: Vector2, drag_offset: Vector2 = Vector2.ZERO) -> void:
	node.global_position = global_mouse_pos - drag_offset

# 适用于Control的悬停效果
static func hover_control(control: Control, is_hovering: bool, config: DragConfig = null) -> void:
	if config == null:
		config = default_config
		
	if not _drag_cache.has(control):
		_drag_cache[control] = {
			"original_position": control.position
		}
	
	var tween = _init_shared_tween(control)
	if tween.is_running():
		tween.kill()
	
	tween = control.create_tween()
	
	if is_hovering:
		tween.tween_property(control, "position", _drag_cache[control].original_position + config.hover_offset, config.hover_tween_duration)
	else:
		tween.tween_property(control, "position", _drag_cache[control].original_position, config.hover_tween_duration)

# 适用于Area2D的悬停效果
static func hover_area2d(area: Area2D, is_hovering: bool, config: DragConfig = null) -> void:
	if config == null:
		config = default_config
		
	if not _drag_cache.has(area):
		_drag_cache[area] = {
			"original_position": area.position
		}
	
	var tween = area.create_tween()
	
	if is_hovering:
		tween.tween_property(area, "position:y", _drag_cache[area].original_position.y + config.hover_offset.y, config.hover_tween_duration)
	else:
		tween.tween_property(area, "position:y", _drag_cache[area].original_position.y, config.hover_tween_duration)

# 判断是否超过拖拽阈值
static func is_over_drag_threshold(event_position: Vector2, press_start_pos: Vector2, config: DragConfig = null) -> bool:
	if config == null:
		config = default_config
		
	return (event_position - press_start_pos).length() >= config.drag_threshold

# 高亮显示
static func highlight(node: Node, enable: bool = true, highlight_node: Node = null) -> void:
	if highlight_node == null:
		# 尝试查找高亮节点
		if node.has_node("Highlight") or node.has_node("HighlightBorder"):
			highlight_node = node.get_node("Highlight") if node.has_node("Highlight") else node.get_node("HighlightBorder")
		else:
			print("警告: 未找到高亮节点，无法应用高亮效果")
			return
	
	highlight_node.visible = enable

# 序列化拖拽状态，用于存档
static func serialize_drag_state(node: Node) -> Dictionary:
	if not _drag_cache.has(node):
		return {}
		
	return {
		"original_position": {
			"x": _drag_cache[node].original_position.x,
			"y": _drag_cache[node].original_position.y
		}
	}

# 从序列化数据恢复拖拽状态
static func deserialize_drag_state(node: Node, data: Dictionary) -> void:
	if data.is_empty():
		return
		
	_drag_cache[node] = {
		"original_position": Vector2(data.original_position.x, data.original_position.y)
	}
	
	node.position = _drag_cache[node].original_position 
