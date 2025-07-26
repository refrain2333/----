extends Node2D

# 预加载类
const CardEffectController = preload("res://cs/卡牌系统/控制/CardEffectManager.gd")
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")
const TurnManagerClass = preload("res://cs/主场景/manager/TurnManager.gd")
const EffectOrchestratorClass = preload("res://cs/主场景/manager/EffectOrchestrator.gd")
const InputManagerClass = preload("res://cs/主场景/manager/InputManager.gd")
const InputRouterClass = preload("res://cs/主场景/manager/InputRouter.gd")
const JokerManagerClass = preload("res://cs/卡牌系统/数据/管理器/JokerManager.gd")
const DiscoveryManagerClass = preload("res://cs/卡牌系统/数据/管理器/DiscoveryManager.gd")
const CardManagerClass = preload("res://cs/卡牌系统/数据/管理器/CardManager.gd")

# 管理器引用
var card_manager
var turn_manager # TurnManager类型
var effect_orchestrator # EffectOrchestrator类型
var input_manager # InputManager类型
var input_router # InputRouter类型
var game_state: int # 使用GlobalEnums.GameState枚举
var discovery_manager # DiscoveryManager类型
var joker_manager # JokerManager类型
var card_effect_manager: CardEffectController  # 卡牌效果管理器引用

# UI组件引用
var hand_dock
var sidebar
var hud
var deck_widget
var top_dock

# 场景引用
@export var sidebar_scene: PackedScene
@export var hud_scene: PackedScene
@export var hand_dock_scene: PackedScene
@export var deck_widget_scene: PackedScene
@export var top_dock_scene: PackedScene

# 添加一个变量来控制打印频率
var max_hand_size: int  # 最大手牌数量

func _ready():
	print("MainGame._ready: 初始化开始")
	
	# 初始化游戏状态
	game_state = GlobalEnums.GameState.MAIN_MENU
	
	# 初始化游戏管理器
	if get_node_or_null("/root/GameManager"):
		print("MainGame._ready: GameManager单例已存在")
	else:
		print("MainGame._ready: 错误 - GameManager单例不存在，请检查project.godot中的自动加载设置")
		# 尝试通过全局访问
		if get_node("/root/GameManager"):
			print("MainGame._ready: 通过根节点找到GameManager")
	
	# 重置游戏资源
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").reset_game_state()
	else:
		print("MainGame._ready: 无法访问GameManager，游戏可能无法正常运行")
	
	# 初始化卡牌效果管理器
	card_effect_manager = CardEffectController.new()
	add_child(card_effect_manager)
	print("MainGame._ready: 卡牌效果管理器已创建")
	
	# 初始化卡牌管理器
	card_manager = CardManagerClass.new(self)
	add_child(card_manager)
	# 确保卡牌管理器使用同一个卡牌效果管理器
	if card_manager and card_effect_manager and card_manager.effect_manager != card_effect_manager:
		print("MainGame._ready: 设置卡牌管理器的效果管理器引用")
		card_manager.effect_manager = card_effect_manager
	print("MainGame._ready: 卡牌管理器已创建")
	
	# 初始化效果协调器
	# 检查Manager节点是否存在
	var manager_node = $UIContainer/Manager
	if not manager_node:
		# 创建Manager节点
		manager_node = Node.new()
		manager_node.name = "Manager"
		$UIContainer.add_child(manager_node)
		print("MainGame._ready: 创建Manager节点")
	
	# 获取或创建效果协调器
	effect_orchestrator = manager_node.get_node_or_null("EffectOrchestrator")
	if not effect_orchestrator:
		effect_orchestrator = EffectOrchestratorClass.new(self)  # 传递self作为game_scene参数
		effect_orchestrator.name = "EffectOrchestrator"
		manager_node.add_child(effect_orchestrator)
		print("MainGame._ready: 效果协调器已创建")
	
	# 设置效果协调器
	effect_orchestrator.setup(card_manager, card_effect_manager, get_node_or_null("/root/GameManager"), get_node_or_null("/root/EventManager"))
	print("MainGame._ready: 效果协调器已设置")
	
	# 加载UI组件
	_load_ui_components()
	
	# 关键修复：允许UI容器穿透鼠标事件，否则所有子节点都无法收到点击
	var ui_container = $UIContainer
	if ui_container:
		print("MainGame._ready: 设置UIContainer鼠标过滤器为PASS")
		ui_container.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		print("MainGame._ready: 错误 - UIContainer不存在")
	
	# 检查和设置HandDock的鼠标过滤器
	if hand_dock:
		print("MainGame._ready: 检查HandDock的鼠标过滤器")
		print("MainGame._ready: HandDock当前鼠标过滤器为 %d" % hand_dock.mouse_filter)
		hand_dock.mouse_filter = Control.MOUSE_FILTER_PASS
		print("MainGame._ready: HandDock鼠标过滤器已设置为PASS(%d)" % Control.MOUSE_FILTER_PASS)
		
		# 检查卡牌容器的鼠标过滤器
		var card_container = hand_dock.get_node_or_null("CardContainer")
		if card_container:
			print("MainGame._ready: CardContainer当前鼠标过滤器为 %d" % card_container.mouse_filter)
			card_container.mouse_filter = Control.MOUSE_FILTER_PASS
			print("MainGame._ready: CardContainer鼠标过滤器已设置为PASS(%d)" % Control.MOUSE_FILTER_PASS)
		else:
			print("MainGame._ready: 错误 - CardContainer不存在")
	
	# 手动连接HandDock的按钮信号
	if hand_dock:
		print("MainGame._ready: 手动连接HandDock信号")
		# 断开可能存在的旧连接
		if hand_dock.is_connected("play_button_pressed", Callable(self, "_on_play_button_pressed")):
			print("MainGame._ready: 断开已存在的play_button_pressed连接")
			hand_dock.disconnect("play_button_pressed", Callable(self, "_on_play_button_pressed"))
		if hand_dock.is_connected("discard_button_pressed", Callable(self, "_on_discard_button_pressed")):
			print("MainGame._ready: 断开已存在的discard_button_pressed连接")
			hand_dock.disconnect("discard_button_pressed", Callable(self, "_on_discard_button_pressed"))
			
		# 创建新连接
		print("MainGame._ready: 连接HandDock.play_button_pressed到_on_play_button_pressed")
		hand_dock.connect("play_button_pressed", Callable(self, "_on_play_button_pressed"))
		print("MainGame._ready: 连接HandDock.discard_button_pressed到_on_discard_button_pressed")
		hand_dock.connect("discard_button_pressed", Callable(self, "_on_discard_button_pressed"))
		print("MainGame._ready: HandDock信号连接完成")
	else:
		print("MainGame._ready: 错误 - HandDock不存在，无法连接信号")
	
	# 连接GameManager信号
	print("MainGame._ready: 连接GameManager信号")
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr:
		if not game_mgr.resources_changed.is_connected(Callable(self, "_on_resources_changed")):
			game_mgr.resources_changed.connect(Callable(self, "_on_resources_changed"))
		print("MainGame._ready: 连接GameManager.resources_changed到_on_resources_changed")

		if not game_mgr.score_changed.is_connected(Callable(self, "_on_score_changed")):
			game_mgr.score_changed.connect(Callable(self, "_on_score_changed"))
		print("MainGame._ready: 连接GameManager.score_changed到_on_score_changed")

		if not game_mgr.game_won.is_connected(Callable(self, "_on_game_won")):
			game_mgr.game_won.connect(Callable(self, "_on_game_won"))
		print("MainGame._ready: 连接GameManager.game_won到_on_game_won")

		# 连接额外的信号（全局GameManager特有的）
		if not game_mgr.mana_changed.is_connected(Callable(self, "_on_score_changed")):
			game_mgr.mana_changed.connect(Callable(self, "_on_score_changed"))
		print("MainGame._ready: 连接GameManager.mana_changed到_on_score_changed")
	else:
		print("MainGame._ready: 错误 - 无法获取GameManager单例，信号连接失败")
	
	# 初始化最大手牌数量
	max_hand_size = 5  # 默认值，与CardManager中的默认值保持一致
	if card_manager:
		max_hand_size = card_manager.max_hand_size
	
	# 开始游戏
	_start_game()
	
	print("MainGame._ready: 初始化完成")

# 加载UI组件
func _load_ui_components():
	print("MainGame._load_ui_components: 加载UI组件")
	
	# 获取已存在的UI组件
	hand_dock = $UIContainer/HandDock
	sidebar = $UIContainer/Sidebar
	hud = $UIContainer/Hud
	deck_widget = $UIContainer/DeckWidget
	top_dock = $UIContainer/TopDock
	
	if hand_dock:
		print("MainGame._load_ui_components: 找到HandDock组件")
	else:
		print("MainGame._load_ui_components: 错误 - 未找到HandDock组件")
	
	# 设置DeckWidget
	if deck_widget:
		print("MainGame._load_ui_components: 找到DeckWidget组件")
		if card_manager:
			deck_widget.setup(card_manager)
			print("MainGame._load_ui_components: DeckWidget已连接到CardManager")
			
			# 连接DeckWidget信号
			if not deck_widget.deck_clicked.is_connected(Callable(self, "_on_deck_clicked")):
				deck_widget.deck_clicked.connect(Callable(self, "_on_deck_clicked"))
				print("MainGame._load_ui_components: 已连接DeckWidget.deck_clicked信号")
		else:
			print("MainGame._load_ui_components: 错误 - CardManager未初始化，无法设置DeckWidget")
	else:
		print("MainGame._load_ui_components: 错误 - 未找到DeckWidget组件")
	
	print("MainGame._load_ui_components: UI组件加载完成")

# 开始游戏
func _start_game():
	print("MainGame._start_game: 开始游戏")
	
	# 等待一帧，确保GameManager单例已经加载
	await get_tree().process_frame
	
	# 获取GameManager引用 - 尝试多种方式
	var game_mgr = null
	
	# 方法1: 直接从根节点获取，不使用/root前缀
	if not game_mgr and get_tree() and get_tree().root:
		game_mgr = get_tree().root.get_node_or_null("GameManager")
		if game_mgr:
			print("MainGame._start_game: 从根节点直接获取到GameManager")
	
	# 方法2: 使用完整路径
	if not game_mgr and get_tree() and get_tree().root:
		game_mgr = get_tree().root.get_node_or_null("/root/GameManager")
		if game_mgr:
			print("MainGame._start_game: 使用/root/路径获取到GameManager")
	
	# 方法3: 从场景树中查找
	if not game_mgr and get_tree():
		var root = get_tree().root
		for child in root.get_children():
			if child.get_name() == "GameManager":
				game_mgr = child
				print("MainGame._start_game: 通过遍历场景树找到GameManager")
				break
	
	if not game_mgr:
		print("MainGame._start_game: 错误 - 无法获取GameManager单例")
		return
	
	print("MainGame._start_game: 成功获取GameManager单例")
	
	# 连接GameManager到EffectOrchestrator
	if effect_orchestrator and game_mgr.has_method("connect_to_orchestrator"):
		game_mgr.connect_to_orchestrator(effect_orchestrator)
		print("MainGame._start_game: GameManager已连接到EffectOrchestrator")
	
	# 确保GameManager的符文库已初始化
	if game_mgr.all_runes.size() == 0:
		print("MainGame._start_game: GameManager符文库为空，尝试初始化")
		game_mgr.initialize_rune_library()
	
	# 发放初始手牌
	if card_manager:
		# 初始化卡牌管理器
		card_manager.initialize()
		print("MainGame._start_game: 调用卡牌管理器的deal_initial_hand方法")
		card_manager.deal_initial_hand(5)
		print("MainGame._start_game: 已发放初始手牌")
	
	print("MainGame._start_game: 游戏开始完成")

# 游戏胜利处理
func _on_game_won():
	print("MainGame._on_game_won: 游戏胜利！")
	
	# 创建胜利弹窗
	var popup = AcceptDialog.new()
	popup.dialog_text = "🎉 目标达成！"
	popup.title = "胜利"
	popup.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y / 2 - 50)
	popup.size = Vector2(300, 150)
	
	# 连接确认按钮到重新开始游戏
	popup.confirmed.connect(_restart_game)
	
	# 添加到场景并显示
	add_child(popup)
	popup.popup_centered()
	
	print("MainGame._on_game_won: 已显示胜利弹窗")

# 重新开始游戏
func _restart_game():
	print("MainGame._restart_game: 重新开始游戏")
	
	# 重置游戏状态
	var game_mgr = get_node_or_null("/root/GameManager")
	if game_mgr:
		game_mgr.reset_game_state()
	else:
		print("MainGame._restart_game: 错误 - 无法获取GameManager单例")
	
	# 清空手牌
	if hand_dock:
		print("MainGame._restart_game: 清空手牌")
		var card_container = hand_dock.get_node_or_null("CardContainer")
		if card_container:
			for child in card_container.get_children():
				child.queue_free()
	
	# 发放初始手牌
	if card_manager:
		print("MainGame._restart_game: 发放初始手牌")
		card_manager.deal_initial_hand(5)
	
	print("MainGame._restart_game: 游戏重新开始完成")

# 资源变化处理
func _on_resources_changed(focus, essence, deck_size):
	print("MainGame._on_resources_changed: 收到资源更新，focus=%d, essence=%d, deck_size=%d" % [focus, essence, deck_size])
	
	# 更新sidebar显示
	if not sidebar:
		sidebar = $UIContainer/Sidebar
	
	if sidebar:
		sidebar.set_focus(focus)
		sidebar.set_essence(essence)
		print("MainGame._on_resources_changed: 已更新sidebar显示")
	else:
		print("MainGame._on_resources_changed: 错误 - sidebar为空")
	
	# 更新牌库组件显示
	if not deck_widget:
		deck_widget = $UIContainer/DeckWidget
	
	if deck_widget and deck_widget.has_method("update_deck_info"):
		var game_mgr = get_node_or_null("/root/GameManager")
		if game_mgr:
			deck_widget.update_deck_info(deck_size, game_mgr.total_runes)
			print("MainGame._on_resources_changed: 已更新deck_widget显示")
		else:
			print("MainGame._on_resources_changed: 错误 - 无法获取GameManager单例")
	else:
		print("MainGame._on_resources_changed: 警告 - deck_widget为空或没有update_deck_info方法")

# 分数变化处理
func _on_score_changed(new_score):
	print("MainGame._on_score_changed: 收到分数更新，new_score=%d" % new_score)
	
	# 先检查sidebar是否存在
	if not sidebar:
		print("MainGame._on_score_changed: sidebar不存在，尝试获取")
		sidebar = $UIContainer/Sidebar
	
	# 更新sidebar的总得分（学识魔力）
	if sidebar and sidebar.has_method("set_mana"):
		print("MainGame._on_score_changed: 更新sidebar学识魔力")
		sidebar.set_mana(new_score)
	else:
		print("MainGame._on_score_changed: 错误 - 无法更新学识魔力，sidebar为空或没有set_mana方法")

# 更新牌库组件
func update_deck_widget():
	var deck_widget = $UIContainer/DeckWidget
	if deck_widget and deck_widget.has_method("update_deck_info"):
		var game_mgr = get_node_or_null("/root/GameManager")
		if game_mgr:
			deck_widget.update_deck_info(game_mgr.remaining_runes, game_mgr.total_runes)
			print("MainGame.update_deck_widget: 已更新牌库显示，剩余=%d，总数=%d" % [game_mgr.remaining_runes, game_mgr.total_runes])
		else:
			print("MainGame.update_deck_widget: 错误 - 无法获取GameManager单例")

# 获取特效层
func get_effect_layer() -> CanvasLayer:
	# 如果已经有特效层，返回它
	var existing_layer = find_child("EffectLayer", false)
	if existing_layer and existing_layer is CanvasLayer:
		return existing_layer
	
	# 否则创建一个新的
	var effect_layer = CanvasLayer.new()
	effect_layer.name = "EffectLayer"
	effect_layer.layer = 5  # 设置为较高的层级，确保特效显示在最上层
	add_child(effect_layer)
	return effect_layer

# 处理设置按钮点击
func _on_settings_button_pressed():
	print("MainGame._on_settings_button_pressed: 设置菜单即将开放...")
	# 可以在这里创建一个临时的状态提示
	var status_label = Label.new()
	status_label.text = "设置菜单即将开放..."
	status_label.position = Vector2(get_viewport().size.x / 2 - 100, 50)
	add_child(status_label)
	
	# 2秒后自动移除提示
	await get_tree().create_timer(2.0).timeout
	status_label.queue_free()

# 处理出牌按钮点击
func _on_play_button_pressed():
	print("MainGame._on_play_button_pressed: 收到打出卡牌信号")
	
	# 检查卡牌管理器是否存在
	if card_manager:
		print("MainGame._on_play_button_pressed: 调用卡牌管理器的play_selected方法")
		var result = await card_manager.play_selected()
		print("MainGame._on_play_button_pressed: play_selected返回结果=%s" % str(result))
	else:
		print("MainGame._on_play_button_pressed: 错误 - 卡牌管理器不存在")

# 处理弃牌按钮点击
func _on_discard_button_pressed():
	print("MainGame._on_discard_button_pressed: 收到弃置卡牌信号")
	# 检查卡牌管理器是否存在
	if card_manager:
		print("MainGame._on_discard_button_pressed: 调用卡牌管理器的discard_selected方法")
		var result = await card_manager.discard_selected()
		print("MainGame._on_discard_button_pressed: discard_selected返回结果=%s" % str(result))
	else:
		print("MainGame._on_discard_button_pressed: 错误 - 卡牌管理器不存在")

# 按值排序卡牌
func sort_cards_by_value():
	if hand_dock and hand_dock.has_method("sort_cards_by_value"):
		hand_dock.sort_cards_by_value()

# 按花色排序卡牌
func sort_cards_by_suit():
	if hand_dock and hand_dock.has_method("sort_cards_by_suit"):
		hand_dock.sort_cards_by_suit()

# 处理牌库点击事件
func _on_deck_clicked():
	print("MainGame: 牌库被点击")
	
	# 这里可以添加额外逻辑，例如播放音效等
	# 实际的弹窗逻辑已在DeckWidget中处理
