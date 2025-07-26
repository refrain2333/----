class_name CardEffectManagerData
extends Node

# 修改类名以避免冲突
# 原类名: CardEffectManager

# 信号
signal effect_triggered(card_data, effect_type, effect_params)

# 蜡封类型和效果映射
const WAX_SEAL_EFFECTS = {
	"RED": {"effect": "damage", "value": 2},           # 红色蜡封：造成伤害
	"BLUE": {"effect": "draw", "value": 1},            # 蓝色蜡封：抽牌
	"PURPLE": {"effect": "transform", "target": "random"}, # 紫色蜡封：变形
	"GOLD": {"effect": "score", "value": 5},           # 金色蜡封：额外分数
	"GREEN": {"effect": "heal", "value": 3},           # 绿色蜡封：治疗
	"ORANGE": {"effect": "burn", "turns": 2},          # 橙色蜡封：持续伤害
	"BROWN": {"effect": "earth", "value": 1},          # 棕色蜡封：土元素效果
	"WHITE": {"effect": "enhance", "target": "next"}   # 白色蜡封：增强下一张牌
}

# 牌框类型和效果映射
const FRAME_EFFECTS = {
	"STONE": {"effect": "value_boost", "value": 2},    # 石质框架：提高卡牌值
	"SILVER": {"effect": "element_boost", "multiplier": 1.5}, # 银质框架：增强元素效果
	"GOLD": {"effect": "double", "chance": 0.2}        # 金质框架：概率双重效果
}

# 材质类型和效果映射
const MATERIAL_EFFECTS = {
	"GLASS": {"effect": "bypass", "chance": 0.3},      # 玻璃材质：概率无视防御
	"ROCK": {"effect": "defense", "value": 3},         # 岩石材质：增加防御
	"METAL": {"effect": "reflect", "percent": 0.2}     # 金属材质：反弹伤害
}

# 游戏管理器引用
var game_manager

func _ready():
	pass

# 设置游戏管理器
func setup(manager):
	game_manager = manager

# 处理卡牌的所有强化效果
func process_card_effects(card_data: CardData, target = null) -> Dictionary:
	var result = {
		"effects": [],
		"value_change": 0,
		"score_bonus": 0
	}
	
	# 1. 处理蜡封效果
	if "wax_seals" in card_data and card_data.wax_seals:
		for seal_type in card_data.wax_seals:
			var effect_result = _process_wax_seal_effect(seal_type, card_data, target)
			if effect_result:
				result.effects.append(effect_result)

				# 更新值变化和分数奖励
			if "value_change" in effect_result:
				result.value_change += effect_result.value_change
			if "score_bonus" in effect_result:
				result.score_bonus += effect_result.score_bonus
	
	# 2. 处理框架效果
	if card_data.frame_type != "":
		var frame_result = _process_frame_effect(card_data.frame_type, card_data, target)
		if frame_result:
			result.effects.append(frame_result)
			
			# 更新值变化和分数奖励
			if "value_change" in frame_result:
				result.value_change += frame_result.value_change
			if "score_bonus" in frame_result:
				result.score_bonus += frame_result.score_bonus
	
	# 3. 处理材质效果
	if card_data.material_type != "":
		var material_result = _process_material_effect(card_data.material_type, card_data, target)
		if material_result:
			result.effects.append(material_result)
			
			# 更新值变化和分数奖励
			if "value_change" in material_result:
				result.value_change += material_result.value_change
			if "score_bonus" in material_result:
				result.score_bonus += material_result.score_bonus
	
	return result

# 处理蜡封效果
func _process_wax_seal_effect(seal_type: String, card_data: CardData, target = null) -> Dictionary:
	if not seal_type in WAX_SEAL_EFFECTS:
		return {}
	
	var effect_data = WAX_SEAL_EFFECTS[seal_type]
	var result = {
		"type": "wax_seal",
		"seal_type": seal_type,
		"effect_name": effect_data.effect
	}
	
	match effect_data.effect:
		"damage":
			result["damage"] = effect_data.value
			emit_signal("effect_triggered", card_data, "damage", {"value": effect_data.value, "target": target})
			
		"draw":
			result["cards"] = effect_data.value
			emit_signal("effect_triggered", card_data, "draw", {"count": effect_data.value})
			
		"transform":
			result["transform_target"] = effect_data.target
			emit_signal("effect_triggered", card_data, "transform", {"target": effect_data.target})
			
		"score":
			result["score_bonus"] = effect_data.value
			emit_signal("effect_triggered", card_data, "score", {"value": effect_data.value})
			
		"heal":
			result["heal"] = effect_data.value
			emit_signal("effect_triggered", card_data, "heal", {"value": effect_data.value})
			
		"burn":
			result["burn_turns"] = effect_data.turns
			emit_signal("effect_triggered", card_data, "burn", {"turns": effect_data.turns, "target": target})
			
		"earth":
			result["earth"] = effect_data.value
			emit_signal("effect_triggered", card_data, "earth", {"value": effect_data.value})
			
		"enhance":
			result["enhance_target"] = effect_data.target
			emit_signal("effect_triggered", card_data, "enhance", {"target": effect_data.target})
	
	return result

# 处理框架效果
func _process_frame_effect(frame_type: String, card_data: CardData, target = null) -> Dictionary:
	if not frame_type in FRAME_EFFECTS:
		return {}
	
	var effect_data = FRAME_EFFECTS[frame_type]
	var result = {
		"type": "frame",
		"frame_type": frame_type,
		"effect_name": effect_data.effect
	}
	
	match effect_data.effect:
		"value_boost":
			result["value_change"] = effect_data.value
			result["original_value"] = card_data.base_value
			result["new_value"] = card_data.base_value + effect_data.value
			emit_signal("effect_triggered", card_data, "value_boost", {"value": effect_data.value})
			
		"element_boost":
			result["multiplier"] = effect_data.multiplier
			emit_signal("effect_triggered", card_data, "element_boost", {"multiplier": effect_data.multiplier})
			
		"double":
			# 概率触发双重效果
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			if rng.randf() <= effect_data.chance:
				result["double_activated"] = true
				emit_signal("effect_triggered", card_data, "double", {"activated": true})
			else:
				result["double_activated"] = false
	
	return result

# 处理材质效果
func _process_material_effect(material_type: String, card_data: CardData, target = null) -> Dictionary:
	if not material_type in MATERIAL_EFFECTS:
		return {}
	
	var effect_data = MATERIAL_EFFECTS[material_type]
	var result = {
		"type": "material",
		"material_type": material_type,
		"effect_name": effect_data.effect
	}
	
	match effect_data.effect:
		"bypass":
			# 概率无视防御
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			if rng.randf() <= effect_data.chance:
				result["bypass_activated"] = true
				emit_signal("effect_triggered", card_data, "bypass", {"activated": true, "target": target})
			else:
				result["bypass_activated"] = false
			
		"defense":
			result["defense"] = effect_data.value
			emit_signal("effect_triggered", card_data, "defense", {"value": effect_data.value})
			
		"reflect":
			result["reflect_percent"] = effect_data.percent
			emit_signal("effect_triggered", card_data, "reflect", {"percent": effect_data.percent})
	
	return result 