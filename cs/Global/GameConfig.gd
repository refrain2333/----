extends Resource
class_name GameConfigResource

# 引入GlobalEnums
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 胜利目标分数 (按学年)
@export var victory_score_by_year: Dictionary = {
	1: 500,   # 一年级
	2: 1200,  # 二年级
	3: 2000,  # 三年级
	4: 3000,  # 四年级
	5: 4500,  # 五年级
	6: 6000   # 六年级
} : set = _set_victory_scores

# 确保正确的数据类型
func _set_victory_scores(value: Dictionary):
	# 验证字典中的所有键是否为整数，所有值是否为整数
	var valid_dict = {}
	for key in value:
		if key is int and value[key] is int:
			valid_dict[key] = value[key]
		else:
			push_warning("GameConfig: 胜利分数字典包含非整数键或值，已跳过: %s: %s" % [key, value[key]])
	
	victory_score_by_year = valid_dict

# 学期奖励 (按学期类型)
@export var term_rewards_by_type: Dictionary = {
	GlobalEnums.TermType.SPRING: {
		"lore_points": 20,
		"wax_seal_type": "RED"
	},
	GlobalEnums.TermType.SUMMER: {
		"lore_points": 30,
		"wax_seal_type": "BLUE"
	},
	GlobalEnums.TermType.AUTUMN: {
		"lore_points": 40,
		"wax_seal_type": "GREEN"
	},
	GlobalEnums.TermType.WINTER: {
		"lore_points": 50,
		"wax_seal_type": "GOLD"
	}
}

# 初始手牌大小
@export var initial_player_hand_size: int = 8

# 每回合最大技能法术使用数
@export var max_active_spells_per_turn: int = 2

# 最大弃牌重抽数量
@export var max_discard_redraw_count: int = 3

# 牌型基础得分
@export var card_type_base_scores: Dictionary = {
	"HIGH_CARD": 5,
	"PAIR": 10,
	"TWO_PAIR": 20,
	"THREE_OF_KIND": 30,
	"STRAIGHT": 40,
	"FLUSH": 50,
	"FULL_HOUSE": 60,
	"FOUR_OF_KIND": 80,
	"STRAIGHT_FLUSH": 100,
	"ROYAL_FLUSH": 150
}

# 牌型等级倍率
@export var card_type_level_multipliers: Dictionary = {
	"HIGH_CARD": [1.0, 1.2, 1.5, 1.8, 2.0],
	"PAIR": [1.0, 1.3, 1.6, 2.0, 2.5],
	"TWO_PAIR": [1.0, 1.4, 1.8, 2.2, 2.8],
	"THREE_OF_KIND": [1.0, 1.5, 2.0, 2.5, 3.0],
	"STRAIGHT": [1.0, 1.6, 2.2, 2.8, 3.5],
	"FLUSH": [1.0, 1.7, 2.4, 3.2, 4.0],
	"FULL_HOUSE": [1.0, 1.8, 2.6, 3.5, 4.5],
	"FOUR_OF_KIND": [1.0, 2.0, 3.0, 4.0, 5.0],
	"STRAIGHT_FLUSH": [1.0, 2.5, 4.0, 6.0, 8.0],
	"ROYAL_FLUSH": [1.0, 3.0, 5.0, 8.0, 12.0]
}

# 商店商品刷新概率
@export var shop_rarity_probabilities: Dictionary = {
	"COMMON": 0.65,
	"RARE": 0.25,
	"EPIC": 0.08,
	"LEGENDARY": 0.02
}

# 商店物品费用范围
@export var shop_cost_ranges: Dictionary = {
	"COMMON": [8, 15],
	"RARE": [20, 35],
	"EPIC": [40, 60],
	"LEGENDARY": [80, 120]
}

# 初始槽位容量
@export var initial_artifact_slot_capacity: int = 3
@export var initial_spell_bag_capacity: int = 5
@export var initial_joker_slot_capacity: int = 2

# 初始资源
@export var initial_lore_points: int = 50

# 每学年初始手牌上限调整
@export var year_hand_size_adjustments: Dictionary = {
	1: 0,   # 一年级不调整
	2: 1,   # 二年级+1
	3: 2,   # 三年级+2
	4: 3,   # 四年级+3
	5: 4,   # 五年级+4
	6: 5    # 六年级+5
}

# 学期考核回合数
@export var assessment_turns_by_term: Dictionary = {
	GlobalEnums.TermType.SPRING: 10,
	GlobalEnums.TermType.SUMMER: 12,
	GlobalEnums.TermType.AUTUMN: 15,
	GlobalEnums.TermType.WINTER: 20
}

# 随机事件概率
@export var random_event_chance: float = 0.15  # 每回合15%概率触发随机事件

# 克隆此配置
func clone() -> GameConfigResource:
	var new_config = GameConfigResource.new()
	new_config.victory_score_by_year = victory_score_by_year.duplicate(true)
	new_config.term_rewards_by_type = term_rewards_by_type.duplicate(true)
	new_config.initial_player_hand_size = initial_player_hand_size
	new_config.max_active_spells_per_turn = max_active_spells_per_turn
	new_config.max_discard_redraw_count = max_discard_redraw_count
	new_config.card_type_base_scores = card_type_base_scores.duplicate(true)
	new_config.card_type_level_multipliers = card_type_level_multipliers.duplicate(true)
	new_config.shop_rarity_probabilities = shop_rarity_probabilities.duplicate(true)
	new_config.shop_cost_ranges = shop_cost_ranges.duplicate(true)
	new_config.initial_artifact_slot_capacity = initial_artifact_slot_capacity
	new_config.initial_spell_bag_capacity = initial_spell_bag_capacity
	new_config.initial_joker_slot_capacity = initial_joker_slot_capacity
	new_config.initial_lore_points = initial_lore_points
	new_config.year_hand_size_adjustments = year_hand_size_adjustments.duplicate(true)
	new_config.assessment_turns_by_term = assessment_turns_by_term.duplicate(true)
	new_config.random_event_chance = random_event_chance
	return new_config 
