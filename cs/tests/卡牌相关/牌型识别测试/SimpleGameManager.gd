class_name HandTypeTestGameManager
extends Node

## 🎯 简单游戏管理器 - 用于出牌系统测试
## 
## 提供基础的游戏管理功能，模拟完整的GameManager行为

# 游戏状态
var game_state: String = "playing"
var current_score: int = 0
var turn_count: int = 0
var actions_remaining: int = 3

# 配置
var card_type_levels: Dictionary = {}
var game_config: Dictionary = {}

# 信号
signal game_state_changed(new_state: String)
signal score_changed(new_score: int)
signal turn_changed(new_turn: int)
signal actions_changed(remaining: int)

## 🎯 初始化
func _ready():
	print("SimpleGameManager: 初始化完成")
	_setup_default_config()

## 🔧 设置默认配置
func _setup_default_config():
	# 默认牌型等级
	card_type_levels = {
		"HIGH_CARD": 1,
		"PAIR": 1,
		"TWO_PAIR": 1,
		"THREE_KIND": 1,
		"STRAIGHT": 1,
		"FLUSH": 1,
		"FULL_HOUSE": 1,
		"FOUR_KIND": 1,
		"STRAIGHT_FLUSH": 1,
		"ROYAL_FLUSH": 1
	}
	
	# 默认游戏配置
	game_config = {
		"max_turns": 10,
		"starting_score": 0,
		"win_condition": 1000,
		"actions_per_turn": 3
	}
	
	actions_remaining = game_config.actions_per_turn

## 🎯 获取牌型等级
func get_card_type_level(card_type: String) -> int:
	return card_type_levels.get(card_type, 1)

## 🎯 设置牌型等级
func set_card_type_level(card_type: String, level: int):
	card_type_levels[card_type] = level
	print("SimpleGameManager: 设置 %s 等级为 %d" % [card_type, level])

## 🎯 添加分数
func add_score(points: int):
	current_score += points
	score_changed.emit(current_score)
	print("SimpleGameManager: 添加 %d 分，总分: %d" % [points, current_score])

## 🎯 使用行动点
func use_action():
	if actions_remaining > 0:
		actions_remaining -= 1
		actions_changed.emit(actions_remaining)
		print("SimpleGameManager: 使用1个行动点，剩余: %d" % actions_remaining)
		return true
	else:
		print("SimpleGameManager: 没有剩余行动点")
		return false

## 🎯 下一回合
func next_turn():
	turn_count += 1
	actions_remaining = game_config.actions_per_turn
	turn_changed.emit(turn_count)
	actions_changed.emit(actions_remaining)
	print("SimpleGameManager: 第 %d 回合开始，行动点重置为 %d" % [turn_count, actions_remaining])

## 🎯 检查游戏结束
func check_game_over() -> bool:
	if current_score >= game_config.win_condition:
		game_state = "won"
		game_state_changed.emit(game_state)
		return true
	elif turn_count >= game_config.max_turns:
		game_state = "lost"
		game_state_changed.emit(game_state)
		return true
	return false

## 🎯 重置游戏
func reset_game():
	current_score = 0
	turn_count = 0
	actions_remaining = game_config.actions_per_turn
	game_state = "playing"
	
	score_changed.emit(current_score)
	turn_changed.emit(turn_count)
	actions_changed.emit(actions_remaining)
	game_state_changed.emit(game_state)
	
	print("SimpleGameManager: 游戏重置")

## 🎯 获取游戏状态
func get_game_state() -> Dictionary:
	return {
		"state": game_state,
		"score": current_score,
		"turn": turn_count,
		"actions_remaining": actions_remaining,
		"max_turns": game_config.max_turns
	}

## 🎯 获取当前分数
func get_current_score() -> int:
	return current_score

## 🎯 获取当前回合
func get_current_turn() -> int:
	return turn_count

## 🎯 获取剩余行动点
func get_actions_remaining() -> int:
	return actions_remaining

## 🎯 是否可以执行行动
func can_perform_action() -> bool:
	return actions_remaining > 0 and game_state == "playing"

## 🎯 获取游戏配置
func get_game_config() -> Dictionary:
	return game_config.duplicate()

## 🎯 设置游戏配置
func set_game_config(new_config: Dictionary):
	for key in new_config:
		if game_config.has(key):
			game_config[key] = new_config[key]
	print("SimpleGameManager: 游戏配置已更新")

## 🎯 获取状态摘要
func get_status_summary() -> String:
	return "回合 %d/%d | 分数: %d | 行动点: %d/%d | 状态: %s" % [
		turn_count, 
		game_config.max_turns, 
		current_score, 
		actions_remaining, 
		game_config.actions_per_turn,
		game_state
	]
