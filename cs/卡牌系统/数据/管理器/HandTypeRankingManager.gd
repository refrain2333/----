class_name HandTypeRankingManager
extends RefCounted

## 🎯 动态牌型等级管理器
## 
## 核心功能：
## - LV1-LV5等级管理
## - 动态倍率计算
## - 等级升级和持久化
## - 遵循项目架构规范，放置在管理器目录

# 导入依赖
const HandTypeEnumsClass = preload("res://cs/卡牌系统/数据/HandTypeEnums.gd")

# 使用共享的枚举和配置
const HandType = HandTypeEnumsClass.HandType
const HAND_TYPE_NAMES = HandTypeEnumsClass.HAND_TYPE_NAMES
const LEVEL_MULTIPLIERS = HandTypeEnumsClass.LEVEL_MULTIPLIERS

# 当前等级设置（默认全部LV1）
var current_levels: Dictionary = {}

# 信号
signal hand_type_level_changed(hand_type: HandType, old_level: int, new_level: int)
signal hand_type_upgraded(hand_type: HandType, new_level: int, new_multiplier: float)
signal all_levels_reset()

## 🎯 初始化系统
func _init():
	_reset_all_levels()
	print("HandTypeRankingManager: 动态等级系统初始化完成")

## 🎯 重置所有等级为LV1
func _reset_all_levels():
	current_levels.clear()
	for hand_type in LEVEL_MULTIPLIERS.keys():
		current_levels[hand_type] = 1

## 🎯 获取牌型当前等级
func get_hand_type_level(hand_type: HandType) -> int:
	return current_levels.get(hand_type, 1)

## 🎯 设置牌型等级
func set_hand_type_level(hand_type: HandType, level: int) -> bool:
	if not HandTypeEnumsClass.is_valid_level(level):
		push_error("HandTypeRankingManager: 无效等级 %d，必须在1-5之间" % level)
		return false

	if not HandTypeEnumsClass.is_valid_hand_type(hand_type):
		push_error("HandTypeRankingManager: 无效牌型 %d" % hand_type)
		return false
	
	var old_level = current_levels.get(hand_type, 1)
	current_levels[hand_type] = level
	var multiplier = get_multiplier(hand_type)
	
	print("HandTypeRankingManager: %s 设置为 LV%d (%.1fx)" % [
		HAND_TYPE_NAMES.get(hand_type, "未知"),
		level,
		multiplier
	])
	
	# 发送信号
	hand_type_level_changed.emit(hand_type, old_level, level)
	
	return true

## 🎯 升级牌型等级
func level_up_hand_type(hand_type: HandType) -> bool:
	var current_level = get_hand_type_level(hand_type)
	if current_level >= 5:
		print("HandTypeRankingManager: %s 已达到最高等级LV5" % HAND_TYPE_NAMES.get(hand_type, "未知"))
		return false
	
	var success = set_hand_type_level(hand_type, current_level + 1)
	if success:
		var new_multiplier = get_multiplier(hand_type)
		hand_type_upgraded.emit(hand_type, current_level + 1, new_multiplier)
	
	return success

## 🎯 获取动态倍率
func get_multiplier(hand_type: HandType) -> float:
	var level = get_hand_type_level(hand_type)
	return HandTypeEnumsClass.calculate_dynamic_multiplier(hand_type, level)

## 🎯 获取基础倍率（LV1倍率）
func get_base_multiplier(hand_type: HandType) -> float:
	var config = HandTypeEnumsClass.get_level_multiplier_config(hand_type)
	return config[0]

## 🎯 批量设置所有牌型等级
func set_all_levels(level: int) -> bool:
	if not HandTypeEnumsClass.is_valid_level(level):
		push_error("HandTypeRankingManager: 无效等级 %d" % level)
		return false
	
	var count = 0
	for hand_type in LEVEL_MULTIPLIERS.keys():
		current_levels[hand_type] = level
		count += 1
	
	print("HandTypeRankingManager: 批量设置 %d 个牌型为 LV%d" % [count, level])
	all_levels_reset.emit()
	return true

## 🎯 获取所有等级状态
func get_all_levels() -> Dictionary:
	return current_levels.duplicate()

## 🎯 获取等级状态摘要
func get_level_summary() -> String:
	var summary = "牌型等级状态:\n"
	for hand_type in LEVEL_MULTIPLIERS.keys():
		var level = current_levels[hand_type]
		var multiplier = get_multiplier(hand_type)
		var name = HAND_TYPE_NAMES.get(hand_type, "未知")
		summary += "  %s: LV%d (%.1fx)\n" % [name, level, multiplier]
	return summary

## 🎯 获取升级成本信息
func get_upgrade_cost(hand_type: HandType, target_level: int) -> Dictionary:
	var current_level = get_hand_type_level(hand_type)
	if target_level <= current_level:
		return {"cost": 0, "currency": "无需升级"}
	
	# 简化的成本计算（可根据游戏需求调整）
	var cost = (target_level - current_level) * 100
	return {"cost": cost, "currency": "经验值"}

## 🎯 导出等级数据
func export_levels() -> Dictionary:
	return {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"levels": current_levels.duplicate()
	}

## 🎯 导入等级数据
func import_levels(data: Dictionary) -> bool:
	if not data.has("levels"):
		push_error("HandTypeRankingManager: 导入数据缺少levels字段")
		return false
	
	var imported_levels = data.levels
	var valid_count = 0
	
	for hand_type in imported_levels.keys():
		if LEVEL_MULTIPLIERS.has(hand_type):
			var level = imported_levels[hand_type]
			if HandTypeEnumsClass.is_valid_level(level):
				current_levels[hand_type] = level
				valid_count += 1
	
	print("HandTypeRankingManager: 成功导入 %d 个牌型等级设置" % valid_count)
	all_levels_reset.emit()
	return valid_count > 0

## 🎯 获取等级选项列表
static func get_level_options() -> Array:
	var options = []
	for level in range(1, 6):
		options.append({
			"level": level,
			"name": "LV%d" % level,
			"description": "等级 %d" % level
		})
	return options

## 🎯 获取等级描述
func get_level_description(hand_type: HandType, level: int) -> String:
	if not HandTypeEnumsClass.is_valid_level(level):
		return "无效等级"

	if not HandTypeEnumsClass.is_valid_hand_type(hand_type):
		return "无效牌型"

	var multiplier = HandTypeEnumsClass.calculate_dynamic_multiplier(hand_type, level)
	return "LV%d (%.1fx倍率)" % [level, multiplier]

## 🎯 获取系统统计信息
func get_statistics() -> Dictionary:
	var stats = {
		"total_hand_types": LEVEL_MULTIPLIERS.size(),
		"level_distribution": {},
		"average_level": 0.0,
		"average_multiplier": 0.0,
		"max_level": 1,
		"min_level": 5
	}
	
	var total_level = 0
	var total_multiplier = 0.0
	
	for hand_type in current_levels.keys():
		var level = current_levels[hand_type]
		var multiplier = get_multiplier(hand_type)
		
		# 等级分布统计
		if not stats.level_distribution.has(level):
			stats.level_distribution[level] = 0
		stats.level_distribution[level] += 1
		
		# 累计统计
		total_level += level
		total_multiplier += multiplier
		
		# 最大最小等级
		if level > stats.max_level:
			stats.max_level = level
		if level < stats.min_level:
			stats.min_level = level
	
	# 平均值计算
	var count = current_levels.size()
	if count > 0:
		stats.average_level = float(total_level) / count
		stats.average_multiplier = total_multiplier / count
	
	return stats

## 🎯 静态方法：获取基础分数
static func get_base_score(hand_type: HandType) -> int:
	return HandTypeEnumsClass.get_base_score(hand_type)

## 🎯 静态方法：比较两个牌型
static func compare_hands(hand1: Dictionary, hand2: Dictionary) -> int:
	# 首先比较牌型等级
	if hand1.hand_type != hand2.hand_type:
		return hand1.hand_type - hand2.hand_type
	
	# 牌型相同时比较具体数值
	if hand1.primary_value != hand2.primary_value:
		return hand1.primary_value - hand2.primary_value
	
	if hand1.secondary_value != hand2.secondary_value:
		return hand1.secondary_value - hand2.secondary_value
	
	# 比较踢脚牌
	var kickers1 = hand1.get("kickers", [])
	var kickers2 = hand2.get("kickers", [])
	var min_size = min(kickers1.size(), kickers2.size())
	
	for i in range(min_size):
		if kickers1[i] != kickers2[i]:
			return kickers1[i] - kickers2[i]
	
	return 0  # 完全相同

## 🎯 获取牌型强度排名
func get_hand_type_strength_ranking() -> Array:
	var ranking = []
	var all_types = HandTypeEnumsClass.get_all_hand_types()
	
	for hand_type in all_types:
		var level = get_hand_type_level(hand_type)
		var multiplier = get_multiplier(hand_type)
		var base_score = get_base_score(hand_type)
		
		ranking.append({
			"hand_type": hand_type,
			"name": HAND_TYPE_NAMES.get(hand_type, "未知"),
			"level": level,
			"multiplier": multiplier,
			"base_score": base_score,
			"effective_score": base_score * multiplier
		})
	
	# 按有效得分排序
	ranking.sort_custom(func(a, b): return a.effective_score > b.effective_score)
	
	return ranking
