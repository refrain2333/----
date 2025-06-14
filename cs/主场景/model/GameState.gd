class_name GameState
extends Node

# 游戏运行时状态 - 本局游戏的数据快照
var turn_number: int = 1            # 当前回合数
var hand_cards: Array = []          # 当前手牌ID列表
var played_cards: Array = []        # 本回合已打出的卡牌
var active_combinations: Array = [] # 当前场上的组合
var resources: Dictionary = {       # 资源状态
	"mana": 0,        # 学识魔力（分数）
	"focus": 5,       # 集中力（剩余出牌次数）
	"essence": 3,     # 精华（弃牌次数）
	"lore": 4         # 学识点（金币）
}
var score: Dictionary = {           # 分数状态
	"base": 50,       # 基础分数
	"multiplier": 1   # 分数倍率
}
var deck_stats: Dictionary = {      # 牌库统计
	"total": 52,      # 牌库总数
	"remaining": 52   # 剩余数量
}

# 引用主场景
var main_game

func _init(game_scene):
	main_game = game_scene

# 同步游戏状态（从GameManager获取最新状态）
func sync_game_state():
	if not Engine.has_singleton("GameManager"):
		return
	
	var GameManager = Engine.get_singleton("GameManager")
	
	# 同步回合数
	turn_number = GameManager.current_turn
	
	# 同步手牌
	hand_cards = []
	if GameManager.has_method("get_hand"):
		hand_cards = GameManager.get_hand()
	
	# 同步资源
	resources.mana = GameManager.current_mana if GameManager.has_method("get_mana") else 0
	resources.focus = GameManager.focus_count if GameManager.has_method("get_focus") else 5
	resources.essence = GameManager.essence_count if GameManager.has_method("get_essence") else 3
	resources.lore = GameManager.lore_points if GameManager.has_method("get_lore") else 4
	
	# 同步分数
	score.base = GameManager.base_score if GameManager.has_method("get_base_score") else 50
	score.multiplier = GameManager.score_multiplier if GameManager.has_method("get_multiplier") else 1
	
	# 同步牌库
	deck_stats.total = GameManager.total_runes if GameManager.has_method("get_total_runes") else 52
	deck_stats.remaining = GameManager.remaining_runes if GameManager.has_method("get_remaining_runes") else 52
	
	# 更新牌库UI
	if main_game and main_game.ui_manager:
		main_game.ui_manager.update_deck_info(deck_stats.remaining, deck_stats.total)

# 记录出牌
func record_played_card(card_data):
	played_cards.append(card_data)
	
	# 检查是否形成组合
	check_combinations()

# 检查卡牌组合
func check_combinations():
	# 组合检测逻辑
	var combinations = []
	
	# 检查同花组合
	var suits = {}
	for card in played_cards:
		if not suits.has(card.element):
			suits[card.element] = []
		suits[card.element].append(card)
	
	for element in suits:
		if suits[element].size() >= 3:
			combinations.append({
				"type": "flush",
				"element": element,
				"cards": suits[element]
			})
	
	# 检查顺子组合
	var sorted_by_power = played_cards.duplicate()
	sorted_by_power.sort_custom(func(a, b): return a.power < b.power)
	
	var straight = []
	for i in range(sorted_by_power.size()):
		if i == 0 or sorted_by_power[i].power == sorted_by_power[i-1].power + 1:
			straight.append(sorted_by_power[i])
		else:
			straight = [sorted_by_power[i]]
		
		if straight.size() >= 3:
			combinations.append({
				"type": "straight",
				"cards": straight.duplicate()
			})
	
	# 更新活跃组合
	active_combinations = combinations

# 检查奖励
func check_for_rewards(score_value):
	# 检查是否达到奖励阈值
	if score_value >= 100:
		# 添加小丑卡奖励
		main_game.joker_manager.offer_joker_reward()
	
	# 检查是否达到发现阈值
	if score_value >= 150:
		# 添加发现奖励
		main_game.discovery_manager.offer_discovery()

# 设置分数值
func set_score_values(base: int, multiplier: int):
	score.base = base
	score.multiplier = multiplier
	
	# 同步到GameManager
	GameManager.base_score = score.base
	GameManager.score_multiplier = score.multiplier

# 重置回合状态
func reset_turn_state():
	played_cards = []
	active_combinations = []
	
	# 重置回合资源
	resources.focus = 5  # 默认初始值
	resources.essence = 3  # 默认初始值
	
	# 重置分数
	score.base = 50
	score.multiplier = 1

# 保存游戏状态（用于存档）
func save_game_state() -> Dictionary:
	return {
		"turn_number": turn_number,
		"hand_cards": hand_cards,
		"played_cards": played_cards,
		"active_combinations": active_combinations,
		"resources": resources,
		"score": score,
		"deck_stats": deck_stats
	}

# 加载游戏状态（用于读档）
func load_game_state(state_data: Dictionary):
	if state_data.has("turn_number"):
		turn_number = state_data.turn_number
	
	if state_data.has("hand_cards"):
		hand_cards = state_data.hand_cards
	
	if state_data.has("played_cards"):
		played_cards = state_data.played_cards
	
	if state_data.has("active_combinations"):
		active_combinations = state_data.active_combinations
	
	if state_data.has("resources"):
		resources = state_data.resources
	
	if state_data.has("score"):
		score = state_data.score
	
	if state_data.has("deck_stats"):
		deck_stats = state_data.deck_stats
	
	# 同步到GameManager
	GameManager.current_turn = turn_number
	GameManager.current_mana = resources.mana
	GameManager.focus_count = resources.focus
	GameManager.essence_count = resources.essence
	GameManager.lore_points = resources.lore
	GameManager.base_score = score.base
	GameManager.score_multiplier = score.multiplier
	
	# 更新手牌
	GameManager.hand = []
	for card_id in hand_cards:
		GameManager.hand.append(card_id)
	
	# 更新UI
	main_game.ui_manager.update_ui()
	
	# 更新牌库UI
	if main_game and main_game.ui_manager:
		main_game.ui_manager.update_deck_info(deck_stats.remaining, deck_stats.total)
