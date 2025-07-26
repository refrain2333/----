class_name TurnActionManager
extends Node

## 回合制操作限制管理器
##
## 负责管理每回合的操作次数限制，如出牌次数、弃牌次数等。
## 支持动态配置和扩展，通过信号与其他系统解耦通信。

# 导入依赖
const GameSessionConfigClass = preload("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd")

# 信号
signal action_performed(action_type: String, remaining_count: int, total_limit: int)
signal action_limit_reached(action_type: String, current_count: int)
signal turn_actions_reset()
signal action_limits_updated(action_limits: Dictionary)

# 配置
var session_config
var action_counts: Dictionary = {}
var action_limits: Dictionary = {}

# 常用操作类型常量
const ACTION_PLAY = "play"
const ACTION_DISCARD = "discard"

# 调试选项
var enable_logging: bool = true

func _init():
	# 初始化基本状态
	action_counts = {}
	action_limits = {}
	enable_logging = false

# 使用配置设置管理器
func setup_with_config(config):
	session_config = config
	enable_logging = config.enable_debug_logging
	
	# 设置操作限制
	action_limits[ACTION_PLAY] = config.max_play_actions_per_turn
	action_limits[ACTION_DISCARD] = config.max_discard_actions_per_turn
	
	# 重置操作计数
	reset_turn_actions()
	
	if enable_logging:
		print("TurnActionManager: 配置已设置 - %s" % config.get_config_summary())
	
	emit_signal("action_limits_updated", action_limits)

# 检查是否可以执行指定操作
func can_perform_action(action_type: String) -> bool:
	if not session_config.enable_action_limits:
		return true
	
	if not action_type in action_limits:
		if enable_logging:
			push_warning("TurnActionManager: 未知操作类型: %s" % action_type)
		return false
	
	var current_count = action_counts.get(action_type, 0)
	var limit = action_limits[action_type]
	
	return current_count < limit

# 执行操作（增加计数）
func perform_action(action_type: String) -> bool:
	if not can_perform_action(action_type):
		var current_count = action_counts.get(action_type, 0)
		emit_signal("action_limit_reached", action_type, current_count)
		
		if enable_logging:
			print("TurnActionManager: 操作限制已达到 - %s (%d/%d)" % [
				action_type, current_count, action_limits.get(action_type, 0)
			])
		return false
	
	# 增加操作计数
	if not action_type in action_counts:
		action_counts[action_type] = 0
	
	action_counts[action_type] += 1
	
	var current_count = action_counts[action_type]
	var limit = action_limits[action_type]
	var remaining = limit - current_count
	
	emit_signal("action_performed", action_type, remaining, limit)
	
	if enable_logging:
		print("TurnActionManager: 执行操作 %s (%d/%d，剩余%d次)" % [
			action_type, current_count, limit, remaining
		])
	
	# 检查是否达到限制
	if remaining <= 0:
		emit_signal("action_limit_reached", action_type, current_count)
	
	return true

# 获取剩余操作次数
func get_remaining_actions(action_type: String) -> int:
	if not session_config.enable_action_limits:
		return 999  # 无限制时返回大数
	
	if not action_type in action_limits:
		return 0
	
	var current_count = action_counts.get(action_type, 0)
	var limit = action_limits[action_type]
	return max(0, limit - current_count)

# 获取当前操作次数
func get_current_actions(action_type: String) -> int:
	return action_counts.get(action_type, 0)

# 获取操作限制
func get_action_limit(action_type: String) -> int:
	return action_limits.get(action_type, 0)

# 重置回合操作计数
func reset_turn_actions():
	action_counts.clear()
	
	if enable_logging:
		print("TurnActionManager: 回合操作计数已重置")
	
	emit_signal("turn_actions_reset")

# 动态设置操作限制
func set_action_limit(action_type: String, limit: int):
	action_limits[action_type] = max(0, limit)
	
	if enable_logging:
		print("TurnActionManager: 设置操作限制 %s = %d" % [action_type, limit])
	
	emit_signal("action_limits_updated", action_limits)

# 添加新的操作类型
func add_action_type(action_type: String, limit: int):
	set_action_limit(action_type, limit)

# 移除操作类型
func remove_action_type(action_type: String):
	if action_type in action_limits:
		action_limits.erase(action_type)
	if action_type in action_counts:
		action_counts.erase(action_type)
	
	if enable_logging:
		print("TurnActionManager: 移除操作类型 %s" % action_type)
	
	emit_signal("action_limits_updated", action_limits)

# 获取所有操作状态
func get_all_action_status() -> Dictionary:
	var status = {}
	for action_type in action_limits.keys():
		status[action_type] = {
			"current": get_current_actions(action_type),
			"limit": get_action_limit(action_type),
			"remaining": get_remaining_actions(action_type),
			"can_perform": can_perform_action(action_type)
		}
	return status

# 获取状态摘要文本
func get_status_summary() -> String:
	var parts = []
	for action_type in action_limits.keys():
		var current = get_current_actions(action_type)
		var limit = get_action_limit(action_type)
		parts.append("%s: %d/%d" % [action_type, current, limit])
	
	return "操作状态: " + ", ".join(parts)

# 更新配置
func update_config(new_config):
	setup_with_config(new_config)

# 启用/禁用操作限制
func set_action_limits_enabled(enabled: bool):
	if session_config:
		session_config.enable_action_limits = enabled
		
		if enable_logging:
			print("TurnActionManager: 操作限制 %s" % ("启用" if enabled else "禁用"))

# 检查是否启用了操作限制
func is_action_limits_enabled() -> bool:
	return session_config and session_config.enable_action_limits
