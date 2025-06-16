class_name InputRouter
extends Node

# 信号
signal key_pressed(key_event)     # 键盘按键
signal mouse_drag(drag_event)     # 鼠标拖拽
signal mouse_click(click_event)   # 鼠标点击
signal ui_action(action_name, action_data)  # UI动作

# 引用
var main_game  # 引用主场景
var input_enabled: bool = true  # 是否处理输入

# 初始化
func _init(game_scene):
	main_game = game_scene
	
	# 设置处理输入
	set_process_unhandled_input(true)

# 处理未处理的输入事件
func _unhandled_input(event):
	if not input_enabled:
		return
		
	# 处理键盘输入
	if event is InputEventKey and event.pressed:
		handle_key_input(event)
	
	# 处理鼠标输入
	elif event is InputEventMouseButton:
		handle_mouse_input(event)
	
	# 处理鼠标移动
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		handle_mouse_drag(event)

# 处理键盘输入
func handle_key_input(event: InputEventKey):
	# 发出信号
	emit_signal("key_pressed", event)
	
	# 处理常用快捷键
	match event.keycode:
		KEY_ESCAPE:
			emit_signal("ui_action", "toggle_menu", {})
		KEY_SPACE:
			emit_signal("ui_action", "end_turn", {})
		KEY_E:
			emit_signal("ui_action", "use_essence", {})
		KEY_D:
			emit_signal("ui_action", "draw_card", {})
		KEY_S:
			if event.ctrl_pressed:
				emit_signal("ui_action", "sort_by_suit", {})
			else:
				emit_signal("ui_action", "sort_by_value", {})
		KEY_F:
			emit_signal("ui_action", "focus_card", {"index": 0})
		KEY_H:
			emit_signal("ui_action", "show_help", {})
		KEY_R:
			if event.ctrl_pressed:
				emit_signal("ui_action", "restart_game", {})

# 处理鼠标输入
func handle_mouse_input(event: InputEventMouseButton):
	# 发出信号
	emit_signal("mouse_click", event)
	print("InputRouter: 鼠标事件 button=%s pressed=%s pos=%s" % [event.button_index, event.pressed, event.global_position])
	
	# 处理鼠标左键点击
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 检查是否点击了关键区域
		_check_area_clicks(event.global_position)
		return  # 调试：直接返回，避免后续处理
	
	# 处理鼠标右键点击
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("ui_action", "inspect_card", {"position": event.global_position})
	
	# 处理鼠标滚轮
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		emit_signal("ui_action", "scroll_up", {"position": event.global_position})
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		emit_signal("ui_action", "scroll_down", {"position": event.global_position})

# 处理鼠标拖动
func handle_mouse_drag(event: InputEventMouseMotion):
	# 发出信号
	emit_signal("mouse_drag", event)

# 禁用输入处理（例如在弹出菜单时）
func disable_input():
	input_enabled = false

# 启用输入处理
func enable_input():
	input_enabled = true

# 连接UI事件
func connect_ui_events():
	# 查找并连接主场景中的按钮
	_connect_button_events()

# 检查区域点击
func _check_area_clicks(global_position: Vector2):
	# 检查符文库区域
	var rune_library = _find_node("RuneBackTexture")
	if rune_library and rune_library.get_global_rect().has_point(global_position):
		emit_signal("ui_action", "draw_card", {})
		return
	
	# 传奇法器区域
	var artifact_container = _find_node("ArtifactContainer")
	if artifact_container and artifact_container.get_global_rect().has_point(global_position):
		emit_signal("ui_action", "select_artifact", {"position": global_position})
		return
	
	# 发现区域
	var discovery_container = _find_node("DiscoveryContainer")
	if discovery_container and discovery_container.get_global_rect().has_point(global_position):
		emit_signal("ui_action", "select_discovery", {"position": global_position})
		return

# 连接按钮事件
func _connect_button_events():
	# 结束回合按钮
	_connect_button("EndTurnButton", "end_turn")
	
	# 弃牌按钮
	_connect_button("DiscardButton", "use_essence")
	
	# 排序按钮
	_connect_button("SortValueButton", "sort_by_value")
	_connect_button("SortSuitButton", "sort_by_suit")
	
	# 设置按钮
	_connect_button("SettingsButton", "toggle_menu")
	
	# 帮助按钮
	_connect_button("HelpButton", "show_help")

# 连接按钮
func _connect_button(button_name: String, action_name: String):
	var button = _find_node(button_name)
	if button and button is Button:
		if not button.pressed.is_connected(func(): emit_signal("ui_action", action_name, {})):
			button.pressed.connect(func(): emit_signal("ui_action", action_name, {}))

# 辅助方法：查找节点
func _find_node(node_name: String) -> Node:
	return main_game.find_child(node_name, true)

# 手动处理输入事件（从外部调用）
func handle_input_event(event):
	if input_enabled:
		_unhandled_input(event) 