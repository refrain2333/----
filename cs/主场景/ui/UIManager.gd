class_name UIManager
extends CanvasLayer

# 信号
signal hud_ready(hud_node)
signal settings_opened
signal settings_closed

# 导出UI场景变量
@export var sidebar_scene: PackedScene
@export var hud_scene: PackedScene
@export var hand_dock_scene: PackedScene
@export var deck_widget_scene: PackedScene
@export var top_dock_scene: PackedScene

# 引用主场景
var main_game

# UI组件引用
var sidebar
var hud
var hand_dock
var deck_widget
var top_dock

# 状态文本显示计时器
var status_timer: Timer

# 设置菜单是否打开
var settings_open = false

func _init(game_scene):
	main_game = game_scene

func _ready():
	# 创建状态显示计时器
	status_timer = Timer.new()
	status_timer.one_shot = true
	status_timer.wait_time = 3.0
	status_timer.timeout.connect(_on_status_timer_timeout)
	add_child(status_timer)
	
	# 实例化所有UI组件
	_instantiate_ui_components()
	
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("ui_manager", self)

# 使用已存在的UI组件
func use_existing_ui_components(sidebar_node, hud_node, hand_dock_node, deck_widget_node, top_dock_node):
	sidebar = sidebar_node
	hud = hud_node
	hand_dock = hand_dock_node
	deck_widget = deck_widget_node
	top_dock = top_dock_node
	
	# 连接信号
	if sidebar and sidebar.has_method("connect_signals"):
		sidebar.settings_button_pressed.connect(_on_settings_button_pressed)
	
	# 发送HUD准备好的信号
	if hud:
		emit_signal("hud_ready", hud)

# 实例化UI组件
func _instantiate_ui_components():
	# 如果UI组件已经存在，则不需要实例化
	if sidebar and hud and hand_dock and deck_widget and top_dock:
		return
		
	# 实例化左侧信息面板
	if sidebar_scene and not sidebar:
		sidebar = sidebar_scene.instantiate()
		add_child(sidebar)
		sidebar.settings_button_pressed.connect(_on_settings_button_pressed)
	
	# 实例化HUD (资源/结束回合按钮)
	if hud_scene and not hud:
		hud = hud_scene.instantiate()
		add_child(hud)
		emit_signal("hud_ready", hud)
	
	# 实例化手牌区域
	if hand_dock_scene and not hand_dock:
		hand_dock = hand_dock_scene.instantiate()
		add_child(hand_dock)
	
	# 实例化牌库堆叠
	if deck_widget_scene and not deck_widget:
		deck_widget = deck_widget_scene.instantiate()
		add_child(deck_widget)
	
	# 实例化顶部区域(法器槽+发现槽)
	if top_dock_scene and not top_dock:
		top_dock = top_dock_scene.instantiate()
		add_child(top_dock)

# 更新所有UI
func update_ui():
	# 更新各个UI组件
	if sidebar and sidebar.has_method("update_ui"):
		sidebar.update_ui()
	
	if hud and hud.has_method("update_ui"):
		hud.update_ui()
	
	if hand_dock and hand_dock.has_method("update_ui"):
		hand_dock.update_ui()
	
	if deck_widget and deck_widget.has_method("update_ui"):
		deck_widget.update_ui()
	
	if top_dock and top_dock.has_method("update_ui"):
		top_dock.update_ui()

# 更新牌库信息
func update_deck_info(remaining: int, total: int):
	if deck_widget and deck_widget.has_method("update_deck_info"):
		deck_widget.update_deck_info(remaining, total)

# 设置状态文本
func set_status(text: String, duration: float = 3.0):
	if hud and hud.has_method("set_status_text"):
		hud.set_status_text(text)
		status_timer.wait_time = duration
		status_timer.start()

# 清除状态文本
func _on_status_timer_timeout():
	if hud and hud.has_method("set_status_text"):
		hud.set_status_text("")

# 处理设置按钮点击
func _on_settings_button_pressed():
	if settings_open:
		close_settings()
	else:
		open_settings()

# 打开设置菜单
func open_settings():
	set_status("设置菜单即将开放...")
	settings_open = true
	emit_signal("settings_opened")

# 关闭设置菜单
func close_settings():
	settings_open = false
	emit_signal("settings_closed")

# 添加卡牌到手牌
func add_card_to_hand(card_data):
	if hand_dock and hand_dock.has_method("add_card"):
		return hand_dock.add_card(card_data)
	return null

# 从手牌移除卡牌
func remove_card_from_hand(card_instance):
	if hand_dock and hand_dock.has_method("remove_card"):
		hand_dock.remove_card(card_instance)

# 获取手牌容器
func get_hand_container():
	if hand_dock and hand_dock.has_method("get_card_container"):
		return hand_dock.get_card_container()
	return null

# 获取法器容器
func get_artifact_container():
	if top_dock and top_dock.has_method("get_artifact_container"):
		return top_dock.get_artifact_container()
	return null

# 获取发现容器
func get_discovery_container():
	if top_dock and top_dock.has_method("get_discovery_container"):
		return top_dock.get_discovery_container()
	return null

# 获取牌库纹理
func get_rune_back_texture():
	if deck_widget and deck_widget.has_method("get_rune_back_texture"):
		return deck_widget.get_rune_back_texture()
	return null

# 更新资源显示
func update_resources(mana: int, focus: int, essence: int, lore: int):
	if sidebar:
		sidebar.set_mana(mana)
		sidebar.set_focus(focus)
		sidebar.set_essence(essence)
		sidebar.set_lore(lore)

# 更新分数显示
func update_score(score: int, multiplier: int = 1):
	if sidebar:
		sidebar.set_score(score)
		sidebar.set_multiplier(multiplier)

# 更新进度显示
func update_progress(year: int, term: int, term_total: int = 4):
	if sidebar:
		sidebar.set_year(year)
		sidebar.set_term(term, term_total)

# 更新目标和奖励
func update_target(target_score: int, reward: int):
	if sidebar:
		sidebar.set_target(target_score)
		sidebar.set_reward(reward)

# 显示发现区域
func show_discovery_area(prompt_text: String = "选择一张卡牌添加到你的手牌"):
	if top_dock:
		top_dock.show_discovery()
		var prompt_label = top_dock.discovery_area.get_node("PromptLabel")
		if prompt_label:
			prompt_label.text = prompt_text

# 隐藏发现区域
func hide_discovery_area():
	if top_dock:
		top_dock.hide_discovery() 
