
extends Node

# 游戏状态枚举
enum GameState {
	MAIN_MENU,
	RESEARCH,
	SHOP,
	ASSESSMENT,
	TERM_SUMMARY
}

# 学期类型枚举
enum TermType {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

# 稀有度枚举
enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# 派系类型枚举
enum FactionType {
	ELEMENTAL,    # 元素派系
	RUNE,         # 符文派系
	TIME_SPACE,   # 时空派系
	ARTIFICE      # 工艺派系
}

# 卡牌强化类型
enum CardReinforcementType {
	WAX_SEAL,
	FRAME,
	MATERIAL
}

# 蜡封类型
enum WaxSealType {
	RED,
	BLUE,
	GREEN,
	PURPLE,
	GOLD,
	ORANGE,
	BROWN,
	WHITE
}

# 牌框类型
enum FrameType {
	STONE,
	SILVER,
	GOLD
}

# 材质类型
enum MaterialType {
	GLASS,
	ROCK,
	METAL
}

# 效果触发时机
enum EffectTriggerTiming {
	ON_TURN_START,
	BEFORE_PLAY,
	ON_SCORE_CALCULATION,
	ON_TURN_END,
	ON_DRAW,
	ON_DISCARD,
	ON_DESTROY,
	ON_TERM_START,
	ON_TERM_END,
	ON_PURCHASE,
	ON_SHOP_REFRESH
}

# 法术类型
enum SpellType {
	INSTANT_USE,    # 瞬发法术
	ACTIVE_SKILL    # 技能区法术
}

# 卡牌类型常量 - 使用常量而非枚举，方便直接使用字符串值（符合v1.6规范）
const CARD_TYPE_HIGH_CARD = "HighCard"
const CARD_TYPE_PAIR = "Pair"
const CARD_TYPE_TWO_PAIR = "TwoPair"
const CARD_TYPE_THREE_OF_KIND = "ThreeOfKind"
const CARD_TYPE_STRAIGHT = "Straight"
const CARD_TYPE_FLUSH = "Flush"
const CARD_TYPE_FULL_HOUSE = "FullHouse"
const CARD_TYPE_FOUR_OF_KIND = "FourOfKind"
const CARD_TYPE_STRAIGHT_FLUSH = "StraightFlush"
const CARD_TYPE_ROYAL_FLUSH = "RoyalFlush"

# 功能性方法 - 获取枚举名称
func get_term_name(term_type: int) -> String:
	match term_type:
		TermType.SPRING: return "春季学期"
		TermType.SUMMER: return "夏季学期"
		TermType.AUTUMN: return "秋季学期"
		TermType.WINTER: return "冬季学期"
		_: return "未知学期"

func get_rarity_name(rarity: int) -> String:
	match rarity:
		Rarity.COMMON: return "普通"
		Rarity.RARE: return "稀有"
		Rarity.EPIC: return "史诗"
		Rarity.LEGENDARY: return "传说"
		_: return "未知"

func get_faction_name(faction: int) -> String:
	match faction:
		FactionType.ELEMENTAL: return "元素派系"
		FactionType.RUNE: return "符文派系"
		FactionType.TIME_SPACE: return "时空派系"
		FactionType.ARTIFICE: return "工艺派系"
		_: return "未知派系"

func get_card_type_name(type_string: String) -> String:
	match type_string:
		CARD_TYPE_HIGH_CARD: return "高牌"
		CARD_TYPE_PAIR: return "对子"
		CARD_TYPE_TWO_PAIR: return "两对"
		CARD_TYPE_THREE_OF_KIND: return "三条"
		CARD_TYPE_STRAIGHT: return "顺子"
		CARD_TYPE_FLUSH: return "同花"
		CARD_TYPE_FULL_HOUSE: return "葫芦"
		CARD_TYPE_FOUR_OF_KIND: return "四条"
		CARD_TYPE_STRAIGHT_FLUSH: return "同花顺"
		CARD_TYPE_ROYAL_FLUSH: return "皇家同花顺"
		_: return "未知牌型"

# 牌型类型
enum CardCombinationType {
	HIGH_CARD,     # 高牌
	PAIR,          # 对子
	TWO_PAIR,      # 两对
	THREE_OF_KIND, # 三条
	STRAIGHT,      # 顺子
	FLUSH,         # 同花
	FULL_HOUSE,    # 葫芦
	FOUR_OF_KIND,  # 四条
	STRAIGHT_FLUSH,# 同花顺
	ROYAL_FLUSH    # 皇家同花顺
}

# 事件类型
enum EventType {
	RANDOM,        # 随机事件
	SCHEDULED,     # 计划事件
	TRIGGERED,     # 触发事件
	SHOP,          # 商店事件
	ASSESSMENT,    # 考核事件
	SPECIAL        # 特殊事件
}

# 卡牌类型（基础扑克牌的花色）
enum CardSuit {
	HEARTS,    # 红桃
	DIAMONDS,  # 方片
	CLUBS,     # 梅花
	SPADES     # 黑桃
}

# 获取花色名称
func get_suit_name(suit: CardSuit) -> String:
	match suit:
		CardSuit.HEARTS: return "红桃"
		CardSuit.DIAMONDS: return "方片"
		CardSuit.CLUBS: return "梅花"
		CardSuit.SPADES: return "黑桃"
		_: return "未知花色"

# 获取牌型名称
func get_combination_name(combination: CardCombinationType) -> String:
	match combination:
		CardCombinationType.HIGH_CARD: return "高牌"
		CardCombinationType.PAIR: return "对子"
		CardCombinationType.TWO_PAIR: return "两对"
		CardCombinationType.THREE_OF_KIND: return "三条"
		CardCombinationType.STRAIGHT: return "顺子"
		CardCombinationType.FLUSH: return "同花"
		CardCombinationType.FULL_HOUSE: return "葫芦"
		CardCombinationType.FOUR_OF_KIND: return "四条"
		CardCombinationType.STRAIGHT_FLUSH: return "同花顺"
		CardCombinationType.ROYAL_FLUSH: return "皇家同花顺"
		_: return "未知牌型" 

# === 游戏调试辅助功能 ===
# 根据给定的枚举类型和值返回对应的名称，用于调试输出
func get_enum_name(enum_type: String, value: int) -> String:
	match enum_type:
		"GameState": 
			match value:
				GameState.MAIN_MENU: return "主菜单"
				GameState.RESEARCH: return "研究"
				GameState.SHOP: return "商店"
				GameState.ASSESSMENT: return "考核"
				GameState.TERM_SUMMARY: return "学期总结"
				_: return "未知游戏状态(%d)" % value
		"TermType": return get_term_name(value)
		"Rarity": return get_rarity_name(value)
		"FactionType": return get_faction_name(value)
		"CardSuit": return get_suit_name(value)
		"CardCombinationType": return get_combination_name(value)
		_: return "未知枚举类型: %s, 值: %d" % [enum_type, value]
