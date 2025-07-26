class_name JokerData
extends Resource

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 守护灵基本属性（符合v1.6规范）
@export var id: String = ""               # 例如 "JOKER_TIME_WIZARD"
@export var name: String = ""             # 例如 "时间术士"
@export var description: String = ""      # 用于UI显示的描述文本
@export var cost: int = 0                 # 购买费用

# 效果属性（符合v1.6规范）
@export var effect_type: String = ""      # 例如 "ADD_XP_PER_PAIR"
@export var effect_value = null           # 效果参数

# 守护灵特有属性（符合v1.6规范）
@export var trigger_timing: int = GlobalEnums.EffectTriggerTiming.ON_SCORE_CALCULATION # 触发时机

# 获取守护灵描述文本
func get_description() -> String:
	var timing_text = _get_timing_text(trigger_timing)
	return timing_text + " " + description

# 获取守护灵信息
func get_info() -> String:
	var timing_text = _get_timing_text(trigger_timing, false)
	return name + " (触发:" + timing_text + ", 价格:" + str(cost) + ")"

# 获取触发时机文本表示
func _get_timing_text(timing: int, with_brackets: bool = true) -> String:
	var text = ""
	
	match timing:
		GlobalEnums.EffectTriggerTiming.ON_TURN_START:
			text = "回合开始"
		GlobalEnums.EffectTriggerTiming.BEFORE_PLAY:
			text = "打牌前"
		GlobalEnums.EffectTriggerTiming.ON_SCORE_CALCULATION:
			text = "计分时"
		GlobalEnums.EffectTriggerTiming.ON_DRAW:
			text = "抽牌时"
		GlobalEnums.EffectTriggerTiming.ON_DISCARD:
			text = "弃牌时"
		_:
			text = "未知时机"
	
	if with_brackets:
		return "[" + text + "]"
	else:
		return text

# 克隆守护灵数据
func clone() -> JokerData:
	var new_joker = JokerData.new()
	new_joker.id = id
	new_joker.name = name
	new_joker.description = description
	new_joker.cost = cost
	new_joker.effect_type = effect_type
	new_joker.effect_value = effect_value
	new_joker.trigger_timing = trigger_timing
	return new_joker