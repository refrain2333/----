class_name HandTypeEnums
extends RefCounted

## 🎯 牌型枚举和常量定义
##
## 集中定义所有牌型相关的枚举、常量和配置数据，
## 避免循环依赖，为牌型识别系统提供统一的数据源。
##
## 功能特性：
## - 完整的牌型枚举定义（高牌到五条）
## - 动态等级系统配置（LV1-LV5）
## - 基础分值和倍率配置
## - 支持皇家同花顺等特殊牌型

# 牌型枚举（按强度从低到高）
enum HandType {
	HIGH_CARD = 1,        # 高牌
	PAIR = 2,             # 一对
	TWO_PAIR = 3,         # 两对
	THREE_KIND = 4,       # 三条
	STRAIGHT = 5,         # 顺子
	FLUSH = 6,            # 同花
	FULL_HOUSE = 7,       # 葫芦
	FOUR_KIND = 8,        # 四条
	STRAIGHT_FLUSH = 9,   # 同花顺
	ROYAL_FLUSH = 10,     # 皇家同花顺
	FIVE_KIND = 11        # 五条（特殊牌型）
}

# 牌型名称映射
const HAND_TYPE_NAMES = {
	HandType.HIGH_CARD: "高牌",
	HandType.PAIR: "一对",
	HandType.TWO_PAIR: "两对",
	HandType.THREE_KIND: "三条",
	HandType.STRAIGHT: "顺子",
	HandType.FLUSH: "同花",
	HandType.FULL_HOUSE: "葫芦",
	HandType.FOUR_KIND: "四条",
	HandType.STRAIGHT_FLUSH: "同花顺",
	HandType.ROYAL_FLUSH: "皇家同花顺",
	HandType.FIVE_KIND: "五条"
}

# 牌型基础分值
const BASE_SCORES = {
	HandType.HIGH_CARD: 1,
	HandType.PAIR: 2,
	HandType.TWO_PAIR: 3,
	HandType.THREE_KIND: 5,
	HandType.STRAIGHT: 8,
	HandType.FLUSH: 13,
	HandType.FULL_HOUSE: 21,
	HandType.FOUR_KIND: 34,
	HandType.STRAIGHT_FLUSH: 55,
	HandType.ROYAL_FLUSH: 89,
	HandType.FIVE_KIND: 144
}

# 等级倍率配置（按照规范文档）
const LEVEL_MULTIPLIERS = {
	# 牌型: [LV1倍率, 每级增量]
	HandType.HIGH_CARD: [1.0, 0.2],      # 1.0x → 1.8x
	HandType.PAIR: [1.5, 0.3],           # 1.5x → 2.7x
	HandType.TWO_PAIR: [2.0, 0.4],       # 2.0x → 3.6x
	HandType.THREE_KIND: [3.0, 0.6],     # 3.0x → 5.4x
	HandType.STRAIGHT: [4.0, 0.8],       # 4.0x → 7.2x
	HandType.FLUSH: [5.0, 1.0],          # 5.0x → 9.0x
	HandType.FULL_HOUSE: [7.0, 1.4],     # 7.0x → 12.6x
	HandType.FOUR_KIND: [10.0, 2.0],     # 10.0x → 18.0x
	HandType.STRAIGHT_FLUSH: [15.0, 3.0], # 15.0x → 27.0x
	HandType.ROYAL_FLUSH: [25.0, 5.0],   # 25.0x → 45.0x
	HandType.FIVE_KIND: [50.0, 10.0]     # 50.0x → 90.0x
}

## 🎯 辅助方法

## 验证等级有效性
static func is_valid_level(level: int) -> bool:
	return level >= 1 and level <= 5

## 验证牌型有效性
static func is_valid_hand_type(hand_type: HandType) -> bool:
	return LEVEL_MULTIPLIERS.has(hand_type)

## 计算动态倍率
static func calculate_dynamic_multiplier(hand_type: HandType, level: int) -> float:
	if not is_valid_hand_type(hand_type) or not is_valid_level(level):
		return 1.0

	var config = LEVEL_MULTIPLIERS[hand_type]
	var base_multiplier = config[0]
	var level_increment = config[1]

	# 动态倍率 = 基础倍率 + (当前等级 - 1) × 等级增量
	return base_multiplier + (level - 1) * level_increment

## 获取等级倍率配置
static func get_level_multiplier_config(hand_type: HandType) -> Array:
	return LEVEL_MULTIPLIERS.get(hand_type, [1.0, 0.0])

## 获取基础分数
static func get_base_score(hand_type: HandType) -> int:
	return BASE_SCORES.get(hand_type, 1)

## 获取所有牌型
static func get_all_hand_types() -> Array:
	return LEVEL_MULTIPLIERS.keys()

## 获取牌型英文名称
static func get_hand_type_english_name(hand_type: HandType) -> String:
	match hand_type:
		HandType.HIGH_CARD: return "HIGH_CARD"
		HandType.PAIR: return "PAIR"
		HandType.TWO_PAIR: return "TWO_PAIR"
		HandType.THREE_KIND: return "THREE_KIND"
		HandType.STRAIGHT: return "STRAIGHT"
		HandType.FLUSH: return "FLUSH"
		HandType.FULL_HOUSE: return "FULL_HOUSE"
		HandType.FOUR_KIND: return "FOUR_KIND"
		HandType.STRAIGHT_FLUSH: return "STRAIGHT_FLUSH"
		HandType.ROYAL_FLUSH: return "ROYAL_FLUSH"
		HandType.FIVE_KIND: return "FIVE_KIND"
		_: return "UNKNOWN"

## 获取牌型中文名称
static func get_hand_type_chinese_name(hand_type: HandType) -> String:
	return HAND_TYPE_NAMES.get(hand_type, "未知牌型")

## 比较牌型强度
static func compare_hand_types(type1: HandType, type2: HandType) -> int:
	return int(type1) - int(type2)
