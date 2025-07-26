class_name CardView
extends Control
# 实现 ISelectable 接口

# 导入GlobalEnums和ResourcePaths
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")
const ResourcePaths = preload("res://cs/卡牌系统/视图/ResourcePaths.gd")

# 卡牌数据
var card_data: CardData = null
var is_flipped: bool = false
var is_draggable: bool = true
var original_position: Vector2
var original_z_index: int = 0
var hover_offset: Vector2 = Vector2(0, -20)
var hover_enabled: bool = true
var is_selected: bool = false
var original_size: Vector2

# 视觉组件引用
@onready var front_texture: TextureRect = $CardFront
@onready var back_texture: TextureRect = $CardBack
@onready var card_power_label: Label = $CardFront/PowerLabel
@onready var highlight_panel: Panel = $Highlight

# 强化效果组件引用
@onready var frame_node: Node2D = $ReinforcementEffects/Frame
@onready var wax_seals_container: Node2D = $ReinforcementEffects/WaxSeals
@onready var material_effect: ColorRect = $ReinforcementEffects/Material
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 拖放相关
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# 悬停预览相关
var hover_timer: Timer = null
var info_preview: CardInfoPreview = null
var hover_delay: float = 0.4  # 悬停延时（秒）- 修改为0.4秒以提供更快的响应
var is_hovering: bool = false
var preview_enabled: bool = true

# 信号
signal card_clicked(card_view)
signal card_dragged(card_view)
signal card_dropped(card_view, drop_position)
signal card_hovered(card_view)
signal card_unhovered(card_view)
signal selection_changed(card_view, is_selected)
signal card_drag_started(card_view)

func _ready():
	custom_minimum_size = Vector2(120, 180)
	await get_tree().process_frame
	original_position = position
	original_size = size
	original_z_index = z_index
	highlight(false)

	# 初始化悬停预览系统
	_setup_hover_preview()

	# 设置输入处理
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 确保所有子节点的鼠标过滤器设置正确
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 确保信号连接安全，不重复连接
	if gui_input.is_connected(Callable(self, "_handle_gui_input")):
		gui_input.disconnect(Callable(self, "_handle_gui_input"))
	gui_input.connect(Callable(self, "_handle_gui_input"))

	if mouse_entered.is_connected(Callable(self, "_on_mouse_entered")):
		mouse_entered.disconnect(Callable(self, "_on_mouse_entered"))
	mouse_entered.connect(Callable(self, "_on_mouse_entered"))

	if mouse_exited.is_connected(Callable(self, "_on_mouse_exited")):
		mouse_exited.disconnect(Callable(self, "_on_mouse_exited"))
	mouse_exited.connect(Callable(self, "_on_mouse_exited"))

# 设置卡牌数据并更新视图
func setup(new_card_data: CardData):
	card_data = new_card_data
	update_view()

# 更新卡牌视图
func update_view():
	if not card_data or not is_inside_tree() or not is_node_ready():
		call_deferred("update_view")
		return
	
	# 加载卡牌贴图
	var texture = null
	
	# 尝试从card_data中的image_path加载贴图
	if card_data.image_path and ResourceLoader.exists(card_data.image_path):
		texture = load(card_data.image_path)
	
	# 如果未能加载指定贴图，使用通过ResourcePaths生成路径
	if not texture:
		var generated_path = ResourcePaths.get_card_image_path(card_data.id)
		if ResourceLoader.exists(generated_path):
			texture = load(generated_path)
	
	# 如果仍未能加载，使用默认贴图
	if not texture:
		var default_path = "res://assets/images/pokers/1.jpg"
		if ResourceLoader.exists(default_path):
			texture = load(default_path)
	
	# 设置贴图和卡牌信息
	if texture and front_texture:
		front_texture.texture = texture

	if card_power_label:
		card_power_label.text = card_data.get_value_display_name()
	
	# 更新强化效果
	_update_reinforcement_visuals()

# 更新强化效果视觉展示
func _update_reinforcement_visuals():
	if not card_data or not is_inside_tree() or not is_node_ready():
		call_deferred("_update_reinforcement_visuals")
		return
	
	# 更新牌框
	if frame_node:
		frame_node.visible = false
		if card_data.has_frame_reinforcement():
			var frame_path = ResourcePaths.get_frame_path(card_data.frame_type)
			if ResourceLoader.exists(frame_path):
				frame_node.texture = load(frame_path)
				frame_node.visible = true
	
	# 更新蜡封
	if wax_seals_container:
		# 清除现有的蜡封
		for child in wax_seals_container.get_children():
			child.queue_free()
		
		# 添加新的蜡封
		if card_data.has_any_wax_seal():
			var seal_count = card_data.get_wax_seal_count()
			var angle_step = 2 * PI / seal_count
			var radius = 40
			
			for i in range(seal_count):
				var seal_type = card_data.wax_seals[i]
				var texture_path = ResourcePaths.get_wax_seal_path(seal_type)
				if ResourceLoader.exists(texture_path):
					var seal_sprite = Sprite2D.new()
					seal_sprite.texture = load(texture_path)
					seal_sprite.scale = Vector2(0.4, 0.4)
					
					# 计算蜡封位置
					var angle = i * angle_step
					seal_sprite.position = Vector2(radius * cos(angle), radius * sin(angle))
					wax_seals_container.add_child(seal_sprite)
	
	# 更新材质
	if material_effect:
		material_effect.visible = false
		if card_data.has_material_reinforcement():
			var shader_path = ResourcePaths.get_material_shader_path(card_data.material_type)
			if ResourceLoader.exists(shader_path):
				var shader_material = ShaderMaterial.new()
				shader_material.shader = load(shader_path)
				material_effect.material = shader_material
				material_effect.visible = true

# 翻转卡牌
func flip(flip_to_back: bool = false):
	is_flipped = flip_to_back
	front_texture.visible = !is_flipped
	back_texture.visible = is_flipped
	if animation_player:
		animation_player.play("flip")

# 高亮显示
func highlight(enable: bool = true):
	if highlight_panel:
		highlight_panel.visible = enable
	
	z_index = original_z_index + (10 if enable else 0)

# 处理拖动
func _process(_delta):
	if is_being_dragged:
		global_position = get_global_mouse_position() - drag_offset
		emit_signal("card_dragged", self)

# 鼠标进入时
func _on_mouse_entered():
	is_hovering = true

	# 只有在未被选中且未被拖动时才应用悬停效果
	if not is_being_dragged and is_draggable and not is_selected:
		if hover_enabled:
			# 使用动画进行平滑悬停效果
			var tween = create_tween()
			tween.tween_property(self, "position", Vector2(position.x, original_position.y + hover_offset.y), 0.1)
		highlight(true)

	# 启动悬停计时器
	_start_hover_timer()

	emit_signal("card_hovered", self)

# 鼠标离开时
func _on_mouse_exited():
	is_hovering = false

	# 只有在未被选中且未被拖动时才恢复悬停效果
	if not is_being_dragged and is_draggable and not is_selected:
		if hover_enabled:
			# 使用动画平滑恢复位置
			var tween = create_tween()
			tween.tween_property(self, "position", original_position, 0.1)
		highlight(false)

	# 停止悬停计时器并隐藏预览
	_stop_hover_timer()
	_hide_info_preview()

	emit_signal("card_unhovered", self)

# 统一的GUI输入处理
func _handle_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("CardView._handle_gui_input: 卡牌被点击 %s，当前选择状态: %s" % [get_card_name(), is_selected])
		emit_signal("card_clicked", self)
		# 注意：不在这里调用toggle_selected()，让HandDock通过TurnManager来管理选择状态
		get_viewport().set_input_as_handled()

# 获取卡牌值
func get_card_power() -> int:
	return card_data.base_value if card_data else 0

# 获取卡牌数据
func get_card_data() -> CardData:
	return card_data

# 获取卡牌名称
func get_card_name() -> String:
	return card_data.name if card_data else "未知卡牌"

# 设置是否可拖动
func set_draggable(draggable: bool):
	is_draggable = draggable

# 设置原始位置
func set_original_position(pos: Vector2):
	original_position = pos
	position = pos

# 设置鼠标悬停效果
func set_hover_enabled(enabled: bool):
	hover_enabled = enabled

# 选择逻辑
func toggle_selected() -> bool:
	set_selected(!is_selected)
	return is_selected

# 设置卡牌选中状态
func set_selected(value):
	if is_selected == value:
		return

	is_selected = value

	# 使用动画进行平滑过渡
	_animate_selection_state()

	emit_signal("selection_changed", self, is_selected)

# 动画化选择状态变化
func _animate_selection_state():
	# 保持水平位置不变
	var current_x = position.x

	# 创建选择状态动画
	var tween = create_tween()
	tween.set_parallel(true)

	if is_selected:
		# 选中状态：向上移动，增加z_index，显示高亮
		tween.tween_property(self, "position", Vector2(current_x, original_position.y - 35), 0.2)
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)
		z_index = original_z_index + 10

		# 高亮效果
		if highlight_panel:
			highlight_panel.visible = true
			highlight_panel.modulate = Color(1, 1, 0, 0.0)
			tween.tween_property(highlight_panel, "modulate", Color(1, 1, 0, 0.4), 0.2)
	else:
		# 取消选中：恢复原位置和大小
		tween.tween_property(self, "position", Vector2(current_x, original_position.y), 0.2)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
		z_index = original_z_index

		# 移除高亮效果
		if highlight_panel:
			tween.tween_property(highlight_panel, "modulate", Color(1, 1, 0, 0.0), 0.2)
			tween.tween_callback(func(): highlight_panel.visible = false).set_delay(0.2)

# 获取选中状态
func get_selected_state() -> bool:
	return is_selected

# ==================== 悬停预览功能 ====================

# 初始化悬停预览系统
func _setup_hover_preview():
	# 创建悬停计时器
	hover_timer = Timer.new()
	hover_timer.wait_time = hover_delay
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timeout)
	add_child(hover_timer)

	# 创建信息预览面板
	var preview_scene = preload("res://cs/卡牌系统/视图/CardInfoPreview.tscn")
	info_preview = preview_scene.instantiate()

	# 将预览面板添加到场景树的顶层，确保不被其他UI遮挡
	# 延迟添加，确保场景树已准备好
	call_deferred("_add_preview_to_scene")

# 将预览面板添加到场景树
func _add_preview_to_scene():
	if not info_preview:
		return

	# 查找最合适的父节点来添加预览面板
	var target_parent = _find_best_preview_parent()
	if target_parent:
		target_parent.add_child(info_preview)
		# 设置高层级，确保显示在最前面
		info_preview.z_index = 1000

# 查找最合适的预览面板父节点
func _find_best_preview_parent():
	# 首先检查是否在Window中（如对话框）
	var current_node = self
	while current_node != null:
		if current_node is Window:
			# 如果在Window中，将预览面板添加到Window中
			return current_node
		current_node = current_node.get_parent()

	# 如果不在Window中，添加到主场景
	return get_tree().current_scene

# 启动悬停计时器
func _start_hover_timer():
	if not preview_enabled or not hover_timer or not card_data:
		return

	# 如果已经在显示预览，不需要重新启动计时器
	if info_preview and info_preview.visible:
		return

	hover_timer.start()

# 停止悬停计时器
func _stop_hover_timer():
	if hover_timer:
		hover_timer.stop()

# 悬停超时回调
func _on_hover_timeout():
	if is_hovering and preview_enabled and card_data:
		_show_info_preview()

# 显示信息预览
func _show_info_preview():
	if not info_preview or not card_data:
		return

	# 确保预览面板已经添加到场景树中
	if not info_preview.is_inside_tree():
		_add_preview_to_scene()
		# 等待一帧确保添加完成
		await get_tree().process_frame

	# 设置卡牌数据
	info_preview.setup_card_info(card_data)

	# 计算预览面板位置
	var card_pos: Vector2
	var card_size_actual: Vector2

	# 获取卡牌的实际显示边界
	var card_rect = get_global_rect()
	card_size_actual = card_rect.size

	# 直接使用卡牌的全局坐标，不进行任何转换
	card_pos = card_rect.position

	info_preview.set_preview_position(card_pos, card_size_actual)

	# 显示预览面板
	info_preview.show_preview()

# 隐藏信息预览
func _hide_info_preview():
	if info_preview:
		info_preview.hide_preview()

# 设置悬停延时
func set_hover_delay(delay: float):
	hover_delay = delay
	if hover_timer:
		hover_timer.wait_time = delay

# 设置预览功能启用状态
func set_preview_enabled(enabled: bool):
	preview_enabled = enabled
	if not enabled:
		_hide_info_preview()

# 清理资源
func _exit_tree():
	if info_preview and is_instance_valid(info_preview):
		info_preview.queue_free()
