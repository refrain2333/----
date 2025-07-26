extends Node

# 配置资源
var config: GameConfigResource

func _ready():
	# 加载配置资源
	config = load("res://assets/data/game_config.tres")
	if not config:
		# 如果找不到配置文件，创建一个默认配置
		config = GameConfigResource.new()
		push_warning("GameConfigSingleton: 无法加载配置文件，已创建默认配置")

# 获取配置
func get_config() -> GameConfigResource:
	return config

# 以下是便捷访问方法，直接访问配置中的属性

# 获取胜利目标分数
func get_victory_score(year: int) -> int:
	if config.victory_score_by_year.has(year):
		return config.victory_score_by_year[year]
	return 500  # 默认值

# 获取学期奖励
func get_term_rewards(term_type) -> Dictionary:
	if config.term_rewards_by_type.has(term_type):
		return config.term_rewards_by_type[term_type]
	return {"lore_points": 0, "wax_seal_type": ""}

# 获取初始手牌大小
func get_initial_hand_size() -> int:
	return config.initial_player_hand_size

# 获取学年手牌调整值
func get_year_hand_size_adjustment(year: int) -> int:
	if config.year_hand_size_adjustments.has(year):
		return config.year_hand_size_adjustments[year]
	return 0

# 获取牌型基础分数
func get_card_type_base_score(card_type: String) -> int:
	if config.card_type_base_scores.has(card_type):
		return config.card_type_base_scores[card_type]
	return 0

# 获取牌型等级倍率
func get_card_type_level_multiplier(card_type: String, level: int) -> float:
	if config.card_type_level_multipliers.has(card_type):
		var multipliers = config.card_type_level_multipliers[card_type]
		if level >= 0 and level < multipliers.size():
			return multipliers[level]
	return 1.0 