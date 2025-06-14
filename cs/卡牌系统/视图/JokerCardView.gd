class_name JokerCardView
extends Control

# 小丑卡数据
var joker_data: JokerData = null  # 引用 cs/卡牌系统/数据/JokerData.gd
var is_draggable: bool = true
var original_position: Vector2
var original_parent = null
var original_z_index: int = 0
var hover_offset: Vector2 = Vector2(0, -20)  # 鼠标悬停时向上偏移量
var hover_enabled: bool = true  # 是否启用悬停效果
var is_selected: bool = false  # 小丑卡是否被选中

# 视觉组件引用
@onready var joker_texture: TextureRect = $JokerTexture
@onready var joker_name_label: Label = $InfoPanel/NameLabel
@onready var joker_effect_label: Label = $InfoPanel/EffectLabel
@onready var joker_type_label: Label = $InfoPanel/TypeLabel
@onready var highlight_sprite: Sprite2D = $Highlight
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 拖放相关
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# 信号
signal joker_clicked(joker_view)
signal joker_dragged(joker_view)
signal joker_dropped(joker_view, drop_position)
signal joker_hovered(joker_view)
signal joker_unhovered(joker_view)

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

# 设置小丑卡数据并更新视图
func setup(data):
	joker_data = data
	update_view()

# 更新小丑卡视图
func update_view():
	if not joker_data:
		return
	
	# 加载小丑卡贴图
	var texture_path = "res://assets/images/jokers/" + joker_data.image_name + ".png"
	var texture = load(texture_path)
	if texture:
		joker_texture.texture = texture
	
	# 更新小丑卡信息标签
	joker_name_label.text = joker_data.name
	joker_effect_label.text = joker_data.effect_description
	joker_type_label.text = get_joker_type_display(joker_data.type)
	
	# 根据小丑类型设置颜色
	var type_color = get_joker_type_color(joker_data.type)
	joker_type_label.set("theme_override_colors/font_color", type_color)

# 获取小丑卡类型显示名称
func get_joker_type_display(type: String) -> String:
	match type:
		"common": return "普通"
		"rare": return "稀有"
		"legendary": return "传奇"
		"negative": return "负面"
		"special": return "特殊"
		_: return "未知"

# 获取小丑卡类型颜色
func get_joker_type_color(type: String) -> Color:
	match type:
		"common": return Color(0.7, 0.7, 0.7)  # 灰色
		"rare": return Color(0.3, 0.5, 1.0)    # 蓝色
		"legendary": return Color(1.0, 0.5, 0.0)  # 橙色
		"negative": return Color(0.7, 0.0, 0.0)   # 红色
		"special": return Color(0.7, 0.0, 1.0)    # 紫色
		_: return Color(1.0, 1.0, 1.0)  # 白色

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
			emit_signal("joker_clicked", self)
			
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
				
				# 提高Z顺序使卡牌显示在最上层
				z_index = 100
				
				# emit_signal("joker_clicked", self) # 已在上面调用
			else:
				# 停止拖动
				is_being_dragged = false
				
				# 发送小丑卡放下信号
				emit_signal("joker_dropped", self, get_global_mouse_position())
				
				# 恢复原始Z顺序
				z_index = original_z_index

# 每帧处理拖动
func _process(_delta):
	if is_being_dragged:
		# 更新位置跟随鼠标
		global_position = get_global_mouse_position() - drag_offset
		emit_signal("joker_dragged", self)

# 鼠标进入时
func _on_mouse_entered():
	if not is_being_dragged and is_draggable:
		# 悬停效果
		if hover_enabled:
			var tween = create_tween()
			tween.tween_property(self, "position", original_position + hover_offset, 0.1)
		highlight(true)
	
	emit_signal("joker_hovered", self)

# 鼠标离开时
func _on_mouse_exited():
	if not is_being_dragged and is_draggable:
		# 恢复原始位置
		if hover_enabled and not is_selected: # 只有在未选中状态才恢复位置
			var tween = create_tween()
			tween.tween_property(self, "position", original_position, 0.1)
		highlight(false)
	
	emit_signal("joker_unhovered", self)

# 获取小丑卡数据
func get_joker_data():
	return joker_data

# 获取小丑卡名称
func get_joker_name() -> String:
	if joker_data:
		return joker_data.name
	return "未知小丑牌"

# 设置是否可拖动
func set_draggable(draggable: bool):
	is_draggable = draggable

# 设置原始位置
func set_original_position(pos: Vector2):
	original_position = pos
	position = pos

# 播放动画
func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

# 应用小丑卡效果
func apply_effect():
	if joker_data and joker_data.has_method("apply_effect"):
		joker_data.apply_effect()
		# 可以添加视觉效果
		play_animation("apply_effect")

# 禁用鼠标悬停移动效果
func disable_hover_movement():
	hover_enabled = false
	
# 启用鼠标悬停移动效果
func enable_hover_movement():
	hover_enabled = true

# 设置小丑卡选中状态
func set_selected(selected: bool):
	is_selected = selected
	highlight(is_selected)
	
	if is_selected:
		position.y = original_position.y - 20  # 向上移动20像素
	else:
		position.y = original_position.y  # 恢复原始位置 
