class_name JokerView
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
	setup_input_handling()
	
	# 保存原始位置
	original_position = position
	original_z_index = z_index

# 设置输入处理
func setup_input_handling():
	set_process_input(true)
	
	# 连接信号
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

# 设置小丑卡数据并更新视图
func setup(data):
	joker_data = data
	update_view()

# 更新小丑卡视图
func update_view():
	if not joker_data:
		return
	
	# 加载小丑卡贴图
	_update_texture()
	
	# 更新小丑卡信息标签
	if joker_name_label:
		joker_name_label.text = joker_data.item_name
	
	if joker_effect_label:
		joker_effect_label.text = joker_data.get_description()
	
	if joker_type_label:
		joker_type_label.text = _get_timing_display(joker_data.trigger_event_timing)

# 获取触发时机对应的显示文本
func _get_timing_display(timing: int) -> String:
	match timing:
		GlobalEnums.EffectTriggerTiming.ON_TURN_START:
			return "回合开始"
		GlobalEnums.EffectTriggerTiming.BEFORE_PLAY:
			return "出牌时"
		GlobalEnums.EffectTriggerTiming.ON_SCORE_CALCULATION:
			return "计分时"
		GlobalEnums.EffectTriggerTiming.ON_DRAW:
			return "抽牌时"
		GlobalEnums.EffectTriggerTiming.ON_DISCARD:
			return "弃牌时"
		_:
			return "特殊"

# 更新贴图
func _update_texture():
	if not joker_texture:
		return
		
	var texture_path = ""
	
	# 尝试根据ID加载贴图
	if joker_data:
		texture_path = "res://assets/images/jokers/" + joker_data.item_id.to_lower() + ".png"
		
	# 默认路径
	if not ResourceLoader.exists(texture_path):
		texture_path = "res://assets/images/jokers/common_joker.png"
	
	# 加载贴图
	if ResourceLoader.exists(texture_path):
		joker_texture.texture = load(texture_path)

# 高亮显示
func highlight(enable: bool = true):
	highlight_sprite.visible = enable
	if enable:
		z_index = original_z_index + 10
	else:
		z_index = original_z_index

# 处理GUI输入
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 发送点击信号
			emit_signal("joker_clicked", self)
			
			# 开始拖动
			if is_draggable:
				start_drag(event)
		else:
			# 停止拖动
			stop_drag()

# 开始拖动
func start_drag(event):
	is_being_dragged = true
	drag_offset = get_global_mouse_position() - global_position
	original_position = global_position
	z_index = 100

# 停止拖动
func stop_drag():
	if is_being_dragged:
		is_being_dragged = false
		emit_signal("joker_dropped", self, get_global_mouse_position())
		z_index = original_z_index

# 每帧处理拖动
func _process(_delta):
	if is_being_dragged:
		global_position = get_global_mouse_position() - drag_offset
		emit_signal("joker_dragged", self)

# 鼠标进入时
func _on_mouse_entered():
	if not is_being_dragged and is_draggable and not is_selected:
		# 悬停效果
		if hover_enabled:
			position.y = original_position.y - 20 # 向上偏移
		highlight(true)
	
	emit_signal("joker_hovered", self)

# 鼠标离开时
func _on_mouse_exited():
	if not is_being_dragged and is_draggable and not is_selected:
		# 恢复原始位置
		if hover_enabled:
			position.y = original_position.y
		highlight(false)
	
	emit_signal("joker_unhovered", self)

# 获取小丑卡数据
func get_joker_data():
	return joker_data

# 获取小丑卡名称
func get_joker_name() -> String:
	if joker_data:
		return joker_data.item_name
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

# 设置悬停效果
func set_hover_enabled(enabled: bool):
	hover_enabled = enabled
