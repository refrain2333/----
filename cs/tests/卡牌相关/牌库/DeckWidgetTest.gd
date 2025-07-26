extends Node

# 测试场景引用
@onready var deck_widget = $DeckWidget

func _ready():
	print("DeckWidgetTest: 测试初始化")
	_create_test_card_data()

# 创建测试卡牌数据
func _create_test_card_data():
	print("DeckWidgetTest: 开始从.tres文件加载卡牌数据")

	# 从.tres文件加载真实的卡牌数据
	var all_cards = []
	var current_deck = []
	var played_cards = []

	var suit_codes = ["S", "H", "D", "C"]
	var values = range(1, 14)  # A-K (1-13)

	for suit_code in suit_codes:
		for value in values:
			var card_id = "%s%d" % [suit_code, value]
			var card_path = "res://assets/data/cards/" + card_id + ".tres"

			# 从.tres文件加载卡牌数据
			if ResourceLoader.exists(card_path):
				var card_resource = load(card_path)
				if card_resource:
					all_cards.append(card_resource)
					current_deck.append(card_resource)
					print("DeckWidgetTest: 加载卡牌 %s - %s (花色: %s)" % [card_resource.id, card_resource.name, card_resource.suit])
				else:
					print("DeckWidgetTest: 无法加载卡牌数据 - %s" % card_path)
			else:
				print("DeckWidgetTest: 卡牌文件不存在 - %s" % card_path)

	print("DeckWidgetTest: 创建了 %d 张测试卡牌" % all_cards.size())

	# 更新牌库UI
	deck_widget.all_cards_data = all_cards
	deck_widget.current_deck_data = current_deck
	deck_widget.played_cards_data = played_cards
	deck_widget.update_deck_info(current_deck.size(), all_cards.size())

# 注意：现在直接使用.tres文件中的正确数据，不再需要动态生成名称
