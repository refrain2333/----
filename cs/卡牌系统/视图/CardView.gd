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
var _is_selected: bool = false  # 卡牌是否被选中，改为私有变量避免与函数重名

# 视觉组件引用
@onready var front_texture: TextureRect = $CardFront
@onready var back_texture: TextureRect = $CardBack
@onready var card_name_label: Label = $CardFront/NameLabel
@onready var card_element_label: Label = $CardFront/ElementLabel
@onready var card_power_label: Label = $CardFront/PowerLabel
@onready var highlight_sprite: Sprite2D = $Highlight
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

func _ready():
	# 初始化
	highlight_sprite.visible = false
	set_process_input(true)
	
	# 连接信号
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 保存原始位置
	original_position = position
	original_z_index = z_index

# 设置卡牌数据并更新视图
func setup(new_card_data: CardData):
	card_data = new_card_data
	update_view()

# 更新卡牌视图
func update_view():
	if not card_data:
		return
	
	# 加载卡牌贴图
	var texture = null
	if card_data.texture_path and ResourceLoader.exists(card_data.texture_path):
		texture = load(card_data.texture_path)
	
	# 如果贴图为空，使用预设占位图
	if not texture:
		texture = load("res://assets/debug/rune.png")
	
	if texture:
		front_texture.texture = texture
	
	# 更新卡牌信息标签
	card_name_label.text = card_data.display_name
	card_element_label.text = _get_element_display_name(card_data.element)
	card_power_label.text = str(card_data.power)
	
	# 根据元素设置颜色
	var element_color = _get_element_color(card_data.element)
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
	highlight_sprite.visible = enable
	if enable:
		z_index = original_z_index + 10
	else:
		z_index = original_z_index

# 处理输入事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 发送点击信号
			emit_signal("card_clicked", self)
			
			# 不再在这里处理拖拽，而是在MainGame中通过点击信号处理选中逻辑
			return
	
	# 以下代码用于未来实现拖拽功能，现在启用以解决未使用信号的警告
	if not is_draggable:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖动
				is_being_dragged = true
				drag_offset = get_global_mouse_position() - global_position
				original_position = global_position
				original_parent = get_parent()
				
				# 使用 DragHelper 处理拖拽开始
				DragHelper.begin_drag_control(self)
			else:
				# 停止拖动
				is_being_dragged = false
				
				# 发送卡牌放下信号
				emit_signal("card_dropped", self, get_global_mouse_position())
				
				# 使用 DragHelper 处理拖拽结束
				DragHelper.end_drag(self)

# 每帧处理拖动
func _process(_delta):
	if is_being_dragged:
		# 使用 DragHelper 更新拖拽位置
		DragHelper.update_drag_position(self, get_global_mouse_position(), drag_offset)
		emit_signal("card_dragged", self)

# 鼠标进入时
func _on_mouse_entered():
	if not is_being_dragged and is_draggable:
		# 悬停效果
		if hover_enabled:
			DragHelper.hover_control(self, true)
		highlight(true)
	
	emit_signal("card_hovered", self)

# 鼠标离开时
func _on_mouse_exited():
	if not is_being_dragged and is_draggable:
		# 恢复原始位置
		if hover_enabled:
			DragHelper.hover_control(self, false)
		highlight(false)
	
	emit_signal("card_unhovered", self)

# 获取卡牌数据
func get_card_data() -> CardData:
	return card_data

# 获取卡牌名称
func get_card_name() -> String:
	if card_data:
		return card_data.display_name
	return "未知卡牌"

# 设置是否可拖动
func set_draggable(draggable: bool):
	is_draggable = draggable

# 设置原始位置
func set_original_position(pos: Vector2):
	original_position = pos
	position = pos 

# 禁用鼠标悬停移动效果
func disable_hover_movement():
	hover_enabled = false
	
# 启用鼠标悬停移动效果
func enable_hover_movement():
	hover_enabled = true

# 实现 ISelectable 接口
func toggle_selected() -> bool:
	_is_selected = !_is_selected
	set_selected(_is_selected)
	return _is_selected

# 设置卡牌选中状态
func set_selected(flag: bool) -> void:
	_is_selected = flag
	highlight(_is_selected)
	
	if _is_selected:
		position.y = original_position.y - 20  # 向上移动20像素
	else:
		position.y = original_position.y  # 恢复原始位置

# 获取选中状态
func is_selected() -> bool:
	return _is_selected
 
