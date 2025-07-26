class_name GameScoreManager
extends RefCounted

## 游戏得分管理器
##
## 负责管理回合得分和总得分，支持不同来源的得分记录和统计。
## 使用信号系统与UI和其他组件解耦通信。

# 导入依赖
const GameSessionConfigClass = preload("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd")

# 信号
signal score_changed(turn_score: int, total_score: int, source: String)
signal turn_score_reset(previous_turn_score: int)
signal total_score_reset(previous_total_score: int)
signal score_milestone_reached(milestone: int, total_score: int)

# 得分数据
var current_turn_score: int = 0
var total_score: int = 0
var score_history: Array[Dictionary] = []

# 配置
var session_config
var enable_logging: bool = true
var enable_history_tracking: bool = true

# 得分里程碑（用于成就系统）
var score_milestones: Array[int] = [100, 500, 1000, 2500, 5000, 10000]
var reached_milestones: Array[int] = []

func _init():
	# 初始化基本状态
	current_turn_score = 0
	total_score = 0
	score_history = []
	reached_milestones = []
	enable_logging = false
	enable_history_tracking = true

# 使用配置设置管理器
func setup_with_config(config):
	session_config = config
	enable_logging = config.enable_debug_logging
	
	if enable_logging:
		print("GameScoreManager: 配置已设置，得分倍率: %.1f" % config.score_multiplier)

# 添加得分
func add_score(points: int, source: String = "unknown"):
	if not session_config:
		push_error("GameScoreManager: 配置未设置")
		return
	
	# 应用得分倍率
	var actual_points = int(points * session_config.score_multiplier)
	
	# 更新得分
	current_turn_score += actual_points
	total_score += actual_points
	
	# 记录得分历史
	if enable_history_tracking:
		score_history.append({
			"points": actual_points,
			"source": source,
			"timestamp": Time.get_unix_time_from_system(),
			"turn_score_after": current_turn_score,
			"total_score_after": total_score
		})
	
	if enable_logging:
		print("GameScoreManager: 添加得分 %d (来源: %s)，回合得分: %d，总得分: %d" % [
			actual_points, source, current_turn_score, total_score
		])
	
	# 发送信号
	emit_signal("score_changed", current_turn_score, total_score, source)
	
	# 检查里程碑
	_check_milestones()

# 获取当前回合得分
func get_current_turn_score() -> int:
	return current_turn_score

# 获取总得分
func get_total_score() -> int:
	return total_score

# 重置回合得分
func reset_turn_score():
	var previous_score = current_turn_score
	current_turn_score = 0
	
	if enable_logging:
		print("GameScoreManager: 回合得分已重置，之前得分: %d" % previous_score)
	
	emit_signal("turn_score_reset", previous_score)
	emit_signal("score_changed", current_turn_score, total_score, "turn_reset")

# 重置总得分
func reset_total_score():
	var previous_total = total_score
	total_score = 0
	current_turn_score = 0
	reached_milestones.clear()
	
	if enable_history_tracking:
		score_history.clear()
	
	if enable_logging:
		print("GameScoreManager: 总得分已重置，之前得分: %d" % previous_total)
	
	emit_signal("total_score_reset", previous_total)
	emit_signal("score_changed", current_turn_score, total_score, "total_reset")

# 检查得分里程碑
func _check_milestones():
	for milestone in score_milestones:
		if total_score >= milestone and not milestone in reached_milestones:
			reached_milestones.append(milestone)
			emit_signal("score_milestone_reached", milestone, total_score)
			
			if enable_logging:
				print("GameScoreManager: 达成得分里程碑 %d！当前总得分: %d" % [milestone, total_score])

# 获取得分统计信息
func get_score_stats() -> Dictionary:
	var stats = {
		"current_turn_score": current_turn_score,
		"total_score": total_score,
		"score_multiplier": session_config.score_multiplier if session_config else 1.0,
		"total_entries": score_history.size(),
		"reached_milestones": reached_milestones.duplicate(),
		"next_milestone": _get_next_milestone()
	}
	
	# 计算得分来源统计
	var source_stats = {}
	for entry in score_history:
		var source = entry.source
		if source in source_stats:
			source_stats[source] += entry.points
		else:
			source_stats[source] = entry.points
	
	stats["score_by_source"] = source_stats
	return stats

# 获取下一个里程碑
func _get_next_milestone() -> int:
	for milestone in score_milestones:
		if not milestone in reached_milestones:
			return milestone
	return -1  # 所有里程碑都已达成

# 获取得分历史
func get_score_history(limit: int = -1) -> Array:
	if limit <= 0:
		return score_history.duplicate()
	else:
		var start_index = max(0, score_history.size() - limit)
		return score_history.slice(start_index)

# 获取最近的得分记录
func get_recent_scores(count: int = 5) -> Array:
	return get_score_history(count)

# 计算平均得分
func get_average_score_per_entry() -> float:
	if score_history.is_empty():
		return 0.0
	
	return float(total_score) / float(score_history.size())

# 获取最高单次得分
func get_highest_single_score() -> int:
	var highest = 0
	for entry in score_history:
		if entry.points > highest:
			highest = entry.points
	return highest

# 设置自定义里程碑
func set_score_milestones(milestones: Array[int]):
	score_milestones = milestones.duplicate()
	score_milestones.sort()
	
	# 重新检查已达成的里程碑
	reached_milestones.clear()
	_check_milestones()
	
	if enable_logging:
		print("GameScoreManager: 设置得分里程碑: %s" % str(score_milestones))

# 添加里程碑
func add_milestone(milestone: int):
	if not milestone in score_milestones:
		score_milestones.append(milestone)
		score_milestones.sort()
		_check_milestones()

# 获取得分摘要文本
func get_score_summary() -> String:
	var next_milestone = _get_next_milestone()
	var milestone_text = ""
	
	if next_milestone > 0:
		var progress = total_score
		var remaining = next_milestone - progress
		milestone_text = "，距离下个里程碑还需 %d 分" % remaining
	else:
		milestone_text = "，已达成所有里程碑"
	
	return "回合得分: %d，总得分: %d%s" % [current_turn_score, total_score, milestone_text]

# 更新配置
func update_config(new_config):
	setup_with_config(new_config)

# 启用/禁用历史记录
func set_history_tracking_enabled(enabled: bool):
	enable_history_tracking = enabled
	if not enabled:
		score_history.clear()
	
	if enable_logging:
		print("GameScoreManager: 历史记录 %s" % ("启用" if enabled else "禁用"))

# 导出得分数据
func export_score_data() -> Dictionary:
	return {
		"current_turn_score": current_turn_score,
		"total_score": total_score,
		"score_history": score_history.duplicate(),
		"reached_milestones": reached_milestones.duplicate(),
		"config": {
			"score_multiplier": session_config.score_multiplier if session_config else 1.0
		}
	}

# 导入得分数据
func import_score_data(data: Dictionary):
	if "current_turn_score" in data:
		current_turn_score = data.current_turn_score
	if "total_score" in data:
		total_score = data.total_score
	if "score_history" in data:
		score_history = data.score_history
	if "reached_milestones" in data:
		reached_milestones = data.reached_milestones
	
	emit_signal("score_changed", current_turn_score, total_score, "import")
	
	if enable_logging:
		print("GameScoreManager: 导入得分数据完成")
