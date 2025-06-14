extends Node2D

# 管理器引用
var card_manager: CardManager
var turn_manager: TurnManager
var effect_orchestrator: EffectOrchestrator
var input_manager: InputManager
var input_router: InputRouter
var ui_manager: UIManager
var game_state: GameState
var discovery_manager: DiscoveryManager
var joker_manager: JokerManager

# 场景引用
@export var sidebar_scene: PackedScene
@export var hud_scene: PackedScene
@export var hand_dock_scene: PackedScene
@export var deck_widget_scene: PackedScene
@export var top_dock_scene: PackedScene

func _ready():
	print("主场景初始化")
	
	# 初始化游戏状态
	game_state = GameState.new(self)
	
	# 初始化管理器
	card_manager = CardManager.new(self)
	turn_manager = TurnManager.new(self)
	effect_orchestrator = EffectOrchestrator.new(self)
	input_manager = InputManager.new(self)
	input_router = InputRouter.new(self)
	
	# 初始化UI管理器并使用已存在的UI组件
	ui_manager = UIManager.new(self)
	ui_manager.use_existing_ui_components($UIContainer/Sidebar, $UIContainer/Hud, 
		$UIContainer/HandDock, $UIContainer/DeckWidget, $UIContainer/TopDock)
	add_child(ui_manager)
	
	# 连接UI管理器信号
	ui_manager.hud_ready.connect(turn_manager.connect_ui)
	
	# 初始化发现和小丑管理器
	discovery_manager = DiscoveryManager.new(self)
	joker_manager = JokerManager.new(self)
	
	# 初始化各系统
	effect_orchestrator.initialize()
	card_manager.initialize()
	
	# 设置发现和小丑管理器的容器
	var artifact_container = ui_manager.get_artifact_container()
	var discovery_container = ui_manager.get_discovery_container()
	if artifact_container and discovery_container:
		discovery_manager.setup(discovery_container, artifact_container)
		discovery_manager.initialize_discoveries()
		discovery_manager.initialize_artifacts()
	
	# 同步游戏状态
	game_state.sync_game_state()
	
	# 更新UI
	ui_manager.update_ui()
	
	# 直接更新牌库组件
	update_deck_widget()
	
	# 开始第一个回合
	turn_manager.start_turn()

# 更新牌库组件
func update_deck_widget():
	var deck_widget = $UIContainer/DeckWidget
	if deck_widget and deck_widget.has_method("update_deck_info"):
		deck_widget.update_deck_info(game_state.deck_stats.remaining, game_state.deck_stats.total)

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
	ui_manager.set_status("设置菜单即将开放...")

# 处理出牌按钮点击
func _on_play_button_pressed():
	# 检查是否有选中的卡牌
	var hand_dock = ui_manager.hand_dock
	if hand_dock and hand_dock.selected_cards.size() > 0:
		# 出牌
		card_manager.play_card(hand_dock.selected_cards[0])

# 处理弃牌按钮点击
func _on_discard_button_pressed():
	# 检查是否有选中的卡牌
	var hand_dock = ui_manager.hand_dock
	if hand_dock and hand_dock.selected_cards.size() > 0:
		# 弃牌
		card_manager.discard_card(hand_dock.selected_cards[0])

# 按值排序卡牌
func sort_cards_by_value():
	var hand_dock = ui_manager.hand_dock
	if hand_dock and hand_dock.has_method("sort_cards_by_value"):
		hand_dock.sort_cards_by_value()

# 按花色排序卡牌
func sort_cards_by_suit():
	var hand_dock = ui_manager.hand_dock
	if hand_dock and hand_dock.has_method("sort_cards_by_suit"):
		hand_dock.sort_cards_by_suit() 
