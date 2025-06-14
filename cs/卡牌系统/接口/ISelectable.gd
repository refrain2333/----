class_name ISelectable
extends RefCounted

# 可选择对象接口：定义所有可被选择的对象应该实现的方法

# 信号
signal selected(selectable)
signal deselected(selectable)
signal highlight_changed(selectable, is_highlighted)

# 属性
var _is_selected: bool = false
var _is_highlighted: bool = false
var _is_selectable: bool = true

# 设置选中状态
func set_selected(value: bool) -> void:
	if _is_selected == value:
		return
		
	_is_selected = value
	
	if _is_selected:
		emit_signal("selected", self)
	else:
		emit_signal("deselected", self)

# 获取选中状态
func is_selected() -> bool:
	return _is_selected

# 设置高亮状态
func set_highlighted(value: bool) -> void:
	if _is_highlighted == value:
		return
		
	_is_highlighted = value
	emit_signal("highlight_changed", self, _is_highlighted)

# 获取高亮状态
func is_highlighted() -> bool:
	return _is_highlighted

# 设置是否可选择
func set_selectable(value: bool) -> void:
	_is_selectable = value

# 获取是否可选择
func is_selectable() -> bool:
	return _is_selectable

# 当对象被点击时调用
func on_clicked() -> void:
	if _is_selectable:
		set_selected(not _is_selected)

# 当鼠标进入对象时调用
func on_mouse_entered() -> void:
	if _is_selectable:
		set_highlighted(true)

# 当鼠标离开对象时调用
func on_mouse_exited() -> void:
	set_highlighted(false) 
