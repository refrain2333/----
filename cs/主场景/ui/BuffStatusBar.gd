class_name BuffStatusBar
extends HBoxContainer

# Buff图标预制体
var buff_icon_scene = preload("res://cs/主场景/ui/BuffIcon.tscn")

# 引用
var event_manager = null

# 字体
var font = preload("res://assets/font/ZCOOL_KuaiLe/ZCOOLKuaiLe-Regular.ttf")

# 图标颜色
const BUFF_COLOR = Color(0.2, 0.8, 0.2)  # 绿色
const DEBUFF_COLOR = Color(0.8, 0.2, 0.2)  # 红色
const TERM_COLOR = Color(0.3, 0.3, 0.8)  # 蓝色

func _ready():
	# 获取EventManager引用
	event_manager = get_node_or_null("/root/EventManager")
	
	if event_manager:
		# 连接信号
		event_manager.buff_applied.connect(_on_buff_applied)
		event_manager.debuff_applied.connect(_on_debuff_applied)
		event_manager.buff_expired.connect(_on_buff_expired)
		event_manager.debuff_expired.connect(_on_debuff_expired)
		
		# 初始化现有buff
		_refresh_all_buffs()
	else:
		push_error("BuffStatusBar: 无法获取EventManager引用")

# 刷新所有buff显示
func _refresh_all_buffs():
	# 清除所有现有图标
	for child in get_children():
		child.queue_free()
	
	# 添加学期Buff图标
	for buff in event_manager.active_term_buffs:
		_add_buff_icon(buff, true)
	
	# 添加回合Buff图标
	for buff in event_manager.active_turn_buffs:
		_add_buff_icon(buff, false)
	
	# 添加Debuff图标
	for debuff in event_manager.active_debuffs:
		_add_debuff_icon(debuff)

# 当有新Buff应用时
func _on_buff_applied(buff_data):
	var is_term_buff = event_manager.active_term_buffs.has(buff_data)
	_add_buff_icon(buff_data, is_term_buff)

# 当有新Debuff应用时
func _on_debuff_applied(debuff_data):
	_add_debuff_icon(debuff_data)

# 当Buff过期时
func _on_buff_expired(buff_data):
	_remove_icon_by_id(buff_data.id)

# 当Debuff过期时
func _on_debuff_expired(debuff_data):
	_remove_icon_by_id(debuff_data.id)

# 添加Buff图标
func _add_buff_icon(buff_data, is_term_buff: bool = false):
	var icon = _create_icon()
	
	# 设置图标属性
	icon.name = "buff_" + buff_data.id
	icon.tooltip_text = buff_data.description
	
	# 设置图标颜色（学期buff用蓝色，回合buff用绿色）
	var panel = icon.get_node("Panel")
	panel.self_modulate = TERM_COLOR if is_term_buff else BUFF_COLOR
	
	# 设置持续时间标签
	var duration_label = icon.get_node("DurationLabel")
	if buff_data.duration > 0:
		duration_label.text = str(buff_data.duration)
	else:
		duration_label.text = "∞"  # 无限持续时间
	
	# 设置图标文字（使用buff id的首字母）
	var label = icon.get_node("Label")
	if buff_data.id.length() > 0:
		label.text = buff_data.id[0].to_upper()
	
	add_child(icon)
	return icon

# 添加Debuff图标
func _add_debuff_icon(debuff_data):
	var icon = _create_icon()
	
	# 设置图标属性
	icon.name = "debuff_" + debuff_data.id
	icon.tooltip_text = debuff_data.description
	
	# 设置图标颜色（红色）
	var panel = icon.get_node("Panel")
	panel.self_modulate = DEBUFF_COLOR
	
	# 设置持续时间标签
	var duration_label = icon.get_node("DurationLabel")
	if debuff_data.duration > 0:
		duration_label.text = str(debuff_data.duration)
	else:
		duration_label.text = "∞"  # 无限持续时间
	
	# 设置图标文字（使用debuff id的首字母）
	var label = icon.get_node("Label")
	if debuff_data.id.length() > 0:
		label.text = debuff_data.id[0].to_upper()
	
	add_child(icon)
	return icon

# 通过ID删除图标
func _remove_icon_by_id(buff_id: String):
	var buff_node = get_node_or_null("buff_" + buff_id)
	if buff_node:
		buff_node.queue_free()
		return
	
	var debuff_node = get_node_or_null("debuff_" + buff_id)
	if debuff_node:
		debuff_node.queue_free()

# 创建图标基础控件
func _create_icon():
	# 如果有预制体，直接实例化
	if buff_icon_scene:
		return buff_icon_scene.instantiate()
	
	# 否则创建自定义图标
	var container = Control.new()
	container.custom_minimum_size = Vector2(40, 40)
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(panel)
	
	var label = Label.new()
	label.name = "Label"
	label.text = "B"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_override("font", font)
	container.add_child(label)
	
	var duration_label = Label.new()
	duration_label.name = "DurationLabel"
	duration_label.text = "0"
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	duration_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	duration_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	duration_label.size = Vector2(20, 20)
	duration_label.add_theme_font_override("font", font)
	duration_label.add_theme_font_size_override("font_size", 14)
	container.add_child(duration_label)
	
	return container 