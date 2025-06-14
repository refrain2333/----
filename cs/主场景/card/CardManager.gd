class_name CardManager
extends Node

var main_game  # 引用主场景

# 卡牌预制体
var card_scene = preload("res://cs/卡牌系统/视图/RuneCard.tscn")

# 构造函数
func _init(game_scene):
	main_game = game_scene

# 初始化卡牌系统
func initialize():
	print("卡牌系统初始化")
	
	# 初始化牌库
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("initialize_deck"):
			GameManager.initialize_deck()

# 从牌库抽一张卡
func draw_card_from_library():
	if not Engine.has_singleton("GameManager"):
		print("错误：找不到GameManager单例")
		return null
	
	var GameManager = Engine.get_singleton("GameManager")
	
	# 检查手牌是否已满
	if GameManager.is_hand_full():
		main_game.ui_manager.set_status("手牌已满，无法抽取更多符文")
		return null
	
	# 抽牌
	var card_data = GameManager.draw_card()
	if not card_data:
		main_game.ui_manager.set_status("符文库已空")
		return null
	
	# 添加到手牌UI
	var card_instance = main_game.ui_manager.add_card_to_hand(card_data)
	
	# 创建抽牌特效
	if main_game.effect_orchestrator:
		var deck_position = Vector2(1600, 500)  # 牌库位置
		var hand_position = card_instance.global_position
		main_game.effect_orchestrator.create_draw_effect(deck_position, hand_position)
	
	# 更新UI
	main_game.ui_manager.update_ui()
	main_game.ui_manager.set_status("抽取了一张符文")
	
	return card_instance

# 打出卡牌
func play_card(card_instance):
	if not Engine.has_singleton("GameManager"):
		return
	
	var GameManager = Engine.get_singleton("GameManager")
	
	# 获取卡牌数据
	var card_data = card_instance.get_card_data() if card_instance.has_method("get_card_data") else null
	if not card_data:
		return
	
	# 检查是否可以出牌
	if not GameManager.can_play_card(card_data):
		main_game.ui_manager.set_status("无法出牌：集中力不足或费用不足")
		return
	
	# 从手牌移除
	main_game.ui_manager.remove_card_from_hand(card_instance)
	
	# 创建放置特效
	if main_game.effect_orchestrator:
		main_game.effect_orchestrator.create_card_drop_effect(card_instance.global_position)
	
	# 记录出牌
	main_game.turn_manager.record_play(card_instance)
	
	# 更新UI
	main_game.ui_manager.update_ui()
	main_game.ui_manager.set_status("打出了符文: " + card_data.name)

# 弃置卡牌
func discard_card(card_instance):
	if not Engine.has_singleton("GameManager"):
		return
	
	var GameManager = Engine.get_singleton("GameManager")
	
	# 检查是否可以弃牌
	if not GameManager.can_discard_card():
		main_game.ui_manager.set_status("无法弃牌：精华不足")
		return
	
	# 获取卡牌数据
	var card_data = card_instance.get_card_data() if card_instance.has_method("get_card_data") else null
	if not card_data:
		return
	
	# 从手牌移除
	main_game.ui_manager.remove_card_from_hand(card_instance)
	
	# 消耗精华
	GameManager.use_essence()
	
	# 更新UI
	main_game.ui_manager.update_ui()
	main_game.ui_manager.set_status("弃置了符文: " + card_data.name)

# 获取卡牌数据
func get_card_data(card_id):
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager.has_method("get_card_by_id"):
			return GameManager.get_card_by_id(card_id)
	
	return null 