extends Node2D

# 导入必要的类
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")
const CardData = preload("res://cs/卡牌系统/数据/CardData.gd")
const CardEffectController = preload("res://cs/卡牌系统/控制/CardEffectManager.gd")

# 组件引用
@onready var card_container = $CardContainer
@onready var reinforcement_buttons = $UI/ReinforcementControls
@onready var info_label = $UI/InfoLabel

# 卡牌资源
var card_data: CardData
var card_view: Node

# 卡牌效果管理器
var effect_manager

# 强化类型
var wax_seal_types = ["RED", "BLUE", "PURPLE", "GOLD", "GREEN", "ORANGE", "BROWN", "WHITE"]
var frame_types = ["STONE", "SILVER", "GOLD"]
var material_types = ["GLASS", "ROCK", "METAL"]

func _ready():
	# 创建效果管理器
	effect_manager = CardEffectController.new()
	add_child(effect_manager)
	
	# 创建一个测试卡牌
	_create_test_card()
	
	# 创建UI控件
	_create_ui_controls()
	
	# 更新信息显示
	_update_info_label()

# 创建测试卡牌
func _create_test_card():
	# 创建卡牌数据
	card_data = CardData.new()
	card_data.id = "H1"
	card_data.base_value = 1
	card_data.suit = "hearts"
	card_data.name = "红桃A"
	card_data.image_path = "res://assets/images/pokers/1.jpg"
	
	# 创建卡牌视图
	var card_scene = load("res://cs/卡牌系统/视图/Card.tscn")
	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)
	
	# 获取卡牌视图组件
	card_view = card_instance.get_node("CardView")
	card_view.setup(card_data)

# 创建UI控件
func _create_ui_controls():
	# 创建蜡封按钮
	var y_offset = 0
	
	var wax_seal_label = Label.new()
	wax_seal_label.text = "蜡封类型"
	wax_seal_label.position = Vector2(10, y_offset)
	reinforcement_buttons.add_child(wax_seal_label)
	y_offset += 30
	
	for seal_type in wax_seal_types:
		var button = Button.new()
		button.text = "添加 " + seal_type + " 蜡封"
		button.position = Vector2(10, y_offset)
		button.size = Vector2(200, 30)
		button.pressed.connect(_on_add_wax_seal.bind(seal_type))
		reinforcement_buttons.add_child(button)
		y_offset += 40
	
	y_offset += 20
	
	# 创建牌框按钮
	var frame_label = Label.new()
	frame_label.text = "牌框类型"
	frame_label.position = Vector2(10, y_offset)
	reinforcement_buttons.add_child(frame_label)
	y_offset += 30
	
	for frame_type in frame_types:
		var button = Button.new()
		button.text = "设置 " + frame_type + " 牌框"
		button.position = Vector2(10, y_offset)
		button.size = Vector2(200, 30)
		button.pressed.connect(_on_set_frame.bind(frame_type))
		reinforcement_buttons.add_child(button)
		y_offset += 40
	
	y_offset += 20
	
	# 创建材质按钮
	var material_label = Label.new()
	material_label.text = "材质类型"
	material_label.position = Vector2(10, y_offset)
	reinforcement_buttons.add_child(material_label)
	y_offset += 30
	
	for material_type in material_types:
		var button = Button.new()
		button.text = "设置 " + material_type + " 材质"
		button.position = Vector2(10, y_offset)
		button.size = Vector2(200, 30)
		button.pressed.connect(_on_set_material.bind(material_type))
		reinforcement_buttons.add_child(button)
		y_offset += 40
	
	y_offset += 20
	
	# 创建测试按钮
	var test_button = Button.new()
	test_button.text = "测试效果"
	test_button.position = Vector2(10, y_offset)
	test_button.size = Vector2(200, 30)
	test_button.pressed.connect(_on_test_effects)
	reinforcement_buttons.add_child(test_button)
	
	# 创建清除按钮
	y_offset += 40
	var clear_button = Button.new()
	clear_button.text = "清除所有强化"
	clear_button.position = Vector2(10, y_offset)
	clear_button.size = Vector2(200, 30)
	clear_button.pressed.connect(_on_clear_reinforcements)
	reinforcement_buttons.add_child(clear_button)
	
	# 创建卡牌切换按钮
	y_offset += 60
	var card_switch_label = Label.new()
	card_switch_label.text = "切换卡牌"
	card_switch_label.position = Vector2(10, y_offset)
	reinforcement_buttons.add_child(card_switch_label)
	y_offset += 30
	
	var cards = [
		{"name": "红桃A", "id": "H1", "suit": "hearts", "value": 1},
		{"name": "黑桃K", "id": "S13", "suit": "spades", "value": 13},
		{"name": "方块Q", "id": "D12", "suit": "diamonds", "value": 12}
	]
	
	for card_info in cards:
		var button = Button.new()
		button.text = card_info["name"]
		button.position = Vector2(10, y_offset)
		button.size = Vector2(200, 30)
		button.pressed.connect(_on_change_card.bind(card_info))
		reinforcement_buttons.add_child(button)
		y_offset += 40

# 添加蜡封
func _on_add_wax_seal(seal_type: String):
	if not card_data.wax_seal_types.has(seal_type):
		card_data.add_reinforcement("WAX_SEAL", seal_type)
		card_view.update_view()
		_update_info_label()

# 设置牌框
func _on_set_frame(frame_type: String):
	card_data.add_reinforcement("FRAME", frame_type)
	card_view.update_view()
	_update_info_label()

# 设置材质
func _on_set_material(material_type: String):
	card_data.add_reinforcement("MATERIAL", material_type)
	card_view.update_view()
	_update_info_label()

# 测试效果
func _on_test_effects():
	# 创建模拟游戏管理器
	var mock_game_manager = MockGameManager.new()
	add_child(mock_game_manager)
	
	# 设置效果管理器
	effect_manager.setup(mock_game_manager)
	
	# 处理卡牌效果
	var effect_result = effect_manager.process_card_effects(card_data, null)
	
	# 显示效果结果
	var result_text = "效果结果:\n"
	result_text += "值变化: " + str(effect_result.value_change) + "\n"
	result_text += "分数奖励: " + str(effect_result.score_bonus) + "\n\n"
	
	result_text += "触发的效果:\n"
	for effect in effect_result.effects:
		result_text += "- " + _format_effect(effect) + "\n"
	
	# 应用效果到游戏状态
	effect_manager.apply_effects_to_game_state(effect_result.effects)
	
	# 显示游戏状态变化
	result_text += "\n游戏状态变化:\n"
	result_text += mock_game_manager.get_logs()
	
	# 设置结果信息
	info_label.text = result_text
	
	# 从场景移除模拟管理器
	mock_game_manager.queue_free()

# 清除所有强化
func _on_clear_reinforcements():
	card_data.wax_seals = []
	card_data.frame_type = ""
	card_data.material_type = ""
	card_view.update_view()
	_update_info_label()

# 切换卡牌
func _on_change_card(card_info: Dictionary):
	card_data.id = card_info["id"]
	card_data.base_value = card_info["value"]
	card_data.suit = card_info["suit"]
	card_data.name = card_info["name"]
	card_data.image_path = "res://assets/images/pokers/" + str(card_info["value"]) + ".jpg"
	card_view.update_view()
	_update_info_label()

# 格式化效果信息
func _format_effect(effect: Dictionary) -> String:
	var text = ""
	
	match effect.type:
		"wax_seal":
			text = effect.seal_type + " 蜡封: " + effect.effect_name
			if "value" in effect:
				text += " (值: " + str(effect.value) + ")"
		"frame":
			text = effect.frame_type + " 牌框: " + effect.effect_name
			if "value_change" in effect:
				text += " (改变: " + str(effect.value_change) + ")"
			if "double_activated" in effect:
				text += " (已激活: " + str(effect.double_activated) + ")"
		"material":
			text = effect.material_type + " 材质: " + effect.effect_name
			if "bypass_activated" in effect:
				text += " (已激活: " + str(effect.bypass_activated) + ")"
	
	return text

# 更新信息标签
func _update_info_label():
	var text = "卡牌信息：\n"
	text += "名称: " + card_data.card_name + "\n"
	text += "点数: " + str(card_data.base_value) + "\n"
	text += "花色: " + card_data.card_suit + "\n\n"
	
	text += "增强效果:\n"
	
	if card_data.wax_seal_types.size() > 0:
		text += "蜡封: " + str(card_data.wax_seal_types) + "\n"
	
	if card_data.frame_type != "":
		text += "牌框: " + card_data.frame_type + "\n"
	
	if card_data.material_type != "":
		text += "材质: " + card_data.material_type + "\n"
	
	info_label.text = text

# 模拟游戏管理器类，用于测试
class MockGameManager extends Node:
	var logs = []
	
	# 基础接口
	func apply_damage(target, damage):
		logs.append("对目标造成 " + str(damage) + " 点伤害")
	
	func apply_damage_to_opponent(damage):
		logs.append("对敌方造成 " + str(damage) + " 点伤害")
	
	func draw_cards(count):
		logs.append("抽取 " + str(count) + " 张卡牌")
	
	func transform_random_card():
		logs.append("随机变形一张卡牌")
	
	func add_score(value):
		logs.append("增加 " + str(value) + " 分数")
	
	func heal_player(value):
		logs.append("治疗玩家 " + str(value) + " 点生命")
	
	func apply_burn_effect(target, turns):
		logs.append("对目标施加 " + str(turns) + " 回合燃烧效果")
	
	func apply_burn_effect_to_opponent(turns):
		logs.append("对敌方施加 " + str(turns) + " 回合燃烧效果")
	
	func apply_earth_effect(value):
		logs.append("应用 " + str(value) + " 点土元素效果")
	
	func enhance_next_card():
		logs.append("增强下一张卡牌")
	
	func set_element_effect_multiplier(multiplier):
		logs.append("设置元素效果倍率为 " + str(multiplier))
	
	func activate_double_effect():
		logs.append("激活双重效果")
	
	func set_bypass_defense(value):
		logs.append("设置无视防御: " + str(value))
	
	func add_defense(value):
		logs.append("增加 " + str(value) + " 点防御")
	
	func set_damage_reflection(percent):
		logs.append("设置伤害反弹百分比: " + str(percent * 100) + "%")
	
	# 获取日志
	func get_logs() -> String:
		var result = ""
		for log in logs:
			result += "- " + log + "\n"
		return result 
