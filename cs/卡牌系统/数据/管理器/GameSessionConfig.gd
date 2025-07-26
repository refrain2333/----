class_name GameSessionConfig
extends Resource

## 游戏会话配置资源
## 
## 定义游戏会话中的各种规则和限制参数，支持不同难度和模式的配置。
## 通过继承Resource，可以序列化为.tres文件，便于管理和修改。

# 回合制操作限制配置
@export_group("回合制操作限制")
@export var max_play_actions_per_turn: int = 3 : set = set_max_play_actions
@export var max_discard_actions_per_turn: int = 2 : set = set_max_discard_actions
@export var enable_action_limits: bool = true

# 手牌配置
@export_group("手牌管理")
@export var initial_hand_size: int = 5 : set = set_initial_hand_size
@export var max_hand_size: int = 8 : set = set_max_hand_size
@export var auto_refill_hand: bool = true
@export var refill_delay: float = 0.5

# 得分配置
@export_group("得分系统")
@export var enable_turn_score_tracking: bool = true
@export var score_multiplier: float = 1.0 : set = set_score_multiplier
@export var reset_turn_score_on_new_turn: bool = true

# 牌库配置
@export_group("牌库管理")
@export var enable_deck_view: bool = true
@export var auto_update_deck_view: bool = true
@export var deck_view_update_delay: float = 0.1

# 调试配置
@export_group("调试选项")
@export var enable_debug_logging: bool = false
@export var show_action_counts: bool = true

# 配置验证
func _init():
	_validate_config()

# 验证配置参数的合理性
func _validate_config():
	if max_play_actions_per_turn < 0:
		max_play_actions_per_turn = 0
		push_warning("GameSessionConfig: max_play_actions_per_turn 不能为负数，已重置为0")
	
	if max_discard_actions_per_turn < 0:
		max_discard_actions_per_turn = 0
		push_warning("GameSessionConfig: max_discard_actions_per_turn 不能为负数，已重置为0")
	
	if initial_hand_size < 0:
		initial_hand_size = 0
		push_warning("GameSessionConfig: initial_hand_size 不能为负数，已重置为0")
	
	if max_hand_size < initial_hand_size:
		max_hand_size = initial_hand_size
		push_warning("GameSessionConfig: max_hand_size 不能小于 initial_hand_size，已调整")
	
	if score_multiplier < 0:
		score_multiplier = 0.0
		push_warning("GameSessionConfig: score_multiplier 不能为负数，已重置为0")

# Setter方法，确保参数合理性
func set_max_play_actions(value: int):
	max_play_actions_per_turn = max(0, value)

func set_max_discard_actions(value: int):
	max_discard_actions_per_turn = max(0, value)

func set_initial_hand_size(value: int):
	initial_hand_size = max(0, value)
	if max_hand_size < initial_hand_size:
		max_hand_size = initial_hand_size

func set_max_hand_size(value: int):
	max_hand_size = max(initial_hand_size, value)

func set_score_multiplier(value: float):
	score_multiplier = max(0.0, value)

# 获取配置摘要
func get_config_summary() -> String:
	return "GameSessionConfig: 出牌%d次/回合, 弃牌%d次/回合, 手牌%d-%d张, 得分倍率%.1f" % [
		max_play_actions_per_turn, max_discard_actions_per_turn, 
		initial_hand_size, max_hand_size, score_multiplier
	]

# 创建默认配置
static func create_default():
	var config = load("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd").new()
	config.max_play_actions_per_turn = 3
	config.max_discard_actions_per_turn = 2
	config.initial_hand_size = 5
	config.max_hand_size = 8
	config.score_multiplier = 1.0
	config.enable_action_limits = true
	config.auto_refill_hand = true
	return config

# 创建简单模式配置
static func create_easy_mode():
	var config = create_default()
	config.max_play_actions_per_turn = 5
	config.max_discard_actions_per_turn = 3
	config.score_multiplier = 1.2
	return config

# 创建困难模式配置
static func create_hard_mode():
	var config = create_default()
	config.max_play_actions_per_turn = 2
	config.max_discard_actions_per_turn = 1
	config.score_multiplier = 0.8
	return config

# 克隆配置
func clone():
	var new_config = load("res://cs/卡牌系统/数据/管理器/GameSessionConfig.gd").new()
	new_config.max_play_actions_per_turn = max_play_actions_per_turn
	new_config.max_discard_actions_per_turn = max_discard_actions_per_turn
	new_config.initial_hand_size = initial_hand_size
	new_config.max_hand_size = max_hand_size
	new_config.auto_refill_hand = auto_refill_hand
	new_config.refill_delay = refill_delay
	new_config.enable_turn_score_tracking = enable_turn_score_tracking
	new_config.score_multiplier = score_multiplier
	new_config.reset_turn_score_on_new_turn = reset_turn_score_on_new_turn
	new_config.enable_deck_view = enable_deck_view
	new_config.auto_update_deck_view = auto_update_deck_view
	new_config.deck_view_update_delay = deck_view_update_delay
	new_config.enable_debug_logging = enable_debug_logging
	new_config.show_action_counts = show_action_counts
	new_config.enable_action_limits = enable_action_limits
	return new_config
