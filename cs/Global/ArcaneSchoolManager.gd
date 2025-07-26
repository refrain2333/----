extends Node

# =====================================================
# 警告：此类已弃用，请使用GameManager代替
# 此类仅作为兼容层存在，将在未来版本中移除
# =====================================================

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 获取GameManager单例引用
@onready var game_manager = get_node_or_null("/root/GameManager")

# ===== 信号系统 =====
# 游戏流程信号 - 所有信号都会转发到GameManager
signal new_year_started(year)
signal term_started(term_type)
signal term_ended()
signal wisdom_hall_opened()
signal assessment_started(year)
signal game_won()
signal game_lost()

# 状态更新信号
signal game_state_changed(state_dict)
signal lore_changed(points)
signal card_type_levels_changed(levels)
signal score_changed(score)

# ===== 初始化方法 =====
func _ready():
	print("警告：ArcaneSchoolManager已弃用，请使用GameManager代替")
	
	# 连接GameManager的信号到本地信号
	if game_manager:
		_connect_signals()
	else:
		push_error("ArcaneSchoolManager: 无法获取GameManager单例")

# 连接GameManager的信号
func _connect_signals():
	if not game_manager:
		return
		
	# 连接所有需要转发的信号
	game_manager.new_year_started.connect(func(year): emit_signal("new_year_started", year))
	game_manager.term_started.connect(func(term): emit_signal("term_started", term))
	game_manager.term_ended.connect(func(): emit_signal("term_ended"))
	game_manager.wisdom_hall_opened.connect(func(): emit_signal("wisdom_hall_opened"))
	game_manager.assessment_started.connect(func(year): emit_signal("assessment_started", year))
	game_manager.game_won.connect(func(): emit_signal("game_won"))
	game_manager.game_lost.connect(func(): emit_signal("game_lost"))
	game_manager.game_state_changed.connect(func(state): emit_signal("game_state_changed", game_manager.get_state_snapshot()))
	game_manager.lore_changed.connect(func(points): emit_signal("lore_changed", points))
	game_manager.card_type_levels_changed.connect(func(levels): emit_signal("card_type_levels_changed", levels))
	game_manager.score_changed.connect(func(score): emit_signal("score_changed", score))

# ===== 属性代理 =====
# 所有属性都代理到GameManager

var current_year: int:
	get: return game_manager.current_year if game_manager else 0
	set(value): if game_manager: game_manager.current_year = value

var current_term: int:
	get: return game_manager.current_term if game_manager else 0
	set(value): if game_manager: game_manager.current_term = value

var game_state: int:
	get: return game_manager.game_state if game_manager else GlobalEnums.GameState.MAIN_MENU
	set(value): if game_manager: game_manager.game_state = value

var player_score: int:
	get: return game_manager.player_score if game_manager else 0
	set(value): if game_manager: game_manager.player_score = value

var lore_points: int:
	get: return game_manager.lore_points if game_manager else 0
	set(value): if game_manager: game_manager.lore_points = value

var card_type_levels: Dictionary:
	get: return game_manager.card_type_levels.duplicate() if game_manager else {}

# ===== 方法代理 =====
# 所有方法都代理到GameManager

func _initialize_game():
	if game_manager:
		game_manager.initialize_game_state()

func start_new_year():
	if game_manager:
		game_manager.start_new_year()

func start_term(term: int):
	if game_manager:
		game_manager.start_term(term)

func end_term():
	if game_manager:
		game_manager.end_term()

func start_wisdom_hall():
	if game_manager:
		game_manager.start_wisdom_hall()

func start_assessment():
	if game_manager:
		game_manager.start_assessment()

func end_assessment():
	if game_manager:
		game_manager.end_assessment()

func add_lore_points(amount: int):
	if game_manager:
		game_manager.add_lore(amount)

func add_assessment_score(amount: int):
	if game_manager:
		game_manager.add_assessment_score(amount)

func increase_card_type_level(type_name: String):
	if game_manager:
		game_manager.modify_card_type_level(type_name, 1)

func get_state_snapshot() -> Dictionary:
	return game_manager.get_state_snapshot() if game_manager else {}

func get_current_hand_size() -> int:
	return game_manager.get_current_hand_size() if game_manager else 5

func on_cards_played(cards: Array):
	if game_manager:
		game_manager.on_cards_played(cards) 
