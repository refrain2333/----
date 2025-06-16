class_name CardView
extends Control
# 实现 ISelectable 接口

# 卡牌数据
var card_data: CardData = null  # 引用 cs/卡牌系统/数据/CardData.gd
var is_flipped: bool = false
var is_draggable: bool = true
var original_position: Vector2
var original_parent = null
var original_z_index: int = 0
var hover_offset: Vector2 = Vector2(0, -20)  # 鼠标悬停时向上偏移量
var hover_enabled: bool = true  # 是否启用悬停效果
var is_selected: bool = false  # 卡牌是否被选中
var return_to_origin: bool = true  # 定义是否返回原位的标志
var _original_position_set: bool = false # 用于延迟捕获原始位置
var original_size: Vector2

# 视觉组件引用
@onready var front_texture: TextureRect = $CardFront
@onready var back_texture: TextureRect = $CardBack
@onready var card_name_label: Label = $CardFront/NameLabel
@onready var card_element_label: Label = $CardFront/ElementLabel
@onready var card_power_label: Label = $CardFront/PowerLabel
@onready var highlight_panel: Panel = $Highlight
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 拖放相关
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# 信号
signal card_clicked(card_view)
signal card_dragged(card_view)
signal card_dropped(card_view, drop_position)
signal card_hovered(card_view)
signal card_unhovered(card_view)
signal selection_changed(card_view, is_selected)  # 新增：选中状态变化信号
signal card_drag_started(card_view)  # 添加缺失的信号

func _ready():
	custom_minimum_size = Vector2(135, 180)  # 设置最小大小而非直接修改size
	# 延迟一帧以确保布局更新后再缓存位置
	await get_tree().process_frame
	_cache_original_position()
	highlight(false)
	
	# 设置输入处理
	set_process_input(true)
	
	# 设置鼠标过滤器为STOP，确保卡牌可以接收鼠标输入
	mouse_filter = Control.MOUSE_FILTER_STOP
	print("CardView '%s': 设置mouse_filter = MOUSE_FILTER_STOP (%d)" % [name, Control.MOUSE_FILTER_STOP])
	
	# 确保所有子节点的鼠标过滤器设置正确
	print("CardView '%s': 设置所有子节点的mouse_filter = MOUSE_FILTER_IGNORE" % name)
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("CardView '%s': 子节点 %s 的mouse_filter设置为IGNORE" % [name, child.name])
	
	# 连接信号
	if not gui_input.is_connected(_handle_gui_input):
		gui_input.connect(_handle_gui_input)
		print("CardView '%s': 已连接gui_input信号" % name)
	else:
		print("CardView '%s': gui_input信号已连接，跳过" % name)
	
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
		print("CardView '%s': 已连接mouse_entered信号" % name)
	else:
		print("CardView '%s': mouse_entered信号已连接，跳过" % name)
		
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
		print("CardView '%s': 已连接mouse_exited信号" % name)
	else:
		print("CardView '%s': mouse_exited信号已连接，跳过" % name)
	
	original_z_index = z_index
	print("CardView '%s': _ready初始化完成" % name)

# 缓存卡牌原始位置
func _cache_original_position():
	if not is_inside_tree():
		return  # 如果不在树中，不进行缓存
		
	original_position = position
	original_size = size
	_original_position_set = true
	print("CardView '%s': 已缓存原始位置 (%s, %s) 尺寸 (%s, %s)" % [name, original_position.x, original_position.y, original_size.x, original_size.y])

# 设置卡牌数据并更新视图
func setup(new_card_data: CardData):
	card_data = new_card_data
	update_view()

# 更新卡牌视图
func update_view():
	if not card_data:
		return
	
	# 确保UI组件已经初始化
	if not is_inside_tree() or not is_node_ready():
		print("CardView.update_view: 节点尚未准备好，延迟更新")
		call_deferred("update_view")
		return
	
	# 检查front_texture是否存在
	if not front_texture:
		print("CardView.update_view: front_texture为空，尝试重新获取")
		front_texture = get_node_or_null("CardFront")
		if not front_texture:
			print("CardView.update_view: 无法获取CardFront节点")
			return
	
	# 加载卡牌贴图
	var texture = null
	
	# 1. 如果卡牌数据有指定贴图路径，首先尝试使用它
	if card_data.has("texture_path") and card_data.texture_path:
		var path = card_data.texture_path
		
		# 处理@路径格式，将其转换为res://格式
		if path.begins_with("@/pokers/"):
			var alt_path = "res://assets/images/pokers/" + path.substr(9)
			print("处理替代路径: @ -> res://，尝试: " + alt_path)
			path = alt_path
		
		print("尝试加载贴图路径: " + path)
		if ResourceLoader.exists(path):
			texture = load(path)
			print("成功从texture_path加载贴图")
		else:
			print("警告: 贴图路径不存在: " + path)
	
	# 2. 否则，根据卡牌的元素和值确定图片编号
	if not texture:
		var image_number = 0
		
		# 计算图片编号
		if card_data.has("element") and card_data.has("value"):
			var element = card_data.element
			var value = card_data.value
			
			match element:
				"earth": # 黑桃 1-13
					image_number = value
				"fire": # 红桃 14-26 
					image_number = 13 + value
				"air": # 梅花 27-39
					image_number = 26 + value
				"water": # 方片 40-52
					image_number = 40 - 1 + value
			
			# 尝试加载对应编号的图片
			var image_path = "res://assets/images/pokers/" + str(image_number) + ".jpg"
			var alt_image_path = "@/pokers/" + str(image_number) + ".jpg"
			
			print("尝试加载图片路径1: " + image_path)
			if ResourceLoader.exists(image_path):
				texture = load(image_path)
				print("成功从路径1加载卡牌图片")
			else:
				print("路径1找不到卡牌图片，尝试替代路径")
				
				# 尝试多种可能的路径格式
				var possible_paths = [
					"res://assets/images/pokers/" + str(image_number) + ".jpg",
					"res://pokers/" + str(image_number) + ".jpg",
					"res://assets/pokers/" + str(image_number) + ".jpg",
					"res://images/pokers/" + str(image_number) + ".jpg"
				]
				
				var loaded = false
				for path in possible_paths:
					print("尝试路径: " + path)
					if ResourceLoader.exists(path):
						texture = load(path)
						print("成功从路径加载卡牌图片: " + path)
						loaded = true
						break
				
				if not loaded:
					print("所有图片路径都找不到: " + str(image_number) + ".jpg")
	
	# 3. 如果前两步都失败，尝试使用备用图片
	if not texture:
		print("尝试加载备用图片")
		var alt_paths = [
			"res://assets/images/pokers/1.jpg", # 默认使用黑桃A
			"res://pokers/1.jpg",
			"res://assets/pokers/1.jpg",
			"res://assets/images/pokers/card_back.png",
			"res://pokers/card_back.png",
			"res://assets/pokers/card_back.png",
			"res://assets/images/card.png",
			"res://assets/card.png",
			"res://icon.svg"
		]
		
		for path in alt_paths:
			print("尝试备用路径: " + path)
			if ResourceLoader.exists(path):
				texture = load(path)
				print("使用备用卡牌图片: " + path)
				break
			else:
				print("备用路径不存在: " + path)
	
	# 4. 如果所有尝试都失败，创建一个简单的纯色纹理
	if not texture:
		print("所有图片路径都失败，创建纯色纹理")
		var image = Image.create(100, 150, false, Image.FORMAT_RGB8)
		image.fill(Color(0.3, 0.3, 0.3))
		texture = ImageTexture.create_from_image(image)
	
	# 设置贴图
	if texture and front_texture:
		front_texture.texture = texture
		print("CardView.update_view: 成功设置卡牌贴图")
	elif not front_texture:
		print("CardView.update_view: 错误 - front_texture仍然为空")
	elif not texture:
		print("CardView.update_view: 错误 - texture为空")
	
	# 更新卡牌信息标签
	if card_name_label:
		if card_data.has("display_name"):
			card_name_label.text = card_data.display_name
		elif card_data.has("name"):
			card_name_label.text = card_data.name
		else:
			card_name_label.text = "未命名卡牌"
	else:
		print("CardView.update_view: 错误 - card_name_label为空")
	
	var element_text = ""
	if card_data.has("element"):
		var element_name = _get_element_display_name(card_data.element)
		var suit_name = _get_suit_display_name(card_data.suit if card_data.has("suit") else "")
		element_text = element_name + " (" + suit_name + ")"
	card_element_label.text = element_text
	
	var power_text = ""
	if card_data.has("power"):
		power_text = str(card_data.power)
	card_power_label.text = power_text
	
	# 根据元素设置颜色
	var element = card_data.element if card_data.has("element") else ""
	var element_color = _get_element_color(element)
	card_element_label.set("theme_override_colors/font_color", element_color)

# 获取元素显示名称
func _get_element_display_name(element: String) -> String:
	match element:
		"fire": return "火"
		"water": return "水"
		"earth": return "土"
		"air": return "风"
		"arcane": return "奥术"
		_: return "未知"

# 获取花色显示名称
func _get_suit_display_name(suit: String) -> String:
	match suit:
		"hearts": return "红桃"
		"diamonds": return "方片"
		"spades": return "黑桃"
		"clubs": return "梅花"
		_: return "未知"

# 获取元素颜色
func _get_element_color(element: String) -> Color:
	match element:
		"fire": return Color(1, 0.3, 0.3)  # 红色
		"water": return Color(0.3, 0.5, 1)  # 蓝色
		"earth": return Color(0.6, 0.4, 0.2)  # 棕色
		"air": return Color(0.7, 1, 1)  # 浅蓝色
		"arcane": return Color(0.8, 0.3, 1)  # 紫色
		_: return Color(1, 1, 1)  # 白色

# 翻转卡牌
func flip(flip_to_back: bool = false):
	is_flipped = flip_to_back
	front_texture.visible = !is_flipped
	back_texture.visible = is_flipped
	animation_player.play("flip")

# 高亮显示
func highlight(enable: bool = true):
	print("CardView.highlight: 设置高亮状态为: " + str(enable))
	
	if highlight_panel:
		highlight_panel.visible = enable
		print("CardView.highlight: 高亮面板可见性设置为: " + str(enable))
	else:
		print("CardView.highlight: 警告 - highlight_panel为空，尝试获取节点")
		highlight_panel = get_node_or_null("Highlight")
		if highlight_panel:
			highlight_panel.visible = enable
			print("CardView.highlight: 成功获取高亮面板并设置可见性为: " + str(enable))
		else:
			# 使用背景颜色变化作为高亮效果
			modulate = Color(1.2, 1.2, 0.8) if enable else Color(1, 1, 1)
			print("CardView.highlight: 使用modulate作为高亮效果")
	
	if enable:
		z_index = original_z_index + 10
		print("CardView.highlight: 提高z_index: " + str(z_index))
	else:
		z_index = original_z_index
		print("CardView.highlight: 恢复z_index: " + str(z_index))

# 每帧处理拖动
func _process(_delta):
	if is_being_dragged:
		# 直接更新拖拽位置
		global_position = get_global_mouse_position() - drag_offset
		emit_signal("card_dragged", self)

# 鼠标进入时
func _on_mouse_entered():
	if not is_being_dragged and is_draggable and not is_selected:
		print("CardView '%s': Mouse entered, applying hover effect." % name)
		# 悬停效果 - 只有在卡牌未被选中时才应用悬停效果
		if hover_enabled:
			# 实现简单的悬停效果
			position.y = original_position.y - 20 # 悬停时向上移动
		highlight(true)
	
	emit_signal("card_hovered", self)

# 鼠标离开时
func _on_mouse_exited():
	if not is_being_dragged and is_draggable and not is_selected:
		print("CardView '%s': Mouse exited, removing hover effect." % name)
		# 恢复原始位置 - 只有在卡牌未被选中时才恢复位置
		if hover_enabled:
			# 恢复到原始位置
			position = original_position
		highlight(false)
	
	emit_signal("card_unhovered", self)

# 这里直接添加_input函数作为备用输入机制
func _input(event):
	# 只处理鼠标左键点击事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 检查点击是否发生在卡牌区域内
		var local_pos = get_local_mouse_position()
		var rect = Rect2(Vector2(0, 0), size)
		
		if rect.has_point(local_pos):
			print("CardView '%s': 在_input中捕获到点击，位置=%s" % [name, str(local_pos)])
			
			# 直接切换选中状态，不依赖信号
			toggle_selected()
			
			# 防止事件继续传播
			get_viewport().set_input_as_handled()

# GUI输入处理的备用方案，替换原来的_gui_input
func _handle_gui_input(event):
	if event is InputEventMouseButton:
		print("CardView '%s': _gui_input收到鼠标事件，按钮=%d，按下=%s" % [name, event.button_index, str(event.pressed)])
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("CardView '%s': _gui_input处理左键点击" % name)
			# 添加额外调试信息，确保信号已发送
			var connections = get_signal_connection_list("card_clicked")
			print("CardView '%s': card_clicked信号的连接数量: %d" % [name, connections.size()])
			for conn in connections:
				print("CardView '%s': 连接到 %s.%s" % [name, conn.target.name if conn.target.has_method("get_name") else "UnknownTarget", conn.method])
			
			emit_signal("card_clicked", self)
			print("CardView '%s': card_clicked信号已发送" % name)
			get_viewport().set_input_as_handled()
			
			# 作为备用，直接调用toggle_selected
			if not connections.size():
				print("CardView '%s': 未找到card_clicked信号的连接，直接调用toggle_selected" % name)
				toggle_selected()

# 获取卡牌数据
func get_card_data() -> CardData:
	return card_data

# 获取卡牌名称
func get_card_name() -> String:
	if card_data and card_data.has("name"):
		return card_data.name
	return "未知卡牌"

# 设置是否可拖动
func set_draggable(draggable: bool):
	is_draggable = draggable

# 设置原始位置（仅用于初始定位，不会在选中逻辑中使用）
func set_original_position(pos: Vector2):
	original_position = pos
	position = pos
	print("CardView '%s': 设置初始位置为 (%s, %s)" % [name, pos.x, pos.y])

# 禁用鼠标悬停移动效果
func disable_hover_movement():
	hover_enabled = false
	
# 启用鼠标悬停移动效果
func enable_hover_movement():
	hover_enabled = true

# --- 选择逻辑重构 ---

# 实现 ISelectable 接口
func toggle_selected() -> bool:
	set_selected(!is_selected)
	return is_selected

# 设置卡牌选中状态
func set_selected(value):
	if is_selected == value:
		return
		
	is_selected = value
	
	# 当选中状态改变时，只改变垂直位置，保持水平位置不变
	var current_x = position.x
	
	if is_selected:
		# 向上移动卡牌以表示选中，但保持水平位置不变
		position = Vector2(current_x, -30) # 固定的选中位置
		print("CardView '%s': 选中状态，位置: (%s, %s)" % [name, position.x, position.y])
		highlight(true)
	else:
		# 恢复原始垂直位置，但保持水平位置不变
		position = Vector2(current_x, 0) # 固定的未选中位置
		print("CardView '%s': 未选中状态，位置: (%s, %s)" % [name, position.x, position.y])
		highlight(false)
	
	emit_signal("selection_changed", self, is_selected)

# 获取选中状态
func get_selected_state() -> bool:
	return is_selected

# 确保已缓存原始位置
func _ensure_original_position():
	if not _original_position_set:
		original_position = position
		_original_position_set = true

# Godot 会优先调用 _gui_input，所以这里直接转发到 _handle_gui_input 方便统一处理
func _gui_input(event):
	_handle_gui_input(event)
