class_name CardEffectController
extends Node

# =====================================================
# 警告：此类已重命名为CardEffectController
# 原CardEffectManager类名现在指向/cs/卡牌系统/数据/管理器/CardEffectManager.gd
# =====================================================

# 信号
signal effect_triggered(card_data, effect_type, params)
signal effect_applied(card_data, effect_result)

# 效果接口预加载
var fire_element_effect = preload("res://cs/卡牌系统/接口/FireElementEffect.gd")
var freeze_effect = preload("res://cs/卡牌系统/接口/FreezeEffect.gd")

# 用于存储每次打出卡牌时使用的蜡封效果，避免重复触发
var _used_wax_seals: Dictionary = {}

# 重置状态，每回合开始时调用
func reset_state() -> void:
	_used_wax_seals.clear()

# 处理蜡封效果
func process_wax_seal_effects(card: CardData, game_manager) -> void:
	if not card or card.wax_seal_types.is_empty():
		return
		
	for seal_type in card.wax_seal_types:
		# 避免重复处理同一张卡的同一类蜡封
		var card_seal_key = card.card_id + "_" + seal_type
		if _used_wax_seals.has(card_seal_key):
			continue
			
		_used_wax_seals[card_seal_key] = true
		
		# 根据蜡封类型应用效果
		match seal_type:
			"RED": # 红色蜡封
				# 额外获得10点学识点
				game_manager.add_lore(10)
				print("红色蜡封效果: +10学识点")
				
			"BLUE": # 蓝色蜡封
				# 立即从牌库抽一张牌
				game_manager.get_node("CardManager").draw_card(1, true)
				print("蓝色蜡封效果: 抽1张牌")
				
			"PURPLE": # 紫色蜡封
				# 本回合基础分数+20
				game_manager.add_term_buff({"type": "BASE_SCORE_BONUS", "value": 20})
				print("紫色蜡封效果: 本回合基础分数+20")
				
			"GOLD": # 金色蜡封
				# 复制卡牌效果
				var effect_data = {"card_id": card.id, "type": "GOLD_WAX_COPY"}
				game_manager.register_gold_seal_effect(effect_data)
				print("金色蜡封效果: 卡牌效果复制")
				
			"GREEN": # 绿色蜡封
				# 牌库顶部的下一张牌获得随机蜡封
				_apply_random_wax_seal_to_top_card(game_manager)
				print("绿色蜡封效果: 顶部牌获得随机蜡封")
				
			"ORANGE": # 橙色蜡封
				# 本回合抽牌上限+1
				game_manager.add_turn_buff({"type": "DRAW_LIMIT_BONUS", "value": 1})
				print("橙色蜡封效果: 本回合抽牌上限+1")
				
			"BROWN": # 棕色蜡封
				# 50%几率获得15点学识点
				if randf() <= 0.5:
					game_manager.add_lore(15)
					print("棕色蜡封效果: 触发成功! +15学识点")
				else:
					print("棕色蜡封效果: 触发失败")
					
			"WHITE": # 白色蜡封
				# 法术背包中所有法术费用-1
				game_manager.add_turn_buff({"type": "SPELL_COST_REDUCTION", "value": 1})
				print("白色蜡封效果: 本回合法术费用-1")
				
			_:
				print("未知蜡封类型: ", seal_type)
		
		# 蜡封是一次性的，触发后移除
		card.remove_wax_seal(seal_type)

# 应用牌框效果
func apply_frame_effect(card: CardData, base_value: int) -> int:
	if not card or card.frame_type.is_empty():
		return base_value
		
	var modified_value = base_value
	
	match card.frame_type:
		"STONE": # 石质牌框
			# 基础点数+2
			modified_value += 2
			print("石质牌框效果: 基础点数+2")
			
		"SILVER": # 银质牌框
			# 防止销毁（在处理摧毁逻辑时使用）
			# 这里不需要修改点数
			print("银质牌框效果: 防止被销毁")
			
		"GOLD": # 黄金牌框
			# 最终得分倍率x1.5 (在ScoreCalculator中处理)
			print("黄金牌框效果: 将在计分时提供1.5倍率")
			
		_:
			print("未知牌框类型: ", card.frame_type)
	
	return modified_value

# 处理材质效果
func process_material_effect(card: CardData, game_manager) -> bool:
	if not card or card.material_type.is_empty():
		return false
		
	var card_destroyed = false
	
	match card.material_type:
		"GLASS": # 玻璃材质
			# 1/4几率被销毁，除非有银质牌框
			if card.frame_type != "SILVER" and randf() <= 0.25:
				# 将卡牌销毁
				game_manager.get_node("CardManager").destroy_card(card)
				card_destroyed = true
				print("玻璃材质效果: 卡牌被销毁")
			else:
				# 基础效果翻倍 - 在ScoreCalculator中处理
				print("玻璃材质效果: 卡牌安全，基础效果将翻倍")
				
		"ROCK": # 岩石材质
			# 使用后返回牌库底部而非弃牌堆
			game_manager.get_node("CardManager").add_card_to_bottom_of_deck(card.clone())
			print("岩石材质效果: 卡牌将返回牌库底部")
			
		"METAL": # 金属材质
			# 在手牌中时每回合提供1点学识点，这部分在GameManager回合开始时处理
			print("金属材质效果: 已在回合开始时提供学识点")
			
		_:
			print("未知材质类型: ", card.material_type)
	
	return card_destroyed

# 为牌库顶部的卡牌添加随机蜡封
func _apply_random_wax_seal_to_top_card(game_manager) -> void:
	var card_manager = game_manager.get_node("CardManager")
	if not card_manager:
		return
		
	var top_card = card_manager.peek_top_card()
	if not top_card:
		return
		
	# 可用的蜡封类型
	var wax_seal_types = ["RED", "BLUE", "PURPLE", "GOLD", "GREEN", "ORANGE", "BROWN", "WHITE"]
	
	# 随机选择一种蜡封
	var random_seal = wax_seal_types[randi() % wax_seal_types.size()]
	
	# 添加蜡封
	top_card.add_reinforcement("WAX_SEAL", random_seal)
	print("为牌库顶部的卡牌添加了", random_seal, "蜡封")

# 检查卡牌是否有金属材质（用于回合开始检查）
func check_metal_material_in_hand(hand_cards: Array[CardData], game_manager) -> void:
	var metal_count = 0
	
	for card in hand_cards:
		if card.material_type == "METAL":
			metal_count += 1
	
	if metal_count > 0:
		var lore_gain = metal_count * 1  # 每张金属材质牌提供1点学识点
		game_manager.add_lore(lore_gain)
		print("金属材质效果: 从", metal_count, "张卡牌获得", lore_gain, "点学识点")

# 卡牌在分数计算中是否有额外倍率
func get_card_score_multiplier(card: CardData) -> float:
	if not card:
		return 1.0
		
	var multiplier = 1.0
	
	# 黄金牌框提供1.5倍率
	if card.frame_type == "GOLD":
		multiplier *= 1.5
		
	return multiplier
	
# 获取玻璃材质的基础值倍率
func get_glass_material_value_multiplier(card: CardData) -> float:
	if card and card.material_type == "GLASS":
		# 玻璃材质的基础效果翻倍
		return 2.0
	return 1.0

# 处理卡牌效果
func process_card_effects(card_data, context = null):
	print("CardEffectManager: 处理卡牌效果 - " + card_data.name)
	
	var result = {
		"effects": [],
		"score_bonus": 0
	}
	
	# 检查卡牌是否有强化级别
	if not card_data.has("reinforcement_level") or card_data.reinforcement_level <= 0:
		return result
	
	# 基于卡牌类型和强化级别处理效果
	match card_data.reinforcement_level:
		1: # 石质
			result.score_bonus += 1
			var effect = {
				"type": "score_bonus",
				"value": 1,
				"source": card_data
			}
			result.effects.append(effect)
			
		2: # 银质
			result.score_bonus += 2
			var effect = {
				"type": "score_bonus",
				"value": 2,
				"source": card_data
			}
			result.effects.append(effect)
			
			# 添加特殊效果
			if card_data.suit == "hearts":
				# 红桃牌增加生命值
				var heal_effect = {
					"type": "heal",
					"value": 1,
					"source": card_data
				}
				result.effects.append(heal_effect)
				emit_signal("effect_triggered", card_data, "heal", {"value": 1})
				
			elif card_data.suit == "diamonds":
				# 方块牌增加额外分数
				var diamond_effect = {
					"type": "score_bonus_extra",
					"value": 1,
					"source": card_data
				}
				result.effects.append(diamond_effect)
				result.score_bonus += 1

			elif card_data.suit == "clubs":
				# 梅花牌增加防御
				var defense_effect = {
					"type": "defense",
					"value": 1,
					"source": card_data
				}
				result.effects.append(defense_effect)
				emit_signal("effect_triggered", card_data, "defense", {"value": 1})

			elif card_data.suit == "spades":
				# 黑桃牌造成伤害
				var damage_effect = {
					"type": "damage",
					"value": 1,
					"source": card_data
				}
				result.effects.append(damage_effect)
				emit_signal("effect_triggered", card_data, "damage", {"value": 1})
			
		3: # 金质
			result.score_bonus += 3
			var effect = {
				"type": "score_bonus",
				"value": 3,
				"source": card_data
			}
			result.effects.append(effect)
			
			# 添加更强的特殊效果
			if card_data.suit == "hearts":
				# 红桃牌增加更多生命值
				var heal_effect = {
					"type": "heal",
					"value": 2,
					"source": card_data
				}
				result.effects.append(heal_effect)
				emit_signal("effect_triggered", card_data, "heal", {"value": 2})

			elif card_data.suit == "diamonds":
				# 方块牌增加更多额外分数
				var diamond_effect = {
					"type": "score_bonus_extra",
					"value": 2,
					"source": card_data
				}
				result.effects.append(diamond_effect)
				result.score_bonus += 2

			elif card_data.suit == "clubs":
				# 梅花牌增加更多防御
				var defense_effect = {
					"type": "defense",
					"value": 2,
					"source": card_data
				}
				result.effects.append(defense_effect)
				emit_signal("effect_triggered", card_data, "defense", {"value": 2})

			elif card_data.suit == "spades":
				# 黑桃牌造成更多伤害
				var damage_effect = {
					"type": "damage",
					"value": 2,
					"source": card_data
				}
				result.effects.append(damage_effect)
				emit_signal("effect_triggered", card_data, "damage", {"value": 2})
			
			# 额外添加抽牌效果
			var draw_effect = {
				"type": "draw",
				"count": 1,
				"source": card_data
			}
			result.effects.append(draw_effect)
			emit_signal("effect_triggered", card_data, "draw", {"count": 1})
			
		4: # 魔晶
			result.score_bonus += 5
			var effect = {
				"type": "score_bonus",
				"value": 5,
				"source": card_data
			}
			result.effects.append(effect)
			
			# 添加元素效果
			match card_data.card_suit:
				GlobalEnums.CardSuit.HEARTS:
					# 红桃牌强力治愈
					var heal_effect = {
						"type": "heal",
						"value": 3,
						"source": card_data
					}
					result.effects.append(heal_effect)
					emit_signal("effect_triggered", card_data, "heal", {"value": 3})
					
					# 额外元素效果: 生命值提升
					var buff_effect = {
						"type": "max_health_boost",
						"value": 1,
						"turns": 3,
						"source": card_data
					}
					result.effects.append(buff_effect)
					emit_signal("effect_triggered", card_data, "max_health_boost", {"value": 1, "turns": 3})
					
				GlobalEnums.CardSuit.DIAMONDS:
					# 方块牌分数暴击
					var diamond_effect = {
						"type": "score_bonus_extra",
						"value": 5,
						"source": card_data
					}
					result.effects.append(diamond_effect)
					result.score_bonus += 5
					
					# 额外元素效果: 下一张牌分数翻倍
					var double_effect = {
						"type": "next_card_double_score",
						"turns": 1,
						"source": card_data
					}
					result.effects.append(double_effect)
					emit_signal("effect_triggered", card_data, "next_card_double_score", {"turns": 1})
					
				GlobalEnums.CardSuit.CLUBS:
					# 梅花牌强力防御
					var defense_effect = {
						"type": "defense",
						"value": 4,
						"source": card_data
					}
					result.effects.append(defense_effect)
					emit_signal("effect_triggered", card_data, "defense", {"value": 4})
					
					# 额外元素效果: 反伤
					var reflect_effect = {
						"type": "reflect",
						"percent": 30,
						"turns": 2,
						"source": card_data
					}
					result.effects.append(reflect_effect)
					emit_signal("effect_triggered", card_data, "reflect", {"percent": 30, "turns": 2})
					
				GlobalEnums.CardSuit.SPADES:
					# 黑桃牌强力伤害
					var damage_effect = {
						"type": "damage",
						"value": 4,
						"source": card_data
					}
					result.effects.append(damage_effect)
					emit_signal("effect_triggered", card_data, "damage", {"value": 4})
					
					# 额外元素效果: 流血
					var bleed_effect = {
						"type": "bleed",
						"damage": 1,
						"turns": 2,
						"source": card_data
					}
					result.effects.append(bleed_effect)
					emit_signal("effect_triggered", card_data, "bleed", {"damage": 1, "turns": 2})
			
			# 抽2张牌
			var draw_effect = {
				"type": "draw",
				"count": 2,
				"source": card_data
			}
			result.effects.append(draw_effect)
			emit_signal("effect_triggered", card_data, "draw", {"count": 2})
	
	# 发送效果应用信号
	emit_signal("effect_applied", card_data, result)
	return result

# 活跃效果列表
var active_effects = []

# 应用效果到游戏状态
func apply_effects_to_game_state(effects):
	for effect in effects:
		# 某些效果需要持续跟踪
		if effect.type in ["max_health_boost", "reflect", "next_card_double_score", "bleed"]:
			# 添加到活跃效果列表
			if effect.has("turns") and effect.turns > 0:
				effect.remaining_turns = effect.turns
				active_effects.append(effect)
	
	# 更新活跃效果
	update_active_effects()

# 更新活跃效果（每回合调用）
func update_active_effects():
	var effects_to_remove = []
	
	# 遍历所有活跃效果，减少剩余回合数
	for effect in active_effects:
		if effect.has("remaining_turns"):
			effect.remaining_turns -= 1
			
			# 移除过期效果
			if effect.remaining_turns <= 0:
				effects_to_remove.append(effect)
	
	# 删除过期效果
	for effect in effects_to_remove:
		active_effects.erase(effect)

# 获取当前活跃效果
func get_active_effects():
	return active_effects

# 清除所有活跃效果
func clear_all_effects():
	active_effects.clear() 
