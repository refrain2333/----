extends Node

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")
const ScoreCalculator = preload("res://cs/Global/ScoreCalculator.gd")

# ===== 信号系统（符合v1.6规范）=====
signal new_year_started(year_num)
signal term_started(term_type)
signal term_ended()
signal wisdom_hall_opened()
signal assessment_started(year_num)
signal assessment_score_updated(current_score, target_score)
signal game_won()
signal game_lost()
signal lore_changed(new_lore_points)
signal card_type_levels_changed(card_type_levels)
signal player_abilities_changed(artifacts, spells, jokers)
signal game_state_changed(year, term, current_assessment_score, lore_points)
signal spell_used(spell_id)
signal score_changed(score)
signal mana_changed(mana)
signal resources_changed(lore, score, runes)

# ===== 游戏流程状态（符合v1.6规范）=====
var current_year: int = 0
var current_term: int = GlobalEnums.TermType.SPRING
var game_state: int = GlobalEnums.GameState.MAIN_MENU
var current_assessment_score: int = 0  # 当前考核得分

# ===== 玩家资源（符合v1.6规范）=====
var lore_points: int = 0  # 传说点数，用于解锁新卡牌和升级
var card_type_levels: Dictionary = {}  # 各种牌型的等级
var equipped_artifacts: Array[ArtifactData] = []  # 装备的法器
var spell_inventory: Array[SpellData] = []        # 持有的法术
var active_jokers: Array[JokerData] = []          # 激活的守护灵

# 游戏资源
var remaining_runes: int = 0  # 剩余符文数量
var total_runes: int = 0      # 总符文数量
var all_runes: Array = []     # 所有符文

# ===== 游戏配置 =====
@onready var game_config = preload("res://assets/data/game_config.tres")
@onready var event_manager = get_node_or_null("/root/EventManager")  # 新增：事件管理器引用

# ===== 初始化方法 =====
func _ready():
	# 初始化游戏状态
	initialize_game_state()

# 初始化游戏状态，在新游戏开始时调用
func initialize_game_state():
	# 重置年份和学期
	current_year = 0
	current_term = GlobalEnums.TermType.SPRING
	current_assessment_score = 0  # 重置考核分数
	
	# 初始化玩家资源
	lore_points = game_config.initial_lore_points
	
	# 初始化牌型等级
	_initialize_card_type_levels()
	
	# 清空玩家能力
	equipped_artifacts.clear()
	spell_inventory.clear()
	active_jokers.clear()
	
	# 发送初始化信号
	emit_signal("lore_changed", lore_points)
	emit_signal("card_type_levels_changed", card_type_levels)
	emit_signal("player_abilities_changed")
	emit_signal("game_state_changed", game_state)
	emit_signal("score_changed", current_assessment_score)  # 发送分数信号

# 重置游戏状态（用于重新开始游戏）
func reset_game_state():
	initialize_game_state()
	print("GameManager: 游戏状态已重置")

# 初始化符文库
func initialize_rune_library():
	all_runes.clear()
	# 这里可以添加初始符文
	print("GameManager: 符文库已初始化")
	
	# 更新符文计数
	total_runes = all_runes.size()
	remaining_runes = total_runes
	
	# 发送资源变化信号
	emit_signal("resources_changed", lore_points, current_assessment_score, remaining_runes)

# 初始化牌型等级
func _initialize_card_type_levels():
	card_type_levels = {
		GlobalEnums.CARD_TYPE_HIGH_CARD: 1,
		GlobalEnums.CARD_TYPE_PAIR: 1,
		GlobalEnums.CARD_TYPE_TWO_PAIR: 1,
		GlobalEnums.CARD_TYPE_THREE_OF_KIND: 1,
		GlobalEnums.CARD_TYPE_STRAIGHT: 1,
		GlobalEnums.CARD_TYPE_FLUSH: 1,
		GlobalEnums.CARD_TYPE_FULL_HOUSE: 1,
		GlobalEnums.CARD_TYPE_FOUR_OF_KIND: 1,
		GlobalEnums.CARD_TYPE_STRAIGHT_FLUSH: 1,
		GlobalEnums.CARD_TYPE_ROYAL_FLUSH: 1
	}

# ===== 游戏流程管理方法 =====
# 开始新学年
func start_new_year(year: int = -1):
	if year < 0:
		current_year += 1  # 如果没有指定年份，则自增
	else:
		current_year = year
		
	print("GameManager: 开始新学年 %d" % current_year)
	emit_signal("new_year_started", current_year)
	emit_signal("game_state_changed", game_state)
	
	# 自动开始春季学期
	if year >= 0:  # 只有在明确指定年份时才自动开始春季学期
		start_term(GlobalEnums.TermType.SPRING)

# 开始学期
func start_term(term: int):
	current_term = term
	var term_name = GlobalEnums.new().get_term_name(current_term)
	print("GameManager: 开始学期 %s" % term_name)
	
	# 应用学期奖励
	if game_config.term_rewards_by_type.has(current_term):
		var rewards = game_config.term_rewards_by_type[current_term]
		if rewards.has("lore_points"):
			add_lore(rewards.lore_points)
	
	# 清理旧的学期Buff
	if event_manager:
		event_manager.on_term_start()
	
	# 发送信号
	emit_signal("term_started", current_term)
	emit_signal("game_state_changed", game_state)

# 结束学期
func end_term():
	var term_name = GlobalEnums.new().get_term_name(current_term)
	print("GameManager: 结束学期 %s" % term_name)
	
	# 清理学期Buff
	if event_manager:
		event_manager.on_term_end()
	
	emit_signal("term_ended")
	emit_signal("game_state_changed", game_state)
	
	# 自动进入下一学期或学年
	_advance_to_next_term()

# 进入下一学期或学年
func _advance_to_next_term():
	match current_term:
		GlobalEnums.TermType.SPRING:
			start_term(GlobalEnums.TermType.SUMMER)
		GlobalEnums.TermType.SUMMER:
			start_term(GlobalEnums.TermType.AUTUMN)
		GlobalEnums.TermType.AUTUMN:
			start_term(GlobalEnums.TermType.WINTER)
		GlobalEnums.TermType.WINTER:
			if current_year < 6:  # 最多6学年
				start_new_year()
			else:
				emit_signal("game_won")

# 进入智慧厅（商店）
func start_wisdom_hall():
	print("GameManager: 进入智慧厅")
	game_state = GlobalEnums.GameState.SHOP
	emit_signal("wisdom_hall_opened")
	emit_signal("game_state_changed", game_state)

# 开始考核（符合v1.6规范）
func start_assessment():
	print("GameManager: 开始考核")
	game_state = GlobalEnums.GameState.ASSESSMENT
	current_assessment_score = 0  # 重置分数
	var target_score = _get_target_score_for_year(current_year)
	emit_signal("assessment_started", current_year)
	emit_signal("assessment_score_updated", current_assessment_score, target_score)
	emit_signal("game_state_changed", current_year, current_term, current_assessment_score, lore_points)
	emit_signal("score_changed", current_assessment_score)

# 结束考核
func end_assessment():
	print("GameManager: 结束考核，得分: %d" % current_assessment_score)

	# 检查是否达到该学年的胜利分数
	var victory_score = game_config.victory_score_by_year.get(current_year, 0)
	if current_assessment_score >= victory_score:
		print("GameManager: 考核通过！")
		end_term()
	else:
		print("GameManager: 考核失败")
		emit_signal("game_lost")

# ===== 玩家资源与能力管理 =====
# 增加传说点数
func add_lore(amount: int):
	# 考虑魔力水晶等法器加成
	var final_amount = amount
	# 这里可以考虑加入效果修正，如魔力水晶增益
	
	lore_points += final_amount
	print("GameManager: 传说点数 %+d = %d" % [final_amount, lore_points])
	emit_signal("lore_changed", lore_points)
	emit_signal("resources_changed", lore_points, current_assessment_score, remaining_runes)

# 增加考核分数
func add_assessment_score(amount: int):
	current_assessment_score += amount
	print("GameManager: 考核分数 %+d = %d" % [amount, current_assessment_score])
	emit_signal("score_changed", current_assessment_score)
	emit_signal("mana_changed", current_assessment_score)  # 同时发送学识魔力变化信号
	emit_signal("resources_changed", lore_points, current_assessment_score, remaining_runes)



# 获取当前手牌上限
func get_current_hand_size() -> int:
	var base_size = game_config.initial_player_hand_size
	
	# 获取对应学年的手牌上限加成
	var year_bonus = game_config.year_hand_size_adjustments.get(current_year, 0)
	
	# 获取Buff/Debuff修正
	var modifier = 0
	var event_manager_node = get_node_or_null("/root/EventManager")
	if event_manager_node and event_manager_node.has_method("get_active_effects"):
		var effects = event_manager_node.get_active_effects()
		if effects.has("hand_size_modifier"):
			modifier += effects.hand_size_modifier
	
	return max(1, base_size + year_bonus + modifier)

# 获取特定牌型的等级
func get_card_type_level(type_name: String) -> int:
	return card_type_levels.get(type_name, 1)

# 修改牌型等级
# 修改牌型等级（符合v1.6规范）
func modify_card_type_level(type_name: String, amount: int):
	var current_level = get_card_type_level(type_name)
	var new_level = clamp(current_level + amount, 1, 5)  # 限制在LV1-LV5
	card_type_levels[type_name] = new_level
	print("GameManager: 牌型等级变化 - %s: LV%d -> LV%d" % [type_name, current_level, new_level])
	emit_signal("card_type_levels_changed", card_type_levels)

# 获取当前状态快照，用于UI和存档
func get_state_snapshot() -> Dictionary:
	return {
		"year": current_year,
		"term": current_term,
		"game_state": game_state,
		"lore_points": lore_points,
		"score": current_assessment_score,
		"card_type_levels": card_type_levels.duplicate(),
		"equipped_artifacts_count": equipped_artifacts.size(),
		"spells_count": spell_inventory.size(),
		"jokers_count": active_jokers.size(),
		"remaining_runes": remaining_runes,
		"total_runes": total_runes
	}

# 获取分数倍率（用于ScoreCalculator）
func get_score_multiplier() -> float:
	# 基础倍率为1.0
	var multiplier = 1.0

	# 这里可以添加基于游戏状态的倍率修正
	# 例如：基于学年、学期、特殊事件等

	return multiplier

# ===== v1.6规范要求的核心方法 =====



# 添加法器
func add_artifact(artifact: ArtifactData):
	equipped_artifacts.append(artifact)
	print("GameManager: 添加法器 - %s" % artifact.name)
	emit_signal("player_abilities_changed", equipped_artifacts, spell_inventory, active_jokers)

# 添加法术
func add_spell(spell: SpellData):
	# 检查是否已有同名法术，如果有则增加充能
	for existing_spell in spell_inventory:
		if existing_spell.id == spell.id:
			existing_spell.charges += spell.charges
			print("GameManager: 法术充能增加 - %s (+%d)" % [spell.name, spell.charges])
			emit_signal("player_abilities_changed", equipped_artifacts, spell_inventory, active_jokers)
			return

	# 如果没有同名法术，则添加新法术
	spell_inventory.append(spell)
	print("GameManager: 添加法术 - %s" % spell.name)
	emit_signal("player_abilities_changed", equipped_artifacts, spell_inventory, active_jokers)

# 激活守护灵
func activate_joker(joker: JokerData, old_joker_index: int = -1):
	if old_joker_index >= 0 and old_joker_index < active_jokers.size():
		# 替换现有守护灵
		var old_joker = active_jokers[old_joker_index]
		active_jokers[old_joker_index] = joker
		print("GameManager: 替换守护灵 - %s -> %s" % [old_joker.name, joker.name])
	else:
		# 添加新守护灵
		active_jokers.append(joker)
		print("GameManager: 激活守护灵 - %s" % joker.name)

	emit_signal("player_abilities_changed", equipped_artifacts, spell_inventory, active_jokers)

# 私有辅助方法
func _get_target_score_for_year(year: int) -> int:
	# 根据年份计算目标分数
	return 1000 + (year - 1) * 500

func _apply_year_effects(year: int):
	# 应用学年特殊效果
	if year >= 3:
		print("GameManager: 高年级效果 - 手牌上限-2")
